--[[
    Social facing for the downed (incapacitated) state.

    This module owns the *distress* speech a downed NPC emits toward the
    survivors who can actually hear it.  It is the counterpart to the existing
    witness-driven modules: the *trigger* is the NPC's own health transition
    (it just went down, or its wound picture changed while down), but delivery
    is per nearby player because a flavor line has to reach a client.

    Every line is attributed, per listener, through PNC.FlavorText, so the
    downed NPC addresses whoever is there in the correct register:

        own follower / faction member -> "I need patching"    (ally)
        warm friend or self            -> a request, not an order
        a different, peaceful faction  -> "I'm fainting, help me" (stranger)
        a personal or faction enemy    -> mercy from a survivor,
                                          or a faint in front of the dead
        a zombie                       -> dying noise, never a plea to a human

    Performance: this runs once per incapacitation *edge* per NPC, not per
    tick.  The per-listener loop is bounded by the online/active player list
    and short-circuits on range, line of sight, and a per-listener cooldown
    that is reserved before the network send so a hostile crowd cannot make a
    single downed NPC spam the queue.
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
-- The flavor vocabulary is owned by the shared composition, which may not
-- have run when this module is required.  Resolve it at call time so load
-- order can never break the server tree.
local function flavorText()
    return PNC.FlavorText
end

-- Never return nil: callers read fields straight off the result, and a nil
-- table would turn a graceful degradation into an index error.
local EMPTY_CONSTANTS = {}
local function flavorConst()
    return PNC.FlavorTextConst or EMPTY_CONSTANTS
end

-- Flavor ids carry their own literals so the module is usable (and testable)
-- even if the constants table is absent.
local function callFlavorID()
    return flavorConst().FLAVOR_CALL or "social.incapacitated_call"
end

local function updateFlavorID()
    return flavorConst().FLAVOR_UPDATE or "social.incapacitated_update"
end

local function repeatFlavorID()
    return flavorConst().FLAVOR_REPEAT or "social.incapacitated_repeat"
end

local HEAR_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
local CALL_COOLDOWN_MS = 20000
local UPDATE_COOLDOWN_MS = 25000
-- While an NPC stays down it keeps asking for help, but on a slow cadence so
-- the plea reads as persistence rather than spam.  The refresh is driven by
-- the existing incapacitated behavior tick, so there is no new timer.
local REPEAT_INTERVAL_MS = 45000
local MAX_TRACKED_NPCS = 256

-- Per-NPC debounce so a flapping health state cannot re-trigger the line.
local lastCallByNPC = {}
local lastCallOrder = {}

local function now()
    return (Core and Core.Now and Core.Now()) or 0
end

local function clean(value, fallback)
    if value == nil then return fallback end
    return tostring(value) ~= "" and tostring(value) or fallback
end

local function clampHistory()
    while #lastCallOrder > MAX_TRACKED_NPCS do
        local oldest = table.remove(lastCallOrder, 1)
        if oldest then lastCallByNPC[oldest] = nil end
    end
end

local function markCalled(npcID, at)
    if not lastCallByNPC[npcID] then
        lastCallOrder[#lastCallOrder + 1] = npcID
    end
    lastCallByNPC[npcID] = at
    clampHistory()
end

local function distanceSq(x1, y1, x2, y2)
    if Core and Core.DistanceSq then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx = x2 - x1
    local dy = y2 - y1
    return (dx * dx) + (dy * dy)
end

local function coordinate(object, method, fallback)
    if not object or type(object[method]) ~= "function" then
        return fallback
    end
    local ok, value = pcall(object[method], object)
    if ok and value ~= nil then return tonumber(value) end
    return fallback
end

local function playerCanHear(player, record, radiusSq)
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = tonumber(record and record.x)
    local ny = tonumber(record and record.y)
    local nz = tonumber(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1
        or distanceSq(px, py, nx, ny) > radiusSq
    then
        return false
    end
    local perception = PNC.Perception
    if perception and type(perception.CanSeeWorldObject) == "function" then
        return perception.CanSeeWorldObject(record, player) == true
    end
    -- Without a perception service, proximity is the honest answer.
    return true
end

-- ---------------------------------------------------------------------------
-- Server-side inputs for the resolver
-- ---------------------------------------------------------------------------

local function resolveThreat(record)
    local perception = PNC.Perception
    local threat
    if perception and type(perception.ResolveRecentAttacker) == "function" then
        local ok, resolved = pcall(perception.ResolveRecentAttacker, record, now())
        if ok then threat = resolved end
    end
    if not threat and record and record.runtime then
        threat = record.runtime.recentThreat
    end
    return threat
end

local function recordAttackerName(threat)
    if type(threat) ~= "table" then return nil end
    local id = threat.id
    if id == nil or id == "" then return nil end
    local registry = PNC.Registry
    local attackerRecord = registry and type(registry.Get) == "function"
        and registry.Get(id) or nil
    if attackerRecord then
        return clean(attackerRecord.displayName
            or attackerRecord.name or attackerRecord.id, nil)
    end
    return nil
end

-- Cross-faction standing, resolved by the faction service when available.
local function factionBandFor(record, listener)
    local factions = PNC.Factions
    if not factions or type(factions.GetFactionID) ~= "function" then
        return nil
    end
    local mine, theirs
    local ok, value = pcall(factions.GetFactionID, record)
    if ok then mine = value end
    if not mine then return nil end
    if listener == nil then return nil end
    local okOwned, listenerFaction = pcall(factions.GetFactionID, listener)
    if not okOwned then listenerFaction = nil end
    if listenerFaction and listenerFaction == mine then return "same" end
    if not listenerFaction then return nil end
    if type(factions.AreAtWar) == "function" then
        local okWar, atWar = pcall(factions.AreAtWar, mine, listenerFaction)
        if okWar and atWar == true then return "war" end
    end
    if type(factions.AreAllied) == "function" then
        local okAlly, allied = pcall(
            factions.AreAllied, mine, listenerFaction
        )
        if okAlly and allied == true then return "allied" end
    end
    return "different"
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

-- Is this record the listener's own follower/companion?  Ownership is a hard
-- "ally" signal regardless of the faction registry's availability.  The mod
-- exposes ownership through the command registry and the identity verifier;
-- both are optional here so the hook still works in a reduced environment.
local function isOwned(record, player)
    if not record or not player then return false end
    local commands = PNC.Commands
    if commands and type(commands.IsOwnedByPlayer) == "function" then
        local ok, owned = pcall(commands.IsOwnedByPlayer, record, player)
        if ok and owned ~= nil then return owned == true end
    end
    local identity = PNC.Identity
    local verifier = identity and identity.Verifier
    if verifier and type(verifier.IsOwnedByPlayer) == "function" then
        local ok, owned = pcall(verifier.IsOwnedByPlayer, record, player)
        if ok and owned ~= nil then return owned == true end
    end
    local runtime = record.runtime
    if runtime and runtime.ownerPlayerID then
        local playerID
        if type(player.getUsername) == "function" then
            playerID = player:getUsername()
        elseif type(player.getPlayerNum) == "function" then
            playerID = player:getPlayerNum()
        end
        playerID = clean(playerID, nil)
        if playerID and tostring(runtime.ownerPlayerID) == tostring(playerID) then
            return true
        end
    end
    -- A recruited NPC is group property; treat it as allied to any listener in
    -- the same faction rather than inventing an owner.
    return false
end

-- Build the resolver input for one (downed NPC, listener) pair.
local function buildInput(record, player, needInputs)
    local threat = resolveThreat(record)
    local playerKey = Hooks.ResolvePlayerKey
        and Hooks.ResolvePlayerKey(player) or nil
    local relationship = relationshipFor(record, playerKey)
    local band = factionBandFor(record, player)
    local factionID
    local otherFactionID
    local factions = PNC.Factions
    if factions and type(factions.GetFactionID) == "function" then
        local okMine, mine = pcall(factions.GetFactionID, record)
        if okMine then factionID = mine end
        local okTheirs, theirs = pcall(factions.GetFactionID, player)
        if okTheirs then otherFactionID = theirs end
    end
    local input = {
        threat = threat,
        relationshipState = relationshipState(relationship),
        relationshipTier = relationshipTier(relationship),
        isCompanion = isOwned(record, player),
        -- A recruited NPC belongs to a player group; without an owner match it
        -- is still addressed as a friendly rather than as an anonymous
        -- stranger, which is the safer reading of an existing relationship.
        isFollower = record.recruited == true,
        factionID = factionID,
        otherFactionID = otherFactionID,
    }
    if band == "war" then
        input.factionBand = (flavorConst().Audience or {}).HOSTILE
    elseif band == "allied" or band == "same" then
        input.factionBand = (flavorConst().Audience or {}).ALLY
    end
    -- Wound inputs are resolved once per call site, not per listener.
    if type(needInputs) == "table" then
        local key
        for key, value in pairs(needInputs) do
            input[key] = value
        end
    end
    return input, threat
end

-- ---------------------------------------------------------------------------
-- Delivery
-- ---------------------------------------------------------------------------

local function emitDistress(record, flavorID, needInputs, reason, cooldownMs)
    local npcID = clean(record and record.id, nil)
    local at = now()
    if not npcID then return 0, "invalid_subject" end
    if record.alive == false then return 0, "subject_dead" end
    local previous = lastCallByNPC[npcID]
    if previous and at - previous < cooldownMs then
        return 0, "debounced"
    end
    local resolver = flavorText()
    if not resolver or type(resolver.BuildContext) ~= "function" then
        return 0, "resolver_unavailable"
    end
    if not Network
        or type(Network.SendConversationRelationshipForNPC) ~= "function"
    then
        return 0, "transport_unavailable"
    end
    if not Core or type(Core.ForEachPlayer) ~= "function" then
        return 0, "player_enumerator_unavailable"
    end
    local radiusSq = HEAR_RADIUS * HEAR_RADIUS
    local emitted = 0
    local eventID = "downed:" .. npcID .. ":" .. tostring(math.floor(at))
    markCalled(npcID, at)
    Core.ForEachPlayer(function(player)
        if not player or not playerCanHear(player, record, radiusSq) then
            return
        end
        local input, threat = buildInput(record, player, needInputs)
        local context = resolver.BuildContext(input)
        context.eventType = flavorID
        context.downedAttackerName = recordAttackerName(threat)
        context.attackerKind = context.downedThreat
        context.downedReason = reason
        context.victimNPCID = npcID
        local result = {
            source = flavorID,
            eventID = eventID,
            npcID = npcID,
            ambientFlavor = {
                eventID = eventID,
                flavorID = flavorID,
                eventType = flavorID,
                family = (flavorConst().FAMILY or "incapacitated_distress"),
                priority = (flavorConst().PRIORITY or 70),
                weight = (flavorConst().WEIGHT or 3),
                llmEligible = false,
                memoryEligible = false,
                npcID = npcID,
                npcType = context.downedAudience,
                socialRole = context.downedAudience,
                relationshipState = input.relationshipState,
                relationshipTier = input.relationshipTier,
                -- One merge key per downed episode keeps "call" and "update"
                -- as a single visible line that updates in place.
                mergeKey = npcID .. ":" .. (flavorConst().FAMILY or "incapacitated_distress"),
                cooldowns = {
                    familyMs = (flavorConst().FAMILY_COOLDOWN_MS or 15000),
                    speakerMs = (flavorConst().SPEAKER_COOLDOWN_MS or 12000),
                    ambientMs = (flavorConst().AMBIENT_CADENCE_MS or 4500),
                    mergeWindowMs = (flavorConst().MERGE_WINDOW_MS or 8000),
                },
                ttlMs = (flavorConst().TTL_MS or 12000),
                holdMs = (flavorConst().HOLD_MS or 3200),
                context = context,
                source = {
                    kind = "social_flavor",
                    channel = "health",
                    eventType = flavorID,
                    contextEligible = false,
                },
            },
        }
        local ok, sent = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            flavorID,
            result
        )
        if ok and sent == true then
            emitted = emitted + 1
        end
    end)
    return emitted, emitted > 0 and "emitted" or "no_audience"
end

-- ---------------------------------------------------------------------------
-- Wound picture -> resolver need inputs
-- ---------------------------------------------------------------------------

local function woundInputs(record)
    local wounds = PNC.NPCWounds
    if not wounds then return { critical = true } end
    local summary
    if type(wounds.BuildStatusSummary) == "function" then
        local ok, value = pcall(wounds.BuildStatusSummary, record)
        if ok then summary = value end
    end
    local treatable = {}
    if type(wounds.GetTreatableWounds) == "function" then
        local ok, value = pcall(wounds.GetTreatableWounds, record)
        if ok and type(value) == "table" then treatable = value end
    end
    local infected = false
    if type(wounds.HasActiveInfection) == "function" then
        local ok, value = pcall(wounds.HasActiveInfection, record)
        if ok then infected = value == true end
    end
    local health = record.health or {}
    local current = tonumber(health.current)
    local max = tonumber(health.max)
    local critical = current == nil or max == nil or max <= 0
        or (current / max) <= 0.25
    return {
        bleeding = summary and summary.bleeding == true or false,
        bleedingRate = summary and tonumber(summary.bleedingRate),
        openWoundCount = summary and summary.openWoundCount,
        treatableWoundCount = #treatable,
        infected = infected,
        critical = critical,
    }
end

-- ---------------------------------------------------------------------------
-- Public hooks
-- ---------------------------------------------------------------------------

-- Called from the health module the moment an NPC enters the downed state.
function Hooks.OnIncapacitated(record, reason)
    if not record or record.alive == false then
        return false, "invalid_subject"
    end
    local emitted, status = emitDistress(
        record,
        callFlavorID(),
        woundInputs(record),
        reason,
        CALL_COOLDOWN_MS
    )
    return emitted > 0, status
end

-- Called when the wound picture changes while the NPC is still down, so a
-- follower that starts bleeding out asks for a bandage specifically.
function Hooks.OnIncapacitatedStatusChanged(record, reason)
    if not record or record.alive == false then
        return false, "invalid_subject"
    end
    local health = record.health
    if not health or health.state ~= "incapacitated" then
        return false, "not_incapacitated"
    end
    local emitted, status = emitDistress(
        record,
        updateFlavorID(),
        woundInputs(record),
        reason,
        UPDATE_COOLDOWN_MS
    )
    return emitted > 0, status
end

-- Driven by the existing incapacitated behavior tick (PNC.BehaviorIncapacitated
-- .Tick), which already runs per-tick for exactly the downed NPCs.  No timer is
-- added: this only decides whether enough time has passed to ask again.
function Hooks.TickIncapacitatedDistress(record)
    local npcID
    local at
    local previous
    if not record or record.alive == false then return false end
    local health = record.health
    if not health or health.state ~= "incapacitated" then return false end
    npcID = clean(record.id, nil)
    if not npcID then return false end
    at = now()
    previous = lastCallByNPC[npcID]
    if not previous then
        -- The NPC went down through a path that did not emit the initial call
        -- (loaded save, desync).  Treat the first tick as the call instead of
        -- waiting a full interval in silence.
        return Hooks.OnIncapacitated(record, "tick_adopted")
    end
    if at - previous < REPEAT_INTERVAL_MS then return false end
    local emitted, status = emitDistress(
        record,
        repeatFlavorID(),
        woundInputs(record),
        "repeat",
        REPEAT_INTERVAL_MS
    )
    return emitted > 0, status
end

-- Test/debug support.
function H.IncapacitatedFlavorDebugReset()
    lastCallByNPC = {}
    lastCallOrder = {}
    return true
end

return Hooks