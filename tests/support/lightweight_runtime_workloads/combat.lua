-- L6 workload family B: combat-hit contact spikes.
--
-- Compares pre-impact miss controls against accepted hits for:
--   NPC -> zombie   (COMBAT_NPC_ZOMBIE_MISS / COMBAT_NPC_ZOMBIE_HIT)
--   NPC -> NPC      (COMBAT_NPC_NPC_MISS    / COMBAT_NPC_NPC_HIT)
--   NPC -> player   (COMBAT_NPC_PLAYER_MISS / COMBAT_NPC_PLAYER_HIT)
-- across attacker counts 1 / 3 / 6 / 12, staggered vs synchronized same-tick
-- contacts, nonlethal repeated hits, kill/incapacitation transitions, and
-- witness-population scaling.
--
-- Drives real production CombatResolution.BuildHitEvent -> ApplyTargetDamage
-- -> target handlers -> wounds/aggro/faction/social/semantic/network/dirty.
-- Only narrow PZ engine boundaries (zombie Hit/Kill, player BodyDamage/BodyPart,
-- sendPlayerStatsChange) are faked and counted.

local Probe = require "tests/support/lightweight_runtime_workloads/probe"

local Combat = {}

Combat.Scenarios = {
    "COMBAT_NPC_ZOMBIE_MISS",
    "COMBAT_NPC_ZOMBIE_HIT",
    "COMBAT_NPC_NPC_MISS",
    "COMBAT_NPC_NPC_HIT",
    "COMBAT_NPC_PLAYER_MISS",
    "COMBAT_NPC_PLAYER_HIT",
}

local function makeBodyPart(probe)
    local health = 100
    local pain = 0
    local bleed = 0
    local cut = 0
    local scratch = 0
    local deep = false
    return {
        AddDamage = function(_, d)
            probe:Add("Native.PlayerBodyPart.AddDamage")
            health = math.max(10, health - (tonumber(d) or 0))
        end,
        getHealth = function() return health end,
        setHealth = function(_, v)
            probe:Add("Native.PlayerBodyPart.SetHealth")
            health = math.max(10, tonumber(v) or health)
        end,
        getAdditionalPain = function() return pain end,
        setAdditionalPain = function(_, v) pain = tonumber(v) or pain end,
        getBleedingTime = function() return bleed end,
        setBleedingTime = function(_, v) bleed = tonumber(v) or bleed end,
        getCutTime = function() return cut end,
        setCutTime = function(_, v) cut = tonumber(v) or cut end,
        getScratchTime = function() return scratch end,
        setScratchTime = function(_, v) scratch = tonumber(v) or scratch end,
        setDeepWounded = function(_, v) deep = v == true end,
        isDeepWounded = function() return deep end,
    }
end

local function installPlayerDamageSurface(player, probe)
    local parts = {}
    local overall = 100
    BodyPartType = BodyPartType or {
        Torso_Upper = "Torso_Upper",
        Torso_Lower = "Torso_Lower",
        UpperArm_L = "UpperArm_L",
        UpperArm_R = "UpperArm_R",
        ForeArm_L = "ForeArm_L",
        ForeArm_R = "ForeArm_R",
        UpperLeg_L = "UpperLeg_L",
        UpperLeg_R = "UpperLeg_R",
        LowerLeg_L = "LowerLeg_L",
        LowerLeg_R = "LowerLeg_R",
        Head = "Head",
        Neck = "Neck",
        Hand_L = "Hand_L",
        Hand_R = "Hand_R",
    }
    local bodyDamage = {
        getBodyPart = function(_, partType)
            local key = tostring(partType or "Torso_Upper")
            parts[key] = parts[key] or makeBodyPart(probe)
            return parts[key]
        end,
        getOverallBodyHealth = function() return overall end,
        setOverallBodyHealth = function(_, v) overall = math.max(10, tonumber(v) or overall) end,
        Update = function()
            probe:Add("Native.BodyDamage.Update")
        end,
    }
    player.getBodyDamage = function() return bodyDamage end
    player.getHealth = function() return overall / 100 end
    player.setHealth = function(_, v) overall = math.max(10, (tonumber(v) or 1) * 100) end
    sendPlayerStatsChange = function()
        probe:Add("Native.SendPlayerStatsChange")
    end
