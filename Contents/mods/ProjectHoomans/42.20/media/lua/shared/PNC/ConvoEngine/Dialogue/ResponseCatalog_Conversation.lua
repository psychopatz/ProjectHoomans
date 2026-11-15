-- Register response pools emitted by the canonical Conversation compiler.

local function canonicalPoolID(poolID)
    poolID = tostring(poolID or "")
    if poolID == "" then
        return ""
    end
    if string.sub(poolID, 1, 9) == "semantic." then
        return poolID
    end
    return "semantic." .. poolID
end

return function(Catalog, responsePools)
    if type(responsePools) ~= "table" then
        error("Conversation registry requires response pools")
    end
    local index
    local pool
    local targetID
    local registered
    local reason
    local function canonicalPrefixedID(value, rawID)
        value = tostring(value or "")
        if value == "" or string.sub(value, 1, 9) == "semantic." then
            return value
        end
        if value == rawID
            or string.sub(value, 1, #rawID + 1) == (rawID .. ".")
        then
            return "semantic." .. value
        end
        return value
    end

    local function canonicalPoolDefinition(pool, targetID, extendingExisting)
        local rawID = tostring(pool.id or "")
        local reg = PNC.ConvoEngine and PNC.ConvoEngine.Registry or nil
        local hasFamily = type(reg) == "table" and type(reg.FamilyFor) == "function"
        local copied = {}
        local key, value
        for key, value in pairs(pool) do
            copied[key] = value
        end
        copied.id = targetID
        if type(pool.variants) == "table" then
            local variants = {}
            local idx
            for idx = 1, #pool.variants do
                local variant = pool.variants[idx]
                if type(variant) == "table" then
                    local nextVariant = {}
                    for key, value in pairs(variant) do
                        nextVariant[key] = value
                    end
                    if targetID ~= rawID
                        and type(variant.id) == "string"
                        and variant.id ~= ""
                    then
                        nextVariant.id = canonicalPrefixedID(variant.id, rawID)
                    end
                    local rawTpl = tostring(variant.templateID or "")
                    local hasRegisteredFamily = rawTpl ~= ""
                        and hasFamily
                        and (reg.FamilyFor(rawTpl, "neutral") ~= nil
                            or (type(reg.ConvoPlan) == "function"
                                and reg.ConvoPlan(rawTpl) ~= nil))
                    if targetID ~= rawID
                        and rawTpl ~= ""
                        and not hasRegisteredFamily
                    then
                        nextVariant.templateID = canonicalPrefixedID(
                            rawTpl, rawID
                        )
                    end
                    if extendingExisting and nextVariant.priority == nil then
                        if not hasRegisteredFamily then
                            nextVariant.priority = -1
                        end
                    end
                    variants[idx] = nextVariant
                else
                    variants[idx] = variant
                end
            end
            copied.variants = variants
        end
        return copied
    end

    for index = 1, #responsePools do
        pool = responsePools[index]
        if type(pool) ~= "table" then
            error("Conversation registry contains an invalid response pool")
        end
        targetID = canonicalPoolID(pool.id)
        local existing = Catalog.Get(targetID)
        local canonicalPool = canonicalPoolDefinition(pool, targetID, existing ~= nil)
        if existing then
            registered, reason = Catalog.Extend(targetID, canonicalPool)
        else
            registered, reason = Catalog.Register(targetID, canonicalPool)
        end
        if registered ~= true then
            error("Conversation response pool could not register "
                .. tostring(targetID) .. " (" .. tostring(reason) .. ")")
        end
    end
end
