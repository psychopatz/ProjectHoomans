-- Choice presentation and authored-choice normalization for a session.

local Choices = {}

function Choices.setPresentedChoices(self, choices, metadata)
    self.choices = choices or {}
    metadata = type(metadata) == "table" and metadata or {}
    self.choicePresentationState = {
        source = metadata.source or "session",
        revision = metadata.revision,
        authoredCount = metadata.authoredCount,
        presentedCount = #self.choices,
        busy = self.busy == true,
        pending = self.pendingChoices ~= nil,
        presentationError = metadata.presentationError,
    }
    return true
end

function Choices.clearChoices(self, reason)
    return self:setPresentedChoices({}, { source = reason or "clear" })
end

function Choices.setChoices(self, choices)
    local authored = choices or {}
    local output = {}
    for index, choice in ipairs(authored) do
        local text = choice.text
        if text == nil and choice.textKey then
            text = {
                key = choice.textKey,
                domain = choice.textDomain,
                args = choice.textArgs,
            }
        end
        output[#output + 1] = {
            id = choice.id or tostring(index),
            text = text,
            response = choice.response,
            next = choice.next,
            close = choice.close,
            closeReason = choice.closeReason,
            action = choice.action or choice.onSelect,
            log = choice.log ~= false,
            enabled = choice.enabled ~= false,
            tooltip = choice.tooltip,
            source = choice,
        }
    end
    local presenter = self.view and self.view.spec
        and self.view.spec.choicePresentation or nil
    local presentedByCallback = false
    local presentationError
    if type(presenter) == "function" then
        local ok, presented = pcall(
            presenter, self.view, output, authored, self
        )
        if ok and type(presented) == "table" then
            output = presented
            presentedByCallback = true
        elseif not ok then
            presentationError = tostring(presented)
        end
    end
    return self:setPresentedChoices(output, {
        source = presentationError and "authored_fallback"
            or presentedByCallback and "choice_presentation"
            or "session",
        authoredCount = #output,
        presentationError = presentationError,
    })
end

return Choices

