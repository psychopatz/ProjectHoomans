require "PNC/Debug/PNC_AnimationDebugCatalog"

PNC = PNC or {}
PNC.AnimationDebugPlayer = PNC.AnimationDebugPlayer or {}

local Player = PNC.AnimationDebugPlayer
local Internal = Player.Internal or {}
Player.Internal = Internal
local Catalog = PNC.AnimationDebugCatalog
local Core = PNC.Core
local Animation = PNC.Animation
local staleActiveAtLoad = Player.active
local Equipment = {}
local Track = {}
local Conditions = {}
local activeTrack

-- Direct body:PlayAnim* calls are part of the legacy ILuaGameCharacter
-- surface. Build 42's model path is driven by AnimationPlayer tracks, so the
-- debugger uses that path when it is exposed and retains the legacy call as a
-- compatibility fallback for older bodies/test doubles.
Player.holdPose = Player.holdPose ~= false
Player.forceRanged = Player.forceRanged == true

local SELECTOR_ADAPTERS = {
    targetseentime = {
        get = function(body)
            return body.getTargetSeenTime
                and body:getTargetSeenTime()
                or 0
        end,
        set = function(body, value)
            if body.setTargetSeenTime then
                body:setTargetSeenTime(tonumber(value) or 0)
            end
        end,
    },
    playerattackposition = {
        get = function(body)
            return body.getPlayerAttackPosition
                and tostring(body:getPlayerAttackPosition() or "")
                or ""
        end,
        set = function(body, value)
            if body.setPlayerAttackPosition then
                body:setPlayerAttackPosition(tostring(value or ""))
            end
        end,
    },
    hitforce = {
        get = function(body)
            return body.getHitForce
                and body:getHitForce()
                or 0
        end,
        set = function(body, value)
            if body.setHitForce then
                body:setHitForce(tonumber(value) or 0)
            end
        end,
    },
    hitreaction = {
        get = function(body)
            return body.getHitReaction
                and tostring(body:getHitReaction() or "")
                or ""
        end,
        set = function(body, value)
            if body.setHitReaction then
                body:setHitReaction(tostring(value or ""))
            end
        end,
    },
    sitonground = {
        get = function(body)
            return body.isSitOnGround
                and body:isSitOnGround() == true
                or false
        end,
        set = function(body, value)
            if body.setSitOnGround then
                body:setSitOnGround(value == true)
            end
        end,
    },
    frombehind = {
        get = function(body)
            return body.isHitFromBehind
                and body:isHitFromBehind() == true
                or false
        end,
        set = function(body, value)
            if body.setHitFromBehind then
                body:setHitFromBehind(value == true)
            end
        end,
    },
    fallonfront = {
        get = function(body)
            return body.isFallOnFront
                and body:isFallOnFront() == true
                or false
        end,
        set = function(body, value)
            if body.setFallOnFront then
                body:setFallOnFront(value == true)
            end
        end,
    },
}

-- These selectors are computed from engine state and have no safe public
-- setter. Writing them through setVariable produces warning spam and still
-- cannot make the corresponding XML branch true.
local READ_ONLY_SELECTORS = {
    bclient = true,
    bhastarget = true,
    bistargetissmallvehicle = true,
    bpassengerexposed = true,
    intrees = true,
    issitting = true,
    previousstate = true,
    waseating = true,
}

local function nowMillis()
    return Core and Core.Now and Core.Now() or 0
end

local function topologyName()
    if isClient and isClient() == true then return "multiplayer client" end
    if isServer and isServer() == true then return "dedicated server" end
    return "singleplayer"
end

local function bodyID(body)
    local modData = body
        and body.getModData
        and body:getModData()
        or nil
    return tostring(modData and modData.PNC_UUID or "")
end

local function getBodyFromPresence(npcId)
    local sync = PNC.ClientPresenceSync
    local id = tostring(npcId or "")
    if id == "" or not sync then return nil end
    if sync.BodyByID and sync.BodyByID[id] then
        return sync.BodyByID[id]
    end
    if sync.BodyByLease then
        for _, body in pairs(sync.BodyByLease) do
            if bodyID(body) == id then return body end
        end
    end
    return nil
end

function Player.ResolveBody(npcId, fallback)
    local requestedID = tostring(npcId or "")
    local fallbackID = bodyID(fallback)
    if fallback
        and (not fallback.isDead or fallback:isDead() ~= true)
        and (
            requestedID == ""
            or fallbackID == ""
            or fallbackID == requestedID
        )
    then
        return fallback
    end
    return getBodyFromPresence(npcId)
end

