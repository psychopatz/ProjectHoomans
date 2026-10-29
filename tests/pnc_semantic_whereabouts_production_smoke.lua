-- Production semantic whereabouts path:
-- question -> cognition request -> authoritative live fact -> response
-- catalog/realization. The test never calls GetSemanticContext.
local T = require "tests/support/test"
T.addPackagePaths()

local worldAge = 10
local requestClock = 1000
local playerFactionID = "home-faction"
local communities = {
    home = {
        id = "home",
        name = "Home A",
        status = "active",
        factionID = "home-faction",
        home = { x = 0, y = 0, z = 0 },
    },
    riverside = {
        id = "riverside",
        name = "Riverside Collective",
        status = "active",
        factionID = "riverside-faction",
        home = { x = 100, y = -100, z = 0 },
    },
}

PsychopatzCore = {}
PNC = {
    Core = {
        Now = function() return requestClock end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
    },
    Semantics = {},
    Network = { ClientState = {} },
    Registry = { Data = {} },
    ConversationScene = {},
    Communities = {},
    Factions = {},
}

local player = {
    getUsername = function() return "Alex" end,
}
getSpecificPlayer = function() return player end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldAge end,
    }
end

function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end

function PNC.ConversationScene.ValidateConversationLease(
    record, _, token
)
    local lease = record and record.runtime
        and record.runtime.conversationLease or nil
    if lease and tostring(lease.token) == tostring(token or "") then
        return true, lease
    end
    return false, "invalid_conversation"
end

function PNC.Communities.Get(id)
    return communities[tostring(id)]
end

function PNC.Factions.GetMembers(factionID)
    if tostring(factionID) ~= "home-faction" then return {} end
    return {
        {
            npcID = "npc-trader",
            alive = true,
            affiliation = {
                factionID = "home-faction",
                communityID = "home",
                role = "trader",
            },
        },
    }
end

function PNC.Factions.GetPlayerFaction()
    return playerFactionID and { id = playerFactionID } or nil
end

PNC.CommunityExcursionService = {
    Get = function(factionID)
        if tostring(factionID) ~= "home-faction" then return nil end
        return {
            homeCommunityID = "home",
            participants = { "npc-trader" },
            revision = 7,
        }
    end,
    GetSocialStatus = function(factionID, viewer)
        if tostring(factionID) ~= "home-faction" then
            return nil, "faction_not_found"
        end
        local known = type(viewer) == "table"
            and tostring(viewer.factionID or "") == "home-faction"
        return {
            status = "away",
            phase = "VISITING",
            state = "VISITING",
            locationState = "visiting",
            publicReason = "trading run",
            destinationKnown = known,
            destinationCommunityID = known and "riverside" or nil,
            expectedReturnKnown = known,
            expectedReturnAt = known and 40 or nil,
            revision = 7,
        }
    end,
}

local Semantic = T.load(
    "PsychopatzCore", "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "PsychopatzCore", "common",
    "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Conversation/Memory/PNC_ConversationMemory.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)
local Service = T.load(
    "ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCognitionService.lua"
)
T.load(
    "ProjectHoomans", "server",
    "PNC/Communities/PNC_CommunityPlaceProjection.lua"
)
T.load(
    "ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCommunityRoleWhereabouts.lua"
)
local Cognition = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticCognitionClient.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueFacts.lua"
)
T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueCognitionFactSource.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueLocalResponse.lua"
)
local Policy = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local ResponseAdapter = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses.lua"
)

PNC.Const = {
    MODULE = "PNC",
    CMD_SEMANTIC_COGNITION_REQUEST = "RequestSemanticCognition",
}
PNC.Client = { Internal = {} }
T.load(
    "ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_Internal.lua"
)
local ClientRequest = T.load(
    "ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_SemanticCognition.lua"
)

local sent
PNC.Network.SendSemanticCognition = function(
    _, projection, reason, requestID, npcID, targetID
)
    sent = {
        projection = projection,
        reason = reason,
        requestID = requestID,
        npcID = npcID,
        targetID = targetID,
    }
    return Cognition.ApplyPayload({
        projection = projection,
        reason = reason,
        requestID = requestID,
        npcID = npcID,
        targetID = targetID,
    })
end

PNC.Registry.Data["npc-speaker"] = {
    id = "npc-speaker",
    alive = true,
    affiliation = { factionID = "home-faction", communityID = "home" },
    runtime = { conversationLease = { token = "lease:whereabouts" } },
}

Cognition.Reset()