end

local function makeCombatZombie(ctx, x, y, probe)
    local z = ctx.makeZombieShell(x, y, 0)
    local hp = 1.0
    local dead = false
    z.getHealth = function() return hp end
    z.setHealth = function(_, v)
        hp = tonumber(v) or hp
        if hp <= 0 then dead = true end
    end
    z.isDead = function() return dead end
    z.Hit = function(_, weapon, attacker, dmg)
        probe:Add("Native.Zombie.Hit")
        hp = hp - (tonumber(dmg) or 0.35)
        if hp <= 0 then dead = true end
    end
    z.Kill = function()
        probe:Add("Native.Zombie.Kill")
        hp = 0
        dead = true
    end
    return z
end

-- options:
--   scenario: one of Combat.Scenarios
--   attackers: 1 | 3 | 6 | 12
--   synchronized: boolean (true = all attackers strike on same tick, false = staggered)
--   witnesses: number of extra live bystander NPCs (for player-hit witness scaling)
--   rounds: number of impact rounds (default 8)
function Combat.New(options)
    local scenario = assert(options.scenario, "combat scenario required")
    local attackerCount = options.attackers or 6
    local synchronized = options.synchronized == true
    local witnessCount = options.witnesses or 0
    local rounds = options.rounds or 8
    local isHit = string.sub(scenario, -4) == "_HIT"
    local targetKind = scenario:find("ZOMBIE") and "zombie"
        or (scenario:find("PLAYER") and "player" or "npc")
    local probe = Probe.New()
    local state = {
        probe = probe,
        attackers = {},
        victims = {},
        witnesses = {},
        zombieTargets = {},
        readyAt = nil,
        round = 0,
        nextRoundAt = 0,
        staggerIndex = 0,
        impactCpuSamples = {},
        tickSamples = {},
        hitsApplied = 0,
        missesExecuted = 0,
        killsObserved = 0,
        incapObserved = 0,
    }
    local wl = { ownsPlayerMotion = true, suppressLegacyMutations = true, state = state }

    local function spawnHostileRecord(id, x, y, factionID)
        local record = assert(PNC.API.Spawn({
            id = id,
            displayName = id,
            x = x,
            y = y,
            z = 0,
            tacticalClass = PNC.Const.TACTICAL_CLASS_HOSTILE,
            hostility = {
                mode = "hostile",
                attackPlayers = true,
                attackNPCs = true,
                attackZombies = true,
            },
        }))
        record.runtime = record.runtime or {}
        record.runtime.forceLive = true
        if factionID and PNC.Factions and PNC.Factions.AssignNPC then
            PNC.Factions.AssignNPC(record, factionID)
        end
        return record
    end

    local function ensureLiveBody(record)
        local body = PNC.Registry.GetLiveZombie(record.id)
        if not body and PNC.Presence and PNC.Presence.Materialize then
            PNC.Presence.Materialize(record, "l6_combat_setup")
            body = PNC.Registry.GetLiveZombie(record.id)
        end
        return body
    end

    function wl.Setup(ctx)
        local player = ctx.players[1]
        installPlayerDamageSurface(player, probe)
        -- Create two opposing factions for real NPC->NPC and NPC->player checks.
        local atkFactionID, vicFactionID
        if PNC.Factions and PNC.Factions.CreateFaction then
            local f1 = PNC.Factions.CreateFaction({
                id = "l6_atk_faction",
                name = "L6 Attackers",
                archetypeID = "raider",
            })
            local f2 = PNC.Factions.CreateFaction({
                id = "l6_vic_faction",
                name = "L6 Defenders",
                archetypeID = "settler",
            })
            atkFactionID = f1 and f1.id or "l6_atk_faction"
            vicFactionID = f2 and f2.id or "l6_vic_faction"
            if PNC.Factions.SetRelation then
                PNC.Factions.SetRelation(atkFactionID, vicFactionID, -100, "l6_combat_war")
            end
        end

        for i = 1, attackerCount do
            local rec = spawnHostileRecord(
                "l6_atk_" .. tostring(i),
                player:getX() + 1.5 + (i % 4) * 0.5,
                player:getY() + math.floor((i - 1) / 4) * 0.5,
                atkFactionID
            )
            ensureLiveBody(rec)
            state.attackers[i] = rec
        end

        if targetKind == "zombie" then
            for i = 1, math.max(attackerCount, 4) do
                state.zombieTargets[i] = makeCombatZombie(
                    ctx,
                    player:getX() + 2.5 + (i % 4) * 0.4,
                    player:getY() + 1.0,
                    probe
                )
            end
        elseif targetKind == "npc" then
            for i = 1, math.max(attackerCount, 4) do
                local vic = spawnHostileRecord(
                    "l6_vic_" .. tostring(i),
                    player:getX() + 2.5 + (i % 4) * 0.5,
                    player:getY() + 1.5 + math.floor((i - 1) / 4) * 0.5,
                    vicFactionID
                )
                ensureLiveBody(vic)
                state.victims[i] = vic
            end
        end

        for i = 1, witnessCount do
            local wit = assert(PNC.API.Spawn({
                id = "l6_wit_" .. tostring(i),
                displayName = "Witness " .. tostring(i),
                x = player:getX() - 2 - (i % 6),
                y = player:getY() - 2 - math.floor((i - 1) / 6),
                z = 0,
            }))
            wit.runtime = wit.runtime or {}
            wit.runtime.forceLive = true
            ensureLiveBody(wit)
            state.witnesses[i] = wit
        end

        -- Attach observation probes to all real combat & downstream seams.
        probe:AttachDiagnostics(PNC.PerformanceScalingDiagnostics)
        probe:Wrap(PNC.CombatResolution, "BuildHitEvent", "Combat.BuildHitEvent")
        probe:Wrap(PNC.CombatResolution, "ApplyTargetDamage", "Combat.ApplyTargetDamage", function(ok)
            return ok and "ok" or "rejected"
        end)
        probe:Wrap(PNC.CombatResolution, "ApplyZombieDamage", "Combat.ApplyZombieDamage")
        probe:Wrap(PNC.CombatResolution, "ApplyNPCDamage", "Combat.ApplyNPCDamage")
        probe:Wrap(PNC.CombatResolution, "ApplyPlayerDamage", "Combat.ApplyPlayerDamage")
        if PNC.CombatZombieReaction then
            probe:Wrap(PNC.CombatZombieReaction, "ApplyWeaponHit", "Zombie.ReactionApply")
            probe:Wrap(PNC.CombatZombieReaction, "Start", "Zombie.ReactionStart")
        end
        if PNC.ZombieAggro then
            probe:Wrap(PNC.ZombieAggro, "OnZombieProvoked", "Zombie.AggroProvoked")
        end
        if PNC.NPCWounds then
            probe:Wrap(PNC.NPCWounds, "ApplyCombatDamage", "NPC.WoundsApply")
        end
        if PNC.Health then
            probe:Wrap(PNC.Health, "ApplyDamage", "NPC.HealthDamage")
        end
        if PNC.MedicalCareService then
            probe:Wrap(PNC.MedicalCareService, "RequestNPC", "NPC.MedicalRequest")
        end
        if PNC.Factions then
            probe:Wrap(PNC.Factions, "OnNPCAggression", "Faction.NPCAggression")
            probe:Wrap(PNC.Factions, "OnNPCAttackPlayer", "Faction.AttackedPlayer")
        end
        if PNC.SocialEventHooks then
            probe:Wrap(PNC.SocialEventHooks, "OnThreatNeutralized", "Social.ThreatNeutralized")
        end
        if PNC.SocialEventHooksInternal then
            probe:Wrap(PNC.SocialEventHooksInternal, "RecordNPCDamagedNPC", "Social.NPCDamagedNPC")
            probe:Wrap(PNC.SocialEventHooksInternal, "RecordNPCDamagedPlayer", "Social.NPCDamagedPlayer")
            probe:Wrap(PNC.SocialEventHooksInternal, "RecordPlayerHurtWitnesses", "Social.PlayerHurtWitnesses")
        end
        if PNC.SocialEncounterTracker then
            probe:Wrap(PNC.SocialEncounterTracker, "RecordActivity", "Social.EncounterActivity")
        end
        if PNC.Semantics and PNC.Semantics.EngineEvents then
            probe:Wrap(PNC.Semantics.EngineEvents, "Publish", "Semantic.EngineEvent")
        end
        local reactSvc = PNC.SemanticCombatReactionService
            or (PNC.Semantics and PNC.Semantics.CombatReactionService)
        if reactSvc then
            probe:Wrap(reactSvc, "OnNPCKill", "Semantic.OnNPCKill")
            probe:Wrap(reactSvc, "OnNPCHumanKill", "Semantic.OnNPCHumanKill")
        end
        if PNC.Network then
            probe:Wrap(PNC.Network, "BroadcastZombieReaction", "Network.ZombieReaction")
            probe:Wrap(PNC.Network, "BroadcastRecord", "Network.BroadcastRecord")
            probe:Wrap(PNC.Network, "BroadcastRemoval", "Network.BroadcastRemoval")
        end
        if PNC.Registry then
            probe:Wrap(PNC.Registry, "MarkDirty", "Registry.MarkDirty")
            probe:Wrap(PNC.Registry, "ForEachLive", "Registry.ForEachLive")
        end
        if PNC.WorldCensus then
            probe:Wrap(PNC.WorldCensus, "Refresh", "Census.Refresh")
        end

        probe.enabled = true
        state.nextRoundAt = ctx.now() + 200
    end

    local function executeStrike(ctx, attackerIndex, roundNum)
        local attacker = state.attackers[attackerIndex]
        if not attacker or attacker.alive == false then return end
        local attackerBody = ensureLiveBody(attacker)
        local target
        local dmg = 22
        if targetKind == "zombie" then
            local z = state.zombieTargets[((attackerIndex - 1) % #state.zombieTargets) + 1]
            if z:isDead() then
                z = makeCombatZombie(ctx, ctx.players[1]:getX() + 2.5, ctx.players[1]:getY() + 1.0, probe)
                state.zombieTargets[((attackerIndex - 1) % #state.zombieTargets) + 1] = z
            end
            target = { kind = "zombie", worldObject = z, zombieId = z:getOnlineID(), id = z:getOnlineID() }
            -- Make every 3rd hit lethal to exercise both nonlethal and kill transitions.
            dmg = (roundNum % 3 == 0) and 120 or 35
        elseif targetKind == "npc" then
            local vIdx = ((attackerIndex - 1) % #state.victims) + 1
            local victim = state.victims[vIdx]
            if victim.alive == false then
                victim = spawnHostileRecord(
                    "l6_vic_respawn_" .. tostring(roundNum) .. "_" .. tostring(attackerIndex),
                    ctx.players[1]:getX() + 2.5,
                    ctx.players[1]:getY() + 1.5,
                    "l6_vic_faction"
                )
                ensureLiveBody(victim)
                state.victims[vIdx] = victim
            end
            target = {
                kind = "npc",
                id = victim.id,
                record = victim,
                zombie = ensureLiveBody(victim),
                immediateSelfDefense = true,
            }
            dmg = (roundNum % 4 == 0) and 120 or 20
        else
            target = {
                kind = "player",
                player = ctx.players[1],
                immediateSelfDefense = true,
            }
            dmg = 12
        end

        local opts = {
            damage = dmg,
            attackType = "melee",
            attackKind = "melee",
            weaponFullType = "Base.BaseballBat",
        }

        local t0 = os.clock()
        if not isHit then
            -- Pre-impact control: run hit-event construction + target/hostility
            -- validation without applying damage.
            PNC.CombatResolution.BuildHitEvent(attacker, target, opts)
            state.missesExecuted = state.missesExecuted + 1
        else
            local ok = PNC.CombatResolution.ApplyTargetDamage(attacker, attackerBody, target, opts)
            if ok then
                state.hitsApplied = state.hitsApplied + 1
                if targetKind == "zombie" and target.worldObject:isDead() then
                    state.killsObserved = state.killsObserved + 1
                elseif targetKind == "npc" then
                    if target.record.alive == false then
                        state.killsObserved = state.killsObserved + 1
                    elseif target.record.health and target.record.health.state == "incapacitated" then
                        state.incapObserved = state.incapObserved + 1
                    end
                end
            end
        end
        state.impactCpuSamples[#state.impactCpuSamples + 1] = (os.clock() - t0) * 1000
    end

    local function runDueStrikes(ctx)
        local now = ctx.now()
        if state.round >= rounds then return end
        if synchronized then
            if now >= state.nextRoundAt then
                state.round = state.round + 1
                state.nextRoundAt = now + 450
                for i = 1, attackerCount do
                    executeStrike(ctx, i, state.round)
                end
            end
        else
            if now >= state.nextRoundAt then
                state.staggerIndex = state.staggerIndex + 1
                local attackerIdx = ((state.staggerIndex - 1) % attackerCount) + 1
                if attackerIdx == 1 then state.round = state.round + 1 end
                state.nextRoundAt = now + math.max(50, math.floor(450 / attackerCount))
                executeStrike(ctx, attackerIdx, state.round)
            end
        end
    end

    function wl.BeforeTick(ctx, tick, elapsedMs)
        -- Execute due strikes inside Server.OnTick (via PrepareTick hook) so
        -- same-tick coalescing and FinishTick flushes run identically to live
        -- gameplay.
        if not state.hookedServerTick then
            state.hookedServerTick = true
            local srv = PNC.Server and PNC.Server.Internal
            if srv and type(srv.PrepareTick) == "function" then
                local origPrepare = srv.PrepareTick
                srv.PrepareTick = function(nowArg)
                    local due = origPrepare(nowArg)
                    runDueStrikes(ctx)
                    return due
                end
            end
        end
    end

    function wl.AfterTick(ctx, tick, elapsedMs, tickMs)
        if not probe.enabled then return end
        probe:EndFrame()
        state.tickSamples[#state.tickSamples + 1] = tickMs
    end

    function wl.Finish(ctx)
        probe.enabled = false
        local p = probe
        return {
            Scenario = scenario,
            TargetKind = targetKind,
            IsHit = isHit,
            Attackers = attackerCount,
            Synchronized = synchronized,
            Witnesses = witnessCount,
            HitsApplied = state.hitsApplied,
            MissesExecuted = state.missesExecuted,
            KillsObserved = state.killsObserved,
            IncapObserved = state.incapObserved,
            BuildHitEvent = p:Get("Combat.BuildHitEvent"),
            ApplyTargetDamage = p:Get("Combat.ApplyTargetDamage"),
            ApplyTargetDamageOk = p:Get("Combat.ApplyTargetDamage.ok"),
            NativeZombieHit = p:Get("Native.Zombie.Hit"),
            ZombieReactionApply = p:Get("Zombie.ReactionApply"),
            ZombieAggroProvoked = p:Get("Zombie.AggroProvoked"),
            ZombieReactionBroadcast = p:Get("Network.ZombieReaction"),
            NPCWoundsApply = p:Get("NPC.WoundsApply"),
            NPCHealthDamage = p:Get("NPC.HealthDamage"),
            NPCMedicalRequest = p:Get("NPC.MedicalRequest"),
            PlayerBodyPartDamage = p:Get("Native.PlayerBodyPart.AddDamage"),
            PlayerBodyDamageUpdate = p:Get("Native.BodyDamage.Update"),
            PlayerStatsChange = p:Get("Native.SendPlayerStatsChange"),
            FactionNPCAggression = p:Get("Faction.NPCAggression"),
            FactionAttackedPlayer = p:Get("Faction.AttackedPlayer"),
            SocialEncounterActivity = p:Get("Social.EncounterActivity"),
            SocialThreatNeutralized = p:Get("Social.ThreatNeutralized"),
            SocialNPCDamagedNPC = p:Get("Social.NPCDamagedNPC"),
            SocialNPCDamagedPlayer = p:Get("Social.NPCDamagedPlayer"),
            SocialPlayerHurtWitnesses = p:Get("Social.PlayerHurtWitnesses"),
            SemanticEngineEvents = p:Get("Semantic.EngineEvent"),
            SemanticNPCKills = p:Get("Semantic.OnNPCKill"),
            SemanticHumanKills = p:Get("Semantic.OnNPCHumanKill"),
            ForEachLiveScans = p:Get("Registry.ForEachLive"),
            MaxFrameForEachLive = p:MaxFrame("Registry.ForEachLive"),
            MaxFrameBodyDamageUpdate = p:MaxFrame("Native.BodyDamage.Update"),
            MaxFrameStatsChange = p:MaxFrame("Native.SendPlayerStatsChange"),
            MaxFrameBroadcasts = p:MaxFrame("Network.BroadcastRecord"),
            MaxFrameDirtyMarks = p:MaxFrame("Registry.MarkDirty"),
            NetworkBroadcasts = p:Get("Network.BroadcastRecord"),
            NetworkRemovals = p:Get("Network.BroadcastRemoval"),
            DirtyMarks = p:Get("Registry.MarkDirty"),
            ImpactCpu = Probe.Percentiles(state.impactCpuSamples),
            Tick = Probe.Percentiles(state.tickSamples),
            Counters = p.totals,
        }
    end

    return wl
end

function Combat.Format(r)
    return string.format(
        "%s n=%d sync=%s wit=%d hits=%d miss=%d kills=%d zHit=%d zAgg=%d zNet=%d npcW=%d npcMed=%d pBD=%d pStat=%d fac=%d soc=%d witScan=%d sem=%d liveScan=%d maxFrLive=%d net=%d dirty=%d impAvg=%.3f impP95=%.3f impMax=%.3f tickMax=%.3f",
        r.Scenario, r.Attackers, r.Synchronized and "Y" or "N", r.Witnesses,
        r.HitsApplied, r.MissesExecuted, r.KillsObserved,
        r.NativeZombieHit, r.ZombieAggroProvoked, r.ZombieReactionBroadcast,
        r.NPCWoundsApply, r.NPCMedicalRequest,
        r.PlayerBodyDamageUpdate, r.PlayerStatsChange,
        r.FactionNPCAggression + r.FactionAttackedPlayer,
        r.SocialEncounterActivity + r.SocialNPCDamagedNPC + r.SocialNPCDamagedPlayer,
        r.SocialPlayerHurtWitnesses,
        r.SemanticEngineEvents + r.SemanticNPCKills + r.SemanticHumanKills,
        r.ForEachLiveScans, r.MaxFrameForEachLive,
        r.NetworkBroadcasts, r.DirtyMarks,
        r.ImpactCpu.avg, r.ImpactCpu.p95, r.ImpactCpu.max, r.Tick.max)
end

return Combat
