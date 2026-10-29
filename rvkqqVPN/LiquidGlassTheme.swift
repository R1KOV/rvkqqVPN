// ============================================================================
// rvkqqVPN — 120Hz Liquid Glass Theme Engine (LiquidGlassTheme.swift)
// Author & License: rvkqq (All Rights Reserved / MIT Dual License)
// Themes: Cyberpunk Neon, Obsidian Dark, Pure Frost, Crimson Glass, Aurora
// Specs: .ultraThinMaterial, 0.5pt Specular Borders, 3D MeshGradient Palettes
// ============================================================================

import SwiftUI

public enum LiquidGlassThemePreset: String, CaseIterable, Identifiable {
    case obsidianDark = "Obsidian Dark"
    case cyberpunkNeon = "Cyberpunk Neon"
    case pureFrost = "Pure Frost"
    case crimsonGlass = "Crimson Glass"
    case aurora = "Aurora"

    public var id: String { rawValue }
}

public struct LiquidGlassPalette {
    public let name: String
    public let primaryText: Color
    public let secondaryText: Color
    public let accentColor: Color
    public let secondaryAccent: Color
    public let specularBorder: Color
    public let surfaceTint: Color
    public let backgroundGradient: LinearGradient
    public let orbMeshColors: [Color]
}

public final class LiquidGlassThemeManager: ObservableObject {
    @Published public var activeTheme: LiquidGlassThemePreset = .obsidianDark

    public init() {}

    public var currentPalette: LiquidGlassPalette {
        switch activeTheme {
        case .obsidianDark:
            return LiquidGlassPalette(
                name: "Obsidian Dark",
                primaryText: Color(red: 0.95, green: 0.97, blue: 1.0),
                secondaryText: Color(red: 0.60, green: 0.66, blue: 0.76),
                accentColor: Color(red: 0.22, green: 0.74, blue: 0.97),
                secondaryAccent: Color(red: 0.39, green: 0.40, blue: 0.95),
                specularBorder: Color.white.opacity(0.22),
                surfaceTint: Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.65),
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.04, blue: 0.09),
                        Color(red: 0.05, green: 0.08, blue: 0.16),
                        Color(red: 0.03, green: 0.05, blue: 0.11)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                orbMeshColors: [
                    Color(red: 0.08, green: 0.65, blue: 0.95),
                    Color(red: 0.24, green: 0.38, blue: 0.96),
                    Color(red: 0.06, green: 0.82, blue: 0.75)
                ]
            )
        case .cyberpunkNeon:
            return LiquidGlassPalette(
                name: "Cyberpunk Neon",
                primaryText: Color(red: 0.98, green: 0.98, blue: 1.0),
                secondaryText: Color(red: 0.72, green: 0.65, blue: 0.88),
                accentColor: Color(red: 0.0, green: 0.95, blue: 0.85),
                secondaryAccent: Color(red: 0.95, green: 0.20, blue: 0.68),
                specularBorder: Color(red: 0.0, green: 0.95, blue: 0.85).opacity(0.35),
                surfaceTint: Color(red: 0.09, green: 0.04, blue: 0.18).opacity(0.68),
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.10),
                        Color(red: 0.10, green: 0.03, blue: 0.20),
                        Color(red: 0.03, green: 0.06, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                orbMeshColors: [
                    Color(red: 0.0, green: 0.96, blue: 0.84),
                    Color(red: 0.94, green: 0.18, blue: 0.65),
                    Color(red: 0.45, green: 0.22, blue: 0.98)
                ]
            )
        case .pureFrost:
            return LiquidGlassPalette(
                name: "Pure Frost",
                primaryText: Color(red: 0.06, green: 0.09, blue: 0.16),
                secondaryText: Color(red: 0.35, green: 0.42, blue: 0.52),
                accentColor: Color(red: 0.01, green: 0.45, blue: 0.88),
                secondaryAccent: Color(red: 0.05, green: 0.65, blue: 0.68),
                specularBorder: Color.black.opacity(0.14),
                surfaceTint: Color.white.opacity(0.75),
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.97, blue: 1.0),
                        Color(red: 0.88, green: 0.93, blue: 0.99),
                        Color(red: 0.96, green: 0.98, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                orbMeshColors: [
                    Color(red: 0.05, green: 0.52, blue: 0.96),
                    Color(red: 0.20, green: 0.78, blue: 0.92),
                    Color(red: 0.36, green: 0.45, blue: 0.95)
                ]
            )
        case .crimsonGlass:
            return LiquidGlassPalette(
                name: "Crimson Glass",
                primaryText: Color(red: 0.99, green: 0.95, blue: 0.96),
                secondaryText: Color(red: 0.78, green: 0.62, blue: 0.66),
                accentColor: Color(red: 0.98, green: 0.26, blue: 0.38),
                secondaryAccent: Color(red: 0.96, green: 0.52, blue: 0.24),
                specularBorder: Color(red: 1.0, green: 0.40, blue: 0.48).opacity(0.30),
                surfaceTint: Color(red: 0.16, green: 0.04, blue: 0.07).opacity(0.68),
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.02, blue: 0.04),
                        Color(red: 0.16, green: 0.03, blue: 0.07),
                        Color(red: 0.06, green: 0.02, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                orbMeshColors: [
                    Color(red: 0.98, green: 0.22, blue: 0.36),
                    Color(red: 0.95, green: 0.50, blue: 0.20),
                    Color(red: 0.65, green: 0.12, blue: 0.38)
                ]
            )
        case .aurora:
            return LiquidGlassPalette(
                name: "Aurora",
                primaryText: Color(red: 0.94, green: 0.99, blue: 0.97),
                secondaryText: Color(red: 0.60, green: 0.76, blue: 0.70),
                accentColor: Color(red: 0.16, green: 0.92, blue: 0.65),
                secondaryAccent: Color(red: 0.22, green: 0.68, blue: 0.96),
                specularBorder: Color(red: 0.25, green: 0.95, blue: 0.72).opacity(0.28),
                surfaceTint: Color(red: 0.03, green: 0.13, blue: 0.12).opacity(0.66),
                backgroundGradient: LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.07, blue: 0.07),
                        Color(red: 0.03, green: 0.14, blue: 0.13),
                        Color(red: 0.02, green: 0.06, blue: 0.11)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                orbMeshColors: [
                    Color(red: 0.12, green: 0.92, blue: 0.64),
                    Color(red: 0.14, green: 0.66, blue: 0.96),
                    Color(red: 0.42, green: 0.88, blue: 0.36)
                ]
            )
        }
    }
}

public struct LiquidGlassCardModifier: ViewModifier {
    public let palette: LiquidGlassPalette

    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(palette.surfaceTint)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.specularBorder, lineWidth: 0.5)
            )
    }
}
