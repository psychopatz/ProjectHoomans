-- Compositional Stance Exchange + Epistemic Factual Queries (Watch-Aware Time
-- & Non-Colonist Inventory Skeptic Gate) smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

_G.PNC = _G.PNC or {}
PNC.Const = { MODULE = "PNC", CMD_SEMANTIC_INVENTORY_QUERY_RESULT = "inv_res", PRESENCE_LIVE = "live" }
PNC.Core = { Now = function() return 500000 end, IsAuthority = function() return true end }

require "PNC/Semantics/PNC_ConversationDirector"
local Stance = PNC.Semantics.StanceAlignment

-- 1) Universal Compositional Stance Action resolution (Layer 1 scaling)
T.equal(Stance.ResolveCompositionalAction("aligned", "compassion"), "aligned_compassion", "compassion aligned action")
T.equal(Stance.ResolveCompositionalAction("clashed", "caution"), "clashed_caution", "caution clashed action")
T.equal(Stance.ResolveCompositionalAction("respected_clash", "caution"), "respected_clash", "respected_clash preserved")
T.equal(Stance.ResolveCompositionalAction("diplomatic", "social"), "diplomatic", "diplomatic preserved")

-- 2) Watch-aware Time query (exact time with watch vs sky estimate without watch)
PNC.ConvoEngine = PNC.ConvoEngine or {}
PNC.ConvoEngine.LocalResponse = PNC.ConvoEngine.LocalResponse or {
    Internal = {
        CopyArgs = function(t) return t end,
        CatalogResponse = function() return nil end,
        ClockText = function(w)
            return string.format("It's %02d:%02d.", w.time.hour, w.time.minute)
        end,
        DayText = function() return "Day 1" end,
        WeatherText = function() return "Clear" end,
        IdentityText = function() return "Maya" end,
        IdentityKnown = function() return true end,
    },
}
require "PNC/ConvoEngine/Dialogue/LocalResponse_Questions_Observations"
local ResolveTime = PNC.ConvoEngine.LocalResponse.Internal.ResolveTime

local world = { time = { hour = 15, minute = 20 }, gameDay = 3 }
local npcWithWatch = {
    id = "w1",
    equipment = { wrist = { fullType = "Base.WristWatch_Right_ClassicBlack" } },
}
local npcNoWatch = {
    id = "w2",
    equipment = { weapon = { fullType = "Base.BaseballBat" } },
    inventory = { items = { { fullType = "Base.Bandage" } } },
}

local resExact = ResolveTime(world, { npcRecord = npcWithWatch })
T.equal(resExact.args.hasWatch, true, "NPC wearing a watch reports hasWatch=true")
T.equal(resExact.args.estimated, false, "NPC with watch gives exact time")
T.contains(resExact.fallback, "15:20", "exact time includes 15:20")

local resEst = ResolveTime(world, { npcRecord = npcNoWatch })
T.equal(resEst.args.hasWatch, false, "NPC without watch reports hasWatch=false")
T.equal(resEst.args.estimated, true, "NPC without watch estimates time")
T.equal(resEst.args.isDark, false, "15:20 is daytime sun estimate")
T.contains(resEst.fallback, "mid-afternoon", "15:20 without watch estimates mid-afternoon")

local resNoon = ResolveTime({ time = { hour = 12, minute = 30 }, gameDay = 3 }, { npcRecord = npcNoWatch })
T.contains(resNoon.fallback, "around noon", "12:30 without watch estimates around noon by the sun")

local resNight = ResolveTime({ time = { hour = 2, minute = 15 }, gameDay = 3 }, { npcRecord = npcNoWatch })
T.equal(resNight.args.isDark, true, "02:15 is nighttime estimate")
T.contains(resNight.fallback, "past midnight", "02:15 without watch estimates past midnight")

-- Verify canonical PNC.Inventory.EnsureRecordInventory delta hydration + revision cache invalidation
local hydratedInv = { revision = 1, items = { { fullType = "Base.Bandage" } } }
local hydrateCalls = 0
PNC.Inventory = {
    EnsureRecordInventory = function()
        hydrateCalls = hydrateCalls + 1
        return hydratedInv
    end,
}
local deltaNPC = { id = "w_delta", runtime = {} } -- record.inventory intentionally nil (delta-compressed)
local resDelta1 = ResolveTime(world, { npcRecord = deltaNPC })
T.equal(resDelta1.args.hasWatch, false, "delta-hydrated NPC without watch estimates time")
T.equal(hydrateCalls, 1, "EnsureRecordInventory hydrated compressed NPC inventory")
-- Add watch & bump revision -> cache invalidates automatically
hydratedInv.items[2] = { fullType = "Base.DigitalWatch_Red" }
hydratedInv.revision = 2
local resDelta2 = ResolveTime(world, { npcRecord = deltaNPC })
T.equal(resDelta2.args.hasWatch, true, "revision bump invalidates watch cache and detects newly acquired watch")
PNC.Inventory = nil

