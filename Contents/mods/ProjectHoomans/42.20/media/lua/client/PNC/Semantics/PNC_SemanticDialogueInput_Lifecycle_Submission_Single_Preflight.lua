-- Single semantic-turn submission preflight.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

function Internal.PrepareSingleSubmission(view, value, part)
    if not view or not view.session then
        return nil, "conversation_unavailable"
    end
    if view.session.llmPending
        or view.session.semanticDialoguePending
    then
        return nil, "conversation_busy"
    end
    if not (type(part) == "table" and part.compoundPart == true) then
        view.lastSemanticCompound = nil
    end

    local semanticFrame = type(part) == "table"
        and part.semanticFrame or nil
    local semanticTransientSurface = type(part) == "table"
        and part.semanticTransientSurface == true
    -- Keep the submitting host available to asynchronous local projections.
    -- Full-screen conversations are discoverable through Core's singleton,
    -- while compact/headless conversations are deliberately not global.  The
    -- reference is runtime-only and is never serialized or sent over the
    -- network.
    Input.ActiveView = view
    view.lastSemanticActionResult = nil
    if not Internal.Interactive(view) then return nil, "conversation_busy" end

    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil, "empty_message" end
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)

    local compoundPart = type(part) == "table"
        and part.compoundPart == true
    if not semanticFrame
        and not compoundPart
        and type(Internal.ParseTurn) == "function"
    then
        local turn = Internal.ParseTurn(value, nil, view)
        if type(turn) == "table" and turn.compound == true then
            return {
                value = value,
                part = part,
                semanticFrame = semanticFrame,
                semanticTransientSurface = semanticTransientSurface,
                compoundParts = turn.parts,
            }
        end
    end

    return {
        value = value,
        part = part,
        semanticFrame = semanticFrame,
        semanticTransientSurface = semanticTransientSurface,
    }
end

return Input
