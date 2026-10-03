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
    return text .. "  " .. tostring(math.max(0,
        math.min(100, math.floor(tonumber(info.percent) or 0)))) .. "%",
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
    local text, color, active = Presentation.ActivityActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    text, color, active = Presentation.WorkActionStatus(snapshot)
    if text ~= "" then return text, color, active end
    return Presentation.TreatmentStatus(snapshot)
end

