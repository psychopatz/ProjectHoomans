--[[
    Project Hoomans action-prop descriptors.

    An action prop is a transient visual item owned by the current animation
    action.  It is intentionally separate from persistent equipment: the
    descriptor says what belongs in each hand, while the client host owns the
    engine hand-model override.
]]

PNC = PNC or {}
PNC.ActionProps = PNC.ActionProps or {}

local ActionProps = PNC.ActionProps

local function value(source, key)
    return source and source[key] or nil
end

local function text(source, key)
    return tostring(value(source, key) or "")
end

local function sceneRevision(visual)
    return value(visual, "sceneStartedAt")
        or value(visual, "sceneRevision")
        or nil
end

local function buildDescriptor(
    source,
    action,
    visual,
    fullType,
    itemID,
    hand,
    revision
)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end
    hand = tostring(hand or "primary")
    if hand ~= "secondary" and hand ~= "both" then
        hand = "primary"
    end
    return {
        source = source,
        primaryFullType = (hand == "primary" or hand == "both")
            and fullType or nil,
        secondaryFullType = (hand == "secondary" or hand == "both")
            and fullType or nil,
        primaryItemID = (hand == "primary" or hand == "both")
            and itemID or nil,
        secondaryItemID = (hand == "secondary" or hand == "both")
            and itemID or nil,
        primaryVisual = (hand == "primary" or hand == "both")
            and value(action, "activityItemVisual") or nil,
        secondaryVisual = (hand == "secondary" or hand == "both")
            and value(action, "activityItemVisual") or nil,
        primaryState = (hand == "primary" or hand == "both")
            and value(action, "activityItemState") or nil,
        secondaryState = (hand == "secondary" or hand == "both")
            and value(action, "activityItemState") or nil,
        hand = hand,
        sceneId = value(visual, "sceneId"),
        sceneStepId = value(visual, "sceneStepId"),
        revision = revision or sceneRevision(visual),
    }
end

local function sceneIs(visual, expected)
    return text(visual, "sceneId") == expected
end

local function resolveScenePropSpec(visual)
    if type(visual) ~= "table" then return nil end
    if visual.propPrimary or visual.propSecondary then
        return {
            primary = visual.propPrimary,
            secondary = visual.propSecondary,
            equipmentMode = visual.propEquipmentMode,
        }, "visual_override"
    end
    local sceneId = text(visual, "sceneId")
    if sceneId == "" then return nil end
    local scenes = PNC.AnimationScenes
    local def = scenes and type(scenes.Get) == "function"
        and scenes.Get(sceneId) or nil
    if type(def) ~= "table" then return nil end
    local stepId = text(visual, "sceneStepId")
    if stepId ~= "" and type(def.steps) == "table" then
        for i = 1, #def.steps do
            local step = def.steps[i]
            if step and tostring(step.id or "") == stepId and step.props then
                return step.props, "scene_step"
            end
        end
    end
    if def.props then return def.props, "scene_default" end
    return nil
end

local function buildDeclaredDescriptor(source, spec, action, visual)
    local actionItem = text(action, "activityItemFullType")
    local actionItemID = value(action, "activityItemID")
    local primaryType = spec.primary
    local primaryItemID
    if not primaryType and spec.primaryFrom == "action_item" then
        primaryType = actionItem ~= "" and actionItem or spec.fallbackPrimary
        if actionItem ~= "" then primaryItemID = actionItemID end
    elseif not primaryType then
        primaryType = spec.fallbackPrimary
    end
    local secondaryType = spec.secondary
    local secondaryItemID
    if not secondaryType and spec.secondaryFrom == "action_item" then
        secondaryType = actionItem ~= "" and actionItem or spec.fallbackSecondary
        if actionItem ~= "" then secondaryItemID = actionItemID end
    elseif not secondaryType then
        secondaryType = spec.fallbackSecondary
    end
    if (not primaryType or primaryType == "")
        and (not secondaryType or secondaryType == "")
    then
        return nil
    end
    local hand = (primaryType and secondaryType) and "both"
        or (secondaryType and "secondary" or "primary")
    return {
        source = source,
        primaryFullType = primaryType,
        secondaryFullType = secondaryType,
        primaryItemID = primaryItemID,
        secondaryItemID = secondaryItemID,
        primaryVisual = primaryItemID ~= nil
            and value(action, "activityItemVisual") or nil,
        secondaryVisual = secondaryItemID ~= nil
            and value(action, "activityItemVisual") or nil,
        primaryState = primaryItemID ~= nil
            and value(action, "activityItemState") or nil,
        secondaryState = secondaryItemID ~= nil
            and value(action, "activityItemState") or nil,
        hand = hand,
        equipmentMode = spec.equipmentMode,
        sceneId = value(visual, "sceneId"),
        sceneStepId = value(visual, "sceneStepId"),
        revision = sceneRevision(visual),
    }
