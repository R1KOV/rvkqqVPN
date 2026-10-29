// ============================================================================
// rvkqqVPN — Global Anti-DPI & TLS Fragmentation Tuner (AntiDPIEngineView.swift)
// Author & License: rvkqq (All Rights Reserved / MIT Dual License)
// Features:
//   - TLS ClientHello Slicing / Fragmentation Byte Sliders & Delay Interval
//   - Exact Chrome HTTP/2 SETTINGS / WINDOW_UPDATE (6291456) + Custom GREASE
//   - XHTTP (packet-up / stream-up / stream-one + XMUX) & XUDP Full Cone NAT
// ============================================================================

import SwiftUI

public struct AntiDPIEngineView: View {
    @EnvironmentObject private var themeManager: LiquidGlassThemeManager
    @EnvironmentObject private var tunnelController: UnbihexTunnelController

    private let xhttpModes = [
        "packet-up + XMUX",
        "stream-up + XMUX",
        "stream-one + XMUX"
    ]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TLS ClientHello Slicing & Fragmentation")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(themeManager.currentPalette.primaryText)

                    HStack {
                        Text("Min Fragment Bytes")
                        Spacer()
                        Text("\(Int(tunnelController.tlsFragmentMinBytes)) B")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Slider(value: $tunnelController.tlsFragmentMinBytes, in: 2...64, step: 1)
                        .tint(themeManager.currentPalette.accentColor)

                    HStack {
                        Text("Max Fragment Bytes")
                        Spacer()
                        Text("\(Int(tunnelController.tlsFragmentMaxBytes)) B")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Slider(value: $tunnelController.tlsFragmentMaxBytes, in: 16...128, step: 1)
                        .tint(themeManager.currentPalette.accentColor)

                    HStack {
                        Text("Inter-Fragment Jitter Delay")
                        Spacer()
                        Text("\(Int(tunnelController.tlsFragmentDelayMs)) ms")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Slider(value: $tunnelController.tlsFragmentDelayMs, in: 1...30, step: 1)
                        .tint(themeManager.currentPalette.accentColor)
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                VStack(alignment: .leading, spacing: 10) {
                    Text("XHTTP + XMUX & XUDP Full Cone NAT")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(themeManager.currentPalette.primaryText)

                    Picker("XHTTP Mode", selection: $tunnelController.xhttpMode) {
                        ForEach(xhttpModes, id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Chrome H2 WINDOW_UPDATE")
                        Spacer()
                        Text("6,291,456 · GREASE 0x5A5A")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    HStack {
                        Text("XUDP GlobalID (Mux.Cool)")
                        Spacer()
                        Text(tunnelController.xudpGlobalID)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Button {
                        tunnelController.applyZeroDropReload(reason: "Anti-DPI Tuner Update")
                    } label: {
                        Text("Hot-Reload Unbihex (Instance::reload)")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(themeManager.currentPalette.accentColor)
                            .foregroundStyle(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))
            }
            .padding(16)
        }
    }
}
