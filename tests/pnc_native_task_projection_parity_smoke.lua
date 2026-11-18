local T = require "tests/support/test"
T.addPackagePaths()

local queuedMessages = {}
local taskDispatchCalls = 0

PsychopatzCore = {
    Semantics = {
        IR = {
            New = function(value) return value end,
        },
    },
    Conversation = {
        Registry = {
            CollectTextKeys = function() return {} end,
        },
        TextCatalog = {
            EnsureSource = function() return true end,
            ValidateSource = function() return true end,
        },
        Text = {
            Resolve = function(value) return value and value.fallback or "" end,
        },
    },
    Translation = {
        GetKey = function(_, _, fallback) return fallback end,
    },
}

PNC = {
    Core = { Now = function() return 100 end },
    ClientCompanionAuthority = {
        IsCompanion = function(record) return record and record.companion == true end,
        IsOwnedByPlayer = function(record) return record and record.owned == true end,
    },
    Network = {
        ClientState = {
            playerContext = { characterUUID = "player:1", socialProfile = {} },
            colonyManagement = {},
            conversationRelationships = {},
            npcKnowledge = {},
            npcPresentations = {},
            semanticTaskResults = {},
            semanticTaskOutcomes = {},
        },
    },
    Conversation = {
        Audience = {
            BuildProfile = function()
                return {
                    audience = "companion",
                    tacticalClass = "companion",
                    playerHostile = false,
                    audiences = { "companion" },
                    baseEstablished = true,
                }
            end,
        },
        Relationship = {
            GetPresentation = function() return {} end,
        },
        Composer = {},
    },
    Semantics = {
        SemanticDialogueRuntime = {
            IsEnabled = function() return true end,
        },
        CapabilityCatalog = {
            ListActions = function()
                return {
                    {
                        id = "WAIT_AT",
                        bindingID = "pnc:task.wait_at",
                        dispatchable = true,
                        binding = { id = "pnc:task.wait_at", owner = "PNC.Semantics.TaskAdapter" },
                    },
                }
            end,
        },
        CommandAdapter = {
            Dispatch = function()
                return { status = "unmapped", accepted = false }
            end,
        },
        TaskAdapter = {},
    },
    ConvoEngine = {
        DialogueInput = { Internal = {} },
    },
}

ZombRand = function() return 1 end
getGameTime = function()
    return { getWorldAgeHours = function() return 12 end }
end

PNC.Identity = {}
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticTaskProjection.lua")
PNC.ConvoEngine.SuggestionPredicates = {}
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/SuggestionPredicates.lua")
PNC.ConvoEngine.DialogueBranchOffers = {}
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/BranchOffers.lua")
PNC.Semantics.ActorConversationContext = {}
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_ActorConversationContext.lua")
PNC.ConvoEngine.DialogueChoiceRanking = {}
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Suggestions/Ranking.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Suggestions/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Suggestions/StaticProvider.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Suggestions/CapabilityProvider.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Suggestions/SocialProvider.lua")
local Suggestions = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/Suggestions.lua")

local Composer = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Context.lua"
)
local ContextProjection = T.load(
    "ProjectHoomans",
    "client",
    "PNC/ConvoEngine/Dialogue/Input_ContextProjection.lua"
)
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/ConvoEngine/Dialogue/Input_Actions.lua"
)

local function hasWaitAt(suggestions)
    for _, row in ipairs(suggestions and suggestions.permittedCapabilities or {}) do
        if row.id == "action.wait_at"
            or (type(row.binding) == "table" and row.binding.id == "pnc:task.wait_at")
        then
            return true, row
        end
    end
    for _, group in ipairs(suggestions and suggestions.groups or {}) do
        for _, row in ipairs(group.capabilities or {}) do
            if row.id == "action.wait_at"
                or (type(row.binding) == "table" and row.binding.id == "pnc:task.wait_at")
            then
                return true, row
            end
        end
    end
    return false, nil
end

local entry = {
    id = "npc:native_wait",
    record = {
        id = "npc:native_wait",
        companion = true,
        owned = true,
        activeBehavior = "idle",
        health = { state = "healthy" },
    },
}
local destination = {
    kind = "campfire",
    targetID = "campfire@native",
    x = 100,
    y = 200,
    z = 0,
}

local composerContext = Composer.BuildContext(entry, { id = "player:1" }, "sunrise", "friendly")
composerContext.suggestionDestination = destination

local session = {
    conversationID = "conv:native_wait",
    semanticTaskRequests = {},
    queueMessage = function(_, kind, payload, meta)
        queuedMessages[#queuedMessages + 1] = {
            kind = kind,
            payload = payload,
            meta = meta,
        }
        return true
    end,
}

local view = {
    spec = {
        npcID = "npc:native_wait",
        context = {
            npcID = "npc:native_wait",
            conversationBlockContext = composerContext,
            suggestionDestination = destination,
        },
    },
    session = session,
}
Input.ActiveView = view

local function buildNativeSuggestions()
    local projected = ContextProjection.Build(view, function()
        return { ready = false, status = "unavailable" }
    end)
    return Suggestions.Build({}, projected, nil), projected
end

