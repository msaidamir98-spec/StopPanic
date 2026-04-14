import SwiftUI

// MARK: - HeartAnalysisView

/// Экран мониторинга пульса — анализ паттернов.
/// ⚠️ Информационный wellness-инструмент, НЕ медицинское устройство.
struct HeartAnalysisView: View {
    // MARK: Internal

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.danger, secondaryColor: SP.Colors.warmth)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    disclaimerCard
                    statusCircle
                    if let analysis = service.currentAnalysis {
                        diagnosisCard(analysis)
                        metricsGrid(analysis)
                        recommendationCard(analysis.recommendation)
                        if analysis.suggestMedicalConsult { consultBanner }
                    }
                    breathingTestSection
                    monitoringButton
                    educationCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(String(localized: "heart.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Private

    @StateObject
    private var service = HeartAnalysisService()

    private var diagnosisColor: Color {
        switch service.currentAnalysis?.diagnosis {
        case .stressResponse: SP.Colors.warning
        case .elevatedIrregular: SP.Colors.danger
        case .irregularPattern: .orange
        case .normal: SP.Colors.success
        default: SP.Colors.textTertiary
        }
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                Text(String(localized: "heart.important_info"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
            }
            Text(String(localized: "heart.disclaimer_body"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
                .lineSpacing(3)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .overlay(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Status Circle

    private var statusCircle: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(SP.Colors.bgCardHover, lineWidth: 12)
                    .frame(width: 180, height: 180)
                Circle()
                    .trim(from: 0, to: service.currentAnalysis?.confidence ?? 0)
                    .stroke(
                        diagnosisColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(SP.Anim.spring, value: service.currentAnalysis?.confidence)

                VStack(spacing: 6) {
                    Image(systemName: service.isMonitoring ? "heart.fill" : "heart")
                        .font(.system(size: 36))
                        .foregroundColor(diagnosisColor)
                        .symbolEffect(.pulse, isActive: service.isMonitoring)
                    Text(service.currentAnalysis?.diagnosis.localizedTitle ?? String(localized: "heart.waiting"))
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    if let hr = service.currentAnalysis?.heartRate {
                        Text("\(Int(hr)) BPM")
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textSecondary)
                            .monospacedDigit()
                    }
                }
            }
            Text(String(localized: "heart.pulse_monitoring"))
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)
        }
        .padding(.top, 8)
    }

    // MARK: - Consult Doctor Banner (NOT "Emergency")

    private var consultBanner: some View {
        VStack(spacing: 10) {
            Text(String(localized: "heart.consult_doctor"))
                .font(SP.Typography.title3)
                .foregroundColor(.white)
            Text(String(localized: "heart.consult_doctor_body"))
                .font(SP.Typography.caption)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                .fill(SP.Colors.danger)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "heart.consult_doctor"))
    }

    // MARK: - Breathing Test

    private var breathingTestSection: some View {
        Group {
            if service.isMonitoring {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "lungs.fill")
                            .foregroundColor(SP.Colors.calm)
                        Text(String(localized: "heart.breathing_test"))
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)
                    }

                    Text(String(localized: "heart.breathing_test_body"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                        .lineSpacing(3)

                    HStack(spacing: 12) {
                        Button {
                            SP.Haptic.light()
                            service.markPreBreathingHR()
                        } label: {
                            Text(String(localized: "heart.fix_pulse"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.calm)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SP.Colors.calm.opacity(0.15)))
                        }
                        Button {
                            SP.Haptic.light()
                            service.checkBreathingResponse()
                        } label: {
                            Text(String(localized: "heart.check"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.success)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SP.Colors.success.opacity(0.15)))
                        }
                    }

                    if service.breathingResponseDetected {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SP.Colors.success)
                            Text(String(localized: "heart.pulse_dropped"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.success)
                        }
                    }
                }
                .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
            }
        }
    }

    // MARK: - Controls

    private var monitoringButton: some View {
        Button {
            SP.Haptic.medium()
            if service.isMonitoring {
                service.stopMonitoring()
            } else {
                service.startMonitoring()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: service.isMonitoring ? "stop.fill" : "heart.fill")
                    .contentTransition(.symbolEffect(.replace))
                Text(service.isMonitoring ? String(localized: "heart.stop") : String(localized: "heart.start_monitoring"))
            }
            .font(SP.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: SP.Layout.cornerSmall)
                    .fill(service.isMonitoring ? AnyShapeStyle(SP.Colors.danger.opacity(0.8)) : AnyShapeStyle(SP.Colors.heroGradient))
            )
            .shadow(
                color: service.isMonitoring ? SP.Colors.danger.opacity(0.3) : SP.Shadows.glow,
                radius: 12, y: 6
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }

    // MARK: - Education

    private var educationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "heart.how_it_works"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            VStack(alignment: .leading, spacing: 8) {
                infoLine("heart.fill", String(localized: "heart.info_reads_pulse"))
                infoLine("waveform.path", String(localized: "heart.info_analyzes_rhythm"))
                infoLine("brain.head.profile", String(localized: "heart.info_compares_patterns"))
                infoLine("lungs.fill", String(localized: "heart.info_checks_breathing"))
            }

            Text(String(localized: "heart.algorithm_disclaimer"))
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
                .lineSpacing(3)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Helpers

    private func infoLine(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(SP.Colors.accent)
                .frame(width: 16)
            Text(text)
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
        }
    }

    private func diagnosisCard(_ a: HeartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(diagnosisEmoji(a.diagnosis))
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(a.diagnosis.localizedTitle)
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(String(localized: "heart.confidence \(Int(a.confidence * 100))"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
            }

            if a.diagnosis == .stressResponse {
                differenceExplanation(
                    title: String(localized: "heart.stress_signs"),
                    points: [
                        String(localized: "heart.regular_rhythm"),
                        String(localized: "heart.hr_typical \(Int(a.heartRate))"),
                        String(localized: "heart.pattern \(a.risePattern.localizedTitle)"),
                        service.breathingResponseDetected
                            ? String(localized: "heart.pulse_responds")
                            : String(localized: "heart.try_breathing"),
                    ],
                    color: SP.Colors.warning
                )
            } else if a.diagnosis == .elevatedIrregular || a.diagnosis == .irregularPattern {
                differenceExplanation(
                    title: String(localized: "heart.consult_signs"),
                    points: [
                        String(localized: "heart.irregular_rhythm \(String(format: "%.0f%%", a.irregularity * 100))"),
                        String(localized: "heart.hrv_value \(String(format: "%.0f", a.hrvMs))"),
                        String(localized: "heart.no_breathing_response"),
                        String(localized: "heart.recommend_consult"),
                    ],
                    color: SP.Colors.danger
                )
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .overlay(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                .stroke(diagnosisColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func differenceExplanation(title: String, points: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SP.Typography.subheadline)
                .foregroundColor(SP.Colors.textPrimary)
            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .foregroundColor(color)
                    Text(point)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
        }
        .padding(.top, 4)
    }

    private func metricsGrid(_ a: HeartAnalysis) -> some View {
        LazyVGrid(columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)], spacing: 12) {
            metricTile(String(localized: "heart.metric_hr"), value: "\(Int(a.heartRate))", unit: "BPM")
            metricTile(String(localized: "heart.metric_hrv"), value: String(format: "%.0f", a.hrvMs), unit: String(localized: "heart.ms"))
            metricTile(String(localized: "heart.metric_regularity"), value: String(format: "%.0f%%", (1 - a.irregularity) * 100), unit: "")
            metricTile(String(localized: "heart.metric_pattern"), value: a.risePattern.localizedTitle, unit: "")
        }
    }

    private func metricTile(_ title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
            Text(value)
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
                .monospacedDigit()
            if !unit.isEmpty {
                Text(unit)
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    private func recommendationCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(SP.Colors.warning)
                Text(String(localized: "heart.recommendation"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            Text(text)
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private func diagnosisEmoji(_ d: HeartAnalysis.Diagnosis) -> String {
        switch d {
        case .stressResponse: "😮‍💨"
        case .elevatedIrregular: "⚠️"
        case .irregularPattern: "⚠️"
        case .normal: "💚"
        case .inconclusive: "📊"
        }
    }
}
