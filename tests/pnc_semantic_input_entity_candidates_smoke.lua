local T = require "tests/support/test"
T.addPackagePaths()

local originalPNC = PNC
PNC = {
    Network = {
        ClientState = {
            snapshots = {
                known = { name = "Private snapshot label" },
                verified = {
                    name = "Unverified snapshot label",
                    verifiedName = "Verified snapshot name",
                },
                unknown = { name = "Unknown snapshot label" },
                callbackError = { name = "Callback error label" },
            },
            npcPresentations = {
                known = { state = "known", displayName = "Known snapshot" },
                verified = { state = "unknown" },
                unknown = { state = "unknown" },
                callbackError = { state = "unknown" },
            },
        },
    },
    NPCIdentityPresentation = {
        IsNameKnown = function(snapshot)
            if snapshot.name == "Callback error label" then
                error("identity service unavailable")
            end
            return snapshot.verifiedName ~= nil
        end,
        GetName = function(snapshot)
            return snapshot.verifiedName
                or snapshot.name == "Private snapshot label"
                    and "Identity service name" or nil
        end,
    },
}

local EntityCandidates = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_EntityCandidates.lua"
)

local source = {
    semanticEntityCandidates = {
        { id = "npc:alice", name = "Explicit Alice", source = "authored" },
        { id = "explicit-only", name = "Explicit Entity" },
        { id = "npc:alice", name = "Duplicate Alice" },
        { id = "", name = "Invalid Entity" },
    },
    identityState = "known",
    npcID = "npc:alice",
    npcName = "Alice",
    npcFirstName = "Alice",
    npcFullName = "Alice Example",
    playerNameKnown = true,
    playerName = "Player",
    playerFirstName = "Player",
    characterUUID = "player-guid",
}
local candidates = EntityCandidates.Build({
    spec = { npcID = "npc:alice" },
    session = { characterUUID = "player-guid" },
}, source)

local function find(id)
    for index = 1, #candidates do
        if candidates[index].id == id then return candidates[index] end
    end
    return nil
end

T.equal(find("npc:alice").name, "Explicit Alice",
    "explicit candidate remains first when its ID duplicates conversation NPC")
T.equal(find("explicit-only").name, "Explicit Entity",
    "explicit semantic entities are preserved")
T.equal(find("player:player-guid").entityType, "player",
    "known player identity uses the bound character UUID")
T.equal(find("known").name, "Identity service name",
    "known presentations use the identity gateway name")
T.equal(find("verified").name, "Verified snapshot name",
    "snapshot names require identity gateway confirmation")
T.equal(find("unknown"), nil,
    "unverified snapshot names are excluded")
T.equal(find("callbackError"), nil,
    "identity gateway failure does not expose a snapshot name")
T.equal(find(""), nil,
    "empty candidate IDs are rejected")

local snapshots = {}
local presentations = {}
for index = 1, 70 do
    local id = "known-" .. tostring(index)
    snapshots[id] = { name = "Person " .. tostring(index) }
    presentations[id] = {
        state = "known",
        displayName = "Known Person " .. tostring(index),
    }
end
PNC.Network.ClientState.snapshots = snapshots
PNC.Network.ClientState.npcPresentations = presentations
local bounded = EntityCandidates.Build({}, {})
local snapshotCandidates = 0
for index = 1, #bounded do
    if bounded[index].source == "known_snapshot" then
        snapshotCandidates = snapshotCandidates + 1
    end
end
T.equal(snapshotCandidates, 64,
    "ambient known snapshot candidates remain capped at 64")

PNC = originalPNC
T.finish("pnc_semantic_input_entity_candidates_smoke")
