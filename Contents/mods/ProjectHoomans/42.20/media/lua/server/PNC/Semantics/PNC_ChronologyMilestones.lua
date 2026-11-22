-- Bounded data-driven personal chronology milestones and anniversaries.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero math.random(), zero OnTick polling.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Milestones = PNC.Semantics.ChronologyMilestones or {}
PNC.Semantics.ChronologyMilestones = Milestones

Milestones.VERSION = 1
Milestones.DEFAULT_ANNIVERSARY_HOURS = 8760
Milestones.DEFAULT_PUMP_BUDGET = 8
Milestones.SALIENT_MIN_SEVERITY = 0.60

Milestones._pumpCursor = Milestones._pumpCursor or 1
Milestones._metrics = Milestones._metrics or {
    evaluations = 0,
    triggered = 0,
    beatsDelivered = 0,
    scenesTriggered = 0,
    factsPublished = 0,
}

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function clamp(value, low, high)
    local num = finite(value, low)
    if num < low then return low end
    if num > high then return high end
    return num
end

local function copyTable(tbl)
    local out = {}
    if type(tbl) ~= "table" then return out end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = copyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

Milestones.DEFINITIONS = Milestones.DEFINITIONS or {}
Milestones.DEFINITION_ORDER = Milestones.DEFINITION_ORDER or {}

