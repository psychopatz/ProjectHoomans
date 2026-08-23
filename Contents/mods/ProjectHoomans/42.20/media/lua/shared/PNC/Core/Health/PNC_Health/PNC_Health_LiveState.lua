--[[
    PNC Health
    Single writer for NPC HP, incapacitation, revive recovery, and death state.
    It also owns recent-damage timers that drive overhead combat visibility.
]]

PNC = PNC or {}
PNC.Health = PNC.Health or {}

local Health = PNC.Health
Health.Internal = Health.Internal or {}
local Internal = Health.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox

local function resolvePathService()
    return PNC.PathService
end

local function resolveAnimation()
    return PNC.Animation
end

local function resolveCombatTactics()
    return PNC.CombatTactics
end

local function resolveLiveBodyControl()
    return PNC.LiveBodyControl
end

local function shouldPreventZombieAttack(record)
    return not Settings.CanZombieTargetRecord(record)
        or (
            PNC.Stealth
            and PNC.Stealth.ShouldSuppressZombieAggro
            and PNC.Stealth.ShouldSuppressZombieAggro(record)
        )
end

function Health.Ensure(record)
    if not record.health then
        record.health = {
            current = Const.DEFAULT_HP_MAX,
            max = Const.DEFAULT_HP_MAX,
            state = "normal",
            lastDamageAt = 0,
            downedAt = 0,
            recentDamageUntil = 0,
            reviveUntil = 0,
            reviveProtectionUntil = 0,
        }
    end
    if record.health.recentDamageUntil == nil then
        record.health.recentDamageUntil = 0
    end
    if record.health.reviveUntil == nil then
        record.health.reviveUntil = 0
    end
    if record.health.reviveProtectionUntil == nil then
        record.health.reviveProtectionUntil = 0
    end
    if type(record.health.body) ~= "table" then
        record.health.body = {
            wounds = {}, parts = {}, bleedingRate = 0, openWoundCount = 0,
            bandagedWoundCount = 0, lastBleedAt = 0,
        }
    end
    return record.health
end

function Health.MarkRecentDamage(record, now)
    local health = Health.Ensure(record)
    local damageAt = tonumber(now) or Core.Now()
    health.lastDamageAt = damageAt
    health.recentDamageUntil = damageAt + Const.RECENT_DAMAGE_SHOW_MS
    record.runtime = record.runtime or {}
    record.runtime.inCombatUntil = math.max(
        tonumber(record.runtime.inCombatUntil or 0) or 0,
        damageAt + Const.DEBUG_COMBAT_HOLD_MS
    )
end

local function applyIncapacitatedLiveState(record, zombie)
    local Animation = resolveAnimation()
    local LiveBodyControl = resolveLiveBodyControl()
    local path = record and record.runtime and record.runtime.pathing or nil
    local moving = path and (path.phase == "requested" or path.phase == "active") and path.mode == "crawl"
    if not zombie then
        return
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(shouldPreventZombieAttack(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.INCAPACITATED_ENGINE_BUFFER)
    end
    if Animation and Animation.ApplyDowned
        and not (record.runtime and record.runtime.selfTreatment
            and record.runtime.selfTreatment.phase == "bandaging")
    then
        Animation.ApplyDowned(zombie, record, moving == true)
    end
end

local function applyNormalLiveState(record, zombie)
    local Animation = resolveAnimation()
    local LiveBodyControl = resolveLiveBodyControl()
    if not zombie then
        return
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(shouldPreventZombieAttack(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.DEFAULT_ENGINE_BUFFER)
    end
    if LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if Animation and Animation.ClearDowned then
        Animation.ClearDowned(zombie)
    end
    if Animation and Animation.Apply then
        Animation.Apply(zombie, record, "Idle")
    end
end

local function refreshNormalLiveBuffer(record, zombie)
    local LiveBodyControl = resolveLiveBodyControl()
    if not zombie then
        return
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(shouldPreventZombieAttack(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.DEFAULT_ENGINE_BUFFER)
    end
end

Internal.ResolvePathService = resolvePathService
Internal.ResolveAnimation = resolveAnimation
Internal.ResolveCombatTactics = resolveCombatTactics
Internal.ResolveLiveBodyControl = resolveLiveBodyControl
Internal.ShouldPreventZombieAttack = shouldPreventZombieAttack
Internal.ApplyIncapacitatedLiveState = applyIncapacitatedLiveState
Internal.ApplyNormalLiveState = applyNormalLiveState
Internal.RefreshNormalLiveBuffer = refreshNormalLiveBuffer
