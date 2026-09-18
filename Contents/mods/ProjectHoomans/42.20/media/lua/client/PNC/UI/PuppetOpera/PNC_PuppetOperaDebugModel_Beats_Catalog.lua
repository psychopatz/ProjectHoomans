-- Beat selection and row projections for the Puppet Opera model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local beatAt = Internal.beatAt
local beatTrackSummary = Internal.beatTrackSummary

function Model.SelectBeat(index)
    local value = tonumber(index) or 1
    local draft = currentDraft()
    if not draft or not draft.beats or not draft.beats[value] then
        return false, "beat_not_found"
    end
    State.selectedBeatIndex = value
    Internal.touch()
    return true
end

function Model.GetSelectedBeatIndex()
    return State.selectedBeatIndex
end

function Model.GetSelectedBeat()
    return beatAt(State.selectedBeatIndex)
end

function Model.GetBeatRows()
    local draft = currentDraft()
    local rows = {}
    for index, beat in ipairs(draft and draft.beats or {}) do
        rows[#rows + 1] = {
            index = index,
            id = beat.id or ("beat_" .. tostring(index)),
            durationMs = beat.durationMs,
            player = beat.player,
            npc = beat.npc,
            tracks = beat.tracks,
            summary = beatTrackSummary(beat),
            selected = index == State.selectedBeatIndex,
        }
    end
    return rows
end

return Model
