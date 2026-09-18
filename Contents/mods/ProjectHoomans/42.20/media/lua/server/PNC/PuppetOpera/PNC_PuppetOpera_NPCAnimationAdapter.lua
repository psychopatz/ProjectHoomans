-- Puppet-owned NPC presentation adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.NPCAnimation = PNC.PuppetOpera.NPCAnimation or {}

local Adapter = PNC.PuppetOpera.NPCAnimation
local Animation = PNC.Animation

local SESSION_KEY = "PNC_PuppetOperaAnimationSession"
local BUMP_KEY = "PNC_PuppetOperaAnimationBump"

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
    local expected = modData and tostring(modData[BUMP_KEY] or "") or ""
    local requested = modData
        and tostring(modData.PNC_BumpRequestedType or "") or ""
    return sessionMarkerMatches(body, sessionID)
        and expected ~= ""
        and requested == expected
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
    local bump = tostring(track.bump or "")
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
    if not Animation or not Animation.PlayBump then
        return false, "npc_animation_service_unavailable"
    end
    local accepted
    local reason = nil
    accepted, reason = Animation.PlayBump(
        body,
        record,
        bump,
        {
            sceneId = "PuppetOpera:" .. tostring(session.sessionId),
            sceneRevision = tonumber(session.revision) or 0,
            leaseUntil = tonumber(session.beatStartedAt or 0)
                + tonumber(beat.durationMs or 900)
                + 1500,
            keepManagedUseless = false,
            nonCombat = track.nonCombat == true,
        }
    )
    if accepted ~= true then return false, reason or "npc_animation_rejected" end
    modData[SESSION_KEY] = tostring(session.sessionId)
    modData[BUMP_KEY] = Animation.ResolveBumpType
        and Animation.ResolveBumpType(bump) or bump
    actor.animationStartedAt = PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0
    actor.animationOwned = true
    actor.lastReason = "npc_animation_started"
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
