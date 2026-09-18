-- Shared actor identity and live-actor contracts for Puppet Opera.
--
-- This module owns the small Internal surface shared by the live-actor
-- spokes and by the scene layout model.  It does not discover actors or
-- mutate editor state itself.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local Opera = Internal.Opera
local currentDraft = Internal.currentDraft
local translatedLabel = Internal.translatedLabel

local function actorLabel(definition, fallback)
    return translatedLabel(
        definition and definition.labelKey,
        definition and definition.label ~= ""
            and definition.label or fallback
    )
end

local function actorOrder(left, right)
    local order = {
        actor_1 = 1,
        actor_2 = 2,
        player = 1,
        npc = 2,
    }
    local leftOrder = order[left.id] or 10
    local rightOrder = order[right.id] or 10
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return tostring(left.id) < tostring(right.id)
end

local function firstActorID(draft)
    local first
    for id in pairs(draft and draft.actors or {}) do
        if not first or tostring(id) < tostring(first) then
            first = id
        end
    end
    return first or "player"
end

local function actorDefinition(actorID)
    local draft = currentDraft()
    return draft and draft.actors and draft.actors[tostring(actorID)] or nil
end

local function bindingMap()
    local id = tostring(State.blueprintID or "")
    State.actorBindings[id] = State.actorBindings[id] or {}
    return State.actorBindings[id]
end

local function actorBinding(actorID, definition)
    local bindings = bindingMap()
    local bound = bindings[tostring(actorID)]
    if bound and tostring(bound) ~= "" then return tostring(bound) end
    return nil
end

local function allowedActorKinds(definition)
    if not definition then return {} end
    if definition.kind then return { definition.kind } end
    local result = {}
    for _, kind in ipairs(definition.allowedKinds or {}) do
        result[#result + 1] = tostring(kind)
    end
    if #result == 0 then
        result = { "local_player", "nearby_live_npc" }
    end
    return result
end

local function kindAllowed(definition, actorKind)
    actorKind = tostring(actorKind or "")
    for _, kind in ipairs(allowedActorKinds(definition)) do
        if kind == actorKind then return true end
    end
    return false
end

-- This is a live-list identity, not a blueprint actor id. Keeping it
-- separate prevents a drag from the live list from being confused with the
-- scene's ordinary `player` slot.
local LIVE_PLAYER_ID = "__local_player__"

local function compactLiveID(value)
    local id = tostring(value or "")
    if id == "" or id == LIVE_PLAYER_ID then return nil end
    if #id <= 8 then return id end
    return string.sub(id, -8)
end

local function findLiveActorRow(id, rows)
    id = id and tostring(id) or nil
    if not id then return nil end
    for _, row in ipairs(rows or {}) do
        if tostring(row.id) == id then return row end
    end
    return nil
end

local function liveActorName(row, fallback)
    local name = row and row.name or fallback
    name = tostring(name or "")
    return name ~= "" and name or tostring(fallback or "Unknown actor")
end

local function actorDiscoveryRadius()
    return Opera and Opera.Config
        and tonumber(Opera.Config.actorDiscoveryRadius) or 12
end

Internal.actorLabel = actorLabel
Internal.actorOrder = actorOrder
Internal.firstActorID = firstActorID
Internal.actorDefinition = actorDefinition
Internal.bindingMap = bindingMap
Internal.actorBinding = actorBinding
Internal.allowedActorKinds = allowedActorKinds
Internal.kindAllowed = kindAllowed
Internal.LIVE_PLAYER_ID = LIVE_PLAYER_ID
Internal.compactLiveID = compactLiveID
Internal.findLiveActorRow = findLiveActorRow
Internal.liveActorName = liveActorName
Internal.actorDiscoveryRadius = actorDiscoveryRadius

return Model
