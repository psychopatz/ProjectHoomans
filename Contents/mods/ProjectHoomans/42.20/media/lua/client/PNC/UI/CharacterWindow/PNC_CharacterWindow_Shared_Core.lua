PNC = PNC or {}
PNC.CharacterWindowShared = PNC.CharacterWindowShared or {}

local Shared = PNC.CharacterWindowShared

local itemStatsCache = {}
local bodyTextureCache = {}

Shared.BodyParts = {
    { id = "Hand_L", index = 0, label = "Left Hand", labelKey = "UI_PNC_Character_BodyPart_LeftHand", texture = "left-hand" },
    { id = "Hand_R", index = 1, label = "Right Hand", labelKey = "UI_PNC_Character_BodyPart_RightHand", texture = "right-hand" },
    { id = "ForeArm_L", index = 2, label = "Left Forearm", labelKey = "UI_PNC_Character_BodyPart_LeftForearm", texture = "lower-left-arm" },
    { id = "ForeArm_R", index = 3, label = "Right Forearm", labelKey = "UI_PNC_Character_BodyPart_RightForearm", texture = "lower-right-arm" },
    { id = "UpperArm_L", index = 4, label = "Left Upper Arm", labelKey = "UI_PNC_Character_BodyPart_LeftUpperArm", texture = "upper-left-arm", maleNodeX = 10, femaleNodeX = 4 },
    { id = "UpperArm_R", index = 5, label = "Right Upper Arm", labelKey = "UI_PNC_Character_BodyPart_RightUpperArm", texture = "upper-right-arm", maleNodeX = -10, femaleNodeX = -4 },
    { id = "Torso_Upper", index = 6, label = "Upper Torso", labelKey = "UI_PNC_Character_BodyPart_UpperTorso", texture = "chest" },
    { id = "Torso_Lower", index = 7, label = "Lower Torso", labelKey = "UI_PNC_Character_BodyPart_LowerTorso", texture = "abdomen" },
    { id = "Head", index = 8, label = "Head", labelKey = "UI_PNC_Character_BodyPart_Head", texture = "head" },
    { id = "Neck", index = 9, label = "Neck", labelKey = "UI_PNC_Character_BodyPart_Neck", texture = "neck" },
    { id = "Groin", index = 10, label = "Groin", labelKey = "UI_PNC_Character_BodyPart_Groin", texture = "groin" },
    { id = "UpperLeg_L", index = 11, label = "Left Thigh", labelKey = "UI_PNC_Character_BodyPart_LeftThigh", texture = "left-thigh", nodeX = -2, nodeY = 10 },
    { id = "UpperLeg_R", index = 12, label = "Right Thigh", labelKey = "UI_PNC_Character_BodyPart_RightThigh", texture = "right-thigh", nodeX = 2, nodeY = 10 },
    { id = "LowerLeg_L", index = 13, label = "Left Shin", labelKey = "UI_PNC_Character_BodyPart_LeftShin", texture = "left-calf" },
    { id = "LowerLeg_R", index = 14, label = "Right Shin", labelKey = "UI_PNC_Character_BodyPart_RightShin", texture = "right-calf" },
    { id = "Foot_L", index = 15, label = "Left Foot", labelKey = "UI_PNC_Character_BodyPart_LeftFoot", texture = "left-foot", nodeX = -2 },
    { id = "Foot_R", index = 16, label = "Right Foot", labelKey = "UI_PNC_Character_BodyPart_RightFoot", texture = "right-foot", nodeX = 2 },
}

local BODY_PART_BY_ID = {}
for _, definition in ipairs(Shared.BodyParts) do
    BODY_PART_BY_ID[definition.id] = definition
end

local function safeCall(target, methodName, ...)
    local method = target and target[methodName] or nil
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function createItem(fullType)
    if PNC.Equipment and PNC.Equipment.CreateItem then
        local item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table" and item[1] then item = item[1] end
        if item then return item end
    end
    if instanceItem then
        local ok, item = pcall(instanceItem, fullType)
        if ok and item then return item end
    end
    return nil
end

local function listSize(list)
    return list and list.size and tonumber(list:size()) or 0
end

local function listGet(list, index)
    return list and list.get and list:get(index) or nil
end

local function normalizePartId(value)
    local name = value and tostring(value) or ""
    name = string.match(name, "([%w_]+)$") or name
    return BODY_PART_BY_ID[name] and name or nil
end

local function markCoverage(output, partId)
    if partId and BODY_PART_BY_ID[partId] then output[partId] = true end
end

local function fallbackCoverage(location)
    local output = {}
    local slot = string.lower(tostring(location or ""))
    if string.find(slot, "hat", 1, true) or string.find(slot, "head", 1, true) then
        output.Head = true
    end
    if string.find(slot, "neck", 1, true) or string.find(slot, "scarf", 1, true) then
        output.Neck = true
    end
    if string.find(slot, "hand", 1, true) or string.find(slot, "glove", 1, true) then
        output.Hand_L = true
        output.Hand_R = true
    end
    if string.find(slot, "shoe", 1, true) or string.find(slot, "sock", 1, true) or string.find(slot, "foot", 1, true) then
        output.Foot_L = true
        output.Foot_R = true
    end
    if string.find(slot, "pants", 1, true) or string.find(slot, "trouser", 1, true)
        or string.find(slot, "skirt", 1, true) or string.find(slot, "short", 1, true)
    then
        output.Torso_Lower = true
        output.Groin = true
        output.UpperLeg_L = true
        output.UpperLeg_R = true
        output.LowerLeg_L = true
        output.LowerLeg_R = true
    end
    if string.find(slot, "shirt", 1, true) or string.find(slot, "jacket", 1, true)
        or string.find(slot, "sweater", 1, true) or string.find(slot, "top", 1, true)
        or string.find(slot, "torso", 1, true) or string.find(slot, "suit", 1, true)
    then
        output.Torso_Upper = true
        output.Torso_Lower = true
        output.UpperArm_L = true
        output.UpperArm_R = true
        output.ForeArm_L = true
        output.ForeArm_R = true
    end
    return output
