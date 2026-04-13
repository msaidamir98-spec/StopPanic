import SwiftUI

// MARK: - GroundingStep

private struct GroundingStep {
    let emoji: String
    let count: Int
    let sense: String
    let verb: String
    let color: Color
}

// MARK: - GroundingExerciseView

// ✨ Glass cards, staggered items, particle background, celebration

struct GroundingExerciseView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(
                primaryColor: isComplete ? SP.Colors.success : steps[min(currentStep, 4)].color,
                secondaryColor: SP.Colors.calm
            )

            if isComplete {
                completionView
            } else {
                exerciseView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var currentStep = 0
    @State
    private var inputs: [[String]] = [[], [], [], [], []]
    @State
    private var currentInput = ""
    @State
    private var isComplete = false
    @State
    private var appear = false
    @State
    private var completionScale: CGFloat = 0.3
    @FocusState
    private var isFocused: Bool

    private let steps: [GroundingStep] = [
        GroundingStep(emoji: "👁️", count: 5, sense: String(localized: "grounding.sense_see"), verb: String(localized: "grounding.verb_see"), color: SP.Colors.accent),
        GroundingStep(emoji: "✋", count: 4, sense: String(localized: "grounding.sense_touch"), verb: String(localized: "grounding.verb_touch"), color: SP.Colors.calm),
        GroundingStep(emoji: "👂", count: 3, sense: String(localized: "grounding.sense_hear"), verb: String(localized: "grounding.verb_hear"), color: SP.Colors.warmth),
        GroundingStep(emoji: "👃", count: 2, sense: String(localized: "grounding.sense_smell"), verb: String(localized: "grounding.verb_smell"), color: SP.Colors.success),
        GroundingStep(emoji: "👅", count: 1, sense: String(localized: "grounding.sense_taste"), verb: String(localized: "grounding.verb_taste"), color: SP.Colors.accent),
    ]

    // MARK: - Exercise View

    private var exerciseView: some View {
        let step = steps[currentStep]

        return VStack(spacing: 24) {
            // Top bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SP.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.warmGlass))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                }
                Spacer()
                Text(String(localized: "grounding.step_of \(currentStep + 1) \(5)"))
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .padding(.horizontal, SP.Layout.padding)
            .padding(.top, 12)

            // Progress with glow
            HStack(spacing: 6) {
                ForEach(0 ..< 5, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep ? step.color : Color.white.opacity(0.1))
                        .frame(height: 4)
                        .shadow(
                            color: i <= currentStep ? step.color.opacity(0.4) : .clear, radius: 4
                        )
                        .animation(SP.Anim.springSnappy.delay(Double(i) * 0.05), value: currentStep)
                }
            }
            .padding(.horizontal, SP.Layout.padding)

            Spacer()

            // Big prompt
            Text(step.emoji)
                .font(.system(size: 72))
                .scaleEffect(appear ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: currentStep)

            Text(String(localized: "grounding.name_count \(step.count)"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(step.color)

            Text(String(localized: "grounding.what_you \(step.sense)"))
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textSecondary)

            // Entered items with staggered animation
            VStack(spacing: 8) {
                ForEach(Array(inputs[currentStep].enumerated()), id: \.offset) { _, item in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(step.color)
                            .font(.system(size: 16))
                        Text(String(localized: "grounding.i_verb \(step.verb) \(item)"))
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.warmGlass)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(step.color.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                }
            }
            .padding(.horizontal, SP.Layout.padding)

            Spacer()

            // Input
            if inputs[currentStep].count < step.count {
                HStack(spacing: 12) {
                    TextField(String(localized: "grounding.enter"), text: $currentInput)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.warmGlass)
                        )
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .onSubmit { addItem() }

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(step.color)
                    }
                    .disabled(currentInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, SP.Layout.padding)
            } else {
                Button {
                    SP.Haptic.success()
                    withAnimation(SP.Anim.spring) {
                        if currentStep < 4 {
                            currentStep += 1
                        } else {
                            isComplete = true
                            coordinator.completedSession()
                        }
                    }
                } label: {
                    Text(currentStep < 4 ? String(localized: "grounding.next") : String(localized: "grounding.finish"))
                        .spPrimaryButton()
                }
                .buttonStyle(PremiumButtonStyle())
                .padding(.horizontal, SP.Layout.padding)
                .glowPulse(color: step.color)
            }

            Spacer().frame(height: 20)
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Celebration rings
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .stroke(SP.Colors.success.opacity(0.1 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(130 + i * 25), height: CGFloat(130 + i * 25))
                        .scaleEffect(completionScale)
                }

                Circle()
                    .fill(SP.Colors.success.opacity(0.15))
                    .frame(width: 130, height: 130)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(SP.Colors.success)
                    .scaleEffect(completionScale)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    completionScale = 1.0
                }
            }

            Text(String(localized: "grounding.done_title"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "grounding.done_body"))
            .font(SP.Typography.body)
            .foregroundColor(SP.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(String(localized: "general.done"))
                    .spPrimaryButton()
            }
            .buttonStyle(PremiumButtonStyle())
            .padding(.horizontal, SP.Layout.padding)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Logic

    private func addItem() {
        let text = currentInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        SP.Haptic.soft()
        withAnimation(SP.Anim.springSnappy) {
            inputs[currentStep].append(text)
        }
        currentInput = ""
    }
}

