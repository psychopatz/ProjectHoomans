local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeHours = function() return 42.5 end,
    }
end

local nowMs = 20000
local npcStore = {}
local deliveredBarks = {}
local resolvedRoles = {}
local enqueuedReplies = {}
local relationshipEffects = {}

local playerObj = {
    _x = 16, _y = 10, _z = 0, _dead = false, _attacking = false,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    isAttacking = function(self) return self._attacking end,
    isAiming = function() return false end,
    isDoShove = function() return false end,
    getUsername = function() return "OwnerPlayer" end,
    getDescriptor = function() return { getForename = function() return "Alex" end } end,
}

local function makeZombie(id, opts)
    opts = opts or {}
    local md = {
        PNC_ZombiePursuitTarget = opts.npcTarget,
        PNC_ZombiePursuitUntil = opts.untilMs or (nowMs + 5000),
        PNC_AggroNPCId = opts.forcedNpc,
        PNC_AggroNPCUntil = opts.forcedUntilMs or 0,
    }
    return {
        _id = id,
        _target = opts.playerTarget,
        _attackedBy = opts.attackedBy,
        _dead = opts.dead == true,
        isDead = function(self) return self._dead end,
        getTarget = function(self) return self._target end,
        getAttackedBy = function(self) return self._attackedBy end,
        getModData = function() return md end,
    }
end

local activeOrder = {}
local activeByID = {}
local function setActiveZombies(list)
    activeOrder = {}
    activeByID = {}
    for i = 1, #list do
        local z = list[i]
        activeOrder[i] = z._id
        activeByID[z._id] = { zombie = z }
    end
end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = {
    Const = {
        ZOMBIE_TARGET_RADIUS = 16,
        ALLY_WARNING_RADIUS = 16,
    },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(fn) fn(playerObj) end,
    },
    Store = {
        GetAll = function() return npcStore end,
    },
    Registry = {
        Data = npcStore,
    },
    Perception = {
        AreWarningAllies = function() return true end,
    },
    ZombieAggro = {
        ActiveSet = {
            order = activeOrder,
            byID = activeByID,
        },
        State = {
            bites = {},
        },
    },
    Relationships = {
        ApplyConversationEffect = function(npcId, relKey, payload, meta)
            relationshipEffects[#relationshipEffects + 1] = {
                npcId = npcId,
                relKey = relKey,
                payload = payload,
                meta = meta,
            }
            return true
        end,
    },
    Semantics = {},
}

local function syncActiveSet()
    PNC.ZombieAggro.ActiveSet.order = activeOrder
    PNC.ZombieAggro.ActiveSet.byID = activeByID
end

local S = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations"
local I = PNC.Semantics.CombatTargetCalloutsInternal

S.ResolveAllyWarnTone = function() return "shaken" end
S.BuildRichSpeechTokens = function(speaker, addr, desc)
    return {
        ["target.name"] = addr and (addr.displayName or addr.name) or "partner",
        ["enemy.count"] = tostring(desc and desc.enemyCount or 1),
    }
end
S.ResolveSemanticLine = function(speaker, family, act, tCls, ref, _, toks, extra)
    local role = extra and extra.replyRole or "default"
    resolvedRoles[#resolvedRoles + 1] = {
        speakerId = speaker.id,
        role = role,
        targetName = toks and toks["target.name"],
        swarmCount = toks and toks["swarm.count"],
    }
    return role .. " -> " .. tostring(toks and toks["target.name"] or "?"), {
        realizationID = "test." .. role,
        presentationClass = "BARK",
    }
end
S.DeliverBark = function(speaker, at, opts)
    deliveredBarks[#deliveredBarks + 1] = {
        speakerId = speaker.id,
        text = opts.text,
        interrupt = opts.interrupt,
        speechEventID = opts.speechEventID,
    }
    return 1
