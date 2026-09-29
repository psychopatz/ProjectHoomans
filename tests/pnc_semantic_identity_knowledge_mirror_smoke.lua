-- Contract test for the identity disclosure -> client knowledge mirror.
--
-- Asking a spawned NPC their name must make the name reach the SAME client
-- knowledge record that the world nameplate reads (`ClientState.npcKnowledge`),
-- in the same handling as the authoritative result. Before this contract the
-- semantic identity route only set `identityDisclosureVerified`, so the portrait
-- plate and conversation log showed the learned name while the nameplate stayed
-- hidden until an unrelated knowledge request happened to arrive.

local T = require "tests/support/test"
T.addPackagePaths()

local SERVER = "PNC/Knowledge/PlayerKnowledgeCommands/"
local CLIENT = "PNC/"

local identityName = "Deon Byrd"
local npcID = "npcDeonByrd_ZUL8"
local relationship = { approval = 0, respect = 0, familiarity = 0, revision = 1 }
local knowledgeRevision = 0
local sent = {}
local registeredCommands = {}

-- ---------------------------------------------------------------- server stubs

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = {
    Core = {
        Now = function() return 5000 end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_SEMANTIC_IDENTITY_RESULT = "SemanticIdentityResult",
    },
    Semantics = {},
    PlayerKnowledgeCommands = {
        Processed = {},
        Uncommitted = {},
        Diagnostics = {},
        Internal = {
            SafeID = function(value)
                value = tostring(value or "")
                return value ~= "" and value or nil
            end,
            ContextFor = function()
                return {
                    characterUUID = "char_player",
                    entityKey = "player:sp:char_player",
                    bindingRevision = 1,
                }
            end,
            IntroductionText = function() return "I'm " .. identityName .. "." end,
        },
    },
    PlayerContext = {
        Resolve = function()
            return {
                characterUUID = "char_player",
                entityKey = "player:sp:char_player",
                bindingRevision = 1,
            }, "resolved"
        end,
    },
    Registry = {
        Get = function(id)
            if tostring(id) ~= npcID then return nil end
            return { id = npcID, identity = { displayName = identityName } }
        end,
    },
    PlayerCharacters = {
        GetRegistryRecord = function()
            return { displayName = "Psycho", forename = "Psycho", surname = "" }
        end,
    },
    Conversations = nil,
    Conversation = {
        Authority = {
            Internal = {
                ValidateLease = function(_, _, token)
                    local valid = token == "lease"
                    return valid, valid and "validated" or "invalid_lease",
                        { token = token }
                end,
            },
        },
    },
    Relationships = {
        Get = function() return relationship end,
        ApplyConversationEffect = function(_, _, effect, context)
            relationship.approval = relationship.approval
                + (tonumber(effect.approval) or 0)
            relationship.respect = relationship.respect
                + (tonumber(effect.respect) or 0)
            relationship.familiarity = relationship.familiarity
                + (tonumber(effect.familiarity) or 0)
            relationship.revision = relationship.revision + 1
            return true, "applied", {
                eventID = context and context.eventID,
                memoryID = context and context.eventID,
                memoryType = effect.memoryType,
            }
        end,
    },
    RelationshipPresentation = {
        Summarize = function(value) return value end,
    },
    Translation = {
        TrFormat = function(key, fallback, ...)
            local args = { ... }
            if type(fallback) == "string"
                and string.find(fallback, "%%s", 1, true)
            then
                local index = 0
                return (string.gsub(fallback, "%%s", function()
                    index = index + 1
                    return tostring(args[index] or "")
                end))
            end
            return fallback
        end,
    },
    PersistenceCoordinator = { Commit = function() return true, "committed" end },
    Network = {
        SendSemanticIdentityResult = function(_, payload)
            sent[#sent + 1] = payload
            return true
        end,
        SendConversationRelationship = function() return true end,
    },
}

-- The knowledge API records the fact and returns the player-scoped projection.
-- The projection carries the same snapshot shape the server really ships.
PNC.NPCKnowledgeAPI = {
    DiscloseForPlayer = function(_, options)
        knowledgeRevision = knowledgeRevision + 1
        return {
            accepted = true,
            committed = true,
            requestID = options.requestID,
            npcID = options.npcID,
            topicID = options.topicID,
            revealed = { "identity.name" },
            failures = {},
        }, nil
    end,
    GetForPlayer = function(_, id)
        return {
            npcID = tostring(id),
            revision = knowledgeRevision,
            identity = { displayName = identityName },
            categories = {
                {
                    id = "identity",
                    descriptors = {
                        {
                            descriptorID = "identity.name",
                            category = "identity",
                            status = "confirmed",
                            value = identityName,
                            confidence = 1,
                        },
                    },
                },
            },
        }, nil
    end,
}

T.load("ProjectHoomans", "server", SERVER .. "PNC_PlayerKnowledgeCommands_Core.lua")
T.load("ProjectHoomans", "server", SERVER .. "PNC_PlayerKnowledgeCommands_Presentation.lua")
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticIdentityExchange.lua")
T.load("ProjectHoomans", "server", SERVER .. "PNC_PlayerKnowledgeCommands_Identity.lua")

local Commands = PNC.PlayerKnowledgeCommands
T.truthy(type(Commands.Internal.PresentationFor) == "function",
    "server presentation projection is available to the identity handler")

-- ---------------------------------------------------------------- client stubs

local clientSendClientCommand = nil
sendClientCommand = function(...) clientSendClientCommand = { ... } end
isServer = function() return false end
getSpecificPlayer = function() return {} end
sendServerCommand = function() end

PNC.Client = { Internal = {} }
PNC.Network = {
    ClientState = {
        npcKnowledge = {},
        npcPresentations = {},
        snapshots = {},
        pendingSemanticIdentity = { [npcID] = "identity_exchange:1" },
        playerContext = { characterUUID = "char_player" },
    },
}
PNC.Client.Internal.RegisterServerCommand = function(command, handler)
    registeredCommands[command] = handler
    return true
end
PNC.Const.CMD_NPC_KNOWLEDGE = "NPCKnowledge"
PNC.Const.CMD_NPC_PRESENTATION = "NPCPresentation"
PNC.Const.CMD_PLAYER_BOOTSTRAP = "PlayerBootstrap"
PNC.Const.CMD_KNOWLEDGE_DISCLOSURE = "KnowledgeDisclosure"
PNC.Const.CMD_KNOWLEDGE_DEBUG = "KnowledgeDebug"

T.load("ProjectHoomans", "client", CLIENT .. "Knowledge/PNC_NPCIdentityPresentation.lua")
-- The real knowledge router owns the shared presentation/knowledge receiver.
-- Loading it (instead of stubbing it) is what proves the identity result and the
-- nameplate read the same client record.
T.load("ProjectHoomans", "client",
    CLIENT .. "Networking/ClientCommandRouter/PNC_ClientCommandRouter_Knowledge.lua")
T.load("ProjectHoomans", "client",
    CLIENT .. "Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentity.lua")

local Identity = PNC.NPCIdentityPresentation
local ClientState = PNC.Network.ClientState

T.falsy(Identity.IsNameKnown(npcID),
    "spawned NPC name is unknown before the disclosure")
T.equal(Identity.GetName(npcID), "Unknown survivor",
    "unknown spawned NPC never leaks its transport name")

-- ------------------------------------------------------- authoritative exchange

local accepted, payload = Commands.HandleSemanticIdentity({}, {
    requestID = "identity_exchange:1",
    npcID = npcID,
    kind = "identity_claim",
    claimedName = "Psycho",
    conversationToken = "lease",
})

T.truthy(accepted, "truthful claim is accepted by the server handler")
T.truthy(payload and payload.accepted == true, "accepted result is returned")
T.equal(payload.responseKey,
    "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed",
    "reply carries the confirmed identity exchange key")
T.equal(payload.responseArgs[2], identityName,
    "reply formats the canonical NPC name")
T.truthy(type(payload.presentation) == "table",
    "accepted result carries the canonical identity projection")
T.equal(payload.presentation.state, "known",
    "carried projection is already known after the disclosure commit")
T.equal(payload.presentation.displayName, identityName,
    "carried projection exposes the learned name")

-- ------------------------------------------------------------------ client apply

local handler = registeredCommands["SemanticIdentityResult"]
T.truthy(type(handler) == "function",
    "client registers the semantic identity result handler")
handler(payload)

local knowledge = ClientState.npcKnowledge[npcID]
T.truthy(knowledge ~= nil,
    "identity claim mirrors knowledge into ClientState.npcKnowledge")
T.equal(ClientState.npcPresentations[npcID]
    and ClientState.npcPresentations[npcID].state, "known",
    "identity claim mirrors the known presentation state")
T.truthy(ClientState.identityDisclosureVerified[npcID]
    and ClientState.identityDisclosureVerified[npcID].verified == true,
    "verified disclosure marker is retained for presentation fallback")

-- These two assertions are the actual reported symptom: the SAME fact that the
-- portrait plate shows must switch the world nameplate on.
T.truthy(Identity.IsNameKnown(npcID),
    "nameplate identity gate sees the learned name immediately")
T.equal(Identity.GetName(npcID), identityName,
    "nameplate renders the learned name immediately")

T.equal(ClientState.identityDisclosurePending[npcID], nil,
    "knowledge mirror clears the pending disclosure marker")

T.finish("pnc_semantic_identity_knowledge_mirror_smoke")
