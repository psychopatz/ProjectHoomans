local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local now = 1000
local sends = {}
local queryCount = 0
local bodies = {}
local records = {}
for i = 1, 3 do
    records[i] = {
        id = "npc" .. tostring(i),
        alive = true,
        x = i + 1,
        y = 0,
        z = 0,
        style = i == 1 and "supportive" or "practical",
        runtime = {
            zombieObservation = {
                band = "several",
                nearbyCount = 5,
            },
        },
    }
    bodies[records[i].id] = {
        isDead = function() return false end,
    }
end

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "tester" end,
}
local zombie = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = { ZOMBIE_TARGET_RADIUS = 12 },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Registry = {
        GetLiveZombie = function(id) return bodies[id] end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            queryCount = queryCount + 1
            return records
        end,
        QueryPlayers = function()
            return { player }
        end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(
            targetPlayer, npcID, reason, payload
        )
            sends[#sends + 1] = {
                player = targetPlayer,
                npcID = npcID,
                reason = reason,
                payload = payload,
            }
            return true
        end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:p1" end,
    },
    Semantics = {
        CombatReactionProfile = {
            Build = function(record, _, options)
                return {
                    combatReactionRole = options.role,
                    combatReactionStyle = record.style or "practical",
                    combatReactionMood = "steady",
                    combatPressure = "several",
                    killerActorKind = options.actorKind,
                    relationshipState = "friend",
                    relationshipTier = "warm",
                    socialStyle = "friendly",
                    healthState = "okay",
                    health = "I'm okay.",
                    nextAction = "Clear the nearby zombies before we relax.",
                    quantity = "5 zombies are still close enough to matter.",
                    nearbyZombieCount = 5,
                }
            end,
        },
        SocialReactions = {
            Resolve = function(spec)
                local c = spec.context
                return {
                    fallback = c.combatReactionRole == "killer"
                        and c.combatWeaponNamed == true
                        and "This {combatWeaponDisplayName} works."
                        or c.combatReactionStyle == "supportive"
                            and "Good one. You okay?"
                            or "Good. Check the area.",
                    semanticAct = "REACT",
                    topic = "combat",
                    responsePlanID = "semantic.combat.kill."
                        .. c.combatReactionRole .. "."
                        .. c.combatReactionStyle,
                    realizationFamily = "semantic.combat.kill."
                        .. c.combatReactionRole .. "."
                        .. c.combatReactionStyle,
                    realizationID = "semantic.test",
                    offerIDs = {
                        "semantic.followup.event.happened",
                        "semantic.followup.event.quantity",
                        "semantic.followup.event.health",
                        "semantic.followup.event.next",
                    },
                }
            end,
        },
    },
}

local Service = T.load(
    "ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCombatReactionService.lua"
)

