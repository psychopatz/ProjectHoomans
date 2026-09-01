local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/UI/")
    .. "PNC_Settings.lua"

local createdID
local createdName
local writes = {}
local options = {
    data = {},
    dict = {},
    addTitle = function(self, name)
        self.data[#self.data + 1] = { type = "title", name = name }
    end,
    addSeparator = function(self)
        self.data[#self.data + 1] = { type = "separator" }
    end,
    addTickBox = function(self, id, name, value)
        local option = {
            id = id,
            name = name,
            value = value,
            getValue = function(item) return item.value end,
        }
        self.data[#self.data + 1] = option
        self.dict[id] = option
        return option
    end,
    getOption = function(self, id) return self.dict[id] end,
    apply = function() end,
}

PZAPI = {
    ModOptions = {
        getOptions = function() return nil end,
        create = function(_, id, name)
            createdID = id
            createdName = name
            return options
        end,
    },
}
package.preload["PZAPI/ModOptions"] =
    function() return PZAPI.ModOptions end

PNC = {
    SettingsStore = {
        Set = function(_, id, value)
            writes[id] = value
        end,
    },
    Runtime = {},
    Nameplates = {
        Settings = {},
    },
}

T.load(FILE)

T.equal(createdID, "ProjectHoomans",
    "native mod-options registration id")
T.equal(createdName, "UI_PNC_Settings_Title",
    "native mod-options translated title")
T.truthy(options:getOption("showAIDebug"),
    "AI overlay missing from native options")
T.truthy(options:getOption("showCampDebug"),
    "camp facility overlay missing from native options")
T.truthy(options:getOption("debugShowAnimation"),
    "animation detail missing from native options")
T.truthy(options:getOption("storageTransactionLogging"),
    "storage transaction logging missing from native options")

options:getOption("showAIDebug").value = true
options:apply()
T.equal(PNC.Nameplates.Settings.showAIDebug, true,
    "native settings did not apply AI overlay")
T.equal(writes.showAIDebug, true,
    "native settings did not persist AI overlay")
options:getOption("storageTransactionLogging").value = true
options:apply()
T.equal(PNC.Nameplates.Settings.storageTransactionLogging, true,
    "storage transaction logging setting did not apply")
T.equal(writes.storageTransactionLogging, true,
    "storage transaction logging setting did not persist")
T.equal(PNC.Settings.Open(), options,
    "compatibility settings surface")
T.finish("pnc_ingame_settings_location_smoke")

T.finish("pnc_ingame_settings_location_smoke")
