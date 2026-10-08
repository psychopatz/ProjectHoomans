-- Target-owned native NPC-knowledge restart fixture, phase two.
-- Read one normalized player-character/NPC note after a JVM restart.

local CHARACTER_UUID = "char_pzharness_npc_knowledge_restart"
local NPC_ID = "npc_pzharness_npc_knowledge_restart"
local ITEM_LIKE = "Base.TinCan"
local ITEM_DISLIKE = "Base.Axe"
local SOURCE_EVENT = "gift-native-restart"

PZHarnessNativeTest = function()
    local knowledge = PNC and PNC.NPCKnowledge or nil
    PZHarness.assertTrue(
        knowledge and knowledge.Loaded == true and knowledge.Registry
            and knowledge.Registry.byCharacter and knowledge.Get
            and knowledge.GetGiftPreference,
        "native NPCKnowledge was not loaded after the JVM restart"
    )

    local note = knowledge.Get(CHARACTER_UUID, NPC_ID)
    PZHarness.assertTrue(
        note and note.npcID == NPC_ID
            and note.giftPreferences
            and note.giftPreferences[ITEM_LIKE]
            and note.giftPreferences[ITEM_LIKE].disposition == "like"
            and note.giftPreferences[ITEM_LIKE].sourceType == "gift_reaction"
            and note.giftPreferences[ITEM_LIKE].sourceEventID == SOURCE_EVENT
            and note.giftPreferences[ITEM_LIKE].createdAt == 777
            and note.giftPreferences[ITEM_DISLIKE]
            and note.giftPreferences[ITEM_DISLIKE].disposition == "dislike",
        "native NPCKnowledge note did not survive restart"
    )
    local preference = knowledge.GetGiftPreference(
        CHARACTER_UUID,
        NPC_ID,
        ITEM_LIKE
    )
    PZHarness.assertTrue(
        preference and preference.fullType == ITEM_LIKE
            and preference.disposition == "like"
            and preference.sourceEventID == SOURCE_EVENT,
        "native NPCKnowledge preference did not survive restart"
    )
    PZHarness.assertTrue(
        knowledge.Dirty == false,
        "native NPCKnowledge was unexpectedly dirty after reload"
    )

    local raw = ModData.get("PNC_NPCKnowledge")
    local rawCharacter = raw and raw.byCharacter
        and raw.byCharacter[CHARACTER_UUID]
    local rawNote = rawCharacter and rawCharacter.byNPC
        and rawCharacter.byNPC[NPC_ID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.schemaVersion == 1
            and type(rawCharacter) == "table"
            and type(rawNote) == "table"
            and rawNote.npcID == NPC_ID
            and rawNote.giftPreferences[ITEM_LIKE].disposition == "like"
            and rawNote.giftPreferences[ITEM_DISLIKE].disposition == "dislike",
        "native NPCKnowledge ModData was not reloaded"
    )
end
