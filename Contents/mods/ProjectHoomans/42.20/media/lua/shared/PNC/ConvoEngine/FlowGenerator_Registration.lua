-- Automatic-flow registry and response registration.
-- This is the only extracted seam allowed to mutate runtime registries.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Generator = PNC.ConvoEngine.AutomaticFlowGenerator

local Definitions = require
    "PNC/ConvoEngine/FlowGenerator_Definitions"
local BuildParts = require
    "PNC/ConvoEngine/FlowGenerator_Build"
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

local function collectPoolContext(artifact)
    local lookup = {}
    local metaMap = type(artifact.responsePoolMetadata) == "table"
        and artifact.responsePoolMetadata or {}
    for poolID, meta in pairs(metaMap) do
        if type(meta) == "table" then
            lookup[tostring(poolID)] = meta
        end
    end
    local capToAction = {}
    for _, row in ipairs(artifact.coverage or {}) do
        if type(row) == "table" and row.capabilityID and row.id then
            capToAction[tostring(row.capabilityID)] = tostring(row.id)
        end
    end
    for _, flow in ipairs(artifact.flows or {}) do
        if type(flow) == "table" then
            local capID = flow.capabilityID
            local actionID = flow.action or (capID and capToAction[tostring(capID)])
            for _, node in pairs(flow.nodes or {}) do
                if type(node) == "table" and type(node.responsePool) == "string" then
                    local key = node.responsePool
                    lookup[key] = lookup[key] or {}
                    lookup[key].capabilityID = lookup[key].capabilityID or capID
                    lookup[key].action = lookup[key].action or actionID
                end
            end
        end
    end
    for _, pool in ipairs(artifact.responsePools or {}) do
        if type(pool) == "table" and type(pool.id) == "string" then
            local key = pool.id
            lookup[key] = lookup[key] or {}
            lookup[key].capabilityID = lookup[key].capabilityID
                or pool.capabilityID
            lookup[key].action = lookup[key].action or pool.action
        end
    end
    return lookup
end

local function formatPoolError(poolID, reason, meta, detail)
    local capability = (meta and meta.capabilityID) or "unknown"
    local action = (meta and meta.action) or "unknown"
    local template = (detail and detail.templateID) or "none"
    local realization = (detail and detail.realizationID) or "none"
    return "automatic semantic response registration failed: pool="
        .. tostring(poolID or "unknown")
        .. " reason=" .. tostring(reason or "unknown")
        .. " capability=" .. tostring(capability)
        .. " action=" .. tostring(action)
        .. " template=" .. tostring(template)
        .. " realization=" .. tostring(realization)
end

local function preflightArtifact(artifact, responses, poolContext)
    poolContext = poolContext or collectPoolContext(artifact)
    local preflightedPools = {}
    local maxPools = tonumber(responses.MAX_POOLS)
    local existingCount = tonumber(responses.POOL_COUNT) or 0
    local newDistinctCount = 0
    for index = 1, #(artifact.responsePools or {}) do
        local pool = artifact.responsePools[index]
        local poolID = type(pool) == "table" and tostring(pool.id or "") or ""
        local meta = poolContext[poolID] or (type(pool) == "table" and {
            capabilityID = pool.capabilityID,
            action = pool.action,
        }) or nil
        local ok, info = responses.Preflight(poolID, pool, {
            strictVariants = true,
        })
        if not ok then
            local detail = type(info) == "table" and info or { reason = info }
            return false, formatPoolError(poolID, detail.reason, meta, detail)
        end
        if not preflightedPools[poolID] and info.isNewPool then
            newDistinctCount = newDistinctCount + 1
            if maxPools and maxPools > 0 and (existingCount + newDistinctCount) > maxPools then
                return false, formatPoolError(poolID, "response_pool_limit", meta)
            end
        end
        preflightedPools[poolID] = true
    end
    for index = 1, #(artifact.flows or {}) do
        local definition = artifact.flows[index]
        if type(definition) ~= "table" or tostring(definition.id or "") == ""
            or type(definition.nodes) ~= "table"
        then
            return false, "automatic semantic flow preflight failed: invalid_flow_definition"
        end
        for _, node in pairs(definition.nodes) do
            if type(node) == "table" and node.responsePool ~= nil then
                local poolID = tostring(node.responsePool)
                if not preflightedPools[poolID] and not responses.Get(poolID) then
                    local meta = poolContext[poolID]
                    return false, formatPoolError(
                        poolID, "flow_references_unregistered_pool", meta
                    )
                end
            end
        end
    end
    return true
end

local function register(capabilityCatalog, artifact)
    local registry = PNC.ConvoEngine.DialogueFlowRegistry
        or require "PNC/ConvoEngine/Dialogue/FlowRegistry"
    local responses = PNC.ConvoEngine.ResponseCatalog
        or require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
    artifact = type(artifact) == "table" and artifact or build(
        capabilityCatalog
    )
    local poolContext = collectPoolContext(artifact)
    local preflightOk, preflightError = preflightArtifact(artifact, responses, poolContext)
    if not preflightOk then
        error(preflightError)
    end
    artifact.regeneratedFlowIDs = {}
    for index = 1, #artifact.responsePools do
        local pool = artifact.responsePools[index]
        local registered, reasonOrPool = responses.Register(pool.id, pool)
        if registered ~= true then
            local meta = poolContext[tostring(pool and pool.id or "")]
            error(formatPoolError(pool and pool.id, reasonOrPool, meta))
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

