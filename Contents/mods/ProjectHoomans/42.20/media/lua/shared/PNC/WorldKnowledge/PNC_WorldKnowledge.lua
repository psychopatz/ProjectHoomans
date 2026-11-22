PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
PNC.WorldKnowledge = PNC.WorldKnowledge or {}

local Adapter = PNC.WorldKnowledge
local loaded, CoreWKG = pcall(require,
    "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge")
if not loaded or type(CoreWKG) ~= "table" then CoreWKG = nil end

Adapter.VERSION = 1
Adapter.Core = CoreWKG
Adapter.MAX_GOSSIP = 4

local function actorID(record)
    local runtime = record and record.runtime or nil
    local id = record and (record.coreActorID or record.id) or nil
    id = id or runtime and runtime.coreActorID
    id = tostring(id or "")
    return id ~= "" and id or nil
end

local function now()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

local function recordFor(id)
    return PNC.Registry and type(PNC.Registry.Get) == "function"
        and PNC.Registry.Get(id) or nil
end

local function factionFor(record)
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    if not factionID or not PNC.Factions
        or type(PNC.Factions.Get) ~= "function"
    then return nil end
    return PNC.Factions.Get(factionID)
end

local function acquire(record, factID, provenance, options)
    if not CoreWKG or not record or not factID then return nil end
    options = type(options) == "table" and options or {}
    return CoreWKG.Acquire(actorID(record), factID, {
        authorized = true, provenance = provenance,
        confidence = options.confidence, source = options.source or "hoomans",
        acquisitionPath = options.acquisitionPath or provenance,
        learnedAt = options.learnedAt or now(),
    })
end

local function acquireFaction(factionID, factID, options)
    local faction = PNC.Factions and PNC.Factions.Get
        and PNC.Factions.Get(factionID) or nil
    local members = faction and faction.memberIDs or nil
    local count = 0
    if type(members) ~= "table" then return count end
    for npcID, _ in pairs(members) do
        local record = recordFor(npcID)
        if record and record.alive ~= false
            and acquire(record, factID, "faction", options)
        then count = count + 1 end
    end
    return count
end

local function safeName(record)
    return tostring(record and (record.name or record.displayName) or "unknown")
end

local function causeFor(record, damageEvent, reason)
    local kind = damageEvent and tostring(damageEvent.attackerKind or "") or ""
    local attackerID = damageEvent and (damageEvent.attackerID
        or damageEvent.attackerZombieID or damageEvent.attackerZombieId) or nil
    if kind == "zombie" or tostring(reason or "") == "zombie_infection" then
        return "zombie", attackerID, true
    end
    if kind == "player" then return "player", attackerID, true end
    if kind == "npc" or kind == "foreign_npc" or kind == "managed_npc" then
        return "hostile_npc", attackerID, true
    end
    return "unknown", attackerID, false
end

function Adapter.ActorID(record)
    return actorID(record)
end

function Adapter.Publish(specification, options)
    if not CoreWKG then return nil, "core_world_knowledge_unavailable" end
    return CoreWKG.Publish(specification, options)
end

function Adapter.PublishZombiePressure(record, count, source, at)
    local value = math.max(0, tonumber(count) or 0)
    local classified = PNC.ZombieObservation
        and type(PNC.ZombieObservation.Classify) == "function"
        and PNC.ZombieObservation.Classify(value) or nil
    local band = classified and classified.knowledgeBand
        or value >= 12 and "horde"
        or value >= 6 and "heavy"
        or value >= 3 and "moderate"
        or "light"
    local fact = Adapter.Publish({
        producer = "hoomans:zombie", kind = "zombie.pressure",
        subject = { id = actorID(record) or tostring(record and record.id or "unknown"), kind = "npc" },
        eventID = tostring(record and record.id or "unknown") .. ":" .. band
            .. ":" .. tostring(math.floor((tonumber(at) or now()) / 24)),
        occurredAt = tonumber(at) or now(), observedAt = tonumber(at) or now(),
        severity = math.min(1, value / 12), retention = "historical",
        payload = {
            band = band,
            pressureBand = classified and classified.band or nil,
            count = value,
            source = tostring(source or "combat"),
        },
    })
    if fact then acquire(record, fact.factID, "experienced", {
        confidence = 1, source = "zombie_hazard_sensing",
        acquisitionPath = source, learnedAt = at,
    }) end
    return fact
