local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local events = {}
local presentations = {}
local logs = {}
local player = {}
local victim = {
    id = "diddy-victim",
    alive = true,
    affiliation = { factionID = "diddy-club" },
}
local teammate = {
    id = "diddy-teammate",
    alive = true,
    affiliation = { factionID = "diddy-club" },
}
local follower = {
    id = "player-follower",
    alive = true,
    affiliation = { factionID = "player-faction" },
}

isServer = function() return true end
isClient = function() return false end

PNC = {
    Config = { Relationships = { EnableSocialEvents = true } },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
        LogInfo = function(message) logs[#logs + 1] = message end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:tester:character" end,
    },
    SocialEventHooksInternal = {
        WorldAgeHours = function() return 10 end,
    },
    Factions = {
        GetFactionID = function(record)
            return record and record.affiliation
                and record.affiliation.factionID or nil
        end,
        GetPlayerDiplomacyFaction = function()
            return { id = "player-faction" }
        end,
        GetMembers = function(factionID)
            T.equal(factionID, "diddy-club", "victim faction roster lookup")
            return {
                {
                    npcID = victim.id,
                    alive = true,
                    affiliation = victim.affiliation,
                },
                {
                    npcID = teammate.id,
                    alive = true,
                    affiliation = teammate.affiliation,
                },
                {
                    npcID = follower.id,
                    alive = true,
                    affiliation = follower.affiliation,
                },
            }
        end,
    },
    Registry = {
        Get = function(id)
            if id == victim.id then return victim end
            if id == teammate.id then return teammate end
            if id == follower.id then return follower end
            return nil
        end,
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
                            approval = event.type == "faction_member_attacked"
                                and 8 or 7,
                            respect = event.type == "faction_member_attacked"
                                and 7 or 6,
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

Events = {
    OnBeingHitByZombie = { Add = function() end },
    OnTick = { Add = function() end },
}

T.load("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter.lua")

local H = PNC.SocialEventHooksInternal
local applied, reason = H.RecordPlayerDamagedNPC(
    player,
    victim,
    {
        amount = 20,
        attackType = "melee",
        attackKind = "player_weapon_event",
        source = "player_weapon_event",
    }
)

T.equal(applied, true, "victim damage event applies")
T.equal(reason, "presented", "victim damage event is presented")
T.equal(#events, 2, "victim and faction teammate events are emitted")
T.equal(events[1].type, "player_damaged_npc", "victim event type")
T.equal(events[1].targetKey, "npc:diddy-victim", "victim event target")
T.equal(events[2].type, "faction_member_attacked",
    "faction teammate event type")
T.equal(events[2].targetKey, "npc:diddy-teammate",
    "faction teammate event target")
T.equal(events[2].context.victimNPCID, victim.id,
    "faction teammate event preserves victim")
T.equal(events[2].context.victimFactionID, "diddy-club",
    "faction teammate event preserves victim faction")
T.equal(events[2].context.attackerFactionID, "player-faction",
    "faction teammate event preserves attacker faction")
T.equal(events[2].context.relationshipScope, "faction_member",
    "faction teammate relationship scope")
T.equal(#presentations, 2, "victim and faction teammate arrows are presented")
T.equal(presentations[1].reason, "player_damaged_npc",
    "victim uses direct relationship presentation")
T.equal(presentations[2].reason, "faction_member_attacked",
    "teammate uses faction relationship presentation")
T.truthy(events[1].id ~= events[2].id,
    "victim and teammate events have unique IDs")

local foundFollowerDispatch = false
for _, event in ipairs(events) do
    if event.targetKey == "npc:" .. follower.id then
        foundFollowerDispatch = true
    end
end
T.falsy(foundFollowerDispatch, "player follower is not penalized")
T.contains(table.concat(logs, "\n"), "memberNPCID=player-follower",
    "follower exclusion is logged")
T.contains(table.concat(logs, "\n"), "reason=members_notified",
    "faction propagation summary is logged")

T.finish("pnc_social_faction_attack_smoke")