local function findBumpType(entry)
    if not entry or entry.state ~= "bumped" then return nil end
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name == "BumpType"
            and condition.kind == "STRING"
            and condition.value
            and condition.value ~= ""
        then
            return tostring(condition.value)
        end
    end
    return nil
end

local function invoke(target, methodName, ...)
    local method
    local ok
    local first
    local second
    if not target then return false, nil, "missing_target" end
    method = target[methodName]
    if type(method) ~= "function" then
        return false, nil, "missing_method:" .. tostring(methodName)
    end
    ok, first, second = pcall(method, target, ...)
    if not ok then return false, nil, tostring(first) end
    return true, first, second
end

local function readValue(target, methodName, ...)
    local ok
    local value
    ok, value = invoke(target, methodName, ...)
    return ok and value or nil
end

local function writeField(target, fieldName, value)
    if not target then return false end
    return pcall(function() target[fieldName] = value end)
end

function Player.CanPipeline(entry)
    return findBumpType(entry) ~= nil
end

function Player.GetPlaybackRoute(entry)
    if Player.CanPipeline(entry) then
        return "PNC BumpType → XML node"
    end
    if entry and entry.playable then
        return "resolved selectors + native animation track"
    end
    return "selectors only (no direct clip)"
end

function Player.GetEntryNote(entry)
    local state = tostring(entry and entry.state or "")
    if state == "attack" or state == "attack-network" then
        return "Zombie bite-graph guard; this PNC node intentionally uses an idle/aim clip. NPC weapon swings are under bumped."
    end
    if Player.CanPipeline(entry) then
        return "Engine XML playback through the same BumpType route used by live NPC actions."
    end
    return "Preview applies writable selectors, then owns a native animation track. Hold mode freezes its final frame."
end

local function isPipelineMode(mode)
    return mode == "pipeline" or mode == "xml_pipeline"
end

function Player.Stop(reason)
    local active = Player.active
    if not active then return false end
    local effects = PNC.ClientFirearmEffects
    local anchor = PNC.NameplateFirearmAnchor
    if effects
        and effects.IsSimulationActive
        and effects.IsSimulationActive(active.body, active.npcId)
        and effects.StopSimulation
    then
        effects.StopSimulation()
    end
    if anchor and anchor.IsTarget
        and anchor.IsTarget(active.body, active.npcId)
        and anchor.ClearTarget
    then
        anchor.ClearTarget()
    end
    if isPipelineMode(active.mode)
        and Animation
        and Animation.FinishBump
    then
        Animation.FinishBump(active.body, true)
    end
    Track.release(active)
    Equipment.restore(active)
    Conditions.restore(active)
    Conditions.clear(active)
    if active.body
        and active.body.setUseless
        and active.uselessBefore ~= nil
    then
        active.body:setUseless(active.uselessBefore)
    end
    -- The ranged switch is session-scoped. Closing/replacing the preview must
    -- never carry a temporary equipment preference into a later animation.
    Player.forceRanged = false
    Player.lastResult = {
        ok = true,
        reason = tostring(reason or "stopped"),
        at = nowMillis(),
        mode = active.mode,
        node = active.entry and active.entry.node or nil,
    }
    Player.active = nil
    return true
end

local function begin(
    entry,
    npcId,
    body,
    mode,
    record,
    applySelectors,
    options
)
    -- Keep the temporary ranged preference while replacing/replaying a clip.
    -- Player.Stop still clears it for an explicit stop or a failed start.
    local preserveRanged = Player.forceRanged == true
    Player.Stop("replaced")
    Player.forceRanged = preserveRanged
    body = Player.ResolveBody(npcId, body)
    if not body then
        Player.lastResult = {
            ok = false,
            reason = "selected NPC has no local live body",
            at = nowMillis(),
        }
        return nil, "no_local_body"
    end
    if not entry then
        Player.lastResult = {
            ok = false,
            reason = "no animation node selected",
            at = nowMillis(),
        }
        return nil, "no_entry"
    end
    local active = {
        body = body,
        npcId = tostring(npcId or bodyID(body)),
        entry = entry,
        mode = mode,
        record = record or {
            id = tostring(npcId or bodyID(body)),
            runtime = { debug = true },
        },
        startedAt = nowMillis(),
        previousVariables = {},
        skippedSelectors = {},
        bumpOptions = options,
        holdPose = Player.holdPose == true,
        poseHeld = false,
        previousEquipmentVariables = {},
        uselessBefore = body.isUseless
            and body:isUseless() == true
            or false,
    }
    Player.active = active
    if applySelectors ~= false then
        Conditions.save(active)
    end
    if Player.forceRanged then
        local rangedOK, rangedReason = Equipment.applyRanged(active)
        if not rangedOK then
            active.equipmentFailure = rangedReason
        end
    end
    Conditions.mark(active)
    return active
