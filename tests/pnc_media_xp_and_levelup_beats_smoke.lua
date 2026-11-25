-- Player-parity companion TV/VHS XP + method-aware Skill Level-Up Beats smoke test:
-- 1) Life and Living / VHS skill codes (CRP+1 = 50 XP, exact vanilla parity)
-- 2) Range (<=5 tiles, same z), guid dedupe, SandboxVars.LevelForMediaXPCutoff
-- 3) Companion still earns XP when broadcast dialogue is on cooldown
-- 4) Level-up beats adapt to earning method (tv_broadcast, combat, building, exercise, cooking, medical, survival)
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

_G.SandboxVars = {
    ProjectHoomans = { ChatterDensity = 2 },
    LevelForMediaXPCutoff = 3,
}
local simNow = 300000
_G.getGameTime = function()
    return { getWorldAgeHours = function() return 48.0 end }
end

local eventListeners = {}
_G.PNC = _G.PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.EventTypes = { NPC_SKILL_LEVEL_UP = "npc.skill_level_up" }
PNC.Events = {
    on = function(ev, fn)
        eventListeners[ev] = eventListeners[ev] or {}
        eventListeners[ev][#eventListeners[ev] + 1] = fn
    end,
    emit = function(ev, ...)
        local list = eventListeners[ev] or {}
        for i = 1, #list do list[i](...) end
    end,
}
PNC.Core = {
    Now = function() return simNow end,
    ForEachPlayer = function(fn)
        fn({
            getX = function() return 100 end,
            getY = function() return 100 end,
            getZ = function() return 0 end,
            getDescriptor = function() return { getForename = function() return "Rick" end } end,
        })
    end,
}

require "PNC/Core/Base/PNC_Sandbox"
require "PNC/Core/Skills/PNC_SkillCatalog"

-- Minimal deterministic Skills engine stub that mirrors PNC_Skills.AddXP + NPC_SKILL_LEVEL_UP
local xpLedger = {}
local levelLedger = {}
PNC.Skills = {
    CanLearn = function(rec) return rec and rec.canLearn ~= false end,
    GetLevel = function(rec, skillID)
        local m = levelLedger[rec.id]
        return (m and m[skillID]) or 0
    end,
    GetXP = function(rec, skillID)
        local m = xpLedger[rec.id]
        return (m and m[skillID]) or 0
    end,
    AddXP = function(rec, skillID, amount, opts)
        xpLedger[rec.id] = xpLedger[rec.id] or {}
        levelLedger[rec.id] = levelLedger[rec.id] or {}
        local curXP = (xpLedger[rec.id][skillID] or 0) + amount
        local curLvl = levelLedger[rec.id][skillID] or 0
        local leveledUp = false
        while curXP >= 75 and curLvl < 10 do
            curXP = curXP - 75
            curLvl = curLvl + 1
            leveledUp = true
        end
        xpLedger[rec.id][skillID] = curXP
        levelLedger[rec.id][skillID] = curLvl
        if leveledUp then
            PNC.Events.emit(PNC.EventTypes.NPC_SKILL_LEVEL_UP, rec, skillID, curLvl, {
                source = opts and opts.source or nil,
                showName = opts and opts.showName or nil,
            })
        end
        return true
    end,
}

require "PNC/Semantics/PNC_SemanticDialogueBeats"

local Beats = PNC.Semantics.DialogueBeats
local Dir = PNC.Semantics.ConversationDirector

local nearNPC = { id = "n_near", name = "Maya", alive = true, presenceState = "live", x = 102, y = 100, z = 0, social = { personality = { socialStyle = "warm", sociability = 0.85 } } }
local allyNPC = { id = "n_ally", name = "Cole", alive = true, presenceState = "live", x = 103, y = 100, z = 0, social = { personality = { socialStyle = "practical", sociability = 0.65 } } }
local farNPC  = { id = "n_far",  name = "Far",  alive = true, presenceState = "live", x = 112, y = 100, z = 0 }
local upstairsNPC = { id = "n_up", name = "Up", alive = true, presenceState = "live", x = 101, y = 100, z = 1 }
local cappedNPC = { id = "n_cap", name = "Cap", alive = true, presenceState = "live", x = 101, y = 101, z = 0 }
levelLedger["n_cap"] = { Carpentry = 3 }

local allNPCs = { nearNPC, allyNPC, farNPC, upstairsNPC, cappedNPC }
PNC.SpatialIndex = { QueryNPCs = function() return allNPCs end }
PNC.Perception = {
    GetTeamKey = function() return "squad_tv" end,
    GetActiveSkirmish = function() return nil end,
    AreWarningAllies = function() return true end,
}
PNC.Registry = {
    Get = function(id)
        for i = 1, #allNPCs do
            if allNPCs[i].id == id then return allNPCs[i] end
        end
        return nil
    end,
}

local delivered = {}
PNC.Semantics.SpeechTransport.ResolveLine = function(_, spec)
    local tok = type(spec) == "table" and spec.tokens or {}
    return tostring(spec and spec.poolID or "")
        .. "|" .. tostring(spec and spec.role or "")
        .. "|" .. tostring(tok["slot.skill.name"] or "")
        .. "|" .. tostring(tok["slot.show.name"] or ""), { poolID = spec and spec.poolID }
end
PNC.Semantics.SpeechTransport.Deliver = function(speaker, _, opts)
    delivered[#delivered + 1] = {
        speaker = speaker and speaker.id or nil,
        text = opts and opts.text or "",
        topic = opts and opts.topic or "",
    }
    return true
end

local tv = {
    isTelevision = true,
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    getDeviceData = function()
        return {
            getIsTelevision = function() return true end,
            getIsTurnedOn = function() return true end,
            getChannel = function() return 203 end, -- Life and Living TV
            isEmergencyBroadcast = function() return false end,
            getMediaData = function() return nil end,
        }
    end,
}

-- 1) First Woodcraft line (CRP+1 -> 50 XP, exact vanilla parity)
Beats.ResetRuntime()
Beats.OnDeviceTextEvent("guid:wc:1", "CRP+1", 100, 100, 0, "Welcome to Woodcraft!", tv, simNow)
T.equal(PNC.Skills.GetXP(nearNPC, "Carpentry"), 50, "nearby companion earns 50 Carpentry XP on CRP+1")
T.equal(PNC.Skills.GetXP(farNPC, "Carpentry"), 0, "companion >5 tiles away earns 0 TV XP")
T.equal(PNC.Skills.GetXP(upstairsNPC, "Carpentry"), 0, "companion on different floor earns 0 TV XP")
T.equal(PNC.Skills.GetXP(cappedNPC, "Carpentry"), 0, "companion at LevelForMediaXPCutoff earns 0 TV XP")

