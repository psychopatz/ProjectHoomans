local T = require "tests/support/test"

-- Radio-relayed orders are the only path that lets a player command a colonist
-- who is out of earshot or currently abstract, so both halves of the contract
-- are pinned here: the shared verdict, and the equipment predicate it consults.

local function newRadioGear()
    local Equipment = { Internal = {} }
    Equipment.CreateItem = function(fullType)
        if fullType == "Base.WalkieTalkie2" then
            return { getAttachmentType = function() return "Walkie" end }
        end
        if fullType == "Base.Bandage" then
            return { getAttachmentType = function() return "" end }
        end
        return nil, "invalid_full_type"
    end
    Equipment.EnsureRecordEquipment = function(record)
        record.equipment = record.equipment or {
            attached = {}, worn = {},
        }
        return record.equipment
    end
    Equipment.ResolveAttachedLocation = function(_, _, occupied)
        if occupied and occupied["Walkie Belt Right"] then return nil end
        return "Walkie Belt Right"
    end
    Equipment.GetOrderedAttachedEntries = function(equipment)
        local entries = {}
        for location, fullType in pairs(equipment.attached or {}) do
            entries[#entries + 1] = { location = location, fullType = fullType,
                slotType = "SmallBeltRight" }
        end
        return entries
    end
    PNC.Equipment = Equipment
    local RadioGear = T["load"]("ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_RadioGear.lua")
    return Equipment, RadioGear
end

-- Equipping a handed-over radio claims a free belt slot and reports failure
-- instead of silently bagging the item. The real inventory mutation is loaded
-- here so the slot-ownership rules under test are the shipped ones.
local mutationCalls = {}
local revisions = 0
local synced = 0

local function stubInventoryMutation()
    Inventory = {}
    Inventory.Internal = {
        normalizeString = function(value)
            if value == nil or value == "" then return nil end
            return tostring(value)
        end,
        setItemContainer = function(inv, item, containerID)
            item.container = containerID
            inv.containers = inv.containers or {}
            inv.containers[containerID] = inv.containers[containerID]
                or { items = {} }
            return true
        end,
        buildOperation = function(op, data)
            local payload = { op = op }
            for key, value in pairs(data or {}) do payload[key] = value end
            return payload
        end,
        bumpRevision = function() revisions = revisions + 1 end,
    }
    Inventory.EnsureRecordInventory = function(record)
        record.inventory = record.inventory or { items = {}, attached = {},
            worn = {}, equipped = {}, containers = { root = { items = {} } } }
        return record.inventory
    end
    Inventory.SyncEquipmentFromInventory = function(record)
        synced = synced + 1
        record.equipment = record.equipment or { attached = {}, worn = {} }
        record.equipment.attached = {}
        for slot, itemID in pairs(record.inventory.attached or {}) do
            local item = record.inventory.items[itemID]
            if item then record.equipment.attached[slot] = item.type end
        end
        return record.equipment
    end
    Inventory.RebuildCaches = function() end
    PNC.Inventory = Inventory
    PNC.Registry = { MarkDirty = function() end }
    PNC.Core = PNC.Core or {}
    PNC.Core.LogWarn = function() end
    dofile(T.path("ProjectHoomans", "shared",
        "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/"
            .. "PNC_Inventory_Mutations_Equipment.lua"))
    T.truthy(Inventory.SetAttached, "the inventory attach mutation exists")
    local realSetAttached = Inventory.SetAttached
    Inventory.SetAttached = function(record, itemID, slot, reason)
        mutationCalls[#mutationCalls + 1] = {
            itemID = itemID, slot = slot, reason = reason,
        }
        return realSetAttached(record, itemID, slot, reason)
    end
end

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = PNC or {}
PNC.Const = { PRESENCE_LIVE = "live", PRESENCE_ABSTRACT = "abstract" }

local Gate = T["load"]("ProjectHoomans", "shared",
    "PNC/Core/Commands/PNC_CompanionCommandRelayGate.lua")
