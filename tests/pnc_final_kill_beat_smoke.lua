-- Final-Kill & Post-Skirmish Relief / Applause beat smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 400000
local spoken = {}
local relEffects = {}
local storyMoments = {}

local soloComp = {
    id = "npc_solo", name = "Daryl", alive = true, presenceState = "live",
    x = 10, y = 10, z = 0, tacticalClass = "colonist", recruited = true,
    health = { hp = 100 }, runtime = {},
}
local squadSlayer = {
    id = "npc_sq1", name = "Meghan", alive = true, presenceState = "live",
    x = 30, y = 30, z = 0, tacticalClass = "colonist", recruited = true,
    ownerOnlineID = 1, health = { hp = 100 }, runtime = {},
}
local squadAlly1 = {
    id = "npc_sq2", name = "Rory", alive = true, presenceState = "live",
    x = 31, y = 30, z = 0, tacticalClass = "colonist", recruited = true,
    ownerOnlineID = 1, health = { hp = 100 }, runtime = {},
}
local squadAlly2 = {
    id = "npc_sq3", name = "Wilfredo", alive = true, presenceState = "live",
    x = 32, y = 30, z = 0, tacticalClass = "colonist", recruited = true,
    ownerOnlineID = 1, health = { hp = 50, bleeding = true }, runtime = {},
}
local guard1 = {
    id = "npc_g1", name = "Sarge", alive = true, presenceState = "live",
    x = 80, y = 80, z = 0, archetypeID = "guard", affiliation = { factionID = "fac_guard", role = "guard" },
    health = { hp = 100 }, runtime = {},
}
local guard2 = {
    id = "npc_g2", name = "Corp", alive = true, presenceState = "live",
    x = 81, y = 80, z = 0, archetypeID = "guard", affiliation = { factionID = "fac_guard", role = "guard" },
    health = { hp = 100 }, runtime = {},
}
local traderSolo = {
    id = "npc_tr", name = "Merchant", alive = true, presenceState = "live",
    x = 120, y = 120, z = 0, archetypeID = "trader", isTrader = true,
    health = { hp = 100 }, runtime = {},
}
local bandit1 = {
    id = "npc_b1", name = "Viper", alive = true, presenceState = "live",
    x = 160, y = 160, z = 0, tacticalClass = "hostile", isHostile = true,
    affiliation = { factionID = "fac_raiders" }, health = { hp = 100 }, runtime = {},
}
local bandit2 = {
    id = "npc_b2", name = "Razor", alive = true, presenceState = "live",
    x = 161, y = 160, z = 0, tacticalClass = "hostile", isHostile = true,
    affiliation = { factionID = "fac_raiders" }, health = { hp = 100 }, runtime = {},
}
local neutralSolo = {
    id = "npc_neu", name = "Sam", alive = true, presenceState = "live",
    x = 200, y = 200, z = 0, health = { hp = 45, bleeding = true }, runtime = {},
}

local player = {
    x = 30.5, y = 30, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getOnlineID = function() return 1 end,
    getDisplayName = function() return "Rick" end,
    getUsername = function() return "Rick" end,
}

local allRecords = { soloComp, squadSlayer, squadAlly1, squadAlly2, guard1, guard2, traderSolo, bandit1, bandit2, neutralSolo }

