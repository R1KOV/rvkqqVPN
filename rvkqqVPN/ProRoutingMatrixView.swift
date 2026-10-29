// ============================================================================
// rvkqqVPN — Pro Routing Matrix, FakeIP/DNS & Core Logs (ProRoutingMatrixView.swift)
// Author & License: rvkqq (All Rights Reserved / MIT Dual License)
// Features:
//   - Succinct Trie (.srs) & Disk-Streamed geosite.dat/geoip.dat Rule Matrix
//   - MTU Slider (1280-1500), FakeIP (198.18.0.0/15) & Strict DoH Tuner
//   - Live NEPacketTunnelProvider RAM Telemetry & Unbihex Core Log Stream
// ============================================================================

import SwiftUI

public struct ProRoutingRuleItem: Identifiable {
    public let id = UUID()
    public let rulePattern: String
    public let engineSource: String
    public let outboundAction: String
}

public struct ProRoutingMatrixView: View {
    @EnvironmentObject private var themeManager: LiquidGlassThemeManager
    @EnvironmentObject private var tunnelController: UnbihexTunnelController

    private let routingRules: [ProRoutingRuleItem] = [
        ProRoutingRuleItem(rulePattern: "geosite:ru-available-only-inside", engineSource: "runetfreedom.srs", outboundAction: "DIRECT"),
        ProRoutingRuleItem(rulePattern: "domain-suffix: .ru / .рф / .su", engineSource: "mmap geosite.dat", outboundAction: "DIRECT"),
        ProRoutingRuleItem(rulePattern: "geoip:ru, geoip:private", engineSource: "mmap geoip.dat", outboundAction: "DIRECT"),
        ProRoutingRuleItem(rulePattern: "geosite:category-ads-all, udp:443", engineSource: "Succinct Trie .srs", outboundAction: "BLOCK"),
        ProRoutingRuleItem(rulePattern: "final: all-remaining-traffic", engineSource: "Unbihex XTLS Vision", outboundAction: "PROXY")
    ]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // MTU & FakeIP / DoH Tuner
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tunnel MTU & FakeIP / Strict DoH Tuner")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(themeManager.currentPalette.primaryText)

                    HStack {
                        Text("Kernel utun MTU")
                        Spacer()
                        Text("\(Int(tunnelController.mtuSize)) bytes")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Slider(value: $tunnelController.mtuSize, in: 1280...1500, step: 10)
                        .tint(themeManager.currentPalette.accentColor)

                    Toggle("FakeIP Synthesis (198.18.0.0/15)", isOn: $tunnelController.fakeIpEnabled)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(themeManager.currentPalette.primaryText)
                        .tint(themeManager.currentPalette.accentColor)

                    Text("DoH: \(tunnelController.strictDohServer)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(themeManager.currentPalette.accentColor)
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                // Karing-Killer Routing Matrix
                VStack(alignment: .leading, spacing: 8) {
                    Text("Succinct Trie (.srs) & Disk-Streaming Geo Matrix")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(themeManager.currentPalette.primaryText)

                    ForEach(routingRules) { rule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.rulePattern)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(themeManager.currentPalette.primaryText)
                                Text(rule.engineSource)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(themeManager.currentPalette.secondaryText)
                            }
                            Spacer()
                            Text(rule.outboundAction)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(themeManager.currentPalette.accentColor)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                // Real-time Core Logs
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unbihex Core Live Telemetry Logs")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(themeManager.currentPalette.primaryText)

                    ForEach(tunnelController.coreLogs.prefix(6), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.secondaryText)
                    }
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))
            }
            .padding(16)
        }
    }
}
