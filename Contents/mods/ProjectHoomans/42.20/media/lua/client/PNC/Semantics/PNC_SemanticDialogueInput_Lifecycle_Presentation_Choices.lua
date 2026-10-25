-- Native Core choice-row construction and semantic presentation application.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

local Suggestions = Internal.Suggestions
local suggestionText = Internal.suggestionText
local suggestionTooltip = Internal.suggestionTooltip
local restoreSemanticChoices = Internal.restoreSemanticChoices
local recordSemanticChoiceClick = Internal.recordSemanticChoiceClick
local authoredRootChoice = Internal.authoredRootChoice
local preserveAuthoredValue = Internal.preserveAuthoredValue

-- Build rows for Core's native choice list. This is a data adapter only: Core
-- still owns layout, scrolling, hover, click gating, and session ordering; the
-- canonical semantic input path owns the click frame. Authored choices are
-- retained only as the current runtime normalization, never as persistence.
local function buildCoreChoices(view, projection, authoredChoices)
    projection = type(projection) == "table" and projection or {}
    local selectedGroup
    local requestedGroup = projection.currentGroupID
    for _, group in ipairs(projection.groups or {}) do
        if group.id == requestedGroup then
            selectedGroup = group
            break
        end
    end
    if not selectedGroup and #(projection.groups or {}) > 0 then
        selectedGroup = projection.groups[1]
    end

    local rows = {}
    local function append(row, enabled)
        local frame = row and row.frame or nil
        if type(frame) ~= "table" then return end
        local authoredChoice = authoredRootChoice(authoredChoices, frame)
        local rowEnabled = enabled == true
            and (not authoredChoice or authoredChoice.enabled ~= false)
        local semanticSource = {
            semanticFrame = frame,
            source = row.source,
            groupID = selectedGroup and selectedGroup.id
                or row.groupID,
        }
        rows[#rows + 1] = {
            id = row.id or row.action or ("semantic:" .. tostring(#rows + 1)),
            text = suggestionText(row),
            enabled = rowEnabled,
            tooltip = authoredChoice and authoredChoice.tooltip
                or suggestionTooltip(row),
            -- Root rows preserve Core's normalized authored behavior. Other
            -- semantic rows remain typed semantic adapters and do not create
            -- a second authored player turn.
            log = authoredChoice and authoredChoice.log ~= false or false,
            response = authoredChoice
                and preserveAuthoredValue(authoredChoice.response, authoredChoice)
                or nil,
            next = authoredChoice
                and preserveAuthoredValue(authoredChoice.next, authoredChoice)
                or nil,
            close = authoredChoice
                and preserveAuthoredValue(authoredChoice.close, authoredChoice)
                or nil,
            closeReason = authoredChoice
                and preserveAuthoredValue(
                    authoredChoice.closeReason, authoredChoice
                ) or nil,
            onHighlightChanged = authoredChoice
                and type(authoredChoice.onHighlightChanged) == "function"
                and function(_, highlighted)
                    return authoredChoice.onHighlightChanged(
                        authoredChoice, highlighted
                    )
                end or nil,
            source = semanticSource,
            action = function()
                local input = PNC.Semantics
                    and PNC.Semantics.DialogueInput or nil
                if not input or type(input.SubmitSemanticFrame)
                    ~= "function"
                then
                    view.lastSemanticSuggestionReason =
                        "semantic_input_unavailable"
                    view.lastSemanticSuggestionFailure = {
                        candidateID = frame.candidateID,
                        requestRevision = frame.requestRevision,
                        reason = "semantic_input_unavailable",
                    }
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.rejected",
                        "semantic_input_unavailable"
                    )
                    return false
                end
                local previousCoreFrame = view.semanticCoreChoiceFrame
                view.semanticCoreChoiceFrame = frame
                local accepted, reason = input.SubmitSemanticFrame(
                    view,
                    frame,
                    authoredChoice and {
                        coreAuthoredChoice = true,
                        authoredChoice = authoredChoice,
                    } or nil
                )
                view.semanticCoreChoiceFrame = previousCoreFrame
                view.lastSemanticSuggestionReason = reason
                if accepted ~= true then
                    view.lastSemanticSuggestionFailure = {
                        candidateID = frame.candidateID,
                        frameKind = frame.kind,
                        requestRevision = frame.requestRevision,
                        reason = reason,
                        currentNodeID = view.session
                            and view.session.currentNodeID,
                    }
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.rejected", reason
                    )
                    -- Core clears the presented row before invoking its
                    -- action. A stale, busy, or rejected semantic frame must
                    -- therefore restore the production choice surface so a
                    -- native click cannot leave the conversation blank.
                    restoreSemanticChoices(view)
                else
                    view.lastSemanticSuggestionFailure = nil
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.accepted", "accepted"
                    )
                end
                return accepted
            end,
        }
    end

    local rootGroupID = projection.rootGroupID
    local navigation = selectedGroup and selectedGroup.navigation or {}
    if #navigation == 0
        and selectedGroup
        and rootGroupID
        and selectedGroup.id ~= rootGroupID
        and projection.allowBack ~= false
        and selectedGroup.allowBack ~= false
        and Suggestions.BuildBackFrame
    then
        -- Compatibility for projections produced before shared navigation was
        -- added. New projections carry this row in group.navigation.
        local frame = Suggestions.BuildBackFrame(
            projection.revision,
            selectedGroup.id,
            Internal.ShallowContext(view)
        )
        if frame then
            navigation = {{
                id = frame.candidateID,
                frame = frame,
                display = {
                    label = frame.labelFallback,
                    labelFallback = frame.labelFallback,
                },
                source = {
                    kind = "semantic_back_navigation",
                    revision = projection.revision,
                    fromGroupID = selectedGroup.id,
                },
            }}
        end
    end
    for _, row in ipairs(navigation) do
        append(row, true)
    end

    local candidates = selectedGroup and selectedGroup.candidates
        or projection.candidates or {}
    for _, candidate in ipairs(candidates) do
        append(candidate, candidate.enabled ~= false)
    end
    local capabilities = selectedGroup and selectedGroup.capabilities
        or projection.permittedCapabilities or {}
    for _, capability in ipairs(capabilities) do
        append(capability,
            (capability.status == "eligible"
                or capability.status == "selected_for_preflight")
                and capability.enabled ~= false)
    end
    -- Owned companion actions are real landing actions, not a topic browser.
    -- Keep them beside the landing choices while leaving unrelated groups
    -- behind the explicit context index.
    if selectedGroup and selectedGroup.id == rootGroupID then
        for _, group in ipairs(projection.groups or {}) do
            if group.id == "owned_actions" then
                for _, capability in ipairs(group.capabilities or {}) do
                    append(capability,
                        (capability.status == "eligible"
                            or capability.status == "selected_for_preflight")
                            and capability.enabled ~= false)
                end
                break
            end
        end
    end
    if view then view.semanticSuggestionRows = rows end
    return rows