_G.PNC = {
    Core = { Now = function() return simNow end, NowWorldAgeHours = function() return 24 end },
    Const = { PRESENCE_LIVE = "live" },
    Registry = {
        Get = function(id)
            for _, r in ipairs(allRecords) do
                if tostring(r.id) == tostring(id) then return r end
            end
            return nil
        end,
        ForEach = function(fn) for _, r in ipairs(allRecords) do fn(r) end end,
    },
    Perception = {
        GetTeamKey = function(rec)
            if rec.affiliation and rec.affiliation.factionID then return "faction:" .. rec.affiliation.factionID end
            if rec.ownerOnlineID then return "owner:" .. tostring(rec.ownerOnlineID) end
            return "actor:" .. tostring(rec.id)
        end,
    },
    Relationships = {
        ApplyConversationEffect = function(actorId, targetKey, eff)
            relEffects[#relEffects + 1] = { actorId = actorId, targetKey = targetKey, approval = eff.approval, respect = eff.respect }
            return true
        end,
    },
    Semantics = {
        DialogueBeats = {},
        ConversationDirector = {
            EvaluateCandidate = function() return true end,
            MarkSpoken = function() end,
            RecordStoryMoment = function(tk, m) storyMoments[#storyMoments + 1] = { tk = tk, kind = m.kind, intensity = m.meta.intensity } end,
        },
        SpeechTransport = {
            ResolveLine = function(speaker, spec)
                return tostring(speaker.id) .. ":" .. tostring(spec.role) .. ":" .. tostring(spec.tokens["addressee.name"])
                    .. ":" .. tostring(spec.tokens["slot.injured.name"]), { poolID = spec.poolID }
            end,
            Deliver = function(speaker, at, opts)
                spoken[#spoken + 1] = { id = speaker.id, at = at, text = opts.text }
                return 1
            end,
        },
    },
}

require "PNC/Semantics/Beats/PNC_SemanticBeats_FinalKill"
local Beats = PNC.Semantics.DialogueBeats

-- 1) Zero-overhead idle tick
T.equal(Beats.TickFinalKillResolutions(simNow), 0, "idle tick returns 0 immediately")

-- 2) Solo NPC multi-kill settle timer (3 kills -> couple, only fires 2.2s after LAST kill)
spoken = {}
Beats.ObserveCombatKill(soloComp, "zombie", simNow)
Beats.ObserveCombatKill(soloComp, "zombie", simNow + 1000)
Beats.ObserveCombatKill(soloComp, "zombie", simNow + 2000)
T.equal(Beats.TickFinalKillResolutions(simNow + 3000), 0, "does not fire before settle window after last kill")
T.equal(Beats.TickFinalKillResolutions(simNow + 4300), 1, "fires once after final kill settles")
T.equal(#spoken, 1, "solo NPC emits 1 expression")
T.truthy(string.find(spoken[1].text, "npc_solo:solo_couple:", 1, true) ~= nil, "solo NPC uses solo_couple role")

-- 3) Squad NPC slayer + wounded member -> ally applause + slayer reply + relief chime + relationship + StoryRecall
spoken, relEffects, storyMoments = {}, {}, {}
simNow = simNow + 50000
Beats.ObserveCombatKill(squadSlayer, "zombie", simNow)
Beats.ObserveCombatKill(squadSlayer, "zombie", simNow + 500)
Beats.TickFinalKillResolutions(simNow + 3000)
T.equal(#spoken, 3, "wounded close-call squad emits 3-turn beat (ally applaud + slayer reply + relief chime)")
T.truthy(string.find(spoken[1].text, "npc_sq2:ally_wounded_relief:Meghan:Wilfredo", 1, true) ~= nil,
    "ally applauds slayer Meghan and names wounded Wilfredo")
T.truthy(string.find(spoken[2].text, "npc_sq1:slayer_reply_wounded:Rory", 1, true) ~= nil,
    "slayer replies to Rory")
T.truthy(string.find(spoken[3].text, "npc_sq3:ally_relief_wounded_chime:", 1, true) ~= nil,
    "third ally adds relief chime")
T.truthy(#relEffects == 1 and relEffects[1].approval == 2, "heavy close-call grants +2 approval")
T.truthy(#storyMoments == 1 and storyMoments[1].intensity == "wounded_close_call", "records StoryRecall moment")

-- 4) Actor-agnostic Player slayer on horde (>= 4 kills, no wounded)
squadAlly2.health.bleeding = false
squadAlly2.health.hp = 100
spoken, relEffects = {}, {}
simNow = simNow + 50000
for i = 1, 4 do
    Beats.ObserveCombatKill(player, "zombie", simNow + (i * 300), { isPlayer = true })
end
Beats.TickFinalKillResolutions(simNow + 4000)
T.truthy(#spoken >= 2, "player horde final kill triggers ally applause + relief chime")
T.truthy(string.find(spoken[1].text, "ally_applaud_horde:Rick", 1, true) ~= nil, "ally applauds player Rick for horde kill")
T.truthy(#relEffects == 1 and relEffects[1].targetKey == "player:1", "relationship boost targets player:1")

-- 5) Archetype flavors: guard squad, solo trader (horde), hostile bandit squad, wounded neutral
spoken = {}
simNow = simNow + 50000
Beats.ObserveCombatKill(guard1, "zombie", simNow)
Beats.ObserveCombatKill(guard1, "zombie", simNow + 200)
Beats.ObserveCombatKill(traderSolo, "hostile_human", simNow)
Beats.ObserveCombatKill(bandit1, "hostile_human", simNow)
Beats.ObserveCombatKill(neutralSolo, "zombie", simNow)
Beats.TickFinalKillResolutions(simNow + 3000)

local sawGuard, sawTrader, sawHostile, sawNeutral = false, false, false, false
for _, s in ipairs(spoken) do
    if string.find(s.text, "npc_g2:ally_guard_clear:Sarge", 1, true) then sawGuard = true end
    if string.find(s.text, "npc_tr:solo_trader_heavy:", 1, true) then sawTrader = true end
    if string.find(s.text, "npc_b2:ally_hostile_bravado:Viper", 1, true) then sawHostile = true end
    if string.find(s.text, "npc_neu:solo_neutral_wounded:", 1, true) then sawNeutral = true end
end
T.equal(sawGuard, true, "guard archetype uses ally_guard_clear")
T.equal(sawTrader, true, "trader archetype uses solo_trader_heavy")
T.equal(sawHostile, true, "hostile archetype uses ally_hostile_bravado")
T.equal(sawNeutral, true, "neutral archetype uses solo_neutral_wounded")

print("pnc_final_kill_beat_smoke: OK")
