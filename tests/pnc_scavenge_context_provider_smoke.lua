local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" }, { "ProjectHoomans", "shared" } })

local provider
local policyState = {
    enabled = true,
    categories = {
        food = false, water = false, medical = false, weapons = false,
        ammo = false, tools = false, materials = false, clothing = false,
    },
    preferences = { containers = true, floorItems = true, corpses = true },
}

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
    Client = {
        GetScavengePolicy = function() return policyState end,
        SetScavengeEnabled = function(enabled)
            policyState.enabled = enabled == true
            return true
        end,
        SetScavengeCategory = function(categoryId, enabled)
            policyState.categories[categoryId] = enabled == true
            return true
        end,
        SetScavengeCategories = function(map)
            for k, _ in pairs(policyState.categories) do
                policyState.categories[k] = map and map[k] == true or false
            end
            return true
        end,
        SetScavengePreferences = function(prefs)
            policyState.preferences = prefs
            return true
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/WorldItems/PNC_WorldItemCategories.lua")

local function newMenu()
    return {
        options = {},
        checked = {},
        addOption = function(self, title, _, callback)
            local option = { title = title, callback = callback }
            self.options[#self.options + 1] = option
            return option
        end,
        addSubMenu = function(_, option, submenu)
            option.submenu = submenu
        end,
        setOptionChecked = function(self, option, checked)
            self.checked[option.title] = checked == true
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
local follower = { id = "bob", name = "Bob", record = {
    orderSpec = { kind = "follow", ownerOnlineID = 7 },
} }
local idleNpc = { id = "carl", name = "Carl", record = {
    orderSpec = { kind = "idle" },
} }

T.truthy(provider.isEnabled(follower, player),
    "current follower exposes category scavenging context")
T.falsy(provider.isEnabled(idleNpc, player),
    "non-following NPC does not expose follow category scavenge submenu")

local menu = newMenu()
provider.addOptions(menu, follower, player)
T.equal(#menu.options, 1, "scavenging uses a single submenu")
local submenu = menu.options[1].submenu
-- 1 toggle + 8 categories + 1 Sources submenu + 1 Clear = 11 options
T.equal(#submenu.options, 11, "submenu provides auto toggle, 8 categories, sources, and clear")

submenu.options[1].callback()
T.equal(policyState.enabled, false, "first option toggles auto-scavenge enabled flag")

-- Toggle Food (option 2) and Medical (option 4)
submenu.options[2].callback()
submenu.options[4].callback()
T.equal(policyState.categories.food, true, "toggled food category on")
T.equal(policyState.categories.medical, true, "toggled medical category on")

-- Sources submenu (option 10)
local sourcesSub = submenu.options[10].submenu
T.equal(#sourcesSub.options, 3, "sources submenu exposes containers, floor, corpses")
sourcesSub.options[1].callback()
T.equal(policyState.preferences.containers, false, "containers source preference toggled off")

-- Clear Categories (option 11)
submenu.options[11].callback()
T.equal(policyState.categories.food, false, "clear resets food category")
T.equal(policyState.categories.medical, false, "clear resets medical category")

T.finish("pnc_scavenge_context_provider_smoke")
