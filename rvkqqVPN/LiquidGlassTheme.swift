// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — Core Game Models & Save Engine
// Author & License: rvkqq (com.rvkqq.iflap)
// Compatibility: All iPhones (iOS 15.0 - iOS 18.0+, 60Hz/120Hz ProMotion)
// ============================================================================

import Foundation
import SwiftUI
import Combine

public enum GameDifficultyId: String, CaseIterable, Identifiable {
    case chill = "chill"
    case normal = "normal"
    case hardcore = "hardcore"
    case bossRush = "boss_rush"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .chill: return "Лёгкий (60Hz Chill)"
        case .normal: return "Нормальный (120Hz)"
        case .hardcore: return "Хардкор (x3 Кэш)"
        case .bossRush: return "Босс-Раш (x5 Кэш)"
        }
    }

    public var subtitle: String {
        switch self {
        case .chill: return "Широкие трубы, плавный полёт, много ХП"
        case .normal: return "Идеальный баланс драйва, врагов и боссов (x1.5 Кэш)"
        case .hardcore: return "Узкие трубы, быстрые дроны, x3.0 Кэш!"
        case .bossRush: return "Боссы каждые 4 трубы, море лазеров и x5.0 Кэш!"
        }
    }

    public var pipeGap: CGFloat {
        switch self {
        case .chill: return 190
        case .normal: return 162
        case .hardcore: return 138
        case .bossRush: return 175
        }
    }

    public var pipeSpeed: CGFloat {
        switch self {
        case .chill: return 2.8
        case .normal: return 3.5
        case .hardcore: return 4.3
        case .bossRush: return 3.6
        }
    }

    public var cashMultiplier: Double {
        switch self {
        case .chill: return 1.0
        case .normal: return 1.5
        case .hardcore: return 3.0
        case .bossRush: return 5.0
        }
    }

    public var bossInterval: Int {
        switch self {
        case .chill: return 12
        case .normal: return 10
        case .hardcore: return 8
        case .bossRush: return 4
        }
    }
}

public struct IPhoneModelItem: Identifiable {
    public let id: String
    public let name: String
    public let year: Int
    public let tagline: String
    public let price: Int
    public let bodyColor: Color
    public let accentColor: Color
    public let cashMultiplier: Double
    public let baseHp: Double
    public let laserCount: Int
    public let laserDamage: Double
    public let perkText: String
}

public struct UpgradeItemSpec: Identifiable {
    public let id: String
    public let name: String
    public let desc: String
    public let baseCost: Int
    public let maxLevel: Int
    public let bonusLabel: String
}

public struct BossTemplate: Identifiable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let baseHp: Double
    public let rewardCash: Int
    public let color: Color
    public let accent: Color
}

public struct QuestTemplate: Identifiable {
    public let id: String
    public let title: String
    public let desc: String
    public let target: Int
    public let reward: Int
    public let metricKey: String
}

public final class GameSaveManager: ObservableObject {
    @Published public var cash: Int = 500
    @Published public var highScorePipes: Int = 0
    @Published public var totalPipesPassed: Int = 0
    @Published public var totalEnemiesKilled: Int = 0
    @Published public var totalBossesKilled: Int = 0
    @Published public var totalAbilitiesUsed: Int = 0
    @Published public var totalCashEarned: Int = 500

    @Published public var selectedIphoneId: String = "iphone_2g"
    @Published public var ownedIphoneIds: Set<String> = ["iphone_2g"]
    @Published public var upgradeLevels: [String: Int] = [
        "laser_power": 0,
        "battery_armor": 0,
        "magsafe_magnet": 0,
        "cash_boost": 0,
        "ability_cdr": 0
    ]
    @Published public var claimedQuestIds: Set<String> = []

    @Published public var difficulty: GameDifficultyId = .normal
    @Published public var musicEnabled: Bool = true
    @Published public var sfxEnabled: Bool = true
    @Published public var hapticsEnabled: Bool = true
    @Published public var graphicsHigh: Bool = true

