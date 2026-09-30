-- Locks the two cross-mod contracts that decide whether Project Hoomans and
-- Project A-Life can fight each other at all:
--   * a managed actor only engages an A-Life actor that is at war with its
--     owner, or that already hurt it (neutral patrols stay neutral);
--   * the directed faction stance must survive the committed-attack target
--     re-resolution, otherwise damage is rejected after perception approved it.

local T = require "tests/support/test"

local ADAPTER = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_Adapter.lua"
)

local managed = {}
local records = {}
local actors = {}

local function body(modData)
    return { getModData = function() return modData end }
end

local owner = { getUsername = function() return "Bob" end }

PNC = {
    Compatibility = {
        ActorOwnership = {
            IsHoomansOwned = function(candidate)
                return managed[candidate] == true
            end,
            RegisterAdapter = function(specification) return specification end,
        },
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 0 end,
        ResolvePlayerByUsername = function(name)
            return name == "Bob" and owner or nil
        end,
    },
    Registry = {
        Get = function(uuid) return records[uuid] end,
    },
    Factions = {
        GetFactionID = function(record)
            return record and record.affiliation
                and record.affiliation.factionID or nil
        end,
    },
}

ProjectALife = {
    ActorRegistry = {
        read = function(uid) return actors[uid] end,
        peek = function(uid) return actors[uid] end,
    },
    Relations = {
        hostileToPlayer = function() return false end,
    },
}

local Hub = T.load(ADAPTER)
local Adapter = PNC.Compatibility.ProjectALifeAdapter
local Policy = PNC.Compatibility.ProjectALifePolicy

T.equal(Hub, Adapter,
    "the adapter hub did not return the provider namespace table")
T.truthy(type(Adapter.CanHoomansAttack) == "function",
    "A-Life adapter did not expose canAttack")
T.truthy(Adapter and Adapter.applyDamage,
    "A-Life adapter did not register a damage capability")

local raiders = { uid = "alifeRaiders", generation = 1, factionId = "raiders" }
local deputy = { uid = "alifeDeputy", generation = 1, factionId = "deputies" }
actors[raiders.uid] = raiders
actors[deputy.uid] = deputy

local squad = {
    id = "npcSquad",
    affiliation = { factionID = "neutral" },
    ownerUsername = "Bob",
}

local deputyBody = body({ ProjectALifeUID = deputy.uid })
local raiderBody = body({ ProjectALifeUID = raiders.uid })
local managedBody = body({ PNC_UUID = "npcSquad", PNC_Owner = "ProjectHoomans" })
records.npcSquad = squad
managed[managedBody] = true

-- 1. A neutral A-Life actor is not a target, even with a concrete faction id.
T.falsy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = deputy.uid,
        factionId = deputy.factionId,
        worldObject = deputyBody,
    },
}), "a neutral A-Life patrol must never be a managed actor target")

-- 2. Direct self defence is always allowed.
T.truthy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = deputy.uid,
        factionId = deputy.factionId,
        worldObject = deputyBody,
        immediateSelfDefense = true,
    },
}), "self defence against an A-Life attacker was rejected")

squad.runtime = {
    recentThreat = {
        kind = "foreign_npc",
        provider = "ProjectALifeNPCs",
        id = raiders.uid,
        expiresAt = 1000,
    },
}
T.truthy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = raiders.uid,
        factionId = raiders.factionId,
        worldObject = raiderBody,
    },
}), "recorded recent threat was not treated as self defence")
squad.runtime = nil

-- 3. Owner-directed hostility opens the engagement, and the faction identity is
--    recovered from the live body after the target ref dropped it.
ProjectALife.Relations.hostileToPlayer = function(actor, player)
    return actor == raiders and player == owner
end
T.truthy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = raiders.uid,
        worldObject = raiderBody,
    },
}), "an A-Life actor at war with the owner must be engageable")
T.falsy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = deputy.uid,
        worldObject = deputyBody,
    },
}), "a neutral A-Life actor must stay neutral for the same owner")
ProjectALife.Relations.hostileToPlayer = function() return false end

-- 4. The regression: a concrete directed stance must survive a re-resolved
--    committed-attack target, which carries no factionId and no actor record.
Policy.SetRelation("ProjectHoomans", "neutral",
    "ProjectALifeNPCs", raiders.factionId, "hostile")
T.truthy(Adapter.CanHoomansAttack({
    attacker = squad,
    target = {
        provider = "ProjectALifeNPCs",
        actorId = raiders.uid,
        worldObject = raiderBody,
    },
}), "a re-resolved target lost its A-Life faction and the hostile stance")

local weapon = { getFullType = function() return "Base.Bat" end }
local attackerBody = body({ PNC_UUID = "npcSquad" })
local applied = {}
ProjectALife.HumanDamage = {
    apply = function(hitAttacker, hitTarget, hitWeapon, scale)
        applied[#applied + 1] = {
            attacker = hitAttacker,
            target = hitTarget,
            weapon = hitWeapon,
            scale = scale,
        }
        return true, 9, "torso"
    end,
}
local damageOk, damageReason = Adapter.applyDamage({
    target = {
        provider = "ProjectALifeNPCs",
        actorId = raiders.uid,
        worldObject = raiderBody,
    },
    context = {
        attackerRecord = squad,
        attackerBody = attackerBody,
        hit = { amount = 9, weaponItem = weapon },
    },
})
T.truthy(damageOk, "managed damage into A-Life was rejected: "
    .. tostring(damageReason))
T.equal(applied[1].target, raiderBody,
    "A-Life damage was applied to the wrong body")
T.equal(applied[1].weapon, weapon,
    "A-Life damage lost the attacker weapon")
