-- Shared companion recipient resolution for emotes, conversations, and
-- other player-to-NPC interactions. This keeps live/ownership/radius rules in
-- one place so each feature addresses the same NPCs.
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.CompanionTargetResolver = PNC.CompanionTargetResolver or {}

local Resolver = PNC.CompanionTargetResolver
local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Registry = PNC.Registry
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local Identity = PNC.NPCIdentityPresentation

local SCOPE_COLONISTS = "colonists"
local SCOPE_OTHER = "other"
local SCOPE_SOCIAL = "social"

Resolver.SCOPE_COLONISTS = SCOPE_COLONISTS
Resolver.SCOPE_OTHER = SCOPE_OTHER
Resolver.SCOPE_SOCIAL = SCOPE_SOCIAL

local function targetName(source)
    return Identity.GetName(source or { recruited = true })
end

local function hasOwnerIdentity(source)
    return source and (
        source.ownerUsername ~= nil
        or source.ownerOnlineID ~= nil
        or source.characterWindow
            and (
                source.characterWindow.ownerUsername ~= nil
                or source.characterWindow.ownerOnlineID ~= nil
            )
    ) or false
end

local function isCompanion(source)
    return Commands and Commands.IsCompanion
        and Commands.IsCompanion(source) == true
end

local function isClientTargetCandidate(source, player, radius, scope)
    local x
    local y
    local z
    local dx
    local dy
    if not source or not player
        or source.alive == false
        or tostring(source.presenceState or Const.PRESENCE_LIVE)
            ~= tostring(Const.PRESENCE_LIVE)
    then
        return false
    end
    if scope == SCOPE_COLONISTS then
        if not isCompanion(source) then return false end
        if hasOwnerIdentity(source)
            and (not Commands.IsOwnedByPlayer
                or not Commands.IsOwnedByPlayer(source, player))
        then
            return false
        end
    elseif scope == SCOPE_OTHER and isCompanion(source) then
        return false
    end
    x = tonumber(source.x)
    y = tonumber(source.y)
    z = tonumber(source.z)
    if x == nil or y == nil or z == nil then return false end
    if math.floor(z) ~= math.floor(tonumber(player:getZ()) or 0) then
        return false
    end
    dx = x - player:getX()
    dy = y - player:getY()
    return (dx * dx) + (dy * dy) <= radius * radius
end

local function pushCandidate(output, seen, player, source, radius, scope)
    local id = source and source.id and tostring(source.id) or nil
    local x
    local y
    local dx
    local dy
    if not id or seen[id] then return end
    if not isClientTargetCandidate(source, player, radius, scope) then
        return
    end
    x = tonumber(source.x)
    y = tonumber(source.y)
    if x == nil or y == nil then return end
    dx = x - player:getX()
    dy = y - player:getY()
    seen[id] = true
    output[#output + 1] = {
        id = id,
        name = targetName(source),
        attackType = Commands and Commands.GetCurrentAttackType
            and Commands.GetCurrentAttackType(source) or nil,
        distSq = (dx * dx) + (dy * dy),
        source = source,
    }
end

