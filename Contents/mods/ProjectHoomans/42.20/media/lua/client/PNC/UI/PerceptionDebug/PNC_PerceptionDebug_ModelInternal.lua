-- Shared pure formatting helpers for the perception debug presentation
-- model.  Snapshot values are already primitive before they reach here.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Model = PNC.PerceptionDebug.Model or {}
PNC.PerceptionDebug.Model = Model

local Internal = Model.Internal or {}
Model.Internal = Internal

local LABEL_KEYS = {
    selection = "UI_PNC_PerceptionDebug_Label_Selection",
    ["native name"] = "UI_PNC_PerceptionDebug_Label_NativeName",
    ["NPC command name"] = "UI_PNC_PerceptionDebug_Label_NPCCommandName",
    ["semantic kinds"] = "UI_PNC_PerceptionDebug_Label_SemanticKinds",
    ["object / sprite"] = "UI_PNC_PerceptionDebug_Label_ObjectSprite",
    usage = "UI_PNC_PerceptionDebug_Label_Usage",
    ["valid sitting object"] = "UI_PNC_PerceptionDebug_Label_ValidSitting",
    ["sitting seats"] = "UI_PNC_PerceptionDebug_Label_SittingSeats",
    ["sitting validation"] = "UI_PNC_PerceptionDebug_Label_SittingValidation",
    ["valid sleeping object"] = "UI_PNC_PerceptionDebug_Label_ValidSleeping",
    ["sleep surface"] = "UI_PNC_PerceptionDebug_Label_SleepSurface",
    ["water state"] = "UI_PNC_PerceptionDebug_Label_WaterState",
    ["water amount"] = "UI_PNC_PerceptionDebug_Label_WaterAmount",
    ["drink / fill"] = "UI_PNC_PerceptionDebug_Label_DrinkFill",
    ["jobs / capabilities"] = "UI_PNC_PerceptionDebug_Label_JobsCapabilities",
    room = "UI_PNC_PerceptionDebug_Label_Room",
    ["room type"] = "UI_PNC_PerceptionDebug_Label_RoomType",
    ["room identity"] = "UI_PNC_PerceptionDebug_Label_RoomIdentity",
    ["camp zone"] = "UI_PNC_PerceptionDebug_Label_CampZone",
    position = "UI_PNC_PerceptionDebug_Label_Position",
    ["object key"] = "UI_PNC_PerceptionDebug_Label_ObjectKey",
    ["resource key"] = "UI_PNC_PerceptionDebug_Label_ResourceKey",
    diagnostics = "UI_PNC_PerceptionDebug_Label_Diagnostics",
    ["camp policy"] = "UI_PNC_PerceptionDebug_Label_CampPolicy",
    preview = "UI_PNC_PerceptionDebug_Label_Preview",
    ["preview result"] = "UI_PNC_PerceptionDebug_Label_PreviewResult",
    source = "UI_PNC_PerceptionDebug_Label_Source",
    scope = "UI_PNC_PerceptionDebug_Label_Scope",
    label = "UI_PNC_PerceptionDebug_Label_Label",
    ["site / campfire id"] = "UI_PNC_PerceptionDebug_Label_SiteCampfireID",
}

local VALUE_KEYS = {
    YES = "UI_PNC_PerceptionDebug_Value_Yes",
    NO = "UI_PNC_PerceptionDebug_Value_No",
    none = "UI_PNC_PerceptionDebug_Value_None",
    unknown = "UI_PNC_PerceptionDebug_Value_Unknown",
    unclassified = "UI_PNC_PerceptionDebug_Value_Unclassified",
    room = "UI_PNC_PerceptionDebug_Value_Room",
    ["living room"] = "UI_PNC_PerceptionDebug_Value_LivingRoom",
    bedroom = "UI_PNC_PerceptionDebug_Value_Bedroom",
    bathroom = "UI_PNC_PerceptionDebug_Value_Bathroom",
    kitchen = "UI_PNC_PerceptionDebug_Value_Kitchen",
    bed = "UI_PNC_PerceptionDebug_Value_Bed",
    sofa = "UI_PNC_PerceptionDebug_Value_Sofa",
    campfire = "UI_PNC_PerceptionDebug_Value_Campfire",
    SAFE = "UI_PNC_PerceptionDebug_Value_Safe",
    UNSAFE = "UI_PNC_PerceptionDebug_Value_Unsafe",
    ACTIVE = "UI_PNC_PerceptionDebug_Value_Active",
    DEPLETED = "UI_PNC_PerceptionDebug_Value_Depleted",
    UNKNOWN = "UI_PNC_PerceptionDebug_Value_Unknown",
    UNAVAILABLE = "UI_PNC_PerceptionDebug_Value_Unavailable",
    READY = "UI_PNC_PerceptionDebug_Value_Ready",
    ["room then campfire"] = "UI_PNC_PerceptionDebug_Value_RoomThenCampfire",
    Sitting = "UI_PNC_PerceptionDebug_Usage_Sitting",
    Drinking = "UI_PNC_PerceptionDebug_Usage_Drinking",
    ["Filling water"] = "UI_PNC_PerceptionDebug_Usage_FillingWater",
    Campfire = "UI_PNC_PerceptionDebug_Usage_Campfire",
    living = "UI_PNC_PerceptionDebug_Job_Living",
    recreation = "UI_PNC_PerceptionDebug_Job_Recreation",
    sleep = "UI_PNC_PerceptionDebug_Job_Sleep",
    camp = "UI_PNC_PerceptionDebug_Job_Camp",
    ["survival.drink.world"] = "UI_PNC_PerceptionDebug_Job_SurvivalDrink",
    ["survival.fill.water"] = "UI_PNC_PerceptionDebug_Job_SurvivalFill",
}

