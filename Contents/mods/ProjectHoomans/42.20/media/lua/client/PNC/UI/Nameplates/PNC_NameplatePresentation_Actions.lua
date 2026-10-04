local Presentation = PNC.NameplatePresentation
local ACTION_COLOR = { r = 0.35, g = 0.88, b = 1.0, a = 1.0 }

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function facilityName(info)
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get(info.facilityDefinitionId) or nil
    return definition and tr(definition.displayNameKey,
        tostring(info.facilityDefinitionId or "Building"))
        or tr("UI_PNC_Action_BuildingTarget", "Building")
end

local function itemName(fullType, fallback)
    if fullType and getItemNameFromFullType then
        local value = getItemNameFromFullType(fullType)
        if value and value ~= "" then return value end
    end
    if fullType and tostring(fullType) ~= "" then
        local shortType = string.match(tostring(fullType), "([^%.]+)$")
            or tostring(fullType)
        return string.gsub(shortType, "_", " ")
    end
    return fallback
end

local function activityItemName(info)
    if type(info) ~= "table" then return nil end
    local fullType = info.activityItemFullType
    local labelKey = info.activityItemLabelKey
    local worldWater = info.resourceKind == "world_water"
        or info.capability == "survival.drink.world"
    local hasFullType = fullType ~= nil and tostring(fullType) ~= ""
    local hasLabelKey = type(labelKey) == "string" and labelKey ~= ""
    if not hasFullType and not hasLabelKey and not worldWater then
        return nil
    end
    local fallbackText = worldWater and "water" or "item"
    local fallback = hasLabelKey and tr(labelKey, fallbackText) or fallbackText
    return itemName(fullType, fallback)
end

local function activityLabel(info, fallback)
    if tostring(info and info.activityConsumptionMode or "") == "dual" then
        return tr("UI_PNC_Activity_Consuming", "Consuming")
    end
    return type(info and info.labelKey) == "string"
        and info.labelKey ~= ""
        and tr(info.labelKey, fallback) or fallback
end

local function recipeTarget(info)
    local resolved = info.recipeId and PNC.RecipeKnowledgeRegistry
        and PNC.RecipeKnowledgeRegistry.Queries
        and PNC.RecipeKnowledgeRegistry.Queries.Resolve(info.recipeId) or nil
    local output = resolved and resolved.descriptor
        and resolved.descriptor.outputs and resolved.descriptor.outputs[1] or nil
    local fullType = output and output.itemTypes and output.itemTypes[1] or nil
    return itemName(fullType, tr("UI_PNC_Action_ItemTarget", "item"))
end

local LUMBER_PHASE_LABELS = {
    TRAVEL = { key = "UI_PNC_Action_LumberTraveling", fallback = "Traveling to" },
    CHOPPING = { key = "UI_PNC_Action_LumberChopping", fallback = "Chopping" },
    OUTPUT_APPROACH = { key = "UI_PNC_Action_LumberCollecting", fallback = "Collecting wood" },
    GRAB_PENDING = { key = "UI_PNC_Action_LumberGrabbing", fallback = "Grabbing wood" },
    CARRYING = { key = "UI_PNC_Action_LumberDelivering", fallback = "Delivering wood" },
    OUTPUT_DESTINATION_APPROACH = { key = "UI_PNC_Action_LumberDelivering", fallback = "Delivering wood" },
    DEPOSIT_PENDING = { key = "UI_PNC_Action_LumberDepositing", fallback = "Depositing wood" },
    WAITING_FOR_TOOL = { key = "UI_PNC_Action_LumberWaitingTool", fallback = "Waiting for tool" },
    WAITING_FOR_FATIGUE = { key = "UI_PNC_Action_LumberWaitingFatigue", fallback = "Waiting to recover" },
    WAITING_FOR_STOCKPILE = { key = "UI_PNC_Action_LumberWaitingStockpile", fallback = "Waiting for stockpile" },
    WAITING_FOR_TREE_CHUNK = { key = "UI_PNC_Action_LumberWaitingTree", fallback = "Waiting for tree" },
    WAITING_FOR_MATERIALIZATION = { key = "UI_PNC_Action_LumberWaitingWorld", fallback = "Waiting for world" },
    WAITING_FOR_TRAVEL = { key = "UI_PNC_Action_LumberWaitingTravel", fallback = "Waiting to travel" },
    WAITING_FOR_WORKER = { key = "UI_PNC_Action_LumberWaitingWorker", fallback = "Waiting for worker" },
}

local LUMBER_REASON_LABELS = {
    storage_full = "storage full",
    lumber_travel_stalled = "navigation stalled",
    native_no_goal_progress = "navigation stalled",
    no_approach_point = "no reachable work point",
    lumber_tool_missing = "missing lumber tool",
    tool_cannot_chop = "invalid lumber tool",
}

