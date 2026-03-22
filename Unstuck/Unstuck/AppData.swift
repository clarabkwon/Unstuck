// AppData.swift — shared app state, persistence, and business logic
// Unstuck

import SwiftUI
import Combine
import Foundation

// MARK: - Enums

enum EnergyLevel: String, CaseIterable, Identifiable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
    var id: String { rawValue }
    var maxEffortScore: Int {
        switch self { case .low: return 2; case .medium: return 3; case .high: return 5 }
    }
}

enum TimeAvailable: String, CaseIterable, Identifiable {
    case short  = "15 min"
    case medium = "1 hr"
    case open   = "Open"
    var id: String { rawValue }
    var maxMinutes: Int? {
        switch self { case .short: return 15; case .medium: return 60; case .open: return nil }
    }
}

enum MoodLabel: String, CaseIterable, Identifiable {
    case struggling = "Struggling"
    case okay       = "Okay"
    case good       = "Good"
    var id: String { rawValue }
}

// MARK: - Persisted records

struct CheckInRecord: Codable {
    let date: Date
    let mood: String
    let overwhelmScore: Int   // kept for schema compatibility, always 0
    let energyRaw: String
}

struct CompletedTask: Codable, Identifiable {
    let id: UUID
    let title: String         // first step text, used as display label
    let completedAt: Date
    let totalMinutes: Int
    let stepCount: Int
}

// MARK: - AppData

class AppData: ObservableObject {
    @Published var steps: [BreakdownStep] = []          // active task breakdown
    @Published var energyLevel: EnergyLevel    = .medium
    @Published var timeAvailable: TimeAvailable = .medium
    @Published var hasCheckedIn: Bool = false
    @Published var mood: MoodLabel = .okay
    @Published var sessionQuote: String = ""            // rotates each launch
    @Published var completedTasks: [CompletedTask] = []
    @Published var checkInHistory: [CheckInRecord] = []

    // UserDefaults keys
    private let historyKey        = "checkInHistory"
    private let resetShownKey     = "resetShownDate"
    private let winsKey           = "completedTasks"
    private let lastQuoteKey      = "lastQuoteIndex"
    private let checkedInTodayKey = "checkedInDate"

    init() {
        loadHistory()
        loadWins()
        sessionQuote = pickQuote()
    }

    // MARK: - Derived

    var isDayLightMode: Bool { mood == .struggling }
    var isDaySoftWarning: Bool { mood == .okay }

    // Returns true if the user already checked in today — used to skip CheckInView
    var hasCheckedInToday: Bool {
        UserDefaults.standard.string(forKey: checkedInTodayKey) == todayString()
    }

    // MARK: - Streak

    // Counts consecutive days ending today (or yesterday) with at least one completion
    var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let activeDays = Set(completedTasks.map { cal.startOfDay(for: $0.completedAt) })

        var streak = 0
        var checking = today
        while activeDays.contains(checking) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checking) else { break }
            checking = prev
        }
        if streak == 0 {
            checking = cal.date(byAdding: .day, value: -1, to: today) ?? today
            while activeDays.contains(checking) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checking) else { break }
                checking = prev
            }
        }
        return streak
    }

    var todayCompletions: [CompletedTask] {
        let start = Calendar.current.startOfDay(for: Date())
        return completedTasks.filter { $0.completedAt >= start }
    }

    var yesterdayCompletions: [CompletedTask] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let yStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
        return completedTasks.filter { $0.completedAt >= yStart && $0.completedAt < todayStart }
    }

    var hasRecentWins: Bool { !todayCompletions.isEmpty || !yesterdayCompletions.isEmpty }

    // MARK: - Actions

    // Called when "Mark complete" is tapped in TaskDetailView
    func saveCompletedTask() {
        guard !steps.isEmpty else { return }
        let record = CompletedTask(
            id: UUID(),
            title: steps.first?.text ?? "Task",
            completedAt: Date(),
            totalMinutes: steps.reduce(0) { $0 + $1.estimatedMinutes },
            stepCount: steps.count
        )
        completedTasks.append(record)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        completedTasks = completedTasks.filter { $0.completedAt >= cutoff }
        persistWins()
    }

    // MARK: - Session quote

    private static let quotes = [
        "Let's get you moving.",
        "One thing at a time.",
        "You've got this. Let's start small.",
        "Stuck? Let's fix that.",
        "Whatever's in the way \u{2014} let's move it.",
        "Small steps. Real progress.",
        "Not behind. Just getting started.",
        "Progress, not perfection.",
        "Every task starts with one step."
    ]

    // Picks a random quote, never repeating the last one shown
    private func pickQuote() -> String {
        let lastIndex = UserDefaults.standard.integer(forKey: lastQuoteKey)
        var available = Array(AppData.quotes.indices)
        if available.count > 1 { available.removeAll { $0 == lastIndex } }
        let picked = available.randomElement() ?? 0
        UserDefaults.standard.set(picked, forKey: lastQuoteKey)
        return AppData.quotes[picked]
    }

    // MARK: - Reset sheet

    // Returns true once per day on struggling days, records the date so it won't fire again
    func shouldShowResetToday() -> Bool {
        guard isDayLightMode else { return false }
        let today = todayString()
        let lastShown = UserDefaults.standard.string(forKey: resetShownKey) ?? ""
        if lastShown == today { return false }
        UserDefaults.standard.set(today, forKey: resetShownKey)
        return true
    }

    // MARK: - Pattern detection

    func roughDayCount(inLast days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return checkInHistory.filter {
            $0.date >= cutoff && $0.mood == MoodLabel.struggling.rawValue
        }.count
    }

    var burnoutPatternDetected: Bool { roughDayCount(inLast: 7) >= 3 }

    // MARK: - Persistence

    func saveCheckIn() {
        let record = CheckInRecord(
            date: Date(), mood: mood.rawValue,
            overwhelmScore: 0, energyRaw: energyLevel.rawValue
        )
        checkInHistory.append(record)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        checkInHistory = checkInHistory.filter { $0.date >= cutoff }
        persistHistory()
        UserDefaults.standard.set(todayString(), forKey: checkedInTodayKey)
        hasCheckedIn = true
    }

    private func persistHistory() {
        if let encoded = try? JSONEncoder().encode(checkInHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([CheckInRecord].self, from: data)
        else { return }
        checkInHistory = decoded
    }

    private func persistWins() {
        if let encoded = try? JSONEncoder().encode(completedTasks) {
            UserDefaults.standard.set(encoded, forKey: winsKey)
        }
    }

    private func loadWins() {
        guard let data = UserDefaults.standard.data(forKey: winsKey),
              let decoded = try? JSONDecoder().decode([CompletedTask].self, from: data)
        else { return }
        completedTasks = decoded
    }

    private func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
