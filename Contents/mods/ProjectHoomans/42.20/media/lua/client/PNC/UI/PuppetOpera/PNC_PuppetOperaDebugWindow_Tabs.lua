-- Tab-panel construction for the Puppet Opera scene builder.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
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

    window.layoutTab = ISPNCPuppetOperaLayoutTab:new(0, 0, 1, 1)
    window.layoutTab:initialise()
    window.layoutTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_AnchorGrid", "Layout / anchors"),
        window.layoutTab
    )

    window.playerAnimationTab = ISPNCPuppetOperaAnimationTab:new(0, 0, 1, 1)
    window.playerAnimationTab:initialise()
    window.playerAnimationTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_PlayerAnimations", "Player animations"),
        window.playerAnimationTab
    )

    window.npcAnimationTab = ISPNCPuppetOperaAnimationTab:new(0, 0, 1, 1)
    window.npcAnimationTab:initialise()
    window.npcAnimationTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_NPCAnimations", "NPC animations"),
        window.npcAnimationTab
    )

    window.beatsTab = ISPNCPuppetOperaBeatsTab:new(0, 0, 1, 1)
    window.beatsTab:initialise()
    window.beatsTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_Beats", "Beats"),
        window.beatsTab
    )

    window.traceTab = ISPNCPuppetOperaTraceTab:new(0, 0, 1, 1)
    window.traceTab:initialise()
    window.traceTab:instantiate()
    window.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_Trace", "Trace"),
        window.traceTab
    )
    window.tabDefinitions = {
        {
            key = "layout",
            name = tr("UI_PNC_PuppetOpera_AnchorGrid", "Layout / anchors"),
            view = window.layoutTab,
        },
        {
            key = "player",
            name = tr("UI_PNC_PuppetOpera_PlayerAnimations", "Player animations"),
            view = window.playerAnimationTab,
        },
        {
            key = "npc",
            name = tr("UI_PNC_PuppetOpera_NPCAnimations", "NPC animations"),
            view = window.npcAnimationTab,
        },
        {
            key = "beats",
            name = tr("UI_PNC_PuppetOpera_Beats", "Beats"),
            view = window.beatsTab,
        },
        {
            key = "trace",
            name = tr("UI_PNC_PuppetOpera_Trace", "Trace"),
            view = window.traceTab,
        },
    }
    window.visibleTabKeys = {
        layout = true,
        player = true,
        npc = true,
        beats = true,
        trace = true,
    }

    window.layoutTab:setContext(window)
    window.playerAnimationTab:setContext(window, "player")
    window.npcAnimationTab:setContext(window, "npc")
    window.beatsTab:setContext(window)
    window.traceTab:setContext(window)
end

Internal.createTabs = createTabs

return createTabs
