import SwiftUI
import WatchKit

// MARK: - Premium Watch Breathing View

/// Дыхательная техника 4-7-8 для Apple Watch
/// Premium: анимированный круг с градиентом, haptic feedback, cycle dots
struct WatchBreathingView: View {
    @ObservedObject var connectivity: WatchConnectionManager
    @State private var phase: BreathPhase = .idle
    @State private var breathScale: CGFloat = 0.4
    @State private var countdown: Int = 0
    @State private var cycleCount: Int = 0
    @State private var isRunning = false
    @State private var ringProgress: CGFloat = 0
    @State private var glowIntensity: Double = 0.2
    
    private let totalCycles = 4
    
    enum BreathPhase: String {
        case idle = "Готов к дыханию"
        case inhale = "Вдох"
        case hold = "Задержка"
        case exhale = "Выдох"
        case done = "Отлично!"
    }
    
    private var phaseColor: Color {
        switch phase {
        case .idle: return .cyan
        case .inhale: return .blue
        case .hold: return .indigo
        case .exhale: return .purple
        case .done: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Phase label
            Text(phase.rawValue)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(phaseColor)
                .animation(.easeInOut(duration: 0.3), value: phase)
            
            Spacer(minLength: 2)
            
            // MARK: - Breathing Circle
            ZStack {
                // Outer ring glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(0.2 * glowIntensity), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [phaseColor, phaseColor.opacity(0.3)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 108, height: 108)
                    .rotationEffect(.degrees(-90))
                
                // Background ring
                Circle()
                    .stroke(phaseColor.opacity(0.1), lineWidth: 3)
                    .frame(width: 108, height: 108)
                
                // Breathing blob
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                phaseColor.opacity(0.5),
                                phaseColor.opacity(0.2),
                                phaseColor.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(breathScale)
                
                // Inner glass
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .scaleEffect(breathScale)
                    .opacity(0.5)
                
                // Content
                if phase == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce)
                } else if phase != .idle {
                    Text("\(countdown)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(countdown)))
                } else {
                    Image(systemName: "wind")
                        .font(.system(size: 20))
                        .foregroundStyle(phaseColor.opacity(0.7))
                }
            }
            
            Spacer(minLength: 2)
            
            // MARK: - Cycle Dots
            if isRunning || phase == .done {
                HStack(spacing: 6) {
                    ForEach(0..<totalCycles, id: \.self) { i in
                        Circle()
                            .fill(i < cycleCount ? phaseColor : Color.white.opacity(0.15))
                            .frame(width: 6, height: 6)
                            .shadow(color: i < cycleCount ? phaseColor.opacity(0.5) : .clear, radius: 2)
                            .animation(.spring(duration: 0.4), value: cycleCount)
                    }
                }
            }
            
            // MARK: - Button
            Button {
                WKInterfaceDevice.current().play(.click)
                if isRunning {
                    stopBreathing()
                } else {
                    startBreathing()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isRunning ? "xmark.circle.fill" : "play.circle.fill")
                        .font(.caption)
                    Text(buttonLabel)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .tint(isRunning ? .red.opacity(0.8) : phaseColor)
        }
        .padding(.vertical, 4)
        .navigationTitle("Дыхание")
    }
    
    private var buttonLabel: String {
        switch phase {
        case .done: return "Ещё раз"
        case .idle: return "Начать 4-7-8"
        default: return "Остановить"
        }
    }
    
    // MARK: - Breathing Logic
    
    private func startBreathing() {
        isRunning = true
        cycleCount = 0
        phase = .idle
        runCycle()
    }
    
    private func stopBreathing() {
        isRunning = false
        phase = .idle
        withAnimation(.easeOut(duration: 0.5)) {
            breathScale = 0.4
            ringProgress = 0
            glowIntensity = 0.2
        }
    }
    
    private func runCycle() {
        guard isRunning, cycleCount < totalCycles else {
            finishSession()
            return
        }
        
        // === ВДОХ 4 сек ===
        phase = .inhale
        countdown = 4
        WKInterfaceDevice.current().play(.start)
        
        withAnimation(.easeInOut(duration: 4)) {
            breathScale = 1.0
            glowIntensity = 1.0
        }
        animateRingProgress(duration: 4)
        
        countDown(from: 4) { [self] in
            guard isRunning else { return }
            
            // === ЗАДЕРЖКА 7 сек ===
            phase = .hold
            countdown = 7
            WKInterfaceDevice.current().play(.click)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                glowIntensity = 0.6
            }
            animateRingProgress(duration: 7)
            
            countDown(from: 7) { [self] in
                guard isRunning else { return }
                
                // === ВЫДОХ 8 сек ===
                phase = .exhale
                countdown = 8
                WKInterfaceDevice.current().play(.directionDown)
                
                withAnimation(.easeInOut(duration: 8)) {
                    breathScale = 0.4
                    glowIntensity = 0.2
                }
                animateRingProgress(duration: 8)
                
                countDown(from: 8) { [self] in
                    cycleCount += 1
                    WKInterfaceDevice.current().play(.click)
                    runCycle()
                }
            }
        }
    }
    
    private func finishSession() {
        phase = .done
        isRunning = false
        WKInterfaceDevice.current().play(.success)
        
        withAnimation(.spring(duration: 0.6)) {
            breathScale = 0.7
            ringProgress = 1.0
            glowIntensity = 0.5
        }
        
        connectivity.notifySessionCompleted()
    }
    
    // MARK: - Helpers
    
    private func countDown(from value: Int, completion: @escaping () -> Void) {
        countdown = value
        guard value > 0, isRunning else {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard isRunning else { return }
            countDown(from: value - 1, completion: completion)
        }
    }
    
    private func animateRingProgress(duration: Double) {
        withAnimation(.linear(duration: 0.1)) {
            ringProgress = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: duration)) {
                ringProgress = 1.0
            }
        }
    }
}

#Preview {
    WatchBreathingView(connectivity: WatchConnectionManager.shared)
}
