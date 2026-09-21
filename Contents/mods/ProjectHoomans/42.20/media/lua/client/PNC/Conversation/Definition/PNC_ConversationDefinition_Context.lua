-- Identity, faction, and portrait projection for Conversation definitions.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Context = {}
local FlavorAddress = PNC.FlavorAddress
local IdentityPresentation = PNC.NPCIdentityPresentation
local Loader = Conversation.TextLoader

local SYSTEM_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}

local function systemText(key)
    Loader.EnsureSource(SYSTEM_SOURCE, { key })
    return PsychopatzCore.Conversation.Text.Resolve({
        key = key,
        domain = SYSTEM_SOURCE.domain,
    })
end

local function cleanName(value)
    value = type(value) == "string" and value or nil
    if not value then return nil end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or nil
end

local function nameParts(fullName, firstName, lastName)
    fullName = cleanName(fullName)
    firstName = cleanName(firstName)
    lastName = cleanName(lastName)
    if not firstName and fullName then
        firstName = string.match(fullName, "^(%S+)")
    end
    if not lastName and fullName then
        lastName = string.match(fullName, "^%S+%s+(.+)$")
    end
    if not fullName then
        fullName = table.concat({ firstName or "", lastName or "" }, " ")
        fullName = cleanName(fullName)
    end
    return fullName, firstName, lastName
end

local function npcIdentity(entry, projection, displayedName)
    local snapshot = projection and projection.snapshot
        or entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local identity = snapshot.identity or record.identity or {}
    local survivor = identity.survivor or snapshot.survivor
        or record.survivor or {}
    return nameParts(
        displayedName,
        survivor.forename or snapshot.forename or record.forename,
        survivor.surname or snapshot.surname or record.surname
    )
end

local function visibleIdentityArguments(
    entry,
    player,
    projection,
    clientState,
    npcName,
    npcKnown,
    npcID
)
    local stranger = systemText("identity.stranger")
    local playerContext = clientState and clientState.playerContext or {}
    local playerAddress = FlavorAddress.ResolveForNPC({
        npcID = npcID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(entry, npcID),
        player = player,
        playerContext = playerContext,
        playerUUID = playerContext.characterUUID or playerContext.playerUUID,
        state = clientState,
    })
    local npcFull, npcFirst, npcLast = npcIdentity(
        entry, projection, npcName
    )
    if not npcKnown then
        npcFull, npcFirst, npcLast = stranger, stranger, stranger
    end
    return {
        playerName = playerAddress.addressName,
        playerAddressName = playerAddress.addressName,
        playerFullName = playerAddress.fullName or stranger,
        playerFirstName = playerAddress.firstName or stranger,
        playerLastName = playerAddress.lastName or "",
        playerSurname = playerAddress.surname or "",
        playerNameKnown = playerAddress.known,
        playerIsFemale = playerAddress.isFemale,
        playerNicknameID = playerAddress.nicknameID,
        npcName = npcFull or stranger,
        npcFullName = npcFull or stranger,
        npcFirstName = npcFirst or npcFull or stranger,
        npcLastName = npcLast or "",
        npcSurname = npcLast or "",
    }
end

local function roleLabel(value)
    value = tostring(value or "")
    local output = {}
    local capitalize = true
    for index = 1, #value do
        local character = string.sub(value, index, index)
        if character == "_" then
            output[#output + 1] = " "
            capitalize = true
        else
            if capitalize then
                character = string.upper(character)
                capitalize = false
            end
            output[#output + 1] = character
        end
    end
    return table.concat(output)
end

Conversation.FormatRoleLabel = roleLabel

local function factionPresentation(entry)
    local faction = IdentityPresentation.GetFaction(entry)
    if type(faction) ~= "table" then return nil end
    local name = tostring(faction.name or "")
    local role = roleLabel(faction.role or faction.rank)
    if name == "" or role == "" then return nil end
    return {
        name = name,
        role = role,
        id = faction.id,
        emblem = faction.emblem,
    }
end

local function stablePortraitSignature(value, depth)
    local keys = {}
    local parts = {}
    local index
    local key
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return tostring(value or "") end
    if depth > 4 then return "[depth]" end
    for key, _ in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    for index = 1, #keys do
        key = keys[index]
        parts[#parts + 1] = tostring(key) .. "="
            .. stablePortraitSignature(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ";") .. "}"
end

local function portraitSpec(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local summary = snapshot.portrait or {}
    local equipment = snapshot.equipmentSummary
        or summary.equipment
        or record.equipment
        or { worn = {} }
    return {
        id = entry and entry.id,
        key = table.concat({
            tostring(entry and entry.id or ""),
            tostring(snapshot.identitySeed or summary.identitySeed
                or record.identitySeed or 1),
            tostring(snapshot.presenceRevision or 0),
            stablePortraitSignature(equipment),
        }, "|"),
        identitySeed = snapshot.identitySeed or summary.identitySeed
            or record.identitySeed or 1,
        isFemale = snapshot.isFemale == true
            or summary.isFemale == true or record.isFemale == true,
        -- Live NPCs use IsoZombie carriers for engine animation/replication.
        -- Conversation portraits must render the descriptor-backed human
        -- preview instead of exposing that carrier's zombie appearance.
        preferDescriptor = true,
        faceOnly = true,
        includeCurrentClothing = true,
        clothingMode = "current",
        appearance = snapshot.appearance or summary.appearance
            or record.appearance or {},
        equipment = equipment,
    }
end

local function identityProjection(entry)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local projection = clientState.npcPresentations
        and clientState.npcPresentations[npcID] or nil
    local verifiedDisclosures = clientState.identityDisclosureVerified
    local verifiedDisclosure = verifiedDisclosures
        and verifiedDisclosures[npcID] or nil
    local playerContext = clientState.playerContext or {}
    local identityClaimVerified = type(verifiedDisclosure) == "table"
        and verifiedDisclosure.verified == true
        and tostring(verifiedDisclosure.characterUUID or "")
            == tostring(playerContext.characterUUID or "")
    local learnedName = IdentityPresentation.GetFact(entry, "identity.name")
    local identityKnown = IdentityPresentation.IsNameKnown(entry)
    local storedName = identityClaimVerified
        and tostring(verifiedDisclosure.displayName or "") or ""
    local knownName = storedName ~= "" and storedName
        or learnedName and learnedName.value
        or projection and projection.displayName
    if (knownName == nil or tostring(knownName) == "") and identityKnown then
        knownName = IdentityPresentation.GetName(entry)
    end
    local state = identityClaimVerified and knownName
        and tostring(knownName) ~= "" and "known"
        or "unknown"
    if projection and not identityClaimVerified then
        -- Older saves may contain an identity fact learned through the
        -- premature disclosure route. It is not proof of a verified exchange.
        projection.canAskName = true
    end
    local name = state == "known"
        and tostring(knownName)
        or systemText("identity.stranger")
    return state, name, projection, clientState, identityClaimVerified
end

Context.FactionPresentation = factionPresentation
Context.IdentityProjection = identityProjection
Context.PortraitSpec = portraitSpec
Context.VisibleIdentityArguments = visibleIdentityArguments

return Context
