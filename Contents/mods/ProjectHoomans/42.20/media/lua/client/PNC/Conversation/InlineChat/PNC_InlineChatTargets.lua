-- Recipient acquisition, world targeting, and highlights for inline chat.
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Conversation/InlineChat/PNC_InlineChatTargets_Layout"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Resolver = PNC.CompanionTargetResolver
local State = InlineChat.State
local Targets = Internal.Targets or {}
Internal.Targets = Targets

local function nowMs()
    return (PNC.Core and PNC.Core.Now and PNC.Core.Now())
        or (getTimeInMillis and getTimeInMillis()) or 0
end

local function resolveZombie(entry)
    local registry = PNC.Registry
    local id = tostring(entry and entry.id or "")
    if id ~= "" and registry and registry.GetLiveZombie then
        local live = registry.GetLiveZombie(id)
        if live and (not live.isDead or live:isDead() ~= true) then return live end
        local sync = PNC.ClientPresenceSync
        local body = sync and sync.ResolveBodyForNPC
            and sync.ResolveBodyForNPC(id, entry and entry.snapshot)
        if body and (not body.isDead or body:isDead() ~= true) then return body end
        return nil
    end
    if entry and entry.zombie and (not entry.zombie.isDead or entry.zombie:isDead() ~= true) then
        return entry.zombie
    end
    return nil
end

local function refreshPresenceBodies()
    local sync = PNC.ClientPresenceSync
    if sync and sync.RefreshBodyMap then sync.RefreshBodyMap(nowMs()) end
end

local function clearOutline(playerIndex, zombie)
    local hub = PNC.ContextHub
    if zombie and zombie.setOutlineHighlight
        and not (hub and hub.IsHighlighting and hub.IsHighlighting(playerIndex, zombie)) then
        zombie:setOutlineHighlight(playerIndex, false)
    end
end

function Targets.ClearHighlights(playerIndex)
    for _, zombie in pairs(State.highlightedZombies or {}) do
        clearOutline(playerIndex, zombie)
    end
    State.highlightedZombies = {}
end

function Targets.RefreshHighlights(playerIndex)
    local previous, current = State.highlightedZombies or {}, {}
    local c = Config.HIGHLIGHT_COLOR
    refreshPresenceBodies()
    for _, entry in ipairs(State.entries or {}) do
        local id = tostring(entry and entry.id or "")
        local zombie = resolveZombie(entry)
        if id ~= "" and zombie and zombie.setOutlineHighlight then
            current[id] = zombie
            zombie:setOutlineHighlight(playerIndex, true)
            if zombie.setOutlineHighlightCol then
                zombie:setOutlineHighlightCol(playerIndex, c.r, c.g, c.b, c.a)
            end
        end
    end
    for id, zombie in pairs(previous) do
        if current[id] ~= zombie then
            clearOutline(playerIndex, zombie)
        end
    end
    State.highlightedZombies = current
    return current
end

InlineChat.RefreshHighlights = function() return Targets.RefreshHighlights(0) end
InlineChat.ClearHighlights = function() Targets.ClearHighlights(0) end

function Targets.CurrentView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

function Targets.DirectFromEntry(entry, player)
    local source = entry and (entry.source or entry.record or entry.snapshot) or nil
    local zombie = entry and entry.zombie or source and source.zombie or nil
    local id = tostring(entry and entry.id or source and source.id or "")
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(entry and entry.x) or tonumber(source and source.x)
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(entry and entry.y) or tonumber(source and source.y)
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(entry and entry.z) or tonumber(source and source.z)
    if id == "" or not player or x == nil or y == nil or z == nil then return nil end
    if zombie and zombie.isDead and zombie:isDead() then return nil end
    if math.floor(z) ~= math.floor(tonumber(player:getZ()) or 0) then return nil end
    local dx, dy = x - player:getX(), y - player:getY()
    if (dx * dx) + (dy * dy) > 400 then return nil end
    return {
        id = id,
        name = entry.name or (source and source.name) or "NPC",
        distSq = (dx * dx) + (dy * dy),
        source = entry,
        zombie = zombie,
        record = entry.record,
        snapshot = entry.snapshot,
    }
end

local function resolveNearestCycle(player, currentID, scope)
    if Resolver.ResolveNearestCycle then
        return Resolver.ResolveNearestCycle(player, currentID, nil, scope)
    end
    local candidates = Resolver.CollectNearbyTargets
        and Resolver.CollectNearbyTargets(player, nil, scope) or {}
    local nextIndex = 1
    local current = currentID ~= nil and tostring(currentID) or nil
    if current and current ~= "" and #candidates > 0 then
        for index, candidate in ipairs(candidates) do
            if tostring(candidate.id) == current then
                nextIndex = (index % #candidates) + 1
                break
            end
        end
    end
    local target = candidates[nextIndex]
    return {
        mode = Config.MODE_NEAREST,
        scope = scope,
        target = target,
        targets = target and { target } or {},
    }
end

function Targets.ResolveRecipients(player, options)
    options = options or {}
    if not player or not Resolver then return nil end
    local mode = Resolver.NormalizeMode(options.mode or State.mode or Config.MODE_NEAREST)
    local scope = Resolver.NormalizeScope(options.scope or State.scope or Config.SCOPE_COLONISTS)
    local resolved
    if options.cycleNearest and mode == Config.MODE_NEAREST then
        resolved = resolveNearestCycle(player, State.targetID, scope)
    else
        resolved = Resolver.ResolveRecipients(player, mode, nil, scope)
    end
    if not resolved then return nil end
    if not resolved.target and scope == Config.SCOPE_COLONISTS and Resolver.SCOPE_SOCIAL then
        local social = (options.cycleNearest and mode == Config.MODE_NEAREST)
            and resolveNearestCycle(player, State.targetID, Config.SCOPE_SOCIAL)
            or Resolver.ResolveRecipients(player, mode, nil, Config.SCOPE_SOCIAL)
        if social and social.target then resolved = social end
    end
    local primary = resolved.target
    if State.targetID and not options.cycleNearest and not options.selectClosest then
        local candidates = resolved.targets
        if mode == Config.MODE_NEAREST and #candidates == 0 then
            candidates = Resolver.CollectNearbyTargets(player, nil, scope)
        end
        local found = false
        for _, candidate in ipairs(candidates) do
            if tostring(candidate.id) == tostring(State.targetID) then
                primary = candidate
                found = true
                break
            end
        end
        if not found and State.directTarget then
            primary = Targets.DirectFromEntry(State.directTarget, player)
            found = primary ~= nil
            if found then resolved.targets = { primary } end
        end
        if not found then return nil end
    end
    if not primary then return nil end
    if mode == Config.MODE_NEAREST then resolved.targets = { primary } end
    return { primary = primary, targets = resolved.targets, scope = resolved.scope }
end

InlineChat.ResolveRecipients = function(player, options)
    return Targets.ResolveRecipients(player, options)
end

return Targets
