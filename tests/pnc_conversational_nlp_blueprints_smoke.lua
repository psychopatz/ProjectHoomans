local T = require "tests/support/test"

T.addPackagePaths()

local Formatter = require "PNC/ConvoEngine/TokenFormatter"
local Lexicon = require "PNC/ConvoEngine/Lexicon"
local OfferRealizer = require "PNC/ConvoEngine/OfferRealizer"
local Normalizer = require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local FollowUp = require "PsychopatzCore/Semantics/PsychopatzSemanticFollowUp"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require "PNC/ConvoEngine/ResponseCatalog/Generated/Init"

-- 1. Dynamic list conjunctions (1, 2, 3+ items, "and" / "or", with & without articles)
T.equal(Formatter.Format("I have {items|list_a}.", { items = { "bandage" } }),
    "I have a bandage.", "1 item with article")
T.equal(Formatter.Format("I have {items|list_a}.", { items = { "bandage", "apple" } }),
    "I have a bandage and an apple.", "2 items with a/an")
T.equal(Formatter.Format("I have {items|list_a}.", { items = { "bandage", "apple", "flashlight" } }),
    "I have a bandage, an apple, and a flashlight.", "3 items Oxford comma + a/an")
T.equal(Formatter.Format("Want {items|or}?", { items = { "water", "soup", "bandages" } }),
    "Want water, soup, or bandages?", "3 items 'or' conjunction")

-- 2. Adaptive punctuation {end} & automatic punctuation cleanup
T.equal(Formatter.Format("Watch out{end}", {}, { context = { speakerStyle = "brave" } }),
    "Watch out!", "brave/combat uses !")
T.equal(Formatter.Format("Hold on{end}", {}, { context = { speakerStyle = "shaken" } }),
    "Hold on...", "shaken uses ...")
T.equal(Formatter.Format("Alright{end}", {}, { context = { speakerStyle = "cold" } }),
    "Alright.", "cold uses .")
T.equal(Formatter.CleanPunctuation("Hey!.  watch out , . "),
    "Hey! Watch out.", "punctuation cleanup + auto-cap after !")

-- 3. Nuanced rudeness, shouting, politeness, skepticism & dialogue acts
local nShout = Normalizer.Normalize("GIVE ME A BANDAGE RIGHT NOW")
T.equal(nShout.playerShouting, true, "ALL CAPS detected as shouting")
T.equal(nShout.playerRude, true, "blunt ALL CAPS detected as rude")
T.equal(nShout.playerTone, "hostile", "rude shouting maps to hostile tone")

local nDismiss = Normalizer.Normalize("get lost, none of your business")
T.equal(nDismiss.playerRude, true, "dismissive phrase detected as rude")

local nSkep = Normalizer.Normalize("really? are you sure?")
T.equal(nSkep.playerSkeptical, true, "skepticism detected")
T.equal(nSkep.playerTone, "skeptical", "skeptical tone selected")

local nPolite = Normalizer.Normalize("could you please help, thanks")
T.equal(nPolite.playerPolite, true, "politeness detected")
T.equal(nPolite.playerRude, false, "polite is not rude")

-- 4. Multi-turn elliptical follow-up resolution against ContextState
local ctxState = {
    currentTopic = "medical",
    mentions = {
        { role = "location", kind = "location", key = "school", label = "the school" },
        { role = "person", kind = "person", key = "npc_1", label = "Myrna" },
    },
}
local irWhere = FollowUp.Resolve(Normalizer.Normalize("where?"), ctxState)
T.truthy(irWhere and irWhere.intent == "QUESTION" and irWhere.action == "LOCATE" and irWhere.target.key == "school",
    "'where?' resolves against last location mention")

local irWho = FollowUp.Resolve(Normalizer.Normalize("who?"), ctxState)
T.truthy(irWho and irWho.intent == "QUESTION" and irWho.action == "IDENTIFY" and irWho.target.key == "npc_1",
    "'who?' resolves against last person mention")

local irDeny = FollowUp.Resolve(Normalizer.Normalize("never mind"), ctxState)
T.truthy(irDeny and irDeny.intent == "REFUSE" and irDeny.action == "CANCEL",
    "'never mind' resolves to DENY/CANCEL")

local irConfirm = FollowUp.Resolve(Normalizer.Normalize("yeah sure"), ctxState)
T.truthy(irConfirm and irConfirm.intent == "AGREE" and irConfirm.action == "CONFIRM",
    "'yeah sure' resolves to CONFIRM")

-- 5. Dynamic .convo Offer Blueprints (Player button labels + Colonist autonomous choice)
local tokens = Formatter.AttachPronouns({
    ["addressee.name"] = "Elena",
    ["mention.items"] = { "bandage", "apple", "water" },
}, "addressee", { female = true })

local offers = OfferRealizer.BuildForPool("semantic.combat.assist.gratitude", {
    anyInjured = true,
    playerRude = true,
    speakerStyle = "brave",
}, tokens, { salt = "bp1" })

T.equal(#offers, 4, "all 4 blueprint offers realized (wound + supplies + stay_safe + apologize)")
T.equal(offers[1].label, "Check on her wound", "dynamic pronoun in button label")
T.equal(offers[1].say, "Hold still—let me check her wound!", "dynamic pronoun + adaptive {end} in spoken line")
T.equal(offers[2].label, "Ask about a bandage, an apple, and a water", "dynamic |list_a in button label")
T.equal(offers[2].say, "You got any spare bandage, apple, and water?", "dynamic |list in spoken line")
T.equal(offers[4].id, "repair.apologize", "rudeness unlocks social_repair blueprint offer")

-- Autonomous colonist pick from exact same realized offers
local picked = OfferRealizer.PickAutonomous(offers, { compassion = 0.9, sociability = 0.8, aggression = 0.1, bravery = 0.5 }, {})
T.truthy(picked ~= nil and (picked.utility == "compassion" or picked.utility == "openness"),
    "compassionate colonist picks compassion/openness offer autonomously")

-- Discourse glue pushback reacts to shouting vs rudeness
local pushShout = Lexicon.Expand("{glue.pushback_rude} calm down.", { npcID = "n1", playerShouting = true, playerRude = true }, {}, { salt = "s1" })
T.truthy(string.find(pushShout, "yell", 1, true) ~= nil or string.find(pushShout, "voice", 1, true) ~= nil,
    "shouting triggers anti-yelling discourse glue: " .. pushShout)

-- 6. Number / quantity word normalization
T.equal(Normalizer.Normalize("give me two bandages").quantity, 2, "two -> 2")
T.equal(Normalizer.Normalize("a couple of cans").quantity, 2, "a couple -> 2")
T.equal(Normalizer.Normalize("half a dozen bottles").quantity, 6, "half a dozen -> 6")
T.equal(Normalizer.Normalize("5 nails").quantity, 5, "digit 5 -> 5")
T.equal(Normalizer.Normalize("one of us").quantity, nil, "'one of' idiom not treated as quantity")

-- 7. Live Parser.ParseCandidates elliptical follow-up fallback
local Parser = require "PsychopatzCore/Semantics/PsychopatzSemanticParser"
local liveWhere = Parser.ParseCandidates("where?", { context = ctxState })
T.truthy(liveWhere.selected ~= nil and liveWhere.diagnostics.selectedPass == "followup"
    and liveWhere.selected.ir.action == "LOCATE" and liveWhere.selected.ir.target.key == "school",
    "live Parser falls back to FollowUp.Resolve for elliptical 'where?'")

print("pnc_conversational_nlp_blueprints_smoke: ok")
