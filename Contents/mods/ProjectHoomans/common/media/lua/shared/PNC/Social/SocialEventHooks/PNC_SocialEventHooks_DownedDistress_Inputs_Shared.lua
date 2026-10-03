if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local now = H.Now
local clean = H.Clean
local flavorConst = H.FlavorConst

-- ---------------------------------------------------------------------------
-- Server-side inputs for the resolver
-- ---------------------------------------------------------------------------

local function resolveThreat(record)
    local perception = PNC.Perception
    local threat
    if perception and type(perception.ResolveRecentAttacker) == "function" then
        local ok, resolved = pcall(perception.ResolveRecentAttacker, record, now())
        if ok then threat = resolved end
    end
    if not threat and record and record.runtime then
        threat = record.runtime.recentThreat
    end
    return threat
end

local function recordAttackerName(threat)
    if type(threat) ~= "table" then return nil end
    local id = threat.id
    if id == nil or id == "" then return nil end
    local registry = PNC.Registry
    local attackerRecord = registry and type(registry.Get) == "function"
        and registry.Get(id) or nil
    if attackerRecord then
        return clean(attackerRecord.displayName
            or attackerRecord.name or attackerRecord.id, nil)
    end
    return nil
end

-- Cross-faction standing, resolved by the faction service when available.
local function factionBandFor(record, listener)
    local factions = PNC.Factions
    if not factions or type(factions.GetFactionID) ~= "function" then
        return nil
    end
    local mine, theirs
    local ok, value = pcall(factions.GetFactionID, record)
    if ok then mine = value end
    if not mine then return nil end
    if listener == nil then return nil end
    local okOwned, listenerFaction = pcall(factions.GetFactionID, listener)
    if not okOwned then listenerFaction = nil end
    if listenerFaction and listenerFaction == mine then return "same" end
    if not listenerFaction then return nil end
    if type(factions.AreAtWar) == "function" then
        local okWar, atWar = pcall(factions.AreAtWar, mine, listenerFaction)
        if okWar and atWar == true then return "war" end
    end
    if type(factions.AreAllied) == "function" then
        local okAlly, allied = pcall(
            factions.AreAllied, mine, listenerFaction
        )
        if okAlly and allied == true then return "allied" end
    end
    return "different"
end

local function relationshipFor(record, playerKey)
    local social = record and record.social
    local relationships = social and social.relationships
    if not relationships or not playerKey then return nil end
    return relationships[playerKey]
end

local function relationshipState(relationship)
    return tostring(relationship and (
        relationship.state or relationship.category
    ) or "unknown")
end

local function relationshipTier(relationship)
    local state = relationshipState(relationship)
    if state == "enemy" or state == "rival" then return "reserved" end
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    if state == "friend" or approval >= 30 then return "warm" end
    if approval >= 10 or familiarity >= 5 then return "familiar" end
    return "reserved"
end

-- Is this record the listener's own follower/companion?  Ownership is a hard
-- "ally" signal regardless of the faction registry's availability.  The mod
-- exposes ownership through the command registry and the identity verifier;
-- both are optional here so the hook still works in a reduced environment.
local function isOwned(record, player)
    if not record or not player then return false end
    local commands = PNC.Commands
    if commands and type(commands.IsOwnedByPlayer) == "function" then
        local ok, owned = pcall(commands.IsOwnedByPlayer, record, player)
        if ok and owned ~= nil then return owned == true end
    end
    local identity = PNC.Identity
    local verifier = identity and identity.Verifier
    if verifier and type(verifier.IsOwnedByPlayer) == "function" then
        local ok, owned = pcall(verifier.IsOwnedByPlayer, record, player)
        if ok and owned ~= nil then return owned == true end
    end
    local runtime = record.runtime
    if runtime and runtime.ownerPlayerID then
        local playerID
        if type(player.getUsername) == "function" then
            playerID = player:getUsername()
        elseif type(player.getPlayerNum) == "function" then
            playerID = player:getPlayerNum()
        end
        playerID = clean(playerID, nil)
        if playerID and tostring(runtime.ownerPlayerID) == tostring(playerID) then
            return true
        end
    end
    -- A recruited NPC is group property; treat it as allied to any listener in
    -- the same faction rather than inventing an owner.
    return false
end

-- Build the resolver input for one (downed NPC, listener) pair.
local function buildInput(record, player, needInputs)
    local threat = resolveThreat(record)
    local playerKey = Hooks.ResolvePlayerKey
        and Hooks.ResolvePlayerKey(player) or nil
    local relationship = relationshipFor(record, playerKey)
    local band = factionBandFor(record, player)
    local factionID
    local otherFactionID
    local factions = PNC.Factions
    if factions and type(factions.GetFactionID) == "function" then
        local okMine, mine = pcall(factions.GetFactionID, record)
        if okMine then factionID = mine end
        local okTheirs, theirs = pcall(factions.GetFactionID, player)
        if okTheirs then otherFactionID = theirs end
    end
    local input = {
        threat = threat,
        relationshipState = relationshipState(relationship),
        relationshipTier = relationshipTier(relationship),
        isCompanion = isOwned(record, player),
        -- A recruited NPC belongs to a player group; without an owner match it
        -- is still addressed as a friendly rather than as an anonymous
        -- stranger, which is the safer reading of an existing relationship.
        isFollower = record.recruited == true,
        factionID = factionID,
        otherFactionID = otherFactionID,
    }
    if band == "war" then
        input.factionBand = (flavorConst().Audience or {}).HOSTILE
    elseif band == "allied" or band == "same" then
        input.factionBand = (flavorConst().Audience or {}).ALLY
    end
    -- Wound inputs are resolved once per call site, not per listener.
    if type(needInputs) == "table" then
        local key
        for key, value in pairs(needInputs) do
            input[key] = value
        end
    end
    return input, threat
end

H.ResolveThreat = resolveThreat
H.RecordAttackerName = recordAttackerName
H.FactionBandFor = factionBandFor
H.RelationshipFor = relationshipFor
H.RelationshipState = relationshipState
H.RelationshipTier = relationshipTier
H.IsOwned = isOwned
H.BuildInput = buildInput

return Hooks
