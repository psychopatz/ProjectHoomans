-- Companion mirror-sitting and approved-break ground sit controller.
-- Reuses AnimationScenes ("ambient.companion.sitGround") and LiveBodyControl.IsSeated
-- so safety/combat/movement preemption stays unified with zero split seating state.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local MirrorSit = Internal.MirrorSit or {}
Internal.MirrorSit = MirrorSit

local SCENE_ID = "ambient.companion.sitGround"
local MIRROR_SIT_MAX_DIST = 4.5
local MIRROR_STAND_DIST = 5.5
local MIRROR_DELAY_MIN_MS = 600
local MIRROR_DELAY_SPAN_MS = 750

local function safeBoolCall(obj, methodName)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return false end
    local ok, val = pcall(fn, obj)
    return ok == true and val == true
end

function MirrorSit.IsActorSeated(actor)
    if not actor then return false end
    -- NPC record check (shared with LiveBodyControl)
    if type(actor) == "table" and actor.id ~= nil and actor.runtime ~= nil then
        local lbc = PNC.LiveBodyControl
        if lbc and type(lbc.IsSeated) == "function" and lbc.IsSeated(actor) == true then
            return true
        end
        local scene = actor.runtime.animationScene
        if type(scene) == "table" and type(scene.id) == "string"
            and string.find(string.lower(scene.id), "sit", 1, true) ~= nil
        then
            return true
        end
        return false
    end
    -- Player / IsoGameCharacter check (Build 42 native methods)
    if safeBoolCall(actor, "isSitting") then return true end
    if safeBoolCall(actor, "isSitOnGround") then return true end
    if safeBoolCall(actor, "isSittingOnFurniture") then return true end
    return false
end

local function jitterDelayMs(record)
    local id = tostring(record and record.id or "0")
    local h = 17
    for i = 1, #id do
        h = (h * 31 + string.byte(id, i)) % 10007
    end
    return MIRROR_DELAY_MIN_MS + (h % MIRROR_DELAY_SPAN_MS)
end

local function hasActiveBreakSit(record, now)
    local rt = record and record.runtime or nil
    if type(rt) ~= "table" then return false end
    return now < (tonumber(rt.companionBreakSitUntil) or 0)
end

local function isInCombat(record, now)
    local rt = record and record.runtime or nil
    if type(rt) ~= "table" then return false end
    if rt.target ~= nil or rt.attackAction ~= nil or rt.combatTarget ~= nil then
        return true
    end
    return now < (tonumber(rt.inCombatUntil) or 0)
end

function MirrorSit.Stop(record, zombie, reason)
    local rt = record and record.runtime or nil
    local scenes = PNC.AnimationScenes
    if type(rt) == "table" then
        if type(rt.companionMirrorSit) == "table" then
            rt.companionMirrorSit.active = false
            rt.companionMirrorSit.pendingSince = nil
        end
        if reason == "combat" or reason == "hazard" or reason == "owner_vehicle" then
            rt.companionBreakSitUntil = nil
        end
    end
    if scenes and type(scenes.Stop) == "function"
        and rt and rt.animationScene and rt.animationScene.id == SCENE_ID
    then
        scenes.Stop(record, zombie, reason or "mirror_sit_end")
        return true
    end
    return false
end

