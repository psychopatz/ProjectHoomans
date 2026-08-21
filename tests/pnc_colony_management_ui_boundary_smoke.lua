local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

local calls = {}
local originalRequire = require
require = function(name)
    calls[#calls + 1] = name
    return true
end
local UI = dofile(ROOT
    .. "client/PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement.lua")
require = originalRequire

local expected = {
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Layout",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Diagnostics",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Controller",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Window",
}
equal(#calls, #expected, "canonical require count")
for index = 1, #expected do
    equal(calls[index], expected[index], "canonical require order " .. index)
end
equal(UI, PNC.ColonyManagementUI, "canonical UI return")

local Client = PNC.ColonyManagementClient
local snapshot = Client.ReadSnapshot()
equal(snapshot.snapshot.colony.name, "Boundary Colony", "snapshot projection")
equal(snapshot.revision, 7, "snapshot revision")
equal(snapshot.receivedAt, 33, "snapshot receive time")
local changed, update = Client.HasUpdate(6, 33)
equal(changed, true, "new revision detected")
equal(update.revision, 7, "update envelope")
changed = Client.HasUpdate(7, 33)
equal(changed, false, "stale state ignored")
local ok, reason, requestedAt = Client.RequestSnapshot()
equal(ok, true, "snapshot request")
equal(reason, "requested", "snapshot request reason")
equal(requestedAt, 44, "snapshot request time")
equal(requested, 1, "snapshot request count")

local function source(path)
    local file = assert(io.open(path, "r"))
    local value = file:read("*a")
    file:close()
    return value
end

local controllerSource = source(ROOT
    .. "client/PNC/UI/Communities/ColonyManagement/"
    .. "PNC_ColonyManagement_Controller.lua")
local windowSource = source(ROOT
    .. "client/PNC/UI/Communities/ColonyManagement/"
    .. "PNC_ColonyManagement_Window.lua")
local scavengeTabSource = source(ROOT
    .. "client/PNC/UI/Communities/ColonyManagement/"
    .. "PNC_ColonyManagement_ScavengeTab.lua")
for _, value in ipairs({ controllerSource, windowSource }) do
    equal(value:find("PNC.Network.ClientState", 1, true), nil,
        "shell bypasses client snapshot boundary")
end
equal(windowSource:find("PNC.Client.RequestColonyManagement", 1, true), nil,
    "window bypasses client request boundary")
if not windowSource:find("Client.HasUpdate", 1, true) then
    error("window update boundary missing")
end
if not scavengeTabSource:find("followingCurrentPlayer == true", 1, true) then
    error("scavenge roster is not follower-only")
end
if not scavengeTabSource:find("or assigned", 1, true) then
    error("assigned scavengers disappear after leaving follow order")
end
if not scavengeTabSource:find("UI.CreateToggleButton", 1, true) then
    error("scavenge assignment does not use reusable toggle control")
end
if not scavengeTabSource:find("Controller.Open", 1, true) then
    error("colony party management bypasses shared scavenging pipeline")
end
if not scavengeTabSource:find('id = "toggle_scavenger"', 1, true)
    or not scavengeTabSource:find('id = "open_scavenge"', 1, true)
then error("scavenge roster controls missing") end
equal(scavengeTabSource:find("ISPNCInventoryList", 1, true), nil,
    "colony scavenge tab does not duplicate loot manifest UI")

print("pnc_colony_management_ui_boundary_smoke: ok")