local emitted, reason = Service.OnPlayerKill(player, zombie, { now = now })
T.equal(emitted, 2, "player kill is bounded to two nearby speakers")
T.equal(reason, "semantic_reaction_emitted", "player reaction reason")
T.equal(queryCount, 1, "player kill performs one spatial NPC query")
T.equal(#sends, 2, "only two presentation sends occur")
T.equal(sends[1].reason, "zombie_kill_witnessed",
    "routine kill uses ephemeral semantic event type")
T.equal(sends[1].payload.meaningful, false,
    "routine kill interaction is not marked meaningful")
T.equal(sends[1].payload.transientInteraction, true,
    "routine kill follow-up context is live-only")
T.equal(sends[1].payload.ambientFlavor.memoryEligible, false,
    "routine kill speech is not memory eligible")
T.equal(sends[1].payload.ambientFlavor.llmEligible, false,
    "routine kill does not invoke expensive LLM generation")
T.equal(sends[1].payload.ambientFlavor.presentationClass, "BARK",
    "routine kill is explicitly non-blocking combat chatter")
T.equal(
    sends[1].payload.ambientFlavor.context.combatMoment.schema,
    "semantic.combat.moment.v1",
    "routine kill carries the unified bounded combat-moment contract"
)
T.equal(
    sends[1].payload.ambientFlavor.context.combatMoment.kind,
    "kill",
    "kill reaction moment identifies its authoritative event kind"
)
T.equal(#sends[1].payload.ambientFlavor.offerIDs, 4,
    "kill reaction exposes grounded follow-ups")
T.equal(
    sends[1].payload.semanticEventFacts[sends[1].payload.eventID].quantity,
    "5 zombies are still close enough to matter.",
    "quantity follow-up is grounded"
)
T.falsy(PNC.SocialEvents,
    "routine semantic reaction requires no SocialEvents mutation owner")
for _, record in ipairs(records) do
    T.falsy(record.runtime.semanticCombatReaction,
        "unified arbiter replaces the old per-record kill throttle")
end

now = 1200
local coalesced, coalescedReason = Service.OnPlayerKill(
    player, zombie, { now = now }
)
T.equal(coalesced, 0, "rapid kill does not fan out again")
T.equal(coalescedReason, "reaction_coalesced", "rapid reaction is coalesced")
T.equal(queryCount, 1, "coalesced kill skips even the spatial witness query")
T.equal(#sends, 2, "coalesced kill sends no presentation")

now = 2000
local cooldown, cooldownReason = Service.OnPlayerKill(
    player, zombie, { now = now }
)
T.equal(cooldown, 0, "global cooldown suppresses repeated speech")
T.equal(cooldownReason, "reaction_coalesced",
    "global cooldown skips the whole reaction fanout")
T.equal(queryCount, 1,
    "coalesced kill performs no spatial query or presentation work")
T.equal(#sends, 2, "global cooldown sends no presentation")

now = 7000
local later = Service.OnPlayerKill(player, zombie, { now = now })
T.equal(later, 2, "eligible speakers can react again after cooldown")
T.equal(#sends, 4, "only eligible cooldown-expired speeches are sent")
local laterFact = sends[3].payload.semanticEventFacts[
    sends[3].payload.eventID
]
T.equal(laterFact.killBurstCount, 3,
    "suppressed kills coalesce into the next spoken event fact")

Service.ResetRuntime()
for _, record in ipairs(records) do
    record.runtime.semanticCombatReaction = nil
end
sends = {}
PNC.Skills = {
    ResolveWeaponSkill = function() return "LongBlade" end,
    GetLevel = function() return 6 end,
}
local machete = {
    getFullType = function() return "Base.Machete" end,
    getDisplayName = function() return "Machete" end,
}
now = 10000
local npcListeners, npcReason = Service.OnNPCKill(records[1], zombie, {
    now = now,
    attackType = "melee",
    attackKind = "swing",
    weaponItem = machete,
    weaponFullType = "Base.Machete",
    partId = "Head",
    woundType = "cut",
})
T.equal(npcListeners, 1, "NPC self-kill speaks to nearby player")
T.equal(npcReason, "semantic_reaction_emitted", "NPC kill reaction reason")
T.equal(sends[1].reason, "zombie_kill_self",
    "NPC kill uses the same semantic reaction system")
T.equal(
    sends[1].payload.ambientFlavor.context.combatReactionRole,
    "killer",
    "NPC kill selects killer-role response family"
)
local killContext = sends[1].payload.ambientFlavor.context
T.equal(killContext.combatWeaponFamily, "long_blade",
    "NPC kill semantics receive normalized actual weapon family")
T.equal(killContext.combatWeaponSkill, "LongBlade",
    "NPC kill semantics reuse existing weapon-skill authority")
T.equal(killContext.combatSkillBand, "high",
    "NPC kill semantics receive bounded actual skill band")
T.equal(killContext.combatHitZone, "head_neck",
    "NPC kill semantics receive authoritative hit zone")
T.equal(killContext.combatWeaponDisplayName, "Machete",
    "safe actual weapon display name is available as optional flavor")
T.equal(killContext.combatMoment.weaponFullType, "Base.Machete",
    "bounded internal combat moment retains authoritative weapon provenance")
T.equal(killContext.combatMoment.woundType, "cut",
    "bounded combat moment retains authoritative wound type")
T.equal(sends[1].payload.ambientFlavor.text, "This Machete works.",
    "safe actual weapon name is substituted before player presentation")
T.falsy(string.find(
    sends[1].payload.ambientFlavor.text, "Base.", 1, true
), "internal item type never leaks through named-weapon flavor")

Service.ResetRuntime()
sends = {}
now = 16000
local hostileTarget = {
    id = "human-target",
    alive = false,
    x = 2,
    y = 0,
    z = 0,
}
local humanListeners, humanReason = Service.OnNPCHumanKill(
    records[1],
    hostileTarget,
    nil,
    {
        now = now,
        attackType = "ranged",
        attackKind = "ranged",
        weaponItem = {
            getFullType = function() return "Base.Pistol" end,
            getDisplayName = function() return "M9 Pistol" end,
        },
        weaponFullType = "Base.Pistol",
        partId = "Torso_Upper",
        woundType = "bullet",
        hostilityReason = "enemy",
    }
)
T.equal(humanListeners, 1, "hostile-human self-kill speaks to nearby player")
T.equal(humanReason, "semantic_reaction_emitted",
    "hostile-human kill uses the semantic combat reaction service")
T.equal(sends[1].reason, "hostile_npc_kill_self",
    "hostile-human kill uses a distinct event type")
local humanContext = sends[1].payload.ambientFlavor.context
T.equal(humanContext.combatMoment.targetKind, "human_npc",
    "hostile-human combat moment cannot masquerade as zombie kill")
T.equal(
    sends[1].payload.ambientFlavor.llmEligible,
    false,
    "routine hostile-human kill bark remains non-LLM"
)
T.equal(
    sends[1].payload.ambientFlavor.memoryEligible,
    false,
    "routine hostile-human kill bark remains non-memory"
)

T.finish("pnc_semantic_combat_reaction_service_smoke")
