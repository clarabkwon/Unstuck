// ResetActivityView.swift
// Unstuck
//
// A guided reset screen for rough days.
// Accessible from ContentView when isDayLightMode is true.
// Offers three short reset activities — breathing, a walk prompt, music.

import SwiftUI

// MARK: - Reset activity model

struct ResetActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String          // SF Symbol
    let durationSeconds: Int  // for the breathing timer; 0 = no timer
    let color: Color
}

private let resetActivities: [ResetActivity] = [
    ResetActivity(
        title: "2-min breathing",
        subtitle: "Breathe in for 4 counts, hold 4, out for 4. Repeat.",
        icon: "wind",
        durationSeconds: 120,
        color: .teal
    ),
    ResetActivity(
        title: "Quick walk",
        subtitle: "Step outside or walk around the room for 2 minutes.",
        icon: "figure.walk",
        durationSeconds: 0,
        color: Color(red: 0.24, green: 0.60, blue: 0.24)
    ),
    ResetActivity(
        title: "One good song",
        subtitle: "Put on a song you love. Just listen — nothing else.",
        icon: "music.note",
        durationSeconds: 0,
        color: Color(red: 0.53, green: 0.29, blue: 0.87)
    ),
]

// MARK: - ResetActivityView

struct ResetActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeActivity: ResetActivity? = nil
    @State private var secondsLeft: Int = 0
    @State private var timer: Timer? = nil
    @State private var timerDone: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 6) {
                        Text("Take a moment")
                            .font(.title2).bold()
                        Text("Pick one reset and you'll feel more ready to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal)

                    // Activity cards
                    ForEach(resetActivities) { activity in
                        ResetCard(
                            activity: activity,
                            isActive: activeActivity?.id == activity.id,
                            secondsLeft: activeActivity?.id == activity.id ? secondsLeft : activity.durationSeconds,
                            timerDone: activeActivity?.id == activity.id ? timerDone : false
                        ) {
                            startActivity(activity)
                        }
                        .padding(.horizontal)
                    }

                    // Done button
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Text("I'm ready — show my task")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { stopTimer(); dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear { stopTimer() }
    }

    // MARK: - Timer

    private func startActivity(_ activity: ResetActivity) {
        stopTimer()
        timerDone = false
        activeActivity = activity

        guard activity.durationSeconds > 0 else { return }

        secondsLeft = activity.durationSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                stopTimer()
                timerDone = true
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Reset card

private struct ResetCard: View {
    let activity: ResetActivity
    let isActive: Bool
    let secondsLeft: Int
    let timerDone: Bool
    let onStart: () -> Void

    private var progressFraction: Double {
        guard activity.durationSeconds > 0 else { return 0 }
        return 1.0 - Double(secondsLeft) / Double(activity.durationSeconds)
    }

    private var timeLabel: String {
        let m = secondsLeft / 60
        let s = secondsLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(activity.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: activity.icon)
                        .foregroundStyle(activity.color)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(activity.title)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(activity.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Start / timer / done state
                Group {
                    if timerDone && isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.teal)
                            .font(.title2)
                    } else if isActive && activity.durationSeconds > 0 {
                        Text(timeLabel)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(activity.color)
                            .monospacedDigit()
                    } else {
                        Button("Start", action: onStart)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(activity.color)
                    }
                }
            }
            .padding(16)

            // Progress bar (only for timed activities when active)
            if isActive && activity.durationSeconds > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemFill))
                            .frame(height: 3)
                        Rectangle()
                            .fill(activity.color)
                            .frame(width: geo.size.width * progressFraction, height: 3)
                            .animation(.linear(duration: 1), value: progressFraction)
                    }
                }
                .frame(height: 3)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? activity.color.opacity(0.4) : Color(.separator),
                        lineWidth: isActive ? 1 : 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ResetActivityView()
}