function Resolver.CollectNearbyTargets(player, radius, scope)
    local output = {}
    local seen = {}
    scope = Resolver.NormalizeScope(scope)
    local commandRadius = tonumber(radius)
        or tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
    local id
    local snapshot
    if not player or player.isDead and player:isDead() then return output end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            pushCandidate(
                output, seen, player, record, commandRadius, scope
            )
        end)
    end
    for id, snapshot in pairs(
        ClientState and ClientState.snapshots or {}
    ) do
        pushCandidate(
            output, seen, player, snapshot, commandRadius, scope
        )
    end
    table.sort(output, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    return output
end

function Resolver.CollectNearbyCompanions(player, radius)
    return Resolver.CollectNearbyTargets(player, radius, SCOPE_COLONISTS)
end

function Resolver.CollectNearbySocialTargets(player, radius)
    return Resolver.CollectNearbyTargets(player, radius, SCOPE_SOCIAL)
end

-- Player speech is a territory/colony-local presentation event, not a
-- proximity interaction.  Keep ownership and liveness validation, but do not
-- discard a colonist merely because FollowOwner has carried them away from
-- the player or because the server currently represents them abstractly.
local function isSpeechRecipient(source, player)
    if not source or not player or source.alive == false then
        return false
    end
    if not isCompanion(source) then return false end
    if hasOwnerIdentity(source)
        and (not Commands.IsOwnedByPlayer
            or not Commands.IsOwnedByPlayer(source, player))
    then
        return false
    end
    return true
end

local function pushSpeechRecipient(output, seen, player, source)
    local id = source and source.id and tostring(source.id) or nil
    local x = source and tonumber(source.x) or nil
    local y = source and tonumber(source.y) or nil
    local dx
    local dy
    if not id or seen[id] or not isSpeechRecipient(source, player) then
        return
    end
    if x ~= nil and y ~= nil and player.getX and player.getY then
        dx = x - player:getX()
        dy = y - player:getY()
    end
    seen[id] = true
    output[#output + 1] = {
        id = id,
        name = targetName(source),
        distSq = dx and dy and (dx * dx) + (dy * dy) or math.huge,
        source = source,
    }
end

function Resolver.CollectOwnedCompanions(player)
    local output = {}
    local seen = {}
    local id
    local snapshot
    if not player or player.isDead and player:isDead() then
        return output
    end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            pushSpeechRecipient(output, seen, player, record)
        end)
    end
    for id, snapshot in pairs(
        ClientState and ClientState.snapshots or {}
    ) do
        pushSpeechRecipient(output, seen, player, snapshot)
    end
    table.sort(output, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    return output
end

function Resolver.NormalizeMode(mode)
    mode = tostring(mode or "nearest")
    if mode == "nearby" or mode == "multiple" or mode == "group" then
        return "nearby"
    end
    return "nearest"
end

function Resolver.NormalizeScope(scope)
    scope = tostring(scope or SCOPE_COLONISTS)
    if scope == SCOPE_OTHER
        or scope == "non_colonists"
        or scope == "non-colonist"
        or scope == "noncolonists"
    then
        return SCOPE_OTHER
    end
    if scope == SCOPE_SOCIAL or scope == "all" then
        return SCOPE_SOCIAL
    end
    return SCOPE_COLONISTS
end

function Resolver.ResolveRecipients(player, mode, radius, scope)
    local normalized = Resolver.NormalizeMode(mode)
    local normalizedScope = Resolver.NormalizeScope(scope)
    local candidates = Resolver.CollectNearbyTargets(
        player, radius, normalizedScope
    )
    local nearest = candidates[1]
    if normalized == "nearest" then
        return {
            mode = normalized,
            scope = normalizedScope,
            target = nearest,
            targets = nearest and { nearest } or {},
        }
    end
    return {
        mode = normalized,
        scope = normalizedScope,
        target = nearest,
        targets = candidates,
    }
end

-- Convert a target result into the richer entry shape consumed by the shared
-- conversation definition.
function Resolver.BuildConversationEntry(target)
    local source = target and target.source or target
    local id = tostring(target and target.id or source and source.id or "")
    local snapshot = ClientState and ClientState.snapshots
        and ClientState.snapshots[id] or target and target.snapshot
        or source and source.snapshot or nil
    local record = Registry and Registry.Get and Registry.Get(id)
        or target and target.record
        or source and source.record
        or nil
    local zombie = target and target.zombie
        or source and source.zombie
        or Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(id)
        or nil
    if not record and not snapshot then
        record = source
    end
    return {
        id = id,
        name = target and target.name or targetName(record or snapshot or source),
        record = record,
        snapshot = snapshot,
        zombie = zombie,
        source = source,
    }
end

return Resolver
