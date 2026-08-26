if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance
local copy = Internal.copy
local IdentityVerifier = PNC.Identity
    and PNC.Identity.Verifier or nil

local function factionSummary(faction)
    local archetype = Archetypes.Get(faction.archetypeID)
    local mobile = faction.mobile
    local archetypeLabel = archetype and archetype.label
        or faction.archetypeID
    if mobile and mobile.active == true then
        if faction.archetypeID == "looter" then
            archetypeLabel = "Mobile Looter Group"
        elseif faction.archetypeID == "trader" then
            archetypeLabel = "Trading Caravan"
        end
    end
    local communities = PNC.Communities
        and PNC.Communities.GetForFaction
        and PNC.Communities.GetForFaction(faction.id)
        or {}
    local communityNames = {}
    local communityPopulation = 0
    local communitySupplies = {
        food = 0,
        medicine = 0,
        ammunition = 0,
        tools = 0,
        materials = 0,
    }
    for _, community in ipairs(communities) do
        communityNames[#communityNames + 1] =
            community.name .. " (" .. community.mode
                .. "/" .. community.status .. ")"
        if community.status == "active" then
            communityPopulation = communityPopulation
                + (tonumber(community.currentPopulation) or 0)
        end
        for category, amount in pairs(
            community.supplies or {}
        ) do
            communitySupplies[category] =
                (tonumber(communitySupplies[category]) or 0)
                + (tonumber(amount) or 0)
        end
    end
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        archetypeLabel = archetypeLabel,
        status = faction.status,
        leaderNPCID = faction.leaderNPCID,
        memberCount = Core.TableSize(faction.memberIDs),
        ownerPlayerKey = faction.ownerPlayerKey,
        playerMemberCount =
            Core.TableSize(faction.playerMemberKeys),
        createdAt = faction.createdAt,
        archivedAt = faction.archivedAt,
        tags = copy(faction.tags),
        policy = copy(faction.policy),
        emblem = copy(faction.emblem),
        mobile = copy(mobile),
        revision = faction.revision,
        communityCount = #communities,
        communityNames = communityNames,
        communityPopulation = communityPopulation,
        communitySupplies = communitySupplies,
    }
end

local function npcSummary(record)
    local affiliation = Factions.GetNPCAffiliation(record.id)
    local identity = IdentityVerifier
        and IdentityVerifier.BuildView(record, { includeOwner = true })
        or nil
    local identityVerification = IdentityVerifier
        and IdentityVerifier.Verify(record)
        or nil
    return {
        id = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        factionID = identity and identity.factionID
            or affiliation and affiliation.factionID or nil,
        tacticalClass = record.faction,
        recruited = identity and identity.recruited
            or record.recruited == true,
        colonyOwned = identity and identity.colonyOwned or false,
        identity = identity,
        identityVerification = identityVerification,
        recordRevision = record.recordRevision,
        presenceRevision = record.presenceRevision,
        affiliation = affiliation,
    }
end

local function targetSummary(target)
    if type(target) ~= "table" then return nil end
    return {
        kind = target.kind,
        id = target.id or target.npcID
            or target.onlineID or target.zombieId,
        username = target.username,
        visible = target.visible,
        threatening = target.threatening,
    }
end

local function relationshipChanges(record, playerKey)
    local output = {}
    local changes = record.runtime
        and record.runtime.relationshipDebugChanges or {}
    local first = math.max(1, #changes - 15)
    local index
    for index = first, #changes do
        local change = changes[index]
        if change.targetKey == playerKey then
            output[#output + 1] = copy(change)
            while #output > 5 do
                table.remove(output, 1)
            end
        end
    end
    return output
end


Internal.factionSummary = factionSummary
Internal.npcSummary = npcSummary
Internal.targetSummary = targetSummary
Internal.relationshipChanges = relationshipChanges

return Debug
