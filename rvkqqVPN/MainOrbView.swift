// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — 120Hz Native SwiftUI Game Arena
// Author & License: rvkqq (com.rvkqq.iflap)
// ============================================================================

import Foundation
import SwiftUI
import Combine

public struct PipeObstacle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var gapCenterY: CGFloat
    public var gapHeight: CGFloat
    public var passed: Bool = false
}

public struct CashPickup: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var value: Int
    public var isGoldCoin: Bool
}

public struct EnemyDrone: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var vy: CGFloat
    public var hp: Double
    public var maxHp: Double
    public var kind: Int // 0=AndroidBot, 1=FakeCharger, 2=BSOD
}

public struct LaserShot: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var vy: CGFloat
    public var damage: Double
    public var isEnemy: Bool
}

public struct ExplosionParticle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var vx: CGFloat
    public var vy: CGFloat
    public var life: Double
    public var color: Color
}

public struct FlappyIphoneArenaView: View {
    @EnvironmentObject public var save: GameSaveManager

    @State private var isPlaying: Bool = false
    @State private var isGameOver: Bool = false

    @State private var playerY: CGFloat = 240
    @State private var playerVy: CGFloat = 0
    @State private var playerHp: Double = 100
    @State private var runPipes: Int = 0
    @State private var runCash: Int = 0

    @State private var pipes: [PipeObstacle] = []
    @State private var pickups: [CashPickup] = []
    @State private var enemies: [EnemyDrone] = []
    @State private var lasers: [LaserShot] = []
    @State private var particles: [ExplosionParticle] = []

    // Active Boss State
    @State private var activeBossIndex: Int? = nil
    @State private var bossHp: Double = 0
    @State private var bossMaxHp: Double = 1000
    @State private var bossY: CGFloat = 220
    @State private var bossVy: CGFloat = 2.2

    // Active Abilities & Cooldowns
    @State private var shieldRemaining: Double = 0
    @State private var magnetRemaining: Double = 0
    @State private var overclockRemaining: Double = 0

    @State private var cdEmp: Double = 0
    @State private var cdShield: Double = 0
    @State private var cdMagnet: Double = 0
    @State private var cdOverclock: Double = 0

    @State private var tickCount: Int = 0

    private let gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let w = max(320, geo.size.width)
            let h = max(420, geo.size.height)