end
S.EnqueueCustomReply = function(spec)
    enqueuedReplies[#enqueuedReplies + 1] = spec
    return true
end

local johnny = {
    id = "npc_johnny",
    displayName = "Johnny",
    alive = true,
    x = 10, y = 10, z = 0,
    ownerUsername = "OwnerPlayer",
    health = { current = 80, max = 100 },
    runtime = {},
}
local emma = {
    id = "npc_emma",
    displayName = "Emma",
    alive = true,
    x = 13, y = 10, z = 0,
    ownerUsername = "OwnerPlayer",
    health = { current = 90, max = 100 },
    runtime = {},
}
local rod = {
    id = "npc_rod",
    displayName = "Rod",
    alive = true,
    x = 18, y = 10, z = 0,
    ownerUsername = "OwnerPlayer",
    health = { current = 95, max = 100 },
    runtime = {},
}
npcStore = {
    [johnny.id] = johnny,
    [emma.id] = emma,
    [rod.id] = rod,
}
PNC.Registry.Data = npcStore

-- 1) Johnny has 3 zombies, Emma has 2 zombies, Rod has 1 zombie, Player Alex has 0 zombies.
--    Even though Emma is closest (3 tiles), Alex has 0 threats so Alex MUST be chosen!
setActiveZombies({
    makeZombie(1, { npcTarget = johnny.id }),
    makeZombie(2, { npcTarget = johnny.id }),
    makeZombie(3, { npcTarget = johnny.id }),
    makeZombie(4, { npcTarget = emma.id }),
    makeZombie(5, { npcTarget = emma.id }),
    makeZombie(6, { npcTarget = rod.id }),
})
syncActiveSet()

local function assertEq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", tostring(msg), tostring(expected), tostring(actual)), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then
        error(tostring(msg or "expected truthy value"), 2)
    end
end

assertEq(I.CountThreatsOnActor(johnny, false, nowMs), 3, "Johnny should have 3 active threats")
assertEq(I.CountThreatsOnActor(emma, false, nowMs), 2, "Emma should have 2 active threats")
assertEq(I.CountThreatsOnActor(rod, false, nowMs), 1, "Rod should have 1 active threat")
assertEq(I.CountThreatsOnActor(playerObj, true, nowMs), 0, "Player should have 0 active threats")

local helper1 = I.FindLeastThreatenedHelper(johnny, 16, nowMs)
assertTruthy(helper1, "Least-threatened helper should be found")
assertEq(helper1.isPlayer, true, "Player with 0 threats should beat closer NPCs with threats")
assertEq(helper1.name, "Alex", "Helper name should resolve to player forename")
assertEq(helper1.relKey, "player:OwnerPlayer", "Player relationship key should include username")