function MirrorSit.TryStart(record, zombie, owner, ownerDist, followState, hazard, ownerEngaged, ownerVehicle, now)
    if not record or not zombie or record.alive == false then return false end
    local rt = record.runtime or {}
    record.runtime = rt
    local breakSit = hasActiveBreakSit(record, now)
    local ownerSeated = owner ~= nil and MirrorSit.IsActorSeated(owner)

    if ownerSeated then
        local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
        if beats and type(beats.OnLeaderActionObserved) == "function" then
            beats.OnLeaderActionObserved(owner, "sit", now)
        end
    end

    if ownerVehicle or ownerEngaged or (hazard and hazard.active == true)
        or isInCombat(record, now)
        or (followState and followState.ownerMoving == true and not breakSit)
    then
        if rt.companionMirrorSit then
            rt.companionMirrorSit.pendingSince = nil
            if rt.companionMirrorSit.active == true then
                MirrorSit.Stop(record, zombie, ownerVehicle and "owner_vehicle" or "combat")
            end
        end
        return false
    end

    if not ownerSeated and not breakSit then
        if rt.companionMirrorSit then
            rt.companionMirrorSit.pendingSince = nil
            if rt.companionMirrorSit.active == true then
                MirrorSit.Stop(record, zombie, "owner_stood_up")
            end
        end
        return false
    end

    if not breakSit then
        local dz = owner and owner.getZ and math.abs(owner:getZ() - (tonumber(record.z) or 0)) or 0
        if (tonumber(ownerDist) or 0) > MIRROR_SIT_MAX_DIST or dz >= 1 then
            if rt.companionMirrorSit then rt.companionMirrorSit.pendingSince = nil end
            return false
        end
    end

    local ms = rt.companionMirrorSit or {}
    rt.companionMirrorSit = ms
    if ms.active == true and rt.animationScene and rt.animationScene.id == SCENE_ID then
        return true
    end

    if not breakSit then
        if not ms.pendingSince then
            ms.pendingSince = now
            ms.delayMs = jitterDelayMs(record)
            return false
        end
        if now < (ms.pendingSince + (tonumber(ms.delayMs) or MIRROR_DELAY_MIN_MS)) then
            return false
        end
    end

    local scenes = PNC.AnimationScenes
    if not scenes or type(scenes.Start) ~= "function" then return false end
    local common = PNC.BehaviorCommon
    if common and type(common.HaltMovement) == "function" then
        common.HaltMovement(record, zombie, breakSit and "companion_break_sit" or "companion_mirror_sit")
    end
    local ok = scenes.Start(record, zombie, SCENE_ID, {
        reason = breakSit and "companion_break_sit" or "owner_seated",
        now = now,
    })
    if ok then
        ms.active = true
        ms.pendingSince = nil
        ms.startedAt = now
        ms.reason = breakSit and "companion_break_sit" or "owner_seated"
        record.activeBehavior = breakSit and "FollowOwner:break_sit" or "FollowOwner:mirror_sit"
        return true
    end
    return false
end

-- Called by AnimationScenes.Tick while ambient.companion.sitGround is active.
-- Stands the follower back up the instant the leader stands, moves away, or enters combat.
function MirrorSit.OnSceneTick(record, zombie, scene, now)
    if not record or not zombie or record.alive == false then return false end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    if isInCombat(record, now) then
        MirrorSit.Stop(record, zombie, "combat")
        return false
    end
    if hasActiveBreakSit(record, now) then
        return true
    end
    local common = PNC.BehaviorCommon
    local owner = common and common.GetOwner and common.GetOwner(record) or nil
    if not owner then
        MirrorSit.Stop(record, zombie, "owner_missing")
        return false
    end
    local ownerVehicle = owner.getVehicle and owner:getVehicle() or nil
    if ownerVehicle then
        MirrorSit.Stop(record, zombie, "owner_vehicle")
        return false
    end
    if not MirrorSit.IsActorSeated(owner) then
        MirrorSit.Stop(record, zombie, "owner_stood_up")
        return false
    end
    local ox = owner.getX and owner:getX() or tonumber(record.x) or 0
    local oy = owner.getY and owner:getY() or tonumber(record.y) or 0
    local oz = owner.getZ and owner:getZ() or tonumber(record.z) or 0
    local dx = (tonumber(record.x) or 0) - ox
    local dy = (tonumber(record.y) or 0) - oy
    if math.abs((tonumber(record.z) or 0) - oz) >= 1
        or (dx * dx + dy * dy) > (MIRROR_STAND_DIST * MIRROR_STAND_DIST)
    then
        MirrorSit.Stop(record, zombie, "owner_moved_away")
        return false
    end
    return true
end

return MirrorSit
