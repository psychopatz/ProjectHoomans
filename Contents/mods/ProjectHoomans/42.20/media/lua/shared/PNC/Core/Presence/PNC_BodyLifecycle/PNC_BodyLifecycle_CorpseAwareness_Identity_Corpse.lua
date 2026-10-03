local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.IdentityDeps or {}
local safeDisplayText = Deps.safeDisplayText
local MAX_CORPSE_ITEMS_TO_SCAN = Deps.MAX_CORPSE_ITEMS_TO_SCAN
local CACHE_SCHEMA_VERSION = Deps.CACHE_SCHEMA_VERSION

local function modDataOf(object)
    if object and object.getModData then
        local data = object:getModData()
        if type(data) == "table" then return data end
    end
    return nil
end

local function itemFullType(item)
    if item and item.getFullType then
        local fullType = item:getFullType()
        if fullType then return tostring(fullType) end
    end
    return tostring(item and (item.fullType or item.type) or "")
end

local function itemModData(item)
    return modDataOf(item)
end

local function inspectCorpseItems(record, corpse)
    local expectedNPCID = tostring(record and record.id or "")
    local container = corpse and corpse.getContainer
        and corpse:getContainer()
        or corpse and corpse.getInventory
            and corpse:getInventory() or nil
    local items = container and container.getItems
        and container:getItems() or nil
    local identity
    local itemsScanned = 0

    local function inspect(item)
        local fullType = itemFullType(item)
        local data = itemModData(item)
        if fullType == "Base.IDcard" and data
            and data.PNC_IDCard == true
            and tostring(data.PNC_IDCardNPCId or "") == expectedNPCID
            and tonumber(data.PNC_IDCardVersion) == 1
        then
            identity = identity or {}
            identity.npcID = expectedNPCID
            identity.name = safeDisplayText(
                data.PNC_IDCardNPCName,
                "Unknown NPC"
            )
        elseif fullType == "Base.Necklace_DogTag" and data
            and data.PNC_FactionDogTag == true
            and tostring(data.PNC_FactionDogTagNPCId or "")
                == expectedNPCID
            and tonumber(data.PNC_FactionDogTagVersion) == 1
        then
            identity = identity or {}
            identity.factionID = tostring(
                data.PNC_FactionDogTagFactionId or ""
            )
            identity.factionName = safeDisplayText(
                data.PNC_FactionDogTagFactionName,
                ""
            )
        end
    end

    if not items then return nil end
    if items.size and items.get then
        local size = items:size()
        local lowerIndex
        local index
        size = math.max(0, tonumber(size) or 0)
        lowerIndex = math.max(0, size - MAX_CORPSE_ITEMS_TO_SCAN)
        for index = size - 1, lowerIndex, -1 do
            itemsScanned = itemsScanned + 1
            inspect(items:get(index))
            if identity and identity.name and identity.factionID
                and identity.factionID ~= ""
            then
                break
            end
        end
    elseif type(items) == "table" then
        for _, item in pairs(items) do
            itemsScanned = itemsScanned + 1
            inspect(item)
            if itemsScanned >= MAX_CORPSE_ITEMS_TO_SCAN then break end
            if identity and identity.name and identity.factionID
                and identity.factionID ~= ""
            then
                break
            end
        end
    end

    if not identity or identity.npcID ~= expectedNPCID
        or not identity.name or identity.name == ""
    then
        return nil
    end
    return identity
end

local function cacheCorpseIdentity(corpseData, identity)
    if type(corpseData) ~= "table" or type(identity) ~= "table" then
        return false
    end
    corpseData.PNC_CorpseAwarenessIdentityVersion = CACHE_SCHEMA_VERSION
    corpseData.PNC_CorpseAwarenessIdentityNPCId = tostring(
        identity.npcID or ""
    )
    corpseData.PNC_CorpseAwarenessIdentityToken = tostring(
        identity.token or ""
    )
    corpseData.PNC_CorpseAwarenessIdentityName = safeDisplayText(
        identity.name,
        "Unknown NPC"
    )
    corpseData.PNC_CorpseAwarenessFactionID = tostring(
        identity.factionID or ""
    )
    corpseData.PNC_CorpseAwarenessFactionName = safeDisplayText(
        identity.factionName,
        ""
    )
    return true
end

local function corpseIdentity(record, corpse, corpseData)
    local npcID = tostring(record and record.id or "")
    local token = tostring(
        corpseData.PNC_CorpseToken
            or record and record.corpseToken
            or record and record.corpse and record.corpse.token
            or ""
    )
    local cached
    if tonumber(corpseData.PNC_CorpseAwarenessIdentityVersion)
            == CACHE_SCHEMA_VERSION
        and tostring(corpseData.PNC_CorpseAwarenessIdentityNPCId or "")
            == npcID
        and tostring(corpseData.PNC_CorpseAwarenessIdentityToken or "")
            == token
    then
        cached = {
            npcID = npcID,
            name = safeDisplayText(
                corpseData.PNC_CorpseAwarenessIdentityName,
                "Unknown NPC"
            ),
            factionID = tostring(
                corpseData.PNC_CorpseAwarenessFactionID or ""
            ),
            factionName = safeDisplayText(
                corpseData.PNC_CorpseAwarenessFactionName,
                ""
            ),
            token = token,
        }
        if cached.name ~= "Unknown NPC" or corpseData.PNC_CorpseAwarenessIdentityName
            == "Unknown NPC"
        then
            return cached
        end
    end

    local found = inspectCorpseItems(record, corpse)
    if not found then return nil end
    found.token = token
    cacheCorpseIdentity(corpseData, found)
    return found
end

local Identity = Awareness.Internal.Identity or {}
Awareness.Internal.Identity = Identity
Identity.modDataOf = modDataOf
Identity.corpseIdentity = corpseIdentity
Identity.cacheCorpseIdentity = cacheCorpseIdentity
