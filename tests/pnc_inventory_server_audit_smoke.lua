local T = require "tests/support/test"
T.addPackagePaths()

local record = {
    id = "npc-audit",
    inventory = {
        revision = 7,
        items = {
            ["npc-item"] = {
                id = "npc-item",
                type = "Base.HuntingKnife",
                stack = 1,
            },
        },
    },
    runtime = {},
}
local authorized = true
local authorizationReason = "commandable"
local fullSyncs = 0
local deltaSyncs = 0
local actionExecutions = 0
local auditEvents = {}
local commandResults = {}

local function auditField(entry, name)
    local prefix = name .. "="
    for index = 1, #(entry and entry.fields or {}) do
        local field = entry.fields[index]
        if string.sub(field, 1, #prefix) == prefix then
            return string.sub(field, #prefix + 1)
        end
    end
    return nil
end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_INVENTORY_TRANSFER = "InventoryTransfer",
        CMD_INVENTORY_ACTION = "InventoryAction",
        CMD_INVENTORY_RESULT = "InventoryResult",
        INVENTORY_INTERACTION_RADIUS = 3,
        INVENTORY_TRANSFER_MAX_ITEMS = 64,
        INVENTORY_TRANSFER_MAX_QUANTITY = 1024,
        TACTICAL_CLASS_HOSTILE = "hostile",
    },
    Core = {
        LogWarn = function() end,
    },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
        GetLiveZombie = function() return nil end,
    },
    CompanionCommands = {
        CanPlayerCommand = function()
            return authorized, authorizationReason
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(target) return target.inventory end,
        Internal = {},
    },
    InventoryActions = {
        Get = function() return { refreshEquipment = false } end,
        Execute = function(_, _, target)
            actionExecutions = actionExecutions + 1
            target.inventory.revision = target.inventory.revision + 1
            return true, "equipped_primary"
        end,
    },
    Network = {
        SendCharacterPayload = function()
            fullSyncs = fullSyncs + 1
        end,
        SendInventoryDelta = function()
            deltaSyncs = deltaSyncs + 1
            return true
        end,
    },
    PerformanceScalingDiagnostics = {
        InventoryAuditEnabled = true,
        LogInventoryAudit = function(event, fields)
            auditEvents[#auditEvents + 1] = { event = event, fields = fields }
        end,
    },
}
PsychopatzCore = { Debug = { CanUse = function() return false end } }
sendServerCommand = function(_, _, _, payload)
    commandResults[#commandResults + 1] = payload
end

package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload["PsychopatzCore/Inventory/PsychopatzItemTransfer"] = function()
    return {
        ResolvePlayerItems = function() return {} end,
        DescribeItem = function() return {} end,
        TakeFromPlayer = function() return false, "not_used" end,
        GiveToPlayerContainer = function() return false, "not_used" end,
        RemoveItem = function() return true end,
        DropToSquare = function() return false, "not_used" end,
    }
end

local Service = require "PNC/Server/PNC_ServerInventory"
PNC.ServerInventory = Service
local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerInventoryCommandHandler"

local player = {}
T.equal(Router.Handle(PNC.Const.CMD_INVENTORY_ACTION, player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 7,
    requestId = "action-commit",
}), true, "action command routed to production service")
T.equal(actionExecutions, 1, "authorized current action executed")
T.equal(deltaSyncs, 1, "committed action sent its delta")
T.equal(record.inventory.revision, 8, "committed action advanced revision")
local committedAction = auditEvents[#auditEvents]
T.equal(committedAction.event, "server_action", "action audit event")
T.equal(auditField(committedAction, "stage"), "completed",
    "committed action audit stage")
T.equal(auditField(committedAction, "route"), "action:equip_primary",
    "committed action audit route")
T.equal(auditField(committedAction, "authority"), "allowed",
    "committed action audit authority")
T.equal(auditField(committedAction, "adapter_result"), "committed",
    "committed action audit adapter result")
T.equal(auditField(committedAction, "revision_before"), "7",
    "committed action audit starting revision")
T.equal(auditField(committedAction, "revision_after"), "8",
    "committed action audit final revision")

T.equal(Router.Handle(PNC.Const.CMD_INVENTORY_ACTION, player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 7,
    requestId = "action-stale",
}), true, "stale action command routed")
T.equal(fullSyncs, 1, "stale action receives current full payload")
T.equal(actionExecutions, 1, "stale action stopped before gameplay adapter")
T.equal(record.inventory.revision, 8, "stale action did not mutate revision")
local staleAction = auditEvents[#auditEvents]
T.equal(staleAction.event, "server_action", "stale action audit event")
T.equal(auditField(staleAction, "stage"), "stale_revision",
    "stale action audit stage")
T.equal(auditField(staleAction, "authority_reason"), "commandable",
    "stale action authority reason")
T.equal(auditField(staleAction, "adapter_result"), "not_run",
    "stale action adapter was not run")
T.equal(auditField(staleAction, "reason"), "revision_conflict",
    "stale action audit failure reason")
T.equal(auditField(staleAction, "revision_expected"), "7",
    "stale action audit client revision")
T.equal(auditField(staleAction, "revision_before"), "8",
    "stale action audit server revision")
T.equal(auditField(staleAction, "revision_after"), "8",
    "stale action audit final revision")

T.equal(Router.Handle(PNC.Const.CMD_INVENTORY_TRANSFER, player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "root",
    inventoryRevision = 7,
    requestId = "transfer-stale",
}), true, "stale transfer command routed")
T.equal(fullSyncs, 2, "stale transfer receives current full payload")
local staleTransfer = auditEvents[#auditEvents]
T.equal(staleTransfer.event, "server_transfer", "transfer audit event")
T.equal(auditField(staleTransfer, "stage"), "stale_revision",
    "stale transfer audit stage")
T.equal(auditField(staleTransfer, "route"), "npc_to_player",
    "stale transfer audit route")
T.equal(auditField(staleTransfer, "adapter_result"), "not_run",
    "stale transfer adapter was not run")
T.equal(auditField(staleTransfer, "revision_after"), "8",
    "stale transfer audit final revision")

authorized = false
authorizationReason = "not_owner"
T.equal(Router.Handle(PNC.Const.CMD_INVENTORY_ACTION, player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 8,
    requestId = "action-denied",
}), true, "denied action command routed")
T.equal(actionExecutions, 1, "unauthorized action stopped before adapter")
local deniedAction = auditEvents[#auditEvents]
T.equal(auditField(deniedAction, "stage"), "rejected",
    "denied action audit stage")
T.equal(auditField(deniedAction, "authority"), "denied",
    "denied action authority decision")
T.equal(auditField(deniedAction, "authority_reason"), "not_owner",
    "denied action audit reason")
T.equal(auditField(deniedAction, "adapter_result"), "not_run",
    "denied action adapter was not run")

T.finish("pnc_inventory_server_audit_smoke")
