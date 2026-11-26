local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

local ROOT = "tools/providers/pnc/codebuilder/sources/conversation"

-- 1. Validate declarative JSON definitions, EN/TL parity, placeholders, and static voice guard
--    using Python (json + re) so we don't depend on external Lua JSON libraries.
local pyCheck = [[python3 -c '
import json, os, re

root = "tools/providers/pnc/codebuilder/sources/conversation"
families = [
    ("chronology_milestone_react.json", "chronology.milestone.react", [
        "first_week_steady", "first_week_warm", "first_week_guarded",
        "first_month_steady", "first_month_warm", "first_month_guarded",
        "first_season_steady", "first_season_warm", "first_season_guarded",
        "first_year_steady", "first_year_warm", "first_year_guarded",
        "anniversary_steady", "anniversary_warm", "anniversary_guarded",
    ]),
    ("world_event_food_crisis.json", "world.event.food_crisis", [
        "experienced", "rumor", "uncertain", "reply",
    ]),
    ("world_event_raider_surge.json", "world.event.raider_surge", [
        "experienced", "witnessed", "rumor", "uncertain", "reply",
    ]),
    ("world_event_surplus.json", "world.event.surplus", [
        "experienced", "rumor", "uncertain", "reply",
    ]),
]

allowed_placeholders = {
    "addressee.name", "speaker.name", "scene.location", "scene.clock",
    "slot.show.name", "show.name",
}
placeholder_re = re.compile(r"\{([^}]+)\}")
jargon_re = re.compile(
    r"\b(?:NPCs?|UI|ModData|payload|cooldown|slot|debug|fallback|system error|invalid target|TODO|FIXME|placeholder)\b",
    re.IGNORECASE,
)

for fn, fam_id, expected_variants in families:
    def_path = os.path.join(root, "dialogue/world_event_beats", fn)
    assert os.path.isfile(def_path), f"Missing def: {def_path}"
    with open(def_path, "r", encoding="utf-8") as f:
        d = json.load(f)
    assert d.get("schema") == "psychopatz.convo-engine.v1", f"Bad schema in {fn}"
    assert d.get("id") == fam_id, f"Bad id in {fn}"
    var_ids = [v["id"] for v in d.get("say", {}).get("variants", [])]
    for ev in expected_variants:
        assert ev in var_ids, f"Missing variant {ev} in {fn}"

    for loc in ("EN", "TL"):
        tr_path = os.path.join(root, "translations", loc, "dialogue/world_event_beats", fn)
        assert os.path.isfile(tr_path), f"Missing {loc} translation: {tr_path}"
        with open(tr_path, "r", encoding="utf-8") as f:
            tr = json.load(f)
        assert tr.get("schema") == "psychopatz.convo-engine.translation.v1", f"Bad tr schema in {loc}/{fn}"
        assert tr.get("family") == fam_id, f"Bad tr family in {loc}/{fn}"
        entries = tr.get("entries", {})
        for vid in var_ids:
            key = f"say.variants.{vid}"
            lines = entries.get(key)
            assert isinstance(lines, list) and len(lines) >= 3, f"Need >=3 lines for {loc}/{fn}:{key}"
            for line in lines:
                assert isinstance(line, str) and line.strip(), f"Empty line in {loc}/{fn}:{key}"
                for ph in placeholder_re.findall(line):
                    assert ph in allowed_placeholders, f"Disallowed placeholder {{{ph}}} in {loc}/{fn}:{key}"

# Static voice guard across world_event_beats/ and thematic_interactive/
for subdir in ("world_event_beats", "thematic_interactive"):
    dpath = os.path.join(root, "translations/EN/dialogue", subdir)
    assert os.path.isdir(dpath), f"Missing EN dir: {dpath}"
    for fn in sorted(os.listdir(dpath)):
        if not fn.endswith(".json"):
            continue
        fpath = os.path.join(dpath, fn)
        with open(fpath, "r", encoding="utf-8") as f:
            tr = json.load(f)
        for key, vals in tr.get("entries", {}).items():
            lines = vals if isinstance(vals, list) else [vals]
            for line in lines:
                if not isinstance(line, str):
                    continue
                cleaned = placeholder_re.sub("", line)
                m = jargon_re.search(cleaned)
                assert not m, f"System jargon {m.group(0)!r} in {subdir}/{fn}:{key}: {line!r}"
print("PY_VOICE_GUARD_OK")
']]

local handle = io.popen(pyCheck)
local pyOut = handle and handle:read("*a") or ""
if handle then handle:close() end
T.truthy(string.find(pyOut, "PY_VOICE_GUARD_OK", 1, true) ~= nil,
    "declarative JSON + static voice guard failed: " .. tostring(pyOut))

-- 2. Verify world_alarm.convo contains semantic.world.alarm.react
local scFile = io.open(
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_alarm.convo",
    "r"
)
T.truthy(scFile ~= nil, "world_alarm.convo must exist")
local scText = scFile:read("*a")
scFile:close()
local worldSectionStart = string.find(scText, "semantic.world.alarm.react", 1, true)
T.truthy(worldSectionStart ~= nil, "semantic.world.alarm.react must be in world_alarm.convo")

-- 3. Load ConvoEngine Registry and seed our 4 new families if reconcile.py --apply hasn't run yet
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Registry = require "PNC/ConvoEngine/Registry"
Registry.CONVO_PLANS = Registry.CONVO_PLANS or {}

local function seedPlan(familyID, variants)
    if Registry.CONVO_PLANS[familyID] then return end
    local variantList = {}
    for i = 1, #variants do
        local v = variants[i]
        variantList[i] = {
            id = v.id,
            templateID = "convo." .. familyID .. ".say.1." .. v.id,
            fallback = v.line,
            textRole = "spoken_action",
            variantCount = 1,
        }
    end
    Registry.CONVO_PLANS[familyID] = {
        id = familyID,
        kind = "dialogue",
        owner = "ProjectHoomans",
        exchangeFamily = {
            familyID = familyID,
            initiatingSay = {
                keyOrder = { "1" },
                mode = "single",
                realizations = {
                    ["1"] = {
                        key = "1",
                        shorthand = true,
                        variants = variantList,
                    },
                },
            },
        },
        payload = {
            metadata = {
                category = "projecthoomans:event_reactions",
                contentOwner = "projecthoomans.dialogue_content.events",
                responseAct = "REACT",
            },
            say = {
                keyOrder = { "1" },
                mode = "single",
                realizations = {
                    ["1"] = {
                        key = "1",
                        shorthand = true,
                        variants = variantList,
                    },
                },
            },
        },
    }
end

seedPlan("chronology.milestone.react", {
    { id = "first_week_steady", line = "Seven days since the world went sideways. Still breathing, {addressee.name}." },
    { id = "first_week_warm", line = "A whole week still standing, {addressee.name}. Glad I'm not alone." },
    { id = "first_week_guarded", line = "Week one. Don't get comfortable out here." },
    { id = "first_month_steady", line = "Thirty days since everything fell apart, {addressee.name}." },
    { id = "first_month_warm", line = "We made it a whole month, {addressee.name}." },
    { id = "first_month_guarded", line = "Month's gone by. Canned goods are thinning out." },
    { id = "first_season_steady", line = "Whole season gone by since the outbreak, {addressee.name}." },
    { id = "first_season_warm", line = "An entire season together out here, {addressee.name}." },
    { id = "first_season_guarded", line = "Three months in. Stay sharp." },
    { id = "first_year_steady", line = "A full year, {addressee.name}. Three hundred sixty-five days." },
    { id = "first_year_warm", line = "A full year, {addressee.name}. Against every odd, we're still here." },
    { id = "first_year_guarded", line = "One year. Don't celebrate too loud." },
    { id = "anniversary_steady", line = "Funny how a day like today brings old memories back, {addressee.name}." },
    { id = "anniversary_warm", line = "Days like today hit a little harder, {addressee.name}." },
    { id = "anniversary_guarded", line = "Calendar's just numbers now, {addressee.name}." },
})
seedPlan("world.event.food_crisis", {
    { id = "experienced", line = "We're scraping the bottom of the pantry here, {addressee.name}." },
    { id = "rumor", line = "Word is food's getting scarce down the road, {addressee.name}." },
    { id = "uncertain", line = "Can't swear to it, {addressee.name}, but talk is food's getting hard to find." },
    { id = "reply", line = "Yeah, {addressee.name}, I noticed our rations thinning out too." },
})
seedPlan("world.event.raider_surge", {
    { id = "experienced", line = "Ran into armed crews along the road myself, {addressee.name}." },
    { id = "witnessed", line = "Saw armed crews working the highway from the treeline, {addressee.name}." },
    { id = "rumor", line = "Heard armed crews are working the highway, {addressee.name}." },
    { id = "uncertain", line = "Not sure how organized they are, {addressee.name}, but I keep hearing talk of roadblocks." },
    { id = "reply", line = "Copy that, {addressee.name}. Keep a shell chambered." },
})
seedPlan("world.event.surplus", {
    { id = "experienced", line = "Garden plots are finally paying off, {addressee.name}." },
    { id = "rumor", line = "Word is the farms outside town brought in a strong harvest, {addressee.name}." },
    { id = "uncertain", line = "Can't say how long it'll last, {addressee.name}, but folks say there's extra harvest." },
    { id = "reply", line = "Good to hear, {addressee.name}. Let's get what we can jarred." },
})

require "PNC/ConvoEngine/Foundation"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
local Reactions = require "PNC/ConvoEngine/Social/Reaction"

-- 4. Verify Social/Reaction.lua resolves chronology & scoped world events cleanly
local rWeekWarm = Reactions.Resolve({
    eventType = "chronology_milestone_beat",
    npcID = "npc:1",
    context = { milestoneStage = "first_week", socialStyle = "warm", combatReactionRole = "chronology_milestone" },
})
T.truthy(rWeekWarm, "chronology first_week warm resolves")
T.equal(rWeekWarm.templateID, "hoomans.world.chronology.milestone.first_week_warm")

local rYearGuarded = Reactions.Resolve({
    eventType = "chronology_milestone_beat",
    npcID = "npc:1",
    context = { milestoneStage = "first_year", socialStyle = "guarded", combatReactionRole = "chronology_milestone" },
})
T.truthy(rYearGuarded, "chronology first_year guarded resolves")
T.equal(rYearGuarded.templateID, "hoomans.world.chronology.milestone.first_year_guarded")

local rAnniv = Reactions.Resolve({
    eventType = "chronology_milestone_beat",
    npcID = "npc:1",
    context = { milestoneStage = "anniversary", socialStyle = "steady", combatReactionRole = "chronology_anniversary" },
})
T.truthy(rAnniv, "chronology anniversary resolves")
T.equal(rAnniv.templateID, "hoomans.world.chronology.milestone.anniversary_steady")

local rFoodExp = Reactions.Resolve({
    eventType = "world_scoped_event_beat",
    npcID = "npc:1",
    context = { worldEventType = "food_crisis", epistemicProvenance = "experienced" },
})
T.truthy(rFoodExp, "food_crisis experienced resolves")
T.equal(rFoodExp.templateID, "hoomans.world.event.food_crisis.experienced")

local rFoodRumor = Reactions.Resolve({
    eventType = "world_scoped_event_beat",
    npcID = "npc:1",
    context = { worldEventType = "food_crisis", epistemicProvenance = "rumor" },
})
T.truthy(rFoodRumor, "food_crisis rumor resolves")
T.equal(rFoodRumor.templateID, "hoomans.world.event.food_crisis.rumor")

local rRaiderWit = Reactions.Resolve({
    eventType = "world_scoped_event_beat",
    npcID = "npc:1",
    context = { worldEventType = "bandit_bonanza", epistemicProvenance = "witnessed" },
})
T.truthy(rRaiderWit, "bandit_bonanza witnessed resolves")
T.equal(rRaiderWit.templateID, "hoomans.world.event.raider_surge.witnessed")

local rRaiderRumor = Reactions.Resolve({
    eventType = "world_event_raider_surge",
    npcID = "npc:1",
    context = { epistemicProvenance = "rumor" },
})
T.truthy(rRaiderRumor, "raider_surge rumor resolves")
T.equal(rRaiderRumor.templateID, "hoomans.world.event.raider_surge.rumor")

local rSurplusExp = Reactions.Resolve({
    eventType = "world_scoped_event_beat",
    npcID = "npc:1",
    context = { worldEventType = "agricultural_surplus", epistemicProvenance = "experienced" },
})
T.truthy(rSurplusExp, "agricultural_surplus experienced resolves")
T.equal(rSurplusExp.templateID, "hoomans.world.event.surplus.experienced")

-- 5. Verify PNC_ChronologyMilestones.lua emits declarative beat context without hardcoded text
local deliveredOpts = nil
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.SpeechTransport = {
    Deliver = function(_, _, opts)
        deliveredOpts = opts
        return 1
    end,
}
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_ChronologyMilestones.lua")
local Milestones = PNC.Semantics.ChronologyMilestones
Milestones.ResetRuntime()
local res = Milestones.EvaluateActor({
    id = "npc:d6_test",
    name = "Caleb",
    alive = true,
    survivalStartHours = 0,
    socialStyle = "warm",
    runtime = {},
}, 170, { nowMs = 1000 })
T.truthy(type(res) == "table" and #res >= 1, "first_week milestone triggers")
T.truthy(deliveredOpts ~= nil, "SpeechTransport.Deliver called")
T.equal(deliveredOpts.poolID, "semantic.world.chronology.milestone")
T.equal(deliveredOpts.text, nil, "no hardcoded text passed from ChronologyMilestones")
T.equal(deliveredOpts.context.milestoneStage, "first_week")
T.equal(deliveredOpts.context.socialStyle, "warm")

-- 6. Verify graceful dynamic-token rendering across TokenFormatter & SpeechTransport
PNC.Semantics.SpeechTransport = nil
local SpeechTransport = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticSpeechTransport.lua")
local TokenFormatter = require "PNC/ConvoEngine/TokenFormatter"

-- Known name + location resolve cleanly
T.equal(
    SpeechTransport.FormatTokens("Hey, {addressee.name}, watch out {scene.location}!", {
        ["addressee.name"] = "Marcus",
        ["scene.location"] = "by the fence",
    }),
    "Hey, Marcus, watch out by the fence!"
)

-- Missing / nil / empty tokens cleanly collapse vocative punctuation with zero raw {token} leaks
T.equal(SpeechTransport.FormatTokens("Hey, {addressee.name}, watch out!", {}), "Hey, watch out!")
T.equal(SpeechTransport.FormatTokens("{addressee.name}, watch out!", nil), "Watch out!")
T.equal(SpeechTransport.FormatTokens("Take care, {addressee.name}.", { ["addressee.name"] = "" }), "Take care.")
T.equal(
    SpeechTransport.FormatTokens("{scene.clock}—and the lights died, {addressee.name}.", {}),
    "And the lights died."
)
T.equal(TokenFormatter.FirstTokenName("Unknown Survivor"), nil)
T.equal(TokenFormatter.FirstTokenName("Ellie Vance"), "Ellie")

-- ResolveLine populates speaker.name, addressee.name (when known), and scene.location cleanly
local formatted, resolvedLine = SpeechTransport.ResolveLine(
    { id = "npc:tok", name = "Caleb Mercer", zoneName = "in Muldraugh" },
    {
        eventType = "chronology_milestone_beat",
        eventRef = "tok:1",
        poolID = "semantic.world.chronology.milestone",
        context = { milestoneStage = "first_week", socialStyle = "warm", playerName = "Ellie Vance", playerNameKnown = true },
    }
)
T.truthy(resolvedLine ~= nil and type(formatted) == "string", "ResolveLine produces formatted text")
T.falsy(string.find(formatted, "{", 1, true), "ResolveLine leaves no raw {token} placeholders")
T.contains(formatted, "Ellie", "ResolveLine populates known addressee.name")

-- Missing/unknown addressee name collapses cleanly in ResolveLine without leaking {addressee.name}
local unknownFormatted = SpeechTransport.ResolveLine(
    { id = "npc:tok2", name = "Caleb Mercer" },
    {
        eventType = "chronology_milestone_beat",
        eventRef = "tok:2",
        poolID = "semantic.world.chronology.milestone",
        context = { milestoneStage = "first_week", socialStyle = "warm", playerName = "Unknown Survivor", playerNameKnown = false },
    }
)
T.truthy(type(unknownFormatted) == "string" and unknownFormatted ~= "", "ResolveLine with unknown addressee returns text")
T.falsy(string.find(unknownFormatted, "{", 1, true), "ResolveLine with unknown addressee leaves no raw braces")
T.falsy(string.find(unknownFormatted, ", ,", 1, true), "ResolveLine with unknown addressee leaves no double comma")
T.falsy(string.find(unknownFormatted, ", .", 1, true), "ResolveLine with unknown addressee leaves no broken comma-period")

print("pnc_declarative_beats_and_voice_smoke: PASS")