T.equal(applied[1].scale, 1, "A-Life damage used an unexpected scale")

-- 5. Damage with no weapon is the unarmed case and must still reach A-Life.
applied = {}
T.truthy(Adapter.applyDamage({
    target = {
        provider = "ProjectALifeNPCs",
        actorId = raiders.uid,
        worldObject = raiderBody,
    },
    context = {
        attackerRecord = squad,
        attackerBody = attackerBody,
        hit = { amount = 4 },
    },
}), "unarmed managed damage into A-Life was rejected")
T.equal(applied[1].weapon, nil,
    "unarmed damage should forward a nil weapon to A-Life")

-- 6. The reverse direction: A-Life may only reach a managed body once the
--    directed relation is hostile. The old gate required the *target* to be
--    A-Life-owned, so this could never return true.
T.falsy(Adapter.CanProjectALifeAttack(deputy, managedBody, {}),
    "a neutral managed actor must stay friendly to A-Life")
T.truthy(Adapter.CanProjectALifeAttack(raiders, managedBody, {}),
    "A-Life could not damage a managed actor it is at war with")

-- 7. One stray hit with an unknown faction must not create a wildcard stance
--    that turns every managed actor hostile to every A-Life faction.
local escalated, escalateReason = Policy.RecordConflict(
    "ProjectHoomans", nil, "ProjectALifeNPCs", deputy.factionId,
    { emitFlavor = false })
T.falsy(escalated,
    "a hit with no Hoomans faction identity escalated to warfare")
T.equal(escalateReason, "faction_identity_missing",
    "unexpected escalation rejection reason")
T.equal(Policy.relations["ProjectHoomans:*->ProjectALifeNPCs:deputies"], nil,
    "a stray hit created a wildcard Hoomans stance")
T.equal(Policy.relations["ProjectALifeNPCs:deputies->ProjectHoomans:*"], nil,
    "a stray hit created a wildcard A-Life stance")

-- 8. A known directed pair still escalates both ways.
T.truthy(Policy.RecordConflict(
    "ProjectHoomans", "neutral", "ProjectALifeNPCs", "scavengers",
    { emitFlavor = false }), "a concrete directed conflict did not escalate")
T.equal(Policy.relations["ProjectHoomans:neutral->ProjectALifeNPCs:scavengers"],
    "hostile", "outgoing conflict stance was not recorded")
T.equal(Policy.relations["ProjectALifeNPCs:scavengers->ProjectHoomans:neutral"],
    "hostile", "incoming conflict stance was not recorded")

-- 9. A-Life's native body classification calls every unstamped body hostile.
--    The reverse bridge must stop that for managed actors, otherwise they are
--    valid line-of-fire bystanders and get a real attacker to retaliate against.
local traders = { uid = "alifeTraders", generation = 1, factionId = "traders" }
actors[traders.uid] = traders

-- A managed body that the directed policy already allows A-Life to engage.
local hostileManagedBody = body({
    PNC_UUID = "npcSquad",
    PNC_Owner = "ProjectHoomans",
    PNC_ProjectALifeRelation = "hostile",
})
managed[hostileManagedBody] = true

local playerKeyCalls = {}
ProjectALife.Perception = {
    -- Perceive a managed body with the kind A-Life itself derived for it.
    findThreat = function() return hostileManagedBody, 4, "zombie" end,
}
ProjectALife.Combat = {
    friendlyBody = function() return false, "native" end,
    hostileToActor = function() return true end,
}
ProjectALife.Speech = {
    playerKey = function(player)
        playerKeyCalls[#playerKeyCalls + 1] = player
        return "bob"
    end,
}
T.load(T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_ReverseBridge.lua"
))
T.falsy(ProjectALife.Combat.hostileToActor(traders, managedBody, nil),
    "a neutral managed actor was still classified hostile by A-Life")
T.truthy(ProjectALife.Combat.hostileToActor(
    traders, body({ ProjectALifeUID = "unrelatedZombie" }), nil),
    "the reverse bridge swallowed A-Life's native hostility for other bodies")

-- An allowed managed target must keep A-Life's own kind. Labelling it "actor"
-- routed it into actor-only logic (ActorRegistry lookup, actor grudge keys, and
-- the Risk/speech path), none of which a managed body can satisfy.
local threat, threatDistance, threatKind =
    ProjectALife.Perception.findThreat(traders, nil, nil)
T.equal(threat, hostileManagedBody,
    "the reverse bridge dropped an allowed managed target")
T.near(threatDistance, 4, 0.001,
    "the reverse bridge lost the perceived distance")
T.equal(threatKind, "zombie",
    "the reverse bridge re-labelled a managed body as an A-Life actor")

-- 10. A-Life's own pleading path calls Speech.playerKey with a non-player (it
--     computes `isPlayer` and then passes `isPlayer and target or nil`), and
--     playerKey indexes that argument without a nil guard. The guard must
--     return what playerKey already returns on failure, and delegate anything
--     that really is a player.
T.equal(ProjectALife.Speech.playerKey(nil), nil,
    "playerKey(nil) must not reach the debugger as an error")
T.equal(ProjectALife.Speech.playerKey(body({})), nil,
    "playerKey(non-player) must not reach the debugger as an error")
local fakePlayer = { getUsername = function() return "Bob" end }
T.equal(ProjectALife.Speech.playerKey(fakePlayer), "bob",
    "a real player argument must still reach A-Life's playerKey")
T.equal(#playerKeyCalls, 1,
    "only the real player argument may reach A-Life's playerKey")

T.finish("pnc_projectalife_compat_policy_smoke")