end

-- This callback is installed in the Core conversation definition. Core calls
-- it after every authored choice normalization, including pending-response
-- completion and in-place spec refresh. Returning nil preserves Core's
-- normalized authored choices as the safe fallback.
local function presentSemanticChoices(view, authoredChoices)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then return nil end
    if view then view.semanticAuthoredChoices = authoredChoices end
    if view and view.session and view.session.busy == true then
        -- Do not replace Core's authored/pending surface while the opening or
        -- a response is still being delivered. Core rejects clicks in this
        -- state, so exposing semantic rows here creates dead buttons.
        view.semanticPresentationPending = projection
        return nil
    end
    local rows = buildCoreChoices(
        view, projection, view and view.semanticAuthoredChoices
    )
    if #rows > 0 then
        view.semanticPresentationPending = nil
        return rows
    end
    return nil
end

local function applyCoreChoices(view, projection, authoredChoices)
    local session = view and view.session or nil
    if not session or type(session.setPresentedChoices) ~= "function" then
        return false, "core_choices_unavailable"
    end
    authoredChoices = authoredChoices
        or view and view.semanticAuthoredChoices
    local rows = buildCoreChoices(view, projection, authoredChoices)
    if session.busy == true then
        -- Session:finishPending will call setChoices after the queued NPC
        -- response, at which point the presentation callback will apply the
        -- same production projection with an interactive Core session.
        view.semanticPresentationPending = projection
        return false, "semantic_choices_deferred"
    end
    if #rows < 1 then
        -- A projection can legitimately be empty while a dependency or
        -- current topic is unavailable. Restore the authored Core choices
        -- when the session is idle; never expose stale choices during a
        -- queued response.
        if session.busy == true then
            -- Session:finishPending will call Core's normal setChoices after
            -- the queued reply; its presentation callback then supplies the
            -- projection or the authored fallback.
            view.semanticPresentationPending = projection
            return false, "semantic_choices_deferred"
        end
        if projection
            and tostring(projection.currentGroupID or "")
                == tostring(projection.rootGroupID or "")
        then
            -- Back is still a valid presentation transition when the
            -- landing group has no currently eligible rows. Keep the
            -- production surface empty rather than rejecting the navigation
            -- frame as if the root itself were stale.
            view.semanticPresentationPending = nil
            session:setPresentedChoices({}, {
                source = "semantic_suggestions_empty",
                revision = projection.revision,
                presentedCount = 0,
            })
            return true, rows
        end
        local node = session.currentNode or {}
        if type(session.setChoices) == "function" then
            session:setChoices(node.choices or {})
        end
        return false, "semantic_choices_empty"
    end
    view.semanticPresentationPending = nil
    local applied = session:setPresentedChoices(rows, {
        source = "semantic_suggestions",
        revision = projection and projection.revision,
        presentedCount = #rows,
    })
    return applied == true, rows
end

Internal.PresentSemanticChoices = presentSemanticChoices
Internal.ApplySemanticChoices = applyCoreChoices
Internal.buildCoreChoices = buildCoreChoices
Internal.presentSemanticChoices = presentSemanticChoices
Internal.applyCoreChoices = applyCoreChoices

return Internal

