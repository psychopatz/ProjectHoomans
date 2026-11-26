local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal

function Internal.CopyInterrupts(source)
    source = type(source) == "table" and source or {}
    return {
        movement = source.movement ~= false,
        combat = source.combat ~= false,
        externalBump = source.externalBump ~= false,
        abstract = source.abstract ~= false,
    }
end

function Internal.NormalizeProps(raw)
    if type(raw) ~= "table" then return nil end
    local function optText(value)
        if value == nil then return nil end
        local s = tostring(value)
        return s ~= "" and s or nil
    end
    local primary = optText(raw.primary or raw.primaryFullType)
    local secondary = optText(raw.secondary or raw.secondaryFullType)
    local primaryFrom = optText(raw.primaryFrom)
    local secondaryFrom = optText(raw.secondaryFrom)
    local fallbackPrimary = optText(raw.fallbackPrimary)
    local fallbackSecondary = optText(raw.fallbackSecondary)
    local equipmentMode = optText(raw.equipmentMode)
    if not primary and not secondary and not primaryFrom
        and not secondaryFrom and not fallbackPrimary
        and not fallbackSecondary and not equipmentMode
    then
        return nil
    end
    return {
        primary = primary,
        secondary = secondary,
        primaryFrom = primaryFrom,
        secondaryFrom = secondaryFrom,
        fallbackPrimary = fallbackPrimary,
        fallbackSecondary = fallbackSecondary,
        equipmentMode = equipmentMode,
    }
end

function Internal.NormalizeSteps(definition)
    local source = type(definition.steps) == "table"
        and definition.steps or nil
    local steps = {}
    local raw
    local bump
    local i
    if not source or #source <= 0 then
        source = {{
            id = definition.stepId,
            route = definition.route,
            bump = definition.bump or definition.bumpType,
            animVars = definition.animVars or definition.vars,
            durationMs = definition.durationMs,
            loop = definition.loop,
            props = definition.props,
        }}
    end
    for i = 1, #source do
        raw = type(source[i]) == "table"
            and source[i] or { bump = source[i] }
        local route = tostring(raw.route or definition.route or "")
        local animVars = type(raw.animVars) == "table" and raw.animVars
            or (type(raw.vars) == "table" and raw.vars or nil)
        if route == "" then
            route = animVars and not raw.bump and not raw.bumpType
                and "anim_vars" or "bump"
        end
        bump = tostring(raw.bump or raw.bumpType or "")
        if route ~= "anim_vars" and bump == "" then
            return nil, "missing_step_bump"
        end
        if route == "anim_vars" and type(animVars) ~= "table" then
            return nil, "missing_step_anim_vars"
        end
        steps[#steps + 1] = {
            id = tostring(raw.id or raw.key or ("step_" .. tostring(i))),
            route = route,
            bump = bump ~= "" and bump or nil,
            animVars = animVars,
            durationMs = math.max(
                0,
                tonumber(raw.durationMs)
                    or tonumber(definition.durationMs)
                    or 0
            ),
            loop = raw.loop == true,
            props = Internal.NormalizeProps(raw.props),
        }
    end
    return steps
end

function Internal.ResolveRepeatMode(definition, steps)
    local repeatMode = tostring(
        definition.repeatMode or definition.playbackMode or ""
    )
    if repeatMode ~= "loop" and repeatMode ~= "once" then
        repeatMode = (
            definition.sequenceLoop == true
                or (definition.loop == true and #steps == 1)
        ) and "loop" or "once"
    end
    if repeatMode == "loop"
        and #steps == 1
        and steps[1].durationMs <= 0
    then
        steps[1].loop = true
    end
    return repeatMode
end

function Internal.NormalizeDefinition(sceneId, definition, steps)
    local repeatMode = Internal.ResolveRepeatMode(definition, steps)
    return {
        id = sceneId,
        bump = steps[1].bump,
        steps = steps,
        durationMs = math.max(0, tonumber(definition.durationMs) or 0),
        priority = tonumber(definition.priority) or 10,
        loop = steps[1].loop == true,
        blocking = definition.blocking == true,
        keepManagedUseless = definition.keepManagedUseless == true,
        -- Some multi-step scenes are one continuous pose lease. Their
        -- selector may change between compatible looped clips, but the
        -- managed body must not leave the action state between steps.
        retainBump = definition.retainBump == true,
        pool = definition.pool and tostring(definition.pool) or nil,
        category = tostring(
            definition.category
                or string.match(sceneId, "^([^%.]+)")
                or "other"
        ),
        label = tostring(definition.label or sceneId),
        description = tostring(definition.description or ""),
        weight = math.max(0, tonumber(definition.weight) or 1),
        sequenceMode = definition.sequenceMode == "shuffle"
            and "shuffle" or "ordered",
        repeatMode = repeatMode,
        sequenceLoop = repeatMode == "loop",
        stepGapMs = math.max(0, tonumber(definition.stepGapMs) or 0),
        stepGapJitterMs = math.max(
            0,
            tonumber(definition.stepGapJitterMs) or 0
        ),
        props = Internal.NormalizeProps(definition.props),
        interrupts = Internal.CopyInterrupts(definition.interrupts),
        onTick = type(definition.onTick) == "function"
            and definition.onTick or nil,
        onStart = type(definition.onStart) == "function"
            and definition.onStart or nil,
        onStop = type(definition.onStop) == "function"
            and definition.onStop or nil,
    }
end
