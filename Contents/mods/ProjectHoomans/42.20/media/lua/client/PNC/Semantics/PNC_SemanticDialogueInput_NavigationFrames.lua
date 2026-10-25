-- Navigation-frame projection validation and application.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local Suggestions = Internal.Suggestions

local function navigationFrameMatchesProjection(view, frame)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then
        return false, "semantic_suggestions_unavailable"
    end
    local currentGroupID = tostring(projection.currentGroupID or "")
    if Suggestions.IsBackFrame(frame) then
        if currentGroupID ~= tostring(frame.fromGroupID or "") then
            return false, "stale_suggestion"
        end
    elseif Suggestions.IsGroupFrame(frame) then
        local parentGroupID = tostring(
            frame.parentGroupID or Suggestions.ROOT_GROUP_ID
        )
        if currentGroupID ~= parentGroupID then
            return false, "stale_suggestion"
        end
    end
    return true, "navigation_frame_current"
end
Internal.NavigationFrameMatchesProjection = navigationFrameMatchesProjection

local function navigationFrameAtCurrentRevision(view, frame)
    local router = Internal.RouterFor(view)
    local output = {}
    for key, value in pairs(frame or {}) do
        output[key] = value
    end
    output.requestRevision = router
        and router.state and tonumber(router.state.sequence)
        or output.requestRevision
    return output
end
Internal.NavigationFrameAtCurrentRevision = navigationFrameAtCurrentRevision

local function applyNavigationProjection(view, frame)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) == "table"
        and tostring(projection.currentGroupID or "")
            == tostring(frame.groupID or "")
    then
        return true, "already_projected"
    end
    local currentFrame = navigationFrameAtCurrentRevision(view, frame)
    -- The navigation utterance has just advanced the semantic router. The
    -- old projection still carries the pre-turn revision, so selecting the
    -- group directly would reject an otherwise valid native click as stale.
    -- Rebuild the same bounded projection at the new revision and requested
    -- group; this is presentation state only and does not execute gameplay.
    if type(projection) == "table"
        and tonumber(projection.revision)
            ~= tonumber(currentFrame.requestRevision)
        and type(Internal.ShallowContext) == "function"
        and type(Suggestions.Build) == "function"
    then
        local context = Internal.ShallowContext(view) or {}
        context.activeSuggestionGroupID = frame.groupID
        context.semanticSuggestionGroupID = frame.groupID
        local rebuilt = Suggestions.Build({
            accepted = false,
            sequence = tonumber(currentFrame.requestRevision) or 0,
            state = {
                sequence = tonumber(currentFrame.requestRevision) or 0,
            },
            ir = {},
            decision = {},
        }, context, nil)
        if type(rebuilt) ~= "table" then
            return false, "semantic_navigation_projection_failed"
        end
        view.semanticSuggestions = rebuilt
        view.semanticSuggestionRevision = rebuilt.revision
        if view.session then
            view.session.semanticSuggestionGroupID = frame.groupID
        end
        if view.spec and view.spec.context then
            view.spec.context.semanticSuggestionGroupID = frame.groupID
        end
        projection = rebuilt
    end
    if Suggestions.IsBackFrame(currentFrame) then
        return Internal.SelectSemanticRoot(
            view,
            currentFrame,
            { skipPlayerReply = true }
        )
    end
    return Internal.SelectSemanticGroup(view, currentFrame)
end
Internal.ApplyNavigationProjection = applyNavigationProjection