end

local function completeStart(active, ok, reason)
    local result = {
        ok = ok == true,
        reason = tostring(reason or (ok and "playing" or "failed")),
        at = nowMillis(),
        mode = active and active.mode or nil,
        node = active and active.entry and active.entry.node or nil,
    }
    if ok ~= true then
        Player.Stop(reason or "play_failed")
    end
    Player.lastResult = result
    print("[PNC][ANIMPLAYER] start"
        .. " ok=" .. tostring(result.ok)
        .. " npc=" .. tostring(active and active.npcId or "-")
        .. " mode=" .. tostring(result.mode or "-")
        .. " state=" .. tostring(
            active and active.entry and active.entry.state or "-"
        )
        .. " node=" .. tostring(result.node or "-")
        .. " clip=" .. tostring(
            active and active.entry and active.entry.anim or "-"
        )
        .. " reason=" .. tostring(result.reason)
        .. " skipped=" .. table.concat(
            active and active.skippedSelectors or {},
            ","
        ))
    return ok == true, reason
end

function Player.PlayXML(entry, npcId, body, record, options)
    local active, reason = begin(
        entry,
        npcId,
        body,
        "xml",
        record,
        true,
        options
    )
    if not active then return false, reason end
    local bumpType = findBumpType(entry)
    if bumpType and Animation and Animation.PlayBump then
        active.mode = "xml_pipeline"
        Conditions.mark(active)
        local ok, playReason = Animation.PlayBump(
            body,
            active.record,
            bumpType,
            options
        )
        return completeStart(
            active,
            ok,
            ok and "xml_pipeline_started"
                or playReason
        )
    end
    if not entry.playable or not entry.anim or entry.anim == "" then
        return completeStart(active, false, "node_has_no_clip")
    end
    if body.setUseless then body:setUseless(false) end
    local nativeOK, nativeReason = Track.nativePlay(active)
    if not nativeOK then
        if body.PlayAnimUnlooped then
            body:PlayAnimUnlooped(tostring(entry.anim))
            active.trackSource = "body.PlayAnimUnlooped"
        elseif body.PlayAnim then
            body:PlayAnim(tostring(entry.anim))
            active.trackSource = "body.PlayAnim"
        else
            return completeStart(active, false, nativeReason)
        end
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(body, "debug_xml_play", nil, true)
    end
    return completeStart(active, true, "xml_selectors_clip_started")
end

function Player.PlayPipeline(entry, npcId, body, record, options)
    local bumpType = findBumpType(entry)
    if not bumpType then return false, "node_has_no_bump_type" end
    local active, reason = begin(
        entry,
        npcId,
        body,
        "pipeline",
        record,
        true,
        options
    )
    if not active then return false, reason end
    if not Animation or not Animation.PlayBump then
        return completeStart(active, false, "pnc_pipeline_unavailable")
    end
    local ok, playReason = Animation.PlayBump(
        body,
        active.record,
        bumpType,
        options
    )
    return completeStart(active, ok, playReason)
end

function Player.PlayRaw(entry, npcId, body, record)
    local active, reason = begin(
        entry,
        npcId,
        body,
        "raw",
        record,
        false
    )
    if not active then return false, reason end
    if not entry.playable or not entry.anim or entry.anim == "" then
        return completeStart(active, false, "node_has_no_clip")
    end
    if body.setUseless then body:setUseless(false) end
    local nativeOK, nativeReason = Track.nativePlay(active)
    if not nativeOK then
        if body.PlayAnimUnlooped then
            body:PlayAnimUnlooped(tostring(entry.anim))
            active.trackSource = "body.PlayAnimUnlooped"
        elseif body.PlayAnim then
            body:PlayAnim(tostring(entry.anim))
            active.trackSource = "body.PlayAnim"
        else
            return completeStart(active, false, nativeReason)
        end
    end
    if PNC.AnimationTrace and PNC.AnimationTrace.Sample then
        PNC.AnimationTrace.Sample(body, "debug_raw_play", nil, true)
    end
    return completeStart(active, true, "raw_clip_started")
end

function Player.Replay()
    local active = Player.active
    if not active then return false, "nothing_to_replay" end
    local entry = active.entry
    local npcId = active.npcId
    local body = active.body
    local record = active.record
    if isPipelineMode(active.mode) then
        return Player.PlayPipeline(
            entry,
            npcId,
            body,
            record,
            active.bumpOptions
        )
    end
    if active.mode == "raw" then
        return Player.PlayRaw(entry, npcId, body, record)
    end
    return Player.PlayXML(
        entry,
        npcId,
        body,
        record,
        active.bumpOptions
    )
