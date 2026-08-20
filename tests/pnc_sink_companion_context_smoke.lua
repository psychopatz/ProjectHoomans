local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function menu()
    local value = { options = {}, submenus = {} }
    function value:addOption(label, target, callback, argument)
        local option = { label = label, target = target,
            callback = callback, argument = argument }
        self.options[#self.options + 1] = option
        return option
    end
    function value:addSubMenu(option, submenu)
        self.submenus[option] = submenu
    end
    return value
end

local requested
local player = {}
local square = {
    getX = function() return 1917 end,
    getY = function() return 14381 end,
    getZ = function() return 0 end,
}
local sink = {
    getSquare = function() return square end,
    getSprite = function() return {
        getName = function() return "fixtures_sinks_01_10" end,
    } end,
    hasFluid = function() return true end,
}
square.getObjects = function() return list({ sink }) end

PNC = {
    Network = { ClientState = { snapshots = {
        parker = { id = "parker", name = "Parker", presenceState = "LIVE" },
    } } },
    CompanionCommands = {
        CanPlayerCommand = function(snapshot)
            return snapshot.id == "parker"
        end,
    },
    NPCIdentityPresentation = {
        GetName = function(snapshot) return snapshot.name end,
    },
    Client = {
        RequestColonyAction = function(action, options)
            requested = { action = action, options = options }
            return true
        end,
    },
}
getSpecificPlayer = function() return player end
ISContextMenu = { getNew = function() return menu() end }

local Context = T.load("ProjectHoomans", "client",
    "PNC/UI/Context/PNC_SinkCompanionContext.lua")
local rootMenu = menu()
Context.BuildWorldContext(0, rootMenu, { sink }, false)
T.equal(#rootMenu.options, 1, "right-clicking a sink adds one companion command")
local submenu = rootMenu.submenus[rootMenu.options[1]]
T.equal(submenu.options[1].label, "Parker",
    "the sink menu lists commandable companions")
submenu.options[1].callback(
    submenu.options[1].target, submenu.options[1].argument)
T.equal(requested.action, "npc_drink_at_water",
    "the sink option sends the authoritative drink action")
T.equal(requested.options.sourceX, 1917, "the exact sink square is sent")
T.equal(requested.options.npcID, "parker", "the chosen NPC is sent")

T.finish("pnc_sink_companion_context_smoke")
