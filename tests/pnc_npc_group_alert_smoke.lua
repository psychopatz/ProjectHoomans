local T = require "tests/support/test"

local now = 1000
local authority = true
local queryCount = 0
local visible = true
local ownerBody
local followerA
local followerB
local unowned
local hostile
local records
local broadcastRecordCount = 0

local function body(x, y)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        isAlive = function() return true end,
    }
end

ownerBody = body(0, 0)
ownerBody.getOnlineID = function() return 42 end
ownerBody.getUsername = function() return "owner" end
ownerBody.isAlive = function() return true end

followerA = {
    id = "follower_a",
    alive = true,
    presenceState = "live",
    ownerOnlineID = 42,
    ownerUsername = "owner",
    tacticalClass = "neutral",
    hostility = { attackNPCs = false },
    x = 2,
    y = 0,
    z = 0,
    runtime = {},
}
followerB = {
    id = "follower_b",
    alive = true,
    presenceState = "live",
    -- Exercise the durable follow-order fallback used after a rehydrate.
    ownerOnlineID = nil,
    ownerUsername = nil,
    orderSpec = { kind = "follow", ownerUsername = "owner" },
    tacticalClass = "neutral",
    hostility = { attackNPCs = false },
    x = 4,
    y = 0,
    z = 0,
    runtime = {},
}
unowned = {
    id = "unowned",
    alive = true,
    presenceState = "live",
    tacticalClass = "neutral",
    hostility = { attackNPCs = false },
    x = 3,
    y = 0,
    z = 0,
    runtime = {},
}
hostile = {
    id = "hostile",
    alive = true,
    presenceState = "live",
    tacticalClass = "hostile",
    hostility = { attackNPCs = true },
    x = 1,
    y = 0,
    z = 0,
    runtime = {},
}

records = {
    follower_a = followerA,
    follower_b = followerB,
    unowned = unowned,
    hostile = hostile,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        NPC_GROUP_ALERT_RADIUS = 8,
        NPC_ALERT_TTL_MS = 1800,
        NPC_ALERT_REPUBLISH_MS = 500,
        NPC_ALERT_LOS_RECHECK_MS = 250,
        ZOMBIE_TARGET_RADIUS = 12,
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        ROAM_TARGET_RADIUS = 12,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Combat = { Internal = { AttackExecution = {} } },
    SpatialIndex = {
        QueryNPCs = function()
            queryCount = queryCount + 1
            return { followerA, followerB, unowned, hostile }
        end,
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function(id)
            if id == "follower_a" then return body(2, 0) end
            if id == "follower_b" then return body(4, 0) end
            if id == "unowned" then return body(3, 0) end
            if id == "hostile" then return body(1, 0) end
            return nil
        end,
    },
    Relationships = {
        AreNPCsEnemies = function(source, target)
            -- Model the real directed relationship contract: the attacker
            -- considers the owner target hostile, while the owner follower
            -- does not necessarily classify the attacker in the same way.
            return source == hostile and target ~= source
        end,
    },
    Stealth = {},
    PerformanceScalingDiagnostics = {
        Enabled = true,
        NPCThreatAuditEnabled = false,
        Increment = function() end,
    },
    Network = {
        BroadcastRecord = function()
            broadcastRecordCount = broadcastRecordCount + 1
        end,
        BroadcastRemoval = function() end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception.lua"
)
PNC.Perception.CanSeeWorldObject = function()
    return visible, "clear"
end

local playerTarget = {
    kind = "player",
    player = ownerBody,
    onlineID = 42,
    username = "owner",
    x = 0,
    y = 0,
    z = 0,
}

T.truthy(
    PNC.Perception.PublishNPCGroupAlert(hostile, playerTarget, now),
    "hostile targeting the owner publishes one group alert"
)
T.equal(queryCount, 1, "group alert performs one bounded spatial fan-out")
T.truthy(followerA.runtime.npcThreatAlert,
    "first live follower receives the alert")
T.truthy(followerB.runtime.npcThreatAlert,
    "second live follower receives the alert")
T.equal(unowned.runtime.npcThreatAlert, nil,
    "unowned NPC is not included in the owner group")

local alert = PNC.Perception.FindNPCGroupAlert(followerA, 6, true)
T.truthy(alert and alert.kind == "npc" and alert.id == "hostile",
    "recipient resolves the hostile source from its alert")
T.equal(alert.groupAlert, true, "resolved target retains group-alert provenance")
T.equal(alert.ownerDefense, true, "group alert is marked as owner defense")
T.equal(alert.alertOnly, false, "visible hostile becomes an actionable target")

PNC.BehaviorThreatGuard = { Internal = {} }
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_TargetEligibility.lua"
)
local distantCandidate = PNC.Perception.FindNPCGroupAlert(followerB, 6, true)
T.truthy(
    PNC.BehaviorThreatGuard.Internal.IsThreat(distantCandidate, {
        x = followerB.x,
        y = followerB.y,
        z = followerB.z,
        radius = 2.2,
    }),
    "group alert keeps a follower eligible beyond the ordinary defense radius"
)