    public let iphones: [IPhoneModelItem] = [
        IPhoneModelItem(
            id: "iphone_2g",
            name: "iPhone 2G Original",
            year: 2007,
            tagline: "Алюминиевая классика Стива Джобса",
            price: 0,
            bodyColor: Color(red: 0.58, green: 0.64, blue: 0.72),
            accentColor: Color(red: 0.22, green: 0.74, blue: 0.97),
            cashMultiplier: 1.0,
            baseHp: 100,
            laserCount: 1,
            laserDamage: 20,
            perkText: "Одиночный iMessage-бластер"
        ),
        IPhoneModelItem(
            id: "iphone_4s",
            name: "iPhone 4S Retina",
            year: 2011,
            tagline: "Стальная рамка и стекло Gorilla Glass",
            price: 450,
            bodyColor: Color(red: 0.88, green: 0.91, blue: 0.95),
            accentColor: Color(red: 0.38, green: 0.65, blue: 0.98),
            cashMultiplier: 1.6,
            baseHp: 135,
            laserCount: 1,
            laserDamage: 30,
            perkText: "+35% прочности корпуса"
        ),
        IPhoneModelItem(
            id: "iphone_5s",
            name: "iPhone 5S Gold TouchID",
            year: 2013,
            tagline: "Золотой корпус и двойной лазер TouchID",
            price: 1500,
            bodyColor: Color(red: 0.98, green: 0.75, blue: 0.14),
            accentColor: Color(red: 0.96, green: 0.62, blue: 0.04),
            cashMultiplier: 2.5,
            baseHp: 170,
            laserCount: 2,
            laserDamage: 40,
            perkText: "Двойной золотой лазер TouchID"
        ),
        IPhoneModelItem(
            id: "iphone_x",
            name: "iPhone X OLED FaceID",
            year: 2017,
            tagline: "Безрамочный OLED и инфракрасный луч",
            price: 4500,
            bodyColor: Color(red: 0.25, green: 0.30, blue: 0.38),
            accentColor: Color(red: 0.66, green: 0.33, blue: 0.97),
            cashMultiplier: 4.0,
            baseHp: 220,
            laserCount: 2,
            laserDamage: 62,
            perkText: "Крит по боссам x1.5"
        ),
        IPhoneModelItem(
            id: "iphone_13_pro",
            name: "iPhone 13 Pro Sierra Blue",
            year: 2021,
            tagline: "120Hz ProMotion и 3 камеры с LiDAR",
            price: 12000,
            bodyColor: Color(red: 0.22, green: 0.74, blue: 0.97),
            accentColor: Color(red: 0.02, green: 0.71, blue: 0.83),
            cashMultiplier: 7.0,
            baseHp: 280,
            laserCount: 3,
            laserDamage: 95,
            perkText: "Тройной веерный лазер 120Hz"
        ),
        IPhoneModelItem(
            id: "iphone_15_pro",
            name: "iPhone 15 Pro Titanium",
            year: 2023,
            tagline: "Аэрокосмический титан Grade 5 + Action Button",
            price: 32000,
            bodyColor: Color(red: 0.66, green: 0.64, blue: 0.62),
            accentColor: Color(red: 0.13, green: 0.83, blue: 0.93),
            cashMultiplier: 12.0,
            baseHp: 360,
            laserCount: 3,
            laserDamage: 145,
            perkText: "-40% урона от труб и ракет"
        ),
        IPhoneModelItem(
            id: "iphone_16_pro_max",
            name: "iPhone 16 Pro Max Desert",
            year: 2024,
            tagline: "Пустынный титан, чип A18 Pro и мега-батарея",
            price: 85000,
            bodyColor: Color(red: 0.85, green: 0.47, blue: 0.02),
            accentColor: Color(red: 0.99, green: 0.88, blue: 0.28),
            cashMultiplier: 22.0,
            baseHp: 480,
            laserCount: 4,
            laserDamage: 240,
            perkText: "4 плазменных луча + Авто-Магнит"
        ),
        IPhoneModelItem(
            id: "iphone_17_ultra",
            name: "iPhone 17 Ultra CyberFold",
            year: 2026,
            tagline: "Голографический флагман с квантовым реактором",
            price: 250000,
            bodyColor: Color(red: 0.06, green: 0.73, blue: 0.51),
            accentColor: Color(red: 0.0, green: 1.0, blue: 0.8),
            cashMultiplier: 50.0,
            baseHp: 680,
            laserCount: 5,
            laserDamage: 450,
            perkText: "5-ствольный рельсотрон + Авто-реген ХП"
        )
    ]

