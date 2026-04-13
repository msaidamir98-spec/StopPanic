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
/// - Light: тёплый ivory/cream, бежевые карточки,
///   коричневатый текст — как крафтовая бумага + лаванда
/// - Dark: глубокий космос (#0A0E1A) + неон — оригинальная тема Stillō
///
/// Ключевые ноу-хау бестселлеров:
/// 1. НИКОГДА чисто белый фон — только warm cream/ivory
/// 2. Текст — тёплый тёмно-коричневый, не чистый чёрный
/// 3. Карточки — ivory с мягким подтоном, не серый
/// 4. Акцентные цвета мягче в светлой теме
/// 5. Тени тёплые (коричневатые), не холодные
/// 6. Glass-эффект — warm tint, не холодный blur
@Observable
@MainActor
final class ThemeManager {
    // MARK: Lifecycle

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "system"
        currentTheme = AppTheme(rawValue: stored) ?? .system
    }

    // MARK: Internal

    /// Singleton — используется из SP.Colors для автоматического
    /// переключения всех 470+ ссылок на цвета без изменения кода экранов.
    static let shared = ThemeManager()

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
        isLight ? Color(hex: "F6F1E9") : Color(hex: "0A0E1A")
    }

    var bgSoft: Color {
        isLight ? Color(hex: "EDE5D8") : Color(hex: "111827")
    }

    var bgCard: Color {
        isLight ? Color(hex: "FAF5ED") : Color(hex: "1A1F35")
    }

    var bgCardHover: Color {
        isLight ? Color(hex: "F0E8DA") : Color(hex: "232847")
    }

    var bgElevated: Color {
        isLight ? Color(hex: "F2ECE2") : Color(hex: "0F1326")
    }

    // MARK: - Accent
    // Light: чуть теплее и мягче — лавандовый с тёплым подтоном
    // Dark: оригинальный фиолетовый неон

    var accent: Color {
        isLight ? Color(hex: "6B5CE7") : Color(hex: "6C63FF")
    }

    var accentSoft: Color {
        isLight ? Color(hex: "9B8FF0") : Color(hex: "8B83FF")
    }

    var accentGlow: Color {
        accent.opacity(isLight ? 0.15 : 0.3)
    }

    // MARK: - Semantic Colors

    var calm: Color {
        isLight ? Color(hex: "37AFA7") : Color(hex: "4ECDC4")
    }

    var calmSoft: Color {
        calm.opacity(isLight ? 0.14 : 0.15)
    }

    var warmth: Color {
        isLight ? Color(hex: "D87D52") : Color(hex: "FF9B71")
    }

    var danger: Color {
        isLight ? Color(hex: "D94F4F") : Color(hex: "FF6B6B")
    }

    var dangerGlow: Color {
        danger.opacity(isLight ? 0.15 : 0.3)
    }

    var success: Color {
        isLight ? Color(hex: "3DA84D") : Color(hex: "51CF66")
    }

    var warning: Color {
        isLight ? Color(hex: "D9AD2B") : Color(hex: "FFD43B")
    }

    // MARK: - Text
    // Light: тёплый тёмно-коричневый — НЕ чистый чёрный
    // Dark: белый (оригинал)

    var textPrimary: Color {
        isLight ? Color(hex: "2A1F12") : .white
    }

    var textSecondary: Color {
        isLight ? Color(hex: "564433") : .white.opacity(0.7)
    }

    var textTertiary: Color {
        isLight ? Color(hex: "8A7560") : .white.opacity(0.45)
    }

    var textOnAccent: Color { .white }

    // MARK: - Gradients

    var heroGradient: LinearGradient {
        isLight
            ? LinearGradient(
                colors: [Color(hex: "6B5CE7"), Color(hex: "9B6FCA")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color(hex: "6C63FF"), Color(hex: "9B59B6")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
    }

    var sosGradient: LinearGradient {
        LinearGradient(
            colors: [danger, isLight ? Color(hex: "C04040") : Color(hex: "FF4757")],
            startPoint: .top, endPoint: .bottom
        )
    }

    var calmGradient: LinearGradient {
        LinearGradient(
            colors: [calm, isLight ? Color(hex: "2E9690") : Color(hex: "45B7AA")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var warmGradient: LinearGradient {
        LinearGradient(
            colors: [warmth, isLight ? Color(hex: "C06838") : Color(hex: "FF7043")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var bgGradient: LinearGradient {
        LinearGradient(
            colors: [bg, bgSoft],
            startPoint: .top, endPoint: .bottom
        )
    }

    var shimmerGradient: LinearGradient {
        isLight
            ? LinearGradient(
                colors: [.clear, Color(hex: "8A7560").opacity(0.06), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            : LinearGradient(
                colors: [.clear, .white.opacity(0.08), .clear],
                startPoint: .leading, endPoint: .trailing
            )
    }

    // MARK: - Shadows
    // Light: тёплые коричневатые тени — не холодный чёрный
    // Dark: чёрные (оригинал)

    var shadowSoft: Color {
        isLight ? Color(hex: "8A7560").opacity(0.12) : .black.opacity(0.25)
    }

    var shadowMedium: Color {
        isLight ? Color(hex: "8A7560").opacity(0.18) : .black.opacity(0.4)
    }

    // MARK: - Glass Card
    // Light: тёплый полупрозрачный ivory — НЕ системный material (он белый!)
    // Dark: .ultraThinMaterial (оригинал)

    var glassMaterial: Material {
        isLight ? .ultraThinMaterial : .ultraThinMaterial
    }

    /// Для light-режима используем тёплую заливку вместо .material
    var glassBackground: AnyShapeStyle {
        if isLight {
            AnyShapeStyle(Color(hex: "EDE5D8").opacity(0.7))
        } else {
            AnyShapeStyle(.ultraThinMaterial)
        }
    }

    var glassBorder: Color {
        isLight ? Color(hex: "C9BAA5").opacity(0.5) : .white.opacity(0.12)
    }

    // MARK: - Ambient Background

    var ambientPrimaryOpacity: Double {
        isLight ? 0.10 : 0.08
    }

    var ambientSecondaryOpacity: Double {
        isLight ? 0.07 : 0.06
    }

    // MARK: Private

    private static let storageKey = "app_theme"
}
