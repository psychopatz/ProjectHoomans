require "ISUI/ISScrollingListBox"
require "PsychopatzCore/UI/PsychopatzUI"

local View = {}
local UI = PsychopatzCore.UI
local Components = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Model = require "PNC/UI/Research/PNC_ResearchModel"
local Presentation = require "PNC/UI/Research/PNC_ResearchPresentation"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Settings = require "PsychopatzCore/Settings/PsychopatzSettings"
local ResearchStore = Settings.Open("ProjectHoomansResearch", {
    fileName = "ProjectHoomans_ResearchUI.txt",
    defaults = { collapsedGroups = "" },
})

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function View.LoadCollapsedGroups()
    if ResearchStore and not ResearchStore.loaded then ResearchStore:Load() end
    local result = {}
    local value = ResearchStore and ResearchStore:Get("collapsedGroups", "") or ""
    for groupID in string.gmatch(tostring(value or ""), "[^,]+") do
        result[groupID] = true
    end
    return result
end

local function saveCollapsedGroups(groups)
    if not ResearchStore then return end
    local ids = {}
    for groupID, collapsed in pairs(groups or {}) do
        if collapsed == true then ids[#ids + 1] = tostring(groupID) end
    end
    table.sort(ids)
    ResearchStore:Set("collapsedGroups", table.concat(ids, ","), true)
end

local function selectedEntry(list)
    local index = list and list.selected or nil
    return index and list.items and list.items[index] or nil
end

local function addCatalogRows(window)
    local list = window.catalogList
    list:clear()
    local view = window.researchView or {}
    for _, group in ipairs(view.groups or {}) do
        list:addItem(group.id, { kind = "group", group = group })
        if not group.collapsed then
            for _, item in ipairs(group.items or {}) do
                list:addItem(item.key, { kind = "item", item = item,
                    selected = item.key == view.selectedKey })
            end
        end
    end
    if #(list.items or {}) == 0 then
        list:addItem("empty", { kind = "item", item = {
            key = "empty", name = tr("UI_PNC_Research_Empty",
                "NO RESEARCH AVAILABLE"), source = "technology",
            status = "unavailable", selected = false,
        }})
    end
end

local function addQueueRows(window)
    local list = window.queueList
    list:clear()
    local queue = window.researchView and window.researchView.activeQueue or {}
    for _, item in ipairs(queue or {}) do
        list:addItem(item.key, { kind = "queue", queue = item,
            selected = item.key == window.researchView.selectedKey })
    end
end

local function rebuildDetail(window)
    window.detailsPane:setItem(window.researchView
        and window.researchView.selected or nil)
end

function View.AttachListHandlers(window)
    window.catalogList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local entry = selectedEntry(list)
        local row = entry and entry.item or nil
        if not row then return end
        if row.kind == "group" then
            local group = row.group
            window.collapsedGroups[group.id] = not group.collapsed
            saveCollapsedGroups(window.collapsedGroups)
            window:rebuild()
        elseif row.kind == "item" and row.item and row.item.key ~= "empty" then
            window.selectedKey = row.item.key
            window:rebuild()
        end
    end
    window.queueList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local entry = selectedEntry(list)
        local row = entry and entry.item or nil
        local queue = row and row.queue or nil
        if queue then
            window.filter = "all"
            window.selectedKey = queue.key
            window:rebuild()
        end
    end
end

function View.ApplyStyles(window)
    for _, control in ipairs(window.filterButtons or {}) do
        UI.SetButtonVariant(control,
            control.researchFilter == window.filter and "selected" or "quiet")
    end
    local view = window.researchView or {}
    local hasOrder = view.selected and view.selected.order ~= nil
        or #(view.activeQueue or {}) > 0
    window.pauseButton:setEnable(hasOrder)
    window.cancelButton:setEnable(hasOrder)
    window.pauseButton:setTitle(tr("UI_PNC_Work_Pause", "PAUSE / RESUME"))
    window.cancelButton:setTitle(tr("UI_PNC_Work_Cancel", "CANCEL ACTIVE"))
end

function View.ApplyContentStyle(window)
    local signature = Options.GetContentOpacitySignature()
    if window.lastContentOpacitySignature == signature then return end
    Options.ApplySurfaceOpacity(window.catalogList, "detail")
    Options.ApplySurfaceOpacity(window.queueList, "detail")
    Options.ApplySurfaceOpacity(window.detailsPane, "detail")
    window.contentOpacity = Options.GetContentOpacity("detail")
    window.lastContentOpacitySignature = signature
end

function View.Rebuild(window)
    window.researchView = Model.Build(window.snapshot or {}, {
        filter = window.filter,
        collapsedGroups = window.collapsedGroups,
        selectedKey = window.selectedKey,
    })
    window.selectedKey = window.researchView.selectedKey
    addCatalogRows(window)
    addQueueRows(window)
    window.queuePane:setHeader(
        tr("UI_PNC_Research_QueueTitle", "ACTIVE QUEUE"),
        tostring(#(window.researchView.activeQueue or {})))
    rebuildDetail(window)
    View.ApplyStyles(window)
    if window.requestResponsiveLayout then
        window:requestResponsiveLayout(true)
    end
end

function View.Refresh(window, update)
    update = update or PNC.ColonyManagementClient.ReadSnapshot()
    window.snapshot = update.snapshot or {}
    window.lastReceiveRevision = tonumber(update.revision) or 0
    window.lastReceiveAt = update.receivedAt
    View.Rebuild(window)
    View.ApplyContentStyle(window)
end

return View
