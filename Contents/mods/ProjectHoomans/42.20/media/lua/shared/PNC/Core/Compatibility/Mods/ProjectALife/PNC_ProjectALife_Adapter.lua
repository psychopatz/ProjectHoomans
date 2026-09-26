-- Project A-Life ownership, damage, and world-event compatibility lives here.
-- Project A-Life remains responsible for its actors and world simulation.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Adapter = PNC.Compatibility.ProjectALifeAdapter
    or {}
PNC.Compatibility.ProjectALifeAdapter = Adapter

local Policy = PNC.Compatibility.ProjectALifePolicy
    or {}
PNC.Compatibility.ProjectALifePolicy = Policy
Policy.defaultRelation = Policy.defaultRelation or "neutral"
Policy.relations = Policy.relations or {}
Policy.conflicts = Policy.conflicts or {}
Policy.conflictSequence = tonumber(Policy.conflictSequence) or 0

local VALID_RELATIONS = {
    friendly = true,
    neutral = true,
    careful = true,
    hostile = true,
}

local function relation(value)
    value = string.lower(tostring(value or "neutral"))
    return VALID_RELATIONS[value] and value or "neutral"
end

local function relationKey(sourceProvider, sourceFaction,
        targetProvider, targetFaction)
    return tostring(sourceProvider or "") .. ":"
        .. tostring(sourceFaction or "*") .. "->"
        .. tostring(targetProvider or "") .. ":"
        .. tostring(targetFaction or "*")
end

function Policy.SetRelation(sourceProvider, sourceFaction,
        targetProvider, targetFaction, value)
    local key = relationKey(sourceProvider, sourceFaction,
        targetProvider, targetFaction)
    local normalized = relation(value)
    if Policy.relations[key] ~= normalized then
        Policy.relations[key] = normalized
        if Policy.Loaded == true then Policy.Dirty = true end
    end
    return Policy.relations[key]
end

function Policy.Resolve(sourceProvider, sourceFaction,
        targetProvider, targetFaction, context)
    local targetBody = context and context.targetBody
    local candidates

    if targetBody and targetBody.getModData then
        local ok, bodyData = pcall(targetBody.getModData, targetBody)
        if ok and type(bodyData) == "table" then
            if type(bodyData.PNC_ProjectALifeRelation) == "string" then
                return relation(bodyData.PNC_ProjectALifeRelation),
                    "target_override"
            end
        end
    end

    candidates = {
        relationKey(sourceProvider, sourceFaction,
            targetProvider, targetFaction),
        relationKey(sourceProvider, "*", targetProvider, targetFaction),
        relationKey(sourceProvider, sourceFaction, targetProvider, "*"),
        relationKey(sourceProvider, "*", targetProvider, "*"),
    }
    for _, key in ipairs(candidates) do
        if Policy.relations[key] ~= nil then
            return relation(Policy.relations[key]), "configured"
        end
    end
    return relation(Policy.defaultRelation), "default"
end

local function providerFactionName(provider, faction)
    if tostring(provider or "") ~= "ProjectALifeNPCs"
        or faction == nil
    then
        return nil
    end
    local catalog = ProjectALife and ProjectALife.Catalog
    if not catalog or type(catalog.faction) ~= "function" then
        return nil
    end
    local ok, definition = pcall(catalog.faction, tostring(faction))
    local general = ok and definition and definition.general or nil
    local name = general and general.name
    return type(name) == "string" and name ~= "" and name or nil
end

