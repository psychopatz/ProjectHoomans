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

function ActionProps.Resolve(snapshot)
    local action = snapshot and snapshot.actionInformation or nil
    local visual = snapshot and snapshot.visualState or nil
    local capability = text(action, "capability")
    local actionKind = text(action, "kind")
    local operation = text(action, "operation")
    local treatmentPhase = text(action, "phase")
    local medical = snapshot and snapshot.medicalCareState or nil
    local medicalPhase = text(medical, "phase")
    local fullType = text(action, "activityItemFullType")
    local itemID = value(action, "activityItemID")

    if snapshot and snapshot.attackMode == true
        or visual and visual.attackActive == true
    then
        return nil
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
