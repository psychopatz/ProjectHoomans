-- Recipient acquisition, world targeting, positioning, and highlights.
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Runtime = Internal.Runtime
local Resolver = PNC.CompanionTargetResolver
local Inline = Integration.Inline
local Targets = Internal.InlineChatTargets or {}
Internal.InlineChatTargets = Targets

local function resolveZombie(entry)
    local registry = PNC.Registry
    local id = tostring(entry and entry.id or "")
    if id ~= "" and registry and registry.GetLiveZombie then
        local live = registry.GetLiveZombie(id)
        if live and (not live.isDead or live:isDead() ~= true) then
            return live
        end
        local sync = PNC.ClientPresenceSync
        local presenceBody = sync and sync.ResolveBodyForNPC
            and sync.ResolveBodyForNPC(id, entry and entry.snapshot)
        if presenceBody
            and (not presenceBody.isDead or presenceBody:isDead() ~= true)
        then
            return presenceBody
        end
        return nil
    end
    if entry and entry.zombie
        and (not entry.zombie.isDead or entry.zombie:isDead() ~= true)
    then
        return entry.zombie
    end
    return nil
end

local function refreshPresenceBodies()
    local sync = PNC.ClientPresenceSync
    local internal = sync and sync.Internal
    if internal and internal.RefreshBodyMap then
        internal.RefreshBodyMap(Runtime.Now())
    end
end

function Targets.ClearHighlights(playerIndex)
    local active = Inline.highlightedZombies or {}
    for _, zombie in pairs(active) do
        if zombie and zombie.setOutlineHighlight then
            zombie:setOutlineHighlight(playerIndex, false)
        end
    end
    Inline.highlightedZombies = {}
end

function Targets.RefreshHighlights(playerIndex)
    local previous = Inline.highlightedZombies or {}
    local current = {}
    refreshPresenceBodies()
    for _, entry in ipairs(Inline.entries or {}) do
        local id = tostring(entry and entry.id or "")
        local zombie = resolveZombie(entry)
        if id ~= "" and zombie and zombie.setOutlineHighlight then
            current[id] = zombie
            zombie:setOutlineHighlight(playerIndex, true)
            if zombie.setOutlineHighlightCol then
                zombie:setOutlineHighlightCol(
                    playerIndex,
                    Config.HIGHLIGHT_COLOR.r,
                    Config.HIGHLIGHT_COLOR.g,
                    Config.HIGHLIGHT_COLOR.b,
                    Config.HIGHLIGHT_COLOR.a
                )
            end
        end
    end
    for id, zombie in pairs(previous) do
        if current[id] ~= zombie
            and zombie
            and zombie.setOutlineHighlight
        then
            zombie:setOutlineHighlight(playerIndex, false)
        end
    end
    Inline.highlightedZombies = current
    return current
end

Integration.RefreshInlineHighlights = function()
    return Targets.RefreshHighlights(0)
end

Integration.ClearInlineHighlights = function()
    Targets.ClearHighlights(0)
end

function Targets.CurrentView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

function Targets.DirectFromEntry(entry, player)
    local source = entry and (entry.source or entry.record or entry.snapshot)
        or nil
    local zombie = entry and entry.zombie or source and source.zombie or nil
    local id = tostring(entry and entry.id or source and source.id or "")
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(entry and entry.x)
        or tonumber(source and source.x)
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(entry and entry.y)
        or tonumber(source and source.y)
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(entry and entry.z)
        or tonumber(source and source.z)
    if id == "" or not player or x == nil or y == nil or z == nil then
        return nil
    end
    if zombie and zombie.isDead and zombie:isDead() then return nil end
    if math.floor(z) ~= math.floor(tonumber(player:getZ()) or 0) then
        return nil
    end
    local dx = x - player:getX()
    local dy = y - player:getY()
    if (dx * dx) + (dy * dy) > 20 * 20 then return nil end
    return {
        id = id,
        name = entry.name or source and source.name or "NPC",
        distSq = (dx * dx) + (dy * dy),
        source = entry,
        zombie = zombie,
        record = entry.record,
        snapshot = entry.snapshot,
    }