// MARK: - MuscleRelaxView

struct MuscleRelaxView: View {
    // MARK: Internal

    var body: some View {
        ZStack {
            AmbientBackground(
                primaryColor: isTensing ? SP.Colors.warmth : SP.Colors.calm,
                secondaryColor: SP.Colors.accent
            )

            VStack(spacing: 24) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SP.Colors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.warmGlass))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                    Spacer()
                    Text("\(currentStep + 1) / \(muscleGroups.count)")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                .padding(.top, 12)

                // Progress
                HStack(spacing: 4) {
                    ForEach(0 ..< muscleGroups.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentStep ? SP.Colors.calm : Color.white.opacity(0.1))
                            .frame(height: 3)
                    }
                }

                if currentStep < muscleGroups.count {
                    let group = muscleGroups[currentStep]

                    Spacer()

                    Image(systemName: group.2)
                        .font(.system(size: 64))
                        .foregroundColor(isTensing ? SP.Colors.warmth : SP.Colors.calm)
                        .scaleEffect(pulseScale)
                        .shadow(
                            color: (isTensing ? SP.Colors.warmth : SP.Colors.calm).opacity(0.3),
                            radius: 12
                        )

                    Text(group.0)
                        .font(SP.Typography.heroTitle)
                        .foregroundColor(SP.Colors.textPrimary)

                    Text(isTensing ? String(localized: "muscle.tense") : String(localized: "muscle.relax"))
                        .font(SP.Typography.title3)
                        .foregroundColor(isTensing ? SP.Colors.warmth : SP.Colors.calm)
                        .contentTransition(.opacity)

                    Text(group.1)
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Spacer()

                    Button {
                        startTenseRelax()
                    } label: {
                        Text(isTensing ? String(localized: "muscle.relaxing") : String(localized: "muscle.tense_button"))
                            .spPrimaryButton()
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .disabled(isTensing)
                } else {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(SP.Colors.success.opacity(0.12))
                            .frame(width: 130, height: 130)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(SP.Colors.success)
                    }

                    Text(String(localized: "muscle.done_title"))
                        .font(SP.Typography.heroTitle)
                        .foregroundColor(SP.Colors.textPrimary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "general.done"))
                            .spPrimaryButton()
                    }
                    .buttonStyle(PremiumButtonStyle())
                }
            }
            .padding(.horizontal, SP.Layout.padding)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .onDisappear {
            timer?.invalidate()
            timer = nil
            relaxTimer?.invalidate()
            relaxTimer = nil
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var currentStep = 0
    @State
    private var isTensing = false
    @State
    private var timer: Timer?
    @State
    private var pulseScale: CGFloat = 1.0
    @State
    private var relaxTimer: Timer?

    private let muscleGroups = [
        (String(localized: "muscle.hands_title"), String(localized: "muscle.hands_desc"), "figure.hand.draw"),
        (String(localized: "muscle.forearms_title"), String(localized: "muscle.forearms_desc"), "figure.arms.open"),
        (String(localized: "muscle.shoulders_title"), String(localized: "muscle.shoulders_desc"), "figure.stand"),
        (String(localized: "muscle.face_title"), String(localized: "muscle.face_desc"), "face.smiling.inverse"),
        (String(localized: "muscle.neck_title"), String(localized: "muscle.neck_desc"), "figure.mind.and.body"),
        (String(localized: "muscle.back_title"), String(localized: "muscle.back_desc"), "figure.strengthtraining.traditional"),
        (String(localized: "muscle.abs_title"), String(localized: "muscle.abs_desc"), "figure.core.training"),
        (String(localized: "muscle.legs_title"), String(localized: "muscle.legs_desc"), "figure.walk"),
    ]

    private func startTenseRelax() {
        guard !isTensing else { return }
        SP.Haptic.medium()
        isTensing = true

        // Pulsing animation during tension
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [self] _ in
            SP.Haptic.success()
            withAnimation(SP.Anim.spring) {
                isTensing = false
                pulseScale = 1.0
            }
            // Auto-advance after 3 sec relaxation
            relaxTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) {
                [self] _ in
                withAnimation(SP.Anim.spring) {
                    currentStep += 1
                }
            }
        }
    }
}