end

function Adapter.PublishDeath(record, damageEvent, reason, at)
    local cause, attackerID, known = causeFor(record, damageEvent, reason)
    local faction = factionFor(record)
    local fact = Adapter.Publish({
        producer = "hoomans:health", kind = "npc.death",
        subject = { id = tostring(record and record.id or "unknown"), kind = "npc", name = safeName(record) },
        object = faction and { id = tostring(faction.id), kind = "faction", name = faction.name } or nil,
        cause = { id = cause, kind = "death_cause" },
        eventID = "death:" .. tostring(record and record.id or "unknown")
            .. ":" .. tostring(at or now()),
        occurredAt = tonumber(at) or now(), observedAt = tonumber(at) or now(),
        severity = 1, retention = "historical",
        payload = { cause = cause, causeKnown = known, attackerID = attackerID,
            factionID = faction and faction.id or nil, reason = tostring(reason or "unknown") },
    })
    if not fact then return nil end
    if faction then acquireFaction(faction.id, fact.factID, {
        source = "faction_death_record", acquisitionPath = "faction",
        confidence = known and 0.95 or 0.7, learnedAt = at,
    }) end
    local sceneAdopters = PNC.ConvoEngine and PNC.ConvoEngine.InteractionSceneAdopters or nil
    if sceneAdopters
        and type(sceneAdopters.OnWorldKnowledgeFact) == "function"
    then
        sceneAdopters.OnWorldKnowledgeFact({
            factID = fact.factID,
            eventID = fact.eventID,
            kind = fact.kind,
            factionID = faction and faction.id or nil,
            x = tonumber(record and record.x),
            y = tonumber(record and record.y),
            z = tonumber(record and record.z),
        })
    end
    return fact
end

function Adapter.PublishIncident(actorFactionID, victimFactionID, incidentType, result, at)
    local fact = Adapter.Publish({
        producer = "hoomans:faction", kind = "faction.incident",
        subject = { id = tostring(actorFactionID), kind = "faction" },
        object = { id = tostring(victimFactionID), kind = "faction" },
        eventID = tostring(result and result.incident and result.incident.id
            or incidentType .. ":" .. tostring(at or now())),
        occurredAt = tonumber(at) or now(), observedAt = tonumber(at) or now(),
        severity = result and result.incident and result.incident.severity or 0.5,
        retention = "historical",
        payload = { incidentType = tostring(incidentType), actorFactionID = tostring(actorFactionID),
            victimFactionID = tostring(victimFactionID), warDeclared = result and result.warDeclared == true,
            allianceBroken = result and result.allianceBroken == true },
    })
    if fact then acquireFaction(actorFactionID, fact.factID, {
        source = "faction_commit", acquisitionPath = "faction", learnedAt = at,
    }) end
    return fact
end

function Adapter.PublishFactionStatus(factionID, status, reason, at)
    local fact = Adapter.Publish({
        producer = "hoomans:faction", kind = "faction.status",
        subject = { id = tostring(factionID), kind = "faction" },
        eventID = tostring(factionID) .. ":" .. tostring(status) .. ":" .. tostring(at or now()),
        occurredAt = tonumber(at) or now(), observedAt = tonumber(at) or now(),
        severity = status == "destroyed" and 1 or 0.5, retention = "historical",
        payload = { status = tostring(status), reason = tostring(reason or "unknown") },
    })
    if fact then acquireFaction(factionID, fact.factID, {
        source = "faction_status_commit", acquisitionPath = "faction", learnedAt = at,
    }) end
    return fact
end

