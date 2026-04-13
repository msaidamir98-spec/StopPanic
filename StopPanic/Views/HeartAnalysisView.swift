import SwiftUI

// MARK: - HeartAnalysisView

/// Экран мониторинга пульса — ПА vs сердечная проблема.
/// ⚠️ Информационный инструмент, НЕ медицинское устройство.
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
                        if analysis.shouldCallEmergency { emergencyBanner }
                    }
                    breathingTestSection
                    monitoringButton
                    educationCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Мониторинг ❤️")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Private

    @StateObject
    private var service = HeartAnalysisService()
    @State
    private var showDisclaimer = true

    private var diagnosisColor: Color {
        switch service.currentAnalysis?.diagnosis {
        case .panicAttack: SP.Colors.warning
        case .likelyCardiac: SP.Colors.danger
        case .arrhythmia: .orange
        case .normal: SP.Colors.success
        default: SP.Colors.textTertiary
        }
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        Group {
            if showDisclaimer {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 18))
                        Text("Важная информация")
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)
                        Spacer()
                        Button {
                            withAnimation(SP.Anim.springFast) { showDisclaimer = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                    }
                    Text(
                        "Этот инструмент — информационный помощник, НЕ медицинское устройство. " +
                            "Он НЕ ставит диагнозы. При боли в груди, одышке или плохом самочувствии " +
                            "НЕМЕДЛЕННО вызовите скорую помощь (103 / 112)."
                    )
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
        }
    }

    // MARK: - Status Circle

    private var statusCircle: some View {
        VStack(spacing: 14) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(SP.Colors.bgCardHover, lineWidth: 12)
                    .frame(width: 180, height: 180)
                // Progress ring
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
                    Text(service.currentAnalysis?.diagnosis.rawValue ?? "Ожидание...")
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
            Text("Мониторинг пульса")
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)
        }
        .padding(.top, 8)
    }

    // MARK: - Emergency

    private var emergencyBanner: some View {
        VStack(spacing: 10) {
            Text("🚨 ВЫЗОВИТЕ СКОРУЮ")
                .font(SP.Typography.title3)
                .foregroundColor(.white)
            Text("103 (Россия) · 112 (Европа) · 911 (США)")
                .font(SP.Typography.headline)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                .fill(SP.Colors.danger)
        )
    }

    // MARK: - Breathing Test

    private var breathingTestSection: some View {
        Group {
            if service.isMonitoring {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "lungs.fill")
                            .foregroundColor(SP.Colors.calm)
                        Text("Дыхательный тест")
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)
                    }

                    Text(
                        "Если пульс снижается после дыхания 4-7-8 — это косвенно указывает на тревогу, а не на сердечную проблему."
                    )
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textSecondary)
                    .lineSpacing(3)

                    HStack(spacing: 12) {
                        Button {
                            SP.Haptic.light()
                            service.markPreBreathingHR()
                        } label: {
                            Text("📌 Зафиксировать пульс")
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
                            Text("✅ Проверить")
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
                            Text("Пульс снизился после дыхания")
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
                Text(service.isMonitoring ? "Остановить" : "Начать мониторинг")
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
                Text("Как это работает")
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            VStack(alignment: .leading, spacing: 8) {
                infoLine("heart.fill", "Считывает пульс через Apple Health / Watch")
                infoLine("waveform.path", "Анализирует регулярность ритма")
                infoLine("brain.head.profile", "Сравнивает паттерны тревоги и сердечных проблем")
                infoLine("lungs.fill", "Проверяет реакцию на дыхание")
            }

            Text(
                "Алгоритм основан на том, что при тревоге ритм ровный (синусовая тахикардия), " +
                    "а при сердечных проблемах — нерегулярный. Это НЕ замена ЭКГ или врача."
            )
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
                    Text(a.diagnosis.rawValue)
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text("Уверенность: \(Int(a.confidence * 100))%")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
            }

            if a.diagnosis == .panicAttack {
                differenceExplanation(
                    title: "Признаки тревоги (не сердечной проблемы):",
                    points: [
                        "Ритм регулярный (синусовая тахикардия)",
                        "ЧСС \(Int(a.heartRate)) BPM — характерно для тревоги",
                        "Паттерн: \(a.risePattern.rawValue)",
                        service.breathingResponseDetected
                            ? "Пульс реагирует на дыхание ✓"
                            : "Попробуйте дыхание для проверки",
                    ],
                    color: SP.Colors.warning
                )
            } else if a.diagnosis == .likelyCardiac || a.diagnosis == .arrhythmia {
                differenceExplanation(
                    title: "Признаки, требующие внимания врача:",
                    points: [
                        "Нерегулярный ритм (\(String(format: "%.0f%%", a.irregularity * 100)))",
                        "HRV: \(String(format: "%.0f", a.hrvMs)) мс",
                        "Не реагирует на дыхательные техники",
                        "Рекомендуем вызвать скорую",
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
            metricTile("❤️ ЧСС", value: "\(Int(a.heartRate))", unit: "BPM")
            metricTile("📈 HRV", value: String(format: "%.0f", a.hrvMs), unit: "мс")
            metricTile("🔀 Регулярность", value: String(format: "%.0f%%", (1 - a.irregularity) * 100), unit: "")
            metricTile("📊 Паттерн", value: a.risePattern.rawValue, unit: "")
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
                Text("Рекомендация")
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
        case .panicAttack: "😮‍💨"
        case .likelyCardiac: "🚨"
        case .arrhythmia: "⚠️"
        case .normal: "💚"
        case .inconclusive: "📊"
        }
    }
}