-- 2) Duplicate guid does not double-award XP
Beats.OnDeviceTextEvent("guid:wc:1", "CRP+1", 100, 100, 0, "Welcome to Woodcraft!", tv, simNow + 500)
T.equal(PNC.Skills.GetXP(nearNPC, "Carpentry"), 50, "duplicate media line guid does not double-award XP")

-- 3) Second unique Woodcraft line 2s later (dialogue debounced, but XP STILL awarded -> levels up to 1!)
delivered = {}
Beats.OnDeviceTextEvent("guid:wc:2", "CRP+1", 100, 100, 0, "Measure twice, cut once on Woodcraft!", tv, simNow + 2000)
T.equal(PNC.Skills.GetLevel(nearNPC, "Carpentry"), 1, "second Woodcraft line awards 50 XP and levels Carpentry to 1")
T.equal(PNC.Skills.GetXP(nearNPC, "Carpentry"), 25, "remaining XP carries over (100 - 75 = 25)")

for step = 1, 8 do
    simNow = simNow + 800
    Beats.Pump(simNow)
end
local sawTvLevelUp = false
for i = 1, #delivered do
    if string.find(delivered[i].text, "semantic.progression.level_up|tv_broadcast_open|Carpentry|Woodcraft", 1, true) then
        sawTvLevelUp = true
    end
end
T.truthy(sawTvLevelUp, "TV level-up emits tv_broadcast_open grounded in Carpentry and Woodcraft")

-- 4) Method-aware level-ups across combat, building, exercise, cooking, medical, survival
local methodCases = {
    { skill = "LongBlunt", meta = { source = "combat" },   expectRole = "combat_open",   expectSkill = "Long Blunt" },
    { skill = "Carpentry", meta = { source = "building" }, expectRole = "building_open", expectSkill = "Carpentry" },
    { skill = "Fitness",   meta = { source = "exercise" }, expectRole = "exercise_open", expectSkill = "Fitness" },
    { skill = "Cooking",   meta = { source = "cooking" },  expectRole = "cooking_open",  expectSkill = "Cooking" },
    { skill = "FirstAid",  meta = { source = "medical" },  expectRole = "medical_open",  expectSkill = "First Aid" },
    { skill = "Fishing",   meta = { source = "survival" }, expectRole = "survival_open", expectSkill = "Fishing" },
}
for idx = 1, #methodCases do
    local mc = methodCases[idx]
    Dir.ResetRuntime()
    Beats.ResetRuntime()
    delivered = {}
    simNow = simNow + 40000
    local ok = Beats.OnNPCSkillLevelUp(nearNPC, mc.skill, 2, mc.meta, simNow)
    T.equal(ok, true, "level-up beat emitted for method " .. mc.meta.source)
    Beats.Pump(simNow + 1500)
    T.truthy(#delivered >= 1, "level-up line delivered for " .. mc.meta.source)
    T.contains(delivered[1].text, mc.expectRole .. "|" .. mc.expectSkill,
        "method " .. mc.meta.source .. " resolves " .. mc.expectRole .. " with " .. mc.expectSkill)
end

print("pnc_media_xp_and_levelup_beats_smoke: OK")
