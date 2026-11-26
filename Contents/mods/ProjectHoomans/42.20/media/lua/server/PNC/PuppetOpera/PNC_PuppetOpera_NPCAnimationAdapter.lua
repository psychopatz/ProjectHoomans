-- Puppet-owned NPC presentation adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.NPCAnimation = PNC.PuppetOpera.NPCAnimation or {}

local Adapter = PNC.PuppetOpera.NPCAnimation
local Animation = PNC.Animation
local AnimVars = PNC.PuppetOpera.AnimVarAdapter
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimVarAdapter"
local Telemetry = PNC.PuppetOpera.Telemetry
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Telemetry"

local SESSION_KEY = "PNC_PuppetOperaAnimationSession"
local BUMP_KEY = "PNC_PuppetOperaAnimationBump"
local ROUTE_KEY = "PNC_PuppetOperaAnimationRoute"

local function modDataOf(body)
    return body and body.getModData and body:getModData() or nil
end

local function sessionMarkerMatches(body, sessionID)
    local modData = modDataOf(body)
    return modData ~= nil
        and tostring(modData[SESSION_KEY] or "")
            == tostring(sessionID or "")
end

local function owns(body, sessionID)
    local modData = modDataOf(body)
    if not sessionMarkerMatches(body, sessionID) then return false end
    if modData and modData[ROUTE_KEY] == "anim_vars" then return true end
    local expected = modData and tostring(modData[BUMP_KEY] or "") or ""
    local requested = modData
        and tostring(modData.PNC_BumpRequestedType or "") or ""
    return expected ~= "" and requested == expected
end

local function bumpFinished(body)
    if body and body.getVariableBoolean
        and body:getVariableBoolean("BumpAnimFinished") == true
    then
        return true
    end
    if body and body.getVariableString then
        local value = string.lower(tostring(
            body:getVariableString("BumpAnimFinished") or ""
        ))
        return value == "true" or value == "1"
    end
    return false
end

local function holdAnimVarNPC(body)
    if not body then return end
    if body.setUseless then body:setUseless(true) end
    if body.setMoving then body:setMoving(false) end
    if body.getPathFindBehavior2 then
        local pfb = body:getPathFindBehavior2()
        if pfb and pfb.reset then pfb:reset() end
    end
    if body.setPath2 then body:setPath2(nil) end
    if body.setTarget then body:setTarget(nil) end
    local stateName = body.getActionStateName
        and tostring(body:getActionStateName() or "") or ""
    if stateName == "bumped" then
        if body.setBumpType then body:setBumpType("") end
        if body.setVariable then body:setVariable("BumpAnimFinished", true) end
    end
    if stateName ~= "idle"
        and ZombieIdleState
        and ZombieIdleState.instance
        and body.changeState
    then
        body:changeState(ZombieIdleState.instance())
    end
end

function Adapter.IsOwned(body, sessionID)
    return owns(body, sessionID)
end

