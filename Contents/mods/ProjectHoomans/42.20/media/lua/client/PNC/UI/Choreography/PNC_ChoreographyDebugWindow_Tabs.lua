-- Tab-panel construction for the Puppet Opera scene builder.

PNC = PNC or {}

local Internal = PNC.ChoreographyDebugWindow.Internal
local Layout = Internal.Layout
local tr = Internal.tr

local function createTabs(window)
    window.tabPanel = ISTabPanel:new(0, 0, 1, 1)
    window.tabPanel:initialise()
    window.tabPanel:instantiate()
    window.tabPanel.tabPadX = Layout.Pixels(10, window.uiScale)
    window.tabPanel.equalTabWidth = false
    window.tabPanel.allowDraggingTabs = false
    window.tabPanel.allowTornOffTabs = false
    window:addChild(window.tabPanel)

    window.layoutTab = ISPNCChoreographyLayoutTab:new(0, 0, 1, 1)
    window.layoutTab:initialise()
    window.layoutTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_AnchorGrid", "Layout / anchors"),
        window.layoutTab
    )

    window.playerAnimationTab = ISPNCChoreographyAnimationTab:new(0, 0, 1, 1)
    window.playerAnimationTab:initialise()
    window.playerAnimationTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_PlayerAnimations", "Player animations"),
        window.playerAnimationTab
    )

    window.npcAnimationTab = ISPNCChoreographyAnimationTab:new(0, 0, 1, 1)
    window.npcAnimationTab:initialise()
    window.npcAnimationTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_NPCAnimations", "NPC animations"),
        window.npcAnimationTab
    )

    window.beatsTab = ISPNCChoreographyBeatsTab:new(0, 0, 1, 1)
    window.beatsTab:initialise()
    window.beatsTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_Beats", "Beats"),
        window.beatsTab
    )

    window.triggersTab = ISPNCChoreographyTriggersTab:new(0, 0, 1, 1)
    window.triggersTab:initialise()
    window.triggersTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_TriggersExport", "Triggers & Export"),
        window.triggersTab
    )

    window.traceTab = ISPNCChoreographyTraceTab:new(0, 0, 1, 1)
    window.traceTab:initialise()
    window.traceTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_Choreography_Trace", "Trace"),
        window.traceTab
    )
    window.tabDefinitions = {
        {
            key = "layout",
            name = tr("UI_PNC_Choreography_AnchorGrid", "Layout / anchors"),
            view = window.layoutTab,
        },
        {
            key = "player",
            name = tr("UI_PNC_Choreography_PlayerAnimations", "Player animations"),
            view = window.playerAnimationTab,
        },
        {
            key = "npc",
            name = tr("UI_PNC_Choreography_NPCAnimations", "NPC animations"),
            view = window.npcAnimationTab,
        },
        {
            key = "beats",
            name = tr("UI_PNC_Choreography_Beats", "Beats"),
            view = window.beatsTab,
        },
        {
            key = "triggers",
            name = tr("UI_PNC_Choreography_TriggersExport", "Triggers & Export"),
            view = window.triggersTab,
        },
        {
            key = "trace",
            name = tr("UI_PNC_Choreography_Trace", "Trace"),
            view = window.traceTab,
        },
    }
    window.visibleTabKeys = {
        layout = true,
        player = true,
        npc = true,
        beats = true,
        triggers = true,
        trace = true,
    }

    window.layoutTab:setContext(window)
    window.playerAnimationTab:setContext(window, "player")
    window.npcAnimationTab:setContext(window, "npc")
    window.beatsTab:setContext(window)
    window.triggersTab:setContext(window)
    window.traceTab:setContext(window)
end

Internal.createTabs = createTabs

return createTabs
