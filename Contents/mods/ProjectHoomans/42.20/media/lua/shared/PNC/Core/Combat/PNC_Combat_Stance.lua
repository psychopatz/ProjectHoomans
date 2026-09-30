--[[
    PNC Combat Stance

    Single source of truth for "this NPC is in fighting mode", which the
    equipment presentation lane reads to decide whether a weapon is held in
    hand or holstered.

    The stance is deliberately broader than a single attack action:

      * a live combat target lease, or
      * an attack action still in flight, or
      * the reaction window opened by the last attack.

    The reaction window is refreshed on every engagement tick, so a firearm
    reload, a ranged reposition, or a target re-acquisition no longer snaps the
    weapon back onto the back between shots.  Disengaging stops refreshing the
    window, so the weapon returns to the holster without any extra teardown.

    The stance never creates or moves items: it only answers whether attacking
    equipment should be presented in hand.

    Two distinct runtime fields are involved, deliberately named apart:

      * ``runtime.combatStanceUntil`` - authority-side hold expiry timestamp.
      * ``runtime.combatStance``      - the boolean mirrored into client record
        views by the presence snapshot, which have no authority runtime.
]]

PNC = PNC or {}
PNC.CombatStance = PNC.CombatStance or {}

local Stance = PNC.CombatStance
local Core = PNC.Core
local Const = PNC.Const

local DEFAULT_HOLD_MS = 6000

-- Non-combat behaviors that must never keep a weapon in hand.
local SUPPRESSED_BEHAVIORS = {
    Dead = true,
    Downed = true,
    Incapacitated = true,
}

local function resolveHoldMs()
    local configured = Const and Const.COMBAT_STANCE_HOLD_MS
    configured = tonumber(configured)
    if configured and configured > 0 then
        return configured
    end
    return DEFAULT_HOLD_MS
end

local function resolveNow(now)
    now = tonumber(now)
    if now ~= nil then
        return now
    end
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

-- Refresh the reaction window for one more hold period.
function Stance.Maintain(record, now)
    local runtime
    if not record then return false end
    runtime = record.runtime
    if type(runtime) ~= "table" then
        runtime = {}
        record.runtime = runtime
    end
    runtime.combatStanceUntil = resolveNow(now) + resolveHoldMs()
    return true
end

-- Drop the reaction window immediately.  Used by non-combat behaviors that
-- own the body while a stale attack hold may still be pending.
function Stance.Clear(record)
    if not record then return false end
    local runtime = record.runtime
    if type(runtime) ~= "table" then return false end
    runtime.combatStanceUntil = nil
    return true
end

function Stance.IsArmed(record, now)
    local runtime
    local behavior
    local attack
    local target
    local attackType
    if not record or record.alive == false then
        return false
    end
    if record.health and record.health.state == "incapacitated" then
        return false
    end
    behavior = record.activeBehavior
    if behavior and SUPPRESSED_BEHAVIORS[tostring(behavior)] == true then
        return false
    end
    runtime = record.runtime
    if type(runtime) ~= "table" then
        return false
    end
    -- An explicitly disabled attack type means the NPC must not present a
    -- weapon at all, even if a stale target lease is still attached.
    attackType = record.attackType
    if attackType ~= nil
        and Const
        and tostring(attackType) == tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    -- A committed action in flight always presents its weapon.
    attack = runtime.attackAction
    if type(attack) == "table" then
        local finishAt = tonumber(attack.finishAt)
        if finishAt == nil or resolveNow(now) < finishAt then
            return true
        end
    end
    -- A live lease keeps the weapon drawn even between swings and shots.
    target = runtime.target
    if type(target) == "table" and target.alertOnly ~= true then
        return true
    end
    -- Otherwise the last engagement decides, with a refreshed hold window.
    return resolveNow(now) < (tonumber(runtime.combatStanceUntil) or 0)
end

-- Presentation snapshot: the single boolean remote bodies need in order to
-- reproduce an in-hand weapon without reconstructing the whole combat runtime.
function Stance.Snapshot(record, now)
    return Stance.IsArmed(record, now) == true
end

return Stance
