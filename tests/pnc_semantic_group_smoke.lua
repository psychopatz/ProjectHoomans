local T = require "tests/support/test"
T.addPackagePaths()

local originalPNC = PNC
local originalCore = PsychopatzCore

local dispatches = {}
local queued = {}
local recorded = {}
local routerCalls = {}
local submitCalls = 0
local group

PsychopatzCore = {
    Semantics = {
        IR = {
            Clone = function(value) return value end,
        },
    },
}
PNC = {
    Core = {
        Now = function() return 1234 end,
    },
    Conversation = {},
    Semantics = {
        DialogueInput = {
            Internal = {},
        },
    },
}

local Group = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationGroup.lua"
)

local function makeSession(id)
    return {
        conversationID = "conversation-" .. id,
        characterUUID = "player-one",
        context = {},
        queueMessage = function() end,
    }
end

local function makeHost(id, name)
    return {
        spec = {
            npcID = id,
            context = {
                npcName = name,
                npcFullName = name,
                playerName = "Player",
            },
        },
        session = makeSession(id),
        closed = false,
    }
end

local alice = makeHost("npc-alice", "Alice Garner")
local bob = makeHost("npc-bob", "Bob Garner")
local charlie = makeHost("npc-charlie", "Charlie Garner")
local hosts = { alice, bob, charlie }
local entries = {
    { id = "npc-alice", name = "Alice Garner" },
    { id = "npc-bob", name = "Bob Garner" },
    { id = "npc-charlie", name = "Charlie Garner" },
}

