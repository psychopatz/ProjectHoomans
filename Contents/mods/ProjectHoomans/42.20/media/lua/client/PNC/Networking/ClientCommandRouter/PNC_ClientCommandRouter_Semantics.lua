-- Client receivers for shared semantic projections.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Cognition = PNC.Semantics and PNC.Semantics.CognitionClient
    or require "PNC/Semantics/PNC_SemanticCognitionClient"

local function recordCampResult(args)
    local perceptionDebug
    local diagnostics
    args = type(args) == "table" and args or {}
    if string.upper(tostring(args.action or "")) ~= "CAMP" then return end
    perceptionDebug = PNC.PerceptionDebug
    diagnostics = perceptionDebug and perceptionDebug.CampDiagnostics or nil
    if not diagnostics or type(diagnostics.RecordServer) ~= "function" then
        pcall(require,
            "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics")
        perceptionDebug = PNC.PerceptionDebug
        diagnostics = perceptionDebug
            and perceptionDebug.CampDiagnostics or nil
    end
    if diagnostics and type(diagnostics.RecordServer) == "function" then
        diagnostics.RecordServer(args)
    end
end

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_COGNITION, function(args)
    Cognition.ApplyPayload(args or {})
end)

if Const.CMD_SEMANTIC_SCENE_SPEECH then
    Internal.RegisterServerCommand(
        Const.CMD_SEMANTIC_SCENE_SPEECH,
        function(args)
            local presentation = PNC.Semantics
                and PNC.Semantics.InteractionScenePresentation or nil
            if type(presentation) ~= "table"
                or type(presentation.Receive) ~= "function"
            then
                presentation = require
                    "PNC/Conversation/PNC_SemanticInteractionScenePresentation"
            end
            if presentation and type(presentation.Receive) == "function" then
                presentation.Receive(args or {})
            end
        end
    )
end

if Const.CMD_COMBAT_ENCOUNTER_INTENT_STATE then
    Internal.RegisterServerCommand(
        Const.CMD_COMBAT_ENCOUNTER_INTENT_STATE,
        function(args)
            local surface = PNC.Semantics
                and PNC.Semantics.CombatResponseSurface or nil
            if type(surface) ~= "table" then
                local ok, loaded = pcall(
                    require,
                    "PNC/Semantics/PNC_SemanticCombatResponseSurface"
                )
                surface = ok and loaded or nil
            end
            if surface and type(surface.ApplyAuthorityState) == "function" then
                surface.ApplyAuthorityState(args or {})
            end
        end
    )
end

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

if Const.CMD_SEMANTIC_QUEST_RESULT then
    Internal.RegisterServerCommand(Const.CMD_SEMANTIC_QUEST_RESULT,
        function(args)
            local input = PNC.Semantics
                and PNC.Semantics.DialogueInput
            if input and type(input.ReceiveSemanticQuestResult)
                == "function"
            then
                input.ReceiveSemanticQuestResult(args or {})
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
