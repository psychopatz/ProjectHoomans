local T = require "tests/support/test"

T.addPackagePaths()

local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local Lexicon = require "PNC/ConvoEngine/Lexicon"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"

-- 1. Deferred streaming (Tier 0 sync + Tier 1 incremental + Tier 2 on-demand flush).
local deferredDiag = ConvoDSL.Reload("EN", { deferStream = true })
T.equal(deferredDiag.language, "EN", "loaded language is EN")
T.truthy(deferredDiag.lexCount >= 20, "Tier 0 loaded EN lexicons synchronously")
T.truthy(deferredDiag.blueprintCount >= 2, "Tier 0 loaded EN blueprints synchronously")
T.truthy(ConvoDSL.PendingCount() >= 20, "Tier 1 queued remaining .convo files for incremental streaming")

local stepped = ConvoDSL.StepStream(2, 0)
T.equal(stepped, 2, "StepStream(2) processes exactly 2 files")
T.truthy(ConvoDSL.PendingCount() >= 18, "remaining files stay queued after 1 tick step")

-- Tier 2 on-demand flush via Catalog.Select drains pending queue automatically.
local alarmPick = Catalog.Select("semantic.world.alarm.react", { npcID = "npc_1" }, "en_salt")
T.truthy(alarmPick ~= nil, "Tier 2 on-demand flush loaded semantic.world.alarm.react")
T.equal(ConvoDSL.PendingCount(), 0, "queue drained cleanly after on-demand flush")