function Adapter.Start(session, actor, beat, track)
    track = track or beat and beat.npc
    if type(session) ~= "table" or type(actor) ~= "table"
        or type(beat) ~= "table" or type(track) ~= "table"
    then
        return false, "npc_beat_arguments_invalid"
    end
    local body = actor.body
    local record = actor.record
    if track.route == "anim_vars" then
        if not body or not record then
            return false, "npc_animation_actor_unavailable"
        end
        local modData = modDataOf(body)
        if not modData then return false, "npc_mod_data_unavailable" end
        if modData[SESSION_KEY] ~= nil
            and tostring(modData[SESSION_KEY] or "")
                ~= tostring(session.sessionId or "")
        then
            return false, "npc_animation_owned_by_other"
        end
        if body.isUseless then
            actor._savedUseless = body:isUseless() == true
        end
        holdAnimVarNPC(body)
        local ok, reason = AnimVars.Apply(body, track, {
            phase = track.phase or beat.id or "play",
            moving = false,
            progress = 0,
        })
        if not ok then return false, reason or "npc_anim_vars_failed" end
        modData[SESSION_KEY] = tostring(session.sessionId)
        modData[ROUTE_KEY] = "anim_vars"
        modData[BUMP_KEY] = nil
        actor.animationStartedAt = PNC.Core and PNC.Core.Now
            and PNC.Core.Now() or 0
        actor.animationOwned = true
        actor.animationTrack = track
        actor.lastReason = "npc_anim_vars_started"
        if Telemetry and Telemetry.LogAnimStart then
            Telemetry.LogAnimStart(session, actor, track)
        end
        return true, "npc_anim_vars_started"
    end
    local bump = tostring(track.bump or track.bumpType or "")
    local driver = PNC.AnimationDriver
    -- Support referencing any registered AnimationScenes / AnimationPacks
    -- sceneId directly from a PuppetOpera beat (inheriting modder overrides
    -- and hand props automatically).
    if bump == "" and track.sceneId and driver
        and type(driver.ResolveSceneTrack) == "function"
    then
        local resolvedTrack = driver.ResolveSceneTrack(track.sceneId)
        if resolvedTrack then
            bump = tostring(resolvedTrack.bump or "")
        end
    end
    if not body or not record or bump == "" then
        return false, "npc_animation_actor_unavailable"
    end
    local modData = modDataOf(body)
    if not modData then return false, "npc_mod_data_unavailable" end
    if modData[SESSION_KEY] ~= nil
        and tostring(modData[SESSION_KEY] or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_animation_owned_by_other"
    end
    local accepted
    local reason = nil
    local leaseUntil = tonumber(session.beatStartedAt or 0)
        + tonumber(beat.durationMs or 900)
        + 1500
    if driver and type(driver.Start) == "function" then
        accepted, reason = driver.Start(body, record, {
            ownerToken = "opera:" .. tostring(session.sessionId),
            forceTakeover = true,
            route = "bump",
            bump = bump,
            sceneId = track.sceneId
                or ("PuppetOpera:" .. tostring(session.sessionId)),
            sceneRevision = tonumber(session.revision) or 0,
            leaseUntil = leaseUntil,
            keepManagedUseless = false,
            nonCombat = track.nonCombat == true,
        })
    else
        if not Animation or not Animation.PlayBump then
            return false, "npc_animation_service_unavailable"
        end
        accepted, reason = Animation.PlayBump(
            body,
            record,
            bump,
            {
                sceneId = "PuppetOpera:" .. tostring(session.sessionId),
                sceneRevision = tonumber(session.revision) or 0,
                leaseUntil = leaseUntil,
                keepManagedUseless = false,
                nonCombat = track.nonCombat == true,
            }
        )
    end
    if accepted ~= true then return false, reason or "npc_animation_rejected" end
    modData[SESSION_KEY] = tostring(session.sessionId)
    modData[BUMP_KEY] = Animation.ResolveBumpType
        and Animation.ResolveBumpType(bump) or bump
    actor.animationStartedAt = PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0
    actor.animationOwned = true
    actor.lastReason = "npc_animation_started"
    if Telemetry and Telemetry.LogAnimStart then
        Telemetry.LogAnimStart(session, actor, track)
    end
    return true, "npc_animation_started"
end

function Adapter.Observe(session, actor, beat)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_animation_arguments_invalid"
    end
    local body = actor.body
    if not owns(body, session.sessionId) then
        return false, "npc_animation_ownership_lost"
    end
    local modData = modDataOf(body)
    if modData and modData[ROUTE_KEY] == "anim_vars" then
        local startedAt = tonumber(actor.animationStartedAt) or 0
        local current = PNC.Core and PNC.Core.Now and PNC.Core.Now() or startedAt
        local duration = tonumber(beat and beat.durationMs) or 900
        local mode = type(beat) == "table" and tostring(beat.mode or "") or ""
        local sustained = mode == "sustained" or mode == "locomotive"
        local elapsed = math.max(0, current - startedAt)
        local progress = 0
        if duration > 0 then
            if sustained then
                progress = (elapsed / duration) % 1
            else
                progress = math.min(1, elapsed / duration)
            end
        end
        local moving = actor.isMoving == true
        local leaderID = actor.tetherLeaderID
        local leader = leaderID and session.actors and session.actors[leaderID] or nil
        local refBody = (leader and leader.body) or body
        if refBody then
            if refBody.isPlayerMoving then
                moving = refBody:isPlayerMoving() == true
            elseif refBody.isMoving then
                moving = refBody:isMoving() == true
            end
        end
        AnimVars.UpdateProgress(body, progress, moving)
        holdAnimVarNPC(body)
        if not sustained and elapsed >= duration then
            actor.lastReason = "npc_animation_duration_complete"
            return true, "finished"
        end
        return true, "playing"
    end
    local active = Animation and Animation.IsBumpActionActive
        and Animation.IsBumpActionActive(
            body,
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        )
        or false
    if active then return true, "playing" end
    if bumpFinished(body) then
        actor.lastReason = "npc_animation_finished"
        return true, "finished"
    end
    local startedAt = tonumber(actor.animationStartedAt) or 0
    local current = PNC.Core and PNC.Core.Now and PNC.Core.Now() or startedAt
    local duration = tonumber(beat and beat.durationMs) or 900
    if current - startedAt >= duration then
        actor.lastReason = "npc_animation_duration_complete"
        return true, "finished"
    end
    return false, "npc_animation_interrupted"
end

function Adapter.Maintain(session, actor, beat, leaseUntil, track)
    track = track or beat and beat.npc
    if not owns(actor.body, session.sessionId) then
        return false, "npc_animation_ownership_lost"
    end
    if type(track) == "table" and track.route == "anim_vars" then
        return true, "npc_anim_vars_maintained"
    end
    if type(track) ~= "table" or not track.bump then
        return false, "npc_animation_track_missing"
    end
    if not Animation or not Animation.MaintainBump then
        return false, "npc_animation_service_unavailable"
    end
    local accepted
    local reason = nil
    accepted, reason = Animation.MaintainBump(
        actor.body,
        actor.record,
        track and track.bump,
        leaseUntil,
        {
            sceneId = "PuppetOpera:" .. tostring(session.sessionId),
            sceneRevision = tonumber(session.revision) or 0,
            keepManagedUseless = false,
            nonCombat = track.nonCombat == true,
        }
    )
    return accepted == true, reason or "npc_animation_maintained"
end

function Adapter.Release(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_animation_arguments_invalid"
    end
    local body = actor.body
    local modData = modDataOf(body)
    if not modData or not sessionMarkerMatches(body, session.sessionId) then
        return false, "npc_animation_not_owned"
    end
    if not owns(body, session.sessionId) then
        modData[SESSION_KEY] = nil
        modData[BUMP_KEY] = nil
        actor.animationOwned = false
        actor.lastReason = "npc_animation_ownership_lost"
        return false, "npc_animation_ownership_lost"
    end
    if modData[ROUTE_KEY] == "anim_vars" then
        AnimVars.Clear(body, actor.animationTrack)
        if body and body.setUseless then
            body:setUseless(actor._savedUseless == true)
        end
        actor._savedUseless = nil
        modData[SESSION_KEY] = nil
        modData[ROUTE_KEY] = nil
        modData[BUMP_KEY] = nil
        actor.animationOwned = false
        actor.animationTrack = nil
        actor.lastReason = "npc_anim_vars_released"
        return true, "released"
    end
    if Animation and Animation.FinishBump then
        Animation.FinishBump(
            body,
            true,
            {
                kind = "puppet_opera",
                sessionId = tostring(session.sessionId),
            }
        )
    end
    modData[SESSION_KEY] = nil
    modData[BUMP_KEY] = nil
    actor.animationOwned = false
    actor.lastReason = "npc_animation_released"
    return true, "released"
end

return Adapter
