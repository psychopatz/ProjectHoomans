local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local learned = false
local commitSucceeds = false
local disclosureCalls = 0
local commits = 0
local sent = { bootstrap = {}, presentation = {}, disclosure = {} }
local context = {
    accountKey = "sp_slot_0", characterUUID = "char_one",
    entityKey = "player:sp_slot_0:char_one", bindingRevision = 4,
}

PNC = {
    Core = { DeepCopy = copy, Now = function() return 1000 end },
    PlayerContext = { Resolve = function() return copy(context), "resolved" end },
    PlayerCharacters = { Registry = {
        migration = { status = "complete" },
        uuidAliases = { char_old = "char_one" },
    } },
    Registry = { Get = function(id)
        return id == "npc_doyle" and {
            id = id, name = "Doyle Wild",
            affiliation = { factionID = "pinecrest" },
        } or nil
    end },
    Identity = { GetCharacterSummary = function(record)
        return { displayName = record.name }
    end },
    Factions = { GetPresentation = function()
        return { name = "Pinecrest Settlement" }
    end },
    NPCKnowledge = {
        Registry = { revision = 9 },
        GetDescriptor = function()
            return learned and { value = "Doyle Wild" } or nil
        end,
        DiscoverTopicForPlayer = function()
            disclosureCalls = disclosureCalls + 1
            learned = true
            return { revealed = { "identity.name" }, failures = {} }
        end,
        BuildPlayerSnapshotForPlayer = function(_, npcID)
            return {
                npcID = npcID, revision = learned and 2 or 1,
                identity = { displayName = "Doyle Wild",
                    archetypeLabel = "Survivor" },
                categories = learned and { { descriptors = {
                    { descriptorID = "identity.name", status = "confirmed",
                        value = "Doyle Wild" },
                } } } or {},
            }
        end,
        BuildKnownSnapshotsForPlayer = function(_, requestedNPCIDs)
            local output = {}
            if type(requestedNPCIDs) == "table" then
                for index = 1, #requestedNPCIDs do
                    output[index] = {
                        npcID = requestedNPCIDs[index], revision = 1,
                        identity = { displayName = "RAW " .. index },
                        categories = {},
                    }
                end
                return output
            end
            for index = 1, 65 do
                output[index] = {
                    npcID = "npc_" .. index, revision = 1,
                    identity = { displayName = "RAW " .. index },
                    categories = {},
                }
            end
            return output
        end,
    },
    PersistenceCoordinator = { Commit = function()
        commits = commits + 1
        return commitSucceeds, commitSucceeds and "committed" or "disk_failed"
    end },
    Network = {
        SendPlayerBootstrap = function(_, payload)
            sent.bootstrap[#sent.bootstrap + 1] = copy(payload)
        end,
        SendNPCPresentation = function(_, payload)
            sent.presentation[#sent.presentation + 1] = copy(payload)
        end,
        SendKnowledgeDisclosure = function(_, payload)
            sent.disclosure[#sent.disclosure + 1] = copy(payload)
        end,
    },
}

T.load(SERVER .. "Knowledge/PNC_PlayerKnowledgeCommands.lua")
local Commands = PNC.PlayerKnowledgeCommands

local unknown = Commands.HandlePresentation({}, {
    requestID = "present:1", npcID = "npc_doyle",
})
T.equal(unknown.state, "unknown", "unknown projection is authoritative")
T.equal(unknown.canAskName, true, "unknown projection allows name question")
T.equal(unknown.snapshot.identity.displayName, nil,
    "unknown projection does not leak raw NPC name")

local failed = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
T.equal(failed.success, false, "failed commit rejects disclosure")
T.equal(failed.responseText, nil, "failed commit cannot display introduction")
T.equal(disclosureCalls, 1, "failed attempt records fact once")
local pending = Commands.HandlePresentation({}, {
    requestID = "present:2", npcID = "npc_doyle",
})
T.equal(pending.state, "error", "dirty disclosure stays gated")
T.equal(pending.reason, "knowledge_commit_pending", "pending commit is diagnosable")

commitSucceeds = true
local retried = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
T.truthy(retried.success, "retry succeeds after durable commit")
T.equal(disclosureCalls, 1, "retry does not duplicate learned evidence")
T.equal(retried.responseText,
    "I'm Doyle Wild. I'm with Pinecrest Settlement.",
    "response text is supplied by authority after commit")
T.equal(retried.presentation.state, "known", "committed projection is known")

local replay = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
T.truthy(replay.success and replay.replayed == true,
    "successful request ID is idempotently replayed")
T.equal(commits, 2, "replay does not perform a third commit")

sent.bootstrap = {}
local bootstrap = Commands.HandleBootstrap({}, { requestID = "bootstrap:1" })
T.equal(#sent.bootstrap, 3, "large bootstrap is chunked")
T.equal(sent.bootstrap[1].chunkIndex, 1, "first bootstrap chunk index")
T.equal(sent.bootstrap[3].chunkCount, 3, "bootstrap chunk count")
T.equal(sent.bootstrap[3].state, "known", "last bootstrap chunk completes")
T.equal(sent.bootstrap[1].snapshots[1].identity.displayName, nil,
    "bootstrap also strips undisclosed raw names")
T.equal(bootstrap.context.characterUUID, "char_one", "bootstrap binds context")

sent.bootstrap = {}
local scoped = Commands.HandleBootstrap({}, {
    requestID = "bootstrap:live",
    scope = "live",
    npcIDs = { "npc_live_1", "npc_live_2" },
})
T.equal(#sent.bootstrap, 1, "live bootstrap remains one batched response")
T.equal(#scoped.snapshots, 2, "live bootstrap returns only requested NPCs")
T.equal(scoped.snapshots[1].npcID, "npc_live_1",
    "live bootstrap preserves requested identity")
T.equal(scoped.scope, "live", "live bootstrap echoes merge scope")

sent.bootstrap = {}
local interested = Commands.HandleBootstrap({}, {
    requestID = "bootstrap:interest",
    scope = "interest",
    npcIDs = { "npc_live_2" },
})
T.equal(#sent.bootstrap, 1, "interest bootstrap remains batched")
T.equal(#interested.snapshots, 1,
    "interest bootstrap returns only consumer-requested NPCs")
T.equal(interested.scope, "interest",
    "interest bootstrap echoes non-destructive merge scope")

sent.bootstrap = {}
local malformedInterest = Commands.HandleBootstrap({}, {
    requestID = "bootstrap:interest:malformed",
    scope = "interest",
})
T.equal(#malformedInterest.snapshots, 0,
    "malformed scoped request cannot fall back to every known NPC")
T.finish("pnc_player_knowledge_commands_smoke")

T.finish("pnc_player_knowledge_commands_smoke")
