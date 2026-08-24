-- Conversation context construction and settlement resolution.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local History = PNC.Conversation.History
local TextLoader = PNC.Conversation.TextLoader
local personalRelationshipQueries = Internal.PersonalRelationshipQueries
local relationshipCategory = Internal.RelationshipCategory
local audienceMap = Internal.AudienceMap
local worldAgeHours = Internal.WorldAgeHours

local function activeColony(factionID)
    if not PNC.Communities or not PNC.Communities.GetForFaction then
        return nil
    end
    for _, community in ipairs(PNC.Communities.GetForFaction(factionID) or {}) do
        if community.status == "active" then return community end
    end
    return nil
end

local function playerSettlement(player)
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local colony = faction and activeColony(faction.id) or nil
    local base = colony and PNC.BaseService and PNC.BaseService.GetForColony
        and PNC.BaseService.GetForColony(colony.id) or nil
    return faction, colony, base
end

function Authority.BuildContext(player, record, token)
    if not player or not record then return nil, "actors_unavailable" end
    if PNC.WorldDiscovery and PNC.WorldDiscovery.DiscoverNPCContext then
        PNC.WorldDiscovery.DiscoverNPCContext(player, record.id)
    end
    local playerEntityKey, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "conversation_block",
        worldAgeHours = worldAgeHours(),
    })
    if not playerEntityKey then return nil, reason end
    local parsed = PNC.EntityRef and PNC.EntityRef.Parse
        and PNC.EntityRef.Parse(playerEntityKey) or nil
    local relationshipQueries = personalRelationshipQueries()
    local relationship = relationshipQueries and relationshipQueries.Get
        and relationshipQueries.Get(record.id, playerEntityKey) or nil
    relationship = type(relationship) == "table" and relationship or {}
    relationship.morale = record.social and record.social.morale or 0
    local category = relationshipCategory(record, relationship)
    local faction, colony, base = playerSettlement(player)
    local playerProfile = PNC.SocialProfiles
        and PNC.SocialProfiles.GetPlayerProfile
        and PNC.SocialProfiles.GetPlayerProfile(
            parsed and parsed.characterUUID or playerEntityKey
        ) or nil
    local context = {
        player = player,
        npcRecord = record,
        npcID = tostring(record.id),
        token = tostring(token or ""),
        playerEntityKey = playerEntityKey,
        characterUUID = parsed and parsed.characterUUID or playerEntityKey,
        relationship = relationship,
        relationshipState = category,
        playerSocialProfile = playerProfile,
        playerPersonality = playerProfile,
        npcPersonality = record.personality or record.socialProfile,
        npcTraits = record.traits or record.socialTraits,
        audiences = audienceMap(record, category),
        allowHostileParley = audienceMap(record, category).hostile,
        worldAgeHours = worldAgeHours(),
        hour = worldAgeHours() % 24,
        worldID = tostring(getWorld and getWorld() or "world"),
        factionID = faction and faction.id or nil,
        colonyID = colony and colony.id or nil,
        baseEstablished = base ~= nil,
    }
    context.historyLookup = function(subjectID, scope)
        return History.Get(subjectID, { scope = scope }, context)
    end
    context.blockValidator = function(block)
        return TextLoader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
    end
    context.categoryValidator = function(categoryDefinition)
        return TextLoader.EnsureSource(
            categoryDefinition.textSource,
            { categoryDefinition.labelKey }
        )
    end
    return context
end

return Authority
