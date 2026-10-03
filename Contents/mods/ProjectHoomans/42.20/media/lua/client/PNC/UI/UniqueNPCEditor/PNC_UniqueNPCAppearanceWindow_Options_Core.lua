local AppearanceUI = PNC.UniqueNPCAppearanceUI
local Internal = AppearanceUI.Internal or {}
local Appearance = Internal.Appearance
local AudioDebug = Internal.AudioDebug

local function tr(key, fallback)
    return PNC.Translation.GetKey(key, fallback or key)
end

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function comboData(combo)
    local selected = combo and combo.selected or 0
    local option = combo and combo.options and combo.options[selected]
    return option and option.data or nil
end

local function selectData(combo, value)
    local found = false
    if value ~= nil and combo and combo.selectData then
        combo:selectData(value)
        for _, option in ipairs(combo.options or {}) do
            if option.data == value then
                found = true
                break
            end
        end
        if not found and combo.addOptionWithData then
            combo:addOptionWithData(
                tr("UI_PNC_UniqueNPCEditor_Unavailable", "Unavailable: ")
                    .. tostring(value), value)
            combo:selectData(value)
        end
    end
    if combo and combo.selected == 0 and combo.options and combo.options[1] then
        combo.selected = 1
    end
end

local function listValues(value)
    local output = {}
    if type(value) == "table" then
        for _, entry in ipairs(value) do output[#output + 1] = entry end
    elseif value and value.size and value.get then
        for index = 0, value:size() - 1 do
            output[#output + 1] = value:get(index)
        end
    end
    return output
end


Internal.tr = tr
Internal.copy = copy
Internal.comboData = comboData
Internal.selectData = selectData
Internal.listValues = listValues
AppearanceUI.Internal = Internal
