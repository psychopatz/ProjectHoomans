local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local factionCalls, socialCalls, semanticCalls, removals = 0, 0, 0, 0
local semanticSpec
local attacker = {
    id = "attacker", alive = true, x = 5, y = 5, z = 0, runtime = {},
}
local target = {
    id = "target", alive = true, x = 6, y = 5, z = 0,
    runtime = {}, health = { state = "normal", current = 5, max = 100 },
}
local targetBody = { isDead = function() return target.alive == false end }
local weapon = {
    getFullType = function() return "Base.Pistol" end,
    getDisplayName = function() return "M9 Pistol" end,
}

PNC = {
    CombatResolution = {},
    Core = { Now = function() return 1000 end },
    Const = {},
    Registry = {
        Get = function(id)
            if tostring(id) == "attacker" then return attacker end
            if tostring(id) == "target" then return target end
        end,
    },
    Relationships = {
        AreNPCsEnemies = function(a, b)
            return a == attacker and b == target
        end,
    },
    NPCWounds = {
        ApplyCombatDamage = function(record)
            if record.alive == false then
                return false, { outcome = "dead", reason = "already_dead" }
            end
            record.alive = false
            record.health.state = "dead"
            record.health.current = 0
            return true, { outcome = "killed", healthState = "dead" }
        end,
    },
    SocialEventHooksInternal = {
        RecordNPCDamagedByNPC = function()
            socialCalls = socialCalls + 1
        end,
    },
    Factions = {
        OnNPCAggression = function(_, _, _, spec)
            factionCalls = factionCalls + 1
            T.truthy(spec.killed, "existing faction aggression sees death")
        end,
    },
    SemanticCombatReactionService = {
        OnNPCHumanKill = function(a, victim, body, spec)
            semanticCalls = semanticCalls + 1
            semanticSpec = {
                attacker = a, victim = victim, body = body, spec = spec,
            }
        end,
    },
    Network = {
        BroadcastRemoval = function(id, reason)
            removals = removals + 1
            T.equal(id, "target", "existing removal owner gets target")
            T.equal(reason, "death", "existing removal reason remains death")
        end,
    },
}

local Resolution = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_NPC.lua"
)
local hit = {
    attackerKind = "npc",
    attackerID = "attacker",
    amount = 20,
    attackType = "ranged",
    attackKind = "ranged",
    weaponItem = weapon,
    weaponFullType = "Base.Pistol",
    partId = "Head",
    woundType = "bullet",
}
local ok = Resolution.ApplyNPCDamage(target, targetBody, hit)
T.truthy(ok, "authoritative hostile NPC damage commits")
T.equal(socialCalls, 1, "existing social damage owner runs exactly once")
T.equal(factionCalls, 1, "existing faction aggression owner runs exactly once")
T.equal(removals, 1, "existing removal owner runs exactly once")
T.equal(semanticCalls, 1, "live-to-dead transition emits one semantic kill moment")
T.equal(semanticSpec.attacker, attacker, "semantic observer receives actual attacker")
T.equal(semanticSpec.victim, target, "semantic observer receives actual victim")
T.equal(semanticSpec.spec.weaponItem, weapon,
    "human kill semantic observer receives actual hit weapon")
T.equal(semanticSpec.spec.weaponFullType, "Base.Pistol",
    "human kill semantic observer receives actual weapon type")
T.equal(semanticSpec.spec.partId, "Head",
    "human kill semantic observer receives actual body part")
T.equal(semanticSpec.spec.woundType, "bullet",
    "human kill semantic observer receives actual wound type")
T.equal(semanticSpec.spec.hostilityReason, "enemy",
    "human kill semantic observer receives grounded hostility reason")

local second = Resolution.ApplyNPCDamage(target, targetBody, hit)
T.falsy(second, "already-dead target rejects duplicate damage")
T.equal(semanticCalls, 1, "dead target cannot emit a duplicate human-kill bark")
T.equal(factionCalls, 1, "duplicate rejected hit cannot duplicate faction mutation")
T.equal(socialCalls, 1, "duplicate rejected hit cannot duplicate social mutation")
T.equal(removals, 1, "duplicate rejected hit cannot duplicate removal")

T.finish("pnc_semantic_hostile_human_kill_bridge_smoke")