end

local function coveredParts(item, location)
    local output = {}
    local covered = safeCall(item, "getCoveredParts")
    local size = listSize(covered)
    local i
    if size <= 0 then return fallbackCoverage(location) end
    for i = 0, size - 1 do
        markCoverage(output, normalizePartId(listGet(covered, i)))
    end
    return output
end

local function virtualWornItem(payload, location)
    local inventory = payload and payload.inventory or nil
    local itemId = inventory and inventory.worn and inventory.worn[location] or nil
    return itemId and inventory.items and inventory.items[itemId] or nil
end

local function liveWornItem(character, location)
    local worn = character and safeCall(character, "getWornItems") or nil
    local i
    -- Build 42 WornItems:getItem() accepts ItemBodyLocation, not the legacy
    -- string body-location names stored in the PNC record. Iteration works for
    -- both legacy string locations and the new typed locations without asking
    -- Kahlua to select an invalid Java overload.
    for i = 0, listSize(worn) - 1 do
        local entry = listGet(worn, i)
        local entryLocation = entry and (safeCall(entry, "getLocation") or safeCall(entry, "getBodyLocation")) or nil
        if tostring(entryLocation or "") == tostring(location) then
            return safeCall(entry, "getItem") or entry
        end
    end
    return nil
end

local function applyVirtualState(item, state)
    local maximum
    if not item or type(state) ~= "table" then return item end
    maximum = tonumber(safeCall(item, "getConditionMax")) or 0
    if state.cond ~= nil and item.setCondition then
        pcall(item.setCondition, item, math.max(0, math.min(maximum > 0 and maximum or tonumber(state.cond), tonumber(state.cond) or 0)))
    end
    if state.uses ~= nil and item.setUses then
        pcall(item.setUses, item, math.max(0, tonumber(state.uses) or 0))
    end
    return item
end

local function round(value, digits)
    local multiplier = 10 ^ (tonumber(digits) or 0)
    return math.floor((tonumber(value) or 0) * multiplier + 0.5) / multiplier
end

function Shared.Round(value, digits)
    return round(value, digits)
end

function Shared.Clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Shared.Text(key, fallback)
    -- Translator.getText expects a non-null string. Trait descriptors can be
    -- supplied by other mods, so an incomplete descriptor must degrade to its
    -- visible fallback instead of throwing a Java NPE every render frame.
    if type(key) ~= "string" or key == "" then
        return fallback or ""
    end
    local value = PNC.Translation.GetKey(key, fallback or key)
    if type(value) ~= "string" or value == "" or value == key then
        return fallback or key
    end
    return value
end

local function humanizeTraitID(value)
    value = tostring(value or "")
    value = string.gsub(value, "^pnc[_:]", "")
    value = string.gsub(value, "([a-z0-9])([A-Z])", "%1 %2")
    value = string.gsub(value, "[_:.-]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%a+", function(word)
        return string.upper(string.sub(word, 1, 1))
            .. string.lower(string.sub(word, 2))
    end)
    return value ~= "" and value or "Unknown trait"
end

function Shared.TraitLabel(traitID, definition, labelKey)
    local key = definition and definition.labelKey or labelKey
    return Shared.Text(key, humanizeTraitID(traitID))
end

function Shared.TraitDescription(traitID, definition, descriptionKey, label)
    local key = definition and definition.descriptionKey or descriptionKey
    local fallback = Shared.Text(
        "UI_PNC_Trait_DescriptionUnavailable",
        "Description unavailable"
    )
    return Shared.Text(key, fallback)
end

function Shared.GetSnapshot(snapshot, payload)
    local payloadSnapshot = payload and payload.snapshot or nil
    local candidate = payloadSnapshot or snapshot
    local id = candidate and candidate.id or snapshot and snapshot.id
    local network = PNC.Network
    local state = network and network.ClientState or nil
    local latest = id and state and state.snapshots
        and state.snapshots[tostring(id)] or nil
    return latest or candidate or {}
end

Shared.Internal = Shared.Internal or {}
Shared.Internal.safeCall = safeCall
Shared.Internal.createItem = createItem
Shared.Internal.listSize = listSize
Shared.Internal.listGet = listGet
Shared.Internal.normalizePartId = normalizePartId
Shared.Internal.markCoverage = markCoverage
Shared.Internal.fallbackCoverage = fallbackCoverage
Shared.Internal.coveredParts = coveredParts
Shared.Internal.virtualWornItem = virtualWornItem
Shared.Internal.liveWornItem = liveWornItem
Shared.Internal.applyVirtualState = applyVirtualState
Shared.Internal.round = round
Shared.Internal.itemStatsCache = itemStatsCache
Shared.Internal.bodyTextureCache = bodyTextureCache
Shared.Internal.bodyPartById = BODY_PART_BY_ID

return Shared
