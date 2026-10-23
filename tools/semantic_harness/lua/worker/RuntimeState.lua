-- Mutable state owned by one isolated semantic harness worker.

local RuntimeState = {}

function RuntimeState.new()
    return {
        scenario = nil,
        -- P12 source/working-world boundary.  sourceSnapshot is only read
        -- through Values.copy; production services receive Runtime.scenario,
        -- which is the detached mutable working projection.
        sourceSnapshot = nil,
        sourceMetadata = nil,
        sourceProvenance = nil,
        sourceProviderPayloads = {},
        sourceWorkingBaseline = nil,
        captureWorkingBaseline = false,
        workingWorldRevision = 0,
        workingResetCount = 0,
        queued = {},
        transcript = {},
        trace = {},
        transport = {},
        translationLookups = {},
        translationLanguage = "EN",
        llmCalls = 0,
        now = 1000,
        turn = 0,
        lastSuggestionRevision = nil,
        semanticClickReceipts = {},
        loadedModules = {},
        moduleManifest = {},
        headlessRequires = {},
        modData = {},
        questBoundary = nil,
        productionQuestRequest = nil,
    }
end

function RuntimeState.resetContainers(runtime)
    runtime.queued = {}
    runtime.transcript = {}
    runtime.trace = {}
    runtime.transport = {}
    runtime.translationLookups = {}
    runtime.llmCalls = 0
    runtime.now = 1000
    runtime.turn = 0
    runtime.lastSuggestionRevision = nil
    runtime.semanticClickReceipts = {}
    runtime.relationships = {}
end

function RuntimeState.resetTurn(runtime)
    runtime.queued = {}
    runtime.transport = {}
    runtime.trace = {}
end

return RuntimeState
