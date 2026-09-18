-- Beat duration and list mutations for the Puppet Opera model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local copy = Internal.copy
local markChanged = Internal.markChanged
local beatAt = Internal.beatAt

function Model.SetBeatDuration(duration)
    local beat = Model.GetSelectedBeat()
    duration = tonumber(duration)
    if not beat then return false, "beat_not_found" end
    if not duration or duration ~= math.floor(duration)
        or duration < 100 or duration > 10000
    then
        return false, "duration_must_be_100_to_10000_ms"
    end
    beat.durationMs = duration
    markChanged()
    return true
end

function Model.AddBeat()
    local draft = currentDraft()
    if not draft then return false, "blueprint_not_found" end
    local source = beatAt(State.selectedBeatIndex) or draft.beats[1]
    if not source then return false, "beat_missing" end
    local beat = copy(source)
    local index = #draft.beats + 1
    beat.id = "beat_" .. tostring(index)
    draft.beats[index] = beat
    State.selectedBeatIndex = index
    markChanged()
    return true
end

function Model.DuplicateBeat()
    return Model.AddBeat()
end

function Model.RemoveBeat()
    local draft = currentDraft()
    if not draft or not draft.beats or #draft.beats <= 1 then
        return false, "at_least_one_beat_required"
    end
    table.remove(draft.beats, State.selectedBeatIndex)
    State.selectedBeatIndex = math.min(
        State.selectedBeatIndex,
        #draft.beats
    )
    markChanged()
    return true
end

function Model.MoveBeat(delta)
    local draft = currentDraft()
    local index = tonumber(State.selectedBeatIndex) or 1
    local nextIndex = index + (tonumber(delta) or 0)
    if not draft or not draft.beats or not draft.beats[nextIndex] then
        return false, "beat_move_out_of_range"
    end
    draft.beats[index], draft.beats[nextIndex] = draft.beats[nextIndex],
        draft.beats[index]
    State.selectedBeatIndex = nextIndex
    markChanged()
    return true
end

return Model
