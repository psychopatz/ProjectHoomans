-- Response-pool registration and bounded extension operations.

return function(Catalog, Core)
    -- Registration call-site instrumentation is optional on game runtimes
    -- without debug.getinfo. It never changes selection or depends on paths
    -- guessed by Python textual scanning.
    local function registrationSource()
        if type(debug) ~= "table"
            or type(debug.getinfo) ~= "function" then
            return nil
        end
        local info = debug.getinfo(3, "S")
        local source = info and info.source
        if type(source) == "string" and string.sub(source, 1, 1) == "@"
            and #source < 1024 then
            return string.sub(source, 2)
        end
        return nil
    end

    function Catalog.Register(id, definition)
        local pool
        local variants
        local index
        local variant
        id = tostring(id or "")
        if not Core.validID(id) or type(definition) ~= "table" then
            return false, "invalid_response_pool"
        end
        variants = definition.variants
        if type(variants) ~= "table" then
            return false, "response_pool_requires_variants"
        end
        pool = {
            id = id,
            variants = {},
        }
        for index = 1, math.min(#variants, Catalog.MAX_VARIANTS) do
            variant = Core.normalizedVariant(id, index, variants[index])
            if variant then pool.variants[#pool.variants + 1] = variant end
        end
        if #pool.variants == 0 then return false, "response_pool_empty" end
        if not Catalog.POOLS[id] then
            local count = 0
            for _ in pairs(Catalog.POOLS) do count = count + 1 end
            if count >= Catalog.MAX_POOLS then
                return false, "response_pool_limit"
            end
        end
        Catalog.POOLS[id] = pool
        local origin = registrationSource()
        local origins = {}
        for _, item in ipairs(pool.variants) do
            origins[item.id] = origin or "UNKNOWN"
        end
        Catalog.REGISTRATION_ORIGINS[id] = origins
        Catalog.REVISION = (Catalog.REVISION or 0) + 1
        return true, pool
    end

    function Catalog.Get(id)
        return Catalog.POOLS[tostring(id or "")]
    end

    -- Read the already selected variant without selecting again.  Lifecycle
    -- follow-up offers are part of the selected response plan, so resolving
    -- them must never rotate the catalog or create a second semantic choice.
    function Catalog.GetVariant(id, realizationID)
        local pool = Catalog.Get(id)
        local requested = tostring(realizationID or "")
        if not pool or requested == "" then return nil end
        for _, variant in ipairs(pool.variants or {}) do
            if tostring(variant.id or "") == requested then
                return variant
            end
        end
        return nil
    end

    function Catalog.OffersForSelection(id, realizationID)
        local variant = Catalog.GetVariant(id, realizationID)
        local plan = variant and variant.plan or nil
        local output = {}
        if type(plan) ~= "table" or type(plan.turns) ~= "table" then
            return output
        end
        for _, turn in ipairs(plan.turns) do
            for _, offer in ipairs(turn.offers or {}) do
                if #output >= 8 then return output end
                output[#output + 1] = offer
            end
        end
        return output
    end

    function Catalog.Extend(id, definition)
        id = tostring(id or "")
        local pool = Catalog.Get(id)
        local variants = type(definition) == "table" and definition.variants
        if not pool then return false, "response_pool_unavailable" end
        if type(variants) ~= "table" or #variants == 0 then
            return false, "response_pool_requires_variants"
        end
        if #pool.variants + #variants > Catalog.MAX_VARIANTS then
            return false, "response_variant_limit"
        end

        local seenIDs = {}
        local index
        local variant
        for index = 1, #pool.variants do
            variant = pool.variants[index]
            seenIDs[variant.id] = true
        end
        local additions = {}
        local normalized
        for index = 1, #variants do
            normalized = Core.normalizedVariant(
                id, #pool.variants + index, variants[index]
            )
            if not normalized then return false, "invalid_response_variant" end
            if seenIDs[normalized.id] then
                return false, "duplicate_response_variant_id"
            end
            seenIDs[normalized.id] = true
            additions[#additions + 1] = normalized
        end
        local origin = registrationSource()
        local origins = Catalog.REGISTRATION_ORIGINS[id] or {}
        for index = 1, #additions do
            pool.variants[#pool.variants + 1] = additions[index]
            origins[additions[index].id] = origin or "UNKNOWN"
        end
        Catalog.REGISTRATION_ORIGINS[id] = origins
        Catalog.REVISION = (Catalog.REVISION or 0) + 1
        return true, pool
    end

    function Catalog.RegisterTextFallbacks()
        local count = 0
        for _, pool in pairs(Catalog.POOLS) do
            for _, variant in ipairs(pool.variants or {}) do
                Core.registerTextFallback(variant.templateID, variant.fallback)
                count = count + 1
            end
        end
        return count
    end
end
