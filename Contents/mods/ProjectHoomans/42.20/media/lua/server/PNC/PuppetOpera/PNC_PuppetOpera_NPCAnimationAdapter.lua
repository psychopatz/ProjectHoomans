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

local function isLocomotiveCarrier(session, actor, beat)
    if type(beat) ~= "table" or beat.mode ~= "locomotive" then return false end
    if actor and actor.tethered == true then return false end
    local def = session and session.blueprint and session.blueprint.actors
        and actor and session.blueprint.actors[actor.id] or nil
    if def and type(def.coupling) == "table" and def.coupling.attachTo then
        return false
    end
    return true
end

local function isPlayerBody(body, refActor)
    if refActor and refActor.kind == "local_player" then return true end
    if type(instanceof) == "function" and body and instanceof(body, "IsoPlayer") then
        return true
    end
    return body ~= nil and body.isLocalPlayer ~= nil
end

local function isNPCMoving(body, refActor, now)
    if not body then return false end
    -- Only use player action-state checks for true IsoPlayer leaders.
    -- Note: IsoZombie inherits isPlayerMoving() from IsoGameCharacter, so
    -- checking `body.isPlayerMoving` would misclassify every zombie as a player!
    if isPlayerBody(body, refActor) then
        if body.getActionStateName then
            local st = tostring(body:getActionStateName() or "")
            if st == "movement" or st == "run" or st == "sprint"
                or st == "turningMovement180"
            then
                return true
            end
            if st == "strafe" then
                return body:isPlayerMoving() == true
            end
            if st ~= "" then
                return false
            end
        end
        return body:isPlayerMoving() == true
    end
    -- For IsoZombie NPC leaders, detect engine locomotion states, active
    -- path2/moveIntent/pathing lane, OR actual world displacement (covers
    -- fake_locomotion too). Keep hysteresis bounded to active intent/pathing
    -- so deferred-movement walk nodes stop cleanly on arrival with zero drift.
    local movingNow = false
    local hasActiveRoute = false
    if body.getPath2 and body:getPath2() ~= nil then
        movingNow = true
        hasActiveRoute = true
    end
    if not movingNow and body.getActionStateName then
        local st = tostring(body:getActionStateName() or "")
        if st == "walktoward" or st == "walktoward-network" or st == "pathfind"
            or st == "movement" or st == "run" or st == "sprint"
        then
            movingNow = true
        end
    end
    if not movingNow and body.isMoving and body:isMoving() == true then
        movingNow = true
    end
    local runtime = refActor and refActor.record
        and refActor.record.runtime or nil
    if runtime then
        if runtime.moveIntent and runtime.moveIntent.kind == "move" then
            movingNow = true
            hasActiveRoute = true
        elseif runtime.pathing and runtime.pathing.phase == "active" then
            movingNow = true
            hasActiveRoute = true
        end
    end
    local bx = body.getX and tonumber(body:getX()) or nil
    local by = body.getY and tonumber(body:getY()) or nil
    if refActor and bx and by then
        if refActor._lastCarryX and refActor._lastCarryY then
            local dx = bx - refActor._lastCarryX
            local dy = by - refActor._lastCarryY
            if (dx * dx + dy * dy) > 0.0001 then
                movingNow = true
            end
        end
        refActor._lastCarryX = bx
        refActor._lastCarryY = by
        local ts = tonumber(now) or 0
        if movingNow then
            refActor._lastCarryMovedAt = ts
        elseif hasActiveRoute
            and refActor._lastCarryMovedAt
            and ts - refActor._lastCarryMovedAt < 250
        then
            movingNow = true
        end
    end
    return movingNow
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
        if not isLocomotiveCarrier(session, actor, beat) then
            if body.isUseless then
                actor._savedUseless = body:isUseless() == true
            end
            holdAnimVarNPC(body)
        else
            -- Do not override setUseless for locomotive carriers:
            -- PNC_Animation_NativeLocomotion owns SP (useless=true for
            -- behavior2_move) vs MP (useless=false for client_goto).
            actor._savedUseless = nil
        end
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
        local leaderID = actor.tetherLeaderID
        local leader = leaderID and session.actors and session.actors[leaderID] or nil
        local refActor = leader or actor
        local refBody = refActor and refActor.body or body
        local moving = isNPCMoving(refBody, refActor, current)
        AnimVars.UpdateProgress(body, progress, moving)
        if not isLocomotiveCarrier(session, actor, beat) then
            holdAnimVarNPC(body)
        end
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
        if actor._savedUseless ~= nil and body and body.setUseless then
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
