-- Converts aggregate casualty counts into canonical persistent NPC mutations.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractCasualtyResolver = PNC.AbstractCasualtyResolver or {}

local Casualties = PNC.AbstractCasualtyResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups

local function condition(record)
    local health = record and record.health or {}
    return math.max(0, math.min(1, (tonumber(health.current) or 100)
        / math.max(1, tonumber(health.max) or 100)))
end

local function exposure(record)
    local role = tostring(record and record.affiliation and record.affiliation.role or "civilian")
    local roles = Config.COMBAT.ROLE_FACTORS
    return (tonumber(roles[role]) or 0.35) * 0.65 + (1 - condition(record)) * 0.35
end

local function candidates(group, seed)
    local output = {}
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            output[#output + 1] = { record = record, exposure = exposure(record),
                tie = PNC.AbstractScavengeResolver.Hash(tostring(seed) .. ":" .. npcID) }
        end
    end
    table.sort(output, function(a, b)
        return a.exposure == b.exposure and a.tie < b.tie or a.exposure > b.exposure
    end)
    return output
end

local function injure(record, severity, attackerID, seed)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local amount = Config.Casualties.DAMAGE[severity] or 6
    local woundType = Config.Casualties.WOUND_TYPE[severity] or "scratch"
    local partOrder = PNC.NPCWounds and PNC.NPCWounds.PartOrder or nil
    local partId
    if type(partOrder) == "table" and #partOrder > 0 then
        local index = PNC.AbstractScavengeResolver.Hash(tostring(seed)
            .. ":" .. record.id .. ":part") % #partOrder + 1
        partId = partOrder[index]
    end
    if PNC.NPCWounds and PNC.NPCWounds.ApplyCombatDamage then
        return PNC.NPCWounds.ApplyCombatDamage(record, nil, {
            amount = amount, woundType = woundType,
            partId = partId,
            type = "abstract_combat_" .. string.lower(severity),
            attackerID = attackerID, attackerKind = "npc",
            x = record.x, y = record.y, z = record.z,
        })
    end
    record.health = type(record.health) == "table" and record.health
        or { current = 100, max = 100, state = "normal" }
    record.health.current = math.max(1, (tonumber(record.health.current) or 100) - amount)
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "health") end
    return true, { outcome = "wounded", damage = amount, woundType = woundType }
end

local function kill(record)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    if PNC.Health and PNC.Health.Kill then
        return PNC.Health.Kill(record, nil, "abstract_combat")
    end
    record.alive = false
    record.health = type(record.health) == "table" and record.health or {}
    record.health.current, record.health.state = 0, "dead"
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "health") end
    if PNC.Factions and PNC.Factions.OnNPCDeath then PNC.Factions.OnNPCDeath(record.id) end
    return true
end

function Casualties.Apply(group, severityCounts, seed, attackerID)
    local pool, output = candidates(group, seed), { injuries = {}, deaths = {}, counts = {} }
    local cursor = 1
    for _, severity in ipairs({ "DEAD", "CRITICAL", "SERIOUS", "MINOR" }) do
        local requested = math.max(0, math.floor(tonumber(severityCounts[severity]) or 0))
        output.counts[severity] = 0
        for _ = 1, requested do
            local selected = pool[cursor]
            if not selected then break end
            cursor = cursor + 1
            local record = selected.record
            if severity == "DEAD" then
                kill(record)
                output.deaths[#output.deaths + 1] = record.id
                Store.Emit("ABSTRACT_MEMBER_KILLED", { groupId = group.id,
                    npcId = record.id, attackerGroupId = attackerID })
            else
                local _, detail = injure(record, severity, attackerID, seed)
                output.injuries[#output.injuries + 1] = { npcId = record.id,
                    groupId = group.id, severity = severity, detail = detail }
                Store.Emit("ABSTRACT_MEMBER_INJURED", { groupId = group.id,
                    npcId = record.id, severity = severity,
                    attackerGroupId = attackerID })
            end
            output.counts[severity] = output.counts[severity] + 1
        end
    end
    local surviving = {}
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then surviving[#surviving + 1] = npcID end
    end
    group.memberIds = surviving
    Groups.MarkCombatProfileDirty(group, "abstract_casualties")
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch("abstract_casualties_applied")
    return output
end

return Casualties