local function localized(key, fallback, language)
    if type(getText) == "function" then
        local value = getText(key)
        if type(value) == "string" and value ~= key then return value end
    end
    if tostring(language or ""):upper() == "TL" then
        if key == "UI_PNC_WKG_ZombieObserved" then return "Nakakita ako ng malaking grupo ng mga zombie." end
        if key == "UI_PNC_WKG_ZombieHeard" then return "Narinig kong may malaking grupo ng mga zombie sa paligid." end
        if key == "UI_PNC_WKG_Death" then return "May namatay; hindi ko alam ang buong detalye." end
        if key == "UI_PNC_WKG_Faction" then return "May balita tungkol sa isang pangkat." end
    end
    return fallback
end

local CORROBORATING_PROVENANCE = {
    experienced = true,
    witnessed = true,
    public = true,
    faction = true,
    environmental = true,
}

local UNCERTAIN_PROVENANCE = {
    radio = true,
    told = true,
    inferred = true,
}

function Adapter.ResolveEpistemicStatus(fact, reference)
    if CoreWKG and type(CoreWKG.ResolveEpistemicStatus) == "function" then
        return CoreWKG.ResolveEpistemicStatus(fact, reference)
    end
    local f = type(fact) == "table" and fact or nil
    local r = type(reference) == "table" and reference or nil
    if not f and not r then return "unknown" end
    if (f and (f.corroborated == true or CORROBORATING_PROVENANCE[f.provenance]))
        or (r and (r.corroborated == true or CORROBORATING_PROVENANCE[r.provenance]))
    then
        return "known"
    end
    local fp = f and f.provenance or nil
    local rp = r and r.provenance or nil
    if UNCERTAIN_PROVENANCE[fp] or UNCERTAIN_PROVENANCE[rp] then
        return "uncertain"
    end
    return "unknown"
end

