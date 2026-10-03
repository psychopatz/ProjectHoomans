local Player = PNC.AnimationDebugPlayer
local Internal = Player.Internal or {}
local Conditions = Internal.Conditions
local SelectorAdapters = Internal.SELECTOR_ADAPTERS
local ReadOnlySelectors = Internal.READ_ONLY_SELECTORS
local SELECTOR_ADAPTERS = SelectorAdapters
local READ_ONLY_SELECTORS = ReadOnlySelectors

local function conditionValue(condition)
    local kind = tostring(condition and condition.kind or "")
    local raw = condition and condition.value or nil
    if kind == "BOOL" then
        return tostring(raw) == "true"
    end
    if kind == "GTR" then
        return (tonumber(raw) or 0) + 0.01
    end
    if kind == "LESS" then
        return (tonumber(raw) or 0) - 0.01
    end
    if kind == "STRNEQ" then
        return tostring(raw or "") .. "__PNC_DEBUG_NOT_EQUAL__"
    end
    return tostring(raw or "")
end

local function readVariable(body, condition)
    local kind = tostring(condition and condition.kind or "")
    local name = condition and condition.name or nil
    local adapter = name
        and SELECTOR_ADAPTERS[string.lower(tostring(name))]
        or nil
    if not name or name == "" then return nil end
    if adapter then return adapter.get(body) end
    if kind == "BOOL" and body.getVariableBoolean then
        return body:getVariableBoolean(name) == true
    end
    if (kind == "GTR" or kind == "LESS")
        and body.getVariableFloat
    then
        return body:getVariableFloat(name, 0.0)
    end
    if body.getVariableString then
        return tostring(body:getVariableString(name) or "")
    end
    return nil
end

local function saveAndApplyConditions(active)
    local body = active.body
    if not body.setVariable then return end
    for _, condition in ipairs(active.entry.conditions or {}) do
        local name = condition.name
        if name and name ~= "" then
            local normalized = string.lower(tostring(name))
            local adapter = SELECTOR_ADAPTERS[normalized]
            if READ_ONLY_SELECTORS[normalized] then
                active.skippedSelectors[#active.skippedSelectors + 1] =
                    tostring(name)
            elseif active.previousVariables[name] == nil then
                active.previousVariables[name] = {
                    condition = condition,
                    value = readVariable(body, condition),
                    adapter = adapter,
                }
                if adapter then
                    adapter.set(body, conditionValue(condition))
                else
                    body:setVariable(name, conditionValue(condition))
                end
            elseif adapter then
                adapter.set(body, conditionValue(condition))
            else
                body:setVariable(name, conditionValue(condition))
            end
        end
    end
    -- Every PNC node depends on the human-shell discriminator, either
    -- directly or through its inherited base node.
    body:setVariable("PNCActor", true)
end

local function restoreConditions(active)
    local body = active and active.body or nil
    if not body or not body.setVariable then return end
    for name, previous in pairs(active.previousVariables or {}) do
        if previous.adapter then
            previous.adapter.set(body, previous.value)
        elseif previous.value ~= nil then
            body:setVariable(name, previous.value)
        elseif body.clearVariable then
            body:clearVariable(name)
        end
    end
    body:setVariable("PNCActor", true)
end

local function markPreview(active)
    local modData = active.body.getModData
        and active.body:getModData()
        or nil
    if not modData then return end
    modData.PNC_AnimationDebugPreview = true
    modData.PNC_AnimationDebugMode = active.mode
    modData.PNC_AnimationDebugState = active.entry.state
    modData.PNC_AnimationDebugNode = active.entry.node
    modData.PNC_AnimationDebugClip = active.entry.anim
    modData.PNC_AnimationDebugStartedAt = active.startedAt
end

local function clearPreview(active)
    local modData = active
        and active.body
        and active.body.getModData
        and active.body:getModData()
        or nil
    if not modData then return end
    modData.PNC_AnimationDebugPreview = nil
    modData.PNC_AnimationDebugMode = nil
    modData.PNC_AnimationDebugState = nil
    modData.PNC_AnimationDebugNode = nil
    modData.PNC_AnimationDebugClip = nil
    modData.PNC_AnimationDebugStartedAt = nil
end

Conditions.save = saveAndApplyConditions
Conditions.restore = restoreConditions
Conditions.mark = markPreview
Conditions.clear = clearPreview