end

local function screenBounds(playerIndex)
    local core = getCore and getCore() or nil
    local width = core and core.getScreenWidth and core:getScreenWidth() or 1920
    local height = core and core.getScreenHeight and core:getScreenHeight() or 1080
    local left = getPlayerScreenLeft and getPlayerScreenLeft(playerIndex) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(playerIndex) or 0
    local playerWidth = getPlayerScreenWidth
        and getPlayerScreenWidth(playerIndex) or width
    local playerHeight = getPlayerScreenHeight
        and getPlayerScreenHeight(playerIndex) or height
    return left, top, left + playerWidth, top + playerHeight
end

function Targets.Position(playerIndex, player)
    local part = Inline.part
    if not part or not player or not isoToScreenX or not isoToScreenY then
        return false
    end
    if not player.getX or not player.getY or not player.getZ then
        return false
    end
    local screenX = isoToScreenX(
        playerIndex, player:getX(), player:getY(), player:getZ()
    )
    local screenY = isoToScreenY(
        playerIndex, player:getX(), player:getY(), player:getZ()
    )
    local left, top, right, bottom = screenBounds(playerIndex)
    local width = part:getWidth()
    local height = part:getHeight()
    local minX = left
    local maxX = math.max(left, right - width)
    local minY = top
    local maxY = math.max(top, bottom - height)
    local targetX = screenX - (width / 2)
    local targetY = screenY + Config.PLAYER_Y_OFFSET
    part:setX(math.max(minX, math.min(maxX, targetX)))
    part:setY(math.max(minY, math.min(maxY, targetY)))
    return true
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
    local mode = Resolver.NormalizeMode(
        options.mode or Inline.mode or Config.MODE_NEAREST
    )
    local scope = Resolver.NormalizeScope(
        options.scope or Inline.scope or Config.SCOPE_COLONISTS
    )
    local resolved
    if options.cycleNearest and mode == Config.MODE_NEAREST then
        resolved = resolveNearestCycle(player, Inline.targetID, scope)
    else
        resolved = Resolver.ResolveRecipients(player, mode, nil, scope)
    end
    if not resolved then return nil end
    if not resolved.target
        and scope == Config.SCOPE_COLONISTS
        and Resolver.SCOPE_SOCIAL
    then
        local social
        if options.cycleNearest and mode == Config.MODE_NEAREST then
            social = resolveNearestCycle(
                player, Inline.targetID, Config.SCOPE_SOCIAL
            )
        else
            social = Resolver.ResolveRecipients(
                player, mode, nil, Config.SCOPE_SOCIAL
            )
        end
        if social and social.target then resolved = social end
    end
    local primary = resolved.target
    if Inline.targetID
        and not options.cycleNearest
        and not options.selectClosest
    then
        local candidates = resolved.targets
        if mode == Config.MODE_NEAREST and #candidates == 0 then
            candidates = Resolver.CollectNearbyTargets(
                player, nil, scope
            )
        end
        local found = false
        for _, candidate in ipairs(candidates) do
            if tostring(candidate.id) == tostring(Inline.targetID) then
                primary = candidate
                found = true
                break
            end
        end
        if not found and Inline.directTarget then
            primary = Targets.DirectFromEntry(Inline.directTarget, player)
            found = primary ~= nil
            if found then resolved.targets = { primary } end
        end
        if not found then return nil end
    end
    if not primary then return nil end
    if mode == Config.MODE_NEAREST then resolved.targets = { primary } end
    return {
        primary = primary,
        targets = resolved.targets,
        scope = resolved.scope,
    }
end

Integration.ResolveInlineRecipients = function(player, options)
    return Targets.ResolveRecipients(player, options)
end

return Targets
