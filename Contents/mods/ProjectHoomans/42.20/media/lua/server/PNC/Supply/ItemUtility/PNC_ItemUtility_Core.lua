if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.ItemUtility.Internal

function H.Call(target, method, ...)
    if not target or type(target[method]) ~= "function" then return nil end
    local ok, value = pcall(target[method], target, ...)
    if not ok then return nil end
    return value
end

function H.Number(value, fallback)
    if type(value) == "number" then return value end
    if type(value) == "string" then
        local converted = tonumber(value)
        if converted ~= nil then return converted end
    end
    return fallback
end

function H.Boolean(value)
    return value == true or tostring(value) == "true"
end

function H.AddTags(output, source)
    if type(source) == "table" then
        for key, value in pairs(source) do
            local tag = type(key) == "number" and value
                or value == true and key or nil
            if tag then output[string.lower(tostring(tag))] = true end
        end
    elseif source and source.size and source.get then
        for index = 0, source:size() - 1 do
            output[string.lower(tostring(source:get(index)))] = true
        end
    end
end

function H.ProbeFor(fullType)
    local item
    local ok
    if InventoryItemFactory then
        if InventoryItemFactory.CreateItem then
            ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
            if not ok then item = nil end
        end
        if not item and InventoryItemFactory.instanceItem then
            ok, item = pcall(InventoryItemFactory.instanceItem, fullType)
            if not ok then item = nil end
        end
    end
    if not item and instanceItem then
        ok, item = pcall(instanceItem, fullType)
        if not ok then item = nil end
    end
    local scriptItem = getScriptManager and getScriptManager()
        and getScriptManager():getItem(fullType) or nil
    return item, scriptItem
end

function H.NormalizeNeedChange(value)
    value = H.Number(value, 0) or 0
    if math.abs(value) > 2 then return value / 100 end
    return value
end

function H.ReadNumber(item, scriptItem, methods, fallback)
    for index = 1, #methods do
        local value = H.Call(item, methods[index])
        if value == nil then value = H.Call(scriptItem, methods[index]) end
        value = H.Number(value)
        if value ~= nil then return value end
    end
    return fallback
end

function H.ReadBoolean(item, scriptItem, methods)
    for index = 1, #methods do
        local value = H.Call(item, methods[index])
        if value == nil then value = H.Call(scriptItem, methods[index]) end
        if value ~= nil then return H.Boolean(value) end
    end
    return false
end

function H.HasAny(tags, values)
    for index = 1, #values do
        if tags[string.lower(values[index])] then return true end
    end
    return false
end

return H
