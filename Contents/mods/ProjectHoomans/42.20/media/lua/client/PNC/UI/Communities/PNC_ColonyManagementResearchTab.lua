local ResearchTab = {}
local UPGRADE_TITLE_KEY = "UI_PNC_Research_DebugUpgradeStorage"

function ResearchTab.Create(window, UI, tr)
    window.researchBlueprintIndex, window.researchSpecimenIndex = 1, 1
    local function control(id, key, variant)
        return UI.CreateButton(window, { id = id, title = getText(key),
            target = window,
            onclick = ISPNCColonyManagementWindow.onResearchControl,
            variant = variant })
    end
    local upgradeTitle = tr(UPGRADE_TITLE_KEY, "Debug: Upgrade Storage")
    window.researchUpgrade = UI.CreateButton(window, {
        id = "storage_capacity",
        title = upgradeTitle,
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchUpgrade,
        variant = "warning",
    })
    window.researchTechnology = UI.CreateButton(window, {
        id = "facility:workshop",
        title = getText("UI_PNC_Research_StartWorkshop"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchControl,
    })
    window.researchBlueprint = UI.CreateButton(window, {
        id = "study_blueprint",
        title = getText("UI_PNC_Research_StudyBlueprint"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchControl,
    })
    window.researchReverse = UI.CreateButton(window, {
        id = "reverse_engineer",
        title = getText("UI_PNC_Research_ReverseEngineer"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchControl,
    })
    window.researchDebugBlueprint = UI.CreateButton(window, {
        id = "debug_blueprint",
        title = getText("UI_PNC_Research_DebugBlueprint"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchControl,
        variant = "warning",
    })
    window.researchDebugSpearKit = UI.CreateButton(window, {
        id = "debug_spear_kit",
        title = getText("UI_PNC_Research_DebugSpearKit"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchControl,
        variant = "warning",
    })
    window.researchBlueprintPrevious = control("blueprint_previous",
        "UI_PNC_Research_PreviousBlueprint")
    window.researchBlueprintNext = control("blueprint_next",
        "UI_PNC_Research_NextBlueprint")
    window.researchSpecimenPrevious = control("specimen_previous",
        "UI_PNC_Research_PreviousSpecimen")
    window.researchSpecimenNext = control("specimen_next",
        "UI_PNC_Research_NextSpecimen")
    window.researchPause = control("research_pause", "UI_PNC_Work_Pause",
        "warning")
    window.researchCancel = control("research_cancel", "UI_PNC_Work_Cancel",
        "warning")
end

function ResearchTab.Layout(window, Layout, content)
    local controls = { window.researchTechnology, window.researchBlueprint,
        window.researchReverse, window.researchPause, window.researchCancel,
        window.researchBlueprintPrevious, window.researchBlueprintNext,
        window.researchSpecimenPrevious, window.researchSpecimenNext,
        window.researchDebugBlueprint, window.researchDebugSpearKit,
        window.researchUpgrade }
    local gap, columns = 6, 4
    local width = math.floor((content.width - gap * (columns - 1)) / columns)
    for index, control in ipairs(controls) do
        local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
        Layout.SetBounds(control, content.x + column * (width + gap),
            content.y + row * 32, width, 27)
    end
end

function ResearchTab.ApplyVisibility(window, active, Layout)
    window.researchUpgrade:setVisible(active
        and window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true)
    window.researchTechnology:setVisible(active)
    window.researchBlueprint:setVisible(active)
    window.researchReverse:setVisible(active)
    window.researchBlueprintPrevious:setVisible(active)
    window.researchBlueprintNext:setVisible(active)
    window.researchSpecimenPrevious:setVisible(active)
    window.researchSpecimenNext:setVisible(active)
    window.researchPause:setVisible(active)
    window.researchCancel:setVisible(active)
    window.researchDebugBlueprint:setVisible(active
        and window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true)
    window.researchDebugSpearKit:setVisible(active
        and window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true)
    if active and Layout then
        window:layoutPane(window.detailsPane, window.layout.content.x,
            window.layout.content.y + 102, window.layout.content.width,
            math.max(60, window.layout.content.height - 102))
    end
end

local function storageRows(window, predicate)
    local output = {}
    for _, row in ipairs(window.snapshot and window.snapshot.storage
        and window.snapshot.storage.rows or {}) do
        if predicate(row) then output[#output + 1] = row end
    end
    return output
end

local function cycle(value, delta, count)
    if count <= 0 then return 1 end
    return ((math.max(1, tonumber(value) or 1) - 1 + delta) % count) + 1
end

local function activeResearch(window)
    for _, order in ipairs(window.snapshot and window.snapshot.research
        and window.snapshot.research.orders or {}) do
        if order.operation == "RESEARCH" and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED" then return order end
    end
end

local function progressValues(order)
    local required = math.max(1, tonumber(order and order.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(order and order.progress) or 0))
    return progress, required,
        math.floor((progress / required) * 100 + 0.5)
end

function ResearchTab.OnControl(window, button)
    local action = tostring(button and button.internal or "")
    local blueprints = storageRows(window, function(value)
        return value.fullType == "PNC.RecipeBlueprint"
    end)
    local specimens = storageRows(window, function(value)
        return value.fullType ~= "PNC.RecipeBlueprint"
    end)
    if action == "blueprint_previous" or action == "blueprint_next" then
        window.researchBlueprintIndex = cycle(window.researchBlueprintIndex,
            action == "blueprint_next" and 1 or -1, #blueprints)
        window:rebuildDetails(); return true
    elseif action == "specimen_previous" or action == "specimen_next" then
        window.researchSpecimenIndex = cycle(window.researchSpecimenIndex,
            action == "specimen_next" and 1 or -1, #specimens)
        window:rebuildDetails(); return true
    elseif action == "research_pause" then
        local order = activeResearch(window)
        if order then PNC.Client.RequestColonyAction("work_pause", {
            workOrderId = order.id, paused = order.status ~= "PAUSED",
        }) return true end
    elseif action == "research_cancel" then
        local order = activeResearch(window)
        if order then PNC.Client.RequestColonyAction("work_cancel", {
            workOrderId = order.id,
        }) return true end
    end
    if action == "facility:workshop" then
        PNC.Client.RequestColonyAction("research_queue_technology", {
            technologyId = action,
        })
    elseif action == "study_blueprint" then
        local row = blueprints[cycle(window.researchBlueprintIndex, 0,
            #blueprints)]
        if row then PNC.Client.RequestColonyAction("research_study_blueprint", {
            recordIndex = row.recordIndex,
        }) end
    elseif action == "reverse_engineer" then
        local row = specimens[cycle(window.researchSpecimenIndex, 0,
            #specimens)]
        if row then PNC.Client.RequestColonyAction("research_reverse_engineer", {
            recordIndex = row.recordIndex,
        }) end
    elseif action == "debug_blueprint" then
        PNC.Client.RequestColonyAction("blueprint_debug_create", {})
    elseif action == "debug_spear_kit" then
        PNC.Client.RequestColonyAction("production_debug_spear_kit", {})
    end
end

function ResearchTab.OnUpgrade(window, button)
    PNC.Client.RequestColonyAction("research_debug_upgrade", {
        researchId = button and button.internal or "storage_capacity",
        storageId = window.snapshot and window.snapshot.storage
            and window.snapshot.storage.storageId,
    })
end

function ResearchTab.Rebuild(window, snapshot, tr)
    if window.tab ~= "research" then return false end
    local entries = snapshot.research and snapshot.research.entries or {}
    if #entries == 0 then
        window:addDetail("NO RESEARCH AVAILABLE",
            "Research definitions are unavailable.")
        return true
    end
    local activeByTechnology = {}
    for _, order in ipairs(snapshot.research.orders or {}) do
        local payload = order.payload or {}
        if order.operation == "RESEARCH" and payload.mode == "technology"
            and order.status ~= "COMPLETED" and order.status ~= "CANCELLED"
        then
            activeByTechnology[tostring(payload.technologyId or "")] = order
        end
    end
    for _, entry in ipairs(entries) do
        if entry.id == "storage_capacity" then
            window:addDetail(tr(entry.labelKey, "Storage Capacity"),
                "Tier " .. tostring(entry.currentLevel), "accent")
        else
            local active = activeByTechnology[tostring(entry.id)]
            local progress, required, percent = progressValues(active)
            local detail = entry.known
                and tr("UI_PNC_Research_Known", "UNLOCKED")
                or active and string.format("%s  %d%%  |  %.1f / %.1f WP",
                    tostring(active.status), percent, progress, required)
                or tostring(entry.requiredWork) .. " WP"
            window:addDetail(tr(entry.labelKey, entry.id),
                detail,
                entry.known and "success" or "accent")
        end
    end
    window:addDetail(tr("UI_PNC_Research_LearnedRecipes", "LEARNED RECIPES"),
        tostring(#(snapshot.research.learnedRecipeIds or {})))
    local blueprints = storageRows(window, function(value)
        return value.fullType == "PNC.RecipeBlueprint"
    end)
    local specimens = storageRows(window, function(value)
        return value.fullType ~= "PNC.RecipeBlueprint"
    end)
    window.researchBlueprintIndex = cycle(window.researchBlueprintIndex, 0,
        #blueprints)
    window.researchSpecimenIndex = cycle(window.researchSpecimenIndex, 0,
        #specimens)
    local blueprint = blueprints[window.researchBlueprintIndex]
    local specimen = specimens[window.researchSpecimenIndex]
    window:addDetail(getText("UI_PNC_Research_BlueprintInput"), blueprint
        and tostring(blueprint.name or blueprint.fullType) or getText("UI_None"))
    window:addDetail(getText("UI_PNC_Research_SpecimenInput"), specimen
        and tostring(specimen.name or specimen.fullType) or getText("UI_None"))
    for _, order in ipairs(snapshot.research.orders or {}) do
        if order.operation == "RESEARCH" and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
        then
            local progress, required, percent = progressValues(order)
            window:addDetail("RESEARCH " .. tostring(order.status)
                    .. "  " .. tostring(percent) .. "%",
                string.format("%.1f / %.1f WP", progress, required),
                order.blockedReason and "warning" or "accent")
            window:addDetail("WORKER", tostring(order.workerId or "UNASSIGNED"))
            if order.blockedReason then
                window:addDetail("BLOCKED", tostring(order.blockedReason), "warning")
            end
        end
    end
    return true
end

return ResearchTab
