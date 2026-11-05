package import SwiftUI
import AppCore
import Theme

package struct StudyBudgetSettings: View {
    @State private var budget = DailyStudyBudget.shared
    @State private var limit = 40
    @State private var newLimit = 5
    @State private var todayOnly = true
    @Environment(\.dismiss) private var dismiss
    package init() {}
    package var body: some View {
        NavigationStack {
            Form {
                Section("Daily review cap") {
                    Text("\(budget.answered) answers today · \(budget.introduced) new cards introduced")
                    Picker("Quick choice", selection: $limit) {
                        ForEach(Array(Set([20, 40, 60, limit])).sorted(), id: \.self) { Text("\($0)").tag($0) }
                    }.pickerStyle(.segmented)
                    Stepper("\(limit) card answers", value: $limit, in: 1...2000, step: 5)
                    Toggle("Today only", isOn: $todayOnly)
                    Text("Each graded answer counts, including repeats and reverse cards. At the cap you can stop or add 20 more. Unseen cards stay due.").amgiFont(.caption)
                }
                Section("New cards per day") {
                    Stepper("Up to \(newLimit) new cards", value: $newLimit, in: 0...100)
                    Text("Shared across selected decks, including new English → Chinese cards. Due reviews come first; overdue cards pause new introductions.").amgiFont(.caption)
                }
            }
            .navigationTitle("Study limits")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { budget.setLimit(limit, todayOnly: todayOnly); budget.setNewLimit(newLimit); dismiss() } }
            }
            .onAppear { limit = budget.limit; newLimit = budget.newLimit }
        }
    }
}