visible = false
now = now + 300
alert = PNC.Perception.FindNPCGroupAlert(followerB, 6, true)
T.truthy(alert and alert.alertOnly == true,
    "unseen group threat still wakes a follower without attacking blindly")

local beforeThrottle = queryCount
T.falsy(
    PNC.Perception.PublishNPCGroupAlert(hostile, playerTarget, now),
    "same source and owner alert is throttled"
)
T.equal(queryCount, beforeThrottle, "throttle avoids a second spatial query")

now = now + 600
visible = true
T.truthy(
    PNC.Perception.PublishNPCGroupAlert(hostile, {
        kind = "npc",
        id = "follower_a",
        x = followerA.x,
        y = followerA.y,
        z = followerA.z,
    }, now),
    "NPC target identity also resolves the owner group"
)

hostile.hostility.attackNPCs = false
hostile.hostility.attackZombies = false
PNC.Perception.ResolveRecentAttacker = function() return nil end
PNC.Perception.FindImmediateZombieThreat = function() return nil end
PNC.Perception.FindNearestEnemyNPC = function() return nil end
PNC.Perception.FindNearestEnemyPlayer = function() return playerTarget end
PNC.Perception.FindBestEnemyZombie = function() return nil end
local resolvedHostileTarget = PNC.Perception.ResolveHostileTarget(hostile)
T.equal(resolvedHostileTarget, playerTarget,
    "hostile target resolution publishes the owner attack incident")

PNC.CombatResolution = {}
PNC.NPCWounds = {
    ApplyCombatDamage = function()
        return false, { outcome = "damage_rejected", partId = "Hand_L" }
    end,
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_NPC.lua"
)
now = now + 600
local ownerDefenseTarget = PNC.Perception.FindNPCGroupAlert(
    followerA,
    6,
    true
)
T.truthy(ownerDefenseTarget,
    "owner-defense alert remains available at damage time")
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Targeting.lua"
)
local committedTarget = PNC.Combat.Internal.AttackExecution.resolveActionTarget(
    PNC.Combat.Internal.AttackExecution.captureTargetRef({
        kind = "npc",
        id = ownerDefenseTarget.id,
        x = ownerDefenseTarget.x,
        y = ownerDefenseTarget.y,
        z = ownerDefenseTarget.z,
        groupAlert = ownerDefenseTarget.groupAlert,
        ownerDefense = ownerDefenseTarget.ownerDefense,
        alertSequence = ownerDefenseTarget.alertSequence,
        alertRadius = ownerDefenseTarget.alertRadius,
        alertOnly = ownerDefenseTarget.alertOnly,
        immediateSelfDefense = ownerDefenseTarget.immediateSelfDefense,
    })
)
T.truthy(committedTarget.groupAlert,
    "committed NPC target preserves group-alert provenance")
