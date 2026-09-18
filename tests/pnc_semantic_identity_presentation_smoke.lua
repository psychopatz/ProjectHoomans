local T = require "tests/support/test"
T.addPackagePaths()

local originalPNC = PNC
local originalPsychopatzCore = PsychopatzCore
local registeredHandler
local queued = {}
local appended = 0

local view = {
    spec = { npcID = "npc-identity" },
    session = {
        queueMessage = function(self, speaker, payload, metadata)
            queued[#queued + 1] = {
                speaker = speaker,
                payload = payload,
                metadata = metadata,
            }
        end,
        append = function()
            appended = appended + 1
        end,
    },
}

PNC = {
    Const = {
        CMD_SEMANTIC_IDENTITY_RESULT = "SemanticIdentityResult",
    },
    Network = {
        ClientState = {
            pendingSemanticIdentity = { ["npc-identity"] = "identity:1" },
        },
    },
    Translation = {
        TrFormat = function(key, fallback, name)
            return "TL:" .. tostring(key) .. ":" .. tostring(name or fallback)
        end,
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                registeredHandler = handler
                return true
            end,
        },
    },
    Semantics = {
        DialogueInput = { ActiveView = view },
    },
}
PsychopatzCore = { Conversation = { instance = nil } }

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentity.lua"
)

T.truthy(registeredHandler,
    "semantic identity result handler registers with the client router")
registeredHandler({
    requestID = "identity:1",
    npcID = "npc-identity",
    accepted = true,
    truthful = true,
    responseText = "Nice to meet you. I'm Mara.",
    responseKey = "UI_PNC_Conversation_ToolReply_AskNameNamed_1",
    responseArgs = { "Mara" },
})

T.equal(appended, 0,
    "authoritative identity results do not bypass the response queue")
T.equal(#queued, 1,
    "authoritative identity result queues exactly one NPC response")
T.equal(queued[1].payload.fallback,
    "Nice to meet you. I'm Mara.",
    "authoritative identity text reaches the active semantic view")
T.equal(queued[1].payload.key,
    "UI_PNC_Conversation_ToolReply_AskNameNamed_1",
    "authoritative identity preserves the real translation key")
T.equal(queued[1].payload.text,
    "TL:UI_PNC_Conversation_ToolReply_AskNameNamed_1:Mara",
    "identity presentation resolves the key through the active language")
T.equal(queued[1].metadata.source.channel,
    "authoritative_response",
    "identity response remains distinguishable from local semantic replies")
T.equal(queued[1].metadata.provenance.provider, "server",
    "identity response preserves server authority provenance")

PNC = originalPNC
PsychopatzCore = originalPsychopatzCore

T.finish("pnc_semantic_identity_presentation_smoke")
