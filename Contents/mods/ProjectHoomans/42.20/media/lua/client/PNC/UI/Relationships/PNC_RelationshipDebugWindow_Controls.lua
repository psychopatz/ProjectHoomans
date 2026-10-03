local Controls = {}

local EVENTS = {
    { id = "treated_wound", title = "Treat Wound", variant = "success" },
    { id = "saved_from_incapacitation", title = "Save", variant = "success" },
    { id = "protected_from_attacker", title = "Protect", variant = "default" },
    { id = "witnessed_player_kill", title = "Witness Kill", variant = "default" },
    { id = "survived_combat_together", title = "Survive Together", variant = "default" },
    { id = "abandoned_in_combat", title = "Abandon", variant = "danger" },
}

local EXTRA_CONTROLS = {
    {
        id = "pacify_24h", title = "Pacify for 24h",
        handler = "onPacification", variant = "success",
    },
    {
        id = "clear_pacification", title = "Clear Pacification",
        handler = "onPacification", variant = "danger",
    },
    {
        id = "context_minus", title = "Context -5",
        handler = "onContext", variant = "quiet",
    },
    {
        id = "context_reset", title = "Context Reset",
        handler = "onContext", variant = "quiet",
    },
    {
        id = "context_plus", title = "Context +5",
        handler = "onContext", variant = "quiet",
    },
}

local PRESETS = {
    { id = "admire", title = "Set Admire" },
    { id = "pity", title = "Set Pity" },
    { id = "fear", title = "Set Fear" },
    { id = "despise", title = "Set Despise" },
    { id = "indifferent", title = "Set Indifferent" },
}

local SECTIONS = {
    { id = "relationship", title = "Relationship" },
    { id = "personality", title = "Personality" },
    { id = "memories", title = "Memories" },
    { id = "conduct", title = "Conduct" },
    { id = "context", title = "Faction / intent" },
    { id = "trace", title = "Event trace" },
    { id = "diagnostics", title = "Diagnostics" },
    { id = "all", title = "All data" },
}

local function addCoreControls(window, WindowClass, UI)
    local refresh = UI.CreateButton(window, {
        id = "refresh",
        title = "Refresh",
        target = window,
        onclick = WindowClass.onRefresh,
        variant = "quiet",
    })
    window.refreshButton = refresh
    window.controls[#window.controls + 1] = refresh
    local knowledge = UI.CreateButton(window, {
        id = "knowledge_notes",
        title = "Knowledge / Notes",
        target = window,
        onclick = WindowClass.onKnowledge,
        variant = "quiet",
    })
    window.knowledgeButton = knowledge
    window.controls[#window.controls + 1] = knowledge
end

local function addEventControls(window, WindowClass, UI)
    for _, definition in ipairs(EVENTS) do
        local button = UI.CreateButton(window, {
            id = definition.id,
            title = definition.title,
            target = window,
            onclick = WindowClass.onTrigger,
            variant = definition.variant,
        })
        window.controls[#window.controls + 1] = button
    end
end

local function addExtraControls(window, WindowClass, UI)
    for _, definition in ipairs(EXTRA_CONTROLS) do
        local button = UI.CreateButton(window, {
            id = definition.id,
            title = definition.title,
            target = window,
            onclick = WindowClass[definition.handler],
            variant = definition.variant,
        })
        window.controls[#window.controls + 1] = button
    end
end

local function addPresetControls(window, WindowClass, UI)
    for _, definition in ipairs(PRESETS) do
        local button = UI.CreateButton(window, {
            id = "baseline_" .. definition.id,
            title = definition.title,
            target = window,
            onclick = WindowClass.onBaseline,
            variant = "quiet",
        })
        button.standingID = definition.id
        window.controls[#window.controls + 1] = button
    end
end

local function addSwapControl(window, WindowClass, UI)
    local button = UI.CreateButton(window, {
        id = "swap_direction",
        title = "Swap Direction",
        target = window,
        onclick = WindowClass.onSwapDirection,
        variant = "quiet",
    })
    window.swapButton = button
    window.controls[#window.controls + 1] = button
end

local function addSectionControls(window, WindowClass, UI)
    for _, definition in ipairs(SECTIONS) do
        local button = UI.CreateButton(window, {
            id = "section_" .. definition.id,
            title = definition.title,
            target = window,
            onclick = WindowClass.onSection,
            variant = "quiet",
        })
        button.sectionID = definition.id
        window.sectionControls[#window.sectionControls + 1] = button
    end
end

local function addCustomBaselineControls(window, WindowClass, UI, Layout)
    window.customApproval = UI.CreateTextEntry(window, {
        text = "0",
        width = Layout.Pixels(86, window.uiScale),
        height = Layout.Pixels(26, window.uiScale),
    })
    window.customRespect = UI.CreateTextEntry(window, {
        text = "0",
        width = Layout.Pixels(86, window.uiScale),
        height = Layout.Pixels(26, window.uiScale),
    })
    window.applyCustomButton = UI.CreateButton(window, {
        id = "apply_custom_baseline",
        title = "Apply synthetic baseline",
        target = window,
        onclick = WindowClass.onCustomBaseline,
        variant = "quiet",
    })
end

function Controls.Create(window, WindowClass, UI, Layout)
    window.contextBonus = 0
    window.controls = {}
    window.sectionControls = {}
    window.currentSection = "relationship"
    addCoreControls(window, WindowClass, UI)
    addEventControls(window, WindowClass, UI)
    addExtraControls(window, WindowClass, UI)
    addPresetControls(window, WindowClass, UI)
    addSwapControl(window, WindowClass, UI)
    addSectionControls(window, WindowClass, UI)
    addCustomBaselineControls(window, WindowClass, UI, Layout)
end

return Controls
