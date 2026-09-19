-- Selection summaries for assigned Puppet Opera animation tracks.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local actorDefinition = Internal.actorDefinition
local trackForBeat = Internal.trackForBeat

function Model.GetSelectionSummary(actorID)
    local beat = Model.GetSelectedBeat()
    actorID = tostring(actorID or State.selectedActorID or "")
    local actorKind = Model.GetActorKind(actorID)
    local track = trackForBeat(beat, actorID, actorKind)
    if not track then return "No track assigned" end
    local definition = actorDefinition(actorID)
    if definition and actorKind == "local_player" then
        if track.mode == "emote" then
            return tostring(track.emote or "-") .. " / emote"
        end
        return tostring(track.action or "-") .. " / " .. tostring(track.anim or "-")
    end
    if track.byKind then
        local variants = {}
        for kind, variant in pairs(track.byKind) do
            variants[#variants + 1] = tostring(kind) .. ":"
                .. tostring(variant.bump or variant.action or "-")
        end
        table.sort(variants)
        return table.concat(variants, " | ")
    end
    return tostring(track.bump or "-") .. " / " .. tostring(track.anim or "-")
end

return Model
