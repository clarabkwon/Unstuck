// TaskDetailView.swift
// Unstuck
//
// Screen 3 — active task view with progress bar and confetti.

import SwiftUI

// MARK: - Confetti particle model

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let xDrift: CGFloat
    let yTravel: CGFloat
    let rotation: Double
    let scale: CGFloat
    let duration: Double
    let delay: Double
}

private let confettiSymbols = ["star.fill", "heart.fill", "circle.fill", "diamond.fill"]
private let confettiColors: [Color] = [.yellow, .pink, .mint, .purple]

private func makeParticles(count: Int = 50) -> [ConfettiParticle] {
    (0..<count).map { i in
        ConfettiParticle(
            symbol:   confettiSymbols[i % confettiSymbols.count],
            color:    confettiColors[i % confettiColors.count],
            startX:   CGFloat.random(in: 0.05...0.95),
            startY:   CGFloat.random(in: 0.3...0.85),
            xDrift:   CGFloat.random(in: -120...120),
            yTravel:  CGFloat.random(in: -420 ... -180),
            rotation: Double.random(in: -360...360),
            scale:    CGFloat.random(in: 0.6...1.4),
            duration: Double.random(in: 1.0...1.8),
            delay:    Double.random(in: 0...0.25)
        )
    }
}

// MARK: - Confetti overlay

private struct ConfettiOverlay: View {
    let particles: [ConfettiParticle]
    let isAnimating: Bool

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Image(systemName: p.symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(p.color)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isAnimating ? p.scale : 0.1)
                    .rotationEffect(.degrees(isAnimating ? p.rotation : 0))
                    .opacity(isAnimating ? 0 : 1)
                    .position(
                        x: geo.size.width  * p.startX + (isAnimating ? p.xDrift  : 0),
                        y: geo.size.height * p.startY + (isAnimating ? p.yTravel : 0)
                    )
                    .animation(.easeOut(duration: p.duration).delay(p.delay), value: isAnimating)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - TaskDetailView

struct TaskDetailView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) private var dismiss

    // Reset sheet
    @State private var showResetSheet: Bool = false

    // Confetti
    @State private var showConfetti: Bool = false
    @State private var confettiAnimating: Bool = false
    @State private var particles: [ConfettiParticle] = []

    // MARK: - Derived

    private var completedCount: Int {
        appData.steps.filter { $0.completed }.count
    }

    private var progress: Double {
        guard !appData.steps.isEmpty else { return 0 }
        return Double(completedCount) / Double(appData.steps.count)
    }

    private var barColor: Color {
        return .teal
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {

            // Main content
            VStack(spacing: 0) {

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemFill))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(barColor)
                                .frame(width: geo.size.width * progress, height: 12)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("\(completedCount) of \(appData.steps.count) steps complete")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))

                // Step list
                List {
                    Section {
                        ForEach(appData.steps.indices, id: \.self) { index in
                            HStack(spacing: 14) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        appData.steps[index].completed.toggle()
                                    }
                                } label: {
                                    Image(systemName: appData.steps[index].completed
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(appData.steps[index].completed ? .teal : .secondary)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Step \(appData.steps[index].order)")
                                        .font(.caption).fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .strikethrough(appData.steps[index].completed)

                                    Text(appData.steps[index].text)
                                        .font(.body)
                                        .strikethrough(appData.steps[index].completed, color: .secondary)
                                        .foregroundStyle(appData.steps[index].completed ? .secondary : .primary)

                                    Text("~\(appData.steps[index].estimatedMinutes) min")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        HStack {
                            Text("Steps")
                            Spacer()
                            Text("\(completedCount) of \(appData.steps.count) done")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Bottom actions
                VStack(spacing: 10) {
                    Button { launchConfettiThenDismiss() } label: {
                        Text("Mark complete").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showResetSheet = true
                    } label: {
                        Text("I need a break").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .overlay(alignment: .top) { Divider() }
            }

            // Confetti layer
            if showConfetti {
                ConfettiOverlay(particles: particles, isAnimating: confettiAnimating)
                    .ignoresSafeArea()
                    .zIndex(2)
            }
        }
        .navigationTitle("In progress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResetSheet) {
            ResetActivityView()
        }
    }

    // MARK: - Confetti + dismiss

    private func launchConfettiThenDismiss() {
        appData.saveCompletedTask()

        particles = makeParticles(count: 50)
        showConfetti = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            confettiAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaskDetailView()
            .environmentObject({
                let d = AppData()
                d.steps = [
                    BreakdownStep(order: 1, text: "Open the document and review existing notes", estimatedMinutes: 5),
                    BreakdownStep(order: 2, text: "Write a rough outline with bullet points", estimatedMinutes: 10),
                    BreakdownStep(order: 3, text: "Fill in each section with key details", estimatedMinutes: 15),
                    BreakdownStep(order: 4, text: "Review and clean up grammar", estimatedMinutes: 5),
                ]
                return d
            }())
    }
}