end

function Player.Finish()
    local active = Player.active
    if not active then return false, "nothing_playing" end
    if isPipelineMode(active.mode)
        and Animation
        and Animation.FinishBump
    then
        Animation.FinishBump(active.body, true)
        Player.lastResult = {
            ok = true,
            reason = "finish_signalled",
            at = nowMillis(),
            mode = active.mode,
            node = active.entry.node,
        }
        return true, "finish_signalled"
    end
    if active.body.reportEvent then
        active.body:reportEvent("ActiveAnimFinishing")
        Player.lastResult = {
            ok = true,
            reason = "active_anim_finishing_reported",
            at = nowMillis(),
            mode = active.mode,
            node = active.entry.node,
        }
        return true, "active_anim_finishing_reported"
    end
    return false, "finish_event_unavailable"
end

function Player.IsPreviewing(bodyOrId)
    local active = Player.active
    if not active then return false end
    if type(bodyOrId) == "string"
        or type(bodyOrId) == "number"
    then
        return active.npcId == tostring(bodyOrId)
    end
    return active.body == bodyOrId
end

function Player.IsHoldPoseEnabled()
    return Player.holdPose == true
end

function Player.SetHoldPose(enabled)
    Player.holdPose = enabled == true
    if Player.active then
        Player.active.holdPose = Player.holdPose
        if not Player.holdPose and Player.active.poseHeld then
            local active = Player.active
            local track = activeTrack(active)
            local duration = track and Track.duration(track) or 0
            if track
                and Track.setTime(track, 0)
                and Track.setPlaying(track, true)
            then
                active.poseHeld = false
                active.holdTime = nil
                active.trackDuration = duration
            end
        end
    end
    return Player.holdPose
end

function Player.HoldCurrentFrame()
    local active = Player.active
    if not active then return false, "nothing_playing" end
    if isPipelineMode(active.mode) then
        return false, "pipeline_pose_hold_unsupported"
    end
    return Track.hold(active)
end

function Player.IsRangedOverrideActive()
    return Player.active ~= nil and Player.active.equipmentSnapshot ~= nil
end

function Player.ToggleRangedWeapon()
    local active = Player.active
    local ok
    local reason
    if not active then return false, "nothing_playing" end
    if active.equipmentSnapshot then
        Equipment.restore(active)
        Player.forceRanged = false
        return false, "temporary_ranged_restored"
    end
    ok, reason = Equipment.applyRanged(active)
    if ok then Player.forceRanged = true end
    return ok, reason
end

function Player.Maintain(body, now)
    local active = Player.active
    if not active or active.body ~= body then return false end
    if body.isDead and body:isDead() then
        Player.Stop("body_dead")
        return false
    end
    -- Pipeline previews use the same topology contract as Bandits: useless in
    -- SP, useful in MP while ActionContext advances. Direct/raw clip playback
    -- has no bump lease and therefore keeps the body useful explicitly.
    if not isPipelineMode(active.mode) and body.setUseless then
        body:setUseless(false)
    end
    Conditions.mark(active)
    Track.maintain(active)
    if isPipelineMode(active.mode)
        and Animation
        and Animation.PumpBumpRelease
    then
        Animation.PumpBumpRelease(body, now or nowMillis())
    end
    Player.Observe(now)
    return true
end

function Player.Observe(now)
    local active = Player.active
    if not active then return false end
    now = tonumber(now) or nowMillis()
    local age = now - (tonumber(active.startedAt) or now)
    local stage = tonumber(active.observationStage) or 0
    local threshold = stage == 0 and 100
        or stage == 1 and 450
        or nil
    if not threshold or age < threshold then return false end
    active.observationStage = stage + 1
    local runtime = Player.Runtime()
    print("[PNC][ANIMPLAYER] observe"
        .. tostring(active.observationStage)
        .. " age=" .. tostring(math.max(0, age)) .. "ms"
        .. " npc=" .. tostring(active.npcId)
        .. " mode=" .. tostring(active.mode)
        .. " requested=" .. tostring(active.entry.anim or "-")
        .. " action=" .. tostring(runtime.actionState or "-")
        .. " animState=" .. tostring(runtime.animationState or "-")
        .. " bump=" .. tostring(runtime.bumpType or "-")
        .. " track=" .. tostring(runtime.track or "-")
        .. " time=" .. tostring(runtime.trackTime or "-")
        .. " weight=" .. tostring(runtime.trackWeight or "-"))
    return true
