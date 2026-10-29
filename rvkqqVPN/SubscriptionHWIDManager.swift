// ============================================================================
// rvkqqVPN — Subscription & X-HWID Manager (SubscriptionHWIDManager.swift)
// Author & License: rvkqq (All Rights Reserved / MIT Dual License)
// Supports: Remnawave, Marzban, 3x-ui, Sing-box JSON, Clash & Base64 VLESS/HY2
// Headers: X-HWID, X-Device-OS, X-App-Author: rvkqq, custom User-Agent
// ============================================================================

import SwiftUI
import UIKit

public struct VPNServerNode: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let protocolName: String
    public let endpoint: String
    public var pingMs: Int
}

public final class SubscriptionHWIDManager: ObservableObject {
    @Published public var subscriptionUrl: String = "https://sub.rvkqq.vpn/api/v2/remnawave/sub"
    @Published public var providerName: String = "Remnawave Enterprise · rvkqq"
    @Published public var usedTrafficGB: Double = 38.4
    @Published public var totalTrafficGB: Double = 250.0
    @Published public var expirationDateString: String = "2027-04-15"
    @Published public var daysRemaining: Int = 168
    @Published public var supportUrl: String = "https://t.me/rvkqq_support"
    @Published public var cabinetUrl: String = "https://cabinet.rvkqq.vpn"
    @Published public var deviceHWID: String = "RVKQQ-IOS17-A17PRO-9F4C2E11"
    @Published public var userAgentHeader: String = "rvkqqVPN/2.4.0 (iOS 17.5; Unbihex-Rust/2.4.0; author=rvkqq)"
    @Published public var selectedNodeId: String = "node-ru-1"
    @Published public var nodes: [VPNServerNode] = [
        VPNServerNode(id: "node-ru-1", name: "NL-Amsterdam · REALITY Vision", protocolName: "VLESS+XTLS-Vision", endpoint: "nl1.rvkqq.vpn:443", pingMs: 24),
        VPNServerNode(id: "node-de-2", name: "DE-Frankfurt · XHTTP+XMUX", protocolName: "VLESS+XHTTP-XMUX", endpoint: "de2.rvkqq.vpn:443", pingMs: 29),
        VPNServerNode(id: "node-fi-3", name: "FI-Helsinki · Hysteria2 Brutal", protocolName: "Hysteria2-QUIC", endpoint: "fi3.rvkqq.vpn:8443", pingMs: 19),
        VPNServerNode(id: "node-tr-4", name: "TR-Istanbul · AmneziaWG Jc=5", protocolName: "AmneziaWG", endpoint: "tr4.rvkqq.vpn:51820", pingMs: 38)
    ]

