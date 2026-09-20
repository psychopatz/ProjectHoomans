local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/"
)
local inventory = { Internal = {} }
local factions = {
    faction_1 = { id = "faction_1", name = "North Watch" },
    faction_2 = { id = "faction_2", name = "River Guard" },
}
local deltaCount = 0
local generatedID = 0

local function cloneState(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, entry in pairs(value) do
        if key == "modData" and type(entry) == "table" then
            output.modData = {}
            for dataKey, dataValue in pairs(entry) do
                output.modData[dataKey] = dataValue
            end
        else
            output[key] = entry
        end
    end
    return output
end

inventory.Internal.sanitizeItemState = cloneState
inventory.Internal.normalizeString = function(value)
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end
inventory.Internal.findItemByTemplateKey = function(inv, templateKey)
    for _, item in pairs(inv and inv.items or {}) do
        if item and item.templateKey == templateKey then return item end
    end
    return nil
end
inventory.EnsureRecordInventory = function(record)
    return record and record.inventory or nil
end
inventory.ApplyDelta = function(record, operations)
    local inv = record.inventory
    for _, operation in ipairs(operations) do
        if operation.op == "remove" then
            inv.items[operation.itemID] = nil
        elseif operation.op == "add" then
            local item = {}
            for key, value in pairs(operation.item) do
                item[key] = value
            end
            if not item.id then
                generatedID = generatedID + 1
                item.id = "generated_" .. generatedID
            end
            inv.items[item.id] = item
        else
            return false, "unexpected_operation"
        end
    end
    deltaCount = deltaCount + 1
    return true, {}
end

PNC = {
    Inventory = inventory,
    Factions = {
        Get = function(id) return factions[tostring(id)] end,
    },
}
local Inventory = PNC.Inventory

T.load(ROOT .. "PNC_Inventory_Items_Construction.lua")

local record = {
    id = "npc_17",
    name = "Ash Marlowe",
    affiliation = { factionID = "faction_1" },
    inventory = {
        items = {
            card_1 = {
                id = "card_1",
                type = "Base.IDcard",
                templateKey = "tmpl:identity_card:0",
                customName = "ID Card: Ash Marlowe",
                identityNPCId = "npc_17",
                identityNPCName = "Ash Marlowe",
                interactionLocked = true,
                interactionLockReason = "identity_card",
            },
        },
        containers = { root = { itemIDs = { "card_1" } } },
        worn = {},
        attached = {},
        equipped = {},
    },
}

local tag, changed, reason = Inventory.RefreshFactionDogTag(record)
T.truthy(changed, "faction membership adds a persistent dogtag")
T.equal(reason, "updated", "first dogtag refresh result")
T.equal(tag.type, "Base.Necklace_DogTag", "vanilla dogtag item type")
T.equal(tag.customName, "Dog Tags: North Watch",
    "dogtag display uses the faction name")
T.equal(tag.itemState.modData.PNC_FactionDogTagFactionName, "North Watch",
    "dogtag metadata stores only the faction name")
T.equal(tag.itemState.modData.PNC_FactionDogTagFactionId, "faction_1",
    "dogtag metadata stores the stable faction ID")
T.equal(tag.itemState.modData.PNC_FactionDogTagNPCId, "npc_17",
    "dogtag metadata binds it to the NPC")
T.equal(tag.interactionLocked, true, "dogtag remains a required identity item")
T.equal(deltaCount, 1, "dogtag is written through the inventory mutation API")

local tagID = tag.id
local unchangedTag, unchanged, unchangedReason =
    Inventory.RefreshFactionDogTag(record)
T.equal(unchanged, false, "unchanged metadata does not write another delta")
T.equal(unchangedReason, "unchanged", "idempotent refresh result")
T.equal(unchangedTag.id, tagID, "idempotent refresh preserves the item")
T.equal(deltaCount, 1, "idempotent refresh does not bump inventory again")

factions.faction_1.name = "North Watch Reformed"
tag, changed = Inventory.RefreshFactionDogTag(record)
T.truthy(changed, "faction rename updates the existing dogtag")
T.equal(tag.id, tagID, "rename preserves the same item identity")
T.equal(tag.customName, "Dog Tags: North Watch Reformed",
    "renamed faction appears on the tag")
T.equal(tag.itemState.modData.PNC_FactionDogTagFactionName,
    "North Watch Reformed", "metadata is updated to the renamed faction")

record.affiliation.factionID = "faction_2"
tag, changed = Inventory.RefreshFactionDogTag(record)
T.truthy(changed, "recruitment transfer updates the dogtag faction")
T.equal(tag.id, tagID, "transfer preserves the same dogtag")
T.equal(tag.itemState.modData.PNC_FactionDogTagFactionId, "faction_2",
    "transfer changes the stable faction ID")
T.equal(tag.itemState.modData.PNC_FactionDogTagFactionName, "River Guard",
    "transfer changes the faction name")
T.equal(deltaCount, 3, "each actual faction change writes exactly one delta")

record.name = "Ash Marlowe Recruited"
local card, cardChanged = Inventory.Internal.ensureIdentityCard(
    record,
    record.inventory
)
T.truthy(cardChanged, "identity card is refreshed after a rename")
T.equal(card.customName, "ID Card: Ash Marlowe Recruited",
    "renamed NPC is shown on their ID card")
T.equal(card.identityNPCName, "Ash Marlowe Recruited",
    "ID card name metadata follows the NPC")

Inventory.EnsureRecordInventory = function(record)
    if not record.inventory then
        local faction = factions[record.affiliation.factionID]
        local metadata = {
            PNC_FactionDogTag = true,
            PNC_FactionDogTagVersion = 1,
            PNC_FactionDogTagNPCId = record.id,
            PNC_FactionDogTagFactionId = faction.id,
            PNC_FactionDogTagFactionName = faction.name,
        }
        record.inventory = {
            items = {
                generated_tag = {
                    id = "generated_tag",
                    type = "Base.Necklace_DogTag",
                    templateKey = "tmpl:faction_dogtag:0",
                    customName = "Dog Tags: " .. faction.name,
                    interactionLocked = true,
                    interactionLockReason = "faction_dogtag",
                    itemState = { modData = metadata },
                },
            },
        }
    end
    return record.inventory
end
local generatedRecord = {
    id = "npc_template_generated",
    affiliation = { factionID = "faction_1" },
}
local generatedTag, generatedChanged, generatedReason =
    Inventory.RefreshFactionDogTag(generatedRecord)
T.truthy(generatedChanged,
    "newly hydrated faction metadata triggers the caller's broadcast")
T.equal(generatedReason, "updated", "template-generated tag refresh result")
T.equal(generatedTag.type, "Base.Necklace_DogTag",
    "faction tag generated with an empty inventory is recognized")
T.equal(deltaCount, 3,
    "template-generated tag does not write an unnecessary inventory delta")

T.finish("pnc_inventory_faction_dogtag_smoke")
