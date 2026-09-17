-- Puppet-owned player animation adapter.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.PlayerAnimation = PNC.PuppetOpera.PlayerAnimation or {}

if not (PsychopatzCore and PsychopatzCore.Animation
    and PsychopatzCore.Animation.Player)
then
    require "PsychopatzCore/Animation/PsychopatzPlayerAnimationController"
end

local Adapter = PNC.PuppetOpera.PlayerAnimation
local Player = PsychopatzCore.Animation.Player
local OWNER_PREFIX = "ProjectHoomans.PuppetOpera:"

local function ownerFor(sessionID)
    return OWNER_PREFIX .. tostring(sessionID or "")
end

function Adapter.Start(sessionID, beat, track)
    track = track or beat and beat.player
    if type(beat) ~= "table" or type(track) ~= "table" then
        return false, "player_beat_missing"
    end
    if Adapter.Active then
        return false, "player_animation_owned_by_puppet_session"
    end
    local entry = track
    local body = Player.ResolveLocalPlayer()
    local options = {
        owner = ownerFor(sessionID),
        loop = false,
        actionEvents = {},
    }
    local accepted
    local reason
    local handle
    accepted, reason, handle = Player.Play(nil, entry, options)
    if accepted ~= true then return false, reason end
    Adapter.Active = {
        sessionId = tostring(sessionID),
        owner = options.owner,
        beatId = beat.id,
        entry = entry,
        handle = handle,
        body = body,
        startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
    return true, "player_animation_started", Adapter.Active
end

function Adapter.IsOwned(sessionID)
    return Adapter.Active ~= nil
        and tostring(Adapter.Active.sessionId or "") == tostring(sessionID or "")
end

function Adapter.Observe(sessionID)
    local active = Adapter.Active
    if not active or tostring(active.sessionId or "") ~= tostring(sessionID or "") then
        return false, "player_animation_not_owned"
    end
    local body = Player.ResolveLocalPlayer()
    if body ~= active.body then
        return false, "local_player_changed"
    end
    if body and body.isAttacking and body:isAttacking() then
        return false, "player_entered_combat"
    end
    if body and body.isPerformingAttackAnimation
        and body:isPerformingAttackAnimation()
    then
        return false, "player_entered_combat"
    end
    local runtime = Player.Runtime and Player.Runtime() or nil
    if runtime and runtime.active == true then
        if tostring(runtime.owner or "") ~= tostring(active.owner or "") then
            return false, "player_animation_ownership_lost"
        end
        return true, "playing"
    end
    local result = runtime and runtime.result or nil
    local resultAt = result and tonumber(result.at) or nil
    if not result or not resultAt
        or resultAt < tonumber(active.startedAt or 0)
    then
        return false, "player_animation_state_lost"
    end
    if result.ok ~= true then
        return false, "player_animation_interrupted:"
            .. tostring(result.reason or "unknown")
    end
    return true, "finished"
end

function Adapter.Stop(sessionID)
    local active = Adapter.Active
    if not active or tostring(active.sessionId or "") ~= tostring(sessionID or "") then
        return false, "player_animation_not_owned"
    end
    local stopped
    local reason
    stopped, reason = Player.Stop(active.handle, "puppet_opera_stop")
    if stopped ~= true then return false, reason end
    Adapter.Active = nil
    return true, "player_animation_stopped"
end

function Adapter.Clear(sessionID)
    if Adapter.Active
        and tostring(Adapter.Active.sessionId or "") == tostring(sessionID or "")
    then
        Adapter.Active = nil
        return true
    end
    return false
end

function Adapter.GetRuntime()
    return Player.Runtime and Player.Runtime() or {}
end

return Adapter
