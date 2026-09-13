-- Event-driven NPC inventory replication.
--
-- Inventory.ApplyDelta is the single compact-inventory mutation boundary.
-- Queueing that event here keeps the normal NPC loop free of inventory scans,
-- coalesces same-tick changes, and publishes only to clients that already
-- requested the affected character detail.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.InventoryReplication = PNC.InventoryReplication or {}

local Replication = PNC.InventoryReplication
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Core = PNC.Core
local Network = PNC.Network

Replication.pending = Replication.pending or {}
Replication.pendingCount = tonumber(Replication.pendingCount) or 0

function Replication.MarkDirty(record)
    local id = record and record.id and tostring(record.id) or nil
    if not id then return false end
    if not Replication.pending[id] then
        Replication.pendingCount = Replication.pendingCount + 1
    end
    Replication.pending[id] = record
    return true
end

function Replication.Flush()
    local pending
    local count = 0
    local id
    local record
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return 0
    end
    if Replication.pendingCount <= 0 then return 0 end
    pending = Replication.pending
    Replication.pending = {}
    Replication.pendingCount = 0
    for id, record in pairs(pending) do
        if Network and Network.PushInventoryDelta then
            count = count + (tonumber(Network.PushInventoryDelta(record)) or 0)
        end
    end
    return count
end

if not Replication.OnInventoryChanged then
    Replication.OnInventoryChanged = function(record)
        Replication.MarkDirty(record)
    end
end

EventBus.subscribe(EventTypes.NPC_INVENTORY_CHANGED,
    Replication.OnInventoryChanged, Replication)

if Events and Events.OnTick and Events.OnTick.Add
    and not Replication.TickHookRegistered
then
    Events.OnTick.Add(function() Replication.Flush() end)
    Replication.TickHookRegistered = true
end

return Replication
