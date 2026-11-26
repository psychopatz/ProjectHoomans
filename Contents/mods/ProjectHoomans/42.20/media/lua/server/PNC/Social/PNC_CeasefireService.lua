-- Actor-agnostic Surrender & Ceasefire Authority (Human NPCs Only).
-- Supports:
--   1. Player using vanilla `surrender` emote -> 80% one-shot ceasefire roll
--      (permanently locked out if the perpetrator provoked/refused toll).
--   2. AI NPC last-man-standing surrender -> player gets unified Conversation
--      UI choice (Spare vs No Mercy) or 80% roll for AI-vs-AI.
-- Never applies to zombie-typed hostiles.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CeasefireService = PNC.CeasefireService or {}

local Ceasefire = PNC.CeasefireService

local ACCEPT_CHANCE = 0.80
local MAX_CONFLICT_KEYS = 64
local CEASEFIRE_DURATION_HOURS = 4

local conflictStates = {}
local conflictOrder = {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function worldAgeHours(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function" then
        return tonumber(PNC.Core.NowWorldAgeHours()) or 0
    end
    return 0
end

local function conflictKey(actorKey, opponentKey)
    return tostring(actorKey or "") .. "|" .. tostring(opponentKey or "")
end

local function getOrCreateConflict(key)
    local st = conflictStates[key]
    if st then return st end
    while #conflictOrder >= MAX_CONFLICT_KEYS do
        local oldest = table.remove(conflictOrder, 1)
        conflictStates[oldest] = nil
    end
    conflictOrder[#conflictOrder + 1] = key
    st = { attempted = false, revoked = false, revokeReason = nil, activeUntil = 0 }
    conflictStates[key] = st
    return st
end

function Ceasefire.IsEligibleHumanTarget(target)
    if type(target) ~= "table" then return false end
    if target.kind == "zombie" or target.isZombie == true then return false end
    if target.alive == false then return false end
    local Perc = PNC.Perception
    if Perc and type(Perc.IsActualZombieBody) == "function" then
        local body = target.zombie or target.body
        if body and Perc.IsActualZombieBody(body) == true then
            return false
        end
    end
    return target.id ~= nil or target.factionId ~= nil or target.factionID ~= nil or target.isPlayer == true
end

function Ceasefire.RevokeCeasefire(actorKey, opponentKey, reason)
    if not actorKey or not opponentKey then return false end
    local key = conflictKey(actorKey, opponentKey)
    local st = getOrCreateConflict(key)
    st.revoked = true
    st.revokeReason = tostring(reason or "provoked")
    st.activeUntil = 0
    return true
end

function Ceasefire.GetConflictState(actorKey, opponentKey)
    return conflictStates[conflictKey(actorKey, opponentKey)]
end

local function clearCombatTargets(record)
    if type(record) ~= "table" then return end
    if type(record.runtime) == "table" then
        record.runtime.target = nil
        record.runtime.combatTarget = nil
        record.runtime.attackAction = nil
        record.runtime.inCombatUntil = 0
    end
end

local function emitSurrenderBeat(speaker, responder, role, now)
    local Beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    if Beats and type(Beats.Emit) == "function" then
        Beats.Emit("combat.surrender", {
            anchor = speaker,
            speaker = speaker,
            partner = responder,
            role = role,
            poolID = "semantic.combat.surrender",
            anim = role == "surrender_plea" and "surrender" or nil,
            animDurationMs = 5000,
            voice = role == "surrender_plea" and "surrender" or nil,
            allowInCombat = true,
        }, now)
    end
    local Perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
    if Perf and speaker and speaker.isPlayer ~= true then
        if role == "surrender_plea" then
            Perf.Perform(speaker, {
                anim = "surrender",
                animDurationMs = 5000,
                voice = "surrender",
                allowInCombat = true,
                reason = "surrender_ceasefire",
            }, now)
        elseif role == "surrender_no_mercy" or role == "surrender_accept" then
            Perf.Interrupt(speaker, role, now)
        end
    end
end

-- Core actor-agnostic surrender resolution.
function Ceasefire.AttemptSurrender(surrenderer, opponents, opts)
    opts = type(opts) == "table" and opts or {}
    if type(surrenderer) ~= "table" then return false, "invalid_surrenderer" end
    local now = nowMs(opts.now)
    local hours = worldAgeHours(opts.worldAgeHours)

    -- Filter strictly to eligible human NPCs / players (never zombies).
    local validOpponents = {}
    for i = 1, #(opponents or {}) do
        if Ceasefire.IsEligibleHumanTarget(opponents[i]) then
            validOpponents[#validOpponents + 1] = opponents[i]
        end
    end
    if #validOpponents == 0 then
        return false, "no_human_opponents"
    end

    local primaryOpp = validOpponents[1]
    local surrKey = tostring(surrenderer.key or surrenderer.id or "actor")
    local oppKey = tostring(primaryOpp.factionId or primaryOpp.factionID or primaryOpp.key or primaryOpp.id or "opp")
    local key = conflictKey(surrKey, oppKey)
    local st = getOrCreateConflict(key)

    if st.revoked then
        emitSurrenderBeat(surrenderer, primaryOpp, "surrender_revoked", now)
        return false, "ceasefire_revoked"
    end
    if st.attempted then
        emitSurrenderBeat(surrenderer, primaryOpp, "surrender_reject", now)
        return false, "ceasefire_already_used"
    end

    -- If an AI NPC surrenders to a human player, open the unified mercy choice UI!
    if surrenderer.isPlayer ~= true and primaryOpp.isPlayer == true and opts.autoResolve ~= true then
        st.attempted = true
        st.pendingMercy = true
        emitSurrenderBeat(surrenderer, primaryOpp, "surrender_plea", now)
        return true, "pending_player_mercy", {
            storyID = "convo.combat.surrender_mercy",
            surrendererID = surrenderer.id,
            conflictKey = key,
        }
    end

    st.attempted = true
    local roll = tonumber(opts.roll)
    if roll == nil then
        roll = (type(ZombRand) == "function" and (ZombRand(1000) / 1000)) or math.random()
    end

    if roll <= ACCEPT_CHANCE then
        st.activeUntil = hours + CEASEFIRE_DURATION_HOURS
        clearCombatTargets(surrenderer)
        for i = 1, #validOpponents do
            clearCombatTargets(validOpponents[i])
        end
        local oppFid = primaryOpp.factionId or primaryOpp.factionID
        if surrenderer.isPlayer == true and PNC.Factions and type(PNC.Factions.PacifyForPlayer) == "function"
            and oppFid
        then
            PNC.Factions.PacifyForPlayer(oppFid, surrKey, {
                worldAgeHours = hours,
                durationHours = CEASEFIRE_DURATION_HOURS,
                reason = "surrender_ceasefire",
            })
        elseif surrenderer.isPlayer ~= true and PNC.BehaviorFlee and type(PNC.BehaviorFlee.StartFlee) == "function" then
            PNC.BehaviorFlee.StartFlee(surrenderer, {
                threatX = primaryOpp.x,
                threatY = primaryOpp.y,
                reason = "spared",
            }, now)
        end
        emitSurrenderBeat(surrenderer, primaryOpp, "surrender_accept", now)
        return true, "ceasefire_accepted"
    end

    emitSurrenderBeat(surrenderer, primaryOpp, "surrender_reject", now)
    return false, "ceasefire_rejected_roll"
end

-- Resolves the player's Spare vs No Mercy decision when an AI NPC surrenders.
function Ceasefire.ResolveMercyDecision(npcRecord, playerRef, decision, opts)
    opts = type(opts) == "table" and opts or {}
    if type(npcRecord) ~= "table" or type(playerRef) ~= "table" then
        return false, "invalid_args"
    end
    local now = nowMs(opts.now)
    local hours = worldAgeHours(opts.worldAgeHours)
    local surrKey = tostring(npcRecord.key or npcRecord.id or "npc")
    local oppKey = tostring(playerRef.key or playerRef.id or "player")
    local st = getOrCreateConflict(conflictKey(surrKey, oppKey))
    st.pendingMercy = false

    if tostring(decision or "") == "spare" then
        st.activeUntil = hours + CEASEFIRE_DURATION_HOURS
        clearCombatTargets(npcRecord)
        if PNC.BehaviorFlee and type(PNC.BehaviorFlee.StartFlee) == "function" then
            PNC.BehaviorFlee.StartFlee(npcRecord, {
                threatX = playerRef.x,
                threatY = playerRef.y,
                reason = "spared",
            }, now)
        end
        emitSurrenderBeat(npcRecord, playerRef, "surrender_accept", now)
        return true, "spared_and_fleeing"
    end

    -- No mercy -> revoke ceasefire and immediately turn hostile again!
    st.revoked = true
    st.revokeReason = "no_mercy"
    st.activeUntil = 0
    npcRecord.activeBehavior = "hostile"
    npcRecord.isHostile = true
    if type(npcRecord.runtime) == "table" then
        npcRecord.runtime.target = playerRef.actor or playerRef
    end
    emitSurrenderBeat(npcRecord, playerRef, "surrender_no_mercy", now)
    return false, "no_mercy_hostile_resumed"
end

-- AI last-man-standing trigger: when an NPC's teammates are all dead and they
-- are the only one left, they surrender to human opponents (never zombies).
function Ceasefire.CheckLastManStandingSurrender(npcRecord, aliveSquadmates, opponents, opts)
    if type(npcRecord) ~= "table" or npcRecord.alive == false then return false, "invalid_npc" end
    if (tonumber(aliveSquadmates) or 0) > 1 then return false, "squad_still_alive" end
    return Ceasefire.AttemptSurrender(npcRecord, opponents, opts)
end

function Ceasefire.ResetRuntime()
    conflictStates = {}
    conflictOrder = {}
end

return Ceasefire
