-- Compound semantic-turn submission and receipt aggregation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

function Internal.SubmitCompound(view, value, parts, sourcePart)
    if type(parts) ~= "table" or #parts < 2 then
        return false, "compound_turn_invalid"
    end
    local index
    local part
    local submitted = true
    local reason
    local receipts = {}
    view.lastSemanticCompound = {
        schemaVersion = 1,
        rawText = value,
        parts = receipts,
    }
    for index = 1, #parts do
        part = parts[index]
        submitted, reason = Internal.SubmitSingle(view, part.text, {
            compoundPart = true,
            compoundRoot = value,
            compoundIndex = index,
            compoundCount = #parts,
            sourcePart = sourcePart,
        })
        receipts[index] = {
            index = index,
            text = part.text,
            accepted = submitted == true,
            reason = reason,
            pattern = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.provenance
                and view.lastSemanticDialogueResult.ir.provenance.pattern,
            intent = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.intent,
            subject = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.subject,
            flow = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.decision
                and view.lastSemanticDialogueResult.decision.flow
                and view.lastSemanticDialogueResult.decision.flow.transition,
        }
        if not submitted then return false, reason end
    end
    return true
end