-- 2) Blindside warning is suppressed when speaker (Johnny) is swarmed; calls swarm_help to Alex instead.
local spoke = S.TryEmitBlindsideWarning(johnny, emma, {
    semanticClass = "zombie",
    enemyCount = 3,
    x = 11, y = 10, z = 0,
}, nowMs, "ref_1")
assertEq(spoke, true, "Swarmed speaker should emit swarm_help instead of blindside warning")
assertEq(#resolvedRoles, 1, "Exactly one callout should be resolved")
assertEq(resolvedRoles[1].role, "swarm_help", "3 zombies should trigger swarm_help role")
assertEq(resolvedRoles[1].targetName, "Alex", "Swarm help should address least-threatened player Alex")
assertEq(resolvedRoles[1].swarmCount, "3", "Swarm count token should be populated")
assertEq(deliveredBarks[1].interrupt, true, "Swarm help should interrupt lower-priority barks")

-- 3) Rescue resolution: threats on Johnny drop to 1 after 2s -> relationship boost + swarm_rescue_thanks.
nowMs = nowMs + 2500
setActiveZombies({
    makeZombie(1, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
})
syncActiveSet()

local rescued = S.CheckSwarmHelpResolution(johnny, nowMs)
assertEq(rescued, true, "Swarm rescue should resolve when threats drop")
assertEq(#relationshipEffects, 1, "Relationship effect should be applied to helper")
assertEq(relationshipEffects[1].npcId, johnny.id, "Relationship effect speaker should be Johnny")
assertEq(relationshipEffects[1].relKey, "player:OwnerPlayer", "Relationship effect should credit player helper")
assertEq(relationshipEffects[1].payload.interactionType, "swarm_rescue", "Interaction type should be swarm_rescue")
assertEq(resolvedRoles[2].role, "swarm_rescue_thanks", "Speaker should emit swarm_rescue_thanks")
assertEq(resolvedRoles[2].targetName, "Alex", "Thanks should address Alex")

-- 4) Actor-agnostic reverse case: Player has 2 threats, Emma has 1, Rod has 0.
--    Johnny has 5 threats (swarm_overwhelmed) -> picks AI/companion NPC Rod + enqueues swarm_help_reply!
nowMs = nowMs + 12000
setActiveZombies({
    makeZombie(10, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
    makeZombie(11, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
    makeZombie(12, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
    makeZombie(13, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
    makeZombie(14, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
    makeZombie(15, { playerTarget = playerObj }),
    makeZombie(16, { playerTarget = playerObj }),
    makeZombie(17, { npcTarget = emma.id, untilMs = nowMs + 5000 }),
})
syncActiveSet()

local helper2 = I.FindLeastThreatenedHelper(johnny, 16, nowMs)
assertTruthy(helper2, "NPC helper should be found")
assertEq(helper2.isPlayer, false, "NPC Rod with 0 threats should beat player with 2 threats")
assertEq(helper2.id, rod.id, "Rod should be selected as least-threatened helper")

local spokeOver = S.TryEmitSwarmHelpCall(johnny, nil, nowMs, "ref_2")
assertEq(spokeOver, true, "5 zombies should trigger swarm_overwhelmed call")
assertEq(resolvedRoles[3].role, "swarm_overwhelmed", "5+ threats should escalate to swarm_overwhelmed")
assertEq(resolvedRoles[3].targetName, "Rod", "Overwhelmed call should address NPC Rod")
assertEq(#enqueuedReplies, 1, "NPC helper should enqueue swarm_help_reply")
assertEq(enqueuedReplies[1].speaker, rod, "Reply speaker should be Rod")
assertEq(enqueuedReplies[1].role, "swarm_help_reply", "Reply role should be swarm_help_reply")

-- 5) Rescue resolution for NPC helper credits npc:npc_rod relationship!
nowMs = nowMs + 2500
setActiveZombies({
    makeZombie(10, { npcTarget = johnny.id, untilMs = nowMs + 5000 }),
})
syncActiveSet()
local rescuedNpc = S.CheckSwarmHelpResolution(johnny, nowMs)
assertEq(rescuedNpc, true, "NPC helper rescue should also resolve")
assertEq(#relationshipEffects, 2, "Second relationship effect should be applied")
assertEq(relationshipEffects[2].relKey, "npc:npc_rod", "Relationship effect should credit NPC helper key")
assertEq(resolvedRoles[4].role, "swarm_rescue_thanks", "Speaker should thank NPC helper")
assertEq(resolvedRoles[4].targetName, "Rod", "Thanks should address Rod")

-- 6) Idle Bystander Callout: 2 NPCs fighting (Johnny + Emma), Player Alex standing idle (0 threats, not attacking).
nowMs = nowMs + 16000
rod.alive = false -- isolate 2 NPCs + 1 idle player (3 total, 2 actively fighting)
playerObj._attacking = false
setActiveZombies({
    makeZombie(20, { npcTarget = johnny.id, untilMs = nowMs + 10000 }),
    makeZombie(21, { npcTarget = emma.id, untilMs = nowMs + 10000 }),
})
syncActiveSet()

local by1, fighters1 = I.FindIdleBystanderHelper(johnny, 16, nowMs)
assertTruthy(by1, "Idle player bystander should be found when 2 NPCs fight")
assertEq(fighters1, 2, "Should count 2 active fighters")
assertEq(by1.isPlayer, true, "Idle bystander should be the player")
assertEq(by1.name, "Alex", "Bystander name should be Alex")

-- First call starts the 3s idle grace timer without barking immediately
assertEq(S.TryEmitBystanderHelpCall(johnny, nil, nowMs, "by_1"), false, "Should wait for 3s idle grace before calling out bystander")

-- After 3.5s of still standing idle, Johnny calls out Alex!
nowMs = nowMs + 3500
assertEq(S.TryEmitBystanderHelpCall(johnny, nil, nowMs, "by_2"), true, "Should emit swarm_bystander_help after idle grace")
assertEq(resolvedRoles[5].role, "swarm_bystander_help", "Role should be swarm_bystander_help")
assertEq(resolvedRoles[5].targetName, "Alex", "Bystander callout should address idle player Alex")

-- If Alex IS actively attacking, Alex is NOT treated as an idle bystander!
playerObj._attacking = true
local byWhileFighting, fightersWhileFighting = I.FindIdleBystanderHelper(johnny, 16, nowMs)
assertEq(byWhileFighting, nil, "Actively attacking player should not be flagged as idle bystander")
assertEq(fightersWhileFighting, 3, "Attacking player should count as 3rd active fighter")

print("PASS: pnc_swarm_help_callout_smoke")