end

function ActionProps.Resolve(snapshot)
    local action = snapshot and snapshot.actionInformation or nil
    local visual = snapshot and snapshot.visualState or nil
    local workPresentation = snapshot and snapshot.workPresentation or nil
    local capability = text(action, "capability")
    local actionKind = text(action, "kind")
    local operation = text(action, "operation")
    local treatmentPhase = text(action, "phase")
    local medical = snapshot and snapshot.medicalCareState or nil
    local medicalPhase = text(medical, "phase")
    local fullType = text(action, "activityItemFullType")
    local itemID = value(action, "activityItemID")

    if visual and visual.attackActive == true then
        return nil
    end

    local hasExplicitVisualProp = type(visual) == "table"
        and (visual.propPrimary ~= nil or visual.propSecondary ~= nil)
    if snapshot and snapshot.attackMode == true and not hasExplicitVisualProp then
        return nil
    end

    -- First-class data-driven hand props declared on the active scene step,
    -- AnimationPack override, or Choreography visual override.
    local propSpec, propSource = resolveScenePropSpec(visual)
    if propSpec then
        local declared = buildDeclaredDescriptor(
            propSource, propSpec, action, visual)
        if declared then return declared end
    end

    -- Vanilla eating and drinking actions put the consumed item in the
    -- secondary action hand.  This is the important distinction from the old
    -- native-hand writer, which always forced primary.
    if (capability == "food.dine"
        or capability == "survival.eat.inventory")
        and sceneIs(visual, "survival.eat.inventory")
    then
        return buildDescriptor(
            "food", action, visual, fullType, itemID, "secondary")
    end
    if capability == "survival.drink.inventory"
        and sceneIs(visual, "survival.drink.inventory")
    then
        return buildDescriptor(
            "hydration", action, visual, fullType, itemID, "secondary")
    end
    if capability == "survival.fill.water"
        and sceneIs(visual, "survival.fill.water")
    then
        return buildDescriptor(
            "water_refill", action, visual, fullType, itemID, "secondary")
    end
    if capability == "survival.drink.world"
        and sceneIs(visual, "survival.drink.world")
    then
        return buildDescriptor(
            "world_water", action, visual, fullType, itemID, "secondary")
    end

    -- Bandages are deliberately not props.  ISApplyBandage uses nil/nil and
    -- the treatment presentation must preserve that vanilla hand contract.
    if actionKind == "treatment" and treatmentPhase == "bandaging" then
        return nil
    end
    if medicalPhase == "treating" then
        return nil
    end

    -- Work snapshots often expose an input, recipe material, seed, or loot
    -- candidate.  Those are not proof that the vanilla action is holding
    -- that item, so do not turn them into hand props.  Producers that know
    -- their actual held tool can publish an explicit action item later.
    if (text(action, "job") == "Fishing"
        or text(action, "orderKind") == "fishing")
        and sceneIs(visual, "fishing.cast")
    then
        if fullType == "" then
            fullType = text(workPresentation, "fullType")
        end
        if itemID == nil then
            itemID = value(workPresentation, "itemID")
        end
        return buildDescriptor(
            "fishing", action, visual, fullType, itemID, "primary")
    end
    if operation == "LUMBER"
        and sceneIs(visual, "lumber.chop")
    then
        return buildDescriptor(
            "lumber", action, visual, fullType, itemID, "primary")
    end
    return nil
end

function ActionProps.BuildKey(descriptor)
    if not descriptor then return "" end
    return table.concat({
        tostring(descriptor.source or ""),
        tostring(descriptor.primaryFullType or ""),
        tostring(descriptor.secondaryFullType or ""),
        tostring(descriptor.primaryItemID or ""),
        tostring(descriptor.secondaryItemID or ""),
        tostring(descriptor.revision or ""),
    }, "|")
end

return ActionProps
