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
            bump = definition.bump,
            durationMs = definition.durationMs,
            loop = definition.loop,
        }}
    end
    for i = 1, #source do
        raw = type(source[i]) == "table"
            and source[i] or { bump = source[i] }
        bump = tostring(raw.bump or "")
        if bump == "" then
            return nil, "missing_step_bump"
        end
        steps[#steps + 1] = {
            id = tostring(raw.id or raw.key or ("step_" .. tostring(i))),
            bump = bump,
            durationMs = math.max(
                0,
                tonumber(raw.durationMs)
                    or tonumber(definition.durationMs)
                    or 0
            ),
            loop = raw.loop == true,
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
        interrupts = Internal.CopyInterrupts(definition.interrupts),
        onTick = type(definition.onTick) == "function"
            and definition.onTick or nil,
        onStop = type(definition.onStop) == "function"
            and definition.onStop or nil,
    }
end
