//
//  ChatClient.swift
//  ReaderFeature
//
//  Minimal client for OpenAI-compatible chat completions, which both
//  OpenRouter and Groq speak. Streaming for free-form answers; a single
//  JSON-mode request for the tutor's structured turns.
//

import Foundation

struct ChatMessage: Codable, Hashable, Sendable {
    enum Role: String, Codable, Sendable { case system, user, assistant }
    var role: Role
    var content: String
}

struct ChatEndpoint: Sendable {
    let provider: AIProvider
    let url: URL
    let apiKey: String
    let model: String
}

enum ChatClientError: LocalizedError {
    case missingKey(AIProvider)
    case http(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingKey(let provider):
            "Add your \(provider.displayName) key in AI Keys first."
        case .http(let status, let message):
            switch status {
            case 401: "The API key was rejected (401). Check it in AI Keys."
            case 402: "Your account is out of credits (402)."
            case 429: "Rate limited (429). Wait a moment and try again."
            default: "Request failed (\(status)): \(message)"
            }
        case .emptyResponse:
            "The model returned an empty response. Try again."
        }
    }
}

enum ChatClient {
    /// Streams the assistant's text as it is generated.
    static func stream(
        _ endpoint: ChatEndpoint,
        messages: [ChatMessage],
        temperature: Double = 0.5
    ) -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try makeRequest(endpoint, messages: messages, stream: true, json: false, temperature: temperature)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    guard status == 200 else {
                        var body = ""
                        for try await line in bytes.lines { body += line }
                        throw ChatClientError.http(status, errorMessage(from: Data(body.utf8)))
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data)
                        else { continue }
                        if let message = chunk.error?.message {
                            throw ChatClientError.http(0, message)
                        }
                        if let text = chunk.choices?.first?.delta?.content, !text.isEmpty {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// One complete response. With `json: true` the provider is asked for a
    /// single JSON object (OpenAI `response_format: json_object`).
    static func complete(
        _ endpoint: ChatEndpoint,
        messages: [ChatMessage],
        json: Bool = false,
        temperature: Double = 0.6
    ) async throws -> String {
        let request = try makeRequest(endpoint, messages: messages, stream: false, json: json, temperature: temperature)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw ChatClientError.http(status, errorMessage(from: data))
        }
        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty
        else { throw ChatClientError.emptyResponse }
        return content
    }

    // MARK: - Private

    private static func makeRequest(
        _ endpoint: ChatEndpoint,
        messages: [ChatMessage],
        stream: Bool,
        json: Bool,
        temperature: Double
    ) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(endpoint.apiKey)", forHTTPHeaderField: "Authorization")
        if endpoint.provider == .openRouter {
            // OpenRouter's optional app attribution headers.
            request.setValue("https://github.com/skylerluk/amgi", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Amgi", forHTTPHeaderField: "X-Title")
        }

        var body: [String: Any] = [
            "model": endpoint.model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "temperature": temperature,
            "stream": stream,
        ]
        if json {
            body["response_format"] = ["type": "json_object"]
        }
        // gpt-oss reasons before answering; keep it brief for chat latency.
        if endpoint.model.contains("gpt-oss") {
            body["reasoning_effort"] = "low"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func errorMessage(from data: Data) -> String {
        if let decoded = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           let message = decoded.error?.message {
            return message
        }
        return String(data: data, encoding: .utf8)?.prefix(200).description ?? "Unknown error"
    }

    private struct ErrorEnvelope: Decodable {
        struct Inner: Decodable { let message: String? }
        let error: Inner?
    }

    private struct StreamChunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta?
        }
        let choices: [Choice]?
        let error: ErrorEnvelope.Inner?
    }

    private struct CompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
        }
        let choices: [Choice]
    }
}
