-- Client receivers for shared semantic projections.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Cognition = PNC.Semantics and PNC.Semantics.CognitionClient
    or require "PNC/Semantics/PNC_SemanticCognitionClient"

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_COGNITION, function(args)
    Cognition.ApplyPayload(args or {})
end)

if Const.CMD_SEMANTIC_TASK_RESULT then
    Internal.RegisterServerCommand(Const.CMD_SEMANTIC_TASK_RESULT,
        function(args)
            local input = PNC.Semantics
                and PNC.Semantics.DialogueInput
            if input and type(input.ReceiveSemanticTaskResult)
                == "function"
            then
                input.ReceiveSemanticTaskResult(args or {})
            end
        end)
end

Internal.RegisterServerCommand(
    Const.CMD_SEMANTIC_INVENTORY_QUERY_RESULT,
    function(args)
        local input = PNC.Semantics and PNC.Semantics.DialogueInput
        if input and type(input.ReceiveInventoryQueryResult) == "function" then
            input.ReceiveInventoryQueryResult(args or {})
        end
    end
)
