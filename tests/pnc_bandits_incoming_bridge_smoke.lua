local T = require "tests/support/test"

local BRIDGE_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingBridge.lua"
)
local CONTEXT_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingContext.lua"
)
local DAMAGE_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingDamage.lua"
)
local HOOK_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_RuntimeHook.lua"
)

local captured
local nativeCalls = 0
local sent
local flavorCalls = 0
local target = {
    getModData = function()
        return {
            PNC_Owner = "ProjectHoomans",
            PNC_UUID = "npc-1",
        }
    end,
    isAlive = function() return true end,
    isDead = function() return false end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    setAttackedBy = function() end,
}
local shooter = {
    id = "bandit-1",
    getX = function() return 11 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getPersistentOutfitID = function() return 7 end,
}
local weapon = {
    isRanged = function() return true end,
    getFullType = function() return "Base.Pistol" end,
    getMaxDamage = function() return 9 end,
}
local foreign = {
    getModData = function() return {} end,
}

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = {
        MODULE = "PNC",
        CMD_BANDITS_INCOMING_DAMAGE = "BanditsIncomingDamage",
    },
    Registry = {
        Get = function(id)
            return id == "npc-1" and {
                id = "npc-1",
                alive = true,
                recruited = true,
            } or nil
        end,
    },
    Compatibility = {
        DamageContext = T.load(T.path(
            "ProjectHoomans",
            "shared",
            "PNC/Core/Compatibility/PNC_Compatibility_DamageContext.lua"
        )),
        ActorOwnership = {
            IsHoomansOwned = function(body) return body == target end,
        },
        IncomingDamage = {
            Apply = function(context)
                captured = context
                return true, { outcome = "wounded" }
            end,
        },
        Bandits = {
            Internal = {
                ActorID = function(body) return body and body.id end,
            },
            Relationships = {
                CanBanditAttackHooman = function()
                    return true, "bandit_hostile"
                end,
            },
            Flavor = {
                Say = function()
                    flavorCalls = flavorCalls + 1
                    return true
                end,
            },
        },
    },
}

BanditUtils = {
    GetCharacterID = function(body) return body and body.id end,
    Hit = function()
        nativeCalls = nativeCalls + 1
        return "native"
    end,
}

T.load(BRIDGE_FILE)
T.load(CONTEXT_FILE)
T.load(DAMAGE_FILE)
T.load(HOOK_FILE)
T.truthy(PNC.Compatibility.Bandits.IncomingBridge,
    "Bandits inbound bridge did not initialize")

local landed = BanditUtils.Hit(shooter, weapon, target, 1)
T.truthy(landed, "Bandits managed-body hit was not handled")
T.equal(nativeCalls, 0,
    "Bandits bridge fell through to native damage for a Hoomans body")
T.equal(captured.attackType, "ranged",
    "Bandits firearm hit lost its ranged classification")
T.equal(captured.attackKind, "bandits_firearm",
    "Bandits firearm hit lost its provider kind")
T.equal(captured.woundType, "bullet",
    "Bandits firearm hit was not routed as a bullet wound")
T.equal(captured.weaponFullType, "Base.Pistol",
    "Bandits weapon identity was not forwarded")
T.equal(captured.attackerID, "bandit-1",
    "Bandits attacker identity was not forwarded")
T.equal(flavorCalls, 1,
    "Bandits presentation hook was not called after routed damage")

local nativeResult = BanditUtils.Hit(shooter, weapon, foreign, 1)
T.equal(nativeResult, "native",
    "unmanaged Bandits targets changed the native hit lane")
T.equal(nativeCalls, 1,
    "unmanaged Bandits target did not reach the native hit function")

PNC.Core.IsAuthority = function() return false end
isClient = function() return true end
getPlayer = function() return { id = "player-1" } end
sendClientCommand = function(player, module, command, args)
    sent = {
        player = player,
        module = module,
        command = command,
        args = args,
    }
end

local requested = BanditUtils.Hit(shooter, weapon, target, 1)
T.truthy(requested, "Bandits client hit was not converted to a request")
T.truthy(sent, "Bandits client hit did not submit an authority request")
T.equal(sent.command, "BanditsIncomingDamage",
    "Bandits client request used the wrong command")
T.equal(sent.args.attackType, "ranged",
    "Bandits client request lost its attack type")
T.equal(sent.args.weaponFullType, "Base.Pistol",
    "Bandits client request lost weapon identity")
T.equal(nativeCalls, 1,
    "Bandits client bridge called native damage")

T.finish("pnc_bandits_incoming_bridge_smoke")
