import SwiftUI

// MARK: - AppTheme Compatibility Shim

// Maps legacy AppTheme references to the new SP.Colors design system.
// This ensures visual consistency across all screens.

enum AppTheme {
    static let background = SP.Colors.bg
    static let card = SP.Colors.bgCard
    static let primary = SP.Colors.accent
    static let secondary = SP.Colors.calm
    static let danger = SP.Colors.danger
    static let textMuted = SP.Colors.textTertiary
}