    public let upgrades: [UpgradeItemSpec] = [
        UpgradeItemSpec(id: "laser_power", name: "Чип A18 Pro (Урон Камеры)", desc: "Усиливает урон лазеров при каждом тапе", baseCost: 150, maxLevel: 25, bonusLabel: "+30% урон"),
        UpgradeItemSpec(id: "battery_armor", name: "Титановая Батарея (Броня ХП)", desc: "Позволяет таранить трубы без потери айфона", baseCost: 200, maxLevel: 25, bonusLabel: "+35 ХП"),
        UpgradeItemSpec(id: "magsafe_magnet", name: "Катушка MagSafe (Магнит)", desc: "Притягивает доллары и монеты издалека", baseCost: 180, maxLevel: 20, bonusLabel: "+28px радиус"),
        UpgradeItemSpec(id: "cash_boost", name: "Акции Apple (Множитель $)", desc: "Увеличивает доход за трубы, монеты и боссов", baseCost: 250, maxLevel: 25, bonusLabel: "+25% доход"),
        UpgradeItemSpec(id: "ability_cdr", name: "Зарядка 120W (Способности)", desc: "Ускоряет откат способностей и лечит в полёте", baseCost: 300, maxLevel: 20, bonusLabel: "-4% откат + хил")
    ]

    public let bosses: [BossTemplate] = [
        BossTemplate(id: "nokia_3310", name: "БОСС 1: NOKIA 3310 TITAN", subtitle: "Неубиваемый кирпич — стреляет пикселями!", baseHp: 850, rewardCash: 2500, color: Color(red: 0.12, green: 0.23, blue: 0.54), accent: Color(red: 0.52, green: 0.80, blue: 0.09)),
        BossTemplate(id: "note_7", name: "БОСС 2: GALAXY NOTE 7 PYRO", subtitle: "Взрывной реактор — метает плазму!", baseHp: 2400, rewardCash: 7500, color: Color(red: 0.60, green: 0.11, blue: 0.11), accent: Color(red: 0.98, green: 0.45, blue: 0.09)),
        BossTemplate(id: "eu_usbc", name: "БОСС 3: ЕВРО-КОМИССАР USB-C", subtitle: "Дрон регулятора — стреляет штрафами!", baseHp: 6500, rewardCash: 22000, color: Color(red: 0.11, green: 0.31, blue: 0.85), accent: Color(red: 0.98, green: 0.80, blue: 0.08)),
        BossTemplate(id: "pro_stand", name: "БОСС 4: ПОДСТАВКА ЗА $999", subtitle: "Меха-Купертино — атакует колёсиками Mac Pro!", baseHp: 18000, rewardCash: 75000, color: Color(red: 0.06, green: 0.09, blue: 0.16), accent: Color(red: 0.22, green: 0.74, blue: 0.97))
    ]

