import SwiftUI

// MARK: - Accessibility Helpers

// Полноценная поддержка VoiceOver, Dynamic Type, Reduce Motion.
// Каждый элемент UI должен быть доступен.

extension View {
    /// Adds accessibility label and hint for panic-related actions
    func spAccessible(label: String, hint: String = "", isButton: Bool = false) -> some View {
        accessibilityLabel(Text(label))
            .accessibilityHint(hint.isEmpty ? Text("") : Text(hint))
            .accessibilityAddTraits(isButton ? .isButton : [])
    }

    /// Respects Reduce Motion preference
    func spReduceMotion(animation: Animation?, value: some Equatable) -> some View {
        modifier(ReduceMotionModifier(animation: animation, value: value))
    }

    /// High contrast border for accessibility
    func spHighContrastBorder(color: Color = .white.opacity(0.3)) -> some View {
        modifier(HighContrastBorder(borderColor: color))
    }
}

// MARK: - ReduceMotionModifier

struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion)
    var reduceMotion

    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - HighContrastBorder

struct HighContrastBorder: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor)
    var diffWithoutColor

    let borderColor: Color

    func body(content: Content) -> some View {
        if diffWithoutColor {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
        } else {
            content
        }
    }
}

// MARK: - AccessibleBreathingModifier

struct AccessibleBreathingModifier: ViewModifier {
    let phase: String
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isActive ? "Фаза дыхания: \(phase)" : "Дыхательная сессия не начата")
            .accessibilityHint(isActive ? "Следуйте инструкциям на экране" : "Нажмите кнопку Начать для запуска сессии")
    }
}

// MARK: - Dynamic Type Scaling

extension SP.Typography {
    /// Scaled font that respects Dynamic Type
    static func scaled(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - SOSAccessibilityAnnouncement

enum SOSAccessibilityAnnouncement {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    static func announceSOSStarted() {
        announce("Экстренная помощь активирована. Следуйте инструкциям на экране.")
    }

    static func announcePhaseChange(_ phase: String) {
        announce(phase)
    }

    static func announceSessionComplete() {
        announce("Сессия завершена. Молодец!")
    }
}
