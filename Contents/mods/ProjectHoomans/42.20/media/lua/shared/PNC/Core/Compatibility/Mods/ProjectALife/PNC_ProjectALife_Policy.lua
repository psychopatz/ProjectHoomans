-- Cross-provider relationship policy for the Project A-Life adapter.
--
-- Owns the directed stance table between Hoomans factions and A-Life factions,
-- how a stance is resolved for a concrete pair, and how a confirmed cross-mod
-- hit is recorded. This module is the only writer of `Policy.relations`.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Policy = PNC.Compatibility.ProjectALifePolicy or {}
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
    if sourceProvider == nil or targetProvider == nil then
        return false, "provider_identity_missing"
    end

    sourceFaction = sourceFaction ~= nil and tostring(sourceFaction) or nil
    targetFaction = targetFaction ~= nil and tostring(targetFaction) or nil
    if sourceFaction == "" then sourceFaction = nil end
    if targetFaction == "" then targetFaction = nil end

    if type(Policy.EnsureLoaded) == "function" then
        Policy.EnsureLoaded()
    end

    Policy.conflictSequence = Policy.conflictSequence + 1
    local entry = {
        id = "projectalife:conflict:" .. tostring(Policy.conflictSequence),
        sourceProvider = tostring(sourceProvider),
        sourceFaction = sourceFaction or "*",
        targetProvider = tostring(targetProvider),
        targetFaction = targetFaction or "*",
        reason = tostring(context.reason or "confirmed_damage"),
        atMs = tonumber(context.atMs)
            or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0),
    }
    Policy.conflicts[#Policy.conflicts + 1] = entry
    while #Policy.conflicts > 128 do
        table.remove(Policy.conflicts, 1)
    end
    if Policy.Loaded == true then Policy.Dirty = true end

    -- Only a directed pair whose faction identity is known on both sides may
    -- escalate. Recording "*" here used to turn one stray hit into permanent
    -- warfare between whichever Hoomans NPC fired and every A-Life faction,
    -- which is what made neutral patrols look like legitimate targets.
    if sourceFaction == nil or targetFaction == nil then
        return false, "faction_identity_missing", entry
    end

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

return Policy
