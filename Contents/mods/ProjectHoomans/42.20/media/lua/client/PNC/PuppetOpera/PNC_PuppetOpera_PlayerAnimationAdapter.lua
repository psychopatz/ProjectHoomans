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
local AnimVars = PNC.PuppetOpera.AnimVarAdapter
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimVarAdapter"
local OWNER_PREFIX = "ProjectHoomans.PuppetOpera:"

local function ownerFor(sessionID)
    return OWNER_PREFIX .. tostring(sessionID or "")
end

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function isBodyMoving(body)
    if not body then return false end
    if body.getActionStateName then
        local state = tostring(body:getActionStateName() or "")
        if state == "movement" or state == "run" or state == "sprint"
            or state == "turningMovement180"
        then
            return true
        end
        if state == "strafe" and body.isPlayerMoving then
            return body:isPlayerMoving() == true
        end
        if state ~= "" then
            return false
        end
    end
    if body.isPlayerMoving then
        return body:isPlayerMoving() == true
    end
    if body.isMoving then
        return body:isMoving() == true
    end
    return false
end

local function isSustainedBeat(beat)
    local mode = type(beat) == "table" and tostring(beat.mode or "") or ""
    return mode == "sustained" or mode == "locomotive"
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
    if entry.route == "anim_vars" then
        if not body then
            return false, "no_local_player"
        end
        if body.isDead and body:isDead() then
            return false, "player_is_dead"
        end
        local moving = isBodyMoving(body)
        local ok, reason = AnimVars.Apply(body, entry, {
            phase = entry.phase or beat.id or "play",
            moving = moving,
            progress = 0,
        })
        if not ok then
            return false, reason or "player_anim_vars_failed"
        end
        local mode = beat.mode or "timed"
        local savedBlock = body.isBlockMovement and body:isBlockMovement() or false
        local savedVault = body.isIgnoreAutoVault and body:isIgnoreAutoVault() or false
        if ISTimedActionQueue and type(ISTimedActionQueue.clear) == "function" then
            ISTimedActionQueue.clear(body)
        end
        if body.setMoving then body:setMoving(false) end
        if body.setPath2 then body:setPath2(nil) end
        if body.getPathFindBehavior2 then
            local pfb = body:getPathFindBehavior2()
            if pfb and pfb.reset then pfb:reset() end
        end
        if mode == "locomotive" then
            if body.setBlockMovement then body:setBlockMovement(false) end
            if body.setIgnoreAutoVault then body:setIgnoreAutoVault(true) end
            if body.setSprinting then body:setSprinting(false) end
        end
        local startX = body.getX and tonumber(body:getX()) or nil
        local startY = body.getY and tonumber(body:getY()) or nil
        Adapter.Active = {
            sessionId = tostring(sessionID),
            owner = ownerFor(sessionID),
            route = "anim_vars",
            beatId = beat.id,
            mode = mode,
            durationMs = tonumber(beat.durationMs) or 900,
            entry = entry,
            body = body,
            savedBlock = savedBlock,
            savedVault = savedVault,
            lastX = startX,
            lastY = startY,
            startedAt = nowMs(),
        }
        return true, "player_anim_vars_started", Adapter.Active
    end
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
        route = "player_action",
        beatId = beat.id,
        entry = entry,
        handle = handle,
        body = body,
        startedAt = nowMs(),
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
    if active.route == "anim_vars" then
        if not body or (body.isDead and body:isDead()) then
            AnimVars.Clear(active.body, active.entry)
            return false, "player_is_dead"
        end
        local elapsed = math.max(0, nowMs() - (tonumber(active.startedAt) or 0))
        local duration = tonumber(active.durationMs) or 900
        local sustained = isSustainedBeat(active)
        local progress = 0
        if duration > 0 then
            if sustained then
                progress = (elapsed / duration) % 1
            else
                progress = math.min(1, elapsed / duration)
            end
        end
        local movingNow = false
        if active.mode == "locomotive" then
            if body.setSprinting then body:setSprinting(false) end
            if body.setRunning and active.entry
                and active.entry.style ~= "carry_piggyback"
            then
                body:setRunning(false)
            end
            movingNow = isBodyMoving(body)
        end
        AnimVars.UpdateProgress(body, progress, movingNow)
        if not sustained and elapsed >= duration then
            return true, "finished"
        end
        return true, "playing"
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
    if active.route == "anim_vars" then
        AnimVars.Clear(active.body, active.entry)
        if active.mode == "locomotive" and active.body then
            if active.body.setBlockMovement then
                active.body:setBlockMovement(active.savedBlock == true)
            end
            if active.body.setIgnoreAutoVault then
                active.body:setIgnoreAutoVault(active.savedVault == true)
            end
        end
        Adapter.Active = nil
        return true, "player_anim_vars_stopped"
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
        if Adapter.Active.route == "anim_vars" then
            AnimVars.Clear(Adapter.Active.body, Adapter.Active.entry)
            if Adapter.Active.mode == "locomotive" and Adapter.Active.body then
                if Adapter.Active.body.setBlockMovement then
                    Adapter.Active.body:setBlockMovement(Adapter.Active.savedBlock == true)
                end
                if Adapter.Active.body.setIgnoreAutoVault then
                    Adapter.Active.body:setIgnoreAutoVault(Adapter.Active.savedVault == true)
                end
            end
        end
        Adapter.Active = nil
        return true
    end
    return false
end

function Adapter.GetRuntime()
    return Player.Runtime and Player.Runtime() or {}
end

return Adapter
