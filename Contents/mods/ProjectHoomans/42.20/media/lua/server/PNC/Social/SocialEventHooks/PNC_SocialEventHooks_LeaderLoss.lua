--[[
    Leadership-loss social facing.

    When a player who led a faction dies, the NPCs who were following them are
    standing right there.  This module lets the survivors speak: grief whose
    tone comes from each NPC's own relationship to the dead leader, and a line
    that acknowledges the structural outcome the faction service just decided
    (a surviving player inherits the group, or it converts to refugees under an
    NPC leader as a mobile group).

    Trigger reuse: this is called from Factions.HandlePlayerCharacterDeath at
    the two points where that function already knows the answer.  There is no
    new polling, no per-tick scan, and no second leadership system -- the
    faction service remains the single authority and this module only speaks.

    Cost control:
      * one emit per leader death, not per member per tick;
      * at most MAX_MOURNERS speakers, chosen by grief priority so the most
        affected voices are the ones heard;
      * a per-faction cooldown so a repair sweep cannot replay the scene;
      * an existing visibility/range gate before any network send.
]]

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Const = PNC.Const
local Network = PNC.Network
local HEAR_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
-- A few voices, not a chorus.  Chosen by grief priority below.
local MAX_MOURNERS = 3
local MAX_TRACKED_FACTIONS = 128
local DEFAULT_FACTION_COOLDOWN_MS = 60000

-- The flavor vocabulary and resolver are owned by the shared composition,
-- which may not have run when this module is required.  Resolve them at call
-- time (never at load time) so load order can never break the server tree.
local function flavorConstants()
    return PNC.FlavorTextConst
end

local function flavorText()
    return PNC.FlavorText
end

local function factionCooldownMs()
    local constants = flavorConstants()
    return tonumber(constants and constants.LEADER_DEATH_COOLDOWN_MS)
        or DEFAULT_FACTION_COOLDOWN_MS
end

local function flavorID()
    local constants = flavorConstants()
    return (constants and constants.FLAVOR_LEADER_DEATH)
        or "social.witnessed_leader_death"
end

local function familyID()
    local constants = flavorConstants()
    return (constants and constants.LEADER_DEATH_FAMILY) or "leader_loss"
end

local function successionName()
    local constants = flavorConstants()
    return (constants and constants.Succession
        and constants.Succession.NONE) or "none"
end

-- Presentation tuning.  The fallbacks mirror the constants' own defaults so a
-- missing constants table degrades to sane numbers rather than nil.
local function priorityValue()
    local constants = flavorConstants()
    return tonumber(constants and constants.LEADER_DEATH_PRIORITY) or 88
end

local function weightValue()
    local constants = flavorConstants()
    return tonumber(constants and constants.LEADER_DEATH_WEIGHT) or 6
end

local function ttlValue()
    local constants = flavorConstants()
    return tonumber(constants and constants.LEADER_DEATH_TTL_MS) or 18000
end

local function holdValue()
    local constants = flavorConstants()
    return tonumber(constants and constants.LEADER_DEATH_HOLD_MS) or 4500
end

-- Grief priority: the more personal the loss, the more likely that NPC is to
-- be one of the few speakers.
local GRIEF_PRIORITY = {
    devoted = 5,
    close = 4,
    colonist = 3,
    distant = 2,
    dissent = 1,
}

local recentByFaction = {}
local recentOrder = {}

local function now()
    return (Core and Core.Now and Core.Now()) or 0
end

local function clean(value, fallback)
    if value == nil then return fallback end
    return tostring(value) ~= "" and tostring(value) or fallback
end

local function coordinate(object, method, fallback)
    if not object or type(object[method]) ~= "function" then
        return fallback
    end
    local ok, value = pcall(object[method], object)
    if ok and value ~= nil then return tonumber(value) end
    return fallback
end

local function clampHistory()
    while #recentOrder > MAX_TRACKED_FACTIONS do
        local oldest = table.remove(recentOrder, 1)
        if oldest then recentByFaction[oldest] = nil end
    end
