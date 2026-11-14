local T = require "tests/support/test"
T.addPackagePaths()

local submittedRequests = {}
local sentCommands = {}
local clientOnlyFlag = false
local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}

PsychopatzCore = {}
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_SEMANTIC_TASK_REQUEST = "semantic_task_request",
    },
    Core = {
        IsClientOnly = function() return clientOnlyFlag end,
        Now = function() return 500 end,
    },
    Network = { ClientState = {} },
    KnowledgeInterest = {},
    Semantics = {},
}

getSpecificPlayer = function() return player end
sendClientCommand = function(_, module, command, args)
    sentCommands[#sentCommands + 1] = {
        module = module,
        command = command,
        args = args,
    }
end

local Affordance = require "PsychopatzCore/ConvoEngine/Affordance"
local ActionContract = require "PsychopatzCore/ConvoEngine/ActionContract"

require "PNC/ConvoEngine/Registry"
require "PNC/ConvoEngine/Manifest"
require "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle"
T.load("ProjectHoomans", "client", "PNC/Networking/PNC_ClientRequests.lua")

local CampAction = T.load("ProjectHoomans", "shared",
    "PNC/ConvoEngine/CampActionContract.lua")

local Registry = PNC.ConvoEngine.Registry
local Client = PNC.Client
local campPlan = Registry.ConvoPlan("command.camp")
T.truthy(campPlan and campPlan.exchangeFamily,
    "compiled command.camp exchangeFamily loaded from Registry")
T.equal(campPlan.exchangeFamily.execute.use, "pnc.companion.camp",
    "command.camp binds execute to pnc.companion.camp")
T.equal(campPlan.exchangeFamily.bindings["camp.locationPhrase"].from,
    "result.data.site", "command.camp binds locationPhrase from result.data.site")