            ZStack {
                // 1. Main Interactive Game Canvas
                Canvas { context, size in
                    // Background Night Sky
                    let bgRect = CGRect(origin: .zero, size: size)
                    context.fill(Path(bgRect), with: .color(Color(red: 0.03, green: 0.05, blue: 0.12)))

                    // Moving Cyber Grid Lines
                    let gridOffset = CGFloat((tickCount * 2) % 40)
                    var gridPath = Path()
                    var gx: CGFloat = -gridOffset
                    while gx < size.width {
                        gridPath.move(to: CGPoint(x: gx, y: 0))
                        gridPath.addLine(to: CGPoint(x: gx, y: size.height))
                        gx += 40
                    }
                    var gy: CGFloat = 0
                    while gy < size.height {
                        gridPath.move(to: CGPoint(x: 0, y: gy))
                        gridPath.addLine(to: CGPoint(x: size.width, y: gy))
                        gy += 40
                    }
                    context.stroke(gridPath, with: .color(Color.cyan.opacity(0.08)), lineWidth: 1)

                    // Draw Pipes
                    for pipe in pipes {
                        let pipeW: CGFloat = 54
                        let topH = max(20, pipe.gapCenterY - pipe.gapHeight / 2.0)
                        let botY = pipe.gapCenterY + pipe.gapHeight / 2.0
                        let botH = max(20, size.height - botY)

                        let topRect = CGRect(x: pipe.x, y: 0, width: pipeW, height: topH)
                        let botRect = CGRect(x: pipe.x, y: botY, width: pipeW, height: botH)

                        context.fill(Path(topRect), with: .color(Color(red: 0.06, green: 0.65, blue: 0.42)))
                        context.fill(Path(botRect), with: .color(Color(red: 0.06, green: 0.65, blue: 0.42)))

                        let capTop = CGRect(x: pipe.x - 4, y: topH - 16, width: pipeW + 8, height: 16)
                        let capBot = CGRect(x: pipe.x - 4, y: botY, width: pipeW + 8, height: 16)
                        context.fill(Path(roundedRect: capTop, cornerRadius: 4), with: .color(Color(red: 0.16, green: 0.88, blue: 0.58)))
                        context.fill(Path(roundedRect: capBot, cornerRadius: 4), with: .color(Color(red: 0.16, green: 0.88, blue: 0.58)))
                    }

                    // Draw Cash Bills & Gold Coins
                    for item in pickups {
                        if item.isGoldCoin {
                            let cRect = CGRect(x: item.x - 11, y: item.y - 11, width: 22, height: 22)
                            context.fill(Path(ellipseIn: cRect), with: .color(Color.yellow))
                        } else {
                            let bRect = CGRect(x: item.x - 14, y: item.y - 9, width: 28, height: 18)
                            context.fill(Path(roundedRect: bRect, cornerRadius: 4), with: .color(Color.green))
                        }
                    }

                    // Draw Enemy Drones
                    for enemy in enemies {
                        let eRect = CGRect(x: enemy.x - 18, y: enemy.y - 18, width: 36, height: 36)
                        let eColor: Color = enemy.kind == 0 ? .green : (enemy.kind == 1 ? .orange : .blue)
                        context.fill(Path(roundedRect: eRect, cornerRadius: 8), with: .color(eColor))
                        // Enemy HP mini-bar
                        let hpRatio = max(0, min(1, enemy.hp / max(1, enemy.maxHp)))
                        let barBg = CGRect(x: enemy.x - 18, y: enemy.y - 26, width: 36, height: 4)
                        let barFg = CGRect(x: enemy.x - 18, y: enemy.y - 26, width: 36 * CGFloat(hpRatio), height: 4)
                        context.fill(Path(barBg), with: .color(Color.black.opacity(0.6)))
                        context.fill(Path(barFg), with: .color(Color.red))
                    }

                    // Draw Active Boss
                    if let bIdx = activeBossIndex {
                        let bossSpec = save.bosses[bIdx % save.bosses.count]
                        let bx = size.width - 78
                        let bRect = CGRect(x: bx - 42, y: bossY - 56, width: 84, height: 112)
                        context.fill(Path(roundedRect: bRect, cornerRadius: 16), with: .color(bossSpec.color))
                        context.stroke(Path(roundedRect: bRect, cornerRadius: 16), with: .color(bossSpec.accent), lineWidth: 3)

                        let screenRect = CGRect(x: bx - 32, y: bossY - 38, width: 64, height: 48)
                        context.fill(Path(roundedRect: screenRect, cornerRadius: 6), with: .color(bossSpec.accent.opacity(0.85)))
                    }

                    // Draw Lasers
                    for shot in lasers {
                        let lRect = CGRect(x: shot.x - 10, y: shot.y - 3, width: 22, height: 6)
                        context.fill(
                            Path(roundedRect: lRect, cornerRadius: 3),
                            with: .color(shot.isEnemy ? Color.red : save.currentIphone.accentColor)
                        )
                    }

                    // Draw Explosion Particles
                    for pt in particles {
                        let pRect = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
                        context.fill(Path(ellipseIn: pRect), with: .color(pt.color.opacity(pt.life)))
                    }

                    // Draw Player iPhone
                    let px: CGFloat = 86
                    let py = playerY

                    // Shield or Magnet Aura
                    if shieldRemaining > 0 {
                        let sRect = CGRect(x: px - 36, y: py - 44, width: 72, height: 88)
                        context.stroke(Path(ellipseIn: sRect), with: .color(Color.cyan), lineWidth: 3)
                    }
                    if magnetRemaining > 0 {
                        let mRect = CGRect(x: px - 42, y: py - 48, width: 84, height: 96)
                        context.stroke(Path(ellipseIn: mRect), with: .color(Color.yellow.opacity(0.75)), lineWidth: 2)
                    }

                    // Thruster Flame
                    let flameH: CGFloat = playerVy < 0 ? 22 : 10
                    let flameRect = CGRect(x: px - 26, y: py + 8, width: 12, height: flameH)
                    context.fill(Path(ellipseIn: flameRect), with: .color(Color.orange))

                    // iPhone Body
                    let phoneRect = CGRect(x: px - 18, y: py - 28, width: 36, height: 56)
                    context.fill(Path(roundedRect: phoneRect, cornerRadius: 9), with: .color(save.currentIphone.bodyColor))
                    context.stroke(Path(roundedRect: phoneRect, cornerRadius: 9), with: .color(Color.white.opacity(0.85)), lineWidth: 1.5)

                    // iPhone OLED Display
                    let dispRect = CGRect(x: px - 15, y: py - 24, width: 30, height: 48)
                    context.fill(Path(roundedRect: dispRect, cornerRadius: 6), with: .color(save.currentIphone.accentColor.opacity(0.45)))

                    // Dynamic Island Pill
                    let islandRect = CGRect(x: px - 7, y: py - 21, width: 14, height: 4)
                    context.fill(Path(roundedRect: islandRect, cornerRadius: 2), with: .color(Color.black))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleUserTap(arenaHeight: h)
                }

                // 2. Top In-Flight HUD (HP Bar, Score, Active Boss HP)
                VStack(spacing: 6) {
                    HStack(spacing: 10) {
                        // Battery HP Bar
                        HStack(spacing: 6) {
                            Text("🔋 \(Int(max(0, playerHp)))/\(Int(save.computedMaxHp))")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(10)

                        Spacer()

                        Text("Трубы: \(runPipes)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.65))
                            .cornerRadius(10)

                        Text("+$\(runCash)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.65))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    if let bIdx = activeBossIndex {
                        let bossSpec = save.bosses[bIdx % save.bosses.count]
                        VStack(spacing: 3) {
                            Text("⚠️ \(bossSpec.name) — \(Int(max(0, bossHp))) HP")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.yellow)
                            ProgressView(value: max(0, bossHp), total: max(1, bossMaxHp))
                                .accentColor(.red)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(10)
                        .padding(.horizontal, 12)
                    }

                    Spacer()

                    // 3. Bottom Active Ability Bar (4 Super Abilities)
                    HStack(spacing: 8) {
                        abilityButton(
                            title: "⚡ ЭМИ",
                            cooldown: cdEmp,
                            active: false,
                            color: .cyan
                        ) {
                            triggerEmpBlast(arenaWidth: w, arenaHeight: h)
                        }

                        abilityButton(
                            title: "🛡️ ЩИТ",
                            cooldown: cdShield,
                            active: shieldRemaining > 0,
                            color: .blue
                        ) {
                            triggerShield()
                        }

                        abilityButton(
                            title: "🧲 МАГНИТ",
                            cooldown: cdMagnet,
                            active: magnetRemaining > 0,
                            color: .yellow
                        ) {
                            triggerMagnet()
                        }

                        abilityButton(
                            title: "🔥 ЛАЗЕР",
                            cooldown: cdOverclock,
                            active: overclockRemaining > 0,
                            color: .pink
                        ) {
                            triggerOverclock()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }

                // 4. Start / Game Over Overlay
                if !isPlaying {
                    VStack(spacing: 14) {
                        Text(isGameOver ? "АЙФОН РАЗБИЛСЯ!" : "iFlap: БИТВА АЙФОНОВ")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("\(save.currentIphone.name) · Множитель x\(String(format: "%.1f", save.computedCashMultiplier))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cyan)

                        if isGameOver {
                            Text("Пройдено труб: \(runPipes) · Заработано: +$\(runCash)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Тапай по экрану, чтобы взлетать, стрелять из камер по дронам и боссам и собирать пачки кэша!")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                        }

                        Button(action: {
                            startNewRun(arenaHeight: h)
                        }) {
                            Text(isGameOver ? "🔄 ВЗЛЕТЕТЬ СНОВА" : "🚀 НАЧАТЬ ПОЛЁТ")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 34)
                                .background(Color.green)
                                .cornerRadius(14)
                        }
                    }
                    .padding(22)
                    .background(Color(red: 0.06, green: 0.09, blue: 0.18).opacity(0.94))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(24)
                }
            }
            .onReceive(gameTimer) { _ in
                if isPlaying {
                    stepPhysics(arenaWidth: w, arenaHeight: h)
                }
            }
        }
    }

    private func abilityButton(
        title: String,
        cooldown: Double,
        active: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(cooldown > 0 ? .gray : .white)
                Text(active ? "АКТИВЕН!" : (cooldown > 0 ? "\(Int(ceil(cooldown)))с" : "ГОТОВ"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(active ? .green : (cooldown > 0 ? .orange : color))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.78))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(active ? Color.green : (cooldown > 0 ? Color.gray.opacity(0.3) : color), lineWidth: 1.2)
            )
        }
        .disabled(!isPlaying || cooldown > 0)
    }

    private func startNewRun(arenaHeight: CGFloat) {
        playerY = arenaHeight * 0.45
        playerVy = -6.5
        playerHp = save.computedMaxHp
        runPipes = 0
        runCash = 0
        pipes.removeAll()
        pickups.removeAll()
        enemies.removeAll()
        lasers.removeAll()
        particles.removeAll()
        activeBossIndex = nil
        shieldRemaining = 2.5
        magnetRemaining = 0
        overclockRemaining = 0
        cdEmp = 0
        cdShield = 0
        cdMagnet = 0
        cdOverclock = 0
        isGameOver = false
        isPlaying = true
        NativeSoundEngine.shared.playFlap()
    }

    private func handleUserTap(arenaHeight: CGFloat) {
        if !isPlaying {
            startNewRun(arenaHeight: arenaHeight)
            return
        }
        playerVy = -7.0
        NativeSoundEngine.shared.playFlap()
        firePlayerLasers()
    }

    private func firePlayerLasers() {
        let count = save.currentIphone.laserCount
        let dmg = save.computedLaserDamage * (overclockRemaining > 0 ? 1.8 : 1.0)
        for i in 0..<count {
            let spread = CGFloat(i - (count - 1) / 2) * 1.1
            lasers.append(LaserShot(x: 110, y: playerY, vy: spread, damage: dmg, isEnemy: false))
        }
        NativeSoundEngine.shared.playLaser()
    }

    private func triggerEmpBlast(arenaWidth: CGFloat, arenaHeight: CGFloat) {
        guard cdEmp <= 0 else { return }
        cdEmp = 12.0
        save.totalAbilitiesUsed += 1
        let bonus = (pipes.count + enemies.count + 1) * Int(45.0 * save.computedCashMultiplier)
        pipes.removeAll()
        enemies.removeAll()
        lasers.removeAll(where: { $0.isEnemy })
        if activeBossIndex != nil {
            bossHp -= save.computedLaserDamage * 6.0
        }
        runCash += bonus
        save.addCash(bonus)
        spawnExplosion(x: arenaWidth * 0.5, y: arenaHeight * 0.5, color: .cyan, count: 24)
        NativeSoundEngine.shared.playExplosion()
    }

    private func triggerShield() {
        guard cdShield <= 0 else { return }
        cdShield = 14.0
        shieldRemaining = 6.0
        save.totalAbilitiesUsed += 1
        NativeSoundEngine.shared.playAbility()
    }

    private func triggerMagnet() {
        guard cdMagnet <= 0 else { return }
        cdMagnet = 15.0
        magnetRemaining = 8.0
        save.totalAbilitiesUsed += 1
        NativeSoundEngine.shared.playAbility()
    }

    private func triggerOverclock() {
        guard cdOverclock <= 0 else { return }
        cdOverclock = 16.0
        overclockRemaining = 6.0
        save.totalAbilitiesUsed += 1
        NativeSoundEngine.shared.playAbility()
    }

    private func spawnExplosion(x: CGFloat, y: CGFloat, color: Color, count: Int) {
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2.0 * Double.pi))
            let spd = CGFloat.random(in: 2.0...7.5)
            particles.append(
                ExplosionParticle(
                    x: x,
                    y: y,
                    vx: CGFloat(cos(angle)) * spd,
                    vy: CGFloat(sin(angle)) * spd,
                    life: 1.0,
                    color: color
                )
            )
        }
    }

    private func stepPhysics(arenaWidth: CGFloat, arenaHeight: CGFloat) {
        tickCount += 1
        let dt = 1.0 / 60.0

        // Cooldowns & Buff Timers
        cdEmp = max(0, cdEmp - dt)
        cdShield = max(0, cdShield - dt)
        cdMagnet = max(0, cdMagnet - dt)
        cdOverclock = max(0, cdOverclock - dt)
        shieldRemaining = max(0, shieldRemaining - dt)
        magnetRemaining = max(0, magnetRemaining - dt)
        overclockRemaining = max(0, overclockRemaining - dt)

        // Passive Battery Regen from 120W Upgrade
        let regenLvl = Double(save.upgradeLevels["ability_cdr"] ?? 0)
        if regenLvl > 0 || save.selectedIphoneId == "iphone_17_ultra" {
            playerHp = min(save.computedMaxHp, playerHp + (regenLvl * 1.2 + 2.0) * dt)
        }

        // Auto-Laser when Overclock is active
        if overclockRemaining > 0 && tickCount % 8 == 0 {
            firePlayerLasers()
        }

        // Player Physics
        playerVy += 0.36
        playerY += playerVy

        // Floor / Ceiling Bounds
        if playerY < 32 {
            playerY = 32
            playerVy = 0
        }
        if playerY > arenaHeight - 36 {
            if shieldRemaining > 0 {
                playerY = arenaHeight - 40
                playerVy = -6.5
            } else {
                playerHp -= 35
                playerY = arenaHeight - 48
                playerVy = -6.8
                NativeSoundEngine.shared.playExplosion()
            }
        }

        let speedMult: CGFloat = overclockRemaining > 0 ? 0.55 : 1.0
        let moveSpeed = save.difficulty.pipeSpeed * speedMult

        // Spawn Pipes & Pickups
        if activeBossIndex == nil && tickCount % 85 == 0 {
            let gapH = save.difficulty.pipeGap
            let centerY = CGFloat.random(in: (gapH * 0.65)...max(gapH * 0.7, arenaHeight - gapH * 0.65))
            pipes.append(PipeObstacle(x: arenaWidth + 40, gapCenterY: centerY, gapHeight: gapH))

            // Spawn Cash inside gap
            pickups.append(CashPickup(x: arenaWidth + 65, y: centerY, value: 45, isGoldCoin: Bool.random()))

            // Spawn Enemy Drone after pipe
            if Double.random(in: 0...1) < 0.65 {
                let eHp = 45.0 + Double(runPipes) * 8.0
                enemies.append(
                    EnemyDrone(
                        x: arenaWidth + 150,
                        y: CGFloat.random(in: 80...max(100, arenaHeight - 90)),
                        vy: CGFloat.random(in: -1.8...1.8),
                        hp: eHp,
                        maxHp: eHp,
                        kind: Int.random(in: 0...2)
                    )
                )
            }
        }

        // Update Pipes
        let px: CGFloat = 86
        var remainingPipes: [PipeObstacle] = []
        for var pipe in pipes {
            pipe.x -= moveSpeed
            let pipeW: CGFloat = 54
            let topH = pipe.gapCenterY - pipe.gapHeight / 2.0
            let botY = pipe.gapCenterY + pipe.gapHeight / 2.0

            // Check Collision with Player
            if px + 16 > pipe.x && px - 16 < pipe.x + pipeW {
                if playerY - 22 < topH || playerY + 22 > botY {
                    if shieldRemaining > 0 {
                        spawnExplosion(x: pipe.x + 25, y: playerY, color: .cyan, count: 10)
                        continue
                    } else {
                        let dmg = save.selectedIphoneId == "iphone_15_pro" ? 24.0 : 38.0
                        playerHp -= dmg
                        playerVy = -5.5
                        spawnExplosion(x: px, y: playerY, color: .red, count: 12)
                        NativeSoundEngine.shared.playExplosion()
                        continue
                    }
                }
            }

            if !pipe.passed && pipe.x + pipeW < px {
                pipe.passed = true
                runPipes += 1
                save.totalPipesPassed += 1
                if runPipes > save.highScorePipes {
                    save.highScorePipes = runPipes
                }
                let earned = max(1, Int(25.0 * save.computedCashMultiplier * (magnetRemaining > 0 ? 3.0 : 1.0)))
                runCash += earned
                save.addCash(earned)

                // Check Boss Spawn
                if activeBossIndex == nil && runPipes > 0 && runPipes % save.difficulty.bossInterval == 0 {
                    let bIdx = (runPipes / save.difficulty.bossInterval - 1) % save.bosses.count
                    activeBossIndex = bIdx
                    let spec = save.bosses[bIdx]
                    bossMaxHp = spec.baseHp * (1.0 + Double(runPipes) * 0.04)
                    bossHp = bossMaxHp
                    bossY = arenaHeight * 0.45
                }
            }

            if pipe.x > -80 {
                remainingPipes.append(pipe)
            }
        }
        pipes = remainingPipes

        // Update Pickups & MagSafe Magnet
        let magRadius = magnetRemaining > 0 ? 420.0 : save.computedMagnetRadius
        var remainingPickups: [CashPickup] = []
        for var item in pickups {
            item.x -= moveSpeed
            let dx = px - item.x
            let dy = playerY - item.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < magRadius {
                item.x += (dx / max(1, dist)) * 8.5
                item.y += (dy / max(1, dist)) * 8.5
            }
            if dist < 34 {
                let mult = save.computedCashMultiplier * (magnetRemaining > 0 ? 3.0 : 1.0)
                let gain = max(1, Int(Double(item.value) * mult))
                runCash += gain
                save.addCash(gain)
                NativeSoundEngine.shared.playCash()
            } else if item.x > -40 {
                remainingPickups.append(item)
            }
        }
        pickups = remainingPickups

        // Update Enemies
        var nextEnemies: [EnemyDrone] = []
        for var enemy in enemies {
            enemy.x -= moveSpeed * 1.15
            enemy.y += enemy.vy
            if enemy.y < 55 || enemy.y > arenaHeight - 60 {
                enemy.vy = -enemy.vy
            }
            let dist = hypot(px - enemy.x, playerY - enemy.y)
            if dist < 36 {
                if shieldRemaining <= 0 {
                    playerHp -= 28
                    NativeSoundEngine.shared.playExplosion()
                }
                spawnExplosion(x: enemy.x, y: enemy.y, color: .green, count: 10)
                continue
            }
            if enemy.x > -50 && enemy.hp > 0 {
                nextEnemies.append(enemy)
            }
        }
        enemies = nextEnemies

        // Update Active Boss
        if let bIdx = activeBossIndex {
            bossY += bossVy
            if bossY < 85 || bossY > arenaHeight - 95 {
                bossVy = -bossVy
            }
            if tickCount % 45 == 0 {
                lasers.append(LaserShot(x: arenaWidth - 110, y: bossY, vy: CGFloat.random(in: -2.2...2.2), damage: 22, isEnemy: true))
            }
            if bossHp <= 0 {
                let spec = save.bosses[bIdx % save.bosses.count]
                let reward = Int(Double(spec.rewardCash) * save.computedCashMultiplier)
                runCash += reward
                save.addCash(reward)
                save.totalBossesKilled += 1
                spawnExplosion(x: arenaWidth - 80, y: bossY, color: .yellow, count: 30)
                NativeSoundEngine.shared.playBossVictory()
                activeBossIndex = nil
            }
        }

        // Update Lasers
        var nextLasers: [LaserShot] = []
        for var shot in lasers {
            shot.x += shot.isEnemy ? -6.5 : 11.5
            shot.y += shot.vy

            if shot.isEnemy {
                if hypot(shot.x - px, shot.y - playerY) < 26 {
                    if shieldRemaining <= 0 {
                        playerHp -= shot.damage
                        NativeSoundEngine.shared.playExplosion()
                    }
                    continue
                }
            } else {
                var hit = false
                for idx in enemies.indices {
                    if hypot(shot.x - enemies[idx].x, shot.y - enemies[idx].y) < 28 {
                        enemies[idx].hp -= shot.damage
                        hit = true
                        if enemies[idx].hp <= 0 {
                            save.totalEnemiesKilled += 1
                            let bounty = Int(80.0 * save.computedCashMultiplier)
                            runCash += bounty
                            save.addCash(bounty)
                            spawnExplosion(x: enemies[idx].x, y: enemies[idx].y, color: .orange, count: 12)
                            NativeSoundEngine.shared.playCash()
                        }
                        break
                    }
                }
                if !hit, activeBossIndex != nil {
                    let bx = arenaWidth - 78
                    if abs(shot.x - bx) < 46 && abs(shot.y - bossY) < 58 {
                        bossHp -= shot.damage
                        hit = true
                        spawnExplosion(x: shot.x, y: shot.y, color: .yellow, count: 4)
                    }
                }
                if hit { continue }
            }

            if shot.x > -30 && shot.x < arenaWidth + 30 {
                nextLasers.append(shot)
            }
        }
        lasers = nextLasers
        enemies.removeAll(where: { $0.hp <= 0 })

        // Update Particles
        var nextParticles: [ExplosionParticle] = []
        for var pt in particles {
            pt.x += pt.vx
            pt.y += pt.vy
            pt.life -= 0.04
            if pt.life > 0 {
                nextParticles.append(pt)
            }
        }
        particles = nextParticles

        // Check Game Over
        if playerHp <= 0 {
            playerHp = 0
            isPlaying = false
            isGameOver = true
            save.saveToDisk()
        }
    }
}
