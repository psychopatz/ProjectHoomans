local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local events = {}
local presentations = {}
local logs = {}
local tickHandlers = {}
local clock = 1000
local player = {
    getUsername = function() return "tester" end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local attackerBody = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local witness = {
    id = "witness",
    alive = true,
    affiliation = { factionID = "team" },
}
local attackerRecord = { id = "attacker", alive = true }
local damagedRecord = {
    id = "damaged",
    alive = true,
    affiliation = { factionID = "team" },
}

isServer = function() return true end
isClient = function() return false end

PNC = {
    Config = { Relationships = { EnableSocialEvents = true } },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return clock end,
        LogInfo = function(message) logs[#logs + 1] = message end,
        ForEachPlayer = function(callback) callback(player) end,
    },
    SocialProfileConstants = {
        ORIENTATION_BISEXUAL = "bisexual",
        ORIENTATION_GAY = "gay",
        SOCIAL_FRIENDLY = "friendly",
        SOCIAL_WITHDRAWN = "withdrawn",
    },
    SocialProfileTypes = {
        NormalizeNPCPersonality = function(value)
            return value
        end,
        NormalizePlayerSocialProfile = function(value)
            return value
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Registry = {
        ForEachLive = function(callback)
            callback(witness, attackerBody, witness.id)
            callback(attackerRecord, attackerBody, attackerRecord.id)
        end,
        GetLiveZombie = function(id)
            if id == "attacker" then return attackerBody end
            return nil
        end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:tester:character" end,
    },
    SocialEventHooksInternal = {
        WorldAgeHours = function() return 10 end,
        WitnessRadius = 12,
        LiveNPCIsWitness = function(record)
            return record.id == witness.id
        end,
        IsPlayer = function(value) return value == player end,
        IsZombie = function(value) return value == attackerBody end,
        ThreatIDFor = function() return "zombie:test" end,
    },
    SocialEvents = {
        Emit = function(event)
            events[#events + 1] = event
            return {
                ok = true,
                eventID = event.id,
                details = {
                    {
                        relationshipBefore = {
                            approval = 10,
                            respect = 10,
                            familiarity = 0,
                        },
                        relationshipAfter = {
                            approval = event.type == "player_damaged_npc"
                                and 7 or 8,
                            respect = event.type == "player_damaged_npc"
                                and 6 or 7,
                            familiarity = 0,
                        },
                    },
                },
            }
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(
            targetPlayer, npcID, reason, context
        )
            presentations[#presentations + 1] = {
                targetPlayer = targetPlayer,
                npcID = npcID,
                reason = reason,
                context = context,
            }
            return true, nil
        end,
    },
}

local bodyPart = {
    health = 100,
    scratchTime = 0,
    cutTime = 0,
    biteTime = 0,
    getHealth = function(self) return self.health end,
    getScratchTime = function(self) return self.scratchTime end,
    getCutTime = function(self) return self.cutTime end,
    getBiteTime = function(self) return self.biteTime end,
    scratched = function(self) return self.scratchTime > 0 end,
    isCut = function(self) return self.cutTime > 0 end,
    bitten = function(self) return self.biteTime > 0 end,
}
local bodyParts = {
    size = function() return 1 end,
    get = function(_, index) return index == 0 and bodyPart or nil end,
}
local bodyDamage = {
    getBodyParts = function() return bodyParts end,
    getOverallBodyHealth = function() return bodyPart.health end,
}
player.getBodyDamage = function() return bodyDamage end
player.getAttackedBy = function() return attackerBody end
Events = {
    OnTick = {
        Add = function(handler) tickHandlers[#tickHandlers + 1] = handler end,
    },
}

local H = PNC.SocialEventHooksInternal
T.load("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter.lua")

local applied, reason = H.RecordPlayerDamagedNPC(
    player,
    damagedRecord,
    { amount = 20, attackType = "melee", source = "player_weapon_event" }
)
T.equal(applied, true, "player damage event applies")
T.equal(reason, "presented", "player damage event is presented")
T.equal(events[1].type, "player_damaged_npc", "player damage event type")
T.equal(events[1].actorKey, "player:tester:character",
    "player damage actor key")
T.equal(events[1].targetKey, "npc:damaged",
    "player damage target key")
T.equal(events[1].context.damage, 20,
    "player damage preserves accepted amount")
T.equal(presentations[1].reason, "player_damaged_npc",
    "player damage uses relationship presentation")

local count, candidates, hurtReason = H.RecordNPCDamagedPlayer(
    player,
    attackerRecord,
    attackerBody,
    { amount = 12, healthLoss = 4.08, woundType = "scratch" }
)
T.equal(count, 1, "nearby NPC receives witnessed hurt event")
T.equal(candidates, 1, "only non-attacker NPC is a hurt witness")
T.equal(hurtReason, "witnesses_notified",
    "hurt witness dispatch succeeds")
T.equal(events[2].type, "witnessed_player_hurt",
    "hurt witness event type")
T.equal(events[2].targetKey, "npc:witness",
    "hurt witness target key")
T.near(events[2].context.damage, 4.08, 0.001,
    "hurt event uses actual health loss")
T.equal(presentations[2].reason, "witnessed_player_hurt",
    "hurt event uses relationship presentation")
T.truthy(events[1].id ~= events[2].id,
    "combat observations receive unique event IDs")
T.truthy(#logs >= 6, "combat observation stages are logged")

local teammateBody = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local zombie = {
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local teammateCount, teammateCandidates, teammateReason =
    H.RecordNPCDamagedByZombie(
        damagedRecord,
        teammateBody,
        zombie,
        {
            amount = 7,
            healthLoss = 7,
            woundType = "scratch",
            attackerID = "zombie:test",
        }
    )
T.equal(teammateCount, 1,
    "same-faction nearby NPC receives teammate hurt flavor")
T.equal(teammateCandidates, 1,
    "teammate hurt scan finds one visible teammate")
T.equal(teammateReason, "teammates_notified",
    "teammate hurt flavor dispatch succeeds")
T.equal(#events, 2,
    "teammate hurt flavor does not mutate relationship state")
T.equal(#presentations, 3,
    "teammate hurt flavor uses the existing presentation transport")
T.equal(presentations[3].reason, "witnessed_teammate_hurt",
    "teammate hurt flavor reason is preserved")
T.equal(
    presentations[3].context.ambientFlavor.flavorID,
    "social.witnessed_teammate_hurt",
    "teammate hurt flavor ID is reusable")
T.equal(
    presentations[3].context.ambientFlavor.context.victimNPCID,
    damagedRecord.id,
    "teammate hurt flavor carries victim identity for client name resolution")
T.equal(
    presentations[3].context.ambientFlavor.context.woundType,
    "scratch",
    "teammate hurt flavor carries wound type")

clock = 3000
local npcAttackerCount, npcAttackerCandidates, npcAttackerReason =
    H.RecordNPCDamagedByNPC(
        damagedRecord,
        teammateBody,
        attackerRecord,
        {
            amount = 11,
            attackerID = attackerRecord.id,
            woundType = "laceration",
        }
    )
T.equal(npcAttackerCount, 1,
    "same-faction teammate hurt by an NPC is also observed")
T.equal(npcAttackerCandidates, 1,
    "NPC battle hurt scan finds one visible teammate")
T.equal(npcAttackerReason, "teammates_notified",
    "NPC battle teammate flavor dispatch succeeds")
T.equal(#presentations, 4,
    "NPC battle teammate flavor uses the presentation transport")
T.equal(presentations[4].context.ambientFlavor.context.attackerKind, "npc",
    "NPC battle teammate flavor preserves attacker kind")

T.equal(#tickHandlers, 1, "vanilla damage poll registers once")
tickHandlers[1]()
bodyPart.health = 92
bodyPart.scratchTime = 8
clock = 5100
tickHandlers[1]()
T.equal(events[3].type, "witnessed_player_hurt",
    "vanilla zombie wound is converted to a hurt event")
T.equal(events[3].context.woundType, "scratch",
    "vanilla wound type is preserved")
T.near(events[3].context.damage, 8, 0.001,
    "vanilla wound uses observed health loss")

T.load("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileMath.lua")
local Math = PNC.SocialProfileMath
local profile = {
    compassion = 0.5,
    bravery = 0.5,
    loyalty = 0.5,
    forgiveness = 0.5,
    socialStyle = "neutral",
}
local light = Math.ModifySocialEvent(
    profile,
    {},
    { type = "player_damaged_npc", context = { damage = 10 } },
    { approvalEffect = -3, respectEffect = -4, moraleEffect = -1, familiarityGain = 0 }
)
local heavy = Math.ModifySocialEvent(
    profile,
    {},
    { type = "player_damaged_npc", context = { damage = 40 } },
    { approvalEffect = -3, respectEffect = -4, moraleEffect = -1, familiarityGain = 0 }
)
local factionHeavy = Math.ModifySocialEvent(
    profile,
    {},
    { type = "faction_member_attacked", context = { damage = 40 } },
    { approvalEffect = -2, respectEffect = -3, moraleEffect = -1, familiarityGain = 0 }
)
T.near(light.approvalEffect, -3, 0.001,
    "baseline damage impact remains unchanged")
T.near(heavy.approvalEffect, -12, 0.001,
    "heavy damage scales approval penalty")
T.near(heavy.respectEffect, -16, 0.001,
    "heavy damage scales respect penalty")
T.near(factionHeavy.approvalEffect, -8, 0.001,
    "faction attack damage scales approval penalty")
T.near(factionHeavy.respectEffect, -12, 0.001,
    "faction attack damage scales respect penalty")

T.finish("pnc_social_combat_damage_smoke")
