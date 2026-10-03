local Debug = PNC.NameplateDebug
local settingEnabled = Debug._SettingEnabled
local infectionState = Debug._InfectionState
local ANIMATION_FRAME_RATE = 30
local DEBUG_TRACK_LAYER_COUNT = 4
local DEBUG_TRACKS_PER_LAYER = 4

function Debug.InfectionText(snapshot, settings)
    local infected
    local infection
    if not settingEnabled(settings, "debugShowInfection") then
        return ""
    end
    infected, infection = infectionState(snapshot)
    if not infected then
        return ""
    end
    return table.concat({
        "INFECTED: YES",
        "Stage: " .. tostring(infection.stage or "incubating"),
        "Fever: " .. tostring(
            math.floor((tonumber(infection.fever) or 0) + 0.5)
        ) .. "%",
        string.format(
            "Temp: %.1f C",
            tonumber(infection.temperatureC) or 37
        ),
    }, " | ")
end

-- IsoGameCharacter exposes these debug accessors directly to Lua. They are
-- safe for empty layer/track slots and avoid indexing AnimationTrack or
-- AdvancedAnimator Java userdata, whose methods are not Lua-exposed.
function Debug.CaptureAnimationRuntime(zombie)
    local runtime = {
        actionState = "-",
        animationState = "-",
        clip = "",
        layer = nil,
        trackIndex = nil,
        time = nil,
        weight = nil,
        frame = nil,
        frameRate = ANIMATION_FRAME_RATE,
        trackCount = 0,
        updating = nil,
    }
    local best
    local layer
    local trackIndex
    if not zombie then return runtime end
    runtime.actionState = tostring(
        zombie.getCurrentActionContextStateName
            and zombie:getCurrentActionContextStateName()
            or zombie.getActionStateName
                and zombie:getActionStateName()
            or "-"
    )
    runtime.animationState = tostring(
        zombie.getAnimationStateName
            and zombie:getAnimationStateName()
            or "-"
    )
    if zombie.isAnimationUpdatingThisFrame then
        runtime.updating =
            zombie:isAnimationUpdatingThisFrame() == true
    end
    if not zombie.dbgGetAnimTrackName then return runtime end
    for layer = 0, DEBUG_TRACK_LAYER_COUNT - 1 do
        for trackIndex = 0, DEBUG_TRACKS_PER_LAYER - 1 do
            local name = tostring(
                zombie:dbgGetAnimTrackName(
                    layer,
                    trackIndex
                ) or ""
            )
            if name ~= "" then
                local time = zombie.dbgGetAnimTrackTime
                    and tonumber(
                        zombie:dbgGetAnimTrackTime(
                            layer,
                            trackIndex
                        )
                    )
                    or 0
                local weight = zombie.dbgGetAnimTrackWeight
                    and tonumber(
                        zombie:dbgGetAnimTrackWeight(
                            layer,
                            trackIndex
                        )
                    )
                    or 0
                local candidate = {
                    clip = name,
                    layer = layer,
                    trackIndex = trackIndex,
                    time = time,
                    weight = weight,
                }
                runtime.trackCount = runtime.trackCount + 1
                if not best
                    or weight > best.weight
                then
                    best = candidate
                end
            end
        end
    end
    if best then
        runtime.clip = best.clip
        runtime.layer = best.layer
        runtime.trackIndex = best.trackIndex
        runtime.time = best.time
        runtime.weight = best.weight
        runtime.frame = math.max(
            0,
            math.floor(
                math.max(0, tonumber(best.time) or 0)
                    * ANIMATION_FRAME_RATE
                    + 0.0001
            )
        )
    end
    return runtime
end

function Debug.AnimationTrackText(zombie)
    local runtime = Debug.CaptureAnimationRuntime(zombie)
    if runtime.clip == "" then
        return "TRACK clip=- state="
            .. tostring(runtime.actionState)
            .. "/" .. tostring(runtime.animationState)
            .. " frame@30=- weight=-"
    end
    return "TRACK clip=" .. tostring(runtime.clip)
        .. " slot=" .. tostring(runtime.layer)
        .. ":" .. tostring(runtime.trackIndex)
        .. " state=" .. tostring(runtime.actionState)
        .. "/" .. tostring(runtime.animationState)
        .. " time=" .. string.format(
            "%.3fs",
            tonumber(runtime.time) or 0
        )
        .. " frame@30=" .. tostring(runtime.frame)
        .. " weight=" .. string.format(
            "%.3f",
            tonumber(runtime.weight) or 0
        )
        .. " tracks=" .. tostring(runtime.trackCount)
        .. (
            runtime.updating ~= nil
                and " updating=" .. tostring(runtime.updating)
                or ""
        )
end

-- Dedicated scene diagnostics keep authority state and the actual local
-- animator on the same overlay. This makes a missing selector, a stuck
-- ActionContext, or an MP primitive-revision problem visible immediately.
