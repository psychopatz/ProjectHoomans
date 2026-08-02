local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end
local function truth(value, label) equal(value == true, true, label) end
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
        BuildKnownSnapshotsForPlayer = function()
            local output = {}
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

dofile(SERVER .. "PNC_PlayerKnowledgeCommands.lua")
local Commands = PNC.PlayerKnowledgeCommands

local unknown = Commands.HandlePresentation({}, {
    requestID = "present:1", npcID = "npc_doyle",
})
equal(unknown.state, "unknown", "unknown projection is authoritative")
equal(unknown.canAskName, true, "unknown projection allows name question")
equal(unknown.snapshot.identity.displayName, nil,
    "unknown projection does not leak raw NPC name")

local failed = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
equal(failed.success, false, "failed commit rejects disclosure")
equal(failed.responseText, nil, "failed commit cannot display introduction")
equal(disclosureCalls, 1, "failed attempt records fact once")
local pending = Commands.HandlePresentation({}, {
    requestID = "present:2", npcID = "npc_doyle",
})
equal(pending.state, "error", "dirty disclosure stays gated")
equal(pending.reason, "knowledge_commit_pending", "pending commit is diagnosable")

commitSucceeds = true
local retried = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
truth(retried.success, "retry succeeds after durable commit")
equal(disclosureCalls, 1, "retry does not duplicate learned evidence")
equal(retried.responseText,
    "I'm Doyle Wild. I'm with Pinecrest Settlement.",
    "response text is supplied by authority after commit")
equal(retried.presentation.state, "known", "committed projection is known")

local replay = Commands.HandleDisclosure({}, {
    requestID = "disclose:1", npcID = "npc_doyle", topicID = "identity_name",
})
truth(replay.success and replay.replayed == true,
    "successful request ID is idempotently replayed")
equal(commits, 2, "replay does not perform a third commit")

sent.bootstrap = {}
local bootstrap = Commands.HandleBootstrap({}, { requestID = "bootstrap:1" })
equal(#sent.bootstrap, 3, "large bootstrap is chunked")
equal(sent.bootstrap[1].chunkIndex, 1, "first bootstrap chunk index")
equal(sent.bootstrap[3].chunkCount, 3, "bootstrap chunk count")
equal(sent.bootstrap[3].state, "known", "last bootstrap chunk completes")
equal(sent.bootstrap[1].snapshots[1].identity.displayName, nil,
    "bootstrap also strips undisclosed raw names")
equal(bootstrap.context.characterUUID, "char_one", "bootstrap binds context")

print("pnc_player_knowledge_commands_smoke: ok")