T.truthy(committedTarget.ownerDefense,
    "committed NPC target preserves owner-defense provenance")
T.equal(committedTarget.alertSequence, ownerDefenseTarget.alertSequence,
    "committed NPC target preserves alert sequence")
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_HitEvent.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Target.lua"
)
local provenanceHit = PNC.CombatResolution.BuildHitEvent(
    followerA,
    committedTarget,
    { damage = 4, attackType = "melee" }
)
T.truthy(provenanceHit.groupAlert,
    "hit events preserve group-alert provenance")
T.truthy(provenanceHit.ownerDefense,
    "hit events preserve owner-defense provenance")
T.equal(provenanceHit.alertSequence, ownerDefenseTarget.alertSequence,
    "hit events preserve alert sequence")
PNC.NPCWounds.ApplyCombatDamage = function()
    return true, { outcome = "wounded", partId = "Hand_L" }
end
local ownerDamageApplied, ownerDamageReason, ownerDamageDetail =
    PNC.CombatResolution.ApplyTargetDamage(
        followerA,
        body(2, 0),
        committedTarget,
        { damage = 4, attackType = "melee" }
    )
T.truthy(ownerDamageApplied,
    "validated owner-defense alert authorizes the complete follower hit path")
T.equal(ownerDamageReason, "hit_npc",
    "owner-defense damage returns the normal NPC hit reason")
T.equal(ownerDamageDetail.outcome, "wounded",
    "authorized follower damage reaches the wound service")
T.equal(broadcastRecordCount, 0,
    "accepted NPC damage does not build a snapshot inline")
T.equal(records[committedTarget.id].runtime.forceSyncEvent,
    "combat_damage",
    "accepted NPC damage queues one coalesced combat snapshot")

local secondDamageApplied = PNC.CombatResolution.ApplyNPCDamage(
    records[committedTarget.id],
    body(2, 0),
    { attackerKind = "player", amount = 2 }
)
T.truthy(secondDamageApplied,
    "a second accepted hit still commits through the health writer")
T.equal(broadcastRecordCount, 0,
    "multiple same-tick NPC hits remain coalesced before record processing")

authority = false
local clientDamageApplied, clientDamageReason =
    PNC.CombatResolution.ApplyTargetDamage(
        followerA,
        body(2, 0),
        committedTarget,
        { damage = 4, attackType = "melee" }
    )
T.falsy(clientDamageApplied,
    "a multiplayer client cannot commit NPC damage")
T.equal(clientDamageReason, "not_authority",
    "the client boundary rejects the damage before mutation")
authority = true

PNC.NPCWounds.ApplyCombatDamage = function()
    return false, { outcome = "damage_rejected", partId = "Hand_L" }
end
local damageApplied, damageReason = PNC.CombatResolution.ApplyNPCDamage(
    followerA,
    body(2, 0),
    {
        attackerKind = "npc",
        attackerID = "hostile",
        amount = 4,
    }
)
T.falsy(damageApplied, "rejected NPC damage remains rejected")
T.equal(damageReason, "npc_damage_rejected",
    "NPC damage rejection keeps its stable reason")
T.truthy(followerB.runtime.npcThreatAlert,
    "NPC damage path publishes the owner alert before wound resolution")

authority = false
now = now + 600
beforeThrottle = queryCount
T.falsy(
    PNC.Perception.PublishNPCGroupAlert(hostile, playerTarget, now),
    "non-authority cannot publish group alerts"
)
T.equal(queryCount, beforeThrottle,
    "non-authority path does not query or mutate the fan-out")
authority = true

now = now + 2000
T.equal(PNC.Perception.FindNPCGroupAlert(followerA, 6, true), nil,
    "expired group alert is discarded")

T.finish("pnc_npc_group_alert_smoke")
