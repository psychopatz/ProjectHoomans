local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")

local requested = 0
PNC = {
    Core = { Now = function() return 44 end },
    Network = { ClientState = {
        colonyManagement = { colony = { name = "Boundary Colony" } },
        colonyManagementRevision = 7,
        lastColonyManagementReceiveAt = 33,
    } },
    Client = {
        RequestColonyManagement = function()
            requested = requested + 1
            return true, "requested"
        end,
    },
}

local Client = T.load(ROOT
    .. "client/PNC/Networking/PNC_ColonyManagementClient.lua")
T.equal(Client, PNC.ColonyManagementClient,
    "canonical client adapter return")
T.falsy(PNC.ColonyManagementUI,
    "legacy colony UI namespace survived adapter load")

local snapshot = Client.ReadSnapshot()
T.equal(snapshot.snapshot.colony.name, "Boundary Colony", "snapshot projection")
T.equal(snapshot.revision, 7, "snapshot revision")
T.equal(snapshot.receivedAt, 33, "snapshot receive time")
local changed, update = Client.HasUpdate(6, 33)
T.equal(changed, true, "new revision detected")
T.equal(update.revision, 7, "update envelope")
changed = Client.HasUpdate(7, 33)
T.equal(changed, false, "stale state ignored")
local ok, reason, requestedAt = Client.RequestSnapshot()
T.equal(ok, true, "snapshot request")
T.equal(reason, "requested", "snapshot request reason")
T.equal(requestedAt, 44, "snapshot request time")
T.equal(requested, 1, "snapshot request count")

local function exists(relative)
    local handle = io.open(ROOT .. relative, "r")
    if handle then handle:close() end
    return handle ~= nil
end

for _, relative in ipairs({
    "client/PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement.lua",
    "client/PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Window.lua",
    "client/PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs.lua",
    "client/PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_ScavengeTab.lua",
    "client/PNC/UI/Building/PNC_Building.lua",
    "client/PNC/UI/Building/PNC_BuildingWindow.lua",
}) do
    T.falsy(exists(relative), "retired UI file still exists: " .. relative)
end

local composition = T.read(ROOT
    .. "client/PNC/Composition/PNC_ClientComposition.lua")
T.contains(composition, "PNC/Networking/PNC_ColonyManagementClient",
    "composition does not load the canonical client adapter")
T.falsy(composition:find("PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement",
    1, true), "composition still loads the retired colony UI")
T.falsy(composition:find("PNC/UI/Building/PNC_Building", 1, true),
    "composition still loads the retired Building shim")

local router = T.read(ROOT
    .. "client/PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Exploration.lua")
T.contains(router, "PNC.ScavengeController.ReceiveSnapshot",
    "scavenge router lost the canonical controller")
T.contains(router, "PNC.ScavengeUI.ReceiveSnapshot",
    "scavenge router lost the canonical window")
T.falsy(router:find("PNC.ColonyScavengeTab", 1, true),
    "scavenge router still targets the retired colony tab")

local settlementTab = T.read(ROOT
    .. "client/PNC/UI/SettlementManagement/PNC_SettlementManagement_Tab.lua")
T.falsy(settlementTab:find("ISPNCColonyManagementWindow", 1, true),
    "Base settlement controls still target the retired window shell")

T.finish("pnc_colony_management_ui_boundary_smoke")