local accepted, reason = ClientRequest.RequestSemanticCognition(
    "npc-speaker",
    {
        subject = "COMMUNITY_ROLE_WHEREABOUTS",
        targetID = "trader",
        conversationToken = "lease:whereabouts",
    }
)
T.equal(accepted, true,
    "production cognition request reaches the Hoomans authority")
T.equal(reason, "dispatched",
    "production cognition request keeps its dispatch status")
T.truthy(sent and sent.projection,
    "authority sends a live cognition projection")

local function produce(question)
    local ir = Semantic.Parser.Parse(question)
    local context = {
        npcID = "npc-speaker",
        llmEnabled = false,
        worldContext = { worldAgeHours = worldAge },
    }
    local resolved, fact = PNC.Semantics.DialogueFacts.Annotate(
        ir, nil, context)
    local decision = Policy.Decide(resolved, nil, context)
    local payload = ResponseAdapter.Payload(decision, {
        npcID = context.npcID,
        worldContext = context.worldContext,
        dialogueIR = resolved,
        dialogueDecision = decision,
    })
    return resolved, fact, decision, payload
end

local variants = {
    "Where is your trader?",
    "Where's the trader?",
    "Do you know where the trader went?",
}
for index = 1, #variants do
    local ir = Semantic.Parser.Parse(variants[index])
    T.equal(ir and ir.subject, "COMMUNITY_ROLE_WHEREABOUTS",
        "natural trader whereabouts question parses as a generic role fact")
    T.equal(ir and ir.target and ir.target.role, "trader",
        "natural trader whereabouts question resolves the trader role")
end

local resolved, fact, decision, payload = produce("Where is your trader?")
T.equal(fact.status, "known",
    "production fact resolver consumes the live Hoomans projection")
T.equal(fact.provider, "client_npc_cognition_projection",
    "production question uses the cognition fact provider")
T.truthy(string.find(payload.text or payload.fallback or "",
    "Riverside Collective", 1, true),
    "realized production response contains the authoritative destination name")
T.truthy(string.find(string.lower(payload.text or payload.fallback or ""),
    "northeast", 1, true),
    "realized production response contains the Core spatial direction")
T.truthy(string.find(string.lower(payload.text or payload.fallback or ""),
    "tomorrow", 1, true),
    "realized production response contains the grounded ETA")
T.equal(decision.response.dialogueAct, "FACT_ANSWER",
    "whereabouts response keeps the fact-answer dialogue act")

-- The live provider is re-evaluated on later questions. A rename and
-- relocation therefore affect later output without rewriting excursion state.
worldAge = 11
requestClock = requestClock + 1001
communities.riverside.name = "New Riverside"
communities.riverside.home = { x = -100, y = 100, z = 0 }
accepted = ClientRequest.RequestSemanticCognition(
    "npc-speaker",
    {
        subject = "COMMUNITY_ROLE_WHEREABOUTS",
        targetID = "trader",
        conversationToken = "lease:whereabouts",
    }
)
T.equal(accepted, true,
    "later whereabouts questions refresh the live projection")
_, fact, _, payload = produce("Where is your trader?")
T.equal(fact.value.destinationName, "New Riverside",
    "settlement rename is resolved from authoritative community state")
T.truthy(string.find(string.lower(payload.text or payload.fallback or ""),
    "southwest", 1, true),
    "settlement relocation changes the later derived direction")

-- An outsider sees the public away state but not the privileged route, name,
-- direction, or ETA. This uses the social-status contract, not a second
-- semantic privacy table.
playerFactionID = "outsider-faction"
worldAge = 12
requestClock = requestClock + 1001
accepted = ClientRequest.RequestSemanticCognition(
    "npc-speaker",
    {
        subject = "COMMUNITY_ROLE_WHEREABOUTS",
        targetID = "trader",
        conversationToken = "lease:whereabouts",
    }
)
T.equal(accepted, true,
    "outsider whereabouts request remains readable")
resolved, fact, _, payload = produce("Where is your trader?")
T.equal(fact.value.destinationName, nil,
    "outsider projection omits the privileged destination name")
T.equal(fact.value.directionLabel, nil,
    "outsider projection omits the privileged route direction")
T.equal(fact.value.expectedReturnAt, nil,
    "outsider projection omits the privileged ETA")
local outsiderText = string.lower(payload.text or payload.fallback or "")
T.falsy(string.find(outsiderText, "new riverside", 1, true),
    "outsider realization does not leak the destination name")
T.falsy(string.find(outsiderText, "southwest", 1, true),
    "outsider realization does not leak the route direction")

T.finish("pnc_semantic_whereabouts_production_smoke")
