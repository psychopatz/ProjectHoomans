-- Production selector and optional read-only, explainable trace use the same
-- matching, scoring, hash and anti-repeat code path.
return function(Catalog, Core)
    local function evaluate(id, context, salt, explain)
        local dsl = PNC and PNC.ConvoEngine and PNC.ConvoEngine.ConvoDSL
        if type(dsl) == "table" then
            if type(dsl.EnsureActiveLanguage) == "function" then
                dsl.EnsureActiveLanguage()
            end
            if type(dsl.PendingCount) == "function" and dsl.PendingCount() > 0
                and type(dsl.EnsurePoolLoaded) == "function"
            then
                dsl.EnsurePoolLoaded(id)
            end
        end
        local pool = Catalog.Get(id)
        if not pool then return nil, "response_pool_unavailable" end

        local candidates = {}
        local rows = explain and {} or nil
        local bestScore = nil
        local condCtx = nil
        local variants = pool.variants or {}
        local evalOrder = (not explain and type(pool._evalOrder) == "table" and #pool._evalOrder == #variants)
            and pool._evalOrder or nil

        local function evaluateSlice(slice, count)
            for step = 1, count do
                local index = slice and slice[step] or step
                local variant = variants[index]
                if not explain and bestScore ~= nil and variant._maxScore ~= nil and variant._maxScore < bestScore then
                    break
                end
                local matched, specificity, checks
                if type(variant.when) ~= "table"
                    or (variant._whenCompiled == true and variant._whenKeys == nil)
                then
                    matched, specificity, checks = true, 0, explain and {} or nil
                else
                    if condCtx == nil then condCtx = Core.conditionContext(context) end
                    if Core.matchesNormalized then
                        matched, specificity, checks = Core.matchesNormalized(variant, condCtx, explain)
                    else
                        matched, specificity, checks = Core.matches(variant, context, explain)
                    end
                end
                local score = nil
                if matched then
                    score = (tonumber(variant.priority) or 0) * 100 + specificity
                    if bestScore == nil or score > bestScore then
                        bestScore = score
                        candidates = { index }
                    elseif score == bestScore then
                        candidates[#candidates + 1] = index
                    end
                end
                if explain then
                    rows[#rows + 1] = {
                        index = index, id = variant.id, eligible = matched,
                        specificity = matched and specificity or 0, score = score,
                        checks = checks or {},
                    }
                end
            end
        end

        local usedBucket = false
        if evalOrder ~= nil and type(context) == "table" then
            local reqRole = context.combatReactionRole
            if type(reqRole) == "string" and reqRole ~= "" and type(pool._byRole) == "table" then
                local roleBucket = pool._byRole[reqRole]
                if roleBucket then evaluateSlice(roleBucket, #roleBucket) end
                local fallbackBucket = pool._noRole
                if fallbackBucket then evaluateSlice(fallbackBucket, #fallbackBucket) end
                usedBucket = true
            else
                local reqTopic = context.topic
                if type(reqTopic) == "string" and reqTopic ~= "" and type(pool._byTopic) == "table" then
                    local topicBucket = pool._byTopic[reqTopic]
                    if topicBucket then evaluateSlice(topicBucket, #topicBucket) end
                    local fallbackBucket = pool._noTopic
                    if fallbackBucket then evaluateSlice(fallbackBucket, #fallbackBucket) end
                    usedBucket = true
                end
            end
        end
        if not usedBucket then
            evaluateSlice(evalOrder, #variants)
        end
        if #candidates == 0 then
            if explain then
                return {
                    ok = true, reason = "response_variant_unavailable",
                    poolID = id, selectedID = nil, candidates = rows,
                    bestScore = nil,
                }
            end
            return nil, "response_variant_unavailable"
        end

        local selectionKey = tostring(id) .. ":"
            .. tostring(context and context.npcID or "")
        local selectedPosition = (
            Core.hash(tostring(salt or "") .. ":" .. selectionKey)
                % #candidates) + 1
        local selectedIndex = candidates[selectedPosition]
        local previousIndex = Catalog.LAST_VARIANTS[selectionKey]
        local rotated = false
        if #candidates > 1 and previousIndex == selectedIndex then
            -- Identical rotation to the live path, using its actual history.
            selectedPosition = (selectedPosition % #candidates) + 1
            selectedIndex = candidates[selectedPosition]
            rotated = true
        end

        if explain then
            for _, row in ipairs(rows) do
                if row.eligible then
                    row.reason = row.score == bestScore
                        and "highest_rank" or "lower_score"
                else
                    row.reason = "condition_mismatch"
                end
                if row.index == selectedIndex then
                    row.reason = rotated and "anti_repeat_rotation"
                        or (#candidates > 1 and "hash_tie_break"
                            or "sole_highest_score")
                end
            end
            return {
                ok = true, schemaVersion = 1,
                type = "response_selection_explanation",
                poolID = id, selectedID = pool.variants[selectedIndex].id,
                selectedIndex = selectedIndex, previousIndex = previousIndex,
                rotated = rotated, tieCount = #candidates,
                bestScore = bestScore, candidates = rows,
                reason = "selected",
            }
        end

        if previousIndex == nil then
            local cap = tonumber(Catalog.MAX_LAST_VARIANTS) or 512
            local order = Catalog.LAST_VARIANT_ORDER
            local count = tonumber(Catalog._lastVariantCount) or 0
            local head = tonumber(Catalog._lastVariantHead) or 1
            if count >= cap then
                local oldest = order[head]
                if oldest ~= nil then
                    Catalog.LAST_VARIANTS[oldest] = nil
                end
                order[head] = selectionKey
                Catalog._lastVariantHead = (head % cap) + 1
            else
                local slot = ((head + count - 1) % cap) + 1
                order[slot] = selectionKey
                Catalog._lastVariantCount = count + 1
            end
        end
        Catalog.LAST_VARIANTS[selectionKey] = selectedIndex
        local variant = pool.variants[selectedIndex]
        return {
            id = variant.id,
            templateID = variant.templateID,
            fallback = variant.fallback,
            plan = variant.plan,
            dialogueAct = variant.dialogueAct,
            topic = variant.topic,
            groundedFactRefs = variant.groundedFactRefs and Core.copy(variant.groundedFactRefs) or nil,
            uncertainty = variant.uncertainty,
            tone = variant.tone,
            personalityStyle = variant.personalityStyle,
            contentOwner = variant.contentOwner,
            translationArgs = variant.translationArgs and Core.copy(variant.translationArgs) or nil,
        }, selectedIndex
    end

    function Catalog.Select(id, context, salt)
        return evaluate(id, context, salt, false)
    end

    function Catalog.ExplainSelection(id, context, salt)
        -- Never selects, rotates, dispatches actions or persists history.
        return evaluate(id, context, salt, true)
    end

    function Catalog.ResetSelections()
        Catalog.LAST_VARIANTS = {}
        Catalog.LAST_VARIANT_ORDER = {}
        Catalog._lastVariantHead = 1
        Catalog._lastVariantCount = 0
        return true
    end
end
