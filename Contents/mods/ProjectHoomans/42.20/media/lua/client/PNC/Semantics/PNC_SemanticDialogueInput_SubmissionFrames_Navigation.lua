-- Navigation and suggestion-group semantic frame routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local Suggestions = Internal.Suggestions

local function submitNavigationFrame(view, frame)
    if not Suggestions.IsNavigationFrame
        or not Suggestions.IsNavigationFrame(frame)
    then
        return false
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    local current, currentReason = Internal.NavigationFrameMatchesProjection(
        view, frame
    )
    if not current then return true, false, currentReason end
    local value = Suggestions.ResolveFrameText(frame)
    if value == "" then return true, false, "navigation_frame_text_missing" end

    local group = view and view.groupConversation
    local accepted
    local submitReason
    if group
        and type(group.SubmitSemanticNavigationFrame) == "function"
    then
        accepted, submitReason = group:SubmitSemanticNavigationFrame(
            frame, value
        )
    else
        accepted, submitReason = Internal.SubmitSingle(
            view,
            value,
            { semanticFrame = frame, navigationFrame = true }
        )
    end
    if accepted ~= true then
        return true, false, submitReason or "navigation_frame_rejected"
    end

    local projected, projectionReason = Internal.ApplyNavigationProjection(
        view, frame
    )
    if projected ~= true then
        return true, false, projectionReason or "navigation_projection_failed"
    end
    Internal.FinishDirectFrame(view, receiptOrReason)
    return true, true, "accepted"
end

local function submitBackFrame(view, frame)
    if not Suggestions.IsBackFrame or not Suggestions.IsBackFrame(frame) then
        return false
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    if type(Internal.SelectSemanticRoot) ~= "function" then
        return true, false, "semantic_root_unavailable"
    end
    local accepted, rootReason = Internal.SelectSemanticRoot(view, frame)
    if accepted == true then
        Internal.FinishDirectFrame(view, receiptOrReason)
    end
    return true, accepted, rootReason
end

local function submitShortcutFrame(view, frame)
    if not Suggestions.IsShortcutFrame
        or not Suggestions.IsShortcutFrame(frame)
    then
        return false
    end
    local allowed, receiptOrReason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, receiptOrReason end
    local value = Suggestions.ResolveFrameText(frame)
    if value == "" then return true, false, "suggestion_frame_unavailable" end
    -- Keep the canonical shortcut frame attached to the submission. A native
    -- group host must not reparse the display label and change its route.
    local accepted, submitReason = Input.Submit(view, value, {
        semanticFrame = frame,
        semanticShortcut = true,
    })
    if accepted == true then
        Internal.FinishDirectFrame(view, receiptOrReason)
    end
    return true, accepted, accepted == true and "accepted"
        or submitReason or "semantic_shortcut_rejected"
end

local function submitGroupFrame(view, frame)
    if not Suggestions.IsGroupFrame or not Suggestions.IsGroupFrame(frame) then
        return false
    end
    local allowed, reason = Internal.BeginDirectFrame(view, frame)
    if not allowed then return true, false, reason end
    if type(Internal.SelectSemanticGroup) ~= "function" then
        return true, false, "semantic_group_unavailable"
    end
    local accepted, groupReason = Internal.SelectSemanticGroup(view, frame)
    if accepted == true then Internal.FinishDirectFrame(view, reason) end
    return true, accepted, groupReason
end

function Internal.SubmitNavigationFrame(view, frame)
    local handled, accepted, reason = submitNavigationFrame(view, frame)
    if handled then return handled, accepted, reason end
    handled, accepted, reason = submitBackFrame(view, frame)
    if handled then return handled, accepted, reason end
    handled, accepted, reason = submitShortcutFrame(view, frame)
    if handled then return handled, accepted, reason end
    handled, accepted, reason = submitGroupFrame(view, frame)
    if handled then return handled, accepted, reason end
    return false
end

return Input
