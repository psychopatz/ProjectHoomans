local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"
local ID_CARD_SCHEMA_VERSION = 1

local function identityCardKey(npcId)
    return "ProjectHoomans:identity-card:" .. tostring(npcId or "")
end

local function factionDogtagKey(npcId)
    return "ProjectHoomans:faction-dogtag:" .. tostring(npcId or "")
end

local function corpseItemNeedsStateUpdate(item, spec)
    local currentName
    local currentData
    local field
    local value
    if not item then return true end
    if spec.customName ~= nil then
        if not item.getName then return true end
        currentName = item:getName()
        if tostring(currentName or "")
            ~= tostring(spec.customName)
        then
            return true
        end
    end
    if type(spec.modData) == "table" then
        if item.getModData then
            currentData = item:getModData()
        end
        if not currentData then return true end
        for field, value in pairs(spec.modData) do
            if currentData[field] ~= value then return true end
        end
    end
    return false
end

local function identityCardSpec(record)
    local npcId = tostring(record and record.id or "")
    local npcName = tostring(
        record and (record.name or record.displayName) or "Unknown NPC"
    )
    return {
        fullType = "Base.IDcard",
        key = identityCardKey(npcId),
        customName = "ID Card: " .. npcName,
        modData = {
            PNC_IDCard = true,
            PNC_IDCardVersion = ID_CARD_SCHEMA_VERSION,
            PNC_IDCardNPCId = npcId,
            PNC_IDCardNPCName = npcName,
        },
        match = function(item)
            local modData = item and item.getModData and item:getModData() or nil
            return Internal.itemFullType(item) == "Base.IDcard"
                and modData
                and tonumber(modData.PNC_IDCardVersion)
                    == ID_CARD_SCHEMA_VERSION
                and modData.PNC_IDCard == true
                and tostring(modData.PNC_IDCardNPCId or "") == npcId
        end,
        create = function()
            return PNC.Equipment and PNC.Equipment.CreateItem
                and PNC.Equipment.CreateItem("Base.IDcard") or nil
        end,
    }
end

function Internal.ensureCorpseIdentityCard(record, target)
    local container
    local item
    local created
    local reason
    local spec
    local existing
    local changed
    if not record or not target then
        return nil, false, "invalid_identity_card_target"
    end
    container = target.getContainer and target:getContainer()
        or target.getInventory and target:getInventory()
        or nil
    if container and container.getItems and container.Remove then
        local items = container:getItems()
        local stale = {}
        local index
        if items and items.size and items.get then
            for index = 0, items:size() - 1 do
                local candidate = items:get(index)
                local data = candidate and candidate.getModData
                    and candidate:getModData() or nil
                if Internal.itemFullType(candidate) == "Base.IDcard"
                    and data and data.PNC_IDCard == true
                    and tostring(data.PNC_IDCardNPCId or "")
                        == tostring(record.id or "")
                    and tonumber(data.PNC_IDCardVersion)
                        ~= ID_CARD_SCHEMA_VERSION
                then
                    stale[#stale + 1] = candidate
                end
            end
        end
        for index = 1, #stale do
            pcall(container.Remove, container, stale[index])
            if sendRemoveItemFromContainer then
                pcall(sendRemoveItemFromContainer, container, stale[index])
            end
        end
    end
    spec = identityCardSpec(record)
    existing = CorpseItems.Find(container, spec)
    changed = corpseItemNeedsStateUpdate(existing, spec)
    item, created, reason = CorpseItems.Inject(container, spec)
    return item, created == true, reason,
        item ~= nil and (created == true or changed) or false
end
Internal.CorpseItemNeedsStateUpdate = corpseItemNeedsStateUpdate
Internal.IdentityCardKey = identityCardKey
Internal.FactionDogtagKey = factionDogtagKey
