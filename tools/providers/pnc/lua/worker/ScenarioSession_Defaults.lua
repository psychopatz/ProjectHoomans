-- Stable synthetic scenario used by the semantic harness worker.

local function install(ScenarioSession)
    ScenarioSession.initialScenario = {
        player = {
            characterUUID = "char_patrick",
            forename = "Patrick",
            surname = "Patz",
            displayName = "Patrick Patz",
            gender = "male",
            needs = {
                hunger = 0.2,
                thirst = 0.4,
                fatigue = 0.1,
                stress = 0.0,
                boredom = 0.0,
                panic = 0.0,
            },
            traits = {},
        },
        npc = {
            npcID = "npc_mara",
            forename = "Mara",
            surname = "Vale",
            identityState = "unknown",
            gender = "female",
            identitySeed = "npc_mara",
            archetype = "General",
            needs = {
                hunger = 0.2,
                thirst = 0.4,
                fatigue = 0.1,
                stress = 0.0,
                boredom = 0.0,
                panic = 0.0,
            },
            traits = { "reserved" },
            relationship = {
                approval = 0,
                respect = 0,
                familiarity = 0,
                revision = 1,
            },
        },
        world = {
            seedString = "semantic-harness-default-save",
            hunger = 0.2,
            thirst = 0.4,
            fatigue = 0.1,
            timeOfDay = 13.5,
            worldAgeHours = 49.5,
            zombieKills = 0,
        },
        conversation = { topic = "greeting", token = "harness-lease" },
        runtime = {
            mode = "singleplayer",
            language = "EN",
            llmEnabled = false,
            providerAvailable = false,
            semanticDialogueEnabled = true,
        },
    }
end

return install
