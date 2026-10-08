-- Target-owned native needs restart fixture, phase two.
-- Read synthetic non-player needs state after a fresh JVM loads ModData.

local RECORD_ID = "npc_pzharness_needs_restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.NeedsRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Loaded == true,
        "native NeedsRepository was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        repository.MODDATA_KEY,
        "native NeedsRepository ModData key was not available after restart"
    )

    local state = repository.Get(RECORD_ID, false)
    PZHarness.assertTrue(
        type(state) == "table" and type(state.needs) == "table",
        "native NeedsRepository did not reload synthetic NPC state"
    )
    PZHarness.assertTrue(
        math.floor(state.needs.hunger * 1000 + 0.5) == 730
            and math.floor(state.needs.thirst * 1000 + 0.5) == 410
            and math.floor(state.needs.fatigue * 1000 + 0.5) == 290,
        "native needs values did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        math.floor(state.hungerOverflow * 1000 + 0.5) == 1250,
        "native hunger overflow did not survive the JVM restart"
    )
    PZHarness.assertTrue(
        type(state.nutrition) == "table"
            and math.floor(state.nutrition.calories + 0.5) == 1234
            and math.floor(state.nutrition.weight * 10 + 0.5) == 725
            and math.floor(state.nutrition.carbohydrates + 0.5) == 12
            and math.floor(state.nutrition.proteins + 0.5) == 23
            and math.floor(state.nutrition.lipids + 0.5) == 34,
        "native nutrition state did not survive the JVM restart"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local packed = raw and raw.n and raw.n[RECORD_ID]
    PZHarness.assertTrue(
        type(raw) == "table"
            and raw.v == 2
            and type(packed) == "table"
            and packed[1] == 730
            and packed[2] == 410
            and packed[3] == 290
            and packed[12] == 1250,
        "native needs ModData was not reloaded"
    )
end
