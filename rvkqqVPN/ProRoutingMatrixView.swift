// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — Quests & Settings Views
// Author & License: rvkqq (com.rvkqq.iflap)
// ============================================================================

import Foundation
import SwiftUI

public struct QuestsListView: View {
    @EnvironmentObject public var save: GameSaveManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("🏆 Квесты и Задания Купертино")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Выполняй задания в полёте и забирай крупные денежные бонусы на покупку новых iPhone!")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                ForEach(save.quests) { q in
                    let prog = save.questProgress(q)
                    let claimed = save.claimedQuestIds.contains(q.id)
                    let ready = prog >= q.target && !claimed

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(q.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text(q.desc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                save.claimQuest(q)
                            }) {
                                Text(claimed ? "✅ ПОЛУЧЕНО" : (ready ? "ЗАБРАТЬ +$\(q.reward)" : "+$\(q.reward)"))
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(claimed ? Color.gray : (ready ? Color.green : Color.yellow.opacity(0.6)))
                                    .cornerRadius(10)
                            }
                            .disabled(!ready)
                        }

                        ProgressView(value: Double(min(prog, q.target)), total: Double(q.target))
                            .accentColor(.green)

                        Text("Прогресс: \(min(prog, q.target)) / \(q.target)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding(14)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ready ? Color.green : Color.white.opacity(0.1), lineWidth: ready ? 2 : 1)
                    )
                }
            }
            .padding(16)
        }
    }
}

public struct GameSettingsView: View {
    @EnvironmentObject public var save: GameSaveManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("⚙️ Настройки и Сложность")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                // Difficulty Selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Режим Сложности")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.cyan)

                    ForEach(GameDifficultyId.allCases) { diff in
                        let active = save.difficulty == diff
                        Button(action: {
                            save.difficulty = diff
                            save.saveToDisk()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(diff.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(diff.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(active ? "✅ АКТИВЕН" : "ВЫБРАТЬ")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(active ? .green : .cyan)
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(active ? Color.green : Color.white.opacity(0.12), lineWidth: 1.2)
                            )
                        }
                    }
                }
                .padding(14)
                .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                .cornerRadius(16)

                // Audio & Haptics Toggles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Звук, Музыка и Вибрация")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.cyan)

                    Toggle("🎵 Фоновая Synthwave Музыка", isOn: Binding(
                        get: { save.musicEnabled },
                        set: { val in
                            save.musicEnabled = val
                            NativeSoundEngine.shared.updateMusicState(enabled: val)
                            save.saveToDisk()
                        }
                    ))
                    .foregroundColor(.white)

                    Toggle("🔊 Реалистичные Звуковые Эффекты", isOn: Binding(
                        get: { save.sfxEnabled },
                        set: { val in
                            save.sfxEnabled = val
                            NativeSoundEngine.shared.sfxEnabled = val
                            save.saveToDisk()
                        }
                    ))
                    .foregroundColor(.white)

                    Toggle("📳 Тактильная Отдача Taptic Engine", isOn: Binding(
                        get: { save.hapticsEnabled },
                        set: { val in
                            save.hapticsEnabled = val
                            NativeSoundEngine.shared.hapticsEnabled = val
                            save.saveToDisk()
                        }
                    ))
                    .foregroundColor(.white)
                }
                .padding(14)
                .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                .cornerRadius(16)

                // Bonus & Reset Buttons
                VStack(spacing: 10) {
                    Button(action: {
                        save.addCash(50000)
                        NativeSoundEngine.shared.playBossVictory()
                    }) {
                        Text("🎁 БОНУС ТЕСТЕРА: ПОЛУЧИТЬ +$50,000 БЕСПЛАТНО")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        save.resetAllProgress()
                    }) {
                        Text("🗑️ Сбросить прогресс и начать с нуля")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(12)
                    }
                }
                .padding(14)
                .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                .cornerRadius(16)
            }
            .padding(16)
        }
    }
}
