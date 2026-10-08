-- Target-owned native conversation-history restart fixture, phase two.
-- Read a world-scoped entry after a fresh JVM loads ModData.

local SUBJECT_ID = "pzharness_native_history_restart"
local OUTCOME_ID = "outcome-native-restart"
local EXPECTED_KEY = "world|" .. SUBJECT_ID

PZHarnessNativeTest = function()
    local history = PNC and PNC.Conversation
        and PNC.Conversation.History or nil
    PZHarness.assertTrue(
        history and history.Get and history.Loaded == true
            and history.Registry and history.Registry.entries,
        "native ConversationHistory was not loaded after the JVM restart"
    )
    PZHarness.assertEqual(
        history.MODDATA_KEY,
        "PNC_ConversationHistory",
        "native ConversationHistory ModData key was not available after restart"
    )

    local entry, key = history.Get(
        SUBJECT_ID,
        { scope = "world" },
        {}
    )
    PZHarness.assertTrue(
        key == EXPECTED_KEY and type(entry) == "table",
        "native ConversationHistory did not reload the world entry"
    )
    PZHarness.assertEqual(
        entry.useCount,
        1,
        "native conversation history use count did not survive restart"
    )
    PZHarness.assertEqual(
        entry.lastUsedWorldHour,
        42,
        "native conversation history world hour did not survive restart"
    )
    PZHarness.assertEqual(
        entry.lastOutcomeID,
        OUTCOME_ID,
        "native conversation history outcome did not survive restart"
    )
    PZHarness.assertTrue(
        history.Dirty == false,
        "native ConversationHistory was unexpectedly dirty after reload"
    )

    local raw = ModData.get(history.MODDATA_KEY)
    local rawEntry = raw and raw.entries and raw.entries[EXPECTED_KEY]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.version == 1
            and type(rawEntry) == "table"
            and rawEntry.useCount == 1
            and rawEntry.lastOutcomeID == OUTCOME_ID,
        "native conversation-history ModData was not reloaded"
    )
end
