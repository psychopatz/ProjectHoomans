-- Target-owned native recipe-knowledge restart fixture, phase two.
-- Read the canonical recipe map and rebuilt reverse index after restart.

local RECIPE_KEY = "PZHarness.Native.Restart.Recipe"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.KnowledgeRepository or nil
    local registry = PNC and PNC.RecipeKnowledgeRegistry or nil
    PZHarness.assertTrue(
        repository and registry and repository.Loaded == true,
        "native KnowledgeRepository was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        registry.Queries and registry.Queries.GetId
            and registry.Queries.GetKey,
        "native recipe registry queries were not available after restart"
    )

    local recipeID = registry.Queries.GetId(RECIPE_KEY)
    PZHarness.assertTrue(
        type(recipeID) == "number",
        "native recipe identity was not rebuilt after the JVM restart"
    )
    PZHarness.assertEqual(
        registry.Queries.GetKey(recipeID),
        RECIPE_KEY,
        "native recipe key did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        registry.Queries.GetId(RECIPE_KEY),
        recipeID,
        "native recipe reverse index did not survive the JVM restart"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local persistedKey = raw
        and raw.idToKey
        and (raw.idToKey[recipeID] or raw.idToKey[tostring(recipeID)])
    PZHarness.assertEqual(
        persistedKey,
        RECIPE_KEY,
        "native recipe-knowledge ModData was not reloaded"
    )
end
