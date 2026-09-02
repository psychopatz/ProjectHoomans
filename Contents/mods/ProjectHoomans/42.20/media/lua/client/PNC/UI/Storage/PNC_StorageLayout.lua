local LayoutModule = {}

local Components = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"

function LayoutModule.Measure(window, content)
    local Layout = PsychopatzCore.UI.Layout
    local scale = window.uiScale
    local gap = Layout.Pixels(6, scale)
    local height = Layout.Pixels(28, scale)
    local sortWidth = Layout.Pixels(132, scale)
    local transferWidth = Layout.Pixels(150, scale)
    local debugWidth = Layout.Pixels(152, scale)
    local minimumSearch = Layout.Pixels(100, scale)
    local required = minimumSearch + sortWidth + transferWidth + debugWidth
        + gap * 3
    local compact = content.width < required
    local searchWidth

    if compact then
        searchWidth = math.max(minimumSearch,
            content.width - sortWidth - gap)
        Layout.SetBounds(window.storageSearch, content.x, content.y,
            searchWidth, height)
        Layout.SetBounds(window.storageSortButton,
            content.x + searchWidth + gap, content.y, sortWidth, height)
        local secondY = content.y + height + gap
        Layout.SetBounds(window.storageTransferButton,
            content.x, secondY, transferWidth, height)
        Layout.SetBounds(window.storageDebugToggle,
            content.x + content.width - debugWidth,
            secondY, debugWidth, height)
        window.layout.storageListY = secondY + height
            + Layout.Pixels(28, scale)
    else
        searchWidth = content.width - sortWidth - transferWidth
            - debugWidth - gap * 3
        Layout.SetBounds(window.storageSearch, content.x, content.y,
            searchWidth, height)
        Layout.SetBounds(window.storageSortButton,
            content.x + searchWidth + gap, content.y, sortWidth, height)
        Layout.SetBounds(window.storageTransferButton,
            content.x + searchWidth + sortWidth + gap * 2,
            content.y, transferWidth, height)
        Layout.SetBounds(window.storageDebugToggle,
            content.x + content.width - debugWidth,
            content.y, debugWidth, height)
        window.layout.storageListY = content.y + Layout.Pixels(56, scale)
    end
end

function LayoutModule.Apply(window, active)
    if not window.layout then return end
    local Layout = PsychopatzCore.UI.Layout
    active = active == true
    window.storageSearch:setVisible(active)
    window.storageList:setVisible(active)
    window.storageSortButton:setVisible(active)

    local storage = window.snapshot and window.snapshot.storage or nil
    local transferVisible = active and storage ~= nil
    window.storageTransferButton:setVisible(transferVisible == true)
    if window.storageTransferButton.setEnable then
        local access = storage and storage.access or nil
        window.storageTransferButton:setEnable(access
            and access.writable == true or false)
    end

    local debugVisible = active and storage ~= nil
        and storage.debugAuthorized == true
    debugVisible = debugVisible == true
    window.storageDebugToggle:setVisible(debugVisible)
    if not debugVisible then window.storageDebugExpanded = false end

    local drawerVisible = debugVisible
        and window.storageDebugExpanded == true
    for _, button in ipairs(window.storageControls or {}) do
        button:setVisible(drawerVisible == true)
        if button.internal == "job_requirements_lumber"
            and button.setEnable
        then
            button:setEnable(window.selectedPersonID ~= nil)
        end
    end

    if not active then
        window.storageActivityPane:setVisible(false)
        window.detailsPane:setVisible(false)
        return
    end

    local content = window.layout.content
    local scale = window.uiScale
    local gap = Layout.Pixels(12, scale)
    local bottom = content.y + content.height
    local compactDrawer = drawerVisible and Layout.IsCompact(
        content.width, Layout.Pixels(820, scale)) or false
    local listWidth = content.width
    local drawerWidth
    if drawerVisible and not compactDrawer then
        drawerWidth = math.max(Layout.Pixels(300, scale),
            math.floor((content.width - gap) * 0.36))
        listWidth = content.width - gap - drawerWidth
    end

    local availableHeight = math.max(Layout.Pixels(60, scale),
        bottom - window.layout.storageListY)
    local showActivity = not compactDrawer
    window.storageActivityPane:setVisible(showActivity == true)
    local activityHeight = showActivity and math.min(
        Layout.Pixels(265, scale),
        math.max(Layout.Pixels(105, scale),
            availableHeight - Layout.Pixels(120, scale) - gap)) or 0
    local listHeight = availableHeight
        - (showActivity and activityHeight + gap or 0)
    if compactDrawer then
        listHeight = math.max(Layout.Pixels(110, scale),
            math.floor(listHeight * 0.48))
    end
    listHeight = math.max(Layout.Pixels(60, scale), listHeight)
    Layout.SetBounds(window.storageList, content.x,
        window.layout.storageListY, listWidth, listHeight)
    Components.LayoutScrollbar(window.storageList)

    if showActivity then
        window:layoutPane(window.storageActivityPane, content.x,
            window.layout.storageListY + listHeight + gap,
            listWidth, activityHeight)
    end

    window.detailsPane:setVisible(drawerVisible == true)
    if drawerVisible then
        local drawerX = compactDrawer and content.x
            or content.x + listWidth + gap
        drawerWidth = compactDrawer and content.width
            or content.width - listWidth - gap
        local controlsY = compactDrawer
            and window.layout.storageListY + listHeight + gap
            or window.layout.storageListY
        local flow = Layout.Flow(window.storageControls,
            { x = drawerX, y = controlsY, width = drawerWidth },
            { scale = window.uiScale, minWidth = 104, gap = 5 })
        local detailsY = flow.bottom + Layout.Pixels(28, scale)
        window:layoutPane(window.detailsPane, drawerX, detailsY,
            drawerWidth, math.max(Layout.Pixels(40, scale),
                bottom - detailsY))
    end
end

return LayoutModule
