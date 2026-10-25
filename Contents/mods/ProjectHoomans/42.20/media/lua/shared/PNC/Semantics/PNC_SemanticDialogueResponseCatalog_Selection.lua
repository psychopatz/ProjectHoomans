-- Deterministic response selection and bounded selection history.

return function(Catalog, Core)
    function Catalog.Select(id, context, salt)
        local pool = Catalog.Get(id)
        local candidates = {}
        local bestScore = nil
        local index
        local variant
        local matched
        local specificity
        local score
        local selectionKey
        local selectedIndex
        if not pool then return nil, "response_pool_unavailable" end
        for index = 1, #pool.variants do
            variant = pool.variants[index]
            matched, specificity = Core.matches(variant, context)
            if matched then
                score = (tonumber(variant.priority) or 0) * 100
                    + specificity
                if bestScore == nil or score > bestScore then
                    bestScore = score
                    candidates = { index }
                elseif score == bestScore then
                    candidates[#candidates + 1] = index
                end
            end
        end
        if #candidates == 0 then
            return nil, "response_variant_unavailable"
        end
        selectionKey = tostring(id) .. ":"
            .. tostring(context and context.npcID or "")
        selectedIndex = candidates[
            (Core.hash(tostring(salt or "") .. ":" .. selectionKey)
                % #candidates) + 1
        ]
        if #candidates > 1
            and Catalog.LAST_VARIANTS[selectionKey] == selectedIndex
        then
            -- Rotate relative to the previously selected candidate. Hashing a
            -- second time is not sufficient: it can produce the same index
            -- again for the same salt and make a response pool repetitive.
            local previousPosition = nil
            local candidatePosition
            for candidatePosition = 1, #candidates do
                if candidates[candidatePosition] == selectedIndex then
                    previousPosition = candidatePosition
                    break
                end
            end
            if previousPosition then
                selectedIndex = candidates[
                    (previousPosition % #candidates) + 1
                ]
            end
        end
        if Catalog.LAST_VARIANTS[selectionKey] == nil then
            while #Catalog.LAST_VARIANT_ORDER >= Catalog.MAX_LAST_VARIANTS do
                local oldest = table.remove(Catalog.LAST_VARIANT_ORDER, 1)
                Catalog.LAST_VARIANTS[oldest] = nil
            end
            Catalog.LAST_VARIANT_ORDER[#Catalog.LAST_VARIANT_ORDER + 1] =
                selectionKey
        end
        Catalog.LAST_VARIANTS[selectionKey] = selectedIndex
        variant = pool.variants[selectedIndex]
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
            translationArgs = Core.copy(variant.translationArgs),
        }, selectedIndex
    end

    function Catalog.ResetSelections()
        Catalog.LAST_VARIANTS = {}
        Catalog.LAST_VARIANT_ORDER = {}
        return true
    end
end
