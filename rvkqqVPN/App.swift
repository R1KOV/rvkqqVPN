// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — Root Application Coordinator (App.swift)
// Author & License: rvkqq (com.rvkqq.iflap)
// Compatible with ALL iPhones (iOS 15.0 - iOS 18.0+, 60Hz & 120Hz ProMotion)
// ============================================================================

import Foundation
import SwiftUI

public enum GameTab: String, CaseIterable, Identifiable {
    case play = "🎮 Играть"
    case iphones = "📱 Айфоны"
    case upgrades = "⚡ Тюнинг"
    case quests = "🏆 Квесты"
    case settings = "⚙️ Опции"

    public var id: String { rawValue }
}

@main
public struct rvkqqVPNApp: App {
    @StateObject private var saveManager = GameSaveManager()
    @State private var selectedTab: GameTab = .play

    public init() {}

    public var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.02, green: 0.04, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Global Cash & Model Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iFlap: БИТВА АЙФОНОВ")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(saveManager.currentIphone.name) · Рекорд: \(saveManager.highScorePipes) труб")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }

                        Spacer()

                        Text("💵 $\(saveManager.cash)")
                            .font(.system(size: 15, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.05, green: 0.08, blue: 0.16))

                    // Main Active View
                    Group {
                        switch selectedTab {
                        case .play:
                            FlappyIphoneArenaView()
                        case .iphones:
                            IPhoneShopView()
                        case .upgrades:
                            UpgradeWorkshopView()
                        case .quests:
                            QuestsListView()
                        case .settings:
                            GameSettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Bottom Tab Bar
                    HStack(spacing: 4) {
                        ForEach(GameTab.allCases) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTab == tab ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedTab == tab ? Color.cyan : Color.white.opacity(0.06))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(red: 0.05, green: 0.08, blue: 0.16))
                }
            }
            .environmentObject(saveManager)
            .preferredColorScheme(.dark)
            .onAppear {
                NativeSoundEngine.shared.sfxEnabled = saveManager.sfxEnabled
                NativeSoundEngine.shared.hapticsEnabled = saveManager.hapticsEnabled
                NativeSoundEngine.shared.updateMusicState(enabled: saveManager.musicEnabled)
            }
        }
    }
}
