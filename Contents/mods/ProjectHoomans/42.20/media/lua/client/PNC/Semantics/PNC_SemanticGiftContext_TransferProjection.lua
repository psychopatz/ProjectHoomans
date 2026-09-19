-- Project authoritative transfer metadata into bounded semantic mentions.
local TransferProjection = {}

local function sameType(left, right)
    return tostring(left or "") ~= ""
        and tostring(left or "") == tostring(right or "")
end

local function factsFor(fullType, pending)
    local selection = pending and pending.selection or nil
    if selection and sameType(selection.fullType, fullType)
        and type(selection.facts) == "table"
    then
        return selection.facts
    end
    local foundation = PNC.Gifts and PNC.Gifts.Foundation
    local adapter = foundation and foundation.MarketSenseAdapter
    if adapter and type(adapter.BuildFacts) == "function" then
        local ok, facts = pcall(adapter.BuildFacts, fullType, nil)
        if ok and type(facts) == "table" then return facts end
    end
    return {}
end

local function itemIDAt(args, index)
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local value = itemIDs[index]
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function displayNameFor(fullType, pending, facts)
    local selection = pending and pending.selection or nil
    if selection and sameType(selection.fullType, fullType)
        and tostring(selection.displayName or "") ~= ""
    then
        return tostring(selection.displayName)
    end
    return tostring(facts.leaf or facts.subcategory or facts.category
        or fullType or "item")
end

local function typesFor(args, pending, maxItems)
    local output = {}
    local itemTypes = type(args.itemTypes) == "table" and args.itemTypes or {}
    local index
    for index = 1, math.min(#itemTypes, maxItems) do
        if tostring(itemTypes[index] or "") ~= "" then
            output[#output + 1] = tostring(itemTypes[index])
        end
    end
    if #output == 0 then
        local selection = pending and pending.selection or nil
        if selection and tostring(selection.fullType or "") ~= "" then
            output[1] = tostring(selection.fullType)
        end
    end
    return output
end

function TransferProjection.Build(args, pending, maxItems)
    args = type(args) == "table" and args or {}
    local types = typesFor(args, pending, maxItems)
    if #types == 0 then return nil end

    local mentions = {}
    local index
    local fullType
    local facts
    local displayName
    local id
    for index = 1, #types do
        fullType = types[index]
        facts = factsFor(fullType, pending)
        displayName = displayNameFor(fullType, pending, facts)
        id = itemIDAt(args, index)
        mentions[#mentions + 1] = {
            id = id,
            itemID = id,
            entityType = "item",
            concept = facts.leaf or facts.subcategory or facts.category
                or fullType,
            category = facts.category or facts.primary,
            text = displayName,
            value = displayName,
            name = displayName,
            fullType = fullType,
            quantity = 1,
            ownerID = args.npcId,
            capabilities = facts.capabilities,
            semanticCapabilities = facts.capabilities,
            tags = facts.tags,
            marketRole = facts.marketRole,
            marketSenseTags = facts.marketSenseTags,
            classification = facts,
            source = "gift_transfer",
        }
    end

    local ir = {
        rawText = "gift received",
        normalizedText = "gift received",
        intent = "INFORM",
        speechAct = "INFORM",
        subject = "INVENTORY",
        confidence = 0.96,
        extensions = {
            topic = "INVENTORY",
            semanticMentions = mentions,
            giftTransfer = {
                source = "authoritative",
                npcID = args.npcId,
            },
        },
    }
    return ir, types, mentions
end

return TransferProjection