local function hasCandidate(host, id, firstName)
    local candidates = host.spec.context.semanticEntityCandidates or {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        if candidate.id == id and candidate.firstName == firstName then
            return true
        end
    end
    return false
end

local function shouldHandle(view, result, value)
    local member = group:MemberForHost(view)
    return not member or group:ShouldRespond(member, result, value)
end

local function makeResult(value, sequence)
    local target
    local result
    if string.find(string.lower(value), "bob", 1, true) then
        target = { id = "npc-bob", entityType = "npc" }
    end
    result = {
        accepted = true,
        sequence = sequence,
        ir = {
            rawText = value,
            normalizedText = string.lower(value),
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "HELP",
            target = target,
            confidence = 0.96,
        },
        decision = {
            route = "deterministic",
            branch = "COMMAND_ACCEPTED",
            action = "HELP",
            actionIntent = { action = "HELP" },
            response = {
                templateID = "semantic.test.group_ack",
                fallback = "I can help.",
            },
        },
    }
    if string.find(string.lower(value), "camp", 1, true) then
        result.ir.action = "CAMP"
        result.decision.action = "CAMP"
        result.decision.actionIntent = { action = "CAMP" }
    end
    return result
end

local internal = PNC.Semantics.DialogueInput.Internal
local dialogueInput = PNC.Semantics.DialogueInput
internal.Now = function() return 1234 end
internal.ShallowContext = function(view) return view.spec.context end
internal.RecordContextTurn = function(view, result, options)
    recorded[#recorded + 1] = {
        id = view.spec.npcID,
        result = result,
        options = options,
    }
    return true
end
internal.RouterFor = function(view)
    return {
        ProcessIR = function(_, ir, context, options)
            routerCalls[#routerCalls + 1] = {
                id = view.spec.npcID,
                context = context,
                options = options,
            }
            return {
                accepted = true,
                sequence = #routerCalls + 10,
                ir = ir,
                decision = {
                    route = "deterministic",
                    branch = "COMMAND_ACCEPTED",
                    action = "HELP",
                    actionIntent = { action = "HELP" },
                    response = {
                        templateID = "semantic.test.group_ack",
                        fallback = "I can help.",
                    },
                },
            }
        end,
    }
end
internal.DispatchAction = function(view, result)
    dispatches[#dispatches + 1] = {
        id = view.spec.npcID,
        requestID = view.semanticRequestID,
        result = result,
    }
    return { accepted = true, status = "accepted" }
end
internal.QueueDeterministicResponse = function(
    view, value, result, actionResult, options
)
    queued[#queued + 1] = {
        id = view.spec.npcID,
        options = options,
        actionResult = actionResult,
    }
    return true
end
internal.SubmitSingle = function(view, value)
    submitCalls = submitCalls + 1
    local result = makeResult(value, submitCalls)
    local actionResult
    view.lastSemanticDialogueResult = result
    view.lastSemanticActionResult = nil
    if shouldHandle(view, result, value) then
        actionResult = internal.DispatchAction(view, result, value)
        view.lastSemanticActionResult = actionResult
        internal.QueueDeterministicResponse(
            view, value, result, actionResult)
    end
    return true
end

PNC.Semantics = nil
group = Group.Create(alice, hosts, entries, { id = "player-one" }, {
    mode = "nearby",
    dialogueInput = dialogueInput,
})
T.truthy(group, "nearby group is created")
T.equal(#group.members, 3, "all selected hosts become participants")
T.equal(#group.participantIDs, 3, "participant ids include every host")
T.truthy(hasCandidate(alice, "npc-bob", "Bob"),
    "group context exposes other participants by first name")
T.truthy(hasCandidate(charlie, "npc-alice", "Alice"),
    "every member receives the shared entity candidates")

local accepted = group:Submit("hello everyone", {})
T.equal(accepted, true, "broadcast turn is accepted")
T.equal(submitCalls, 1, "the canonical input is submitted once")
T.equal(#dispatches, 3, "broadcast dispatches once per participant")
T.equal(#queued, 3, "broadcast queues one response per participant")
T.equal(#routerCalls, 2, "secondary participants use their own routers")
T.equal(#recorded, 2, "secondary participants record the shared turn")
T.equal(queued[2].options.session, alice.session,
    "secondary response uses the canonical primary session")
T.equal(queued[3].options.session, alice.session,
    "all group responses use one queue")
T.equal(queued[2].options.participants, group.participantIDs,
    "responses carry the group participant projection")
T.equal(queued[2].options.speakerName, "Bob Garner",
    "queued response preserves the actual speaker")
T.equal(dispatches[2].requestID ~= dispatches[3].requestID, true,
    "secondary action requests have unique ids")
T.equal(group.activeTurn.responseCount, 3,
    "broadcast turn records all response speakers")

dispatches = {}
queued = {}
routerCalls = {}
recorded = {}
local addressed = group:Submit("Bob, help me", {})
T.equal(addressed, true, "named turn is accepted")
T.equal(#dispatches, 1, "named turn dispatches only to the named NPC")
T.equal(dispatches[1].id, "npc-bob", "named action reaches Bob")
T.equal(#queued, 1, "named turn queues only the named response")
T.equal(queued[1].id, "npc-bob", "named response is spoken by Bob")
T.equal(group.activeTurn.responseCount, 1,
    "named turn records one responding participant")

dispatches = {}
queued = {}
routerCalls = {}
recorded = {}
local groupCampAccepted = group:Submit("let's camp here", {})
T.equal(groupCampAccepted, true, "group camp turn is accepted")
T.equal(submitCalls, 3, "group camp still submits one canonical turn")
T.equal(#dispatches, 1,
    "group camp dispatches one authoritative action")
T.equal(#routerCalls, 0,
    "group camp does not re-interpret the action for every member")
T.equal(#recorded, 0,
    "group camp does not record duplicate semantic turns")
T.equal(#queued, 3,
    "group camp preserves one acknowledgement speaker per participant")
T.equal(group.activeTurn.responseCount, 3,
    "group camp records all acknowledgement speakers")
T.equal(queued[2].actionResult.status, "accepted",
    "group camp acknowledgements reuse the canonical action result")

PNC = originalPNC
PsychopatzCore = originalCore

T.finish("pnc_semantic_group_smoke")