PNC.Semantics.TaskAdapter.Dispatch = function(actionIntent, context)
    taskDispatchCalls = taskDispatchCalls + 1
    return {
        status = "accepted",
        accepted = true,
        request = { requestID = "task:native:" .. tostring(taskDispatchCalls) },
        planID = "plan:native:wait",
    }
end

-- 1. Before request: WAIT_AT is visible and eligible via native context projection.
local beforeSuggestions, beforeProjected = buildNativeSuggestions()
local beforePresent, beforeRow = hasWaitAt(beforeSuggestions)
T.equal(beforePresent, true, "WAIT_AT is visible in native context before request")
T.equal(beforeRow.status, "eligible", "WAIT_AT is eligible before request")
T.equal(beforeProjected.taskProjection.WAIT_AT, nil, "no active/terminal WAIT_AT projection before request")

-- 2. Authoritative request/admission updates session.semanticTaskRequests and native projection.
local admittedResult = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:native:1",
    ir = { normalizedText = "wait at campfire", confidence = 0.95 },
    decision = {
        action = "WAIT_AT",
        branch = "COMMAND_ACCEPTED",
        route = "deterministic",
        actionIntent = { action = "WAIT_AT", target = destination },
    },
}, "wait at campfire")
T.equal(admittedResult.accepted, true, "WAIT_AT task request is admitted")
T.equal(taskDispatchCalls, 1, "exactly one dispatch occurs on admission")

local activeSuggestions, activeProjected = buildNativeSuggestions()
T.equal(type(activeProjected.taskProjection.WAIT_AT), "table",
    "native ContextProjection projects WAIT_AT while active")
T.equal(activeProjected.taskProjection.WAIT_AT.status, "active",
    "native ContextProjection marks WAIT_AT active")
T.equal(activeProjected.taskProjection.WAIT_AT.authoritative, true,
    "native taskProjection entry is authoritative")
local activePresent = hasWaitAt(activeSuggestions)
T.equal(activePresent, false, "WAIT_AT retires from native suggestions while active")

-- 3. Duplicate typed/click input dispatches zero times while active.
local duplicateActive = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:native:2",
    ir = { normalizedText = "wait at campfire", confidence = 0.95 },
    decision = {
        action = "WAIT_AT",
        branch = "COMMAND_ACCEPTED",
        route = "deterministic",
        actionIntent = { action = "WAIT_AT", target = destination },
    },
}, "wait at campfire")
T.equal(duplicateActive.accepted, false, "duplicate WAIT_AT while active is rejected")
T.equal(duplicateActive.reason, "task_already_active", "duplicate WAIT_AT reports task_already_active")
T.equal(taskDispatchCalls, 1, "duplicate WAIT_AT while active dispatches zero times")

-- 4. Terminal states (completed / failed / rejected) project via ReceiveSemanticTaskResult
--    and keep WAIT_AT retired with zero duplicate dispatch.
local terminalStatuses = { "completed", "failed", "rejected" }
for index = 1, #terminalStatuses do
    local terminalStatus = terminalStatuses[index]
    local reqID = index == 1 and "task:native:1" or ("task:terminal:" .. terminalStatus)
    if index > 1 then
        session.semanticTaskRequests[reqID] = { action = "WAIT_AT" }
    end
    local ok = Input.ReceiveSemanticTaskResult({
        requestID = reqID,
        npcID = "npc:native_wait",
        action = "WAIT_AT",
        accepted = terminalStatus == "completed",
        status = terminalStatus,
    })
    T.equal(ok, true, "ReceiveSemanticTaskResult handles terminal status " .. terminalStatus)
    T.equal(session.semanticTaskRequests[reqID], nil, "terminal result clears pending request")

    local termSuggestions, termProjected = buildNativeSuggestions()
    T.equal(termProjected.taskProjection.WAIT_AT.status, terminalStatus,
        "native ContextProjection projects terminal status " .. terminalStatus)
    local composerTerminal = Composer.BuildContext(entry, { id = "player:1" }, "sunrise", "friendly")
    T.equal(composerTerminal.taskProjection.WAIT_AT.status, terminalStatus,
        "native Composer.BuildContext projects terminal status " .. terminalStatus)
    local termPresent = hasWaitAt(termSuggestions)
    T.equal(termPresent, false,
        "WAIT_AT stays retired in native suggestions for terminal status " .. terminalStatus)

    local dupTerm = Input.Internal.DispatchAction(view, {
        sequence = "dialogue:native:term:" .. terminalStatus,
        ir = { normalizedText = "wait at campfire", confidence = 0.95 },
        decision = {
            action = "WAIT_AT",
            branch = "COMMAND_ACCEPTED",
            route = "deterministic",
            actionIntent = { action = "WAIT_AT", target = destination },
        },
    }, "wait at campfire")
    T.equal(dupTerm.accepted, false, "duplicate WAIT_AT in terminal state is rejected")
    T.equal(dupTerm.reason, "task_already_" .. terminalStatus,
        "duplicate WAIT_AT reports task_already_" .. terminalStatus)
    T.equal(taskDispatchCalls, 1, "duplicate WAIT_AT in terminal state dispatches zero times")
end
