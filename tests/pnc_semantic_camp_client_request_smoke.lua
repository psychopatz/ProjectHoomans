local T = require "tests/support/test"
T.addPackagePaths()

local sent = {}
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
        IsClientOnly = function() return true end,
        Now = function() return 100 end,
    },
    Network = { ClientState = {} },
    KnowledgeInterest = {},
    Semantics = {},
}
getSpecificPlayer = function() return player end
sendClientCommand = function(_, module, command, args)
    sent[#sent + 1] = { module = module, command = command, args = args }
end

T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_ClientRequests.lua")
local Client = PNC.Client

local rejected, rejectedReason = Client.RequestSemanticTask({
    action = "CAMP",
    target = { kind = "camp_site", scope = "here" },
}, { npcID = "npc:camp" })
T.falsy(rejected,
    "client semantic CAMP without a visible hint is rejected locally")
T.equal(rejectedReason, "camp_no_visible_site",
    "local semantic CAMP rejection has a stable reason")
T.equal(#sent, 0,
    "missing semantic camp hint does not send a server request")

local accepted, acceptedReason = Client.RequestSemanticTask({
    action = "CAMP",
    target = {
        kind = "camp_site",
        scope = "here",
        clientHint = {
            kind = "camp_site",
            scope = "campfire",
            x = 11.5,
            y = 10.5,
            z = 0,
        },
    },
}, { npcID = "npc:camp" })
T.truthy(accepted, "client semantic CAMP with a hint is queued")
T.equal(acceptedReason, "sent", "hinted semantic CAMP uses normal transport")
T.equal(#sent, 1, "hinted semantic CAMP sends exactly one request")
T.equal(sent[1].args.target.clientHint.x, 11.5,
    "the primitive camp hint crosses the transport boundary")

T.finish("pnc_semantic_camp_client_request_smoke")