function Adapter.RenderFact(fact, reference, options)
    if type(fact) ~= "table" then return nil end
    local epistemic = Adapter.ResolveEpistemicStatus(fact, reference)
    if epistemic == "unknown" then return nil end
    local provenance = reference and reference.provenance or fact.provenance or "unknown"
    local language = options and options.language
    local payload = type(fact.payload) == "table" and fact.payload or {}
    if fact.kind == "zombie.pressure" then
        if epistemic == "known" and (provenance == "experienced" or provenance == "witnessed") then
            return localized("UI_PNC_WKG_ZombieObserved", "I saw a large group of zombies nearby.", language)
        end
        return localized("UI_PNC_WKG_ZombieHeard", "I heard there is heavy zombie pressure nearby.", language)
    end
    if fact.kind == "npc.death" then
        if epistemic == "uncertain" or provenance == "told" or provenance == "radio" then
            return localized("UI_PNC_WKG_Death", "I heard someone died, but I cannot confirm every detail.", language)
        end
        return localized("UI_PNC_WKG_Death", "Someone died; I do not know every detail.", language)
    end
    if fact.kind == "faction.status" or fact.kind == "faction.incident" then
        if epistemic == "uncertain" then
            return "I heard rumors about a faction's situation, though I can't confirm it."
        end
        return localized("UI_PNC_WKG_Faction", "I have news about a faction's situation.", language)
    end
    if fact.kind == "actor.milestone" then
        local label = tostring(payload.label or payload.milestoneID or "a survival milestone")
        local subjectName = type(fact.subject) == "table" and tostring(fact.subject.name or "someone") or "someone"
        if epistemic == "uncertain" then
            return "I heard " .. subjectName .. " reached " .. label .. ", though I wasn't there."
        end
        if provenance == "experienced" or provenance == "witnessed" then
            return tostring(payload.summary or ("I've made it to " .. label .. "."))
        end
        return subjectName .. " reached " .. label .. "."
    end
    if fact.kind == "world.event" then
        local label = tostring(payload.label or payload.eventType or "a world event")
        if epistemic == "uncertain" then
            return "I heard a rumor about " .. label .. ", though I haven't seen proof myself."
        end
        return tostring(payload.summary or ("Confirmed reports of " .. label .. "."))
    end
    if fact.kind == "world.state" then
        local domain = tostring(payload.domain or "conditions")
        local status = tostring(payload.status or "changed")
        if epistemic == "uncertain" then
            return "Word going around is that " .. domain .. " is " .. status .. ", though I can't confirm it."
        end
        return "I know for sure that " .. domain .. " is " .. status .. "."
    end
    if fact.kind == "utility.state" then
        local utility = tostring(payload.utility or "utilities")
        local status = tostring(payload.status or "changed")
        if epistemic == "uncertain" then
            return "Someone mentioned " .. utility .. " is " .. status .. ", though I haven't checked it myself."
        end
        if status == "off" then
            return "The " .. utility .. " is out."
        end
        return "The " .. utility .. " is back on."
    end
    if fact.kind == "world.helicopter_overflight" then
        local locLabel = payload.locationLabel
            or (type(fact.location) == "table" and fact.location.name)
            or nil
        local path = reference and tostring(reference.acquisitionPath or "") or ""
        if provenance == "radio" then
            if locLabel then
                return "Radio traffic mentioned a helicopter near " .. tostring(locLabel) .. "."
            end
            return "Radio traffic mentioned a helicopter in the area."
        end
        if epistemic == "uncertain" or provenance == "told" then
            if locLabel then
                return "Someone told me a helicopter flew near " .. tostring(locLabel) .. ", though I didn't see it myself."
            end
            return "Someone told me a helicopter passed by, though I didn't see it myself."
        end
        if provenance == "environmental" or path == "helicopter_indoor_audio" then
            return "I heard a helicopter pass nearby while I was indoors, though I couldn't see its course."
        end
        if locLabel then
            return "I saw a helicopter pass over " .. tostring(locLabel) .. "."
        end
        return "I saw a helicopter pass overhead."
    end
    if fact.kind == "ambient.gunfire" then
        local locLabel = payload.locationLabel or (type(fact.location) == "table" and fact.location.name) or "nearby"
        local weapon = payload.weaponClass and tostring(payload.weaponClass) or "gunfire"
        if epistemic == "uncertain" then
            return "I heard rumors of " .. weapon .. " shots near " .. tostring(locLabel) .. "."
        end
        if provenance == "witnessed" then
            return "I witnessed " .. weapon .. " gunfire erupt near " .. tostring(locLabel) .. "."
        end
        return "I heard " .. weapon .. " shots echo near " .. tostring(locLabel) .. "."
    end
    if fact.kind == "ambient.scream" then
        local locLabel = payload.locationLabel or (type(fact.location) == "table" and fact.location.name) or "nearby"
        if epistemic == "uncertain" then
            return "Someone told me they heard a scream near " .. tostring(locLabel) .. "."
        end
        return "I heard someone screaming near " .. tostring(locLabel) .. "."
    end
    if fact.kind == "world.house_alarm" then
        local locLabel = payload.locationLabel or (type(fact.location) == "table" and fact.location.name) or "nearby"
        if epistemic == "uncertain" then
            return "Word is a house alarm went off near " .. tostring(locLabel) .. "."
        end
        return "A building alarm started blaring near " .. tostring(locLabel) .. "."
    end
    if fact.kind == "weather.severe_storm" then
        local stormKind = tostring(payload.stormKind or "storm")
        local locLabel = payload.locationLabel or "the region"
        if provenance == "radio" then
            return "Radio reports warned of severe " .. stormKind .. " conditions around " .. tostring(locLabel) .. "."
        end
        return "Severe " .. stormKind .. " weather is sweeping across " .. tostring(locLabel) .. "."
    end
    if fact.kind == "world.fire_hazard" then
        local locLabel = payload.locationLabel or (type(fact.location) == "table" and fact.location.name) or "nearby"
        if epistemic == "uncertain" then
            return "Someone reported a fire near " .. tostring(locLabel) .. "."
        end
        return "A fire broke out near " .. tostring(locLabel) .. "."
    end
    if fact.kind == "media.broadcast" then
        local channel = tostring(payload.channelID or "emergency radio")
        return "I caught a radio broadcast over " .. channel .. "."
    end
    return nil
