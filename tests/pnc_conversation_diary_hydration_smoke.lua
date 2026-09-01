local T = require "tests/support/test"

T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")

local player = {
    getUsername = function() return "player-one" end,
}

PNC = {
    Core = { Now = function() return 500 end },
    Network = {
        ClientState = {
            snapshots = {
                ["npc-one"] = { id = "npc-one", name = "Mara" },
            },
        },
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
}
getSpecificPlayer = function() return player end

T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua")
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationDiary.lua")

local Diary = PNC.Conversation.Diary
local state = PNC.Network.ClientState

T.truthy(Diary.Hydrate("npc-one", {
    {
        eventID = "conversation:vanilla_emote:one",
        kind = "player_emote",
        playerFlavorID = "vanilla_emote_wavehi",
        npcFlavorID = "vanilla_emote_wavehi_npc_warm",
        interactionType = "player_emote_wavehi",
        delta = { approval = 2, respect = 0, familiarity = 1 },
    },
}, 4), "persisted diary hydrates")
T.equal(#Diary.Get("npc-one"), 1,
    "hydration restores the persisted interaction row")
T.truthy(Diary.Get("npc-one")[1].playerText,
    "hydration resolves persisted player flavor")
T.truthy(Diary.Get("npc-one")[1].npcText,
    "hydration resolves persisted NPC flavor")
T.equal(state.conversationDiaryRevisions["npc-one"], 4,
    "hydration records the authoritative interaction revision")

local previous = Diary.Get("npc-one")[1].playerText
T.falsy(Diary.Hydrate("npc-one", {}, 3),
    "stale diary hydration is rejected")
T.equal(Diary.Get("npc-one")[1].playerText, previous,
    "stale hydration cannot erase newer interaction history")

return T.finish("pnc_conversation_diary_hydration_smoke")
