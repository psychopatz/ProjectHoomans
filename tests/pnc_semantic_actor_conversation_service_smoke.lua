local T = require "tests/support/test"
T.addPackagePaths()

local previousPNC = PNC
PNC = {
    Registry = {},
    Semantics = {},
}

local Adapter = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticActorConversationService.lua"
)

local router = {
    state = { sequence = 0 },
    Process = function() return { accepted = true } end,
}
local view = {
    spec = {
        npcID = "mara",
        context = {
            entry = {
                record = {
                    identity = { seed = 42, displayName = "Mara" },
                    persona = { selectionSetVersion = 3 },
                    personality = { warmth = 0.8 },
                    relationships = { faction = "traders" },
                },
            },
        },
    },
    session = { conversationID = "conversation-1" },
}

T.truthy(Adapter.IsAvailable(), "Core actor service is available")
local service, reason = Adapter.Attach(view, router, { context = {} })
T.truthy(service, reason)
T.equal(service.actor.actorId, "mara", "adapter preserves actor ID")
T.equal(service.actor.identity.seed, 42, "adapter projects authored identity")
T.equal(service.actor.persona.selectionSetVersion, 3,
    "adapter projects versioned persona metadata")
T.equal(service.router, router, "adapter injects the production router")

local same = Adapter.Attach(view, router, { context = {} })
T.equal(same, service, "one service remains attached to the session")
T.equal(view.session.semanticActorConversationService, service,
    "service is discoverable from the conversation session")

PNC = previousPNC
T.finish("pnc_semantic_actor_conversation_service_smoke")
