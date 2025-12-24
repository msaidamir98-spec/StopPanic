import SwiftUI

/// Экран «Радар паники» — анализ сердечного ритма ПА vs Инфаркт
struct HeartAnalysisView: View {
    @StateObject private var service = HeartAnalysisService()
    @State private var showDisclaimer = true

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    disclaimerCard
                    statusCircle
                    if let analysis = service.currentAnalysis {
                        diagnosisCard(analysis)
                        metricsGrid(analysis)
                        recommendationCard(analysis.recommendation)
                        if analysis.shouldCallEmergency { emergencyBanner }
                    }
                    monitoringButton
                }
                .padding(16)
            }
        }
        .navigationTitle("Анализ ❤️")
    }

    // MARK: - Disclaimer

    private var disclaimerCard: some View {
        Group {
            if showDisclaimer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Важно")
                            .font(.headline).foregroundColor(.white)
                        Spacer()
                        Button { withAnimation { showDisclaimer = false } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    Text("Этот анализ НЕ заменяет медицинскую диагностику. При подозрении на сердечную проблему НЕМЕДЛЕННО вызовите скорую (103/112).")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(16)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Status

    private var statusCircle: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 14)
                    .frame(width: 180, height: 180)
                Circle()
                    .trim(from: 0, to: service.currentAnalysis?.confidence ?? 0)
                    .stroke(diagnosisColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Image(systemName: service.isMonitoring ? "heart.fill" : "heart")
                        .font(.system(size: 40))
                        .foregroundColor(diagnosisColor)
                        .symbolEffect(.pulse, isActive: service.isMonitoring)
                    Text(service.currentAnalysis?.diagnosis.rawValue ?? "Ожидание...")
                        .font(.headline).foregroundColor(.white)
                    if let hr = service.currentAnalysis?.heartRate {
                        Text("\(Int(hr)) BPM")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            Text("Анализ сердечного ритма")
                .font(.title3.bold()).foregroundColor(.white)
        }
        .padding(.top, 12)
    }

    // MARK: - Diagnosis

    private func diagnosisCard(_ a: HeartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(a.diagnosis == .panicAttack ? "😮‍💨" : a.diagnosis == .likelyCardiac ? "🚨" : "📊")
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(a.diagnosis.rawValue)
                        .font(.headline).foregroundColor(.white)
                    Text("Уверенность: \(Int(a.confidence * 100))%")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }

            // Пояснение различий
            if a.diagnosis == .panicAttack {
                differenceExplanation(
                    title: "Почему это ПА, а не инфаркт:",
                    points: [
                        "✅ Ритм регулярный (синусовая тахикардия)",
                        "✅ ЧСС \(Int(a.heartRate)) BPM — типично для ПА",
                        "✅ Паттерн: \(a.risePattern.rawValue)",
                        service.breathingResponseDetected
                            ? "✅ Пульс реагирует на дыхание"
                            : "⏳ Попробуйте дыхание для подтверждения"
                    ]
                )
            } else if a.diagnosis == .likelyCardiac || a.diagnosis == .arrhythmia {
                differenceExplanation(
                    title: "Признаки сердечной проблемы:",
                    points: [
                        "⚠️ Ритм нерегулярный (\(String(format: "%.0f%%", a.irregularity * 100)))",
                        "⚠️ HRV хаотичен: \(String(format: "%.0f", a.hrvMs)) мс",
                        "⚠️ Не реагирует на дыхательные техники",
                        "🚨 Рекомендуется вызвать скорую"
                    ]
                )
            }
        }
        .padding(16)
        .background(diagnosisColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(diagnosisColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func differenceExplanation(title: String, points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.9))
            ForEach(points, id: \.self) { point in
                Text(point)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Metrics

    private func metricsGrid(_ a: HeartAnalysis) -> some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            metricTile("❤️ ЧСС", value: "\(Int(a.heartRate))", unit: "BPM")
            metricTile("📈 HRV", value: String(format: "%.0f", a.hrvMs), unit: "мс")
            metricTile("🔀 Нерегулярность", value: String(format: "%.0f%%", a.irregularity * 100), unit: "")
            metricTile("📊 Паттерн", value: a.risePattern.rawValue, unit: "")
        }
    }

    private func metricTile(_ title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.white.opacity(0.6))
            Text(value).font(.headline.bold()).foregroundColor(.white)
            if !unit.isEmpty {
                Text(unit).font(.caption2).foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recommendation

    private func recommendationCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Рекомендация").font(.headline).foregroundColor(.white)
            Text(text).font(.body).foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Emergency

    private var emergencyBanner: some View {
        VStack(spacing: 8) {
            Text("🚨 ВЫЗОВИТЕ СКОРУЮ").font(.title3.bold()).foregroundColor(.white)
            Text("103 (Россия) · 112 (Европа) · 911 (США)")
                .font(.headline).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Controls

    private var monitoringButton: some View {
        VStack(spacing: 12) {
            Button {
                if service.isMonitoring {
                    service.stopMonitoring()
                } else {
                    service.startMonitoring()
                }
            } label: {
                HStack {
                    Image(systemName: service.isMonitoring ? "stop.fill" : "heart.fill")
                    Text(service.isMonitoring ? "Остановить мониторинг" : "Начать мониторинг")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(service.isMonitoring ? AppTheme.danger : AppTheme.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if service.isMonitoring {
                Button {
                    service.markPreBreathingHR()
                } label: {
                    Text("🫁 Начать дыхание (для теста)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondary)
                }

                Button {
                    service.checkBreathingResponse()
                } label: {
                    Text("✅ Проверить реакцию на дыхание")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var diagnosisColor: Color {
        switch service.currentAnalysis?.diagnosis {
        case .panicAttack:   return AppTheme.primary
        case .likelyCardiac: return .red
        case .arrhythmia:    return .orange
        case .normal:        return AppTheme.secondary
        default:             return .gray
        }
    }
}

#Preview { NavigationStack { HeartAnalysisView() } }
