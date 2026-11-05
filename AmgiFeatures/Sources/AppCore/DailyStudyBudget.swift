public import Foundation
public import Observation

/// One workload budget per collection profile, shared by every study entry point.
@Observable @MainActor
public final class DailyStudyBudget {
    public static let shared = DailyStudyBudget()
    public private(set) var revision = 0
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private var prefix: String { "study.v1." + (defaults.string(forKey: "amgi.selectedUser") ?? "default") + "." }
    private var day: String { String(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970) }
    private var daily: String { prefix + day + "." }
    public var limit: Int { _ = revision; return max(1, defaults.object(forKey: daily + "limit") as? Int ?? defaults.object(forKey: prefix + "limit") as? Int ?? 40) }
    public var newLimit: Int { _ = revision; return max(0, defaults.object(forKey: prefix + "newLimit") as? Int ?? 5) }
    public var answered: Int { _ = revision; return defaults.integer(forKey: daily + "answered") }
    public var introduced: Int { _ = revision; return defaults.integer(forKey: daily + "introduced") }
    public var reached: Bool { answered >= limit }
    public var selectedIDs: [Int64]? {
        get { _ = revision; return (defaults.array(forKey: prefix + "decks") as? [String])?.compactMap(Int64.init) }
        set { defaults.set(newValue?.map(String.init), forKey: prefix + "decks"); revision += 1 }
    }
    public func setLimit(_ value: Int, todayOnly: Bool) {
        defaults.set(max(1, value), forKey: (todayOnly ? daily : prefix) + "limit")
        if !todayOnly { defaults.removeObject(forKey: daily + "limit") }
        revision += 1
    }
    public func setNewLimit(_ value: Int) { defaults.set(max(0, value), forKey: prefix + "newLimit"); revision += 1 }
    public func record(wasNew: Bool) {
        defaults.set(answered + 1, forKey: daily + "answered")
        if wasNew { defaults.set(introduced + 1, forKey: daily + "introduced") }
        revision += 1
    }
    public func undo(wasNew: Bool) {
        defaults.set(max(0, answered - 1), forKey: daily + "answered")
        if wasNew { defaults.set(max(0, introduced - 1), forKey: daily + "introduced") }
        revision += 1
    }
}
