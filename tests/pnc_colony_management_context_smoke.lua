package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

getText = function(key) return key end

local registered = {}
local function event(name)
    return { Add = function(callback) registered[name] = callback end }
end
Events = {
    OnFillWorldObjectContextMenu = event("context"),
    OnGameStart = event("start"),
    OnCreatePlayer = event("create"),
}

package.preload["ISUI/ISContextMenu"] = function() return true end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsPoint = function(region, x, y, z)
            return region.owned == true and x == 10 and y == 11 and z == 0
        end,
    }
end

local overlayEnabled = false
local toggledSettlement
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
] = function()
    return {
        IsEnabled = function() return overlayEnabled end,
        Toggle = function(settlement)
            toggledSettlement = settlement
            overlayEnabled = not overlayEnabled
        end,
    }
end

ISContextMenu = {
    getNew = function()
        return {
            options = {},
            addOption = function(self, label, target, callback)
                local option = { label = label, target = target,
                    callback = callback }
                self.options[#self.options + 1] = option
                return option
            end,
        }
    end,
}

local opened, requested = 0, 0
local owned = {
    id = "base:owned", factionId = "faction:player",
    geometry = { region = { owned = true } },
}
PNC = {
    Network = { ClientState = { colonyManagement = {
        faction = { id = "faction:player" }, settlement = owned,
    } } },
    NPCSelection = { GetWorldSquare = function(objects) return objects[1] end },
    ColonyManagementUI = { Open = function() opened = opened + 1 end },
    Client = { RequestColonyManagement = function()
        requested = requested + 1
    end },
}

local Context = require "PNC/UI/Context/PNC_ColonyManagementContext"

local function square(x, y, z)
    return { getX = function() return x end, getY = function() return y end,
        getZ = function() return z end }
end

local function menu()
    return {
        options = {},
        addOption = function(self, label)
            local option = { label = label }
            self.options[#self.options + 1] = option
            return option
        end,
        addSubMenu = function(self, root, submenu) root.submenu = submenu end,
    }
end

local context = menu()
assert(Context.Add(context, square(10, 11, 0)) == true,
    "owned colony tile did not expose management context")
assert(context.options[1].label == "Manage Colony",
    "management submenu label")
local submenu = context.options[1].submenu
assert(submenu.options[1].label == "Open Colony Management",
    "open management option label")
assert(submenu.options[2].label == "Turn On Base Overlay",
    "hidden overlay option label")
submenu.options[1].callback()
assert(opened == 1, "context option did not open colony management")
submenu.options[2].callback(submenu.options[2].target)
assert(toggledSettlement == owned and overlayEnabled == true,
    "context option did not enable the owned settlement overlay")

context = menu()
Context.Add(context, square(10, 11, 0))
assert(context.options[1].submenu.options[2].label == "Turn Off Base Overlay",
    "enabled overlay option label")

context = menu()
assert(Context.Add(context, square(99, 99, 0)) == false
    and #context.options == 0,
    "outside tile exposed colony management")

PNC.Network.ClientState.colonyManagement.faction.id = "faction:other"
context = menu()
assert(Context.Add(context, square(10, 11, 0)) == false
    and #context.options == 0,
    "foreign colony exposed management context")

registered.start()
registered.create()
assert(requested == 2, "owned settlement snapshot was not prefetched")

print("pnc_colony_management_context_smoke: ok")