-- A confirmed cross-provider hit escalates both directed stances and records
-- the conflict for the server-side persistence coordinator.
function Policy.RecordConflict(sourceProvider, sourceFaction,
        targetProvider, targetFaction, context)
    context = type(context) == "table" and context or {}
    if sourceProvider == nil or targetProvider == nil
        or (sourceFaction == nil and targetFaction == nil)
    then
        return false, "faction_identity_missing"
    end

    if type(Policy.EnsureLoaded) == "function" then
        Policy.EnsureLoaded()
    end

    Policy.conflictSequence = Policy.conflictSequence + 1
    local entry = {
        id = "projectalife:conflict:" .. tostring(Policy.conflictSequence),
        sourceProvider = tostring(sourceProvider),
        sourceFaction = sourceFaction and tostring(sourceFaction) or "*",
        targetProvider = tostring(targetProvider),
        targetFaction = targetFaction and tostring(targetFaction) or "*",
        reason = tostring(context.reason or "confirmed_damage"),
        atMs = tonumber(context.atMs)
            or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0),
    }
    Policy.SetRelation(
        entry.sourceProvider,
        entry.sourceFaction,
        entry.targetProvider,
        entry.targetFaction,
        "hostile"
    )
    Policy.SetRelation(
        entry.targetProvider,
        entry.targetFaction,
        entry.sourceProvider,
        entry.sourceFaction,
        "hostile"
    )
    Policy.conflicts[#Policy.conflicts + 1] = entry
    while #Policy.conflicts > 128 do
        table.remove(Policy.conflicts, 1)
    end
    if Policy.Loaded == true then Policy.Dirty = true end

    if context.emitFlavor ~= false then
        local events = PNC.Compatibility.ProjectALifeEvents
        local server = events and events.Server
        if server and type(server.Publish) == "function" then
            pcall(
                server.Publish,
                "projectalife_faction_conflict",
                {
                    eventID = entry.id,
                    x = context.x,
                    y = context.y,
                    z = context.z,
                    stance = "hostile",
                    direction = context.direction,
                    factionName = context.factionName
                        or providerFactionName(
                            entry.sourceProvider,
                            entry.sourceFaction)
                        or providerFactionName(
                            entry.targetProvider,
                            entry.targetFaction)
                        or entry.sourceFaction,
                    sourceFaction = entry.sourceFaction,
                    targetFaction = entry.targetFaction,
                    damage = context.damage,
                }
            )
        end
    end
    return true, entry
end

local ActorOwnership = PNC and PNC.Compatibility
    and PNC.Compatibility.ActorOwnership

PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

local function onEvent(eventContext)
    if type(eventContext) ~= "table" then return false end

    local eventName = eventContext.event
    local events = PNC.Compatibility.ProjectALifeEvents

    if eventName == "projectalife_encounter"
        or eventName == "projectalife_faction_stance"
        or eventName == "projectalife_faction_conflict"
    then
        local server = events.Server
        if server and type(server.Publish) == "function" then
            return server.Publish(eventName, eventContext.context) == true
        end
        return false
    end

    if eventName == "projectalife_meta_event"
        or eventName == "projectalife_client_flavor"
    then
        local client = events.Client
        if client and type(client.HandleAdapterEvent) == "function" then
            return client.HandleAdapterEvent(eventContext) == true
        end
    end

    return false
end

local function isProjectALifeBody(body)
    if not body or not body.getModData then return false end

    local data = body:getModData()
    if type(data) ~= "table" then return false end

    return data.ProjectALifeOwned == true or data.ProjectALifeActor == true
end

local function isAlive(body)
    if body == nil then return false end
    local ok, dead = pcall(function()
        return body.isDead and body:isDead() == true
    end)
    if ok and dead then return false end
    local aliveOk, alive = pcall(function()
        return body.isAlive == nil or body:isAlive() == true
    end)
    return aliveOk and alive == true
end

local function position(body)
    if body == nil then return nil, nil, nil end
    local ok, x, y, z = pcall(function()
        return body:getX(), body:getY(), body:getZ()
    end)
    if not ok then return nil, nil, nil end
    return tonumber(x), tonumber(y), tonumber(z)
end

local function registryRecord(uid)
    local alife = ProjectALife
    local registry = alife and alife.ActorRegistry
    if type(uid) ~= "string" or registry == nil then return nil end
    if type(registry.read) == "function" then
        local ok, record = pcall(registry.read, uid)
        if ok and type(record) == "table" then return record end
    end
    if type(registry.peek) == "function" then
        local ok, record = pcall(registry.peek, uid)
        if ok and type(record) == "table" then return record end
    end
    return nil
end

local function activeBinding(uid, generation)
    local alife = ProjectALife
    local watchdog = alife and alife.Watchdog
    local bindings = watchdog and watchdog.bindings
    local binding = type(bindings) == "table" and bindings[uid] or nil
    if type(binding) ~= "table" or binding.shell == nil then return nil end
    if generation ~= nil
        and tonumber(binding.generation) ~= tonumber(generation)
    then
        return nil
    end
    if not isAlive(binding.shell) then return nil end
    return binding
end

local function actorReference(uid, generation)
    local record = registryRecord(uid)
    if record == nil or record.lifecycle ~= "active" then return nil end
    if generation ~= nil
        and tonumber(record.generation) ~= tonumber(generation)
    then
        return nil
    end
    local binding = activeBinding(tostring(record.uid or uid), record.generation)
    if binding == nil then return nil end
    local body = binding.shell
    local x, y, z = position(body)
    return {
        provider = "ProjectALifeNPCs",
        actorId = tostring(record.uid or uid),
        id = tostring(record.uid or uid),
        generation = tonumber(record.generation) or 0,
        kind = "foreign_npc",
        actor = record,
        worldObject = body,
        factionId = record.factionId,
        x = x,
        y = y,
        z = z,
    }
end

local function factionID(record)
    local factions = PNC.Factions
    if factions and type(factions.GetFactionID) == "function" then
        local ok, id = pcall(factions.GetFactionID, record)
        if ok and id ~= nil then return tostring(id) end
    end
    return record and record.affiliation
        and record.affiliation.factionID or nil
end

local function bodyFactionID(body)
    if not body or not body.getModData then return nil end
    local ok, data = pcall(body.getModData, body)
    if not ok or type(data) ~= "table" then return nil end
    if data.PNC_FactionID ~= nil then
        return tostring(data.PNC_FactionID)
    end
    if data.PNC_UUID and PNC.Registry and PNC.Registry.Get then
        return factionID(PNC.Registry.Get(data.PNC_UUID))
    end
    return nil
end

function Adapter.GetHoomansFactionID(body)
    return bodyFactionID(body)
end

function Adapter.RecordConflict(sourceProvider, sourceFaction,
        targetProvider, targetFaction, context)
    return Policy.RecordConflict(
        sourceProvider,
        sourceFaction,
        targetProvider,
        targetFaction,
        context
    )
end

local function recentThreat(record, actorId)
    local recent = record and record.runtime and record.runtime.recentThreat
    if type(recent) ~= "table"
        or recent.kind ~= "foreign_npc"
        or tostring(recent.provider or "") ~= "ProjectALifeNPCs"
        or tostring(recent.id or "") ~= tostring(actorId or "")
    then
        return false
    end
    return (tonumber(recent.expiresAt) or 0) >= (PNC.Core
        and PNC.Core.Now and PNC.Core.Now() or 0)
end

function Adapter.CanHoomansAttack(context)
    context = type(context) == "table" and context or {}
    local attacker = context.attacker
    local target = context.target or {}
    local actorId = target.actorId or target.id
    local sourceFaction = factionID(attacker)
    local targetFaction = target.factionId
    if context.target and context.target.immediateSelfDefense
        or recentThreat(attacker, actorId)
    then
        return true, "self_defense", "hostile"
    end
    local stance, reason = Policy.Resolve(
        "ProjectHoomans", sourceFaction,
        "ProjectALifeNPCs", targetFaction,
        { targetBody = target.worldObject }
    )
    return stance == "hostile" or stance == "careful", reason, stance
end

function Adapter.CanProjectALifeAttack(actor, body, context)
    if not isProjectALifeBody(body) then return false, "foreign_body_required" end
    context = type(context) == "table" and context or {}
    local sourceFaction = actor and actor.factionId
    local targetFaction = bodyFactionID(body)
    local stance, reason = Policy.Resolve(
        "ProjectALifeNPCs", sourceFaction,
        "ProjectHoomans", targetFaction,
        { targetBody = body, actor = actor, phase = context.phase }
    )
    return stance == "hostile" or stance == "careful", reason, stance
end

function Adapter.enumerateTargets(context)
    local output = {}
    local source = context and context.source
    local radius = tonumber(context and context.radius) or 12
    local sx = source and tonumber(source.x)
    local sy = source and tonumber(source.y)
    local sz = source and tonumber(source.z)
    local alife = ProjectALife
    local watchdog = alife and alife.Watchdog
    local bindings = watchdog and watchdog.bindings
    if type(bindings) ~= "table" then return output end

    for uid, binding in pairs(bindings) do
        local record = registryRecord(tostring(uid))
        local body = binding and binding.shell
        if record and record.lifecycle == "active"
            and body and isAlive(body)
            and tonumber(binding.generation) == tonumber(record.generation)
        then
            local x, y, z = position(body)
            local dx = sx and x and x - sx or nil
            local dy = sy and y and y - sy or nil
            if x and y and (sx == nil or dx * dx + dy * dy <= radius * radius)
                and (sz == nil or z == nil or math.abs(z - sz) < 1)
            then
                local candidate = actorReference(tostring(uid), record.generation)
                if candidate ~= nil then
                    candidate.immediateSelfDefense = recentThreat(
                        source, candidate.actorId)
                    output[#output + 1] = candidate
                end
            end
        end
    end
    return output
end

function Adapter.getActorRef(context)
    context = type(context) == "table" and context or {}
    local actor = context.actor
    if type(actor) == "table" then
        local uid = actor.uid or actor.ProjectALifeUID
        if uid ~= nil then return actorReference(tostring(uid), actor.generation) end
    end
    if actor and actor.getModData then
        local ok, data = pcall(actor.getModData, actor)
        if ok and type(data) == "table" and data.ProjectALifeUID then
            return actorReference(tostring(data.ProjectALifeUID),
                data.ProjectALifeGeneration)
        end
    end
    return nil
end

function Adapter.resolveTarget(context)
    context = type(context) == "table" and context or {}
    local ref = context.ref or {}
    return actorReference(tostring(ref.actorId or ref.id or ""), ref.generation)
end

function Adapter.applyDamage(context)
    context = type(context) == "table" and context or {}
    local target = context.target or {}
    local details = context.context or {}
    local body = target.worldObject
    local hit = details.hit or {}
    local attackerBody = details.attackerBody
    local weapon = hit.weaponItem or details.weaponItem
    local alife = ProjectALife
    local humanDamage = alife and alife.HumanDamage
    if not body or not attackerBody or not weapon
        or not humanDamage or type(humanDamage.apply) ~= "function"
    then
        return false, "alife_damage_unavailable"
    end
    local allowed = Adapter.CanHoomansAttack({
        attacker = details.attackerRecord,
        target = target,
        context = details,
    })
    if allowed ~= true then return false, "foreign_target_not_allowed" end
    local ok, applied = pcall(
        humanDamage.apply, attackerBody, body, weapon, 1)
    if ok and applied == true then
        Policy.RecordConflict(
            "ProjectHoomans",
            factionID(details.attackerRecord),
            "ProjectALifeNPCs",
            target.factionId,
            {
                reason = "hoomans_confirmed_damage",
                direction = "outgoing",
                x = target.x,
                y = target.y,
                z = target.z,
                factionName = target.factionId,
                damage = hit.amount,
            }
        )
    end
    return ok and applied == true, ok and "applied" or "alife_damage_failed"
end

if not ActorOwnership or type(ActorOwnership.RegisterAdapter) ~= "function" then
    return false
end

local registered = ActorOwnership.RegisterAdapter({
    id = "ProjectALifeNPCs",
    apiVersion = 1,
    detect = isProjectALifeBody,
    capabilities = {
        events = true,
        targeting = true,
        relationships = true,
        damage = true,
    },
    onEvent = onEvent,
    enumerateTargets = Adapter.enumerateTargets,
    getActorRef = Adapter.getActorRef,
    resolveTarget = Adapter.resolveTarget,
    canAttack = Adapter.CanHoomansAttack,
    applyDamage = Adapter.applyDamage,
})

require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_DamageBridge"
require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_ReverseBridge"

return registered