// MARK: - CognitiveReframingView

struct CognitiveReframingView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.warmth)

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(SP.Colors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.warmGlass))
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        }
                        Spacer()
                    }
                    .padding(.top, 12)

                    Text(String(localized: "cognitive.title"))
                        .font(SP.Typography.title1)
                        .foregroundColor(SP.Colors.textPrimary)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : -10)

                    Text(String(localized: "cognitive.subtitle"))
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textSecondary)
                        .opacity(appear ? 1 : 0)

                    // Step 1
                    VStack(alignment: .leading, spacing: 10) {
                        Label(String(localized: "cognitive.anxious_thought"), systemImage: "exclamationmark.bubble.fill")
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.danger)

                        Text(String(localized: "cognitive.write_thought"))
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)

                        TextField(
                            String(localized: "cognitive.thought_example"),
                            text: $anxiousThought, axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.warmGlass)
                        )
                        .foregroundColor(.white)
                        .frame(minHeight: 60)
                    }
                    .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                    if !anxiousThought.isEmpty {
                        // Step 2
                        VStack(alignment: .leading, spacing: 10) {
                            Label(String(localized: "cognitive.facts_against"), systemImage: "magnifyingglass")
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.warning)

                            Text(String(localized: "cognitive.what_facts"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)

                            TextField(
                                String(localized: "cognitive.facts_example"), text: $evidence,
                                axis: .vertical
                            )
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.warmGlass)
                            )
                            .foregroundColor(.white)
                            .frame(minHeight: 60)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "cognitive.distortions_title"))
                                    .font(SP.Typography.caption)
                                    .foregroundColor(SP.Colors.textTertiary)

                                distortionChip(String(localized: "cognitive.catastrophizing"), String(localized: "cognitive.catastrophizing_desc"))
                                distortionChip(String(localized: "cognitive.black_white"), String(localized: "cognitive.black_white_desc"))
                                distortionChip(String(localized: "cognitive.mind_reading"), String(localized: "cognitive.mind_reading_desc"))
                                distortionChip(String(localized: "cognitive.emotional_reasoning"), String(localized: "cognitive.emotional_reasoning_desc"))
                            }
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if !evidence.isEmpty {
                        // Step 3
                        VStack(alignment: .leading, spacing: 10) {
                            Label(String(localized: "cognitive.alternative"), systemImage: "lightbulb.fill")
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.success)

                            Text(String(localized: "cognitive.how_reframe"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)

                            TextField(
                                String(localized: "cognitive.alternative_example"),
                                text: $alternative, axis: .vertical
                            )
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.warmGlass)
                            )
                            .foregroundColor(.white)
                            .frame(minHeight: 60)
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if !alternative.isEmpty {
                        // Result — celebration
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(SP.Colors.success)
                            Text(String(localized: "cognitive.excellent"))
                                .font(SP.Typography.title2)
                                .foregroundColor(SP.Colors.textPrimary)
                            Text(String(localized: "cognitive.done_body"))
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                            Button {
                                coordinator.completedSession()
                                coordinator.achievementService.updateProgress(
                                    id: "technique_explorer"
                                )
                                dismiss()
                            } label: {
                                Text(String(localized: "cognitive.done_button"))
                                    .spSecondaryButton()
                            }
                            .buttonStyle(PremiumButtonStyle())
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
                        .glowPulse(color: SP.Colors.success)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
                .animation(SP.Anim.spring, value: anxiousThought.isEmpty)
                .animation(SP.Anim.spring, value: evidence.isEmpty)
                .animation(SP.Anim.spring, value: alternative.isEmpty)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var anxiousThought = ""
    @State
    private var evidence = ""
    @State
    private var alternative = ""
    @State
    private var appear = false

    private func distortionChip(_ title: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text("•")
                .foregroundColor(SP.Colors.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.warning)
                Text(desc)
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
    }
}
