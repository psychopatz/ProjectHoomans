-- Shared beat and track contracts consumed by model editing spokes.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local actorLabel = Internal.actorLabel
local actorDefinition = Internal.actorDefinition
local actorBinding = Internal.actorBinding
local findLiveActorRow = Internal.findLiveActorRow
local liveActorName = Internal.liveActorName
local actorDiscoveryRadius = Internal.actorDiscoveryRadius

local function trackForBeat(beat, actorID, actorKind)
    if not beat then return nil end
    actorID = tostring(actorID or "")
    local track
    if type(beat.tracks) == "table" and beat.tracks[actorID] then
        track = beat.tracks[actorID]
    else
        track = beat[actorID]
    end
    if type(track) == "table" and type(track.byKind) == "table" then
        return actorKind and track.byKind[tostring(actorKind)] or track
    end
    return track
end

local function beatTrackSummary(beat)
    local ids = {}
    local tracks = beat and beat.tracks or nil
    if type(tracks) == "table" then
        for actorID in pairs(tracks) do ids[#ids + 1] = tostring(actorID) end
    else
        if beat and beat.player then ids[#ids + 1] = "player" end
        if beat and beat.npc then ids[#ids + 1] = "npc" end
    end
    table.sort(ids)
    local parts = {}
    for _, actorID in ipairs(ids) do
        local definition = actorDefinition(actorID)
        local track = trackForBeat(
            beat,
            actorID,
            definition and definition.kind or nil
        )
        local identity = actorID
        if definition then
            identity = actorLabel(definition, actorID)
                .. " [slot=" .. tostring(actorID) .. "]"
            local binding = actorBinding(actorID, definition)
            if binding then
                local live = findLiveActorRow(
                    binding,
                    Model.GetLiveActorRows(actorDiscoveryRadius())
                )
                identity = identity .. " -> "
                    .. liveActorName(live, binding)
                    .. " [" .. tostring(binding) .. "]"
            end
        end
        local value
        if track and track.mode == "emote" then
            value = track.emote
        elseif track and track.action then
            value = track.action .. "/" .. tostring(track.anim or "-")
        else
            value = track and (track.bump or track.anim) or "-"
        end
        parts[#parts + 1] = identity .. "=" .. tostring(value or "-")
    end
    return table.concat(parts, " | ")
end

local function ensureTracks(beat)
    if not beat then return nil end
    beat.tracks = beat.tracks or {}
    if beat.tracks.player == nil and beat.player ~= nil then
        beat.tracks.player = beat.player
    end
    if beat.tracks.npc == nil and beat.npc ~= nil then
        beat.tracks.npc = beat.npc
    end
    return beat.tracks
end

local function uniqueID(prefix, values)
    local base = tostring(prefix or "actor")
    local candidate = base
    local serial = 2
    while values[candidate] do
        candidate = base .. "_" .. tostring(serial)
        serial = serial + 1
    end
    return candidate
end

local function beatAt(index)
    local draft = currentDraft()
    return draft and draft.beats and draft.beats[tonumber(index) or 1] or nil
end

Internal.trackForBeat = trackForBeat
Internal.beatTrackSummary = beatTrackSummary
Internal.ensureTracks = ensureTracks
Internal.uniqueID = uniqueID
Internal.beatAt = beatAt

return Model