function Internal.Translate(key, fallback)
    local translation = PNC and PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local ok, value = pcall(translation.GetKey, key, fallback or key)
        if ok and value ~= nil and value ~= "" and value ~= key then
            return tostring(value)
        end
    end
    return fallback or key
end

function Internal.Format(key, fallback, ...)
    local translation = PNC and PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        local ok, value = pcall(translation.TrFormat, key, fallback, ...)
        if ok and value ~= nil and value ~= "" then return tostring(value) end
    end
    local args = { ... }
    local value = Internal.Translate(key, fallback or key)
    value = string.gsub(value, "%%(%d+)", function(index)
        local position = tonumber(index)
        return position and args[position] ~= nil
            and tostring(args[position]) or "%%" .. index
    end)
    local formattedOk, formatted = pcall(string.format, value, ...)
    return formattedOk and formatted or value
end

function Internal.Text(value, maximum)
    local result = tostring(value == nil and "" or value)
    if maximum then result = string.sub(result, 1, tonumber(maximum)) end
    return result
end

function Internal.DisplayValue(value)
    local raw = Internal.Text(value)
    local key = VALUE_KEYS[raw]
    if key then return Internal.Translate(key, raw) end
    local normalized = string.lower(string.gsub(raw, "_", " "))
    key = VALUE_KEYS[normalized]
    if key then return Internal.Translate(key, raw) end
    local state = string.match(raw, "^Water Source %(([%u_]+)%)$")
    if state then
        local stateKey = VALUE_KEYS[state]
        if stateKey then
            return Internal.Format("UI_PNC_PerceptionDebug_Usage_WaterSource",
                "Water Source (%1)", Internal.Translate(stateKey, state))
        end
    end
    local surface = string.match(raw, "^Sleeping %(([%a]+)%)$")
    if surface then
        local surfaceKey = surface == "bed"
            and "UI_PNC_PerceptionDebug_Usage_SleepingBed"
            or surface == "sofa"
            and "UI_PNC_PerceptionDebug_Usage_SleepingSofa" or nil
        if surfaceKey then
            return Internal.Translate(surfaceKey, raw)
        end
    end
    local indoor = string.match(raw, "^Indoor room: (.+)$")
    if indoor then
        return Internal.Format("UI_PNC_PerceptionDebug_Usage_IndoorRoom",
            "Indoor room: %1", Internal.DisplayValue(indoor))
    end
    return raw
end

function Internal.ListText(values, fallback)
    if type(values) ~= "table" or #values == 0 then
        return fallback or Internal.DisplayValue("none")
    end
    local output = {}
    for index = 1, #values do
        output[#output + 1] = Internal.DisplayValue(values[index])
    end
    return table.concat(output, ", ")
end

function Internal.YesNo(value)
    return Internal.DisplayValue(value == true and "YES" or "NO")
end

function Internal.AddLine(lines, label, value, tone)
    local rawLabel = Internal.Text(label)
    local labelKey = LABEL_KEYS[rawLabel]
    lines[#lines + 1] = {
        label = labelKey and Internal.Translate(labelKey, rawLabel)
            or rawLabel,
        value = Internal.DisplayValue(value),
        tone = tone,
    }
end

return Internal