local function lumberReason(info)
    local reason = info and (info.blockedReason or info.waitingReason) or nil
    if not reason or tostring(reason) == "" then return nil end
    reason = tostring(reason)
    return LUMBER_REASON_LABELS[reason]
        or string.lower(string.gsub(reason, "_", " "))
end

local function lumberActionText(info, target)
    if string.upper(tostring(info.operation or "")) ~= "LUMBER" then
        return nil
    end

    local phase = string.upper(tostring(info.phase or info.status or ""))
    local reason = lumberReason(info)
    if phase == "BLOCKED" then
        return tr("UI_PNC_Action_Blocked", "Blocked")
            .. (reason and ": " .. reason or "")
    end
    local definition = LUMBER_PHASE_LABELS[phase]
    if not definition then
        return nil
    end

    local label = tr(definition.key, definition.fallback)
    if reason and (string.find(phase, "^WAITING_", 1) == 1
        or phase == "DEPOSIT_PENDING")
    then
        label = label .. " (" .. reason .. ")"
    end
    if phase == "TRAVEL" or phase == "CHOPPING" then
        return label .. " " .. target
    end
    return label
end

local function actionProgress(info, explicitWork)
    local percent = tostring(math.max(0, math.min(100, math.floor(tonumber(info.percent) or 0))))
    if explicitWork then
        return tr("UI_PNC_Action_WorkProgress", "work") .. " " .. percent .. "%"
    end
    return percent .. "%"
end

local FISHING_PHASE_LABELS = {
    TRAVEL = { key = "UI_PNC_Action_Traveling", fallback = "traveling" },
    WAITING = { key = "UI_PNC_Action_Preparing", fallback = "preparing" },
    TOOL_CHECK = { key = "UI_PNC_Action_FishingToolCheck", fallback = "checking tool" },
    WORKING = { key = "UI_PNC_Action_FishingWorking", fallback = "working" },
    ATTEMPT = { key = "UI_PNC_Action_FishingAttempt", fallback = "attempting" },
    OUTPUT = { key = "UI_PNC_Action_FishingOutput", fallback = "storing catch" },
    WAITING_FOR_TOOL = { key = "UI_PNC_Action_FishingWaitingTool", fallback = "waiting for tool" },
    WAITING_FOR_OUTPUT = { key = "UI_PNC_Action_FishingWaitingOutput", fallback = "waiting for output" },
    WAITING_FOR_SPOT = { key = "UI_PNC_Action_FishingWaitingSpot", fallback = "waiting for fishing spot" },
}

function Presentation.FishingActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    local behaviorId = string.lower(tostring(info and info.behaviorId or ""))
    local orderKind = string.lower(tostring(info and info.orderKind or ""))
    if not info or info.kind ~= "behavior"
        or (orderKind ~= "fishing"
            and string.find(behaviorId, "fishing", 1, true) ~= 1)
    then
        return "", ACTION_COLOR, false
    end

    local phase = string.upper(tostring(info.phase or "WAITING"))
    local definition = FISHING_PHASE_LABELS[phase]
        or { fallback = string.lower(string.gsub(phase, "_", " ")) }
    local label = definition.key
        and tr(definition.key, definition.fallback) or definition.fallback
    local jobLabel = tr("UI_PNC_Job_Fishing", "FISHING")
    local percent = math.max(0, math.min(100,
        math.floor(tonumber(info.percent) or 0)))
    local workingLabel = tr("UI_PNC_Action_Working", "Working")
    local text = workingLabel .. " " .. jobLabel .. " - " .. label
        .. " " .. tostring(percent) .. "%"
    if phase == "WORKING" or phase == "WAITING"
        or phase == "ATTEMPT" or phase == "OUTPUT"
    then
        text = text .. " (attempts " .. tostring(info.attemptIndex or 0)
            .. ", catches " .. tostring(info.catches or 0) .. ")"
    end
    if info.waitingReason and tostring(info.waitingReason) ~= ""
        and string.find(phase, "^WAITING", 1) == 1
    then
        text = text .. " (" .. string.lower(string.gsub(
            tostring(info.waitingReason), "_", " ")) .. ")"
    end
    return text, ACTION_COLOR, true
end

