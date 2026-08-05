local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local value = assert(file:read("*a"))
    file:close()
    return value
end

local function assertContains(value, needle, label)
    assert(
        string.find(value, needle, 1, true),
        (label or "assertContains") .. ": missing " .. needle
    )
end

local api = readAll(ROOT .. "shared/PNC/Core/API/PNC_API.lua")
local server = readAll(ROOT .. "server/PNC/PNC_Server.lua")
local monitor = readAll(ROOT .. "client/PNC/UI/PNC_NPCMonitor.lua")
local view = readAll(
    ROOT .. "client/PNC/UI/NPCMonitor/PNC_NPCMonitorView.lua"
)
local diagnostics = readAll(
    ROOT
        .. "shared/PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Diagnostics.lua"
)

assertContains(
    api,
    'command == "set_equipment_slot"',
    "server-authoritative slot mutation"
)
assertContains(
    api,
    "Inventory.SyncFromEquipment(record, \"debug_equipment_slot\")",
    "inventory/equipment reconciliation"
)
assertContains(
    server,
    'args.action == "set_equipment_slot"',
    "MP debug routing"
)
assertContains(
    monitor,
    "function ISPNCNPCMonitor:onEquipment(button)",
    "equipment manager action"
)
assertContains(
    monitor,
    '"Back / bag"',
    "bag and back slot controls"
)
assertContains(
    view,
    '"equipment", "UI_PNC_MonitorEquipment"',
    "monitor equipment button"
)
assertContains(
    diagnostics,
    "equipment = Core.DeepCopy(record.equipment or {})",
    "equipment diagnostics snapshot"
)

print("pnc_equipment_debug_smoke: ok")
