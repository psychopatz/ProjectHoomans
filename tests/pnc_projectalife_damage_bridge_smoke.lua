local T = require "tests/support/test"

local bridgeFile = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_DamageBridge.lua"
)

local incomingCalls = 0
local incomingContext
local playerCalls = 0
local nativeFallbackCalls = 0
local weapon = {
    getFullType = function() return "Base.Cudgel" end,
    getMaxDamage = function() return 1 end,
}

local shell = {
    getModData = function()
        return {
            ProjectALifeUID = "alife-1",
            ProjectALifeGeneration = 2,
        }
    end,
}

local hoomansBody = {
    kind = "hoomans",
    getModData = function()
        return { PNC_NPC = true, PNC_UUID = "npc-1" }
    end,
}

local player = { kind = "player" }
local ordinaryZombie = { kind = "zombie" }

instanceof = function(body, className)
    return className == "IsoPlayer" and body == player
end

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Compatibility = {
        ActorOwnership = {
            IsHoomansOwned = function(body) return body == hoomansBody end,
        },
        ProjectALifeAdapter = {
            CanProjectALifeAttack = function() return true end,
        },
        IncomingDamage = {
            Apply = function(context)
                incomingCalls = incomingCalls + 1
                incomingContext = context
                T.equal(context.target, hoomansBody,
                    "A-Life routed damage to the wrong Hoomans body")
                return true
            end,
        },
    },
    CombatResolution = {
        ApplyPlayerDamage = function(target, amount, attackType,
                hitWeapon, hit)
            playerCalls = playerCalls + 1
            T.equal(target, player, "A-Life routed damage to the wrong player")
            T.truthy(amount > 0, "player bridge passed empty damage")
            T.equal(attackType, "melee", "player attack type was not preserved")
            T.equal(hitWeapon, weapon, "player weapon was not preserved")
            T.equal(hit.attackerID, "alife-1",
                "player hit lost the A-Life attacker identity")
            return true
        end,
    },
}

ProjectALife = {
    ActorRegistry = {
        read = function(uid)
            return uid == "alife-1" and {
                uid = uid,
                factionId = "hostile",
            } or nil
        end,
    },
    HumanDamage = {
        points = function() return 8, "torso" end,
    },
    LineOfFire = {
        resolve = function(_, _, _, applyCharacterHit)
            applyCharacterHit(hoomansBody)
            applyCharacterHit(player)
            return true
        end,
    },
    ModuleGunner = {
        grazePlayer = function()
            nativeFallbackCalls = nativeFallbackCalls + 1
            return true
        end,
    },
    Combat = {
        adapters = {},
        settings = {},
        weaponFor = function() return weapon end,
        isRanged = function() return false end,
        resolveAttack = function(actor, actorShell, target)
            if target == hoomansBody or target == player then
                return ProjectALife.Combat.adapters.applyDamage(
                    actorShell, target, weapon)
            end
            nativeFallbackCalls = nativeFallbackCalls + 1
            return true
        end,
    },
}

T.load(bridgeFile)

local actor = { uid = "alife-1" }
T.truthy(ProjectALife.Combat.resolveAttack(
    actor, shell, hoomansBody, false, "HeadLeft", false
), "Hoomans attack bridge rejected a valid hit")
T.equal(incomingCalls, 1,
    "A-Life did not route a managed Hoomans target through wounds")
T.equal(incomingContext.attackType, "melee",
    "A-Life inbound damage lost its attack type")
T.equal(incomingContext.attackKind, "project_alife_combat_damage",
    "A-Life inbound damage lost its provider kind")
T.equal(incomingContext.weaponItem, weapon,
    "A-Life inbound damage lost its weapon item")

T.truthy(ProjectALife.Combat.resolveAttack(
    actor, shell, player, false, "HeadLeft", false
), "player attack bridge rejected a valid hit")
T.equal(playerCalls, 1,
    "A-Life player damage did not use the safe Hoomans resolver")

local beforeLineHoomans = incomingCalls
local beforeLinePlayers = playerCalls
T.truthy(ProjectALife.LineOfFire.resolve(
    shell, player, weapon, function()
        nativeFallbackCalls = nativeFallbackCalls + 1
    end
), "line-of-fire bridge rejected a valid hit")
T.equal(incomingCalls, beforeLineHoomans + 1,
    "line-of-fire did not route Hoomans bodies through wounds")
T.equal(playerCalls, beforeLinePlayers + 1,
    "line-of-fire did not route players through the safe resolver")

T.truthy(ProjectALife.ModuleGunner.grazePlayer(
    shell, weapon, player
), "gunner bridge rejected a valid player hit")
T.equal(nativeFallbackCalls, 0,
    "gunner bridge fell back to the raw BodyDamage path")

T.truthy(ProjectALife.Combat.resolveAttack(
    actor, shell, ordinaryZombie, false, "HeadLeft", false
), "unmanaged target changed the native A-Life lane")
T.equal(nativeFallbackCalls, 1,
    "unmanaged target was incorrectly captured by the compatibility bridge")

PNC.Core.IsAuthority = function() return false end
local nativeBeforeClientTarget = nativeFallbackCalls
T.falsy(ProjectALife.Combat.resolveAttack(
    actor, shell, hoomansBody, false, "HeadLeft", false
), "A-Life client lane mutated a managed Hoomans body")
T.equal(nativeFallbackCalls, nativeBeforeClientTarget,
    "A-Life client lane fell through to native managed-body damage")

T.equal(PNC.Compatibility.ProjectALifeDamageBridge.metrics.hoomansRouted, 2,
    "Hoomans route metric was not recorded")
T.equal(PNC.Compatibility.ProjectALifeDamageBridge.metrics.playerRouted, 3,
    "player route metric was not recorded")

T.finish("pnc_projectalife_damage_bridge_smoke")
