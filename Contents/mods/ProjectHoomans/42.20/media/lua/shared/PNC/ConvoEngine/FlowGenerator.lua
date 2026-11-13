-- Deterministic metadata-driven production-flow generation.
--
-- This module only turns registered capability metadata into validated flow
-- data. It never parses text and never dispatches a gameplay command. The
-- existing DialogueInput action boundary remains the sole dispatcher.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Generator = PNC.ConvoEngine.AutomaticFlowGenerator or {}
PNC.ConvoEngine.AutomaticFlowGenerator = Generator

Generator.VERSION = 1
Generator.TEMPLATE_VERSION = 1
Generator.TEMPLATE_FINGERPRINT =
    "simple_command:v1:context_gate:typed_binding:one_dispatch:result_map"
Generator.WORKFLOW_KIND = "simple_command"

local BuildParts = require
    "PNC/ConvoEngine/FlowGenerator_Build"
local Registration = require
    "PNC/ConvoEngine/FlowGenerator_Registration"

function Generator.Build(capabilityCatalog)
    return BuildParts.Build(capabilityCatalog)
end

function Generator.Register(capabilityCatalog, artifact)
    return Registration.Register(capabilityCatalog, artifact)
end

function Generator.Regenerate(capabilityCatalog)
    return Registration.Regenerate(capabilityCatalog)
end

return Generator

