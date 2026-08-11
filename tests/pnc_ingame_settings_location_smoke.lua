local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/"
    .. "PNC_Settings.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

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

dofile(FILE)

assertEqual(createdID, "ProjectHoomans",
    "native mod-options registration id")
assertEqual(createdName, "UI_PNC_Settings_Title",
    "native mod-options translated title")
assert(options:getOption("showAIDebug"),
    "AI overlay missing from native options")
assert(options:getOption("debugShowAnimation"),
    "animation detail missing from native options")
assert(options:getOption("storageTransactionLogging"),
    "storage transaction logging missing from native options")

options:getOption("showAIDebug").value = true
options:apply()
assertEqual(PNC.Nameplates.Settings.showAIDebug, true,
    "native settings did not apply AI overlay")
assertEqual(writes.showAIDebug, true,
    "native settings did not persist AI overlay")
options:getOption("storageTransactionLogging").value = true
options:apply()
assertEqual(PNC.Nameplates.Settings.storageTransactionLogging, true,
    "storage transaction logging setting did not apply")
assertEqual(writes.storageTransactionLogging, true,
    "storage transaction logging setting did not persist")
assertEqual(PNC.Settings.Open(), options,
    "compatibility settings surface")

print("pnc_ingame_settings_location_smoke: ok")
