local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Adapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCommandAdapter.lua"
)

local commandCalls = {}
PNC.Client = {
    SendCompanionCommand = function(commandID, npcID, scope, context)
        commandCalls[#commandCalls + 1] = {
            commandID = commandID,
            npcID = npcID,
            scope = scope,
            context = context,
        }
        return true, "network_queued", { npcID }
    end,
}

local follow = Adapter.Dispatch({ action = "FOLLOW" }, {
    npcID = "npc-alice",
    dialogueID = "dialogue-1",
})
T.equal(follow.status, "accepted", "follow uses the existing command path")
T.equal(commandCalls[1].commandID, "follow", "follow command mapping")
T.equal(commandCalls[1].npcID, "npc-alice", "conversation target is preserved")
T.equal(commandCalls[1].context.origin, "semantic_dialogue",
    "semantic source is visible to the authoritative adapter")

local home = Adapter.Resolve({
    action = "GO",
    destination = { category = "HOME" },
})
T.equal(home, "return_home", "go home reuses the existing home command")

local negated = Adapter.Dispatch({
    action = "TAKE",
    modifiers = { negated = true },
}, { npcID = "npc-alice" })
T.equal(negated.status, "skipped", "negated actions never dispatch")

local fetch = Adapter.Dispatch({
    action = "FETCH",
    object = { category = "WATER" },
}, { npcID = "npc-alice" })
T.equal(fetch.status, "unmapped",
    "task requests wait for a dedicated downstream task adapter")
T.equal(#commandCalls, 1, "unmapped actions do not call gameplay transport")

T.finish("pnc_semantic_command_adapter_smoke")
