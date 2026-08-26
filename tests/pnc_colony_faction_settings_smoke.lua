local T = require "tests/support/test"

local LUA_ROOT = T.path("ProjectHoomans", "root", "")
T.addPackagePaths()

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
            T.equal(value, snapshot, "prompt receives local snapshot")
            promptCalls = promptCalls + 1
        end,
    },
}
getSpecificPlayer = function() return {} end

T.load(LUA_ROOT .. "client/PNC/Networking/PNC_ClientRequests.lua")
T.equal(PNC.Client.RequestColonyManagement(), true,
    "single-player colony snapshot request")
T.equal(promptCalls, 1, "single-player request checks faction prompt")

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
        CreateTextEntry = function(_, options)
            local value = entry()
            if options and options.text then value:setText(options.text) end
            return value
        end,
        Layout = { SetBounds = function() end },
    },
}
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
ISPNCColonyManagementWindow = { onColonySettingsControl = function() end }
local renamed
local savedEmblem
PNC.Client.RenameFaction = function(name)
    renamed = name
    return true, "renamed"
end
PNC.Client.SetFactionEmblem = function(emblem)
    savedEmblem = emblem
    return true
end
PNC.FactionEmblemEditor = {
    Open = function(options)
        options.onSave({ revision = 4, backgroundColorID = "blue" },
            options.context)
        return true
    end,
}

local Settings = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_SettingsTab"
)
local details = {}
local window = {
    snapshot = snapshot,
    addChild = function() end,
    addDetail = function(_, label, detail)
        details[#details + 1] = { label = label, detail = detail }
    end,
    refresh = function(self) self.refreshed = true end,
}
Settings.Create(window)
Settings.Rebuild(window, snapshot)
T.equal(window.factionNameEntry:getText(), "Morgan Clan",
    "settings binds current faction name")
window.factionNameEntry:setText("Morgan Wardens")
T.equal(Settings.OnControl(window, window.factionRenameButton), true,
    "settings submits faction rename")
T.equal(renamed, "Morgan Wardens", "settings submits edited name")
T.equal(window.refreshed, true, "settings refreshes after local rename")
T.equal(Settings.OnControl(window, window.factionEmblemButton), true,
    "settings opens the faction emblem editor")
T.equal(savedEmblem.backgroundColorID, "blue",
    "settings saves the edited player faction emblem")
T.finish("pnc_colony_faction_settings_smoke")

T.finish("pnc_colony_faction_settings_smoke")
