-- Runtime and world control metadata for the Semantic Lab.

local RuntimeControls = {}

function RuntimeControls.append(add, context)
    -- UI metadata for the harness. ScenarioSession.configure remains the
    -- authority for accepted scenario state; catalogs below only describe
    -- how Semantic Lab edits that state.
    add("runtime.mode", "runtime.mode", "Runtime", "Worker", "Network mode", "combobox", "enum", {
        options = { "singleplayer", "multiplayer" },
        optionsSource = "semantic_lab.harness",
    })
    add("runtime.language", "runtime.language", "Runtime", "Worker", "Language", "combobox", "enum", {
        options = { "EN", "TL" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("runtime.llmEnabled", "runtime.llmEnabled", "Runtime", "Integrations", "LLM bridge enabled", "boolean", "boolean")
    add("runtime.providerAvailable", "runtime.providerAvailable", "Runtime", "Integrations", "LLM provider available", "boolean", "boolean")
    add("runtime.semanticDialogueEnabled", "runtime.semanticDialogueEnabled", "Runtime", "Worker", "Semantic dialogue enabled", "boolean", "boolean", {
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("runtime.DTHoomans", "runtime.availableMods.DTHoomans", "Runtime", "Integrations", "Dynamic Trading adapter enabled", "boolean", "boolean", {
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })

    local needKeys = { "hunger", "thirst", "fatigue", "stress", "boredom", "panic" }
    for _, key in ipairs(needKeys) do
        local title = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
        add("world." .. key, "world." .. key, "World", "Needs", title, "slider", "number", {
            min = 0, max = 1, step = 0.05, format = "%.2f",
            legacy = true,
            settingsVisible = false,
            description = "Legacy world fallback for older scenarios; edit the owning actor field instead.",
        })
    end
    local function addActorNeeds(prefix, label, panel)
        local actor = context[prefix .. "Data"] or {}
        local source = type(actor.needs) == "table"
            and actor.needs or context.world or {}
        for _, key in ipairs(needKeys) do
            local title = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
            add(prefix .. ".needs." .. key, prefix .. ".needs." .. key,
                "Actors", label .. " Needs", title, "slider", "number", {
                    min = 0, max = 1, step = 0.05, format = "%.2f",
                    currentValue = source[key],
                    workbench = true, workbenchPanel = panel,
                    workbenchTab = "Needs", workbenchSection = "Needs",
                })
        end
    end
    addActorNeeds("player", "Player", "Player")
    addActorNeeds("npc", "NPC", "NPC Target")
    add("world.timeOfDay", "world.timeOfDay", "World", "Time", "Time of day", "slider", "number", {
        min = 0, max = 24, step = 0.25, format = "%.2f",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Time",
    })
    add("world.worldAgeHours", "world.worldAgeHours", "World", "Time", "World age (hours)", "spinbox", "number", {
        min = 0, max = 1000000, step = 0.5, format = "%.1f",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Time",
    })
    add("world.zombieKills", "world.zombieKills", "World", "World facts", "Zombie kills", "integer", "integer", {
        min = 0, max = 1000000, step = 1,
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })
    add("world.weather", "world.weather", "World", "World facts", "Weather", "combobox", "enum", {
        options = { "clear", "rain", "fog", "snow" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })
    add("world.weatherTransition", "world.weatherTransition", "World", "World facts", "Weather transition", "text", "text", {
        emptyToNull = true,
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })
end

return RuntimeControls
