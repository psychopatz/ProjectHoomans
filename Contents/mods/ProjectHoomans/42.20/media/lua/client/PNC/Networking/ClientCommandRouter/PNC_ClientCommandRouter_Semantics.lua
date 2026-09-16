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
