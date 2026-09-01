local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "root", "")

local api = T.read(ROOT .. "shared/PNC/Core/API/PNC_API.lua")
    .. T.read(
        "ProjectHoomans",
        "shared",
        "PNC/Core/API/PNC_API/DebugCommands.lua"
    )
local serverRoute = T.read(
    ROOT .. "server/PNC/Networking/Handlers/"
        .. "PNC_ServerDebugCommandHandler.lua"
) .. T.read(
    ROOT .. "server/PNC/Networking/Handlers/"
        .. "ServerDebugCommandHandler/"
        .. "PNC_ServerDebugCommandHandler_ApiActions.lua"
)
local monitor = T.read(ROOT .. "client/PNC/UI/PNC_NPCMonitor.lua")
local view = T.read(
    ROOT .. "client/PNC/UI/NPCMonitor/PNC_NPCMonitorView.lua"
)
local diagnostics = T.read(
    ROOT
        .. "shared/PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Diagnostics.lua"
)

T.contains(
    api,
    'command == "set_equipment_slot"',
    "server-authoritative slot mutation"
)
T.contains(
    api,
    "syncAndApplyEquipment(record, \"debug_equipment_slot\")",
    "inventory/equipment reconciliation"
)
T.contains(
    serverRoute,
    'set_equipment_slot = true',
    "MP debug routing"
)
T.contains(
    monitor,
    "function ISPNCNPCMonitor:onEquipment(button)",
    "equipment manager action"
)
T.contains(
    monitor,
    '"Back / bag"',
    "bag and back slot controls"
)
T.contains(
    view,
    '"equipment", "UI_PNC_MonitorEquipment"',
    "monitor equipment button"
)
T.contains(
    view,
    '"overlay_camp"',
    "monitor camp overlay button"
)
T.contains(
    diagnostics,
    "equipment = Core.DeepCopy(record.equipment or {})",
    "equipment diagnostics snapshot"
)
T.finish("pnc_equipment_debug_smoke")
