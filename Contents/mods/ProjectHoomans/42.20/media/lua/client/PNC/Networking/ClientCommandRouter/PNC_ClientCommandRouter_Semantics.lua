-- Client receivers for shared semantic projections.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Cognition = PNC.Semantics and PNC.Semantics.CognitionClient
    or require "PNC/Semantics/PNC_SemanticCognitionClient"

local function recordCampResult(args)
    local debug
    local diagnostics
    args = type(args) == "table" and args or {}
    if string.upper(tostring(args.action or "")) ~= "CAMP" then return end
    debug = PNC.PerceptionDebug
    diagnostics = debug and debug.CampDiagnostics or nil
    if not diagnostics or type(diagnostics.RecordServer) ~= "function" then
        pcall(require,
            "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics")
        debug = PNC.PerceptionDebug
        diagnostics = debug and debug.CampDiagnostics or nil
    end
    if diagnostics and type(diagnostics.RecordServer) == "function" then
        diagnostics.RecordServer(args)
    end
end

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_COGNITION, function(args)
    Cognition.ApplyPayload(args or {})
end)

if Const.CMD_SEMANTIC_TASK_RESULT then
    Internal.RegisterServerCommand(Const.CMD_SEMANTIC_TASK_RESULT,
        function(args)
            recordCampResult(args)
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
