-- Target-owned native research restart fixture, phase two.
-- Read the global per-colony research state after a fresh JVM loads ModData.

local COLONY_ID = "pzharness_native_research_restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.ResearchRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Loaded == true,
        "native ResearchRepository was not loaded after the JVM restart"
    )

    local state = repository.Get(COLONY_ID, false)
    PZHarness.assertTrue(
        type(state) == "table",
        "native ResearchRepository did not reload the colony state"
    )
    PZHarness.assertEqual(
        state and state.colonyId,
        COLONY_ID,
        "native research colony identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        state and state.knowledgeRevision,
        7,
        "native research knowledge revision did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        type(state.learnedRecipeIds) == "table"
            and #state.learnedRecipeIds == 2
            and state.learnedRecipeIds[1] == 42
            and state.learnedRecipeIds[2] == 1042,
        "native research recipe IDs were not normalized after reload"
    )
    PZHarness.assertTrue(
        type(state.learnedTechnologyIds) == "table"
            and #state.learnedTechnologyIds == 2
            and state.learnedTechnologyIds[1] == "agriculture"
            and state.learnedTechnologyIds[2] == "metalworking",
        "native research technology IDs were not normalized after reload"
    )
    PZHarness.assertTrue(
        repository.Runtime[COLONY_ID]
            and repository.Runtime[COLONY_ID].learnedRecipeSet[1042] == true
            and repository.Runtime[COLONY_ID]
                .learnedTechnologySet.metalworking == true,
        "native research runtime indexes were not rebuilt after reload"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawState = raw and raw.byColony and raw.byColony[COLONY_ID]
    PZHarness.assertTrue(
        type(rawState) == "table"
            and rawState.colonyId == COLONY_ID
            and rawState.knowledgeRevision == 7,
        "native research ModData was not reloaded"
    )
end