local fullDiag = ConvoDSL.GetDiagnostics()
T.equal(#fullDiag.errors, 0, "zero parse errors across all EN .convo packs: " .. table.concat(fullDiag.errors, "; "))
T.truthy(#fullDiag.filesLoaded >= 100, "loaded all modular EN .convo files (got " .. tostring(#fullDiag.filesLoaded) .. ")")

-- 1b. Composable sleep dialogue in needs/needs_sleep.convo expands cleanly with zero raw tokens.
local sleepPick = Catalog.Select("semantic.companion.moodle_suggest", {
    npcID = "npc_1",
    combatReactionRole = "suggest_sleep",
    socialStyle = "warm",
    isNightOrDusk = true,
}, "sleep_salt")
T.truthy(sleepPick ~= nil, "composable sleep suggestion selected")
local sleepLine = Lexicon.Expand(sleepPick.fallback, {
    npcID = "npc_1",
    socialStyle = "warm",
    isNightOrDusk = true,
}, { ["addressee.name"] = "Pat" }, { salt = "sleep_salt" })
T.truthy(type(sleepLine) == "string" and #sleepLine > 15 and not string.find(sleepLine, "{", 1, true),
    "composable sleep line expanded cleanly: " .. tostring(sleepLine))

-- 1c. `extend lex` and `extend blueprint` merge non-destructively.
local extScript, extErr = ConvoDSL.ParseText([[
lang EN
namespace hoomans
pack community_sleep_plus

extend lex sleep.observe
  [actor.style=tactical] (pri 11): "Your reaction time is tanking"

extend blueprint offer.social_repair
  offer repair.fistbump:
    label: "Offer a truce"
    say: "We're good—let's keep moving."
    intent: INFORM
    subject: SOCIAL
]], "community_sleep_plus.convo", "EN")
T.truthy(extScript ~= nil, "extend lex/blueprint parsed cleanly: " .. tostring(extErr))
ConvoDSL.ApplyScripts({ extScript }, "EN")
local tacticalSleep = Lexicon.Pick("sleep.observe", { npcID = "npc_1", speakerStyle = "tactical" }, "s1", "EN")
T.equal(tacticalSleep, "Your reaction time is tanking", "extend lex appended high-priority tactical entry")
local defaultSleep = Lexicon.Pick("sleep.observe", { npcID = "npc_1", speakerStyle = "neutral" }, "s1", "EN")
T.truthy(type(defaultSleep) == "string" and defaultSleep ~= "Your reaction time is tanking",
    "extend lex preserved base EN entries")
local repairBp = PNC.ConvoEngine.OfferBlueprints["offer.social_repair"]
T.truthy(type(repairBp) == "table" and #repairBp >= 2, "extend blueprint appended offer without clobbering base")

-- 2. Community language pack + theme `extend` + broken pack error containment.
local origGetMods = rawget(_G, "getActivatedMods")
local origList = rawget(_G, "listFilesInModDirectory")
local origReader = rawget(_G, "getModFileReader")

local function javaList(items)
    return {
        size = function() return #items end,
        get = function(_, idx) return items[idx + 1] end,
    }
end

local function stringReader(content)
    local lines = {}
    for line in string.gmatch(content .. "\n", "(.-)\n") do
        lines[#lines + 1] = line
    end
    local pos = 0
    return {
        readLine = function()
            pos = pos + 1
            return lines[pos]
        end,
        close = function() end,
    }
end

local fakeCommunityTLLex = [[
# Community Tagalog lexicon
lang TL
namespace hoomans

lex noun.zombie
  [default]: "zombi" | "patay"
]]

local fakeCommunityTLTheme = [[
# Community Tagalog theme extension
lang TL
namespace hoomans
theme winter_survival

extend semantic.world.alarm.react
  say [env.snowing] (pri 12):
    "Narinig mo yun? Parating na yung mga {noun.zombie} sa gitna ng niyebe!"
]]

local fakeBrokenPack = [[
beat semantic.broken.demo
  say [typo.predicate=true]:
    "Should fail gracefully."
]]

rawset(_G, "getActivatedMods", function()
    return javaList({ "ProjectHoomans", "CommunityTagalogPack", "BrokenPackMod" })
end)

rawset(_G, "listFilesInModDirectory", function(modID, relDir)
    if modID == "CommunityTagalogPack" and relDir == "media/translation/TL/ConvoBlocks/lexicons" then
        return javaList({ "tl_lexicon.convo" })
    end
    if modID == "CommunityTagalogPack" and relDir == "media/translation/TL/ConvoBlocks/themes" then
        return javaList({ "winter_theme.convo", "README.txt" })
    end
    if modID == "BrokenPackMod" and relDir == "media/translation/TL/ConvoBlocks" then
        return javaList({ "broken.convo" })
    end
    return origList(modID, relDir)
end)

rawset(_G, "getModFileReader", function(modID, relPath, createIfNull)
    if modID == "CommunityTagalogPack" and relPath == "media/translation/TL/ConvoBlocks/lexicons/tl_lexicon.convo" then
        return stringReader(fakeCommunityTLLex)
    end
    if modID == "CommunityTagalogPack" and relPath == "media/translation/TL/ConvoBlocks/themes/winter_theme.convo" then
        return stringReader(fakeCommunityTLTheme)
    end
    if modID == "BrokenPackMod" and relPath == "media/translation/TL/ConvoBlocks/broken.convo" then
        return stringReader(fakeBrokenPack)
    end
    return origReader(modID, relPath, createIfNull)
end)

local origManager = rawget(_G, "CustomTranslationManager")
rawset(_G, "CustomTranslationManager", {
    getLanguage = function() return "TL" end,
})

-- Snowing context hits the `extend` themed variant with auto-namespaced ID `winter_survival.v1`.
local snowPick = Catalog.Select("semantic.world.alarm.react", { npcID = "npc_1", worldContext = { weather = { snowing = true } } }, "tl_salt")
T.truthy(snowPick ~= nil, "TL extended theme variant selected")
T.equal(snowPick.id, "semantic.world.alarm.react.winter_survival.v1", "extend auto-namespaced variant ID by theme")

local expanded = Lexicon.Expand(snowPick.fallback, { npcID = "npc_1" }, {}, { salt = "tl_salt" })
T.truthy(
    string.find(expanded, "zombi", 1, true) ~= nil or string.find(expanded, "patay", 1, true) ~= nil,
    "TL lexicon expanded in active language: " .. tostring(expanded)
)

-- Non-snowing context still falls back to the preserved base EN variants (extend is non-destructive!).
local clearPick = Catalog.Select("semantic.world.alarm.react", { npcID = "npc_1", worldContext = { weather = { snowing = false } } }, "tl_salt")
T.truthy(clearPick ~= nil and clearPick.id ~= snowPick.id, "extend preserved base pool variants")

-- Untranslated lex keys fall back to EN automatically.
T.truthy(Lexicon.Has("noun.road", "TL"), "untranslated lex key falls back to EN")

-- Broken community pack recorded a diagnostic error without crashing.
local tlDiag = ConvoDSL.GetDiagnostics()
T.equal(tlDiag.language, "TL", "active diagnostics reflect TL")
T.truthy(tlDiag.extendedCount >= 3, "tracked production + community pool extensions (got " .. tostring(tlDiag.extendedCount) .. ")")
T.equal(#tlDiag.errors, 1, "broken community .convo recorded 1 non-fatal error")
T.contains(tlDiag.errors[1], "unknown context predicate 'typo.predicate'", "error reports exact predicate typo")

-- Switching back to EN evicts unused TL lexicon pack from memory.
rawset(_G, "CustomTranslationManager", origManager)
rawset(_G, "getActivatedMods", origGetMods)
rawset(_G, "listFilesInModDirectory", origList)
rawset(_G, "getModFileReader", origReader)
ConvoDSL.Reload("EN")
T.equal(Lexicon.Packs.TL, nil, "switching away from TL evicted unused TL lexicon pack")

T.finish("pnc_convo_dsl_runtime_loader_smoke")
print("pnc_convo_dsl_runtime_loader_smoke: ok")
