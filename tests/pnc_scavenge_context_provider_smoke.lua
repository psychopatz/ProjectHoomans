local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local provider
local opened
local Controller
Controller = {
    assigned = false,
    IsAssigned = function(selfOrId, maybeId)
        return Controller.assigned
    end,
    ToggleAssigned = function()
        Controller.assigned = not Controller.assigned
        return true
    end,
    Open = function(npcId)
        opened = npcId
        return true
    end,
}
package.preload["PNC/Scavenge/PNC_ScavengeController"] =
    function() return Controller end

PNC = {
    Const = { ORDER_FOLLOW = "follow", COMPANION_COMMAND_RADIUS = 20 },
    ContextHub = {
        RegisterProvider = function(value) provider = value; return true end,
        ApplyOptionPresentation = function(option, presentation)
            option.presentation = presentation
        end,
    },
    CompanionCommands = {
        CanPlayerCommand = function() return true end,
    },
}

local function newMenu()
    return {
        options = {},
        addOption = function(self, title, _, callback)
            local option = { title = title, callback = callback }
            self.options[#self.options + 1] = option
            return option
        end,
        addSubMenu = function(_, option, submenu)
            option.submenu = submenu
        end,
    }
end

ISContextMenu = {
    getNew = function() return newMenu() end,
}

T.load("ProjectHoomans", "client",
    "PNC/UI/Context/Providers/PNC_ContextProvider_Scavenge.lua")
T.truthy(provider, "dedicated scavenging context provider registered")

local player = {
    getOnlineID = function() return 7 end,
    getUsername = function() return "owner" end,
}
local entry = { id = "bob", name = "Bob", record = {
    orderSpec = { kind = "follow", ownerOnlineID = 7 },
} }
T.truthy(provider.isEnabled(entry, player),
    "current follower exposes scavenging context")

local menu = newMenu()
provider.addOptions(menu, entry, player)
T.equal(#menu.options, 1, "scavenging uses a dedicated submenu")
local submenu = menu.options[1].submenu
T.equal(#submenu.options, 2, "submenu provides party toggle and UI access")
submenu.options[1].callback()
T.truthy(Controller.assigned, "context toggles shared party membership")
entry.record.orderSpec.kind = "scavenge"
T.truthy(provider.isEnabled(entry, player),
    "assigned scavenger remains accessible after leaving follow order")
submenu.options[2].callback()
T.equal(opened, "bob", "context opens dedicated scavenging UI")

T.finish("pnc_scavenge_context_provider_smoke")
