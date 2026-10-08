-- Target-owned native research restart fixture, phase one.
-- Exercise the global per-colony research repository through the coordinator.

local COLONY_ID = "pzharness_native_research_restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.ResearchRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Save
            and repository.Load and repository.MarkDirty,
        "native ResearchRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true,
        "native ResearchRepository was not loaded before the test"
    )
    PZHarness.assertTrue(
        repository and repository.MODDATA_KEY,
        "native ResearchRepository ModData key was not available"
    )

    local state = repository.Get(COLONY_ID, true)
    PZHarness.assertTrue(
        type(state) == "table" and state.colonyId == COLONY_ID,
        "native ResearchRepository did not create the colony state"
    )
    state.learnedRecipeIds = { 1042, 42, 1042 }
    state.learnedTechnologyIds = {
        "metalworking",
        "agriculture",
        "metalworking",
    }
    state.knowledgeRevision = 7
    repository.RebuildRuntime()
    repository.MarkDirty()
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native ResearchRepository did not retain its dirty state"
    )
    PZHarness.assertTrue(
        repository.Runtime[COLONY_ID]
            and repository.Runtime[COLONY_ID].learnedRecipeSet[42] == true
            and repository.Runtime[COLONY_ID]
                .learnedTechnologySet.agriculture == true,
        "native ResearchRepository runtime indexes were not rebuilt"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_research_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native research commit failed: "
            .. tostring(commitReason or committed)
    )
    local researchResult = commitDetails
        and commitDetails.results
        and commitDetails.results.research
    PZHarness.assertTrue(
        researchResult and researchResult.changed == true,
        "native persistence coordinator did not save ResearchRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native ResearchRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawState = raw and raw.byColony and raw.byColony[COLONY_ID]
    PZHarness.assertTrue(
        type(rawState) == "table"
            and rawState.colonyId == COLONY_ID
            and rawState.knowledgeRevision == 7
            and type(rawState.learnedRecipeIds) == "table"
            and type(rawState.learnedTechnologyIds) == "table",
        "native research ModData did not contain the committed state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native research OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RESEARCH_WRITE_ON_SAVE:" .. COLONY_ID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native research GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native research GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native research GameWindow.save did not trigger OnSave"
        )
    end
end
