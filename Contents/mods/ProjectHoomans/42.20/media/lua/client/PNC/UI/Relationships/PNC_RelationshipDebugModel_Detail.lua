local Model = require "PNC/UI/Relationships/PNC_RelationshipDebugModel_Core"
local Internal = Model.Internal or {}
local row = Internal.row
local number = Internal.number
local signed = Internal.signed
local mapValue = Internal.mapValue
local appendMap = Internal.appendMap
local enabledKeys = Internal.enabledKeys
local appendConduct = Internal.appendConduct

local function appendReverseRows(rows, snapshot)
    reverse = snapshot.reverse
    if reverse then
        rows[#rows + 1] = row("Reverse direction",
            reverse.exists and "stored" or "not stored",
            reverse.exists and "success" or "textMuted")
        rows[#rows + 1] = row(
            "  scores",
            string.format(
                "approval %s / respect %s / familiarity %s",
                number(reverse.approval),
                number(reverse.respect),
                number(reverse.familiarity)
            )
        )
        rows[#rows + 1] = row(
            "  state",
            tostring(reverse.state)
                .. " (revision "
                .. tostring(reverse.revision or 0) .. ")"
        )
    end
    appendMap(rows, "Cooldown", snapshot.cooldowns)
    appendMap(rows, "Saturation", snapshot.saturation)
    appendConduct(rows, "Observer conduct", snapshot.observerConduct)
    appendConduct(rows, "Target conduct", snapshot.targetConduct)
end

local function appendMemoryRows(rows, snapshot)
    rows[#rows + 1] = row(
        "Memories",
        tostring(#(snapshot.memories or {}))
    )
    local approvalContribution = 0
    local respectContribution = 0
    for _, memory in ipairs(snapshot.memories or {}) do
        approvalContribution = approvalContribution
            + (tonumber(memory.approvalEffect) or 0)
                * (tonumber(memory.currentStrength) or 0)
        respectContribution = respectContribution
            + (tonumber(memory.respectEffect) or 0)
                * (tonumber(memory.currentStrength) or 0)
    end
    rows[#rows + 1] = row(
        "  contribution total",
        "approval " .. signed(approvalContribution)
            .. " / respect " .. signed(respectContribution)
    )
    for index, memory in ipairs(snapshot.memories or {}) do
        rows[#rows + 1] = row(
            tostring(index) .. ". " .. tostring(memory.type),
            tostring(memory.id),
            memory.permanent and "success" or "text"
        )
        rows[#rows + 1] = row(
            "  effects",
            signed(memory.approvalEffect) .. " approval / "
                .. signed(memory.respectEffect) .. " respect / "
                .. signed(memory.moraleEffect) .. " morale"
        )
        rows[#rows + 1] = row(
            "  strength",
            number(memory.currentStrength, 4)
                .. " current / " .. number(memory.strength, 4)
                .. " stored; decay " .. number(memory.decayPerDay, 4)
                .. "/day"
        )
        rows[#rows + 1] = row(
            "  source",
            tostring(memory.knowledgeSource)
                .. (memory.permanent and " / permanent" or "")
                .. (memory.shareable and " / shareable" or "")
        )
        rows[#rows + 1] = row(
            "  timestamps",
            number(memory.createdAt, 3) .. " h created / "
                .. number(memory.lastEvaluatedAt, 3)
                .. " h evaluated"
        )
        rows[#rows + 1] = row(
            "  tags",
            enabledKeys(memory.tags)
        )
    end
end

local function appendActionRows(rows, snapshot)
    local action
    local detail
    action = snapshot.actionResult
    if action then
        rows[#rows + 1] = row(
            "Last trigger",
            action.ok == true
                and tostring(action.eventType or "processed")
                or tostring(action.reason or "rejected"),
            action.ok == true and "success" or "warning"
        )
        rows[#rows + 1] = row(
            "  event",
            tostring(action.eventID or "(none)")
        )
        rows[#rows + 1] = row(
            "  changes",
            tostring(action.memoriesCreated or 0)
                .. " memories / "
                .. tostring(action.relationshipsChanged or 0)
                .. " relationships / "
                .. tostring(action.conductEvidenceCreated or 0)
                .. " conduct evidence"
        )
        detail = action.details and action.details[1] or nil
        if detail and detail.baseEffects and detail.modifiedEffects then
            rows[#rows + 1] = row(
                "  approval effect",
                signed(detail.baseEffects.approvalEffect)
                    .. " -> "
                    .. signed(detail.modifiedEffects.approvalEffect)
            )
            rows[#rows + 1] = row(
                "  respect effect",
                signed(detail.baseEffects.respectEffect)
                    .. " -> "
                    .. signed(detail.modifiedEffects.respectEffect)
            )
            rows[#rows + 1] = row(
                "  familiarity",
                signed(detail.baseEffects.familiarityGain)
                    .. " -> "
                    .. signed(detail.modifiedEffects.familiarityGain)
            )
            appendMap(
                rows,
                "  modifier",
                detail.modifierBreakdown
            )
        end
    end
end


Internal.appendReverseRows = appendReverseRows
Internal.appendMemoryRows = appendMemoryRows
Internal.appendActionRows = appendActionRows

return Model
