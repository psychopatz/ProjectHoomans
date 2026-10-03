if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Network = PNC.Network
local flavorText = H.FlavorText
local flavorConst = H.FlavorConst
local callFlavorID = H.CallFlavorID
local updateFlavorID = H.UpdateFlavorID
local repeatFlavorID = H.RepeatFlavorID
local now = H.Now
local clean = H.Clean
local playerCanHear = H.PlayerCanHear
local recordAttackerName = H.RecordAttackerName
local buildInput = H.BuildInput
local lastCallByNPC = H.LastCallByNPC
local markCalled = H.MarkCalled
local HEAR_RADIUS = H.HEAR_RADIUS
local CALL_COOLDOWN_MS = H.CALL_COOLDOWN_MS
local UPDATE_COOLDOWN_MS = H.UPDATE_COOLDOWN_MS
local REPEAT_INTERVAL_MS = H.REPEAT_INTERVAL_MS

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
    return H.ResetIncapacitatedFlavorState()
end

return Hooks
