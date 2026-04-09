import Combine
import SwiftUI

// MARK: - CalmSessionViewModel

@MainActor
final class CalmSessionViewModel: ObservableObject {
    enum SessionPhase: String {
        case intro
        case breathing
        case grounding
        case reflection
        case complete

        // MARK: Internal

        var title: String {
            switch self {
            case .intro: "Сессия спокойствия"
            case .breathing: "Дыхание"
            case .grounding: "Заземление"
            case .reflection: "Рефлексия"
            case .complete: "Готово!"
            }
        }

        var icon: String {
            switch self {
            case .intro: "figure.mind.and.body"
            case .breathing: "wind"
            case .grounding: "eye.fill"
            case .reflection: "brain.head.profile"
            case .complete: "checkmark.seal.fill"
            }
        }
    }

    @Published
    var phase: SessionPhase = .intro
    @Published
    var breathCyclesDone = 0
    @Published
    var currentTimer: Int = 0

    let totalBreathCycles = 4

    func nextPhase() {
        switch phase {
        case .intro: phase = .breathing
        case .breathing: phase = .grounding
        case .grounding: phase = .reflection
        case .reflection: phase = .complete
        case .complete: break
        }
    }
}

// MARK: - CalmSessionView

struct CalmSessionView: View {
    // MARK: Internal

    @StateObject
    var viewModel: CalmSessionViewModel

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

            VStack(spacing: 32) {
                Spacer()

                // Phase icon
                ZStack {
                    Circle()
                        .fill(SP.Colors.calm.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: viewModel.phase.icon)
                        .font(.system(size: 42))
                        .foregroundColor(SP.Colors.calm)
                }
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1 : 0.7)

                Text(viewModel.phase.title)
                    .font(SP.Typography.heroTitle)
                    .foregroundColor(SP.Colors.textPrimary)

                // Phase content
                phaseContent
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                Spacer()

                // Action button
                if viewModel.phase != .complete {
                    Button {
                        SP.Haptic.medium()
                        withAnimation(SP.Anim.spring) {
                            viewModel.nextPhase()
                        }
                    } label: {
                        Text(nextButtonTitle)
                            .spPrimaryButton()
                    }
                } else {
                    Button {
                        SP.Haptic.success()
                        dismiss()
                    } label: {
                        Text("Закрыть")
                            .spPrimaryButton()
                    }
                }
            }
            .padding(.horizontal, SP.Layout.padding)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Закрыть") { dismiss() }
                    .foregroundColor(SP.Colors.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var appear = false

    private var nextButtonTitle: String {
        switch viewModel.phase {
        case .intro: "Начать дыхание →"
        case .breathing: "К заземлению →"
        case .grounding: "К рефлексии →"
        case .reflection: "Завершить ✓"
        case .complete: "Закрыть"
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .intro:
            VStack(spacing: 12) {
                Text("Эта сессия проведёт тебя через 3 этапа:")
                    .font(SP.Typography.body)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 10) {
                    phaseItem("1", "Дыхание", "Успокоим нервную систему", SP.Colors.calm)
                    phaseItem("2", "Заземление", "Переключим внимание", SP.Colors.accent)
                    phaseItem("3", "Рефлексия", "Проработаем мысли", SP.Colors.warmth)
                }
                .spGlassCard()
            }

        case .breathing:
            VStack(spacing: 16) {
                Text("Дыши по схеме 4-7-8")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textPrimary)

                Text("Вдох 4 сек → Задержка 7 сек → Выдох 8 сек\n\nСделай 4 цикла, затем нажми «Далее»")
                    .font(SP.Typography.body)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .spGlassCard()
            }

        case .grounding:
            VStack(spacing: 16) {
                Text("5-4-3-2-1")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    groundingLine("👁️", "5 вещей, которые ты ВИДИШЬ")
                    groundingLine("👂", "4 звука, которые ты СЛЫШИШЬ")
                    groundingLine("✋", "3 предмета, которых КАСАЕШЬСЯ")
                    groundingLine("👃", "2 запаха, которые ЧУВСТВУЕШЬ")
                    groundingLine("👅", "1 вкус, который ОЩУЩАЕШЬ")
                }
                .spGlassCard()
            }

        case .reflection:
            VStack(spacing: 16) {
                Text("Запиши или проговори:")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("• Что вызвало тревогу?")
                    Text("• Насколько она была реальной угрозой? (1-10)")
                    Text("• Что помогло успокоиться?")
                    Text("• Что ты скажешь себе в следующий раз?")
                }
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .spGlassCard()
            }

        case .complete:
            VStack(spacing: 12) {
                Text("Сессия завершена! 🎉")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textPrimary)

                Text("Ты прошёл дыхание, заземление и рефлексию.\nКаждая сессия делает тебя сильнее.")
                    .font(SP.Typography.body)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    private func phaseItem(_ num: String, _ title: String, _ subtitle: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Text(num)
                .font(SP.Typography.title3)
                .foregroundColor(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(subtitle)
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
    }

    private func groundingLine(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.title3)
            Text(text)
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
        }
    }
}