    public let quests: [QuestTemplate] = [
        QuestTemplate(id: "q_pipes_15", title: "Первый Прорыв", desc: "Пролететь через 15 труб суммарно", target: 15, reward: 1000, metricKey: "pipes"),
        QuestTemplate(id: "q_enemies_10", title: "Охотник на Дронов", desc: "Сбить 10 врагов лазером айфона", target: 10, reward: 2000, metricKey: "enemies"),
        QuestTemplate(id: "q_abilities_5", title: "Мастер Способностей", desc: "Использовать способности 5 раз", target: 5, reward: 2500, metricKey: "abilities"),
        QuestTemplate(id: "q_boss_1", title: "Разрушитель Nokia 3310", desc: "Победить любого Босса", target: 1, reward: 5000, metricKey: "bosses"),
        QuestTemplate(id: "q_iphones_3", title: "Коллекционер Apple", desc: "Открыть 3 модели iPhone", target: 3, reward: 6000, metricKey: "iphones"),
        QuestTemplate(id: "q_pipes_100", title: "Повелитель 120Hz", desc: "Пролететь через 100 труб суммарно", target: 100, reward: 15000, metricKey: "pipes"),
        QuestTemplate(id: "q_boss_5", title: "Терминатор Боссов", desc: "Уничтожить 5 Боссов", target: 5, reward: 35000, metricKey: "bosses"),
        QuestTemplate(id: "q_earned_100k", title: "Волк из Купертино", desc: "Заработать суммарно $100,000", target: 100000, reward: 50000, metricKey: "earned")
    ]

    public init() {
        loadFromDisk()
    }

    public var currentIphone: IPhoneModelItem {
        iphones.first(where: { $0.id == selectedIphoneId }) ?? iphones[0]
    }

    public var computedMaxHp: Double {
        let lvl = Double(upgradeLevels["battery_armor"] ?? 0)
        return currentIphone.baseHp + lvl * 35.0
    }

    public var computedLaserDamage: Double {
        let lvl = Double(upgradeLevels["laser_power"] ?? 0)
        return currentIphone.laserDamage * (1.0 + lvl * 0.30)
    }

    public var computedMagnetRadius: CGFloat {
        let lvl = CGFloat(upgradeLevels["magsafe_magnet"] ?? 0)
        let bonus: CGFloat = (selectedIphoneId == "iphone_16_pro_max" || selectedIphoneId == "iphone_17_ultra") ? 85 : 0
        return 55 + lvl * 28 + bonus
    }

    public var computedCashMultiplier: Double {
        let lvl = Double(upgradeLevels["cash_boost"] ?? 0)
        return currentIphone.cashMultiplier * difficulty.cashMultiplier * (1.0 + lvl * 0.25)
    }

    public func upgradeCost(for spec: UpgradeItemSpec) -> Int {
        let lvl = upgradeLevels[spec.id] ?? 0
        return Int(Double(spec.baseCost) * pow(1.55, Double(lvl)))
    }

    public func buyOrSelectIphone(_ item: IPhoneModelItem) {
        if ownedIphoneIds.contains(item.id) {
            selectedIphoneId = item.id
            saveToDisk()
            return
        }
        guard cash >= item.price else { return }
        cash -= item.price
        ownedIphoneIds.insert(item.id)
        selectedIphoneId = item.id
        NativeSoundEngine.shared.playCash()
        saveToDisk()
    }

    public func buyUpgrade(_ spec: UpgradeItemSpec) {
        let lvl = upgradeLevels[spec.id] ?? 0
        guard lvl < spec.maxLevel else { return }
        let cost = upgradeCost(for: spec)
        guard cash >= cost else { return }
        cash -= cost
        upgradeLevels[spec.id] = lvl + 1
        NativeSoundEngine.shared.playCash()
        saveToDisk()
    }

    public func questProgress(_ q: QuestTemplate) -> Int {
        switch q.metricKey {
        case "pipes": return totalPipesPassed
        case "enemies": return totalEnemiesKilled
        case "bosses": return totalBossesKilled
        case "abilities": return totalAbilitiesUsed
        case "iphones": return ownedIphoneIds.count
        case "earned": return totalCashEarned
        default: return 0
        }
    }

