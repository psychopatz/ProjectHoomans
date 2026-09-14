-- Shared catalog and safety gate for transient NPC presentation reactions.
--
-- Portrait animation identifiers are intentionally resolved here before they
-- reach the live animation-scene arbiter. A live reaction is disposable: if
-- the NPC is moving, busy, seated, sleeping, or otherwise owned by another
-- presentation lane, the request is rejected without changing that owner.

PNC = PNC or {}
PNC.PresentationAnimations = PNC.PresentationAnimations or {}
PNC.PresentationAnimations.Internal =
    PNC.PresentationAnimations.Internal or {}

local Presentation = PNC.PresentationAnimations
local Const = PNC.Const
local Core = PNC.Core
local Scenes = PNC.AnimationScenes
local LiveBodyControl = PNC.LiveBodyControl

local DEFINITIONS = {
    ["greeting.wavehi"] = {
        id = "greeting.wavehi",
        portraitState = "wavehi",
        sceneId = "social.reaction.wavehi",
        bump = "WaveHi",
        durationMs = 2200,
    },
}

local MAX_EVENT_IDS = 64
local BUSY_ACTION_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["climbwall"] = true,
    ["falldown"] = true,
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["lunge"] = true,
    ["lungenetwork"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["pathfind"] = true,
    ["sitonground"] = true,
    ["staggerback"] = true,
    ["staggerback-knockeddown"] = true,
    ["thump"] = true,
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
}

Presentation.Definitions = DEFINITIONS

local function nowValue(options)
    if type(options) == "table" and options.now ~= nil then
        return tonumber(options.now) or 0
    end
    return Core and Core.Now and Core.Now() or 0
end

local function runtimeOf(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    return record.runtime
end

local function actionStateOf(zombie)
    local value
    if not zombie then return "" end
    if LiveBodyControl and LiveBodyControl.GetActionStateName then
        return string.lower(tostring(
            LiveBodyControl.GetActionStateName(zombie) or ""
        ))
    end
    if zombie.getActionStateName then
        value = zombie:getActionStateName()
    end
    return string.lower(tostring(value or ""))
end

local function moving(record, now)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local follow = runtime and runtime.followState or nil
    local intent = runtime and runtime.moveIntent or nil
    if follow and follow.ownerMoving == true then return true end
    if intent and intent.kind == "move" then return true end
    if path and (
        path.phase == "requested"
        or path.phase == "active"
        or now < (tonumber(path.visualMovingUntil) or 0)
        or now < (tonumber(path.specialMoveUntil) or 0)
    ) then
        return true
    end
    return navigation and (
        navigation.nativeActive == true
        or navigation.nativeTraversalState ~= nil
    ) or false
end

local function busyFacilityActivity(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    if activity ~= nil then return true end
    return record and record.orderSpec
        and record.orderSpec.kind == "facility_activity" or false
end

local function markEvent(record, eventID, now)
    local runtime = runtimeOf(record)
    local events = runtime.presentationAnimationEvents or {}
    runtime.presentationAnimationEvents = events
    local count = 0
    local oldestID
    local oldestAt
    local key = tostring(eventID or "")
    if key == "" then return true end
    if events[key] ~= nil then return false end
    events[key] = now
    for currentID, at in pairs(events) do
        count = count + 1
        if oldestAt == nil or (tonumber(at) or 0) < oldestAt then
            oldestID = currentID
            oldestAt = tonumber(at) or 0
        end
    end
    if count > MAX_EVENT_IDS and oldestID then
        events[oldestID] = nil
    end
    return true
end

function Presentation.Get(animationID)
    return DEFINITIONS[tostring(animationID or "")]
end

function Presentation.CanRequest(record, zombie, animationID, options)
    local definition = Presentation.Get(animationID)
    local runtime
    local health
    local treatment
    local now
    local actionState
    local modData
    if not definition then return false, "animation_missing" end
    if not record or not zombie then return false, "live_body_required" end
    if record.presenceState ~= (Const and Const.PRESENCE_LIVE or "live") then
        return false, "live_body_required"
    end
    if record.alive == false or zombie.isDead and zombie:isDead() then
        return false, "npc_unavailable"
    end
    now = nowValue(options)
    runtime = record.runtime or {}
    health = record.health or {}
    if tostring(health.state or "normal") ~= "normal" then
        return false, "health_state"
    end
    if LiveBodyControl and LiveBodyControl.IsPresentationCombatActive
        and LiveBodyControl.IsPresentationCombatActive(record, now)
    then
        return false, "combat"
    end
    if LiveBodyControl and LiveBodyControl.IsSeated
        and LiveBodyControl.IsSeated(record)
    then
        return false, "seated"
    end
    if LiveBodyControl and LiveBodyControl.IsSleeping
        and LiveBodyControl.IsSleeping(record)
    then
        return false, "sleeping"
    end
    if busyFacilityActivity(record) then
        return false, "facility_activity"
    end
    treatment = runtime.selfTreatment
    if treatment and treatment.phase == "bandaging"
        and now < (tonumber(treatment.finishAt) or 0)
    then
        return false, "treatment"
    end
    if moving(record, now) then return false, "movement" end
    actionState = actionStateOf(zombie)
    if BUSY_ACTION_STATES[actionState]
        or LiveBodyControl
        and LiveBodyControl.IsSuppressedActionState
        and LiveBodyControl.IsSuppressedActionState(actionState)
    then
        return false, "action_state"
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData and (modData.PNC_BumpReleasePending == true)
        and not runtime.animationScene
    then
        return false, "bump_release"
    end
    if modData and modData.PNC_BumpActionLease == true
        and not runtime.animationScene
    then
        return false, "animation_lease_active"
    end
    return true, nil, definition
end

function Presentation.Request(record, zombie, animationID, options)
    local allowed
    local reason
    local definition
    local started
    local result
    local now
    local eventID
    options = type(options) == "table" and options or {}
    now = nowValue(options)
    allowed, reason, definition = Presentation.CanRequest(
        record,
        zombie,
        animationID,
        options
    )
    if not allowed then return false, reason end
    if not Scenes or not Scenes.Request then
        return false, "animation_scene_unavailable"
    end
    eventID = tostring(options.eventID or "")
    if eventID ~= "" and not markEvent(record, eventID, now) then
        return false, "duplicate_event"
    end
    started, result = Scenes.Request(
        record,
        zombie,
        definition.sceneId,
        {
            now = now,
            reason = options.reason or "presentation_animation",
            durationMs = definition.durationMs,
        }
    )
    if started ~= true and eventID ~= "" then
        runtimeOf(record).presentationAnimationEvents[eventID] = nil
    end
    return started == true, started == true and result or result or reason
end

return Presentation
