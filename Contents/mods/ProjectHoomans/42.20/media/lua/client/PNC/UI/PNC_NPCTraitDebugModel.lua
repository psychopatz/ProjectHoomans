-- Engine-free presentation model for the live NPC trait registry inspector.

PNC = PNC or {}
PNC.NPCTraitDebugModel = PNC.NPCTraitDebugModel or {}

local Model = PNC.NPCTraitDebugModel

local function text(value)
    if value == nil then return "" end
    if type(value) == "boolean" then return value and "true" or "false" end
    return tostring(value)
end

local function humanize(value)
    value = text(value)
    value = string.gsub(value, "^pnc[_:]", "")
    value = string.gsub(value, "([a-z0-9])([A-Z])", "%1 %2")
    value = string.gsub(value, "[_:.-]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    -- Kahlua can pass an omitted optional capture as nil. Match complete
    -- words instead, so the callback always receives one concrete string.
    value = string.gsub(value, "%a+", function(word)
        word = tostring(word or "")
        return string.upper(string.sub(word, 1, 1))
            .. string.lower(string.sub(word, 2))
    end)
    return value ~= "" and value or "none"
end

local function number(value)
    local numeric = tonumber(value)
    if numeric == nil then return text(value) end
    return string.format("%.2f", numeric)
end

local function signed(value)
    local numeric = tonumber(value)
    if numeric == nil then return text(value) end
    if math.abs(numeric) < 0.0005 then numeric = 0 end
    return (numeric > 0 and "+" or "") .. number(numeric)
end

local function multiplier(value)
    local numeric = tonumber(value)
    if numeric == nil then return text(value) end
    local percent = math.floor(math.abs((numeric - 1) * 100) + 0.5)
    local sign = numeric >= 1 and "+" or "-"
    return "x" .. number(numeric) .. " (" .. sign .. percent .. "%)"
end

local function threshold(value)
    return ">= " .. number(value)
end

local function keys(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, _ in pairs(value) do output[#output + 1] = key end
    table.sort(output, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return output
end

local function listText(value)
    local output = {}
    if type(value) ~= "table" then return "none" end
    if #value > 0 then
        for index = 1, #value do
            output[#output + 1] = text(value[index])
        end
    else
        for key, enabled in pairs(value) do
            if enabled then output[#output + 1] = text(key) end
        end
        table.sort(output)
    end
    return #output > 0 and table.concat(output, ", ") or "none"
end

local function mapText(value)
    local output = {}
    for _, key in ipairs(keys(value)) do
        local item = value[key]
        if type(item) ~= "table" then
            output[#output + 1] = text(key) .. "=" .. text(item)
        end
    end
    return #output > 0 and table.concat(output, ", ") or "none"
end

local function addRow(rows, label, value, metadata)
    local row = { label = label, value = text(value) }
    for key, item in pairs(metadata or {}) do row[key] = item end
    rows[#rows + 1] = row
end

local function addMapRows(rows, prefix, value, depth)
    if type(value) ~= "table" then
        addRow(rows, prefix, value == nil and "none" or value)
        return
    end
    depth = depth or 0
    if depth > 5 then
        addRow(rows, prefix, "[nested]")
        return
    end
    local itemKeys = keys(value)
    if #itemKeys == 0 then
        addRow(rows, prefix, "none")
        return
    end
    for _, key in ipairs(itemKeys) do
        local item = value[key]
        local label = prefix .. " / " .. humanize(key)
        if type(item) == "table" then
            addMapRows(rows, label, item, depth + 1)
        else
            addRow(rows, label, item == nil and "none" or item)
        end
    end
end

local function addPersonalityRows(rows, effects)
    for _, key in ipairs(keys(effects)) do
        addRow(rows, "Personality / " .. humanize(key), signed(effects[key]))
    end
end

local function addCategoryBiasRows(rows, effects)
    for _, category in ipairs(keys(effects)) do
        local candidates = effects[category]
        for _, candidate in ipairs(keys(candidates)) do
            addRow(rows, "Category bias / " .. humanize(category),
                humanize(candidate) .. " (" .. signed(candidates[candidate])
                    .. " bias)")
        end
    end
end

local function addBehaviorRows(rows, effects)
    for _, key in ipairs(keys(effects)) do
        addRow(rows, "Behavior / " .. humanize(key), signed(effects[key]))
    end
end

local FIREARM_LABELS = {
    fireRateMultiplier = "Fire rate",
    aimTimeMultiplier = "Aim time",
    hitChanceBias = "Hit chance",
    pressureAccuracyBias = "Pressure accuracy",
    confidenceThresholdBias = "Confidence threshold",
}

local MELEE_LABELS = {
    attackRateMultiplier = "Attack rate",
    windupTimeMultiplier = "Wind-up time",
    hitChanceBias = "Hit chance",
    pressureAccuracyBias = "Pressure accuracy",
}

local function firearmValue(key, value)
    if key == "fireRateMultiplier" or key == "aimTimeMultiplier" then
        return multiplier(value)
    end
    return signed((tonumber(value) or 0) * 100) .. " percentage points"
end

local function meleeValue(key, value)
    if key == "attackRateMultiplier" or key == "windupTimeMultiplier" then
        return multiplier(value)
    end
    return signed((tonumber(value) or 0) * 100) .. " percentage points"
end

local function addCombatRows(rows, effects)
    local firearm = effects and effects.firearm
    local melee = effects and effects.melee
    local key
    local emitted = false
    if type(firearm) == "table" then
        emitted = true
        for _, key in ipairs({
            "fireRateMultiplier",
            "aimTimeMultiplier",
            "hitChanceBias",
            "pressureAccuracyBias",
            "confidenceThresholdBias",
        }) do
            if firearm[key] ~= nil then
                addRow(rows, "Combat / Firearm / "
                    .. (FIREARM_LABELS[key] or humanize(key)),
                    firearmValue(key, firearm[key]))
            end
        end
    end
    if type(melee) == "table" then
        emitted = true
        for _, key in ipairs({
            "attackRateMultiplier",
            "windupTimeMultiplier",
            "hitChanceBias",
            "pressureAccuracyBias",
        }) do
            if melee[key] ~= nil then
                addRow(rows, "Combat / Melee / "
                    .. (MELEE_LABELS[key] or humanize(key)),
                    meleeValue(key, melee[key]))
            end
        end
    end
    if not emitted then
        addRow(rows, "Combat / Firearm", "none")
    end
    for _, key in ipairs(keys(effects)) do
        if key ~= "firearm" and key ~= "melee" then
            addMapRows(rows, "Combat / " .. humanize(key), effects[key])
        end
    end
end

local SLEEP_POLICY_LABELS = {
    actionThresholdMultiplier = "Action threshold",
    criticalThresholdMultiplier = "Critical threshold",
    wakeThresholdMultiplier = "Wake threshold",
    recoveryMultiplier = "Recovery rate",
}

local function addNeedsRows(rows, effects)
    local order = { "awakeMultiplier", "sleepingMultiplier", "threshold" }
    local labels = {
        awakeMultiplier = "Awake rate",
        sleepingMultiplier = "Sleeping rate",
        threshold = "Threshold",
    }
    for _, need in ipairs(keys(effects)) do
        local effect = effects[need]
        if need == "sleepPolicy" and type(effect) == "table" then
            for _, key in ipairs(keys(effect)) do
                addRow(rows, "Sleep policy / "
                    .. (SLEEP_POLICY_LABELS[key] or humanize(key)),
                    multiplier(effect[key]))
            end
        elseif type(effect) ~= "table" then
            addRow(rows, "Need / " .. humanize(need), effect)
        else
            local emitted = {}
            for _, key in ipairs(order) do
                if effect[key] ~= nil then
                    emitted[key] = true
                    local value = key == "threshold"
                        and threshold(effect[key]) or multiplier(effect[key])
                    addRow(rows, "Need / " .. humanize(need) .. " / "
                        .. labels[key], value)
                end
            end
            for _, key in ipairs(keys(effect)) do
                if not emitted[key] then
                    addRow(rows, "Need / " .. humanize(need) .. " / "
                        .. humanize(key), effect[key])
                end
            end
        end
    end
end

local function addConditionRows(rows, effects)
    local order = { "positiveMultiplier", "negativeMultiplier" }
    local labels = {
        positiveMultiplier = "Positive rate",
        negativeMultiplier = "Negative rate",
    }
    for _, condition in ipairs(keys(effects)) do
        local effect = effects[condition]
        if type(effect) ~= "table" then
            addRow(rows, "Condition / " .. humanize(condition), effect)
        else
            local emitted = {}
            for _, key in ipairs(order) do
                if effect[key] ~= nil then
                    emitted[key] = true
                    addRow(rows, "Condition / " .. humanize(condition) .. " / "
                        .. labels[key], multiplier(effect[key]))
                end
            end
            for _, key in ipairs(keys(effect)) do
                if not emitted[key] then
                    addRow(rows, "Condition / " .. humanize(condition) .. " / "
                        .. humanize(key), effect[key])
                end
            end
        end
    end
end

local function addSleepPolicyRows(rows, effects)
    for _, key in ipairs(keys(effects)) do
        addRow(rows, "Sleep policy / "
            .. (SLEEP_POLICY_LABELS[key] or humanize(key)),
            multiplier(effects[key]))
    end
end

local function addEffectRows(rows, effects)
    local emitted = {}
    local startCount = #rows
    if type(effects) ~= "table" then
        addRow(rows, "Effects", "none")
        return
    end
    if type(effects.personality) == "table" then
        addPersonalityRows(rows, effects.personality)
        emitted.personality = true
    end
    if type(effects.categoryBiases) == "table" then
        addCategoryBiasRows(rows, effects.categoryBiases)
        emitted.categoryBiases = true
    end
    if type(effects.behavior) == "table" then
        addBehaviorRows(rows, effects.behavior)
        emitted.behavior = true
    end
    if type(effects.combat) == "table" then
        addCombatRows(rows, effects.combat)
        emitted.combat = true
    end
    if type(effects.needs) == "table" then
        addNeedsRows(rows, effects.needs)
        emitted.needs = true
    end
    if type(effects.conditions) == "table" then
        addConditionRows(rows, effects.conditions)
        emitted.conditions = true
    end
    if type(effects.sleepPolicy) == "table" then
        addSleepPolicyRows(rows, effects.sleepPolicy)
        emitted.sleepPolicy = true
    end
    for _, key in ipairs(keys(effects)) do
        if not emitted[key] then
            addMapRows(rows, "Effect / " .. humanize(key), effects[key])
        end
    end
    if #rows == startCount then addRow(rows, "Effects", "none") end
end

local function definitions()
    local registry = PNC.NPCTraits
    if not registry or not registry.GetDefinitions then return {} end
    return registry.GetDefinitions()
end

function Model.BuildItems()
    local output = {}
    for _, definition in ipairs(definitions()) do
        local effects = definition.effects or {}
        local channels = keys(effects)
        local channelNames = {}
        for _, channel in ipairs(channels) do
            channelNames[#channelNames + 1] = humanize(channel)
        end
        output[#output + 1] = {
            id = definition.id,
            label = humanize(definition.id),
            labelKey = definition.labelKey,
            descriptionKey = definition.descriptionKey,
            detail = humanize(definition.source or "npc") .. " | "
                .. (#channels > 0 and table.concat(channelNames, ", ")
                    or "no effects"),
            definition = definition,
        }
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Model.BuildRows(definition)
    local rows = {}
    if type(definition) ~= "table" then return rows end
    addRow(rows, "ID", definition.id)
    addRow(rows, "Name", definition.labelKey or definition.id, {
        translationKey = definition.labelKey,
        fallback = humanize(definition.id),
    })
    addRow(rows, "Description", definition.descriptionKey
        or definition.labelKey or definition.id, {
            translationKey = definition.descriptionKey
                or definition.labelKey,
            fallback = humanize(definition.id),
        })
    addRow(rows, "Label key", definition.labelKey)
    addRow(rows, "Description key", definition.descriptionKey)
    addRow(rows, "Source", humanize(definition.source))
    addRow(rows, "Priority", definition.priority)
    addRow(rows, "Icon", definition.iconPath)
    addRow(rows, "Aliases", listText(definition.aliases))
    addRow(rows, "Excludes", listText(definition.excludes))
    addRow(rows, "Tags", listText(definition.tags))
    if definition.generation then
        addMapRows(rows, "Generation", definition.generation)
    else
        addRow(rows, "Generation", "none")
    end
    addEffectRows(rows, definition.effects)
    return rows
end

function Model.Summary(definition)
    if type(definition) ~= "table" then return "none" end
    return "source=" .. text(definition.source or "npc")
        .. " | effects=" .. mapText(definition.effects)
end

return Model