T.truthy(Gate, "relay gate module loads")

-- Verdicts: an order in earshot never needs radio gear, and a remote order
-- always needs both ends.
local allowed, reason = Gate.Evaluate({
    companion = true, owned = true, reachableDirectly = true,
    relayAllowed = true, playerRadio = false, npcRadio = false,
})
T.equal(allowed, true, "a colonist in earshot is commandable without a radio")
T.equal(reason, Gate.DIRECT, "the in-earshot path reports the direct channel")

allowed, reason = Gate.Evaluate({
    companion = true, owned = true, reachableDirectly = false,
    relayAllowed = true, playerRadio = true, npcRadio = true,
})
T.equal(allowed, true, "a remote colonist is commandable over two radios")
T.equal(reason, Gate.RELAY, "the remote path reports the radio relay")

allowed, reason = Gate.Evaluate({
    companion = true, owned = true, reachableDirectly = false,
    relayAllowed = true, playerRadio = true, npcRadio = false,
})
T.falsy(allowed, "a colonist without radio gear cannot be reached remotely")
T.equal(reason, "npc_radio_missing", "the missing colonist radio is named")
T.truthy(Gate.ReasonKey(reason), "every rejection reason is translatable")
T.equal(Gate.ReasonKey(reason), "UI_PNC_RadioRelay_ReasonNpcRadio",
    "the colonist radio reason maps to its catalog key")

allowed, reason = Gate.Evaluate({
    companion = true, owned = true, reachableDirectly = false,
    relayAllowed = true, playerRadio = false, npcRadio = true,
})
T.falsy(allowed, "a silent player radio cannot reach a remote colonist")
T.equal(reason, "player_radio_inactive", "the silent player radio is named")

allowed, reason = Gate.Evaluate({
    companion = true, owned = true, reachableDirectly = false,
    relayAllowed = false, playerRadio = true, npcRadio = true,
})
T.falsy(allowed, "an order that opts out of relay stays proximity-only")
T.equal(reason, "relay_not_allowed", "the opt-out is reported distinctly")

allowed, reason = Gate.Evaluate({
    companion = false, owned = false, dead = false,
    reachableDirectly = false, relayAllowed = true,
    playerRadio = true, npcRadio = true,
})
T.falsy(allowed, "a non-companion is never commandable")
T.equal(reason, "not_companion", "the relationship failure is named")

allowed, reason = Gate.Evaluate({
    companion = true, owned = true, dead = true,
    reachableDirectly = true, relayAllowed = true,
    playerRadio = true, npcRadio = true,
})
T.falsy(allowed, "a dead colonist is never commandable")
T.equal(reason, "dead", "the death failure wins over every other state")

-- Equipment predicate: the belt slot is what counts, not a carried radio.
local Equipment, RadioGear = newRadioGear()
T.truthy(RadioGear.IsRadioType("Base.WalkieTalkie2"),
    "vanilla walkie-talkie gear is recognised")
T.falsy(RadioGear.IsRadioType("Base.Bandage"),
    "non-radio equipment is rejected")
T.falsy(RadioGear.IsRadioType(nil), "missing item types fail closed")

local equipped = { equipment = { attached = {
    ["Walkie Belt Right"] = "Base.WalkieTalkie2",
}, worn = {} } }
local described = RadioGear.Describe(equipped)
T.equal(described.equipped, true, "an attached radio counts as equipped")
T.equal(described.location, "Walkie Belt Right",
    "the equipped radio reports its attachment location")
T.equal(described.fullType, "Base.WalkieTalkie2",
    "the equipped radio reports its item type")
T.equal(RadioGear.HasEquipped(equipped), true, "HasEquipped agrees")

local carried = { equipment = { attached = {}, worn = {} },
    inventory = { items = {
        ["radio:1"] = { id = "radio:1", type = "Base.WalkieTalkie2" },
    } } }
T.equal(RadioGear.HasEquipped(carried), false,
    "a radio loose in the bag is not equipped")

