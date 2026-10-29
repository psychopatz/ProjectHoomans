local T = require "tests/support/test"

local player = { id = "player" }
local provoked = 0
local reactions = 0
local lastSpec

PNC = {
    Core = {
        Now = function() return 1000 end,
        ResolvePlayerByOnlineID = function(id)
            return id == 7 and player or nil
        end,
        ResolvePlayerByUsername = function() return nil end,
    },
    CombatResolution = {},
    NPCWounds = {
        ApplyCombatDamage = function()
            return true, {
                outcome = "wounded",
                healthState = "normal",
                healthCurrent = 90,
                healthMax = 100,
                targetAlive = true,
            }
        end,
    },
    Relationships = {
        ProvokeNeutralByPlayer = function(record)
            provoked = provoked + 1
            record.tacticalClass = "hostile"
            return true, "changed"
        end,
    },
    SemanticCombatReactionService = {
        OnPlayerAssaultedNPC = function(record, targetPlayer, spec)
            reactions = reactions + 1
            T.equal(targetPlayer, player,
                "assault reaction resolves the attacking player")
            T.equal(record.tacticalClass, "hostile",
                "reaction is emitted after neutral-to-hostile transition")
            lastSpec = spec
            return 1, "semantic_reaction_emitted"
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_NPC.lua"
)

local record = {
    id = "neutral",
    alive = true,
    tacticalClass = "neutral",
    x = 10,
    y = 20,
    z = 0,
    runtime = {},
    health = { state = "normal", current = 100, max = 100 },
}
local body = { isDead = function() return false end }

local applied, reason = PNC.CombatResolution.ApplyNPCDamage(
    record,
    body,
    {
        attackerKind = "player",
        attackerOnlineID = 7,
        amount = 10,
        attackType = "melee",
        attackKind = "player_weapon_event",
        woundType = "laceration",
    }
)

T.truthy(applied, "player assault damage is committed")
T.equal(reason, "hit_npc", "player assault uses normal NPC damage result")
T.equal(provoked, 1, "neutral hostility transition runs once")
T.equal(reactions, 1, "hostility transition emits one semantic reaction")
T.equal(lastSpec.hostilityReason, "attacked_by_player",
    "semantic reaction is grounded in the assault cause")
T.equal(lastSpec.attackType, "melee",
    "semantic reaction retains attack context")

T.finish("pnc_player_assault_hostility_reaction_smoke")
