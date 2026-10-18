import Foundation

enum BundledReadingSupport {
    static let bookNames = ["neighborhood-secret", "first-solo-trip"]
    static func bookURL(_ name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "epub")
    }
    private static let translations: [String: String] = {
        guard let url = Bundle.module.url(forResource: "reading-translations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }()
    static func translation(for text: String) -> String? {
        translations[text.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
}