local function addBuiltIn(def)
    if type(def) ~= "table" or not def.id then return end
    local id = tostring(def.id)
    if not Milestones.DEFINITIONS[id] then
        Milestones.DEFINITION_ORDER[#Milestones.DEFINITION_ORDER + 1] = id
    end
    Milestones.DEFINITIONS[id] = def
end

addBuiltIn({
    id = "first_week",
    label = "First Week Survived",
    kind = "survival_age",
    ageHours = 168,
    severity = 0.35,
    beatPriority = 38,
    sceneFollowUp = false,
    demeanor = { moraleHope = 8, confidencePressure = -4 },
    summary = "Made it through the first week alive.",
})

addBuiltIn({
    id = "first_month",
    label = "First Month Survived",
    kind = "survival_age",
    ageHours = 720,
    severity = 0.50,
    beatPriority = 44,
    sceneFollowUp = true,
    demeanor = { moraleHope = 12, confidencePressure = -6 },
    summary = "Survived a full month in the apocalypse.",
})

addBuiltIn({
    id = "first_season",
    label = "First Season Survived",
    kind = "survival_age",
    ageHours = 2160,
    severity = 0.65,
    beatPriority = 48,
    sceneFollowUp = true,
    demeanor = { moraleHope = 15, confidencePressure = -8 },
    summary = "Endured an entire season out here.",
})

addBuiltIn({
    id = "first_year",
    label = "First Year Survived",
    kind = "survival_age",
    ageHours = 8760,
    severity = 0.85,
    beatPriority = 55,
    sceneFollowUp = true,
    demeanor = { moraleHope = 22, confidencePressure = -12 },
    summary = "Survived a full year since the outbreak.",
})

local function sortDefinitions()
    table.sort(Milestones.DEFINITION_ORDER, function(a, b)
        local da = Milestones.DEFINITIONS[a]
        local db = Milestones.DEFINITIONS[b]
        local aa = tonumber(da and da.ageHours) or 0
        local ab = tonumber(db and db.ageHours) or 0
        if aa == ab then return a < b end
        return aa < ab
    end)
end
sortDefinitions()

function Milestones.RegisterDefinition(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or def.id == "" then
        return false, "invalid_milestone_definition"
    end
    local age = finite(def.ageHours, nil)
    if not age or age <= 0 then
        return false, "invalid_milestone_age_hours"
    end
    local copy = copyTable(def)
    copy.kind = tostring(copy.kind or "survival_age")
    copy.ageHours = age
    copy.severity = clamp(copy.severity or 0.5, 0, 1)
    copy.beatPriority = tonumber(copy.beatPriority) or 42
    if not Milestones.DEFINITIONS[copy.id] then
        Milestones.DEFINITION_ORDER[#Milestones.DEFINITION_ORDER + 1] = copy.id
    end
    Milestones.DEFINITIONS[copy.id] = copy
    sortDefinitions()
    return true, copy
end

function Milestones.GetDefinitions(customDefs)
    local out = {}
    if type(customDefs) == "table" then
        for i = 1, #customDefs do
            if type(customDefs[i]) == "table" and customDefs[i].id then
                out[#out + 1] = customDefs[i]
            end
        end
        table.sort(out, function(a, b)
            local aa = tonumber(a.ageHours) or 0
            local ab = tonumber(b.ageHours) or 0
            if aa == ab then return tostring(a.id) < tostring(b.id) end
            return aa < ab
        end)
        return out
    end
    for i = 1, #Milestones.DEFINITION_ORDER do
        local def = Milestones.DEFINITIONS[Milestones.DEFINITION_ORDER[i]]
        if def then out[#out + 1] = def end
    end
    return out
end

local function resolveBasePersonality(record)
    local projection = PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if projection and type(projection.Resolve) == "function" then
        local resolved = projection.Resolve(record, { temporaryDemeanor = {} })
        if resolved and resolved.baseDisposition then
            return resolved.baseDisposition
        end
    end
    return {
        bravery = 50, confidence = 50, aggression = 50, compassion = 50,
        sociability = 50, forgiveness = 50, materialism = 50, loyalty = 50,
    }
end

local function modulateDemeanorForMilestone(record, milestone)
    local base = resolveBasePersonality(record)
    local confidence = (tonumber(base.confidence) or 50) / 100
    local bravery = (tonumber(base.bravery) or 50) / 100
    local compassion = (tonumber(base.compassion) or 50) / 100
    local sociability = (tonumber(base.sociability) or 50) / 100
    local template = type(milestone.demeanor) == "table" and milestone.demeanor or {}

    local hopeScale = 0.65 + 0.55 * confidence + 0.25 * sociability
    local pressureScale = 1.30 - 0.60 * ((bravery + confidence) * 0.5)
    local griefScale = 0.70 + 0.65 * compassion

    local out = {}
    if template.moraleHope ~= nil then
        local raw = tonumber(template.moraleHope) or 0
        out.moraleHope = math.floor((raw * hopeScale) * 100 + 0.5) / 100
    end
    if template.confidencePressure ~= nil then
        local raw = tonumber(template.confidencePressure) or 0
        out.confidencePressure = math.floor((raw * pressureScale) * 100 + 0.5) / 100
    end
    if template.griefStress ~= nil then
        local raw = tonumber(template.griefStress) or 0
        out.griefStress = math.floor((raw * griefScale) * 100 + 0.5) / 100
    end
    if template.vigilanceFear ~= nil then
        local raw = tonumber(template.vigilanceFear) or 0
        out.vigilanceFear = math.floor((raw * pressureScale) * 100 + 0.5) / 100
    end
    return out
end

local function applyTransientDemeanor(record, delta, nowHours, opts)
    local director = PNC.ScopedWorldEventDirector
    if director and type(director.ApplyActorImpulse) == "function" then
        return director.ApplyActorImpulse(record, delta, nowHours, {
            halfLifeHours = (opts and opts.impulseHalfLifeHours) or 48,
            durationHours = (opts and opts.impulseDurationHours) or 192,
        })
    end
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local cur = type(record.runtime.temporaryDemeanor) == "table"
        and copyTable(record.runtime.temporaryDemeanor) or {}
    for axis, val in pairs(delta) do
        cur[axis] = clamp((tonumber(cur[axis]) or 0) + (tonumber(val) or 0), -50, 50)
    end
    record.runtime.temporaryDemeanor = cur
    return cur
end

local function emitMilestoneFact(record, milestone, nowHours, ageHours)
    local wk = PNC.WorldKnowledge
    if not wk or type(wk.Publish) ~= "function" or not wk.Core then
        return nil
    end
    local actorID = wk.ActorID and wk.ActorID(record) or tostring(record.coreActorID or record.id or "")
    if actorID == "" then return nil end

    local fact = wk.Publish({
        producer = "hoomans:chronology",
        kind = "actor.milestone",
        subject = {
            id = actorID,
            kind = "npc",
            name = tostring(record.name or record.displayName or actorID),
        },
        eventID = tostring(milestone.eventID or ("milestone:" .. actorID .. ":" .. tostring(milestone.id))),
        occurredAt = nowHours,
        observedAt = nowHours,
        severity = tonumber(milestone.severity) or 0.5,
        retention = "historical",
        payload = {
            milestoneID = tostring(milestone.id),
            category = tostring(milestone.kind or "survival_age"),
            label = tostring(milestone.label or milestone.id),
            ageHours = ageHours,
            summary = tostring(milestone.summary or milestone.label or milestone.id),
        },
    })
    if fact then
        wk.Core.Acquire(actorID, fact.factID, {
            authorized = true,
            provenance = "experienced",
            confidence = 1.0,
            source = "personal_chronology",
            acquisitionPath = "experienced",
            learnedAt = nowHours,
        })
        Milestones._metrics.factsPublished = Milestones._metrics.factsPublished + 1
    end
    return fact
end

local function resolveSocialStyle(record)
    local style = type(record) == "table" and tostring(record.socialStyle or "") or ""
    if style == "friendly" or style == "protective" or style == "warm" then
        return "warm"
    end
    if style == "withdrawn" or style == "guarded" or style == "hostile" then
        return "guarded"
    end
    local p = type(record) == "table" and type(record.personality) == "table"
        and record.personality or nil
    if p then
        local warmth = (tonumber(p.friendliness) or tonumber(p.empathy) or 50)
        local caution = (tonumber(p.caution) or tonumber(p.paranoia) or 50)
        if warmth >= 65 then return "warm" end
        if caution >= 65 then return "guarded" end
    end
    return "steady"
end

local function resolveMilestoneStage(milestone)
    local kind = tostring(milestone and milestone.kind or "survival_age")
    if kind == "anniversary" then return "anniversary" end
    local id = tostring(milestone and milestone.id or "")
    if id == "first_week" or id == "first_month"
        or id == "first_season" or id == "first_year"
    then
        return id
    end
    return "first_week"
end

local function resolveAddresseeName(record)
    local envBeats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    if envBeats and type(envBeats.FindNearestPlayerName) == "function" then
        return tostring(envBeats.FindNearestPlayerName(record.x, record.y) or "friend")
    end
    return "friend"
end

local function deliverMilestoneBeat(record, milestone, fact, nowMs, opts)
    local transport = PNC.Semantics and PNC.Semantics.SpeechTransport
    if not transport or type(transport.Deliver) ~= "function" then
        return 0
    end
    local role = tostring(milestone.kind or "survival_age") == "anniversary"
        and "chronology_anniversary" or "chronology_milestone"
    local stage = resolveMilestoneStage(milestone)
    local socialStyle = resolveSocialStyle(record)
    local addresseeName = resolveAddresseeName(record)
    local sent = transport.Deliver(record, nowMs, {
        eventType = "chronology_milestone_beat",
        eventRef = "milestone:" .. tostring(milestone.id) .. ":" .. tostring(record.id),
        poolID = "semantic.world.chronology.milestone",
        domain = "chronology",
        topic = "chronology",
        channel = "chronology",
        lane = "beat",
        family = "chronology_milestone",
        threadID = "chronology:" .. tostring(record.id) .. ":" .. tostring(milestone.id),
        priority = tonumber(milestone.beatPriority) or 44,
        role = role,
        factRefs = fact and { fact.factID } or {},
        tokens = {
            ["addressee.name"] = addresseeName,
            ["npc.name"] = tostring(record.name or "Survivor"),
        },
        context = {
            combatReactionRole = role,
            milestoneID = tostring(milestone.id),
            milestoneStage = stage,
            milestoneKind = tostring(milestone.kind or "survival_age"),
            socialStyle = socialStyle,
        },
    })
    if (tonumber(sent) or 0) > 0 then
        Milestones._metrics.beatsDelivered = Milestones._metrics.beatsDelivered + 1
    end

    if milestone.sceneFollowUp == true and opts.triggerScene ~= false then
        local adopters = PNC.ConvoEngine and PNC.ConvoEngine.InteractionSceneAdopters
        if adopters and type(adopters.OnWorldKnowledgeFact) == "function" and fact then
            local ok = adopters.OnWorldKnowledgeFact({
                factID = fact.factID,
                eventID = fact.eventID,
                kind = fact.kind,
                factionID = record.affiliation and record.affiliation.factionID or nil,
                x = tonumber(record.x),
                y = tonumber(record.y),
                z = tonumber(record.z),
                relevance = 0.72,
                priority = 36,
            })
            if ok == true then
                Milestones._metrics.scenesTriggered = Milestones._metrics.scenesTriggered + 1
            end
        end
    end
    return tonumber(sent) or 0
end

local function collectSalientFacts(record, opts)
    if type(opts) == "table" and type(opts.rememberedFacts) == "table" then
        return opts.rememberedFacts
    end
    local wk = PNC.WorldKnowledge
    if not wk or not wk.Core or not wk.Core.ActorKnowledge then return {} end
    local actorID = wk.ActorID and wk.ActorID(record) or tostring(record.coreActorID or record.id or "")
    if actorID == "" then return {} end
    local selected = wk.Core.ActorKnowledge.Select(
        wk.Core.KnowledgeState, wk.Core.LedgerState, actorID, { max = 8 }
    )
    local out = {}
    for i = 1, #selected do
        local item = selected[i]
        if item and item.fact and item.epistemicStatus == "known" then
            out[#out + 1] = item.fact
        end
    end
    return out
end

local function collectAnniversaries(record, prevWorldAge, nowHours, opts)
    local interval = math.max(1, finite(opts and opts.anniversaryIntervalHours,
        Milestones.DEFAULT_ANNIVERSARY_HOURS) or Milestones.DEFAULT_ANNIVERSARY_HOURS)
    local minSeverity = finite(opts and opts.salientMinSeverity, Milestones.SALIENT_MIN_SEVERITY)
        or Milestones.SALIENT_MIN_SEVERITY
    local facts = collectSalientFacts(record, opts)
    local out = {}
    for i = 1, #facts do
        local fact = facts[i]
        if type(fact) == "table"
            and fact.kind ~= "actor.milestone"
            and fact.retention == "historical"
            and (tonumber(fact.severity) or 0) >= minSeverity
        then
            local occurredAt = tonumber(fact.occurredAt)
            if occurredAt ~= nil and nowHours > occurredAt then
                local currentAnniv = math.floor((nowHours - occurredAt) / interval)
                local prevElapsed = prevWorldAge >= 0 and math.max(0, prevWorldAge - occurredAt) or 0
                local prevAnniv = math.floor(prevElapsed / interval)
                if currentAnniv >= 1 and currentAnniv > prevAnniv then
                    local grim = fact.kind == "npc.death" or fact.kind == "faction.status"
                    out[#out + 1] = {
                        id = "anniversary_" .. tostring(fact.factID or fact.eventID or i) .. "_" .. tostring(currentAnniv),
                        eventID = "anniv:" .. tostring(record.id) .. ":" .. tostring(fact.factID or i) .. ":" .. tostring(currentAnniv),
                        kind = "anniversary",
                        label = "Remembered Event Anniversary",
                        severity = tonumber(fact.severity) or 0.7,
                        beatPriority = 42,
                        sceneFollowUp = false,
                        demeanor = grim
                            and { griefStress = 10, confidencePressure = 6, moraleHope = -4 }
                            or { moraleHope = 6, confidencePressure = -3 },
                        summary = "Still remembering what happened " .. tostring(currentAnniv) .. " cycle(s) ago.",
                    }
                    if #out >= 2 then break end
                end
            end
        end
    end
    return out
end

function Milestones.EvaluateActor(record, nowWorldAgeHours, opts)
    if type(record) ~= "table" or record.alive == false or record.id == nil then
        return {}, "actor_unavailable"
    end
    opts = type(opts) == "table" and opts or {}
    local nowHours = math.max(0, finite(nowWorldAgeHours, 0) or 0)

    if record.survivalStartHours == nil then
        if opts.survivalStartHours ~= nil then
            record.survivalStartHours = math.max(0, finite(opts.survivalStartHours, nowHours) or nowHours)
        elseif record.lastMilestoneHours ~= nil then
            record.survivalStartHours = 0
        else
            record.survivalStartHours = nowHours
        end
    end

    local startHours = math.max(0, finite(record.survivalStartHours, nowHours) or nowHours)
    local ageHours = math.max(0, nowHours - startHours)
    local prevWatermark = record.lastMilestoneHours ~= nil
        and finite(record.lastMilestoneHours, -1) or -1
    local prevWorldAge = prevWatermark >= 0 and (startHours + prevWatermark) or -1

    Milestones._metrics.evaluations = Milestones._metrics.evaluations + 1
    if ageHours <= prevWatermark then
        return {}, "already_evaluated"
    end

    local triggered = {}
    local defs = Milestones.GetDefinitions(opts.definitions)
    for i = 1, #defs do
        local def = defs[i]
        local threshold = tonumber(def.ageHours) or 0
        if threshold > prevWatermark and threshold <= ageHours then
            triggered[#triggered + 1] = def
        end
    end

    local anniversaries = collectAnniversaries(record, prevWorldAge, nowHours, opts)
    for i = 1, #anniversaries do
        triggered[#triggered + 1] = anniversaries[i]
    end

    local nowMs = finite(opts.nowMs, nil)
        or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()))
        or (nowHours * 3600000)

    local results = {}
    for i = 1, #triggered do
        local milestone = triggered[i]
        local fact = emitMilestoneFact(record, milestone, nowHours, ageHours)
        local delta = modulateDemeanorForMilestone(record, milestone)
        local demeanor = applyTransientDemeanor(record, delta, nowHours, opts)
        local beatCount = deliverMilestoneBeat(record, milestone, fact, nowMs, opts)
        Milestones._metrics.triggered = Milestones._metrics.triggered + 1
        results[#results + 1] = {
            milestoneID = milestone.id,
            kind = milestone.kind,
            ageHours = ageHours,
            fact = fact,
            demeanorDelta = delta,
            temporaryDemeanor = demeanor,
            beatSent = beatCount,
        }
    end

    record.lastMilestoneHours = ageHours
    if #results > 0 then
        record.milestoneCount = math.max(0, math.floor(tonumber(record.milestoneCount) or 0)) + #results
        if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
            PNC.Registry.MarkDirty(record, "chronology_milestone")
        end
    end

    return results, #results > 0 and "triggered" or "none"
end

function Milestones.PumpBatch(nowWorldAgeHours, budget, opts)
    local reg = PNC.Registry
    local data = reg and reg.Data
    if type(data) ~= "table" then return 0, 0 end

    local ids = {}
    for id, record in pairs(data) do
        if type(record) == "table" and record.alive ~= false then
            ids[#ids + 1] = tostring(id)
        end
    end
    table.sort(ids)
    if #ids == 0 then
        Milestones._pumpCursor = 1
        return 0, 0
    end

    local maxCount = math.max(1, math.floor(tonumber(budget) or Milestones.DEFAULT_PUMP_BUDGET))
    local evaluated = 0
    local triggeredCount = 0
    local cursor = math.max(1, math.min(#ids, tonumber(Milestones._pumpCursor) or 1))
    local steps = math.min(#ids, maxCount)
    for _ = 1, steps do
        local record = data[ids[cursor]]
        if record and record.alive ~= false then
            local res = Milestones.EvaluateActor(record, nowWorldAgeHours, opts)
            evaluated = evaluated + 1
            triggeredCount = triggeredCount + #(res or {})
        end
        cursor = cursor + 1
        if cursor > #ids then cursor = 1 end
    end
    Milestones._pumpCursor = cursor
    return evaluated, triggeredCount
end

function Milestones.ResetRuntime()
    Milestones._pumpCursor = 1
    Milestones._metrics = {
        evaluations = 0,
        triggered = 0,
        beatsDelivered = 0,
        scenesTriggered = 0,
        factsPublished = 0,
    }
end

return Milestones
