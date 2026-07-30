-- Read-only formatting and opt-in logging for processed social events.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.SocialEventDebug = PNC.SocialEventDebug or {}

local Debug = PNC.SocialEventDebug

local function signed(value)
    return string.format("%+.2f", tonumber(value) or 0)
end

local function debugEnabled()
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugSocialEvents == true
end

function Debug.FormatProcessed(processed, definition)
    local lines = {
        "[PNC SocialEvent]",
        "Event: " .. tostring(processed.eventType),
        "Event ID: " .. tostring(processed.eventID),
        "Actor: " .. tostring(processed.actorKey),
        "Target: " .. tostring(processed.targetKey),
    }
    local memory = definition and definition.targetMemory or {}
    local index
    local detail
    local memoryEntry
    local memoryIndex
    lines[#lines + 1] = "Definition approval: "
        .. signed(memory.approvalEffect)
    lines[#lines + 1] = "Definition respect: "
        .. signed(memory.respectEffect)
    lines[#lines + 1] = "Definition morale: "
        .. signed(memory.moraleEffect)
    lines[#lines + 1] = "Familiarity gain: "
        .. signed(memory.familiarityGain)
    for index = 1, #(processed.details or {}) do
        detail = processed.details[index]
        memoryEntry = nil
        lines[#lines + 1] = "Observer NPC: "
            .. tostring(detail.observerNPCID)
        lines[#lines + 1] = "Memory created: "
            .. tostring(detail.memoryID)
        lines[#lines + 1] = "Cooldown result: allowed"
        lines[#lines + 1] = "Saturation approval: "
            .. signed(detail.saturationBefore.approval)
            .. " -> " .. signed(detail.saturationAfter.approval)
        lines[#lines + 1] = "Saturation respect: "
            .. signed(detail.saturationBefore.respect)
            .. " -> " .. signed(detail.saturationAfter.respect)
        for memoryIndex = 1,
            #(detail.relationshipAfter.memories or {})
        do
            if detail.relationshipAfter.memories[memoryIndex].id
                == detail.memoryID
            then
                memoryEntry =
                    detail.relationshipAfter.memories[memoryIndex]
                break
            end
        end
        if memoryEntry then
            lines[#lines + 1] = "Final memory approval: "
                .. signed(memoryEntry.approvalEffect)
            lines[#lines + 1] = "Final memory respect: "
                .. signed(memoryEntry.respectEffect)
        end
        if detail.modifiedEffects then
            lines[#lines + 1] = "Profile-modified effects: "
                .. signed(detail.modifiedEffects.approvalEffect)
                .. " approval, "
                .. signed(detail.modifiedEffects.respectEffect)
                .. " respect, "
                .. signed(detail.modifiedEffects.moraleEffect)
                .. " morale, "
                .. signed(detail.modifiedEffects.familiarityGain)
                .. " familiarity"
        end
        local modifierNames = {}
        local modifierName
        for modifierName, _ in pairs(
            detail.modifierBreakdown or {}
        ) do
            modifierNames[#modifierNames + 1] = modifierName
        end
        table.sort(modifierNames)
        for _, modifierName in ipairs(modifierNames) do
            lines[#lines + 1] = "Profile modifier "
                .. modifierName .. ": x"
                .. string.format(
                    "%.2f",
                    tonumber(
                        detail.modifierBreakdown[modifierName]
                    ) or 1
                )
        end
        lines[#lines + 1] = "Relationship before: "
            .. signed(detail.relationshipBefore.approval) .. " approval, "
            .. signed(detail.relationshipBefore.respect) .. " respect, "
            .. tostring(detail.relationshipBefore.familiarity)
            .. " familiarity, "
            .. tostring(detail.relationshipBefore.state)
        lines[#lines + 1] = "Relationship after: "
            .. signed(detail.relationshipAfter.approval) .. " approval, "
            .. signed(detail.relationshipAfter.respect) .. " respect, "
            .. tostring(detail.relationshipAfter.familiarity)
            .. " familiarity, "
            .. tostring(detail.relationshipAfter.state)
    end
    return table.concat(lines, "\n")
end

function Debug.LogProcessed(processed, definition)
    local text
    if not debugEnabled() then
        return false
    end
    text = Debug.FormatProcessed(processed, definition)
    if PNC.Core and PNC.Core.LogDebug then
        PNC.Core.LogDebug(text)
    elseif print then
        print(text)
    end
    return true
end

return Debug
