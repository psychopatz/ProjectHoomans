local Adapter = {}

function Adapter.New(SemanticExecution, context, callbacks)
    if type(SemanticExecution) ~= "table"
        or type(SemanticExecution.new) ~= "function"
    then
        return nil, "core_execution_contract_required"
    end
    return SemanticExecution.new({
        providerID = "ProjectHoomans",
        materializationMode = context.materializationMode or "physical",
        capabilities = {
            "semantic.conversation",
            "semantic.identity",
            "semantic.interaction",
            "semantic.suggestions",
            "world.discovery",
            "world.radio",
        },
        context = context,
        callbacks = callbacks,
    })
end

return Adapter
