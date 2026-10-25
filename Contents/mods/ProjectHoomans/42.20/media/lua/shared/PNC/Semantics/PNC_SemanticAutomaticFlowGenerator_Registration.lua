-- Automatic-flow registry and response registration.
-- This is the only extracted seam allowed to mutate runtime registries.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Generator = PNC.Semantics.AutomaticFlowGenerator

local Definitions = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator_Definitions"
local BuildParts = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator_Build"
local build = BuildParts.Build
local copyValue = Definitions.CopyValue
local summaryFor = BuildParts.SummaryFor

local function markGenerated(artifact, registry)
    local generated = {}
    for index = 1, #artifact.flows do
        local definition = artifact.flows[index]
        if registry.Get(definition.id) then
            generated[definition.capabilityID] = definition.id
        end
    end
    for index = 1, #artifact.coverage do
        local row = artifact.coverage[index]
        local flow = generated[row.capabilityID]
        if flow then
            row.classification = "generated"
            row.reason = "registered_generated_flow"
            row.flowID = flow
        end
    end
    artifact.generatedFlowIDs = {}
    for _, flowIDValue in pairs(generated) do
        artifact.generatedFlowIDs[#artifact.generatedFlowIDs + 1] = flowIDValue
    end
    table.sort(artifact.generatedFlowIDs)
    artifact.summary = summaryFor(artifact.coverage)
end

local function register(capabilityCatalog, artifact)
    local registry = PNC.Semantics.DialogueFlowRegistry
        or require "PNC/Semantics/PNC_SemanticDialogueFlowRegistry"
    local responses = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    artifact = type(artifact) == "table" and artifact or build(
        capabilityCatalog
    )
    artifact.regeneratedFlowIDs = {}
    for index = 1, #artifact.responsePools do
        local pool = artifact.responsePools[index]
        local registered = responses.Register(pool.id, pool)
        if registered ~= true then
            error("automatic semantic response registration failed: "
                .. tostring(pool.id))
        end
    end
    for index = 1, #artifact.flows do
        local definition = artifact.flows[index]
        local existing = registry.Get(definition.id)
        local registered
        local reason
        if type(registry.ReplaceGenerated) == "function" then
            registered, reason = registry.ReplaceGenerated(definition)
        elseif not existing then
            registered, reason = registry.Register(definition)
        else
            registered = true
        end
        if not registered then
            error("automatic semantic flow registration failed: "
                .. tostring(definition.id) .. " (" .. tostring(reason) .. ")")
        end
        if existing then
            artifact.regeneratedFlowIDs[#artifact.regeneratedFlowIDs + 1] =
                definition.id
        end
    end
    table.sort(artifact.regeneratedFlowIDs)
    markGenerated(artifact, registry)
    artifact.registryRevision = registry.GetRevision()
    artifact.capabilityCatalogVersion = capabilityCatalog.VERSION
    return copyValue(artifact)
end

local function regenerate(capabilityCatalog)
    local artifact = build(capabilityCatalog)
    return register(capabilityCatalog, artifact)
end

return {
    Register = register,
    Regenerate = regenerate,
}

