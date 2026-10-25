-- Target catalog and native Talk entry projection.
--
-- This spoke owns only target facts and the bounded entry consumed by
-- PNC.Conversation.TalkStart.  Session lifecycle and response payloads live
-- in the sibling TalkParity spokes.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity
local Internal = TalkParity.Internal
local TalkStart = Internal.TalkStart

local TARGETS = {
    {
        id = "current",
        label = "Current target",
        description = "Use the currently configured NPC entry.",
        diagnostic = true,
    },
    {
        id = "colonist",
        label = "Colonist",
        description = "Colony-owned NPC without a follow order.",
        tacticalClass = "colonist",
        colonyOwned = true,
        recruited = true,
        companion = true,
        ownedByPlayer = true,
        actorAuthority = { eligible = true, companion = true, owned = true },
        hostility = { attackPlayers = false },
        followState = { mode = "idle" },
        role = "colonist",
    },
    {
        id = "follower",
        label = "Follower",
        description = "Colony-owned NPC with the production follow order.",
        tacticalClass = "colonist",
        colonyOwned = true,
        recruited = true,
        companion = true,
        ownedByPlayer = true,
        actorAuthority = { eligible = true, companion = true, owned = true },
        hostility = { attackPlayers = false },
        followState = { mode = "following" },
        orderKind = "follow",
        orderSpec = { kind = "follow" },
        role = "follower",
    },
    {
        id = "neutral",
        label = "Neutral",
        description = "Non-owned NPC with the production neutral tactical class.",
        tacticalClass = "neutral",
        colonyOwned = false,
        recruited = false,
        companion = false,
        ownedByPlayer = false,
        actorAuthority = { eligible = false, companion = false, owned = false },
        hostility = { attackPlayers = false },
        followState = { mode = "idle" },
    },
    {
        id = "hostile",
        label = "Hostile / Enemy",
        description = "NPC with the production hostile tactical class and player hostility.",
        tacticalClass = "hostile",
        colonyOwned = false,
        recruited = false,
        companion = false,
        ownedByPlayer = false,
        actorAuthority = { eligible = false, companion = false, owned = false },
        hostility = { attackPlayers = true },
        followState = { mode = "idle" },
        activeBehavior = "attack",
    },
}

local ALIASES = {
    enemy = "hostile",
    hostile_enemy = "hostile",
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

local function canonicalID(value)
    local id = string.lower(tostring(value or "current"))
    return ALIASES[id] or id
end

local function targetByID(value)
    local id = canonicalID(value)
    for _, target in ipairs(TARGETS) do
        if target.id == id then return target end
    end
    return nil
end

local function applyOverrides(npc, target)
    if not target or target.id == "current" then return npc end
    local fields = {
        "tacticalClass", "colonyOwned", "recruited", "companion",
        "ownedByPlayer", "actorAuthority", "hostility", "followState",
        "orderKind", "orderSpec", "role", "activeBehavior",
    }
    for _, key in ipairs(fields) do
        npc[key] = copy(target[key])
    end
    return npc
end

function TalkParity.CanonicalID(value)
    return canonicalID(value)
end

function TalkParity.GetTarget(value)
    local target = targetByID(value)
    return target and copy(target) or nil
end

function TalkParity.GetCatalog()
    local catalog = {}
    for _, target in ipairs(TARGETS) do
        local row = {
            id = target.id,
            label = target.label,
            description = target.description,
            diagnostic = target.diagnostic == true,
        }
        if target.tacticalClass then
            row.tacticalClass = target.tacticalClass
        end
        catalog[#catalog + 1] = row
    end
    return catalog
end

function TalkParity.ApplyTarget(scenario, value)
    local target = targetByID(value)
    if not target then return nil, "unknown_talk_target" end
    local result = copy(scenario or {})
    result.npc = copy(result.npc or {})
    applyOverrides(result.npc, target)
    result.runtime = copy(result.runtime or {})
    result.runtime.semanticLabTalkTarget = target.id
    return result, target.id
end

function TalkParity.BuildEntry(scenario, value)
    local target = targetByID(value)
    if not target then return nil, nil, "unknown_talk_target" end
    local npc = copy(scenario and scenario.npc or {})
    applyOverrides(npc, target)
    local id = tostring(npc.npcID or npc.id or "harness-npc")
    local entry = {
        id = id,
        tacticalClass = npc.tacticalClass,
        colonyOwned = npc.colonyOwned == true,
        recruited = npc.recruited == true,
        companion = npc.companion == true,
        ownedByPlayer = npc.ownedByPlayer == true,
        orderKind = npc.orderKind,
        orderSpec = copy(npc.orderSpec),
        followState = copy(npc.followState),
        activeBehavior = npc.activeBehavior,
        role = npc.role,
        hostility = copy(npc.hostility),
        alive = npc.alive ~= false,
        available = npc.available,
        availabilityReason = npc.availabilityReason,
        record = copy(npc),
        snapshot = copy(npc),
    }
    return entry, target
end

function TalkParity.Resolve(scenario, value, player)
    local entry, target, reason = TalkParity.BuildEntry(scenario, value)
    if not entry then return nil, reason end
    local projection, projectionReason = TalkStart.Project(
        entry,
        player,
        { source = "semantic_lab" }
    )
    if not projection then return nil, projectionReason end
    projection.id = target.id
    projection.label = target.label
    projection.description = target.description
    projection.diagnostic = target.diagnostic == true
    projection.entryFacts = {
        colonyOwned = projection.ownership.colonyOwned,
        recruited = projection.ownership.recruited,
        ownedByPlayer = projection.ownership.ownedByPlayer,
        orderKind = projection.ownership.orderKind,
        alive = entry.alive ~= false,
        hostility = copy(entry.hostility),
    }
    return projection
end

Internal.copy = copy
Internal.targetByID = targetByID

return TalkParity