local wornRadio = { equipment = { attached = {},
    worn = { Back = "Base.WalkieTalkie2" } } }
T.equal(RadioGear.HasEquipped(wornRadio), true,
    "radio gear worn on the body counts as equipped")

local inHand = { equipment = { attached = {}, worn = {},
    primaryFullType = "Base.WalkieTalkie2" } }
T.equal(RadioGear.HasEquipped(inHand), true,
    "radio gear held in hand counts as equipped")

local stale = { equipment = nil, inventory = { items = {
    ["radio:2"] = { id = "radio:2", type = "Base.WalkieTalkie2",
        attachedSlot = "Walkie Belt Right" },
    ["bag:1"] = { id = "bag:1", type = "Base.WalkieTalkie2" },
} } }
T.equal(RadioGear.HasEquipped(stale), true,
    "a slot item answers even when the equipment mirror is missing")

-- Equipping a handed-over radio claims a free belt slot and reports failure
-- instead of silently bagging the item.
stubInventoryMutation()
local handed = { id = "npc:radio", runtime = {},
    equipment = { attached = {}, worn = {} },
    inventory = { items = {
        ["gift:1"] = { id = "gift:1", type = "Base.WalkieTalkie2",
            container = "root" },
    }, attached = {}, worn = {}, containers = {} } }
local adopted, adoptReason = RadioGear.AdoptFromInventory(
    handed, "gift:1", "Base.WalkieTalkie2")
T.equal(adopted, true, "a handed-over radio is adopted onto the belt")
T.equal(adoptReason, "attached", "the adoption reports the attach result")
T.equal(handed.inventory.items["gift:1"].attachedSlot, "Walkie Belt Right",
    "the adopted radio owns the belt slot")
T.equal(handed.inventory.attached["Walkie Belt Right"], "gift:1",
    "the attachment map points at the adopted radio")
T.equal(handed.equipment.attached["Walkie Belt Right"], "Base.WalkieTalkie2",
    "the adopted radio reaches the equipment mirror")
T.equal(revisions, 1, "adoption bumps the inventory revision once")
T.equal(synced, 1, "adoption mirrors the equipment state")
T.equal(#mutationCalls, 1, "adoption uses one inventory mutation")
T.equal(mutationCalls[1].reason, "radio_gear_issued",
    "adoption records why the radio was attached")
T.equal(mutationCalls[1].itemID, "gift:1",
    "adoption attaches the transferred item, not a clone")

local secondAdopt, secondReason = RadioGear.AdoptFromInventory(
    handed, "gift:1", "Base.WalkieTalkie2")
T.falsy(secondAdopt, "a colonist never adopts a second radio")
T.equal(secondReason, "already_equipped",
    "the second adoption reports the existing radio")

local notRadio, notRadioReason = RadioGear.AdoptFromInventory(handed, "gift:1",
    "Base.Bandage")
T.falsy(notRadio, "non-radio items are never attached")
T.equal(notRadioReason, "not_radio_gear",
    "the non-radio rejection is named")

-- A colonist whose belt already carries a holstered weapon keeps the radio
-- carried rather than displacing the weapon.
local occupied = { id = "npc:occupied", runtime = {},
    equipment = { attached = { ["Walkie Belt Right"] = "Base.Axe" },
        worn = {} },
    inventory = { items = {
        ["radio:1"] = { id = "radio:1", type = "Base.WalkieTalkie2" },
    }, attached = {}, worn = {}, containers = {} } }
local noSlot, noSlotReason = RadioGear.AdoptFromInventory(occupied, "radio:1",
    "Base.WalkieTalkie2")
T.falsy(noSlot, "a colonist with no free belt slot keeps the radio carried")
T.equal(noSlotReason, "no_attachment_location",
    "the missing attachment location is reported")
T.falsy(occupied.inventory.items["radio:1"].attachedSlot,
    "the occupied belt slot is never displaced")
T.equal(#mutationCalls, 1, "a failed adoption performs no inventory mutation")

T.finish("pnc_radio_relay_commands_smoke")
