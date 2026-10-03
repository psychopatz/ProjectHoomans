local Player = PNC.AnimationDebugPlayer
local Internal = Player.Internal or {}
local Track = Internal.Track
local Animation = Internal.Animation
local invoke = Internal.invoke
local readValue = Internal.readValue
local writeField = Internal.writeField

local function activeTrack(active)
    if not active then return nil end
    return active.track
end

local function trackDuration(track)
    return tonumber(readValue(track, "getDuration")) or 0
end

local function trackTime(track)
    return tonumber(readValue(track, "getCurrentTimeValue"))
        or tonumber(readValue(track, "getCurrentTrackTime"))
        or 0
end

local function setTrackTime(track, value)
    local ok = invoke(track, "setCurrentTimeValue", tonumber(value) or 0)
    if not ok then return false end
    -- Keeping previousTimeValue at the same frame prevents a held track from
    -- repeatedly firing its non-looped-finished event on subsequent updates.
    invoke(track, "setPreviousTimeValue", tonumber(value) or 0)
    return true
end

local function setTrackPlaying(track, value)
    if writeField(track, "isPlaying", value == true) then return true end
    -- A zero speed is the safest fallback when Java public-field writes are
    -- not available through the current Kahlua bridge.
    if value ~= true then
        return invoke(track, "setSpeedDelta", 0.0)
    end
    return false
end

local function releaseOwnedTrack(active)
    local player
    local multiTrack
    local ok
    if not active or not active.track then return end
    player = active.animationPlayer
    multiTrack = player and readValue(player, "getMultiTrack") or nil
    if multiTrack then
        ok = invoke(multiTrack, "removeTrack", active.track)
        if ok then
            active.track = nil
            return
        end
    end
    -- If removeTrack is not Lua-exposed, reset marks currentClip empty and the
    -- engine removes the track on its next multi-track update.
    invoke(active.track, "reset")
    active.track = nil
end

local function nativePlayClip(active)
    local body = active and active.body or nil
    local ok
    local animationPlayer
    local track
    local reason
    if not body or type(body.getAnimationPlayer) ~= "function" then
        return false, "animation_player_unavailable"
    end
    ok, animationPlayer, reason = invoke(body, "getAnimationPlayer")
    if not ok or not animationPlayer then
        return false, "animation_player_unavailable"
    end
    ok, track, reason = invoke(
        animationPlayer,
        "play",
        tostring(active.entry.anim),
        active.entry.looped == true
    )
    if not ok then return false, "animation_player_play_failed" end
    if not track then return false, "animation_clip_not_found" end

    -- AnimationPlayer:play creates a raw track with a zero initial blend
    -- weight. Give this debugger-owned track visible full-body ownership.
    invoke(track, "setBlendWeight", 1.0)
    invoke(
        track,
        "setSpeedDelta",
        tonumber(active.entry.speed) or 1.0
    )
    writeField(track, "isPrimary", true)
    active.animationPlayer = animationPlayer
    active.track = track
    active.trackSource = "AnimationPlayer.play"
    active.nativeTrack = true
    active.trackDuration = trackDuration(track)
    return true
end

local function holdTrack(active, requestedTime)
    local track = activeTrack(active)
    local duration
    local time
    if not track then return false, "debug_track_unavailable" end
    duration = trackDuration(track)
    time = tonumber(requestedTime)
    if time == nil then time = duration > 0 and duration or trackTime(track) end
    if duration > 0 then time = math.min(duration, math.max(0, time)) end
    if not setTrackTime(track, time) then
        return false, "track_time_setter_unavailable"
    end
    if not setTrackPlaying(track, false) then
        return false, "track_pause_unavailable"
    end
    active.poseHeld = true
    active.holdTime = time
    active.trackDuration = duration
    return true
end

local function maintainTrack(active)
    local track = activeTrack(active)
    local duration
    local time
    local finished
    if not track or active.poseHeld == true or active.holdPose ~= true then
        return false
    end
    if active.entry.looped == true then return false end
    duration = trackDuration(track)
    time = trackTime(track)
    finished = readValue(track, "isFinished") == true
        or duration > 0 and time >= duration - 0.0001
    if not finished then return false end
    return holdTrack(active, duration)
end

Track.duration = trackDuration
Track.time = trackTime
Track.setTime = setTrackTime
Track.setPlaying = setTrackPlaying
Track.release = releaseOwnedTrack
Track.nativePlay = nativePlayClip
Track.hold = holdTrack
Track.maintain = maintainTrack
Internal.activeTrack = activeTrack
