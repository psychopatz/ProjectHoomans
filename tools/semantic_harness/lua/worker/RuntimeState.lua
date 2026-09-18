-- Mutable state owned by one isolated semantic harness worker.

local RuntimeState = {}

function RuntimeState.new()
    return {
        scenario = nil,
        queued = {},
        transcript = {},
        trace = {},
        transport = {},
        translationLookups = {},
        translationLanguage = "EN",
        llmCalls = 0,
        now = 1000,
        turn = 0,
        loadedModules = {},
        moduleManifest = {},
        headlessRequires = {},
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
    runtime.relationships = {}
end

return RuntimeState
