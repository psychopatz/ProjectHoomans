local T = require "tests/support/test"

T.addPackagePaths()

local function list()
    local value = { items = {}, selected = 0, visible = false }
    function value:clear() self.items = {} end
    function value:addItem(label, item)
        self.items[#self.items + 1] = { label = label, item = item }
    end
    function value:getItem() return self.items[self.selected] end
    function value:setVisible(nextVisible) self.visible = nextVisible end
    return value
end

local function combo(data)
    return { selected = 1, options = { { data = data } } }
end

local Model = {
    TryAddSkill = function(draft, id, level)
        draft.skillLevels = draft.skillLevels or {}
        draft.skillLevels[id] = level
        return true, nil, id
    end,
    TryAddTrait = function(draft, kind, id)
        local field = kind == "npc" and "npcTraits"
            or kind == "vanilla" and "vanillaTraits" or "dynamicTraits"
        draft[field] = draft[field] or {}
        draft[field][id] = true
        return true, nil, id
    end,
    ListAuthoredItems = function() return {} end,
    NameParts = function() return "Jane", "patz" end,
}

local Profile = {
    Label = function(_, value) return tostring(value) end,
    SourceHelp = function(_, value) return tostring(value) end,
}

ISPNCNPCAuthoringEditor = {
    Internal = {
        Model = Model,
        Presentation = Profile,
        tr = function(key, fallback) return fallback or key end,
        comboData = function(value)
            local option = value.options and value.options[value.selected]
            return option and option.data or nil
        end,
        collectionIDs = function(source, valueEntries)
            local output = {}
            for id, enabled in pairs(source or {}) do
                if enabled == true or valueEntries and tonumber(enabled) ~= nil then
                    output[#output + 1] = tostring(id)
                end
            end
            table.sort(output)
            return output
        end,
        removeCollection = function(source, id)
            local output = {}
            for key, value in pairs(source or {}) do
                if tostring(key) ~= tostring(id) and value then output[key] = value end
            end
            return next(output) and output or nil
        end,
    },
}

PNC = {
    SkillCatalog = {
        GetGroups = function()
            return { { skills = { { id = "Farming", display = "Agriculture" } } } }
        end,
    },
    NPCTraits = {
        GetDefinitions = function()
            return {
                { id = "PNC_HasBrother", labelKey = "Has a Brother" },
                { id = "PNC_Berserker", label = "Berserker" },
            }
        end,
    },
    Translation = { GetKey = function(key, fallback) return fallback or key end },
}
CharacterTraitDefinition = {
    getTraits = function()
        return {
            size = function() return 1 end,
            get = function()
                return {
                    getType = function()
                        return { getName = function() return "Strong" end }
                    end,
                    getLabel = function() return "Strong" end,
                }
            end,
        }
    end,
}

T.load("ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Details.lua")

local window = setmetatable({
    presentationMode = "companion",
    inspectorVisible = false,
    draft = {
        skillLevels = {}, npcTraits = {}, vanillaTraits = {}, dynamicTraits = {},
        authoredFields = {}, identity = { survivor = {} },
    },
    configuredDetails = list(),
    details = list(),
    removeConfiguredButton = {
        setVisible = function(self, value) self.visible = value end,
        setEnable = function(self, value) self.enabled = value end,
    },
    removeButton = { setVisible = function() end },
    resetDetailsButton = { setVisible = function() end },
}, { __index = ISPNCNPCAuthoringEditor })
function window:refreshPreview() end
function window:setStatus(value) self.statusText = value end

window.skillCombo = combo("Farming")
window.skillLevelCombo = combo(3)
window.npcTraitCombo = combo("PNC_Berserker")
window.vanillaTraitCombo = combo("Strong")
window.dynamicTraitCombo = combo("PNC_HasBrother")

window:addSkill()
window:addTrait("npcTrait", window.npcTraitCombo)
window:addTrait("vanillaTrait", window.vanillaTraitCombo)
window:addTrait("dynamicTrait", window.dynamicTraitCombo)
T.equal(#window.configuredDetails.items, 4,
    "all configured skill and trait kinds are visible in General")
T.equal(window.configuredDetails.items[1].label, "Agriculture",
    "skills use a human catalog label")
for _, row in ipairs(window.configuredDetails.items) do
    T.falsy(string.find(row.label, "PNC_", 1, true),
        "normal collection rows do not expose internal IDs")
end

while #window.configuredDetails.items > 0 do
    window.configuredDetails.selected = 1
    window:removeSelectedConfigured()
end
T.equal(#window.configuredDetails.items, 0,
    "configured skills and traits can be removed from General")
T.finish("pnc_starting_companion_general_collections_smoke")
