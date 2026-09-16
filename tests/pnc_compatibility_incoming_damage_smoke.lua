local T = require "tests/support/test"

local OWNERSHIP_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_ActorOwnership.lua"
)
local INCOMING_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_IncomingDamage.lua"
)

local record = {
    id = "hooman-1",
    alive = true,
    x = 10,
    y = 20,
    z = 0,
}
local appliedEvent
local managedBody = {
    getModData = function()
        return {
            PNC_Owner = "ProjectHoomans",
            PNC_UUID = "hooman-1",
        }
    end,
    isDead = function() return false end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local foreignBody = {
    getModData = function() return {} end,
    isDead = function() return false end,
}
local attacker = {
    getX = function() return 12 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return body == managedBody
        end,
    },
    Registry = {
        Get = function(id)
            return id == "hooman-1" and record or nil
        end,
    },
    NPCWounds = {
        ApplyCombatDamage = function(_, body, event)
            appliedEvent = {
                body = body,
                event = event,
            }
            return true, {
                outcome = "wounded",
                damage = event.amount,
            }
        end,
    },
}

T.load(OWNERSHIP_FILE)
local incoming = T.load(INCOMING_FILE)

local applied, result = incoming.Apply({
    target = managedBody,
    attacker = attacker,
    amount = 12,
    type = "bandit_melee",
    woundType = "laceration",
    attackerKind = "foreign_npc",
    attackerProvider = "Bandits",
    attackerID = "bandit-7",
})

T.truthy(applied, "generic inbound damage bridge rejected a valid hit")
T.equal(result.outcome, "wounded", "generic inbound damage returned wrong result")
T.equal(appliedEvent.body, managedBody, "wound pipeline received wrong body")
T.equal(appliedEvent.event.amount, 12, "damage amount was not forwarded")
T.equal(appliedEvent.event.attackerKind, "foreign_npc",
    "foreign attacker kind was not forwarded")
T.equal(appliedEvent.event.attackerProvider, "Bandits",
    "foreign provider was not forwarded")
T.equal(appliedEvent.event.attackerID, "bandit-7",
    "foreign attacker ID was not forwarded")
T.equal(appliedEvent.event.x, 12, "attacker X coordinate was not forwarded")

local rejected, reason = incoming.Apply({
    target = foreignBody,
    attacker = attacker,
    amount = 12,
})
T.falsy(rejected, "inbound bridge accepted a non-Hoomans body")
T.equal(reason, "incoming_target_not_hoomans_owned",
    "inbound bridge returned the wrong ownership rejection")

T.finish("pnc_compatibility_incoming_damage_smoke")
