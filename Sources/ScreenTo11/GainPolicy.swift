import Foundation

enum GainPolicy {
    static func requestedGain(level: Double, potential: Double) -> Double {
        let safePotential = potential.isFinite ? max(1, potential) : 1
        return 1 + min(max(level, 0), 1) * (safePotential - 1)
    }

    static func effectiveGain(level: Double, potential: Double, current: Double) -> Double {
        let safePotential = potential.isFinite ? max(1, potential) : 1
        let safeCurrent = current.isFinite ? max(1, current) : 1
        let usableHeadroom = min(safePotential, safeCurrent)
        return 1 + min(max(level, 0), 1) * (usableHeadroom - 1)
    }
}
