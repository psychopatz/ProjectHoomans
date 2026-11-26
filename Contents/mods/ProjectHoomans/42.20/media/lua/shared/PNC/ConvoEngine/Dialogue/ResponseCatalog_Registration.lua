-- Response-pool registration and bounded extension operations.

return function(Catalog, Core)
    -- Registration call-site instrumentation is optional on game runtimes
    -- without debug.getinfo. It never changes selection or depends on paths
    -- guessed by Python textual scanning.
    local function registrationSource()
        local debugAPI = rawget(_G, "debug")
        local getInfo = type(debugAPI) == "table" and debugAPI["getinfo"]
        if type(getInfo) ~= "function" then
            return nil
        end
        local info = getInfo(3, "S")
        local source = info and info.source
        if type(source) == "string" and string.sub(source, 1, 1) == "@"
            and #source < 1024 then
            return string.sub(source, 2)
        end
        return nil
    end

    local function variantMaxScore(variant)
        local keyCount = 0
        if type(variant._whenKeys) == "table" then
            keyCount = #variant._whenKeys
        elseif type(variant.when) == "table" then
            for _ in pairs(variant.when) do keyCount = keyCount + 1 end
        end
        return (tonumber(variant.priority) or 0) * 100 + keyCount
    end

    local function rebuildPoolIndices(pool)
        local byID = {}
        local evalOrder = {}
        local variants = pool.variants or {}
        for index = 1, #variants do
            local v = variants[index]
            v._maxScore = variantMaxScore(v)
            if v.id ~= nil then byID[tostring(v.id)] = v end
            evalOrder[index] = index
        end
        table.sort(evalOrder, function(a, b)
            local sa = variants[a]._maxScore or 0
            local sb = variants[b]._maxScore or 0
            if sa ~= sb then return sa > sb end
            return a < b
        end)

        -- Pre-index single-string role & topic predicates in _evalOrder so
        -- hot-path Select() scans only matching buckets + fallback variants.
        local byRole, noRole, hasRoleBuckets = {}, {}, false
        local byTopic, noTopic, hasTopicBuckets = {}, {}, false
        for step = 1, #evalOrder do
            local index = evalOrder[step]
            local w = variants[index] and variants[index].when
            local roleVal = type(w) == "table" and w.combatReactionRole or nil
            if type(roleVal) == "string" and roleVal ~= "" then
                local bucket = byRole[roleVal]
                if not bucket then
                    bucket = {}
                    byRole[roleVal] = bucket
                end
                bucket[#bucket + 1] = index
                hasRoleBuckets = true
            else
                noRole[#noRole + 1] = index
            end

            local topicVal = type(w) == "table" and w.topic or nil
            if type(topicVal) == "string" and topicVal ~= "" then
                local bucket = byTopic[topicVal]
                if not bucket then
                    bucket = {}
                    byTopic[topicVal] = bucket
                end
                bucket[#bucket + 1] = index
                hasTopicBuckets = true
            else
                noTopic[#noTopic + 1] = index
            end
        end

        pool.byID = byID
        pool._evalOrder = evalOrder
        pool._byRole = hasRoleBuckets and byRole or nil
        pool._noRole = hasRoleBuckets and noRole or nil
        pool._byTopic = hasTopicBuckets and byTopic or nil
        pool._noTopic = hasTopicBuckets and noTopic or nil
    end

    local function isOverOptionalPoolLimit()
        local limit = tonumber(Catalog.MAX_POOLS)
        if not limit or limit <= 0 then return false end
        return (tonumber(Catalog.POOL_COUNT) or 0) >= limit
    end

    function Catalog.Preflight(id, definition, options)
        id = tostring(id or "")
        options = type(options) == "table" and options or {}
        if not Core.validID(id) or type(definition) ~= "table" then
            return false, {
                reason = "invalid_response_pool",
                poolID = id,
            }
        end
        local variants = definition.variants
        if type(variants) ~= "table" then
            return false, {
                reason = "response_pool_requires_variants",
                poolID = id,
            }
        end
        if options.strictVariants == true and #variants == 0 then
            return false, {
                reason = "response_pool_empty",
                poolID = id,
            }
        end
        if options.strictVariants == true and #variants > Catalog.MAX_VARIANTS then
            return false, {
                reason = "response_variant_limit",
                poolID = id,
            }
        end
        local validCount = 0
        local firstFailure = nil
        local limit = options.strictVariants == true
            and #variants or math.min(#variants, Catalog.MAX_VARIANTS)
        for index = 1, limit do
            local normalized, reason, detail = Core.validateVariant(
                id, index, variants[index]
            )
            if normalized then
                validCount = validCount + 1
            else
                if options.strictVariants == true then
                    return false, {
                        reason = tostring(reason or "invalid_response_variant"),
                        poolID = id,
                        variantIndex = index,
                        templateID = detail and detail.templateID or nil,
                        realizationID = detail and detail.realizationID or nil,
                    }
                end
                if not firstFailure then
                    firstFailure = {
                        reason = tostring(reason or "invalid_response_variant"),
                        poolID = id,
                        variantIndex = index,
                        templateID = detail and detail.templateID or nil,
                        realizationID = detail and detail.realizationID or nil,
                    }
                end
            end
        end
        if validCount == 0 then
            local emptyDetail = firstFailure or {}
            emptyDetail.reason = emptyDetail.reason or "response_pool_empty"
            emptyDetail.poolID = id
            return false, emptyDetail
        end
        local isNew = Catalog.POOLS[id] == nil
        if isNew and isOverOptionalPoolLimit() then
            return false, {
                reason = "response_pool_limit",
                poolID = id,
            }
        end
        return true, {
            id = id,
            variantCount = validCount,
            isNewPool = isNew,
        }
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
        local isNew = Catalog.POOLS[id] == nil
        if isNew and isOverOptionalPoolLimit() then
            return false, "response_pool_limit"
        end
        rebuildPoolIndices(pool)
        Catalog.POOLS[id] = pool
        if isNew then
            Catalog.POOL_COUNT = (tonumber(Catalog.POOL_COUNT) or 0) + 1
        end
        local origin = registrationSource()
        if origin ~= nil then
            local origins = {}
            for _, item in ipairs(pool.variants) do
                origins[item.id] = origin
            end
            Catalog.REGISTRATION_ORIGINS[id] = origins
        end
        Catalog.REVISION = (Catalog.REVISION or 0) + 1
        return true, pool
    end

    function Catalog.GetRaw(id)
        local key = tostring(id or "")
        if key == "" then return nil end
        return Catalog.POOLS[key]
    end

    function Catalog.Get(id)
        local key = tostring(id or "")
        local pool = Catalog.POOLS[key]
        if pool == nil and key ~= "" then
            local dsl = PNC and PNC.ConvoEngine and PNC.ConvoEngine.ConvoDSL
            if type(dsl) == "table" and type(dsl.PendingCount) == "function"
                and dsl.PendingCount() > 0 and type(dsl.EnsurePoolLoaded) == "function"
            then
                dsl.EnsurePoolLoaded(key)
                pool = Catalog.POOLS[key]
            end
        end
        return pool
    end

    -- Read the already selected variant without selecting again.  Lifecycle
    -- follow-up offers are part of the selected response plan, so resolving
    -- them must never rotate the catalog or create a second semantic choice.
    function Catalog.GetVariant(id, realizationID)
        local pool = Catalog.Get(id)
        local requested = tostring(realizationID or "")
        if not pool or requested == "" then return nil end
        if type(pool.byID) == "table" then
            return pool.byID[requested]
        end
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
        local pool = Catalog.POOLS[id]
        if pool == nil then pool = Catalog.Get(id) end
        local variants = type(definition) == "table" and definition.variants
        if not pool then return false, "response_pool_unavailable" end
        if type(variants) ~= "table" or #variants == 0 then
            return false, "response_pool_requires_variants"
        end
        if #pool.variants + #variants > Catalog.MAX_VARIANTS then
            return false, "response_variant_limit"
        end

        local existingByID = type(pool.byID) == "table" and pool.byID or nil
        local batchSeen = {}
        local index
        local variant
        if existingByID == nil then
            existingByID = {}
            for index = 1, #pool.variants do
                variant = pool.variants[index]
                existingByID[variant.id] = variant
            end
        end
        local additions = {}
        local normalized
        for index = 1, #variants do
            normalized = Core.normalizedVariant(
                id, #pool.variants + index, variants[index]
            )
            if not normalized then return false, "invalid_response_variant" end
            if existingByID[normalized.id] ~= nil or batchSeen[normalized.id] then
                return false, "duplicate_response_variant_id"
            end
            batchSeen[normalized.id] = true
            additions[#additions + 1] = normalized
        end
        local origin = registrationSource()
        local origins = origin ~= nil and (Catalog.REGISTRATION_ORIGINS[id] or {}) or nil
        for index = 1, #additions do
            pool.variants[#pool.variants + 1] = additions[index]
            if origins then origins[additions[index].id] = origin end
        end
        rebuildPoolIndices(pool)
        if origins then Catalog.REGISTRATION_ORIGINS[id] = origins end
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
