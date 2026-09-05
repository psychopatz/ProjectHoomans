local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local factionAllows = false
local stealthBlocks = false

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = { PRESENCE_CORPSE = "corpse" },
    Registry = {},
    Factions = {
        CanNPCTargetPlayer = function() return factionAllows end,
    },
    Stealth = {
        ShouldSuppressCompanionCombat = function() return stealthBlocks end,
        ShouldSuppressZombieAggro = function() return false end,
    },
}

require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution"

local attacker = {
    id = "npc-1",
    alive = true,
    presenceState = "live",
}
local player = {
    isDead = function() return false end,
}
local rejected, reason = PNC.CombatResolution.ApplyTargetDamage(
    attacker,
    nil,
    { kind = "player", player = player },
    { damage = 10 }
)
T.falsy(rejected, "stale player target bypassed faction revalidation")
T.equal(reason, "player_target_not_allowed",
    "stale player target returned the wrong rejection reason")

factionAllows = true
stealthBlocks = true
rejected, reason = PNC.CombatResolution.ApplyTargetDamage(
    attacker,
    nil,
    { kind = "player", player = player },
    { damage = 10 }
)
T.falsy(rejected, "stealth player target bypassed combat suppression")
T.equal(reason, "player_target_hidden",
    "stealth player target returned the wrong rejection reason")

T.finish("pnc_player_target_revalidation_smoke")
