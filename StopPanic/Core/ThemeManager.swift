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
///
/// Палитра вдохновлена Calm, Headspace, Finch, Rootd:
/// - Light: тёплый ivory/cream (#FBF7F0), мягкие бежевые карточки,
///   коричневатый текст — как крафтовая бумага + лаванда
/// - Dark: глубокий космос (#0A0E1A) + неон — оригинальная тема Stillō
///
/// Ключевые ноу-хау бестселлеров:
/// 1. НИКОГДА чисто белый фон — только warm cream/ivory (Calm: #FBF8F3)
/// 2. Текст — тёплый тёмно-коричневый (#2D2418), не чистый чёрный
/// 3. Карточки — ivory с лёгким персиковым оттенком, не серый
/// 4. Акцентные цвета мягче в светлой теме (меньше насыщенности)
/// 5. Тени тёплые (коричневатые), не холодные чёрные
/// 6. Glass-эффект — warm tint material, не холодный blur
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

    /// true когда активная тема — светлая
    var isLight: Bool {
        switch currentTheme {
        case .light: true
        case .dark: false
        case .system: UITraitCollection.current.userInterfaceStyle == .light
        }
    }

    // MARK: - Backgrounds
    // Light: Calm-стиль тёплый ivory → мягкий cream
    // Dark: глубокий космос (оригинал)

    var bg: Color {
        isLight ? Color(hex: "FBF7F0") : Color(hex: "0A0E1A")
    }

    var bgSoft: Color {
        isLight ? Color(hex: "F5EFE6") : Color(hex: "111827")
    }

    var bgCard: Color {
        isLight ? Color(hex: "FFFCF7") : Color(hex: "1A1F35")
    }

    var bgCardHover: Color {
        isLight ? Color(hex: "F8F2E8") : Color(hex: "232847")
    }

    var bgElevated: Color {
        isLight ? Color(hex: "FFF9F2") : Color(hex: "0F1326")
    }

    // MARK: - Accent
    // Light: чуть теплее и мягче — лавандовый с тёплым подтоном
    // Dark: оригинальный фиолетовый неон

    var accent: Color {
        isLight ? Color(hex: "7B6CF0") : Color(hex: "6C63FF")
    }

    var accentSoft: Color {
        isLight ? Color(hex: "A89BF5") : Color(hex: "8B83FF")
    }

    var accentGlow: Color {
        accent.opacity(isLight ? 0.12 : 0.3)
    }

    // MARK: - Semantic Colors
    // Light: приглушённые, «пастельные» — глазу комфортно
    // Dark: яркие неоновые (оригинал)

    var calm: Color {
        isLight ? Color(hex: "3DBDB5") : Color(hex: "4ECDC4")
    }

    var calmSoft: Color {
        calm.opacity(isLight ? 0.12 : 0.15)
    }

    var warmth: Color {
        isLight ? Color(hex: "E8895E") : Color(hex: "FF9B71")
    }

    var danger: Color {
        isLight ? Color(hex: "E85D5D") : Color(hex: "FF6B6B")
    }

    var dangerGlow: Color {
        danger.opacity(isLight ? 0.12 : 0.3)
    }

    var success: Color {
        isLight ? Color(hex: "43B558") : Color(hex: "51CF66")
    }

    var warning: Color {
        isLight ? Color(hex: "E8C034") : Color(hex: "FFD43B")
    }

    // MARK: - Text
    // Light: тёплый тёмно-коричневый (Headspace) — НЕ чистый чёрный
    // Dark: белый (оригинал)

    var textPrimary: Color {
        isLight ? Color(hex: "2D2418") : .white
    }

    var textSecondary: Color {
        isLight ? Color(hex: "5C4D3C") : .white.opacity(0.7)
    }

    var textTertiary: Color {
        isLight ? Color(hex: "8C7B68") : .white.opacity(0.45)
    }

    var textOnAccent: Color { .white }

    // MARK: - Gradients
    // Light: мягкие тёплые градиенты
    // Dark: яркие неоновые (оригинал)

    var heroGradient: LinearGradient {
        isLight
            ? LinearGradient(
                colors: [Color(hex: "7B6CF0"), Color(hex: "A878D0")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color(hex: "6C63FF"), Color(hex: "9B59B6")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
    }

    var sosGradient: LinearGradient {
        LinearGradient(
            colors: [danger, isLight ? Color(hex: "D04848") : Color(hex: "FF4757")],
            startPoint: .top, endPoint: .bottom
        )
    }

    var calmGradient: LinearGradient {
        LinearGradient(
            colors: [calm, isLight ? Color(hex: "35A89F") : Color(hex: "45B7AA")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var warmGradient: LinearGradient {
        LinearGradient(
            colors: [warmth, isLight ? Color(hex: "D07040") : Color(hex: "FF7043")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var bgGradient: LinearGradient {
        LinearGradient(
            colors: [bg, bgSoft],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Shadows
    // Light: тёплые коричневатые тени (секрет Calm) — не холодный чёрный
    // Dark: чёрные (оригинал)

    var shadowSoft: Color {
        isLight ? Color(hex: "8C7B68").opacity(0.1) : .black.opacity(0.25)
    }

    var shadowMedium: Color {
        isLight ? Color(hex: "8C7B68").opacity(0.15) : .black.opacity(0.4)
    }

    // MARK: - Glass Card
    // Light: тёплый .regularMaterial с ivory-оттенком
    // Dark: .ultraThinMaterial (оригинал)

    var glassMaterial: Material {
        isLight ? .regularMaterial : .ultraThinMaterial
    }

    var glassBorder: Color {
        isLight ? Color(hex: "D4C8B8").opacity(0.4) : .white.opacity(0.12)
    }

    // MARK: - Ambient Background
    // Light: мягкие пастельные орбы (Finch-стиль)
    // Dark: яркие неоновые (оригинал)

    var ambientPrimaryOpacity: Double {
        isLight ? 0.06 : 0.08
    }

    var ambientSecondaryOpacity: Double {
        isLight ? 0.04 : 0.06
    }

    // MARK: Private

    private static let storageKey = "app_theme"
}