function Presentation.WorkActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if not info then return "", ACTION_COLOR, false end
    if info.kind == "return_home" then
        return tr("UI_PNC_Action_ReturningHome", "Returning Home")
            .. "  " .. tostring(math.max(0,
                math.min(100, math.floor(tonumber(info.percent) or 0))))
            .. "%", ACTION_COLOR, true
    end
    if info.kind == "at_home" then
        return tr("UI_PNC_Action_Idle", "Idle"), ACTION_COLOR, true
    end
    if info.kind ~= "work_order" then return "", ACTION_COLOR, false end
    local operation = tostring(info.operation or "")
    local verb, target
    if operation == "CONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Building", "Building"), facilityName(info)
    elseif operation == "RECONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Reconstructing", "Reconstructing"),
            facilityName(info)
    elseif operation == "DECONSTRUCT" then
        verb, target = tr("UI_PNC_Action_Deconstructing", "Deconstructing"),
            facilityName(info)
    elseif operation == "BUILD_OBJECT" then
        verb = tr("UI_PNC_Action_Building", "Building")
        target = tostring(info.buildDisplayName or info.objectInfoName
            or tr("UI_PNC_Action_BuildObjectTarget", "object"))
    elseif operation == "CRAFT" then
        verb, target = tr("UI_PNC_Action_Crafting", "Crafting"), recipeTarget(info)
    elseif operation == "DISASSEMBLE" then
        verb = tr("UI_PNC_Action_Disassembling", "Disassembling")
        target = itemName(info.specimenFullType,
            tr("UI_PNC_Action_ItemTarget", "item"))
    elseif operation == "RESEARCH" then
        verb = tr("UI_PNC_Action_Researching", "Researching")
        local definition = PNC.ColonyResearchDefinitions
            and PNC.ColonyResearchDefinitions.Get(info.technologyId) or nil
        target = definition and tr(definition.labelKey,
            tostring(info.technologyId or "technology"))
            or tr("UI_PNC_Action_KnowledgeTarget", "knowledge")
    elseif operation == "PROVISION_PICKUP" then
        verb = tr("UI_PNC_Action_Grabbing", "Grabbing")
        target = itemName(info.activityItemFullType,
            tr("UI_PNC_Action_ProvisionTarget", "provision"))
    else
        verb = tr("UI_PNC_Action_Working", "Working")
        target = tostring(operation)
    end
    local text = verb .. " " .. target
    local lumberText = lumberActionText(info, target)
    if lumberText then
        return lumberText .. " - " .. actionProgress(info, true),
            ACTION_COLOR, true
    end
    local status = tostring(info.status or "")
    if status == "TRAVEL_TO_STOCKPILE" then
        if operation == "PROVISION_PICKUP" then
            text = text .. " - "
                .. tr("UI_PNC_Action_Traveling", "traveling")
        else
            text = tr("UI_PNC_Action_CollectingMaterials", "Collecting materials for")
                .. " " .. target
        end
    elseif status == "TRAVEL_TO_STATION" then
        text = text .. " - " .. tr("UI_PNC_Action_Traveling", "traveling")
    elseif status == "BLOCKED" then
        text = text .. " - " .. tr("UI_PNC_Action_Blocked", "blocked")
    elseif info.waitingFor then
        local waiting = tostring(info.waitingFor or "")
        local reason = tostring(info.waitingReason or "")
        if reason ~= "" then
            waiting = waiting .. ":" .. reason
        end
        text = text .. " (" .. string.gsub(waiting, "[_:]", " ") .. ")"
    end
    return text .. "  " .. actionProgress(info, false),
        ACTION_COLOR, true
end

function Presentation.ActivityActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if not info or info.kind ~= "activity" then
        return "", ACTION_COLOR, false
    end
    local fallback = tostring(info.fallback or info.activityId or "")
    local text = activityLabel(info, fallback)
    if info.facilityDefinitionId then
        text = text .. " - " .. facilityName(info)
    end
    local activityItem = activityItemName(info)
    if activityItem and activityItem ~= "" then
        text = text .. " - " .. activityItem
    end
    local phase = string.upper(tostring(info.phase or ""))
    if phase == "TRAVELLING" or phase == "TRAVEL" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Traveling", "traveling") .. ")"
    elseif phase == "QUEUED" or phase == "STARTING" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Preparing", "preparing") .. ")"
    elseif phase == "BLOCKED" then
        text = text .. " ("
            .. tr("UI_PNC_Action_Blocked", "blocked") .. ")"
    elseif info.waitingFor then
        local waiting = tostring(info.waitingFor or "")
        local reason = tostring(info.waitingReason or "")
        if reason ~= "" then
            waiting = waiting .. ":" .. reason
        end
        text = text .. " (" .. string.gsub(waiting, "[_:]", " ") .. ")"
    end
    return text, ACTION_COLOR, text ~= ""
end

function Presentation.ActionStatus(snapshot)
    local info = snapshot and snapshot.actionInformation or nil
    if info and info.kind == "treatment" then
        return Presentation.TreatmentStatus(snapshot)
    end
    local fishingText, fishingColor, fishingActive =
        Presentation.FishingActionStatus(snapshot)
    if fishingText ~= "" then
        return fishingText, fishingColor, fishingActive
    end
    local text, color, active = Presentation.ActivityActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    text, color, active = Presentation.WorkActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    return Presentation.TreatmentStatus(snapshot)
end
