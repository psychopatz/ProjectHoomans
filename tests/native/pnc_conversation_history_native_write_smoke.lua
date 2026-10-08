-- Target-owned native conversation-history restart fixture, phase one.
-- Exercise a world-scoped entry without player or network state.

local SUBJECT_ID = "pzharness_native_history_restart"
local OUTCOME_ID = "outcome-native-restart"
local EXPECTED_KEY = "world|" .. SUBJECT_ID

PZHarnessNativeTest = function()
    local history = PNC and PNC.Conversation
        and PNC.Conversation.History or nil
    PZHarness.assertTrue(
        history and history.BuildKey and history.Commit
            and history.Get and history.Save and history.Load,
        "native ConversationHistory API was not available"
    )
    PZHarness.assertTrue(
        history and history.Loaded == true and history.Registry
            and history.Registry.entries,
        "native ConversationHistory was not loaded before the test"
    )
    PZHarness.assertEqual(
        history.MODDATA_KEY,
        "PNC_ConversationHistory",
        "native ConversationHistory ModData key was not stable"
    )

    local key = history.BuildKey("world", nil, nil, SUBJECT_ID)
    PZHarness.assertEqual(
        key,
        EXPECTED_KEY,
        "native world-scoped conversation key was not canonical"
    )
    local entry = history.Commit(
        SUBJECT_ID,
        { scope = "world" },
        { worldAgeHours = 42 },
        OUTCOME_ID
    )
    PZHarness.assertTrue(
        type(entry) == "table"
            and entry.useCount == 1
            and entry.lastUsedWorldHour == 42
            and entry.lastOutcomeID == OUTCOME_ID,
        "native ConversationHistory did not retain the committed entry"
    )
    local readBack, readKey = history.Get(
        SUBJECT_ID,
        { scope = "world" },
        {}
    )
    PZHarness.assertTrue(
        readKey == EXPECTED_KEY and readBack
            and readBack.useCount == 1,
        "native ConversationHistory did not resolve the world entry"
    )
    PZHarness.assertTrue(
        history.Dirty == true,
        "native ConversationHistory did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_conversation_history_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native conversation-history commit failed: "
            .. tostring(commitReason or committed)
    )
    local historyResult = commitDetails
        and commitDetails.results
        and commitDetails.results.conversationHistory
    PZHarness.assertTrue(
        historyResult and historyResult.changed == true,
        "native persistence coordinator did not save ConversationHistory"
    )
    PZHarness.assertTrue(
        history.Dirty == false,
        "native ConversationHistory remained dirty after commit"
    )

    local raw = ModData.get(history.MODDATA_KEY)
    local rawEntry = raw and raw.entries and raw.entries[EXPECTED_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.version == 1
            and type(rawEntry) == "table"
            and rawEntry.useCount == 1
            and rawEntry.lastOutcomeID == OUTCOME_ID,
        "native conversation-history ModData did not contain the entry"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native conversation-history OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_CONVERSATION_HISTORY_WRITE_ON_SAVE:" .. EXPECTED_KEY)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native conversation-history GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native conversation-history GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native conversation-history GameWindow.save did not trigger OnSave"
        )
    end
end
