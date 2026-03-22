// WinsView.swift — 30-day task history grouped by day, with streak header
// Unstuck

import SwiftUI

struct WinsView: View {
    @EnvironmentObject var appData: AppData

    // Tasks grouped by calendar day, most recent first
    private var grouped: [(date: Date, tasks: [CompletedTask])] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: appData.completedTasks) {
            cal.startOfDay(for: $0.completedAt)
        }
        return byDay
            .map { (date: $0.key, tasks: $0.value.sorted { $0.completedAt > $1.completedAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {

            // Streak header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Text(appData.currentStreak > 0 ? "\(appData.currentStreak)" : "0")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(appData.currentStreak) day streak")
                            .font(.title3).fontWeight(.semibold)
                        Text(appData.currentStreak == 0
                             ? "Complete a task today to start your streak"
                             : "Keep showing up — it adds up.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }

            // Daily groups or empty state
            if grouped.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No wins yet")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Complete your first task and it'll show up here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(grouped, id: \.date) { group in
                    Section(header: DayHeader(date: group.date, count: group.tasks.count)) {
                        ForEach(group.tasks) { task in WinRow(task: task) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Your wins")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Day header

private struct DayHeader: View {
    let date: Date
    let count: Int

    private var label: String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count) task\(count == 1 ? "" : "s")")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Win row

private struct WinRow: View {
    let task: CompletedTask

    private var timeLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: task.completedAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.teal).font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.subheadline).lineLimit(2)
                HStack(spacing: 6) {
                    Text("\(task.stepCount) steps")
                    Text("·")
                    Text("~\(task.totalMinutes) min")
                    Text("·")
                    Text(timeLabel)
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WinsView()
            .environmentObject({
                let d = AppData()
                d.completedTasks = [
                    CompletedTask(id: UUID(), title: "Write outline for report", completedAt: Date(), totalMinutes: 25, stepCount: 4),
                    CompletedTask(id: UUID(), title: "Reply to emails", completedAt: Date().addingTimeInterval(-3600), totalMinutes: 15, stepCount: 3),
                ]
                return d
            }())
    }
}
