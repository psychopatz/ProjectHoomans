-- Target-owned native NPC-knowledge restart fixture, phase one.
-- Exercise one player-character/NPC knowledge note without live players,
-- NPC spawning, or network disclosure.

local CHARACTER_UUID = "char_pzharness_npc_knowledge_restart"
local NPC_ID = "npc_pzharness_npc_knowledge_restart"
local ITEM_LIKE = "Base.TinCan"
local ITEM_DISLIKE = "Base.Axe"
local SOURCE_EVENT = "gift-native-restart"

PZHarnessNativeTest = function()
    local knowledge = PNC and PNC.NPCKnowledge or nil
    PZHarness.assertTrue(
        knowledge and knowledge.Load and knowledge.Save
            and knowledge.Get and knowledge.GetGiftPreference
            and knowledge.RecordGiftPreferences,
        "native NPCKnowledge API was not available"
    )
    PZHarness.assertTrue(
        knowledge.Loaded == true and knowledge.Registry
            and knowledge.Registry.byCharacter,
        "native NPCKnowledge was not loaded before the test"
    )
    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )

    local recorded, recordReason = knowledge.RecordGiftPreferences(
        CHARACTER_UUID,
        NPC_ID,
        {
            [ITEM_LIKE] = "like",
            [ITEM_DISLIKE] = "dislike",
        },
        "gift_reaction",
        SOURCE_EVENT,
        777
    )
    PZHarness.assertTrue(
        recorded == true,
        "native NPCKnowledge gift preferences were not recorded: "
            .. tostring(recordReason)
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
        "native NPCKnowledge note was not normalized"
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
        "native NPCKnowledge preference lookup failed"
    )
    PZHarness.assertTrue(
        knowledge.Dirty == true,
        "native NPCKnowledge did not retain its dirty state"
    )

    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_npc_knowledge_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native NPCKnowledge commit failed: "
            .. tostring(commitReason or committed)
    )
    local knowledgeResult = commitDetails
        and commitDetails.results
        and commitDetails.results.knowledge
    PZHarness.assertTrue(
        knowledgeResult and knowledgeResult.changed == true,
        "native persistence coordinator did not save NPCKnowledge"
    )
    PZHarness.assertTrue(
        knowledge.Dirty == false,
        "native NPCKnowledge remained dirty after commit"
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
        "native NPCKnowledge ModData did not contain the note"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native NPCKnowledge OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_NPC_KNOWLEDGE_WRITE_ON_SAVE:"
                .. CHARACTER_UUID .. "|" .. NPC_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native NPCKnowledge GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native NPCKnowledge GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native NPCKnowledge GameWindow.save did not trigger OnSave"
        )
    end
end
