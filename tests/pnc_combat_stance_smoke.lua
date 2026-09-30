--[[
    Combat stance policy: a fighting NPC presents its weapon in hand, and an
    idle one holsters it again once the fighting-mode hold expires.
]]

local T = require "tests/support/test"

local now = 100000
local Core = {
    Now = function() return now end,
}

PNC = PNC or {}
PNC.Core = Core
PNC.Const = {
    ATTACK_TYPE_NONE = "none",
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Base/PNC_Constants/HealthThreats.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Combat/PNC_Combat_Stance.lua")

local Stance = PNC.CombatStance
local holdMs = tonumber(PNC.Const.COMBAT_STANCE_HOLD_MS)

T.truthy(Stance, "combat stance module did not load")
T.truthy(holdMs and holdMs > 0, "combat stance hold constant missing")

local function armedRecord()
    return {
        id = "npc_stance",
        alive = true,
        health = { state = "normal" },
        activeBehavior = "Combat",
        runtime = {},
    }
end

-- Idle NPCs must never present a weapon.
local idle = armedRecord()
T.falsy(Stance.IsArmed(idle), "idle npc is not armed")
T.falsy(Stance.Snapshot(idle), "idle npc snapshot is not armed")

-- Acquiring a target is the instant fighting mode begins, before any tick.
local engaged = armedRecord()
engaged.runtime.target = { kind = "zombie", zombieId = 42 }
T.truthy(Stance.IsArmed(engaged), "combat target arms the stance")

-- A gesture-only target must not draw a weapon.
local alerted = armedRecord()
alerted.runtime.target = { kind = "zombie", alertOnly = true }
T.falsy(Stance.IsArmed(alerted), "alert-only target does not arm the stance")

-- An attack action in flight arms the stance.
local attacking = armedRecord()
attacking.runtime.attackAction = { attackType = "melee", finishAt = now + 400 }
T.truthy(Stance.IsArmed(attacking), "attack action arms the stance")

-- Repositioning between shots: no target lease and no attack action, but the
-- refreshed hold keeps the weapon in hand.
local repositioning = armedRecord()
Stance.Maintain(repositioning)
repositioning.runtime.target = nil
repositioning.runtime.attackAction = nil
T.truthy(Stance.IsArmed(repositioning),
    "refreshed hold keeps the weapon in hand between shots")

now = now + holdMs - 1
T.truthy(Stance.IsArmed(repositioning), "hold survives just inside the window")

now = now + 1
T.falsy(Stance.IsArmed(repositioning),
    "expired hold returns the weapon to the holster")

-- A live engagement tick keeps refreshing, so the hold never lapses mid-fight.
for _ = 1, 12 do
    now = now + 900
    Stance.Maintain(repositioning)
    T.truthy(Stance.IsArmed(repositioning),
        "engagement tick keeps the weapon drawn mid-fight")
end

-- Disengaging stops the refresh and the weapon holsters.
now = now + holdMs + 1
T.falsy(Stance.IsArmed(repositioning), "disengage holsters the weapon")

-- An explicit parley/disengage clears the hold immediately.
local parley = armedRecord()
Stance.Maintain(parley)
T.truthy(Stance.IsArmed(parley), "parley subject starts armed")
Stance.Clear(parley)
T.falsy(Stance.IsArmed(parley), "parley clears the weapon-drawn hold")

-- Attack disabled: never present a weapon, even with a stale target lease.
local disarmed = armedRecord()
disarmed.attackType = "none"
disarmed.runtime.target = { kind = "zombie" }
Stance.Maintain(disarmed)
T.falsy(Stance.IsArmed(disarmed),
    "attack type none suppresses the weapon-drawn stance")

-- Non-combat body states never present a weapon.
local dead = armedRecord()
dead.alive = false
dead.runtime.target = { kind = "zombie" }
T.falsy(Stance.IsArmed(dead), "dead npc is not armed")

local downed = armedRecord()
downed.health.state = "incapacitated"
downed.runtime.target = { kind = "zombie" }
T.falsy(Stance.IsArmed(downed), "incapacitated npc is not armed")

local downedBehavior = armedRecord()
downedBehavior.activeBehavior = "Downed"
Stance.Maintain(downedBehavior)
T.falsy(Stance.IsArmed(downedBehavior), "downed behavior is not armed")

-- The stance boolean is what the network snapshot publishes for remote bodies.
local broadcast = armedRecord()
Stance.Maintain(broadcast)
T.equal(Stance.Snapshot(broadcast), true, "snapshot publishes fighting mode")
T.equal(Stance.Snapshot(armedRecord()), false, "snapshot publishes idle mode")

-- Equipment presentation must translate the stance into a weapon in hand.
T.load("ProjectHoomans", "shared",
    "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_Hands.lua")
local HandsInternal = PNC.Equipment.Internal
T.truthy(HandsInternal and HandsInternal.isAttackMode,
    "equipment hands internal did not load")

-- A remote record view carries only the mirrored stance boolean.
local view = { id = "npc_view", runtime = { combatStance = false } }
T.falsy(HandsInternal.isAttackMode(view),
    "idle record view keeps the weapon holstered")
view.runtime.combatStance = true
T.truthy(HandsInternal.isAttackMode(view),
    "fighting record view presents the weapon in hand")

-- An authority record with a refreshed hold presents the weapon even with no
-- target lease and no attack action in flight.
local authority = armedRecord()
Stance.Maintain(authority)
T.truthy(HandsInternal.isAttackMode(authority),
    "authority record in fighting mode presents the weapon in hand")

-- The same record holsters once the hold expires.
now = now + holdMs + 1
T.falsy(HandsInternal.isAttackMode(authority),
    "disengaged authority record holsters the weapon")

T.finish("pnc_combat_stance_smoke")