-- Read-only runtime contract check for the native semantic dialogue path.
--
-- This spoke reports capability identity; it does not change parser state,
-- dialogue state, gameplay state, or network authority.  The source marker
-- and fingerprints are intentionally explicit so a native console capture
-- can be compared with the audited checkout and installed package.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Diagnostics = PNC.Semantics.SemanticDiagnostics
if type(Diagnostics) ~= "table" then
    return nil
end

local Handshake = PNC.Semantics.SemanticCapabilityHandshake or {}
PNC.Semantics.SemanticCapabilityHandshake = Handshake

Handshake.VERSION = 1
Handshake.SOURCE_MARKER = "ProjectHoomans.Semantics.C0B.20261017"
Handshake.SOURCE_BASE_REVISION =
    "56288e50e6d782634df7f26ceaa0f0cb7c0922f9"
Handshake.SOURCE_BUILD = "c0b-capability-handshake-working-tree"
Handshake.SOURCE_FINGERPRINTS = {
    dialogueInput =
        "247ef46bf02760ad413cd15b5feb2cbea46d18a7300630caf1625c901c53592b",
    dialogueInputTrace =
        "7b9b3eb75e0e01c0bebb1483c3dbd3dac33ea694b96b62450b859f920a2ce3ab",
    translationBootstrap =
        "04355c037b67f6dbb46349d976eec948868b5a9af5251002658f7b8a836cc49d",
    conversationManifest =
        "054c3826ace4d826bbec4a539c3fe6f9b17657a43a0886843d8ca4a48c53fa85",
    responseEnglish =
        "997dc14ec9b5bafe95f12e5e9e12101ca6d1d7b095fbb96582c077ff37bf4859",
    responseTagalog =
        "ee613dc802a3ca5f4721e5bc70403f26d3b5287898679bb696352903e537640f",
}
Handshake.MANIFEST_PATH = "media/translation/manifests/Conversation.json"

local function available(value, member)
    return type(value) == "table" and type(value[member]) == "function"
end

local function missing(failures, name, condition)
    if not condition then failures[#failures + 1] = name end
end

local function markerValue(value)
    return value == nil and "missing" or tostring(value)
end

local function translationState()
    local translation = PNC.Translation
    local systems = translation and translation.Systems or nil
    local handle = systems and systems.Conversation or nil
    local manager = rawget(_G, "CustomTranslationManager")
    local source = manager and manager.Systems
        and manager.Systems.ProjectHoomans
        and manager.Systems.ProjectHoomans.Conversation or nil
    local loadOK
    local loadResult
    local loadReason

    if available(handle, "load") then
        loadOK, loadResult = handle:load()
        if loadOK ~= true then loadReason = loadResult end
    else
        loadReason = "conversation_catalog_handle_unavailable"
    end

    local registered = source
        and source.manifestPath == Handshake.MANIFEST_PATH
    local manifestRead = source
        and source._manifestState == "loaded"
        and source._manifestPath == Handshake.MANIFEST_PATH
    local loaded = loadOK == true and type(loadResult) == "table"
    local language = manager and type(manager.getLanguage) == "function"
        and manager.getLanguage() or nil

    return {
        managerAvailable = type(manager) == "table",
        managerRegistrationAPI = manager
            and type(manager.registerSystem) == "function"
            and type(manager.forMod) == "function" or false,
        conversationHandle = available(handle, "get")
            and available(handle, "load"),
        manifestRegistered = registered == true,
        manifestRead = manifestRead == true,
        manifestPath = source and source._manifestPath
            or source and source.manifestPath or nil,
        shardCount = source and tonumber(source._lastShardCount) or 0,
        catalogLoaded = loaded,
        catalogLoadReason = loadReason,
        language = language,
    }
end

function Handshake.Report()
    if type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false, "disabled"
    end
    if Handshake.LastReport then
        return Handshake.LastReport.ok == true, Handshake.LastReport
    end

    local semantic = PsychopatzCore and PsychopatzCore.Semantics or nil
    local parser = semantic and semantic.Parser or nil
    local router = semantic and semantic.DialogueRouter or nil
    local ir = semantic and semantic.IR or nil
    local policy = PNC.Semantics.DialoguePolicy
    local translation = translationState()
    local failures = {}

    local parserCandidates = available(parser, "ParseCandidates")
    local candidateSelection = available(policy, "SelectCandidate")
    local flowCommit = available(policy, "CommitFlow")
    local routerCandidateHooks = available(router, "SetCandidateParser")
        and available(router, "SetCandidateSelector")

    missing(failures, "core_semantics", type(semantic) == "table")
    missing(failures, "ir_validate", available(ir, "Validate"))
    missing(failures, "parser_parse", available(parser, "Parse"))
    missing(failures, "parser_parse_candidates", parserCandidates)
    missing(failures, "candidate_selection", candidateSelection)
    missing(failures, "dialogue_router", type(router) == "table")
    missing(failures, "dialogue_router_new", available(router, "New"))
    missing(failures, "dialogue_router_preview", available(router, "Preview"))
    missing(failures, "dialogue_router_process_ir",
        available(router, "ProcessIR"))
    missing(failures, "dialogue_router_candidate_hooks", routerCandidateHooks)
    missing(failures, "flow_commit", flowCommit)
    missing(failures, "translation_manager", translation.managerAvailable)
    missing(failures, "translation_registration_api",
        translation.managerRegistrationAPI)
    missing(failures, "conversation_manifest_registration",
        translation.manifestRegistered)
    missing(failures, "conversation_manifest_reader", translation.manifestRead)
    missing(failures, "conversation_catalog_handle",
        translation.conversationHandle)
    missing(failures, "conversation_catalog_load", translation.catalogLoaded)

    local coreMarker = table.concat({
        "semantic=" .. markerValue(semantic and semantic.VERSION),
        "parserCandidates=" .. markerValue(parser
            and parser.CANDIDATE_VERSION),
        "router=" .. markerValue(router and router.VERSION),
        "manifest=" .. tostring(translation.manifestRegistered == true),
    }, ";")
    local report = {
        schemaVersion = Handshake.VERSION,
        kind = "semantic_capability_handshake",
        ok = #failures == 0,
        failures = failures,
        sourceMarker = Handshake.SOURCE_MARKER,
        sourceBaseRevision = Handshake.SOURCE_BASE_REVISION,
        sourceBuild = Handshake.SOURCE_BUILD,
        sourceFingerprints = Handshake.SOURCE_FINGERPRINTS,
        sourceIdentity = "loaded_module_marker",
        coreApiMarker = coreMarker,
        parserCandidates = parserCandidates,
        candidateSelection = candidateSelection,
        flowCommit = flowCommit,
        routerCandidateHooks = routerCandidateHooks,
        translation = translation,
    }
    Diagnostics.Record("semantic.capability_handshake", report, {
        dedupeKey = "semantic-capability-handshake",
    })
    Handshake.LastReport = report
    return report.ok == true, report
end

Diagnostics.RecordCapabilityHandshake = Handshake.Report

return Handshake
