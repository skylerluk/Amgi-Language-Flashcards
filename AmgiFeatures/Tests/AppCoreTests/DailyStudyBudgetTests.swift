import Foundation
import Testing
@testable import AppCore

@Suite @MainActor struct DailyStudyBudgetTests {
    @Test func budgetPersistsAcrossSessionsAndScopesProfiles() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("one", forKey: "amgi.selectedUser")
        let a = DailyStudyBudget(defaults: defaults)
        #expect(a.limit == 40 && a.newLimit == 5)
        a.setLimit(2, todayOnly: true)
        a.record(wasNew: true); a.record(wasNew: false)
        let b = DailyStudyBudget(defaults: defaults)
        #expect(b.reached && b.answered == 2 && b.introduced == 1)
        b.undo(wasNew: false)
        #expect(!b.reached && b.answered == 1 && b.introduced == 1)
        b.undo(wasNew: true)
        #expect(b.answered == 0 && b.introduced == 0)
        b.selectedIDs = [12, 34]
        defaults.set("two", forKey: "amgi.selectedUser")
        #expect(b.limit == 40 && b.selectedIDs == nil && b.answered == 0)
        defaults.set("one", forKey: "amgi.selectedUser")
        #expect(b.selectedIDs == [12, 34])
    }
}
