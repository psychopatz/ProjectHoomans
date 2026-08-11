-- PNC inventory persistence facade.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Bridge = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreBridge"
local Delta = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreDeltaCodec"

local NPC_PERSISTENCE_SCHEMA = 2
local VALID_MODES = { SEED_ONLY = true, BASELINE_DELTA = true, FULL = true }

local function baseline(record, inv)
    return {
        archetypeID = record.archetypeID,
        seed = record.identitySeed,
        generatorVersion = PNC.Const and PNC.Const.GENERATOR_VERSION or 1,
        equipmentPoolID = inv and inv.template
            and inv.template.equipmentPoolID or nil,
        weaponMode = inv and inv.template and inv.template.weaponMode or nil,
    }
end

local function supportsBaseline(record)
    return record and record.identitySeed ~= nil
        and tostring(record.archetypeID or "") ~= ""
end

function Inventory.GetPersistenceMode(record)
    if record and record.inventoryPersistenceMode == "FULL" then return "FULL" end
    if not supportsBaseline(record) then return "FULL" end
    local inv = Inventory.EnsureRecordInventory(record)
    local delta = Delta.build(record, inv)
    return delta and Delta.isEmpty(delta) and "SEED_ONLY" or "BASELINE_DELTA"
end

function Inventory.Serialize(record)
    local inv = Inventory.EnsureRecordInventory(record)
    if record.inventoryPersistenceMode == "FULL" or not supportsBaseline(record) then
        return { NPC_PERSISTENCE_SCHEMA, "FULL", Bridge.serialize(record) }
    end
    local delta, reason = Delta.build(record, inv)
    if not delta then
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("NPC delta encode failed: " .. tostring(reason))
        end
        record.inventoryPersistenceMode = "FULL"
        record.inventoryPromotionReason = "delta_unrepresentable:"
            .. tostring(reason or "unknown")
        if PNC.SupplyMetrics and PNC.SupplyMetrics.Increment then
            PNC.SupplyMetrics.Increment("deltaToFullPromotions")
        end
        return { NPC_PERSISTENCE_SCHEMA, "FULL", Bridge.serialize(record) }
    end
    local deltaPayload
    if not Delta.isEmpty(delta) then deltaPayload = delta end
    return {
        NPC_PERSISTENCE_SCHEMA,
        Delta.isEmpty(delta) and "SEED_ONLY" or "BASELINE_DELTA",
        math.max(0, math.floor(tonumber(inv.revision) or 0)),
        baseline(record, inv),
        deltaPayload,
    }
end

function Inventory.Deserialize(record, rawInventory)
    if not record then return nil end
    if type(rawInventory) ~= "table" then
        return Inventory.CreateFromTemplate(record)
    end
    local inv
    local reason
    if tonumber(rawInventory[1]) ~= NPC_PERSISTENCE_SCHEMA then
        inv, reason = Bridge.deserialize(record, rawInventory)
    else
        local mode = tostring(rawInventory[2] or "")
        if not VALID_MODES[mode] then reason = "npc_persistence_mode_invalid"
        elseif mode == "FULL" then
            inv, reason = Bridge.deserialize(record, rawInventory[3])
            if inv then record.inventoryPersistenceMode = "FULL" end
        else
            inv = Inventory.CreateFromTemplate(record)
            if mode == "BASELINE_DELTA" then
                local applied
                applied, reason = Delta.apply(record, inv, rawInventory[5])
                if not applied then inv = nil end
            end
            if inv then
                inv.revision = math.max(0,
                    math.floor(tonumber(rawInventory[3]) or 0))
                inv.persistenceMode = mode
                Inventory.RebuildCaches(record)
            end
        end
    end
    if not inv and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("PNC inventory rejected payload: " .. tostring(reason))
    end
    return inv or Inventory.CreateFromTemplate(record)
end