end

function Player.Runtime()
    local active = Player.active
    local body = active and active.body or nil
    return {
        topology = topologyName(),
        active = active ~= nil,
        npcId = active and active.npcId or nil,
        mode = active and active.mode or nil,
        node = active and active.entry and active.entry.node or nil,
        requestedState = active
            and active.entry
            and active.entry.state
            or nil,
        requestedClip = active
            and active.entry
            and active.entry.anim
            or nil,
        actionState = body
            and body.getCurrentActionContextStateName
            and tostring(
                body:getCurrentActionContextStateName() or ""
            )
            or "",
        previousActionState = body
            and body.getPreviousActionContextStateName
            and tostring(
                body:getPreviousActionContextStateName() or ""
            )
            or "",
        animationState = body
            and body.getAnimationStateName
            and tostring(body:getAnimationStateName() or "")
            or "",
        -- AdvancedAnimator is a non-table Java userdata in Build 42.19.
        -- Its public Java methods are intentionally not indexed from Lua.
        advancedState = "not Lua-exposed",
        bumpType = body
            and body.getBumpType
            and tostring(body:getBumpType() or "")
            or "",
        track = body
            and body.dbgGetAnimTrackName
            and tostring(body:dbgGetAnimTrackName(0, 0) or "")
            or "",
        trackTime = body
            and body.dbgGetAnimTrackTime
            and tonumber(body:dbgGetAnimTrackTime(0, 0))
            or nil,
        trackWeight = body
            and body.dbgGetAnimTrackWeight
            and tonumber(body:dbgGetAnimTrackWeight(0, 0))
            or nil,
        trackDuration = active and active.trackDuration or nil,
        trackSource = active and active.trackSource or nil,
        poseHeld = active and active.poseHeld == true or false,
        holdPose = active and active.holdPose == true or Player.holdPose == true,
        rangedOverride = active and active.equipmentOverride or nil,
        equipmentFailure = active and active.equipmentFailure or nil,
        trackFrame = body
            and body.dbgGetAnimTrackTime
            and math.max(
                0,
                math.floor(
                    (
                        tonumber(
                            body:dbgGetAnimTrackTime(0, 0)
                        ) or 0
                    ) * 30 + 0.0001
                )
            )
            or nil,
        useless = body
            and body.isUseless
            and body:isUseless() == true
            or false,
        result = Player.lastResult,
        skippedSelectors = active
            and active.skippedSelectors
            or {},
    }
end

function Player.Dump()
    local active = Player.active
    local runtime = Player.Runtime()
    print("[PNC][ANIMPLAYER] topology="
        .. tostring(runtime.topology)
        .. " npc=" .. tostring(runtime.npcId or "-")
        .. " mode=" .. tostring(runtime.mode or "-")
        .. " node=" .. tostring(runtime.node or "-")
        .. " state=" .. tostring(runtime.requestedState or "-")
        .. "/" .. tostring(runtime.actionState or "-")
        .. "/" .. tostring(runtime.advancedState or "-")
        .. " clip=" .. tostring(runtime.requestedClip or "-")
        .. " track=" .. tostring(runtime.track or "-")
        .. " bump=" .. tostring(runtime.bumpType or "-")
        .. " useless=" .. tostring(runtime.useless))
    if active
        and PNC.AnimationTrace
        and PNC.AnimationTrace.DumpBody
    then
        PNC.AnimationTrace.DumpBody(active.body)
    end
    return runtime
end

function Player.GetCatalog()
    return Catalog
end

Player.Internal = Player.Internal or {}
Player.Internal.Equipment = Equipment
Player.Internal.Track = Track
Player.Internal.Conditions = Conditions
Player.Internal.SELECTOR_ADAPTERS = SELECTOR_ADAPTERS
Player.Internal.READ_ONLY_SELECTORS = READ_ONLY_SELECTORS
Player.Internal.Animation = Animation
Player.Internal.invoke = invoke
Player.Internal.readValue = readValue
Player.Internal.writeField = writeField
require "PNC/Debug/PNC_AnimationDebugPlayer_Conditions"
require "PNC/Debug/PNC_AnimationDebugPlayer_Track"
require "PNC/Debug/PNC_AnimationDebugPlayer_Equipment"
activeTrack = Player.Internal.activeTrack

-- Lua reloads retain the PNC namespace. Recover a preview interrupted by an
-- earlier debugger break so it cannot keep snapshot animation ownership.
if staleActiveAtLoad and Player.active == staleActiveAtLoad then
    Player.Stop("module_reload")
end

return Player