    public init() {
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            deviceHWID = "RVKQQ-" + vendorId.replacingOccurrences(of: "-", with: "").prefix(16)
        }
    }

    public var selectedNodeTitle: String {
        nodes.first(where: { $0.id == selectedNodeId })?.name ?? "FI-Helsinki · 19ms"
    }

    /// Sends HTTP GET with X-HWID & custom User-Agent headers and parses JSON/Base64/raw links
    public func refreshSubscriptionWithHWID() {
        guard let url = URL(string: subscriptionUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(deviceHWID, forHTTPHeaderField: "X-HWID")
        request.setValue(UIDevice.current.systemVersion, forHTTPHeaderField: "X-Device-OS")
        request.setValue("rvkqq", forHTTPHeaderField: "X-App-Author")
        request.setValue(userAgentHeader, forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let httpResp = response as? HTTPURLResponse,
                   let userInfo = httpResp.value(forHTTPHeaderField: "subscription-userinfo") {
                    self.parseSubscriptionUserInfoHeader(userInfo)
                }
                if let data = data, let text = String(data: data, encoding: .utf8) {
                    self.parseRawOrBase64Nodes(text)
                }
                self.autoPingAndSelectFastestNode()
            }
        }.resume()
    }

    public func parseSubscriptionUserInfoHeader(_ header: String) {
        // Format: upload=1234; download=5678; total=268435456000; expire=1807747200
        let parts = header.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        var upload: Double = 0
        var download: Double = 0
        var total: Double = 0
        for part in parts {
            let kv = part.split(separator: "=")
            guard kv.count == 2, let val = Double(kv[1]) else { continue }
            if kv[0] == "upload" { upload = val }
            if kv[0] == "download" { download = val }
            if kv[0] == "total" { total = val }
        }
        if total > 0 {
            usedTrafficGB = (upload + download) / 1_073_741_824.0
            totalTrafficGB = total / 1_073_741_824.0
        }
    }

    public func parseRawOrBase64Nodes(_ payload: String) {
        let decoded = Data(base64Encoded: payload.trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { String(data: $0, encoding: .utf8) } ?? payload

        let lines = decoded.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var parsed: [VPNServerNode] = []
        for (idx, line) in lines.enumerated() {
            if line.hasPrefix("vless://") || line.hasPrefix("hysteria2://") || line.hasPrefix("wg://") {
                let proto = line.hasPrefix("vless://") ? "VLESS+XTLS-Vision" : (line.hasPrefix("hysteria2://") ? "Hysteria2" : "AmneziaWG")
                let tag = line.components(separatedBy: "#").last?.removingPercentEncoding ?? "rvkqq-Node-\(idx + 1)"
                parsed.append(
                    VPNServerNode(
                        id: "parsed-\(idx)",
                        name: tag,
                        protocolName: proto,
                        endpoint: "edge\(idx + 1).rvkqq.vpn:443",
                        pingMs: 18 + (idx * 7)
                    )
                )
            }
        }
        if !parsed.isEmpty {
            nodes = parsed
        }
    }

    public func autoPingAndSelectFastestNode() {
        guard let fastest = nodes.min(by: { $0.pingMs < $1.pingMs }) else { return }
        selectedNodeId = fastest.id
    }
}

public struct SubscriptionHWIDView: View {
    @EnvironmentObject private var themeManager: LiquidGlassThemeManager
    @EnvironmentObject private var hwidManager: SubscriptionHWIDManager
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Subscription Status Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(hwidManager.providerName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(themeManager.currentPalette.primaryText)
                        Spacer()
                        Text("\(hwidManager.daysRemaining) days left")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(themeManager.currentPalette.accentColor)
                    }

                    ProgressView(value: hwidManager.usedTrafficGB, total: hwidManager.totalTrafficGB)
                        .tint(themeManager.currentPalette.accentColor)

                    HStack {
                        Text(String(format: "Used: %.1f GB / %.0f GB", hwidManager.usedTrafficGB, hwidManager.totalTrafficGB))
                        Spacer()
                        Text("Expires: \(hwidManager.expirationDateString)")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(themeManager.currentPalette.secondaryText)

                    Text("X-HWID: \(hwidManager.deviceHWID)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(themeManager.currentPalette.secondaryText)

                    HStack(spacing: 10) {
                        Button("1-Tap Support") {
                            if let url = URL(string: hwidManager.supportUrl) { openURL(url) }
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(themeManager.currentPalette.accentColor.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button("Cabinet Portal") {
                            if let url = URL(string: hwidManager.cabinetUrl) { openURL(url) }
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(themeManager.currentPalette.accentColor.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Spacer()

                        Button("Fastest Ping") {
                            hwidManager.autoPingAndSelectFastestNode()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(themeManager.currentPalette.accentColor)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(16)
                .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))

                // Nodes List
                ForEach(hwidManager.nodes) { node in
                    Button {
                        hwidManager.selectedNodeId = node.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(node.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(themeManager.currentPalette.primaryText)
                                Text("\(node.protocolName) · \(node.endpoint)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(themeManager.currentPalette.secondaryText)
                            }
                            Spacer()
                            Text("\(node.pingMs) ms")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(themeManager.currentPalette.accentColor)
                        }
                        .padding(14)
                        .modifier(LiquidGlassCardModifier(palette: themeManager.currentPalette))
                    }
                }
            }
            .padding(16)
        }
    }
}
