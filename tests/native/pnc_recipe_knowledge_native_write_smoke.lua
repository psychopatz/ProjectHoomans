-- Target-owned native recipe-knowledge restart fixture, phase one.
-- Exercise the global recipe-ID repository through the commit coordinator.

local RECIPE_KEY = "PZHarness.Native.Restart.Recipe"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.KnowledgeRepository or nil
    local registry = PNC and PNC.RecipeKnowledgeRegistry or nil
    PZHarness.assertTrue(
        repository and repository.GetOrCreateId,
        "native KnowledgeRepository API was not available"
    )
    PZHarness.assertTrue(
        registry and registry.Queries and registry.Queries.GetKey,
        "native RecipeKnowledgeRegistry API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true,
        "native KnowledgeRepository was not loaded before the test"
    )

    local recipeID, created = repository.GetOrCreateId(RECIPE_KEY)
    PZHarness.assertTrue(
        type(recipeID) == "number" and created == true,
        "native KnowledgeRepository did not create the recipe identity"
    )
    PZHarness.assertEqual(
        registry.Queries.GetKey(recipeID),
        RECIPE_KEY,
        "native recipe registry did not retain the created key"
    )
    PZHarness.assertEqual(
        registry.Queries.GetId(RECIPE_KEY),
        recipeID,
        "native recipe registry reverse index did not resolve the key"
    )
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native KnowledgeRepository did not retain its dirty state"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_recipe_knowledge_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native recipe-knowledge commit failed: "
            .. tostring(commitReason or committed)
    )
    local knowledgeResult = commitDetails
        and commitDetails.results
        and commitDetails.results.recipeKnowledge
    PZHarness.assertTrue(
        knowledgeResult and knowledgeResult.changed == true,
        "native persistence coordinator did not save KnowledgeRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native KnowledgeRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local persistedKey = raw
        and raw.idToKey
        and (raw.idToKey[recipeID] or raw.idToKey[tostring(recipeID)])
    PZHarness.assertEqual(
        persistedKey,
        RECIPE_KEY,
        "native recipe-knowledge ModData did not contain the created key"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native recipe-knowledge OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_RECIPE_KNOWLEDGE_WRITE_ON_SAVE:" .. RECIPE_KEY)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native recipe-knowledge GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native recipe-knowledge GameWindow.save failed: "
                .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native recipe-knowledge GameWindow.save did not trigger OnSave"
        )
    end
end
