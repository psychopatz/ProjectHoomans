-- Production selector and optional read-only, explainable trace use the same
-- matching, scoring, hash and anti-repeat code path.
return function(Catalog, Core)
    local function evaluate(id, context, salt, explain)
        local pool = Catalog.Get(id)
        if not pool then return nil, "response_pool_unavailable" end

        local candidates = {}
        local rows = explain and {} or nil
        local bestScore = nil
        for index = 1, #pool.variants do
            local variant = pool.variants[index]
            local matched, specificity, checks = Core.matches(
                variant, context, explain
            )
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
            while #Catalog.LAST_VARIANT_ORDER >= Catalog.MAX_LAST_VARIANTS do
                local oldest = table.remove(Catalog.LAST_VARIANT_ORDER, 1)
                Catalog.LAST_VARIANTS[oldest] = nil
            end
            Catalog.LAST_VARIANT_ORDER[#Catalog.LAST_VARIANT_ORDER + 1] =
                selectionKey
        end
        Catalog.LAST_VARIANTS[selectionKey] = selectedIndex
        local variant = pool.variants[selectedIndex]
        return {
            id = variant.id,
            templateID = variant.templateID,
            fallback = variant.fallback,
            compatibilityFlavorID = variant.compatibilityFlavorID,
            plan = variant.plan,
            dialogueAct = variant.dialogueAct,
            topic = variant.topic,
            groundedFactRefs = Core.copy(variant.groundedFactRefs),
            uncertainty = variant.uncertainty,
            tone = variant.tone,
            personalityStyle = variant.personalityStyle,
            contentOwner = variant.contentOwner,
            translationArgs = Core.copy(variant.translationArgs),
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
        return true
    end
end
