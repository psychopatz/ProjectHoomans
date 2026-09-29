-- Placeholder hardening for the conversation identity projection.
--
-- A presentation placeholder is a transport value, not something the player was
-- told. The server's own projection sets `displayName = "Unknown survivor"` while
-- the name is unknown, so a projection carrying that literal must still resolve to
-- the stranger label instead of being rendered as a learned name.

local T = require "tests/support/test"
T.addPackagePaths()

local npcID = "npcDeonByrd_ZUL8"
local CLIENT = "PNC/"

PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(payload)
                return payload and payload.key or "identity.stranger"
            end,
        },
    },
}

PNC = {
    Conversation = {
        TextLoader = {
            EnsureSource = function() return true end,
        },
    },
    FlavorAddress = {
        ResolveForNPC = function()
            return { addressName = "you", known = false }
        end,
        ResolveNPCSeed = function() return 1 end,
    },
    Network = {
        ClientState = {
            npcKnowledge = {},
            npcPresentations = {},
            snapshots = {},
            identityDisclosureVerified = {},
            playerContext = { characterUUID = "char_player" },
        },
    },
}

T.load("ProjectHoomans", "client", CLIENT .. "Knowledge/PNC_NPCIdentityPresentation.lua")
-- The context module returns its table instead of publishing it on PNC.
local function loadContext()
    return dofile(T.path(
        "ProjectHoomans",
        "client",
        CLIENT .. "Conversation/Definition/PNC_ConversationDefinition_Context.lua"
    ))
end
local Context = loadContext()
PNC.Conversation.DefinitionContext = Context

local Identity = PNC.NPCIdentityPresentation
T.truthy(type(Context) == "table",
    "identity projection module returns its context table")

local projection = Context.IdentityProjection
T.truthy(type(projection) == "function",
    "identity projection helper is reachable")

local ClientState = PNC.Network.ClientState
local entry = { id = npcID }

T.truthy(Identity.IsPlaceholderName("Unknown survivor"),
    "shared placeholder helper recognises the server projection default")
T.truthy(Identity.IsPlaceholderName("STRANGER"),
    "shared placeholder helper recognises the stranger token")
T.falsy(Identity.IsPlaceholderName("Deon Byrd"),
    "a real name is never treated as a placeholder")
T.falsy(Identity.IsPlaceholderName(nil),
    "nil is not a placeholder string")

-- 1. Unknown NPC: the server-shaped projection default must not become a name.
ClientState.npcPresentations[npcID] = {
    npcID = npcID,
    state = "unknown",
    displayName = "Unknown survivor",
}
local state, name = projection(entry)
T.equal(state, "unknown",
    "placeholder projection stays unknown before any disclosure")
T.equal(name, "identity.stranger",
    "placeholder projection renders the stranger label, not the placeholder")

-- 2. Learned fact present: the real fact wins over the stale placeholder.
ClientState.npcKnowledge[npcID] = {
    npcID = npcID,
    revision = 1,
    categories = {
        {
            id = "identity",
            descriptors = {
                {
                    descriptorID = "identity.name",
                    status = "confirmed",
                    value = "Deon Byrd",
                },
            },
        },
    },
}
state, name = projection(entry)
T.equal(state, "known",
    "learned name makes the projection known")
T.equal(name, "Deon Byrd",
    "learned name is rendered instead of the stale placeholder")

-- 3. Valueless fact: present but unusable is still unknown.
ClientState.npcKnowledge[npcID] = {
    npcID = npcID,
    revision = 2,
    categories = {
        {
            id = "identity",
            descriptors = {
                { descriptorID = "identity.name", status = "suspected" },
            },
        },
    },
}
state, name = projection(entry)
T.equal(state, "unknown",
    "a descriptor without a usable value stays unknown")
T.equal(name, "identity.stranger",
    "a valueless descriptor cannot surface a name")

T.finish("pnc_identity_placeholder_projection_smoke")