end

function Adapter.QueryActorFact(record, querySpec, nowHours)
    if not CoreWKG or not record then
        return { status = "unknown", epistemicStatus = "unknown" }
    end
    local id = actorID(record)
    if not id then
        return { status = "unknown", epistemicStatus = "unknown" }
    end
    querySpec = type(querySpec) == "table" and querySpec or {}
    local selected = CoreWKG.ActorKnowledge.Select(
        CoreWKG.KnowledgeState, CoreWKG.LedgerState, id, {
            max = 32,
            now = nowHours,
            kind = querySpec.kind,
        }
    )
    local wantedFactID = querySpec.factID and tostring(querySpec.factID) or nil
    local wantedTopic = querySpec.topic and string.lower(tostring(querySpec.topic)) or nil
    for i = 1, #selected do
        local item = selected[i]
        local fact = item and item.fact
        local ref = item and item.reference
        if fact and ref then
            local payload = type(fact.payload) == "table" and fact.payload or {}
            local matches = false
            if wantedFactID and fact.factID == wantedFactID then
                matches = true
            elseif wantedTopic then
                local subjID = type(fact.subject) == "table" and tostring(fact.subject.id or "") or tostring(fact.subject or "")
                local subjName = type(fact.subject) == "table" and tostring(fact.subject.name or "") or ""
                if string.lower(tostring(fact.kind or "")) == wantedTopic
                    or string.lower(subjID) == wantedTopic
                    or string.lower(subjName) == wantedTopic
                    or string.lower(tostring(payload.semanticType or "")) == wantedTopic
                    or string.lower(tostring(payload.utility or "")) == wantedTopic
                    or string.lower(tostring(payload.eventType or "")) == wantedTopic
                    or string.lower(tostring(payload.milestoneID or "")) == wantedTopic
                    or string.lower(tostring(payload.label or "")) == wantedTopic
                then
                    matches = true
                end
            elseif not wantedFactID then
                matches = true
            end
            if matches then
                local epistemic = Adapter.ResolveEpistemicStatus(fact, ref)
                return {
                    status = epistemic == "known" and "known"
                        or (epistemic == "uncertain" and "suspected" or "unknown"),
                    epistemicStatus = epistemic,
                    provenance = ref.provenance,
                    fact = fact,
                    reference = ref,
                    summary = Adapter.RenderFact(fact, ref, querySpec),
                }
            end
        end
    end
    return { status = "unknown", epistemicStatus = "unknown" }
end

function Adapter.BuildConversationContext(record, options)
    if not CoreWKG or not record then return { npcGossip = { statements = {}, factRefs = {} } } end
    options = type(options) == "table" and options or {}
    options.max = math.min(Adapter.MAX_GOSSIP, tonumber(options.max) or Adapter.MAX_GOSSIP)
    options.renderFact = options.renderFact or function(fact, reference)
        return Adapter.RenderFact(fact, reference, options)
    end
    return CoreWKG.Context(actorID(record), options)
end

function Adapter.Explain(record, factID, at)
    return CoreWKG and CoreWKG.Explain(actorID(record), factID, at)
end

function Adapter.Save()
    if not CoreWKG or not ModData or type(ModData.getOrCreate) ~= "function" then return false end
    local store = ModData.getOrCreate("PNC.WorldKnowledge")
    local payload = CoreWKG.ToPayload()
    store.schemaVersion = payload.schemaVersion
    store.ledger = payload.ledger
    store.actors = payload.actors
    return true
end

function Adapter.Load()
    if not CoreWKG or not ModData or type(ModData.get) ~= "function" then return false end
    local store = ModData.get("PNC.WorldKnowledge")
    if type(store) ~= "table" then return false end
    return CoreWKG.FromPayload({ schema = "PsychopatzCore.WorldKnowledge",
        schemaVersion = store.schemaVersion, ledger = store.ledger, actors = store.actors })
end

return Adapter
