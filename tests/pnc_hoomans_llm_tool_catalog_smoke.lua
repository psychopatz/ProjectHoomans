local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common_client" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "common" },
})

PsychopatzCore = {
    Bridge = {
        GetToolCatalog = function()
            return {
                catalog_id = "catalog-1",
                tools = {
                    { id = "projecthoomans.llm:social_react" },
                    { id = "projecthoomans.llm:ask_name" },
                    { id = "projecthoomans.llm:order_follow" },
                },
            }
        end,
    },
    Conversation = {
        Message = {
            GetSaveID = function() return "save-1" end,
            GetGameDay = function() return 3 end,
        },
        Text = { Resolve = function() return "" end },
    },
}
PNC = {
    Network = { ClientState = { playerContext = { characterUUID = "player-1" } } },
    CompanionCommands = {
        List = function()
            return { { id = "follow", clientOnly = false } }
        end,
    },
}
getCurrentSaveName = function() return "Save One" end
getTimeInMillis = function() return 1000 end

T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_HoomansLLMContext.lua")

local Context = PNC.HoomansLLM.Context
local view = {
    spec = {
        npcID = "npc-1",
        context = {
            npcName = "Harley", playerName = "Alex", entry = { id = "npc-1" },
        },
    },
    session = { participants = {}, llmSessionID = "conversation-1" },
    historyPart = { messages = {} },
}

local context = Context.Build(view, "hello")
T.equal(context.available_tools, nil, "catalog mode avoids repeated full schemas")
T.equal(context.tool_catalog_id, "catalog-1", "catalog ID missing")
T.equal(#context.available_tool_ids, 3, "allowed tool IDs missing")
T.equal(context.available_tool_ids[2], "projecthoomans.llm:ask_name",
    "identity tool ID missing")
T.equal(context.available_tool_ids[3], "projecthoomans.llm:order_follow",
    "command tool ID missing")

T.finish("pnc_hoomans_llm_tool_catalog_smoke")