-- Discovery never executes the action.
local discoverCtx = {
    capability = { ["companion.camp"] = true },
    addressee = { id = "npc:camp_companion" },
    slot = { camp_site = { kind = "camp_site", label = "Kitchen", scope = "room" } },
}
local blockedDisc = Affordance.ExecuteExchange(campPlan, discoverCtx, {
    registry = Registry,
    discoveryOnly = true,
})
T.falsy(blockedDisc.accepted, "discoveryOnly prevents action execution")
T.equal(#sentCommands, 0, "discoveryOnly sends no commands")
T.equal(#submittedRequests, 0, "discoveryOnly submits no server tasks")

-- 1. Client-only missing hint rejects locally with no network packet.
clientOnlyFlag = true
local noHintCtx = {
    npcID = "npc:camp_companion",
    addressee = { id = "npc:camp_companion" },
    capability = { ["companion.camp"] = true },
    slot = {
        camp_site = {
            kind = "camp_site",
            scope = "here",
        },
    },
}
local noHintExec = Affordance.ExecuteExchange(campPlan, noHintCtx, {
    registry = Registry,
    exchangeID = "camp_ex_no_hint",
})
T.falsy(noHintExec.accepted, "missing clientHint is rejected")
T.equal(noHintExec.outcome, "rejected_no_site",
    "camp_no_visible_site reasonClass routes to rejected_no_site")
T.equal(noHintExec.reply.text,
    "I don't see a safe place to camp nearby.",
    "rejected_no_site renders bounded reply")
T.equal(#sentCommands, 0, "missing clientHint never sends client command")

-- 2. Singleplayer / authoritative server path via TaskRequestService.Submit + async completion.
clientOnlyFlag = false
PNC.Semantics.TaskRequestService = {
    Submit = function(request, _subCtx)
        submittedRequests[#submittedRequests + 1] = request
        if request.target and request.target.clientHint
            and request.target.clientHint.tooFar == true
        then
            return {
                accepted = false,
                status = "rejected",
                action = "CAMP",
                reason = "camp_site_hint_out_of_range",
            }
        end
        return {
            accepted = true,
            status = "accepted",
            action = "CAMP",
            npcID = request.npcID,
            planID = "semantic:camp:" .. tostring(request.requestID),
            request = request,
            details = {
                site = {
                    kind = "camp_site",
                    label = "Kitchen",
                    scope = "room",
                    siteID = "room:kitchen",
                },
                siteLabel = "Kitchen",
                siteScope = "room",
                siteID = "room:kitchen",
            },
        }
    end,
}

local spCtx = {
    npcID = "npc:camp_companion",
    addressee = { id = "npc:camp_companion" },
    conversationID = "conv:1",
    conversationToken = "tok:1",
    capability = { ["companion.camp"] = true },
    slot = {
        camp_site = {
            kind = "camp_site",
            scope = "room",
            clientHint = {
                kind = "camp_site",
                scope = "room",
                label = "Kitchen",
                siteID = "room:kitchen",
            },
        },
    },
}

local exOk = Affordance.ExecuteExchange(campPlan, spCtx, {
    registry = Registry,
    exchangeID = "camp_ex_kitchen",
    seed = "seed_1",
    index = 1,
})
T.truthy(exOk.accepted, "authoritative CAMP admission accepted")
T.equal(exOk.outcome, "queued", "admission maps to queued outcome")
T.equal(exOk.spokenAction, "Let's camp here.",
    "initiating spoken_action separated from button_label")
T.equal(#submittedRequests, 1, "TaskRequestService.Submit called once")
T.equal(submittedRequests[1].action, "CAMP", "submitted action is CAMP")
T.equal(submittedRequests[1].npcID, "npc:camp_companion", "npcID forwarded")

-- Duplicate exchangeID must not re-submit or re-emit speech.
local exDup = Affordance.ExecuteExchange(campPlan, spCtx, {
    registry = Registry,
    exchangeID = "camp_ex_kitchen",
})
T.equal(#submittedRequests, 1, "duplicate exchange does not re-submit task")
T.truthy(exDup.duplicate, "duplicate exchange flagged")
T.falsy(exDup.emittedReply, "duplicate exchange emits no duplicate reply")

-- Server async completion arrives over CMD_SEMANTIC_TASK_RESULT.
local completedPayload = CampAction.FromTaskResultPayload({
    requestID = exOk.requestID,
    npcID = "npc:camp_companion",
    action = "CAMP",
    accepted = true,
    status = "completed",
    siteLabel = "campfire",
    siteScope = "campfire",
    siteID = "fire:1",
})
local completedRes = Affordance.ApplyActionResult(campPlan, completedPayload, spCtx, {
    registry = Registry,
    requestID = exOk.requestID,
    completeAsync = true,
})
T.truthy(completedRes.accepted, "async CAMP completion accepted")
T.equal(completedRes.outcome, "completed", "completion selects completed branch")
T.equal(completedRes.reply.text, "We're set up by the campfire.",
    "completed branch resolves {camp.locationPhrase} from authoritative site")

-- Duplicate async completion must be ignored without extra speech.
local dupCompleted = Affordance.ApplyActionResult(campPlan, completedPayload, spCtx, {
    registry = Registry,
    requestID = exOk.requestID,
    completeAsync = true,
})
T.falsy(dupCompleted.accepted, "duplicate completion suppressed")
T.truthy(dupCompleted.stale, "duplicate completion marked stale")
T.falsy(dupCompleted.emittedReply, "duplicate completion emits no duplicate reply")

-- 3. Authoritative server out_of_range rejection routes via result.reasonClass.
local farCtx = {
    npcID = "npc:camp_companion",
    addressee = { id = "npc:camp_companion" },
    capability = { ["companion.camp"] = true },
    slot = {
        camp_site = {
            kind = "camp_site",
            scope = "room",
            clientHint = {
                kind = "camp_site",
                scope = "room",
                label = "Distant Barn",
                tooFar = true,
            },
        },
    },
}
local exFar = Affordance.ExecuteExchange(campPlan, farCtx, {
    registry = Registry,
    exchangeID = "camp_ex_far",
})
T.falsy(exFar.accepted, "out_of_range server rejection preserved")
T.equal(exFar.outcome, "rejected_out_of_range",
    "out_of_range maps to rejected_out_of_range branch")
T.equal(exFar.reply.text, "That camp location is too far away right now.",
    "rejected_out_of_range renders exact wording")

-- Client transport wrapping RequestSemanticTask remains intact if toggled back.
clientOnlyFlag = true
local netEx = Affordance.ExecuteExchange(campPlan, spCtx, {
    registry = Registry,
    exchangeID = "camp_ex_mp_net",
})
T.truthy(netEx.accepted, "clientOnly hinted CAMP dispatches through sendClientCommand")
T.equal(#sentCommands, 1, "exactly one CMD_SEMANTIC_TASK_REQUEST packet sent")
T.equal(sentCommands[1].args.action, "CAMP", "MP payload preserves CAMP contract")

T.finish("pnc_convo_engine_camp_action_smoke")
