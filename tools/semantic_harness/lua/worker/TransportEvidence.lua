-- CQS evidence classification only: never suppress or replay transport.
local Evidence = {}

function Evidence.partition(transport)
    local dispatches = {}
    local facts = {}
    local factCommand = PNC and PNC.Const
        and PNC.Const.CMD_SEMANTIC_INTERACTION_LIFECYCLE
        or "SemanticInteractionLifecycle"
    for _, event in ipairs(transport or {}) do
        -- Unknown commands remain in dispatch evidence (fail closed). This
        -- exception is the explicit accepted-interaction fact protocol only.
        if type(event) == "table" and event.command == factCommand then
            facts[#facts + 1] = event
        else
            dispatches[#dispatches + 1] = event
        end
    end
    return dispatches, facts
end

function Evidence.annotate(record)
    record.dispatchTransport, record.factTransport =
        Evidence.partition(record.transport)
    return record
end

return Evidence