end

local function suppress(factionID, at)
    if not recentByFaction[factionID] then
        recentOrder[#recentOrder + 1] = factionID
    end
    recentByFaction[factionID] = at
    clampHistory()
end

-- Reuse the mod's existing visibility gate when it is available, so a mourner
-- is only heard by a player who could actually see them.
local function playerCanHear(player, record, radiusSq)
    local meeting = PNC.SocialMeeting
    if meeting and type(meeting.CanPlayerMeetNPC) == "function" then
        local ok, eligible = pcall(
            meeting.CanPlayerMeetNPC, player, record, nil, HEAR_RADIUS
        )
        if ok and eligible ~= nil then return eligible == true end
    end
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = tonumber(record and record.x)
    local ny = tonumber(record and record.y)
    local nz = tonumber(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1 then return false end
    local dx = px - nx
    local dy = py - ny
    return (dx * dx) + (dy * dy) <= radiusSq
end

local function relationshipFor(record, playerKey)
    local social = record and record.social
    local relationships = social and social.relationships
    if not relationships or not playerKey then return nil end
    return relationships[playerKey]
end

local function relationshipState(relationship)
    return tostring(relationship and (
        relationship.state or relationship.category
    ) or "unknown")
end

local function relationshipTier(relationship)
    local state = relationshipState(relationship)
    if state == "enemy" or state == "rival" then return "reserved" end
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    if state == "friend" or approval >= 30 then return "warm" end
    if approval >= 10 or familiarity >= 5 then return "familiar" end
    return "reserved"
end

-- Pick the speakers.  Deterministic: sort by grief priority, then by npc id so
-- the same death always produces the same few voices.
local function selectMourners(faction, deadPlayerKey)
    local members = {}
    local memberIDs = faction and faction.memberIDs or {}
    local registry = PNC.Registry
    local npcID
    for npcID, _ in pairs(memberIDs) do
        local record = registry and type(registry.Get) == "function"
            and registry.Get(npcID) or nil
        if record and record.alive ~= false then
            local relationship = relationshipFor(record, deadPlayerKey)
            local classify = flavorText()
            local grief = classify.ClassifyGrief({
                relationshipState = relationshipState(relationship),
                relationshipTier = relationshipTier(relationship),
                relationshipKind = relationship and relationship.kind or nil,
                sameFaction = true,
            })
            members[#members + 1] = {
                record = record,
                id = tostring(record.id or npcID),
                relationship = relationship,
                grief = grief,
                priority = GRIEF_PRIORITY[grief] or 1,
            }
        end
    end
    table.sort(members, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return left.id < right.id
    end)
    return members
end

local function resolveLeaderName(deadPlayerKey)
    local registry = PNC.Registry
    if registry and type(registry.Get) == "function" then
        local record = registry.Get(deadPlayerKey)
        if record then
            return clean(record.displayName or record.name
                or record.id, nil)
        end
    end
    return nil
end

local function resolveSuccessorName(successorNPCID)
    local registry = PNC.Registry
    if not successorNPCID then return nil end
    if registry and type(registry.Get) == "function" then
        local record = registry.Get(successorNPCID)
        if record then
            return clean(record.displayName or record.name
                or record.id, nil)
        end
    end
    return tostring(successorNPCID)
end

-- ---------------------------------------------------------------------------
-- Public hook
-- ---------------------------------------------------------------------------

-- Called from Factions.HandlePlayerCharacterDeath.  `succession` is one of
-- Const.Succession.* ; `successorNPCID` is set only when an NPC was named.
function Hooks.OnLeaderLost(faction, deadPlayerKey, succession, successorNPCID)
    local at = now()
    if not faction or not faction.id then return false, "invalid_faction" end
    if not deadPlayerKey then return false, "invalid_leader" end
    local resolver = flavorText()
    if not resolver or type(resolver.BuildLeaderDeathContext) ~= "function"
    then
        return false, "resolver_unavailable"
    end
    if not Network
        or type(Network.SendConversationRelationshipForNPC) ~= "function"
    then
        return false, "transport_unavailable"
    end
    local factionID = tostring(faction.id)
    local previous = recentByFaction[factionID]
    if previous and at - previous < factionCooldownMs() then
        return false, "debounced"
    end
    if not Core or type(Core.ForEachPlayer) ~= "function" then
        return false, "player_enumerator_unavailable"
    end
    local mourners = selectMourners(faction, deadPlayerKey)
    if #mourners == 0 then return false, "no_survivors" end
    suppress(factionID, at)
    local leaderName = resolveLeaderName(deadPlayerKey)
    local successorName = resolveSuccessorName(successorNPCID)
    local radiusSq = HEAR_RADIUS * HEAR_RADIUS
    local emitted = 0
    local index
    for index = 1, math.min(#mourners, MAX_MOURNERS) do
        local mourner = mourners[index]
        local record = mourner.record
        local npcID = mourner.id
        local relationship = mourner.relationship
        local context = resolver.BuildLeaderDeathContext({
            relationshipState = relationshipState(relationship),
            relationshipTier = relationshipTier(relationship),
            relationshipKind = relationship and relationship.kind or nil,
            sameFaction = true,
            succession = succession or successionName(),
            successorName = successorName,
            groupName = faction.name,
        })
        context.leaderName = leaderName or "our leader"
        context.successorName = successorName
        context.eventType = flavorID()
        context.factionID = factionID
        context.deadLeaderKey = deadPlayerKey
        local eventID = "leader_loss:" .. factionID .. ":"
            .. tostring(math.floor(at)) .. ":" .. npcID
        Core.ForEachPlayer(function(player)
            if not player or not playerCanHear(player, record, radiusSq) then
                return
            end
            local result = {
                source = flavorID(),
                eventID = eventID,
                npcID = npcID,
                ambientFlavor = {
                    eventID = eventID,
                    flavorID = flavorID(),
                    eventType = flavorID(),
                    family = familyID(),
                    priority = priorityValue(),
                    weight = weightValue(),
                    llmEligible = false,
                    memoryEligible = true,
                    npcID = npcID,
                    npcType = context.leaderGrief,
                    socialRole = context.leaderGrief,
                    relationshipState = context.leaderGrief,
                    relationshipTier = relationshipTier(relationship),
                    mergeKey = npcID .. ":" .. familyID(),
                    -- Family and ambient cadence are deliberately zero: the
                    -- several mourners are distinct speakers sharing one
                    -- family, so a family cooldown would let only the first
                    -- voice through and collapse the scene back to a single
                    -- line.  Per-speaker cooldown still stops any one NPC
                    -- repeating, and the server-side faction debounce already
                    -- prevents the whole scene replaying.  The client queues
                    -- them one at a time via holdMs, so this reads as a
                    -- sequenced reaction, not a chorus.
                    cooldowns = {
                        familyMs = 0,
                        speakerMs = factionCooldownMs(),
                        ambientMs = 0,
                        mergeWindowMs = 5000,
                    },
                    ttlMs = ttlValue(),
                    holdMs = holdValue(),
                    context = context,
                    source = {
                        kind = "social_flavor",
                        channel = "succession",
                        eventType = flavorID(),
                        contextEligible = true,
                    },
                },
            }
            local ok, sent = pcall(
                Network.SendConversationRelationshipForNPC,
                player,
                npcID,
                flavorID(),
                result
            )
            if ok and sent == true then
                emitted = emitted + 1
            end
        end)
    end
    if emitted == 0 then
        -- Nothing was heard, so let the scene be replayed if a player arrives.
        recentByFaction[factionID] = nil
        return false, "no_audience"
    end
    return true, "emitted"
end

-- Test/debug support.
function H.LeaderLossDebugReset()
    recentByFaction = {}
    recentOrder = {}
    return true
end

return Hooks