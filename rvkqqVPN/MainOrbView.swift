// ============================================================================
// rvkqqVPN — 120Hz Interactive 3D Liquid Glass Orb View (MainOrbView.swift)
// Author & License: rvkqq (All Rights Reserved / MIT Dual License)
// Features:
//   - TimelineView(.animation) 120Hz ProMotion Liquid Glass Orb with specular rim
//   - 1-Click Country Anti-DPI Selector (RU Anti-ТСПУ, IR Filternet, CN GFW, etc.)
//   - Live NEPacketTunnelProvider RAM Gauge (<18MB Guard) & XUDP GlobalID status
// ============================================================================

import SwiftUI

public enum AntiDPICountryPreset: String, CaseIterable, Identifiable {
    case ruAntiTspu = "RU · Anti-ТСПУ (runetfreedom)"
    case irFilternet = "IR · Filternet (XHTTP+XMUX)"
    case cnGfw = "CN · GFW (REALITY+Vision)"
    case byBeltelecom = "BY · Beltelecom Anti-DPI"
    case tmTurkmen = "TM · Turkmen (Fragment+QUIC)"
    case trBtk = "TR · BTK Bypass"
    case globalOptimal = "Global · Zero-Overhead"

    public var id: String { rawValue }
}

public struct MainOrbView: View {
    @EnvironmentObject private var themeManager: LiquidGlassThemeManager
    @EnvironmentObject private var tunnelController: UnbihexTunnelController
    @EnvironmentObject private var hwidManager: SubscriptionHWIDManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 120Hz Interactive Liquid Glass 3D Orb
                TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    Button {
                        tunnelController.toggleTunnel()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            themeManager.currentPalette.orbMeshColors[0].opacity(tunnelController.isConnected ? 0.88 : 0.32),
                                            themeManager.currentPalette.orbMeshColors[1].opacity(tunnelController.isConnected ? 0.55 : 0.18),
                                            themeManager.currentPalette.orbMeshColors[2].opacity(0.05)
                                        ],
                                        center: UnitPoint(
                                            x: 0.5 + 0.12 * cos(t * 1.6),
                                            y: 0.5 + 0.12 * sin(t * 1.3)
                                        ),
                                        startRadius: 12,
                                        endRadius: 125
                                    )
                                )
                                .frame(width: 210, height: 210)
                                .overlay(
                                    Circle()
                                        .strokeBorder(themeManager.currentPalette.specularBorder, lineWidth: 0.5)
                                )

                            VStack(spacing: 6) {
                                Text(tunnelController.isConnected ? "PROTECTED" : "TAP TO CONNECT")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeManager.currentPalette.primaryText)

                                Text(tunnelController.isConnected ? "XTLS Vision · 300s Splice" : "Unbihex Core Ready")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                                Text("Reload #\(tunnelController.reloadGeneration)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(themeManager.currentPalette.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                // 1-Click Country Anti-DPI Preset Selector
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("1-Click Country Anti-DPI Preset")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeManager.currentPalette.primaryText)
                        Spacer()
                        Text("Zero-Drop IPC")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }

                    Picker("Country Preset", selection: Binding(
                        get: { tunnelController.selectedPreset },
                        set: { tunnelController.applyCountryPreset($0) }
                    )) {
                        ForEach(AntiDPICountryPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(themeManager.currentPalette.accentColor)
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                // Active Node & <18MB NE Memory Guard Telemetry
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NE RAM Footprint")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(themeManager.currentPalette.secondaryText)
                        Text(String(format: "%.2f / 18.0 MB", tunnelController.ramFootprintMB))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.primaryText)
                        Text("Succinct .srs + mmap")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fastest Node")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(themeManager.currentPalette.secondaryText)
                        Text(hwidManager.selectedNodeTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(themeManager.currentPalette.primaryText)
                            .lineLimit(1)
                        Text("XUDP GlobalID Active")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
