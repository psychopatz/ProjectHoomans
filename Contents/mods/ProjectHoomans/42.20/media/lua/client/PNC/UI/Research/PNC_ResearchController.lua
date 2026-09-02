require "PsychopatzCore/UI/PsychopatzUI"

local Components = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local DetailPane = require "PNC/UI/Research/PNC_ResearchDetailPane"
local LayoutModel = require "PNC/UI/Research/PNC_ResearchLayout"
local Model = require "PNC/UI/Research/PNC_ResearchModel"
local Presentation = require "PNC/UI/Research/PNC_ResearchPresentation"
local View = require "PNC/UI/Research/PNC_ResearchController_View"

local Controller = {}
local UI = PsychopatzCore.UI
local Client = PNC.ColonyManagementClient

local FILTERS = {
    { id = "all", key = "UI_PNC_Research_Filter_All", fallback = "ALL" },
    { id = "technology", key = "UI_PNC_Research_Filter_Technology",
        fallback = "TECHNOLOGIES" },
    { id = "blueprint", key = "UI_PNC_Research_Filter_Blueprint",
        fallback = "BLUEPRINTS" },
    { id = "book", key = "UI_PNC_Research_Filter_Book", fallback = "BOOKS" },
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function button(window, id, title, variant)
    return UI.CreateButton(window, {
        id = id, title = title, target = window,
        onclick = UI.ButtonCallback(function(control)
            return window:onResearchControl(control)
        end),
        variant = variant or "quiet",
    })
end

local function actionOrder(window)
    local item = window.researchView and window.researchView.selected
    if item and item.order then return item.order end
    local first = window.researchView and window.researchView.activeQueue
        and window.researchView.activeQueue[1]
    return first and first.order or nil
end

function Controller.CreateChildren(window)
    window.filter = window.filter or "all"
    window.collapsedGroups = window.collapsedGroups or View.LoadCollapsedGroups()
    window.selectedKey = window.selectedKey
    window.snapshot = window.snapshot or {}
    window.researchView = Model.Build(window.snapshot, {
        filter = window.filter,
        collapsedGroups = window.collapsedGroups,
        selectedKey = window.selectedKey,
    })
    window.selectedKey = window.researchView.selectedKey
    window.lastReceiveRevision = -1
    window.lastReceiveAt = 0
    window.lastRequestAt = 0

    window.catalogPane, window.catalogList = Components.CreatePane(window,
        50, Presentation.DrawCatalogRow)
    window.catalogPane:setHeader(
        tr("UI_PNC_Research_CatalogTitle", "RESEARCH TREE"), "")
    window.queuePane, window.queueList = Components.CreatePane(window,
        46, Presentation.DrawQueueRow)
    window.queuePane:setHeader(
        tr("UI_PNC_Research_QueueTitle", "ACTIVE QUEUE"), "0")
    window.detailsPane = DetailPane:new(0, 0, 1, 1)
    window.detailsPane:initialise()
    window.detailsPane:instantiate()
    window.detailsPane:setOwner(window)
    window:addChild(window.detailsPane)

    window.filterButtons = {}
    for _, definition in ipairs(FILTERS) do
        local control = button(window, "research_filter:" .. definition.id,
            tr(definition.key, definition.fallback), "quiet")
        control.researchFilter = definition.id
        window.filterButtons[#window.filterButtons + 1] = control
    end
    window.pauseButton = button(window, "research_pause",
        tr("UI_PNC_Work_Pause", "PAUSE / RESUME"), "warning")
    window.cancelButton = button(window, "research_cancel",
        tr("UI_PNC_Work_Cancel", "CANCEL ACTIVE"), "warning")
    window.debugToggle = button(window, "research_debug_toggle",
        tr("UI_PNC_Research_DebugTools", "DEBUG TOOLS") .. "  >", "quiet")
    window.debugBlueprint = button(window, "debug_blueprint",
        tr("UI_PNC_Research_DebugBlueprint", "CREATE RECIPE BLUEPRINT"), "warning")
    window.debugSpearKit = button(window, "debug_spear_kit",
        tr("UI_PNC_Research_DebugSpearKit", "ADD SPEAR TEST KIT"), "warning")
    window.debugExpanded = false

    View.AttachListHandlers(window)
    View.ApplyStyles(window)
end

function Controller.ApplyResponsiveLayout(window)
    return LayoutModel.ApplyResponsiveLayout(window)
end

function Controller.ApplyContentStyle(window)
    return View.ApplyContentStyle(window)
end

function Controller.Rebuild(window)
    return View.Rebuild(window)
end

function Controller.Refresh(window, update)
    return View.Refresh(window, update)
end

function Controller.RequestSnapshot(window)
    local _, _, requestedAt = Client.RequestSnapshot()
    window.lastRequestAt = requestedAt
end

function Controller.OnControl(window, control)
    local action = tostring(control and control.internal or "")
    if action == "research_item_action" then
        local item = window.researchView and window.researchView.selected
        if not item or not item.researchable then return false end
        if item.action == "research_queue_technology" then
            PNC.Client.RequestColonyAction(item.action,
                { technologyId = item.id })
        elseif item.action == "research_study_blueprint" then
            PNC.Client.RequestColonyAction(item.action,
                { recordIndex = item.recordIndex })
        elseif item.action == "research_read_book" then
            PNC.Client.RequestColonyAction(item.action,
                { recordIndex = item.recordIndex })
        else
            return false
        end
        return true
    end
    if string.sub(action, 1, 16) == "research_filter:" then
        window.filter = string.sub(action, 17)
        window.selectedKey = nil
        window:rebuild()
        return true
    end
    if action == "research_debug_toggle" then
        window.debugExpanded = not window.debugExpanded
        window.debugToggle:setTitle(tr("UI_PNC_Research_DebugTools", "DEBUG TOOLS")
            .. (window.debugExpanded and "  v" or "  >"))
        window:requestResponsiveLayout(true)
        return true
    end
    if action == "research_pause" then
        local order = actionOrder(window)
        if not order then return false end
        PNC.Client.RequestColonyAction("work_pause", {
            workOrderId = order.id, paused = order.status ~= "PAUSED",
        })
        return true
    end
    if action == "research_cancel" then
        local order = actionOrder(window)
        if not order then return false end
        PNC.Client.RequestColonyAction("work_cancel", {
            workOrderId = order.id,
        })
        return true
    end
    if action == "debug_blueprint" then
        PNC.Client.RequestColonyAction("blueprint_debug_create", {})
        return true
    end
    if action == "debug_spear_kit" then
        PNC.Client.RequestColonyAction("production_debug_spear_kit", {})
        return true
    end
    return false
end

return Controller
