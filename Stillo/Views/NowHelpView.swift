import Combine
import SwiftUI

// MARK: - NowHelpViewModel

@MainActor
final class NowHelpViewModel: ObservableObject {
    @Published
    var currentStep = 0
    @Published
    var isComplete = false

    let steps: [PanicStep] = [
        PanicStep(
            number: 1,
            title: String(localized: "nowhelp.step1_title"),
            instruction: String(localized: "nowhelp.step1_instruction"),
            icon: "hand.raised.fill",
            color: .red
        ),
        PanicStep(
            number: 2,
            title: String(localized: "nowhelp.step2_title"),
            instruction: String(localized: "nowhelp.step2_instruction"),
            icon: "wind",
            color: .cyan
        ),
        PanicStep(
            number: 3,
            title: String(localized: "nowhelp.step3_title"),
            instruction: String(localized: "nowhelp.step3_instruction"),
            icon: "eye.fill",
            color: .purple
        ),
        PanicStep(
            number: 4,
            title: String(localized: "nowhelp.step4_title"),
            instruction: String(localized: "nowhelp.step4_instruction"),
            icon: "brain.head.profile",
            color: .orange
        ),
        PanicStep(
            number: 5,
            title: String(localized: "nowhelp.step5_title"),
            instruction: String(localized: "nowhelp.step5_instruction"),
            icon: "figure.mind.and.body",
            color: .green
        ),
    ]

    func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        } else {
            isComplete = true
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
}

// MARK: - PanicStep

struct PanicStep {
    let number: Int
    let title: String
    let instruction: String
    let icon: String
    let color: Color
}

// MARK: - NowHelpView

struct NowHelpView: View {
    // MARK: Internal

    @StateObject
    var viewModel: NowHelpViewModel

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.warmth, secondaryColor: SP.Colors.calm)

            if viewModel.isComplete {
                completionView
            } else {
                stepView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "general.close")) { dismiss() }
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

    // MARK: - Step View

    private var stepView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0 ..< viewModel.steps.count, id: \.self) { i in
                    Circle()
                        .fill(i <= viewModel.currentStep ? SP.Colors.accent : Color.white.opacity(0.15))
                        .frame(width: 10, height: 10)
                        .scaleEffect(i == viewModel.currentStep ? 1.3 : 1.0)
                        .animation(SP.Anim.springSnappy, value: viewModel.currentStep)
                }
            }

            let step = viewModel.steps[viewModel.currentStep]

            // Icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: step.icon)
                    .font(.system(size: 42))
                    .foregroundColor(step.color)
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.7)

            // Title
            VStack(spacing: 12) {
                Text(String(localized: "nowhelp.step_of \(step.number) \(viewModel.steps.count)"))
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)

                Text(step.title)
                    .font(SP.Typography.heroTitle)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            // Instruction
            Text(step.instruction)
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .spGlassCard()

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                if viewModel.currentStep > 0 {
                    Button {
                        SP.Haptic.light()
                        withAnimation(SP.Anim.spring) {
                            viewModel.previousStep()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(String(localized: "general.back"))
                        }
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.warmGlass))
                    }
                }

                Button {
                    SP.Haptic.medium()
                    withAnimation(SP.Anim.spring) {
                        viewModel.nextStep()
                    }
                } label: {
                    Text(viewModel.currentStep < viewModel.steps.count - 1 ? String(localized: "nowhelp.next") : String(localized: "nowhelp.finish"))
                        .spPrimaryButton()
                }
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SP.Colors.success.opacity(0.12))
                    .frame(width: 130, height: 130)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(SP.Colors.success)
            }

            Text(String(localized: "nowhelp.well_done"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "nowhelp.done_body"))
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            Button {
                SP.Haptic.success()
                dismiss()
            } label: {
                Text(String(localized: "general.close"))
                    .spPrimaryButton()
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }
}
