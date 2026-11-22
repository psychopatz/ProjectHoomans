local T = require "tests/support/test"

T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeHours = function() return 100 end,
    }
end

local nowMs = 10000
local deliveredBarks = {}
local busEvents = {}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = {
    AllowsServerCode = function() return true end,
}
PsychopatzCore.ShockingEventBus = {
    Emit = function(ev)
        busEvents[#busEvents + 1] = ev
        return true, "emitted"
    end,
}

PNC = PNC or {}
PNC.Const = {
    ZOMBIE_TARGET_RADIUS = 16,
    ALLY_WARNING_RADIUS = 16,
    ATTACK_TYPE_NONE = "none",
    ATTACK_TYPE_AUTO = "auto",
    TACTICAL_CLASS_HOSTILE = "hostile",
    PRESENCE_LIVE = "live",
    ORDER_FOLLOW = "follow",
}

local playerWorldObj = {
    _x = 12, _y = 10, _z = 0, _alive = true,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isAlive = function(self) return self._alive end,
    getOnlineID = function() return 77 end,
    getUsername = function() return "OwnerPlayer" end,
}

PNC.Core = {
    Now = function() return nowMs end,
    IsAuthority = function() return true end,
    IsClientOnly = function() return false end,
    DistanceSq = function(x1, y1, x2, y2)
        local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
        return dx * dx + dy * dy
    end,
    ForEachPlayer = function(cb) cb(playerWorldObj) end,
    ResolvePlayerByOnlineID = function(oid)
        if tostring(oid) == "77" then return playerWorldObj end
        return nil
    end,
    ResolvePlayerByUsername = function(u)
        if tostring(u) == "OwnerPlayer" then return playerWorldObj end
        return nil
    end,
}

PNC.EntityRef = {
    ForNPC = function(id) return "npc:" .. tostring(id) end,
}

PNC.Network = {
    SendConversationRelationshipForNPC = function(player, npcId, eventType, payload)
        deliveredBarks[#deliveredBarks + 1] = {
            npcId = tostring(npcId),
            eventType = tostring(eventType),
            text = payload and payload.ambientFlavor and payload.ambientFlavor.text or nil,
            at = nowMs,
        }
        return true
    end,
}

local npcStore = {}
local liveBodies = {}
PNC.Registry = {
    Data = npcStore,
    Get = function(id) return npcStore[tostring(id)] end,
    GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
}

PNC.SpatialIndex = {
    QueryNPCs = function()
        local out = {}
        for _, rec in pairs(npcStore) do out[#out + 1] = rec end
        return out
    end,
}

local alliedFactions = { ["alpha:bravo"] = true, ["bravo:alpha"] = true }
local hostileFactions = { ["alpha:raiders"] = true, ["raiders:alpha"] = true, ["survivors:raiders"] = true, ["raiders:survivors"] = true }
PNC.Factions = {
    GetFactionID = function(rec)
        return rec and (rec.factionID or (rec.affiliation and rec.affiliation.factionID)) or nil
    end,
    AreAllied = function(f1, f2)
        if f1 == f2 then return true end
        return alliedFactions[tostring(f1) .. ":" .. tostring(f2)] == true
    end,
    CanNPCTargetPlayer = function(rec)
        return rec and (rec.factionID == "raiders" or rec.tacticalClass == "hostile") or false
    end,
}

PNC.Relationships = {
    Get = function(observerId, targetKey)
        local rec = npcStore[tostring(observerId)]
        local rels = rec and rec.social and rec.social.relationships or nil
        return type(rels) == "table" and rels[targetKey] or nil
    end,
    AreNPCsEnemies = function(a, b, opts)
        if not a or not b then return false end
        if a.attackType == "none" and not (opts and opts.ignoreAttackNPCPolicy) then return false end
        local fa = PNC.Factions.GetFactionID(a)
        local fb = PNC.Factions.GetFactionID(b)
        if fa and fb and hostileFactions[tostring(fa) .. ":" .. tostring(fb)] then return true end
        local key = "npc:" .. tostring(b.id)
        local rel = a.social and a.social.relationships and a.social.relationships[key] or nil
        return type(rel) == "table" and (rel.state == "enemy" or rel.state == "rival")
    end,
}

PNC.SecondaryChannel = {
    alerts = {},
    gazes = {},
    barks = {},
    SetAlertLevel = function(rec, level)
        PNC.SecondaryChannel.alerts[tostring(rec.id)] = level
    end,
    RequestGaze = function(rec, tx, ty, dur, at)
        PNC.SecondaryChannel.gazes[tostring(rec.id)] = { tx = tx, ty = ty, dur = dur, at = at }
    end,
    ApplyGazeToBody = function() end,
    RequestBark = function(rec, barkId, at)
        PNC.SecondaryChannel.barks[#PNC.SecondaryChannel.barks + 1] = {
            npcId = tostring(rec.id), barkId = barkId, at = at,
        }
    end,
}

PNC.PerceptionService = {
    clues = {},
    GetProfile = function(rec)
        return { id = rec.tacticalRole or "default", hearingRange = rec.hearingRange or 34, tactical = rec.tactical == true }
    end,
    RecordClue = function(rec, clue, at)
        PNC.PerceptionService.clues[tostring(rec.id)] = clue
    end,
}

-- Load ConvoEngine catalog, Compatibility API, Perception AllyThreat stack, and Callouts.
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_API.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/Visibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatEligibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatTargets.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatAlert.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatPublish.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_Targeting.lua")

local losAllowed = true
PNC.Perception.CanSeeWorldObject = function()
    return losAllowed == true, losAllowed and "los_clear" or "blocked"
end

local zombieWorld = {
    _x = 18, _y = 10, _z = 0, _dead = false,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    isAlive = function(self) return not self._dead end,
}
PNC.Perception.FindZombieByID = function(zid)
    if tostring(zid) == "z-101" then return zombieWorld end
    return nil
end

local Callouts = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua")

local function makeNPC(id, opts)
    opts = opts or {}
    local rec = {
        id = id,
        name = "NPC_" .. tostring(id),
        x = opts.x or 10,
        y = opts.y or 10,
        z = opts.z or 0,
        alive = opts.alive ~= false,
        presenceState = opts.presenceState or "live",
        factionID = opts.factionID,
        ownerOnlineID = opts.ownerOnlineID,
        ownerUsername = opts.ownerUsername,
        attackType = opts.attackType or "auto",
        tacticalClass = opts.tacticalClass,
        tactical = opts.tactical,
        hearingRange = opts.hearingRange,
        social = opts.social or { relationships = {} },
        runtime = opts.runtime or {},
    }
    npcStore[tostring(id)] = rec
    liveBodies[tostring(id)] = {
        getX = function() return rec.x end,
        getY = function() return rec.y end,
        getZ = function() return rec.z end,
        isDead = function() return rec.alive == false end,
        isAlive = function() return rec.alive ~= false end,
    }
    return rec
end

-- 1. Verify all 5 ally eligibility tiers + exclusions.
do
    PNC.Perception.ResetAllyThreatWarnings()
    local callerOwner = makeNPC("c-owner", { x = 10, y = 10, ownerOnlineID = 77 })
    local allyOwner = makeNPC("a-owner", { x = 12, y = 10, ownerOnlineID = 77 })
    T.equal(select(2, PNC.Perception.AreWarningAllies(callerOwner, allyOwner)), "same_owner", "tier 1 same_owner")

    local callerFac = makeNPC("c-fac", { x = 10, y = 10, factionID = "alpha" })
    local allySameFac = makeNPC("a-same-fac", { x = 12, y = 10, factionID = "alpha" })
    local allyAlliedFac = makeNPC("a-allied-fac", { x = 13, y = 10, factionID = "bravo" })
    local enemyFac = makeNPC("e-raider", { x = 11, y = 10, factionID = "raiders" })
    local diffFloor = makeNPC("a-floor1", { x = 11, y = 10, z = 1, factionID = "alpha" })
    local neutral = makeNPC("n-stranger", { x = 11, y = 10 })

    T.equal(select(2, PNC.Perception.AreWarningAllies(callerFac, allySameFac)), "same_faction", "tier 2 same_faction")
    T.equal(select(2, PNC.Perception.AreWarningAllies(callerFac, allyAlliedFac)), "allied_faction", "tier 3 allied_faction")
    T.falsy(PNC.Perception.AreWarningAllies(callerFac, enemyFac), "must exclude enemy faction")
    T.falsy(PNC.Perception.AreWarningAllies(callerFac, diffFloor), "must exclude different floor")
    T.falsy(PNC.Perception.AreWarningAllies(callerFac, neutral), "must exclude neutral stranger")

    callerFac.social.relationships["npc:a-friend"] = { state = "friend" }
    local allyFriend = makeNPC("a-friend", { x = 12, y = 10 })
    T.equal(select(2, PNC.Perception.AreWarningAllies(callerFac, allyFriend)), "personal_friend", "tier 4 personal_friend")

    local packCaller = makeNPC("p-1", { x = 10, y = 10, tacticalClass = "hostile" })
    local packAlly = makeNPC("p-2", { x = 18, y = 10, tacticalClass = "hostile" })
    local okPack, relPack, radPack = PNC.Perception.AreWarningAllies(packCaller, packAlly)
    T.truthy(okPack, "tier 5 hostile_pack must match")
    T.equal(relPack, "hostile_pack", "relation kind must be hostile_pack")
    T.equal(radPack, 12.0, "hostile_pack radius capped at 12m")
end

-- 2. Verify max 8 cap, cooldowns, cone swing, clue memory, LOS gate, and hopDepth == 0.
do
    npcStore, liveBodies, busEvents = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()

    local caller = makeNPC("c1", { x = 10, y = 10, factionID = "survivors", tactical = true })
    local allies = {}
    for i = 1, 10 do
        allies[i] = makeNPC("s" .. tostring(i), {
            x = 10 + i, y = 10, factionID = "survivors",
            runtime = { facingDirX = -1, facingDirY = 0 },
        })
    end
    local farClamped = makeNPC("s-ear-clamped", { x = 18, y = 10, factionID = "survivors", hearingRange = 4.0 })
    local passiveAlly = makeNPC("s-passive", { x = 10.5, y = 10, factionID = "survivors", attackType = "none" })

    local threat = { kind = "zombie", zombieId = "z-101", x = 22, y = 10, z = 0 }
    local res = PNC.Perception.PublishAllyThreatWarning(caller, threat, { at = nowMs })
    T.truthy(res.emitted, "warning must emit to nearby faction allies")
    T.equal(#res.notified, 8, "notified allies must be capped at MAX_WARN_ALLIES=8")
    T.falsy(farClamped.runtime.allyThreatAlert, "hearingRange clamp must exclude ally beyond earshot")
    T.equal(passiveAlly.runtime.allyThreatAlert.canEngage, false, "passive ally receives warning with canEngage=false")

    -- Verify gaze swing + clue memory + LOS wall gate.
    local turned = allies[1]
    T.truthy(turned.runtime.facingDirX > 0.9, "warned ally must turn facingDir toward threat")
    T.truthy(PNC.SecondaryChannel.gazes["s1"] ~= nil, "warned ally must request SecondaryChannel gaze")
    T.truthy(PNC.PerceptionService.clues["s1"] ~= nil, "warned ally must record ClueMemory")
    T.truthy(PNC.Perception.IsWarnedThreat(turned, "zombie", "z-101", nil, nowMs),
        "IsWarnedThreat must allow vision cone bypass ONLY for warned threat")

    losAllowed = false
    local blockedTarget = PNC.Perception.FindAllyThreatAlert(turned, 16)
    T.falsy(blockedTarget, "wall/LOS block must prevent engagement despite warning cone bypass")

    nowMs = nowMs + 300
    losAllowed = true
    local acquiredTarget = PNC.Perception.FindAllyThreatAlert(turned, 16)
    T.truthy(acquiredTarget and acquiredTarget.viaAllyWarning == true,
        "once LOS clears, FindAllyThreatAlert must acquire warned threat")

    -- Anti-cascade hopDepth == 0.
    local cascade = PNC.Perception.PublishAllyThreatWarning(turned, acquiredTarget, { at = nowMs })
    T.falsy(cascade.emitted, "hopDepth == 0 must block re-broadcasting viaAllyWarning targets")
    T.equal(cascade.reason, "hop_limit", "cascade rejection reason must be hop_limit")
    T.equal(PNC.Perception.AllyWarningStats.hopBlocked, 1, "hopBlocked telemetry must increment")

    -- Caller cooldown & team threat dedup using separate eviction queues.
    local repeatCaller = PNC.Perception.PublishAllyThreatWarning(caller, { kind = "zombie", zombieId = "z-other", x = 20, y = 10, z = 0 }, { at = nowMs })
    T.falsy(repeatCaller.emitted, "caller cooldown must throttle immediate second warning")
    local repeatTeam = PNC.Perception.PublishAllyThreatWarning(allies[2], threat, { at = nowMs })
    T.falsy(repeatTeam.emitted, "team-threat dedup must throttle duplicate warning from teammate")
end

-- 3. Verify all 4 target kinds (zombie, npc, player, foreign_npc) + Compatibility cone filter.
do
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    nowMs = 30000

    local modHostileBody = {
        _x = 18, _y = 10, _z = 0, _dead = false,
        getX = function(self) return self._x end,
        getY = function(self) return self._y end,
        getZ = function(self) return self._z end,
        isDead = function(self) return self._dead end,
        isAlive = function(self) return not self._dead end,
    }
    PNC.PerceptionService.PassesBodyVisionCone = function(source, targetObj, _profile, _observer, opts)
        if opts and opts.bypassCone == true then return true end
        local rt = source and source.runtime or {}
        local fx, fy = tonumber(rt.facingDirX) or 1, tonumber(rt.facingDirY) or 0
        local tx = (targetObj and targetObj.getX and targetObj:getX()) or 0
        local ty = (targetObj and targetObj.getY and targetObj:getY()) or 0
        return (fx * (tx - (source.x or 0)) + fy * (ty - (source.y or 0))) >= 0
    end

    PNC.Compatibility.API.RegisterAdapter({
        id = "mock_mod",
        capabilities = { targeting = true, relationships = true },
        enumerateTargets = function()
            return {
                {
                    kind = "foreign_npc",
                    provider = "mock_mod",
                    actorId = "f-1",
                    generation = 1,
                    worldObject = modHostileBody,
                    x = 18, y = 10, z = 0,
                    distSq = 64,
                    threatClass = "human_hostile",
                },
            }
        end,
        canAttack = function(ctx)
            local rec = ctx and ctx.attacker
            return rec and rec.factionID == "survivors"
        end,
        resolveTarget = function(ctx)
            local ref = ctx and ctx.ref
            if ref and tostring(ref.actorId or "") == "f-1" then
                return {
                    kind = "foreign_npc",
                    provider = "mock_mod",
                    actorId = "f-1",
                    generation = 1,
                    worldObject = modHostileBody,
                    threatClass = "human_hostile",
                }
            end
            return nil
        end,
    })

    local spotter = makeNPC("spotter", { x = 10, y = 10, factionID = "survivors", tactical = true })
    -- Ally facing away (-1, 0) initially fails cone filter on mock foreign_npc!
    local guard = makeNPC("guard", {
        x = 10, y = 11, factionID = "survivors", tactical = true,
        runtime = { facingDirX = -1, facingDirY = 0 },
    })
    local preWarned = PNC.Compatibility.Targeting.FindNearestEnemy(guard, 20)
    T.falsy(preWarned, "foreign_npc behind NPC cone must be hidden before warning")

    local passiveBuddy = makeNPC("passive-buddy", { x = 10, y = 12, factionID = "survivors", attackType = "none" })

    -- Spotter warns team via unified CombatTargetCallouts against foreign_npc!
    local ok, callRes = Callouts.OnTargetChanged({
        target = { kind = "foreign_npc", provider = "mock_mod", actorId = "f-1", x = 18, y = 10, z = 0 },
        at = nowMs,
    }, spotter)
    T.truthy(ok and callRes.warning and callRes.warning.emitted, "OnTargetChanged must trigger unified warning for foreign_npc")
    T.truthy(#deliveredBarks >= 1, "callout bark must be delivered")
    T.truthy(Callouts.PendingReplyCount >= 1, "staggered ally replies must be queued")

    local postWarned = PNC.Compatibility.Targeting.FindNearestEnemy(guard, 20)
    T.truthy(postWarned ~= nil and tostring(postWarned.actorId) == "f-1",
        "warned foreign_npc must pass Compatibility_Targeting once alerted")

    -- Before dueAt: pump should not fire yet.
    local early = Callouts.PumpPendingReplies(nowMs + 200)
    T.equal(early, 0, "staggered replies must not fire before dueAt")

    -- After 1500ms: staggered replies fire through ConvoEngine & arbiter.
    nowMs = nowMs + 1500
    local fired = Callouts.PumpPendingReplies(nowMs)
    T.truthy(fired >= 1, "staggered ally replies must fire after dueAt")
    T.equal(Callouts.PendingReplyCount, 0, "PendingReplyCount must reset to zero after pumping")
    T.truthy(deliveredBarks[#deliveredBarks].text and #deliveredBarks[#deliveredBarks].text > 0,
        "ally reply bark must resolve real ConvoEngine localized text")

    -- Hostile faction warns hostile peers against player!
    local bandit1 = makeNPC("bandit-1", { x = 10, y = 10, factionID = "raiders", runtime = { attackPlayers = true } })
    local bandit2 = makeNPC("bandit-2", { x = 11, y = 10, factionID = "raiders" })
    local hostileWarn = PNC.Perception.PublishAllyThreatWarning(bandit1, {
        kind = "player", onlineID = 77, x = 12, y = 10, z = 0,
    }, { at = nowMs, ignoreCooldown = true })
    T.truthy(hostileWarn.emitted, "hostile faction must warn its teammates against player")
    T.equal(hostileWarn.notified[1].canEngage, true, "hostile teammate must be allowed to engage player")
    -- Owner companion will NOT engage owner even if warned.
    local ownerNpc = makeNPC("comp-owner", { x = 10, y = 10, ownerOnlineID = 77 })
    local canEngageOwner, _, reasonOwner = PNC.Perception.CanAllyEngageThreat(ownerNpc, hostileWarn.descriptor)
    T.falsy(canEngageOwner, "companion must refuse to engage its own player owner")
    T.equal(reasonOwner, "cannot_attack_owner")
end

-- 4. Verify ShockingReactionTaskProvider WarnGroup reuses PublishAllyThreatWarning cleanly.
do
    npcStore, liveBodies = {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    nowMs = 50000
    PNC.Core.RegisterModule = function() end
    PNC.Tasking = PNC.Tasking or {}
    local shockProvider = T.load("ProjectHoomans", "server", "PNC/Tasking/Reactions/PNC_ShockingReactionTaskProvider.lua")
    local sCaller = makeNPC("shock-caller", {
        x = 10, y = 10, factionID = "alpha",
        runtime = {
            reactionState = {
                intent = "WarnGroup",
                expiresAt = nowMs + 5000,
                targetX = 18, targetY = 10, targetZ = 0,
            },
        },
    })
    local sAlly = makeNPC("shock-ally", { x = 12, y = 10, factionID = "alpha" })
    shockProvider.ActiveByLease["lease-1"] = {
        event = { sourceId = "z-101", sourceKind = "zombie" },
    }
    shockProvider.Tick({ leaseId = "lease-1", npcId = "shock-caller" })
    T.truthy(sAlly.runtime.allyThreatAlert ~= nil, "WarnGroup must populate unified allyThreatAlert")
    T.equal(sAlly.runtime.allyThreatAlert.kind, "zombie", "WarnGroup must forward normalized zombie target")
end

T.finish("pnc_ally_threat_warning_smoke")
