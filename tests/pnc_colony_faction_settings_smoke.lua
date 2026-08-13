local LUA_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = LUA_ROOT .. "client/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local promptCalls = 0
local snapshot = {
    faction = {
        id = "faction_player", name = "Morgan Clan",
        revision = 2, renamePending = true,
    },
    people = { { id = "npc_one" } },
}

PNC = {
    Const = {},
    Core = {
        Now = function() return 100 end,
        IsClientOnly = function() return false end,
        DeepCopy = function(value) return value end,
    },
    Network = { ClientState = {} },
    Client = { Internal = { IsWorldReady = function() return true end } },
    KnowledgeInterest = { CollectNPCIDs = function() return {} end },
    ColonyManagement = { BuildSnapshot = function() return snapshot end },
    ColonyNamePrompt = {
        OpenIfNeeded = function(value)
            equal(value, snapshot, "prompt receives local snapshot")
            promptCalls = promptCalls + 1
        end,
    },
}
getSpecificPlayer = function() return {} end

dofile(LUA_ROOT .. "client/PNC/Networking/PNC_ClientRequests.lua")
equal(PNC.Client.RequestColonyManagement(), true,
    "single-player colony snapshot request")
equal(promptCalls, 1, "single-player request checks faction prompt")

local function entry()
    local value = ""
    return {
        initialise = function() end,
        instantiate = function() end,
        setMaxTextLength = function() end,
        setVisible = function() end,
        setText = function(_, text) value = text end,
        getText = function() return value end,
    }
end
ISTextEntryBox = { new = function() return entry() end }
package.preload["ISUI/ISTextEntryBox"] = function() return ISTextEntryBox end

local function button(options)
    return {
        internal = options.id,
        setVisible = function() end,
        setEnable = function(self, value) self.enabled = value end,
    }
end
PsychopatzCore = {
    UI = {
        CreateButton = function(_, options) return button(options) end,
        Layout = { SetBounds = function() end },
    },
}
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
ISPNCColonyManagementWindow = { onColonySettingsControl = function() end }
local renamed
PNC.Client.RenameFaction = function(name)
    renamed = name
    return true, "renamed"
end

local Settings = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_SettingsTab"
)
local details = {}
local window = {
    addChild = function() end,
    addDetail = function(_, label, detail)
        details[#details + 1] = { label = label, detail = detail }
    end,
    refresh = function(self) self.refreshed = true end,
}
Settings.Create(window)
Settings.Rebuild(window, snapshot)
equal(window.factionNameEntry:getText(), "Morgan Clan",
    "settings binds current faction name")
window.factionNameEntry:setText("Morgan Wardens")
equal(Settings.OnControl(window, window.factionRenameButton), true,
    "settings submits faction rename")
equal(renamed, "Morgan Wardens", "settings submits edited name")
equal(window.refreshed, true, "settings refreshes after local rename")

print("pnc_colony_faction_settings_smoke: ok")
