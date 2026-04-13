import Observation
import SwiftUI

// MARK: - AppTheme

/// Доступные темы приложения
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    // MARK: Internal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Авто"
        case .dark: "Тёмная"
        case .light: "Светлая"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .dark: "moon.fill"
        case .light: "sun.max.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

// MARK: - ThemeManager

/// Центральный менеджер темы — @Observable для SwiftUI.
/// Хранит выбор пользователя в UserDefaults.
@Observable
@MainActor
final class ThemeManager {
    // MARK: Lifecycle

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "system"
        currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    // MARK: Internal

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.storageKey)
        }
    }

    /// Возвращает ColorScheme для .preferredColorScheme()
    var preferredColorScheme: ColorScheme? {
        currentTheme.colorScheme
    }

    /// true когда активная тема — светлая (для расчёта цветов)
    var isLight: Bool {
        switch currentTheme {
        case .light: true
        case .dark: false
        case .system: UITraitCollection.current.userInterfaceStyle == .light
        }
    }

    // MARK: - Color Palette (dynamic)

    // Backgrounds
    var bg: Color { isLight ? Color(hex: "F5F5FA") : Color(hex: "0A0E1A") }
    var bgSoft: Color { isLight ? Color(hex: "EEEEF5") : Color(hex: "111827") }
    var bgCard: Color { isLight ? Color.white : Color(hex: "1A1F35") }
    var bgCardHover: Color { isLight ? Color(hex: "F0F0F8") : Color(hex: "232847") }
    var bgElevated: Color { isLight ? Color(hex: "FFFFFF") : Color(hex: "0F1326") }

    // Accent (same in both themes)
    var accent: Color { Color(hex: "6C63FF") }
    var accentSoft: Color { Color(hex: "8B83FF") }
    var accentGlow: Color { Color(hex: "6C63FF").opacity(isLight ? 0.15 : 0.3) }

    // Semantic
    var calm: Color { Color(hex: "4ECDC4") }
    var calmSoft: Color { Color(hex: "4ECDC4").opacity(isLight ? 0.1 : 0.15) }
    var warmth: Color { Color(hex: "FF9B71") }
    var danger: Color { Color(hex: "FF6B6B") }
    var dangerGlow: Color { Color(hex: "FF6B6B").opacity(isLight ? 0.15 : 0.3) }
    var success: Color { Color(hex: "51CF66") }
    var warning: Color { Color(hex: "FFD43B") }

    // Text
    var textPrimary: Color { isLight ? Color(hex: "1A1A2E") : .white }
    var textSecondary: Color { isLight ? Color(hex: "1A1A2E").opacity(0.65) : .white.opacity(0.7) }
    var textTertiary: Color { isLight ? Color(hex: "1A1A2E").opacity(0.4) : .white.opacity(0.45) }
    var textOnAccent: Color { .white }

    // Gradients
    var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(hex: "9B59B6")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var sosGradient: LinearGradient {
        LinearGradient(
            colors: [danger, Color(hex: "FF4757")],
            startPoint: .top, endPoint: .bottom
        )
    }

    var calmGradient: LinearGradient {
        LinearGradient(
            colors: [calm, Color(hex: "45B7AA")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var warmGradient: LinearGradient {
        LinearGradient(
            colors: [warmth, Color(hex: "FF7043")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var bgGradient: LinearGradient {
        LinearGradient(
            colors: [bg, bgSoft],
            startPoint: .top, endPoint: .bottom
        )
    }

    // Shadows
    var shadowSoft: Color { isLight ? .black.opacity(0.08) : .black.opacity(0.25) }
    var shadowMedium: Color { isLight ? .black.opacity(0.12) : .black.opacity(0.4) }

    // Glass card material
    var glassMaterial: Material { isLight ? .thinMaterial : .ultraThinMaterial }

    var glassBorder: Color { isLight ? .black.opacity(0.06) : .white.opacity(0.12) }

    // MARK: Private

    private static let storageKey = "app_theme"
}
