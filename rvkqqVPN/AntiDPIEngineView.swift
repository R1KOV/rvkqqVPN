// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — iPhone Showroom & Upgrade Workshop
// Author & License: rvkqq (com.rvkqq.iflap)
// ============================================================================

import Foundation
import SwiftUI

public struct IPhoneShopView: View {
    @EnvironmentObject public var save: GameSaveManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("📱 Магазин iPhone (Все поколения)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Покупай новые модели iPhone, чтобы увеличить множитель бабок, броню батареи и количество лазерных камер!")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                ForEach(save.iphones) { item in
                    let isOwned = save.ownedIphoneIds.contains(item.id)
                    let isSelected = save.selectedIphoneId == item.id

                    HStack(spacing: 12) {
                        // Mini iPhone Icon Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.bodyColor)
                                .frame(width: 42, height: 64)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.accentColor.opacity(0.45))
                                .frame(width: 36, height: 54)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(item.name) (\(String(item.year)))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }

                            Text(item.tagline)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)

                            Text("💰 x\(String(format: "%.1f", item.cashMultiplier)) Кэш · 🔋 \(Int(item.baseHp)) ХП · 🔫 \(item.laserCount)х Лазер")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cyan)

                            Text("✨ \(item.perkText)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.yellow)
                        }

                        Button(action: {
                            save.buyOrSelectIphone(item)
                        }) {
                            Text(isSelected ? "ВЫБРАН" : (isOwned ? "ВЗЯТЬ" : "$\(item.price)"))
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    isSelected
                                        ? Color.green
                                        : (isOwned ? Color.cyan : (save.cash >= item.price ? Color.yellow : Color.gray))
                                )
                                .cornerRadius(10)
                        }
                        .disabled(!isOwned && save.cash < item.price)
                    }
                    .padding(14)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.green : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                    )
                }
            }
            .padding(16)
        }
    }
}

public struct UpgradeWorkshopView: View {
    @EnvironmentObject public var save: GameSaveManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("⚡ Тюнинг и Прокачка Айфона")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Все улучшения работают постоянно на всех купленных айфонах!")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                ForEach(save.upgrades) { spec in
                    let lvl = save.upgradeLevels[spec.id] ?? 0
                    let cost = save.upgradeCost(for: spec)
                    let isMax = lvl >= spec.maxLevel

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(spec.name) [Ур. \(lvl)/\(spec.maxLevel)]")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)

                            Text(spec.desc)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)

                            Text("Бонус: \(spec.bonusLabel) за уровень")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }

                        Spacer()

                        Button(action: {
                            save.buyUpgrade(spec)
                        }) {
                            Text(isMax ? "МАКС" : "$\(cost)")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(isMax ? Color.green : (save.cash >= cost ? Color.cyan : Color.gray))
                                .cornerRadius(10)
                        }
                        .disabled(isMax || save.cash < cost)
                    }
                    .padding(14)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.20))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.22), lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
    }
}