    public func claimQuest(_ q: QuestTemplate) {
        guard !claimedQuestIds.contains(q.id) else { return }
        guard questProgress(q) >= q.target else { return }
        claimedQuestIds.insert(q.id)
        addCash(q.reward)
        NativeSoundEngine.shared.playBossVictory()
        saveToDisk()
    }

    public func addCash(_ amount: Int) {
        guard amount > 0 else { return }
        cash += amount
        totalCashEarned += amount
        saveToDisk()
    }

    public func saveToDisk() {
        let d = UserDefaults.standard
        d.set(cash, forKey: "iflap.cash")
        d.set(highScorePipes, forKey: "iflap.highscore")
        d.set(totalPipesPassed, forKey: "iflap.totalPipes")
        d.set(totalEnemiesKilled, forKey: "iflap.totalEnemies")
        d.set(totalBossesKilled, forKey: "iflap.totalBosses")
        d.set(totalAbilitiesUsed, forKey: "iflap.totalAbilities")
        d.set(totalCashEarned, forKey: "iflap.totalEarned")
        d.set(selectedIphoneId, forKey: "iflap.selectedIphone")
        d.set(Array(ownedIphoneIds), forKey: "iflap.ownedIphones")
        d.set(upgradeLevels, forKey: "iflap.upgrades")
        d.set(Array(claimedQuestIds), forKey: "iflap.claimedQuests")
        d.set(difficulty.rawValue, forKey: "iflap.difficulty")
        d.set(musicEnabled, forKey: "iflap.music")
        d.set(sfxEnabled, forKey: "iflap.sfx")
        d.set(hapticsEnabled, forKey: "iflap.haptics")
    }

    public func loadFromDisk() {
        let d = UserDefaults.standard
        if d.object(forKey: "iflap.cash") != nil {
            cash = d.integer(forKey: "iflap.cash")
            highScorePipes = d.integer(forKey: "iflap.highscore")
            totalPipesPassed = d.integer(forKey: "iflap.totalPipes")
            totalEnemiesKilled = d.integer(forKey: "iflap.totalEnemies")
            totalBossesKilled = d.integer(forKey: "iflap.totalBosses")
            totalAbilitiesUsed = d.integer(forKey: "iflap.totalAbilities")
            totalCashEarned = d.integer(forKey: "iflap.totalEarned")
            selectedIphoneId = d.string(forKey: "iflap.selectedIphone") ?? "iphone_2g"
            if let owned = d.stringArray(forKey: "iflap.ownedIphones") {
                ownedIphoneIds = Set(owned)
            }
            if let upg = d.dictionary(forKey: "iflap.upgrades") as? [String: Int] {
                upgradeLevels = upg
            }
            if let clm = d.stringArray(forKey: "iflap.claimedQuests") {
                claimedQuestIds = Set(clm)
            }
            if let diffRaw = d.string(forKey: "iflap.difficulty"),
               let diff = GameDifficultyId(rawValue: diffRaw) {
                difficulty = diff
            }
            musicEnabled = d.bool(forKey: "iflap.music")
            sfxEnabled = d.bool(forKey: "iflap.sfx")
            hapticsEnabled = d.bool(forKey: "iflap.haptics")
        }
    }

    public func resetAllProgress() {
        cash = 500
        highScorePipes = 0
        totalPipesPassed = 0
        totalEnemiesKilled = 0
        totalBossesKilled = 0
        totalAbilitiesUsed = 0
        totalCashEarned = 500
        selectedIphoneId = "iphone_2g"
        ownedIphoneIds = ["iphone_2g"]
        upgradeLevels = [
            "laser_power": 0,
            "battery_armor": 0,
            "magsafe_magnet": 0,
            "cash_boost": 0,
            "ability_cdr": 0
        ]
        claimedQuestIds = []
        saveToDisk()
    }
}
