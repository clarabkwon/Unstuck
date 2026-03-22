// ContentView.swift — Home screen + task input
// Unstuck

import SwiftUI
import FirebaseAI

struct ContentView: View {
    private let model = FirebaseAI.firebaseAI(backend: .googleAI())
        .generativeModel(modelName: "gemini-2.5-flash")

    @EnvironmentObject var appData: AppData
    @State private var task = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var navigateToDetail = false
    @State private var navigateToWins = false
    @State private var showResetSheet = false

    // MARK: - Derived

    private var streakSubline: String {
        let s = appData.currentStreak
        if s > 1 { return "\(s)-day streak \u{2014} you're on a roll" }
        if s == 1 { return "1-day streak \u{2014} keep it going" }
        return "Complete a task today to start your streak"
    }

    private var winsHeadline: String {
        let t = appData.todayCompletions.count
        let y = appData.yesterdayCompletions.count
        if t > 0 { return "Today: \(t) task\(t == 1 ? "" : "s") done" }
        if y > 0 { return "Yesterday: \(y) task\(y == 1 ? "" : "s") done" }
        return "No wins yet today"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Session quote + app name
                VStack(spacing: 6) {
                    Text(appData.sessionQuote)
                        .font(.title3).fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 32)
                    Text("Unstuck")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .tracking(1.5)
                }
                .padding(.top, 8)

                // Wins + streak card — taps through to full history
                Button { navigateToWins = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Text(appData.currentStreak > 0 ? "\(appData.currentStreak)" : "0")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(winsHeadline)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(streakSubline)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Task input card
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you need to get done?")
                        .font(.headline)
                        .padding(.top, 14)

                    TextField("Describe your task…", text: $task, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)

                    if let errorText {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
                .padding(.horizontal)

                // Start button — fetches Gemini breakdown then navigates
                Button { fetchBreakdown() } label: {
                    Group {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Breaking it down…")
                            }
                        } else {
                            Text("Start this task")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) { TaskDetailView() }
        .navigationDestination(isPresented: $navigateToWins)   { WinsView() }
        .sheet(isPresented: $showResetSheet)                   { ResetActivityView() }
        .onAppear {
            // Show reset sheet once per day on struggling days
            if appData.shouldShowResetToday() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showResetSheet = true
                }
            }
        }
    }

    // MARK: - Gemini breakdown

    private func fetchBreakdown() {
        let trimmedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty else { return }

        isLoading = true
        errorText = nil
        appData.steps = []

        Task {
            do {
                let prompt = """
                Break down this task into 4-6 simple actionable steps.
                Return ONLY a JSON array with no markdown, no explanation.
                Each object must have:
                  - id: a UUID string
                  - order: integer starting at 1
                  - text: string describing the step
                  - estimatedMinutes: integer
                Task: \(trimmedTask)
                """

                let response = try await model.generateContent(prompt)
                guard let raw = response.text else {
                    throw NSError(domain: "Unstuck", code: 0,
                                  userInfo: [NSLocalizedDescriptionKey: "Empty response from Gemini."])
                }

                let cleaned = raw
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard let data = cleaned.data(using: .utf8) else {
                    throw NSError(domain: "Unstuck", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Could not parse response."])
                }

                appData.steps = try JSONDecoder().decode([BreakdownStep].self, from: data)
                task = ""
                navigateToDetail = true
            } catch {
                errorText = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(AppData())
    }
}
