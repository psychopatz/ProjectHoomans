-- Client-side relationship and identity projection for farewell flavor.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

require "PNC/Core/Identity/PNC_FlavorAddress"

local Context = PNC.Conversation.FarewellContext or {}
PNC.Conversation.FarewellContext = Context
local FlavorAddress = PNC.FlavorAddress

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function call(object, method)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object)
    return ok and value or nil
end

local function normalized(value)
    value = string.lower(clean(value, ""))
    return string.gsub(value, "[%s%-]", "_")
end

local function entryParts(entry)
    entry = type(entry) == "table" and entry or {}
    return entry,
        type(entry.snapshot) == "table" and entry.snapshot or {},
        type(entry.record) == "table" and entry.record or {}
end

local function firstValue(entry, snapshot, record, key)
    return entry[key] or snapshot[key] or record[key]
end

local function relationshipKind(entry, snapshot, record, summary, context)
    local generation = record.generation or snapshot.generation or {}
    return firstValue(entry, snapshot, record, "relationshipKind")
        or firstValue(entry, snapshot, record, "conversationRelationship")
        or firstValue(entry, snapshot, record, "relationshipCategory")
        or generation.relationshipKind
        or summary and (
            summary.relationshipKind or summary.category or summary.state
                or summary.status
        )
        or context.conversationRelationshipID
end

local function isHostile(entry, snapshot, record, context)
    local entryHostility = entry.hostility or {}
    local snapshotHostility = snapshot.hostility or {}
    local recordHostility = record.hostility or {}
    return context.playerHostile == true
        or context.tacticalClass == "hostile"
        or entry.tacticalClass == "hostile"
        or snapshot.tacticalClass == "hostile"
        or record.tacticalClass == "hostile"
        or entryHostility.attackPlayers == true
        or snapshotHostility.attackPlayers == true
        or recordHostility.attackPlayers == true
end

function Context.ResolveSocialRole(spec)
    local context = spec and spec.context or {}
    local entry, snapshot, record = entryParts(context.entry)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local npcID = clean(spec and spec.npcID or entry.id, nil)
    local summary = state.conversationRelationships
        and state.conversationRelationships[npcID] or nil
    local kind = normalized(relationshipKind(
        entry, snapshot, record, summary, context
    ))
    local tactical = normalized(firstValue(
        entry, snapshot, record, "tacticalClass"
    ) or context.tacticalClass)
    if isHostile(entry, snapshot, record, context)
        or kind == "hostile" or tactical == "hostile"
    then
        return "hostile"
    end
    if kind == "lover" or kind == "partner" or kind == "spouse" then
        return "lover"
    end
    local family = {
        brother = true, sister = true, mother = true, father = true,
        parent = true, child = true, son = true, daughter = true,
        family = true,
    }
    if family[kind] then return "family" end
    if kind == "member" or kind == "companion" or kind == "colonist"
        or context.npcType == "colonist" or context.npcType == "follower"
    then
        return "colonist"
    end
    return "neutral"
end

local function nameParts(fullName, firstName)
    fullName = clean(fullName, "Survivor")
    firstName = clean(firstName, string.match(fullName, "^(%S+)"))
    return fullName, firstName
end

function Context.Build(spec, role, npcID)
    local source = spec and spec.context or {}
    local entry = source.entry or {}
    local snapshot = entry.snapshot or {}
    local player = source.player or getSpecificPlayer and getSpecificPlayer(0)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local npcName = source.npcName or entry.displayName
        or snapshot.displayName or snapshot.name or npcID
    local identity = PNC.NPCIdentityPresentation
    if identity and type(identity.GetName) == "function" then
        local ok, resolved = pcall(identity.GetName, entry)
        if ok and clean(resolved, nil) then npcName = resolved end
    end
    local npcFull, npcFirst = nameParts(npcName)
    local playerID = clean(
        playerContext.characterUUID or playerContext.playerUUID
            or call(player, "getUsername") or call(player, "getOnlineID"),
        "local-player"
    )
    local playerAddress = FlavorAddress.ResolveForNPC({
        npcID = npcID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(entry, npcID),
        player = player,
        playerContext = playerContext,
        playerUUID = playerID,
        playerNameKnown = source.playerNameKnown,
        isFemale = source.playerIsFemale,
        state = state,
    })
    return {
        npcID = npcID,
        npcType = role,
        socialRole = role,
        relationshipState = source.conversationRelationshipID
            or source.relationshipState or role,
        player = playerAddress.addressName,
        playerName = playerAddress.addressName,
        playerAddressName = playerAddress.addressName,
        playerFullName = playerAddress.fullName,
        playerFirstName = playerAddress.firstName,
        playerSurname = playerAddress.surname,
        playerLastName = playerAddress.lastName,
        playerNameKnown = playerAddress.known,
        playerIsFemale = playerAddress.isFemale,
        playerNicknameID = playerAddress.nicknameID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(entry, npcID),
        npcName = npcFull,
        npcFullName = npcFull,
        npcFirstName = npcFirst,
        playerUUID = playerID,
    }, player, playerID
end

return Context