-- 3) Non-colonist Inventory Skeptic Gate (colonists always allowed; skeptical strangers gated by trust)
local relMap = {}
PNC.Relationships = {
    Get = function(obsId, targetKey) return relMap[tostring(obsId) .. "->" .. tostring(targetKey)] end,
}
local colonist = { id = "c1", alive = true, ownerUsername = "Rick", social = { personality = { socialStyle = "guarded" } } }
local skepticStranger = { id = "s1", alive = true, social = { personality = { socialStyle = "guarded" } } }
PNC.Registry = {
    Get = function(id)
        if id == "c1" then return colonist end
        if id == "s1" then return skepticStranger end
        return nil
    end,
}
PNC.Conversation = { Authority = { Internal = { ValidateLease = function() return true end } } }
PNC.Semantics.InventoryQueryService = {
    Internal = {
        Contract = { Normalize = function(r) return r end },
        Diagnostics = { IsEnabled = function() return false end },
        CopyValue = function(v) return v end,
    },
    Query = function() return { status = "found", items = { { fullType = "Base.TinnedBeans", count = 2 } }, totalCount = 2, distinctItems = 1 } end,
}
require "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService_Request"
local InvSvc = PNC.Semantics.InventoryQueryService

local function makePlayerCtx()
    return { player = { username = "Rick" }, conversationToken = "tok1" }
end
local colRes = InvSvc.HandleRequest({ npcID = "c1", requestID = "r1", query = { mode = "all" } }, makePlayerCtx())
T.equal(colRes.accepted, true, "colonist/companion always grants full inventory visibility even if guarded")

local skepRefused = InvSvc.HandleRequest({ npcID = "s1", requestID = "r2", query = { mode = "all" } }, makePlayerCtx())
T.equal(skepRefused.status, "refused", "skeptical non-colonist with low trust refuses inventory check")
T.equal(skepRefused.reason, "inventory_skeptic_refused", "refusal reason is inventory_skeptic_refused")
T.truthy(type(skepRefused.refusedText) == "string" and #skepRefused.refusedText > 0, "skeptic refusal includes grounded line")

relMap["s1->player:Rick"] = { approval = 30, respect = 10 }
local skepTrusted = InvSvc.HandleRequest({ npcID = "s1", requestID = "r3", query = { mode = "all" } }, makePlayerCtx())
T.equal(skepTrusted.accepted, true, "skeptical non-colonist shares inventory once trust >= 25 approval is earned")

-- 4) PsychopatzCore.TimeFormat: client 24h (army clock) vs 12h (AM/PM) setting
package.path = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path
local TimeFormat = require "PsychopatzCore/Text/PsychopatzTimeFormat"
local clock24Setting = true
_G.getCore = function()
    return { getOptionClock24Hour = function() return clock24Setting end }
end
T.equal(TimeFormat.FormatClockSentence(15, 20), "It's 15:20.", "24h army clock formats 15:20")
T.equal(TimeFormat.FormatClockSentence(0, 5), "It's 00:05.", "24h army clock formats 00:05")
clock24Setting = false
T.equal(TimeFormat.FormatClockSentence(15, 20), "It's 3:20 PM.", "12h AM/PM clock formats 3:20 PM")
T.equal(TimeFormat.FormatClockSentence(0, 5), "It's 12:05 AM.", "12h AM/PM clock formats 12:05 AM")
T.equal(TimeFormat.FormatClockSentence(12, 0), "It's 12:00 PM.", "12h AM/PM clock formats 12:00 PM")
T.equal(TimeFormat.FormatDate(1993, 7, 12), "July 12, 1993", "FormatDate formats calendar date")
T.equal(TimeFormat.FormatDateSentence(1993, 7, 12), "It's July 12, 1993.", "FormatDateSentence formats sentence")
T.equal(TimeFormat.FormatDateSentence(nil, nil, nil, 5), "It's day 5.", "FormatDateSentence falls back to gameDay")
T.equal(TimeFormat.FormatDateTime(1993, 7, 12, 15, 20, { gameDay = 4, use24Hour = true }), "July 12, 1993 (Day 4, 15:20)", "FormatDateTime 24h with gameDay")
T.equal(TimeFormat.FormatDateTime(1993, 7, 12, 15, 20, { use24Hour = false }), "July 12, 1993, 3:20 PM", "FormatDateTime 12h AM/PM")
T.equal(TimeFormat.FormatISO(1993, 7, 12, 15, 20), "1993-07-12T15:20:00", "FormatISO formats strict ISO-8601")
T.equal(TimeFormat.FormatDayClock(1440 * 2 + 15 * 60 + 20, { use24Hour = true }), "D3 15:20", "FormatDayClock 24h")
T.equal(TimeFormat.FormatDayClock(1440 * 2 + 15 * 60 + 20, { use24Hour = false }), "D3 3:20 PM", "FormatDayClock 12h")
T.equal(TimeFormat.ResolveTimeBand(6), "dawn", "ResolveTimeBand 6 is dawn")
T.equal(TimeFormat.ResolveTimeBand(22), "night", "ResolveTimeBand 22 is night")
T.equal(TimeFormat.FormatRelativeHours(0.5), "just now", "FormatRelativeHours <1h")
T.equal(TimeFormat.FormatRelativeHours(30), "yesterday", "FormatRelativeHours 30h is yesterday")
T.equal(PsychopatzCore.DateTime, TimeFormat, "PsychopatzCore.DateTime alias points to TimeFormat")

print("pnc_epistemic_factual_and_compositional_stance_smoke: OK")
