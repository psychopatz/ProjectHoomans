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

-- Load ConvoEngine catalog, SpatialRelation, Compatibility API, Perception AllyThreat stack, and Callouts.
T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Compatibility/PNC_Compatibility_API.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/Visibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatEligibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatMeta.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatSkirmish.lua")
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
        getForwardDirection = function()
            local rt = rec.runtime or {}
            return {
                getX = function() return tonumber(rt.facingDirX) or 1 end,
                getY = function() return tonumber(rt.facingDirY) or 0 end,
            }
        end,
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

-- 5. Verify rich contextual callouts and replies (target names, counts/types, locations, defensive, rotation, 3-beat squad).
do
    local function assertNoRawTokens(text, label)
        T.truthy(type(text) == "string" and text ~= "", label .. ": empty text")
        if string.find(text, "{", 1, true) or string.find(text, "}", 1, true) then
            error(label .. ": unresolved token in: " .. tostring(text))
        end
    end
    local function assertNoLLMHyphens(text, label)
        if string.find(text, "\226\128\148", 1, true)
            or string.find(text, "\226\128\147", 1, true)
            or string.find(text, " - ", 1, true)
        then
            error(label .. ": LLM dash/hyphen found in: " .. tostring(text))
        end
    end

    -- 5a. Named hostile NPC ("Marcus") inside named room ("kitchen") with engaging + defensive allies.
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    PNC.ConvoEngine.SpeechRealization.ResetSelections()
    Callouts.ResetRuntime()
    nowMs = 70000

    local sammie = makeNPC("sammie", { x = 10, y = 10, factionID = "survivors", tactical = true })
    sammie.name = "Sammie"
    local adrienne = makeNPC("adrienne", { x = 11, y = 10, factionID = "survivors", tactical = true })
    adrienne.name = "Adrienne"
    local pete = makeNPC("pete", { x = 12, y = 10, factionID = "survivors", attackType = "none" })
    pete.name = "Pete"
    local marcus = makeNPC("marcus", { x = 14, y = 10, factionID = "raiders" })
    marcus.name = "Marcus"

    local ok, _ = Callouts.OnTargetChanged({
        target = { kind = "npc", id = "marcus", x = 14, y = 10, z = 0, roomName = "kitchen" },
        at = nowMs,
    }, sammie)
    T.truthy(ok, "named hostile NPC warning must emit")
    T.equal(#deliveredBarks, 1, "caller bark must deliver immediately")
    local calloutText = deliveredBarks[1].text
    assertNoRawTokens(calloutText, "5a callout")
    assertNoLLMHyphens(calloutText, "5a callout")
    T.contains(calloutText, "Marcus", "callout must name target Marcus")
    T.contains(calloutText, "in the kitchen", "callout must name kitchen location")

    nowMs = nowMs + 1500
    local fired = Callouts.PumpPendingReplies(nowMs)
    T.equal(fired, 2, "both Adrienne (engaging) and Pete (defensive) must reply")
    T.equal(#deliveredBarks, 3, "two reply barks must deliver")
    assertNoRawTokens(deliveredBarks[2].text, "5a engaging reply")
    assertNoLLMHyphens(deliveredBarks[2].text, "5a engaging reply")
    assertNoRawTokens(deliveredBarks[3].text, "5a defensive reply")
    assertNoLLMHyphens(deliveredBarks[3].text, "5a defensive reply")
    T.contains(deliveredBarks[2].text, "Sammie", "engaging reply must address caller Sammie")
    T.contains(deliveredBarks[2].text, "Marcus", "engaging reply must name Marcus")
    T.contains(deliveredBarks[2].text, "in the kitchen", "engaging reply must name kitchen")
    T.contains(deliveredBarks[3].text, "Sammie", "defensive reply must address caller Sammie")
    T.contains(deliveredBarks[3].text, "Marcus", "defensive reply must name Marcus")
    T.equal(deliveredBarks[3].eventType, "combat_ally_warn_reply_defensive",
        "passive ally must use defensive reply type")

    -- 5b. Multiple zombies (count = 4 from cached perceptionFrame) with tactical bearing.
    deliveredBarks = {}
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    nowMs = 85000

    local zNear = function(zx, zy)
        return { getX = function() return zx end, getY = function() return zy end, isDead = function() return false end }
    end
    local tacticalSpotter = makeNPC("tact-1", {
        x = 10, y = 10, factionID = "survivors", tactical = true,
        runtime = {
            facingDirX = 1, facingDirY = 0,
            perceptionFrame = {
                entries = {
                    { zombie = zombieWorld },
                    { zombie = zNear(18.5, 10) },
                    { zombie = zNear(19, 11) },
                    { zombie = zNear(17.5, 9) },
                },
            },
        },
    })
    tacticalSpotter.name = "Clay"
    local tacticalAlly = makeNPC("tact-2", {
        x = 10, y = 11, factionID = "survivors", tactical = true,
        runtime = { facingDirX = 1, facingDirY = 0 },
    })
    tacticalAlly.name = "Adrienne"

    local okZ, _ = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 },
        at = nowMs,
        ignoreWarningCooldown = true,
    }, tacticalSpotter)
    T.truthy(okZ, "multi-zombie warning must emit")
    assertNoRawTokens(deliveredBarks[1].text, "5b zombie callout")
    assertNoLLMHyphens(deliveredBarks[1].text, "5b zombie callout")
    T.contains(deliveredBarks[1].text, "a few walkers", "callout must use natural few-walkers phrasing")
    T.contains(deliveredBarks[1].text, "o'clock", "tactical callout must include clock bearing")

    nowMs = nowMs + 1500
    Callouts.PumpPendingReplies(nowMs)
    T.truthy(#deliveredBarks >= 2, "tactical ally reply must deliver")
    assertNoRawTokens(deliveredBarks[2].text, "5b zombie reply")
    assertNoLLMHyphens(deliveredBarks[2].text, "5b zombie reply")
    T.contains(deliveredBarks[2].text, "Clay", "reply must address caller Clay")
    T.contains(deliveredBarks[2].text, "a few walkers", "reply must repeat natural enemy phrasing")

    -- 5c. Modded foreign_npc group (bandits x2) + ConvoEngine variant rotation across waves.
    deliveredBarks = {}
    PNC.Compatibility.API.RegisterAdapter({
        id = "bandits",
        capabilities = { targeting = true, relationships = true },
        canAttack = function() return true end,
        resolveTarget = function(ctx)
            local ref = ctx and ctx.ref
            if ref and tostring(ref.actorId or "") == "b-99" then
                return {
                    kind = "foreign_npc", provider = "bandits", actorId = "b-99",
                    displayName = "Viper", factionName = "Marauders",
                    worldObject = zombieWorld, threatClass = "human_hostile",
                }
            end
            return nil
        end,
    })
    nowMs = 100000
    Callouts.OnTargetChanged({
        target = {
            kind = "foreign_npc", provider = "bandits", actorId = "b-99",
            x = 18, y = 10, z = 0, enemyCount = 2,
        },
        at = nowMs, ignoreWarningCooldown = true,
    }, tacticalSpotter)
    local bText1 = deliveredBarks[#deliveredBarks].text
    assertNoRawTokens(bText1, "5c foreign_npc callout 1")
    assertNoLLMHyphens(bText1, "5c foreign_npc callout 1")
    T.contains(bText1, "Viper and their crew", "named multi-hostile foreign target must mention leader and crew")

    nowMs = 110000
    Callouts.OnTargetChanged({
        target = {
            kind = "foreign_npc", provider = "bandits", actorId = "b-88",
            worldObject = zombieWorld, x = 18, y = 10, z = 0, enemyCount = 2,
        },
        at = nowMs, ignoreWarningCooldown = true,
    }, tacticalSpotter)
    local bText2 = deliveredBarks[#deliveredBarks].text
    assertNoRawTokens(bText2, "5c foreign_npc callout 2")
    assertNoLLMHyphens(bText2, "5c foreign_npc callout 2")
    T.contains(bText2, "a couple of bandits", "unnamed bandit pair must mention couple of bandits")
    T.truthy(bText1 ~= bText2, "variant rotation must vary callout wording across events")

    -- 5d. 5-person squad coherent 3-beat reply chain (Spotter -> Lead -> Wingman -> Anchor), zero shock spam.
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    nowMs = 130000

    local sqSammie = makeNPC("sq-sammie", {
        x = 10, y = 10, factionID = "survivors", tactical = true,
        runtime = {
            facingDirX = 1, facingDirY = 0,
            perceptionFrame = {
                entries = {
                    { zombie = zombieWorld },
                    { zombie = zNear(18.5, 10) },
                    { zombie = zNear(19.0, 10.5) },
                },
            },
        },
    })
    sqSammie.name = "Sammie"
    local sqAdrienne = makeNPC("sq-adrienne", { x = 11, y = 10, factionID = "survivors", tactical = true })
    sqAdrienne.name = "Adrienne"
    local sqClay = makeNPC("sq-clay", { x = 12, y = 10, factionID = "survivors", tactical = true })
    sqClay.name = "Clay"
    local sqVonda = makeNPC("sq-vonda", { x = 13, y = 10, factionID = "survivors", tactical = true })
    sqVonda.name = "Vonda"
    local sqDante = makeNPC("sq-dante", { x = 14, y = 10, factionID = "survivors", tactical = true })
    sqDante.name = "Dante"

    local okSq, resSq = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 },
        at = nowMs, ignoreWarningCooldown = true,
    }, sqSammie)
    T.truthy(okSq and resSq and resSq.warning and #resSq.warning.notified == 4, "all 4 nearby squadmates must be alerted")
    T.truthy(sqDante.runtime.allyThreatAlert ~= nil, "4th ally Dante still receives tactical threat alert")
    T.equal(Callouts.PendingReplyCount, 3, "only 3 allies may queue speech replies")
    T.truthy(Callouts.NextReplyDueAt ~= nil, "NextReplyDueAt must be armed after enqueue")
    T.equal(Callouts.PumpPendingReplies(nowMs + 100), 0, "PumpPendingReplies must fast-exit before NextReplyDueAt")

    assertNoRawTokens(deliveredBarks[1].text, "5d callout")
    assertNoLLMHyphens(deliveredBarks[1].text, "5d callout")

    nowMs = nowMs + 800
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "Beat 1 Lead reply must fire at +800ms")
    T.equal(deliveredBarks[2].npcId, "sq-adrienne", "Beat 1 must come from closest Lead ally Adrienne")
    assertNoRawTokens(deliveredBarks[2].text, "5d beat1 lead")
    assertNoLLMHyphens(deliveredBarks[2].text, "5d beat1 lead")
    T.contains(deliveredBarks[2].text, "Sammie", "Beat 1 Lead must address spotter Sammie")
    T.contains(deliveredBarks[2].text, "a few walkers", "Beat 1 Lead must use natural few-walkers phrasing")
    T.contains(deliveredBarks[2].text, "o'clock", "Beat 1 Lead must include location")

    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "Beat 2 Wingman reply must fire at +1500ms")
    T.equal(deliveredBarks[3].npcId, "sq-clay", "Beat 2 must come from second ally Clay")
    assertNoRawTokens(deliveredBarks[3].text, "5d beat2 wingman")
    assertNoLLMHyphens(deliveredBarks[3].text, "5d beat2 wingman")
    T.contains(deliveredBarks[3].text, "Adrienne", "Beat 2 Wingman must chain directly off Lead Adrienne")
    T.contains(deliveredBarks[3].text, "a few walkers", "Beat 2 Wingman must reference natural threat phrasing")

    nowMs = nowMs + 800
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "Beat 3 Anchor reply must fire at +2300ms")
    T.equal(deliveredBarks[4].npcId, "sq-vonda", "Beat 3 must come from third ally Vonda")
    assertNoRawTokens(deliveredBarks[4].text, "5d beat3 anchor")
    assertNoLLMHyphens(deliveredBarks[4].text, "5d beat3 anchor")
    T.contains(deliveredBarks[4].text, "Clay", "Beat 3 Anchor must close the beat addressing Clay")
    T.equal(#deliveredBarks, 4, "5-person squad must stay capped at 1 callout + 3 coherent replies")
    T.equal(Callouts.PendingReplyCount, 0, "PendingReplyCount must drain to 0")
    T.equal(Callouts.NextReplyDueAt, nil, "NextReplyDueAt must clear when queue drains")

    if PNC.ShockingReactionTaskProvider and PNC.ShockingReactionTaskProvider.HandleShockingEvent then
        T.equal(PNC.ShockingReactionTaskProvider.HandleShockingEvent({
            eventType = "shock.ally_threat_warning", x = 10, y = 10, z = 0, radius = 16,
        }), 0, "ShockingReactionTaskProvider must skip duplicate shock.ally_threat_warning fanout")
    end

    -- 5e. Mid-fight target switching (already-aware squad + active skirmish) produces zero countdown spam.
    deliveredBarks = {}
    sqAdrienne.runtime.target = { kind = "zombie", zombieId = "z-101" }
    sqClay.runtime.target = { kind = "zombie", zombieId = "z-101" }
    sqVonda.runtime.target = { kind = "zombie", zombieId = "z-101" }
    sqDante.runtime.target = { kind = "zombie", zombieId = "z-101" }
    sqSammie.runtime.perceptionFrame.entries = {
        { zombie = zombieWorld },
        { zombie = zNear(18.5, 10) },
    }
    nowMs = nowMs + 2000
    local okSw, reasonSw = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-102", x = 18.5, y = 10, z = 0 },
        at = nowMs,
    }, sqSammie)
    T.falsy(okSw, "mid-fight switch within active skirmish must not emit countdown callout")
    T.equal(reasonSw, "skirmish_already_active", "mid-fight switch must return skirmish_already_active")
    T.equal(#deliveredBarks, 0, "zero barks allowed when teammates are already fighting same skirmish")

    -- Verify 2-walker phrasing produces "a couple of stragglers" when a fresh skirmish starts with 2 normal walkers.
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    sqAdrienne.runtime.target = nil
    sqClay.runtime.target = nil
    nowMs = nowMs + 20000
    local okPair = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 },
        at = nowMs, ignoreWarningCooldown = true,
    }, sqSammie)
    T.truthy(okPair, "2-zombie warning must emit")
    assertNoRawTokens(deliveredBarks[#deliveredBarks].text, "5e couple stragglers")
    assertNoLLMHyphens(deliveredBarks[#deliveredBarks].text, "5e couple stragglers")
    T.contains(deliveredBarks[#deliveredBarks].text, "a couple of stragglers", "2 walkers must say a couple of stragglers")

    -- 5f. Crawler posture detection, blindside save warning, and Last Straggler beat.
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    nowMs = 170000

    local crawlSammie = makeNPC("cr-sammie", {
        x = 10, y = 10, factionID = "survivors", tactical = true,
        runtime = { facingDirX = 1, facingDirY = 0, perceptionFrame = { entries = {
            { zombie = zombieWorld }, { zombie = zNear(18.5, 10) }, { zombie = zNear(19, 10.5) },
        } } },
    })
    crawlSammie.name = "Sammie"
    local crawlClay = makeNPC("cr-clay", { x = 12, y = 10, factionID = "survivors", tactical = true })
    crawlClay.name = "Clay"
    local origZ = zombieWorld.isCrawling
    zombieWorld.isCrawling = function() return true end
    local okCr = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-101", x = 18, y = 10, z = 0 },
        at = nowMs,
    }, crawlSammie)
    zombieWorld.isCrawling = origZ
    T.truthy(okCr, "crawler warning must emit")
    assertNoRawTokens(deliveredBarks[1].text, "5f crawler")
    assertNoLLMHyphens(deliveredBarks[1].text, "5f crawler")
    T.contains(deliveredBarks[1].text, "crawler", "crawling zombie target must mention crawler")

    -- Blindside save inside active skirmish (enemy at x=10.5, y=10 behind Clay facing east at x=12, y=10).
    deliveredBarks = {}
    Callouts.ResetRuntime()
    crawlClay.runtime.target = { kind = "zombie", zombieId = "z-101" }
    crawlClay.runtime.facingDirX, crawlClay.runtime.facingDirY = 1, 0
    nowMs = nowMs + 7000
    local okBl, reasonBl = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-behind", x = 10.5, y = 10, z = 0 },
        at = nowMs,
    }, crawlSammie)
    T.truthy(okBl, "blindside threat behind ally cone must emit warning")
    T.equal(reasonBl, "blindside_warning", "blindside save reason must be blindside_warning")
    assertNoRawTokens(deliveredBarks[1].text, "5f blindside callout")
    assertNoLLMHyphens(deliveredBarks[1].text, "5f blindside callout")
    T.contains(deliveredBarks[1].text, "Clay", "blindside callout must warn Clay directly")
    T.truthy(crawlClay.runtime.facingDirX < -0.5, "blindside warning must turn ally toward rear threat")

    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "blindsided ally must reply")
    assertNoRawTokens(deliveredBarks[2].text, "5f blindside reply")
    assertNoLLMHyphens(deliveredBarks[2].text, "5f blindside reply")
    T.contains(deliveredBarks[2].text, "Sammie", "blindside reply must thank Sammie")

    -- Last straggler beat when multi-enemy skirmish drops to 1 remaining walker.
    deliveredBarks = {}
    crawlSammie.runtime.perceptionFrame.entries = { { zombie = zNear(15, 10) } }
    nowMs = nowMs + 7000
    local okLast, reasonLast = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-last", x = 15, y = 10, z = 0 },
        at = nowMs,
    }, crawlSammie)
    T.truthy(okLast, "dropping to 1 remaining enemy from initialCount>=3 must emit last_straggler")
    T.equal(reasonLast, "last_straggler")
    assertNoRawTokens(deliveredBarks[1].text, "5f last_one callout")
    assertNoLLMHyphens(deliveredBarks[1].text, "5f last_one callout")
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "last straggler beat must trigger 1 ally reply")
    assertNoRawTokens(deliveredBarks[2].text, "5f last_one reply")
    assertNoLLMHyphens(deliveredBarks[2].text, "5f last_one reply")
    -- Repeating with 1 remaining enemy must NOT fire last_straggler twice.
    local okLastRep, rLastRep = Callouts.OnTargetChanged({
        target = { kind = "zombie", zombieId = "z-last", x = 15, y = 10, z = 0 },
        at = nowMs + 5000,
    }, crawlSammie)
    T.falsy(okLastRep)
    T.equal(rLastRep, "skirmish_already_active", "last_straggler must fire at most once per skirmish")

    -- 5g. Mid-fight bandaging cover callout + bandage-aware post-fight check-ins.
    local bandages = {}
    PNC.Treatment = {
        HasNPCBandage = function(rec) return bandages[tostring(rec and rec.id or "")] == true end,
    }
    -- Calm base: bandaging emits nothing.
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    PNC.Registry.Data = npcStore
    PNC.Perception.ResetAllyThreatWarnings()
    Callouts.ResetRuntime()
    nowMs = 220000
    local medSam = makeNPC("med-sam", { x = 10, y = 10, factionID = "survivors", tactical = true })
    medSam.name = "Sammie"
    local medAdri = makeNPC("med-adri", { x = 11, y = 10, factionID = "survivors", tactical = true })
    medAdri.name = "Adrienne"
    local medClay = makeNPC("med-clay", { x = 12, y = 10, factionID = "survivors", tactical = true })
    medClay.name = "Clay"
    T.falsy(Callouts.OnAllyBandagingUnderThreat(medSam, medSam, nowMs), "calm bandaging must not shout cover callout")
    T.equal(#deliveredBarks, 0)

    -- Under threat: bandaging self asks teammate to cover -> teammate replies.
    PNC.Perception.RecordSkirmishContact("faction:survivors", { x = 16, y = 10, z = 0, enemyCount = 3 }, nowMs, true)
    medAdri.runtime.target = { kind = "zombie", zombieId = "z-201" }
    T.truthy(Callouts.OnAllyBandagingUnderThreat(medSam, medSam, nowMs), "bandaging under threat must request cover")
    assertNoRawTokens(deliveredBarks[1].text, "5g bandaging_self")
    assertNoLLMHyphens(deliveredBarks[1].text, "5g bandaging_self")
    T.contains(deliveredBarks[1].text, "Adrienne", "bandaging cover request must address teammate")
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1)
    assertNoRawTokens(deliveredBarks[2].text, "5g cover_bandage")
    assertNoLLMHyphens(deliveredBarks[2].text, "5g cover_bandage")
    T.contains(deliveredBarks[2].text, "Sammie", "covering reply must reassure Sammie")

    -- Post-fight check-in subcase A: injured teammate HAS bandage.
    deliveredBarks = {}
    Callouts.ResetRuntime()
    medAdri.runtime.target = nil
    medSam.health = { bleeding = true, state = "injured" }
    bandages["med-sam"] = true
    nowMs = nowMs + 1000
    T.truthy(Callouts.OnTargetCleared(medAdri, { kind = "zombie", zombieId = "z-201" }, "no_target", nowMs),
        "clearing last target must start post-fight medical check-in")
    assertNoRawTokens(deliveredBarks[1].text, "5g checkin_injured")
    assertNoLLMHyphens(deliveredBarks[1].text, "5g checkin_injured")
    T.contains(deliveredBarks[1].text, "Sammie", "check-in must address injured Sammie")
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1)
    assertNoRawTokens(deliveredBarks[2].text, "5g injured_has_bandage")
    assertNoLLMHyphens(deliveredBarks[2].text, "5g injured_has_bandage")
    T.contains(string.lower(deliveredBarks[2].text), "bandage", "injured ally with bandage must confirm bandage")

    -- Post-fight check-in subcase B: injured has NO bandage, teammate DOES -> 3-beat offer.
    deliveredBarks = {}
    Callouts.ResetRuntime()
    nowMs = nowMs + 2000
    bandages["med-sam"] = false
    bandages["med-adri"] = true
    PNC.Perception.RecordSkirmishContact("faction:survivors", { x = 16, y = 10, z = 0, enemyCount = 2 }, nowMs, true)
    T.truthy(Callouts.OnTargetCleared(medAdri, { kind = "zombie", zombieId = "z-202" }, "no_target", nowMs))
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "injured without bandage replies")
    assertNoRawTokens(deliveredBarks[2].text, "5g injured_no_bandage")
    assertNoLLMHyphens(deliveredBarks[2].text, "5g injured_no_bandage")
    nowMs = nowMs + 900
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "teammate with bandage offers spare wrap")
    assertNoRawTokens(deliveredBarks[3].text, "5g medic_has_bandage")
    assertNoLLMHyphens(deliveredBarks[3].text, "5g medic_has_bandage")
    T.contains(deliveredBarks[3].text, "Sammie", "medic offer must address injured Sammie")

    -- Post-fight check-in subcase C: NOBODY has bandages -> scavenge/pressure line.
    deliveredBarks = {}
    Callouts.ResetRuntime()
    nowMs = nowMs + 2000
    bandages["med-sam"], bandages["med-adri"], bandages["med-clay"] = false, false, false
    PNC.Perception.RecordSkirmishContact("faction:survivors", { x = 16, y = 10, z = 0, enemyCount = 2 }, nowMs, true)
    T.truthy(Callouts.OnTargetCleared(medAdri, { kind = "zombie", zombieId = "z-203" }, "no_target", nowMs))
    nowMs = nowMs + 1600
    T.equal(Callouts.PumpPendingReplies(nowMs), 2)
    assertNoRawTokens(deliveredBarks[3].text, "5g medic_no_bandage")
    assertNoLLMHyphens(deliveredBarks[3].text, "5g medic_no_bandage")
    T.contains(deliveredBarks[3].text, "Sammie", "no-bandage follow-up must address injured Sammie")

    -- Post-fight check-in subcase D: everyone unhurt after 3+ enemies -> clean area check-in.
    deliveredBarks = {}
    Callouts.ResetRuntime()
    nowMs = nowMs + 2000
    medSam.health = { bleeding = false, state = "healthy" }
    PNC.Perception.RecordSkirmishContact("faction:survivors", { x = 16, y = 10, z = 0, enemyCount = 4 }, nowMs, true)
    T.truthy(Callouts.OnTargetCleared(medAdri, { kind = "zombie", zombieId = "z-204" }, "no_target", nowMs))
    assertNoRawTokens(deliveredBarks[1].text, "5g checkin_clear")
    assertNoLLMHyphens(deliveredBarks[1].text, "5g checkin_clear")
    nowMs = nowMs + 1500
    T.equal(Callouts.PumpPendingReplies(nowMs), 2, "unhurt team replies all clear")
    assertNoRawTokens(deliveredBarks[2].text, "5g checkin_ok_1")
    assertNoLLMHyphens(deliveredBarks[2].text, "5g checkin_ok_1")
    assertNoRawTokens(deliveredBarks[3].text, "5g checkin_ok_2")
    assertNoLLMHyphens(deliveredBarks[3].text, "5g checkin_ok_2")

    -- 5h. Lightweight transient bark fast-path skips full conversation assembly & relationship UI sync.
    local presCalls, relUiCalls, recvCalls, cmdHandlers = 0, 0, {}, {}
    local savedPNC = PNC
    PNC = {
        Const = { MODULE = "PNC", CMD_CONVERSATION_RELATIONSHIP = "ConvRel" },
        Core = { Now = function() return 300000 end },
        Registry = { Get = function(id) return { id = id, name = "Sammie" } end },
        RelationshipPresentation = {
            BuildForConversation = function() presCalls = presCalls + 1; return { npcID = "s1" } end,
        },
        Network = { ClientState = {} },
        Conversation = { Relationship = { ReceivePresentation = function() relUiCalls = relUiCalls + 1 end } },
        SemanticSpeechPresentation = {
            Receive = function(af, summary) recvCalls[#recvCalls + 1] = { af = af, summary = summary } end,
        },
        Client = {
            Internal = {
                RegisterServerCommand = function(cmd, fn) cmdHandlers[cmd] = fn end,
            },
        },
    }
    PNC.Network.SendConversationRelationship = function(_, summary, _, ctx)
        cmdHandlers[PNC.Const.CMD_CONVERSATION_RELATIONSHIP]({
            summary = summary, ambientFlavor = ctx and ctx.ambientFlavor,
        })
        return true
    end
    T.load("ProjectHoomans", "shared", "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Social.lua")
    T.load("ProjectHoomans", "client", "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_RelationshipResult.lua")
    local sentFast, _, stubSummary = PNC.Network.SendConversationRelationshipForNPC(
        playerWorldObj, "s1", "combat_ally_warn_callout",
        { lightweightBark = true, ambientFlavor = { observerOnly = true, text = "Test bark!" } }
    )
    PNC = savedPNC
    T.truthy(sentFast, "lightweightBark server helper must send cleanly")
    T.equal(stubSummary.lightweightBark, true, "server stub must carry lightweightBark flag")
    T.equal(presCalls, 0, "lightweightBark must skip Presentation.BuildForConversation")
    T.equal(relUiCalls, 0, "lightweightBark must skip client Relationship UI update")
    T.equal(#recvCalls, 1, "lightweightBark must route directly to SemanticSpeechPresentation.Receive")
end

T.finish("pnc_ally_threat_warning_smoke")
