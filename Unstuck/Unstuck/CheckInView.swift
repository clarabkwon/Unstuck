// CheckInView.swift — one-time daily check-in (energy → time → mood)
// Unstuck

import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var appData: AppData
    @State private var step: Int = 0
    @State private var navigateToTask = false
    @State private var navigateToWins = false

    private var questionText: String {
        switch step {
        case 0:  return "How's your energy right now?"
        case 1:  return "How much time do you have?"
        default: return "How are you feeling today?"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Session quote
                VStack(spacing: 8) {
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
                .padding(.top, 60)
                .padding(.bottom, 28)

                Spacer()

                // Step progress dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == step ? Color.accentColor : Color(.systemFill))
                            .frame(width: i == step ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
                    }
                }
                .padding(.bottom, 28)

                // Question text — slides in from trailing edge on advance
                Text(questionText)
                    .font(.title3).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .id("question-\(step)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))

                // Answer pills — auto-advance on tap; mood tap completes check-in
                Group {
                    switch step {
                    case 0:
                        HStack(spacing: 10) {
                            ForEach(EnergyLevel.allCases) { level in
                                StepPill(label: level.rawValue,
                                         isSelected: appData.energyLevel == level,
                                         color: .accentColor) {
                                    appData.energyLevel = level
                                    advance()
                                }
                            }
                        }
                    case 1:
                        HStack(spacing: 10) {
                            ForEach(TimeAvailable.allCases) { slot in
                                StepPill(label: slot.rawValue,
                                         isSelected: appData.timeAvailable == slot,
                                         color: .accentColor) {
                                    appData.timeAvailable = slot
                                    advance()
                                }
                            }
                        }
                    default:
                        HStack(spacing: 10) {
                            ForEach(MoodLabel.allCases) { m in
                                StepPill(label: m.rawValue,
                                         isSelected: appData.mood == m,
                                         color: moodColor(m)) {
                                    appData.mood = m
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        appData.saveCheckIn()
                                        navigateToTask = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .id("options-\(step)")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))

                // Back button (steps 1 and 2 only)
                if step > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) { step -= 1 }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                    .transition(.opacity)
                }

                Spacer()
                Spacer()
            }
            .animation(.easeInOut(duration: 0.22), value: step)
            .navigationTitle("Unstuck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigateToWins = true
                    } label: {
                        Image(systemName: "trophy")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToTask) { ContentView() }
            .navigationDestination(isPresented: $navigateToWins) { WinsView() }
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.22)) { step += 1 }
    }

    private func moodColor(_ mood: MoodLabel) -> Color {
        switch mood {
        case .struggling: return .red
        case .okay:       return .orange
        case .good:       return .teal
        }
    }
}

// MARK: - Step pill

private struct StepPill: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? color : .secondary)
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelected ? color : Color(.separator),
                            lineWidth: isSelected ? 1.5 : 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    CheckInView().environmentObject(AppData())
}
