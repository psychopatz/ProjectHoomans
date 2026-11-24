local T = require "tests/support/test"

T.addPackagePaths()

local Formatter = require "PNC/ConvoEngine/TokenFormatter"
local Lexicon = require "PNC/ConvoEngine/Lexicon"
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require "PNC/ConvoEngine/ResponseCatalog/Generated/Init"

-- 1. Grammar filters: |a, |s, |s:count, |cap, |verb, {?optional}
T.equal(Formatter.Format("{adj|a} fight", { adj = "ugly" }), "an ugly fight", "an before vowel")
T.equal(Formatter.Format("{adj|a} fight", { adj = "rough" }), "a rough fight", "a before consonant")
T.equal(Formatter.Format("{t|a} ago", { t = "hour" }), "an hour ago", "an before silent h")
T.equal(Formatter.Format("{n|s}", { n = "walker" }), "walkers", "regular plural")
T.equal(Formatter.Format("{n|s}", { n = "body" }), "bodies", "y->ies plural")
T.equal(Formatter.Format("{n|s}", { n = "dead" }), "dead", "invariant plural")
T.equal(Formatter.Format("{c} {n|s:c}", { c = 1, n = "walker" }), "1 walker", "count=1 singular")
T.equal(Formatter.Format("{c} {n|s:c}", { c = 5, n = "walker" }), "5 walkers", "count=5 plural")
T.equal(Formatter.Format("{w|cap}!", { w = "whew" }), "Whew!", "capitalize filter")
T.equal(Formatter.Format("Clear. {?extra}", {}), "Clear.", "optional missing collapses cleanly")

-- 2. Pronoun bundles + 3rd-person verb agreement
local tokF = Formatter.AttachPronouns({ act = "bleed" }, "subject", { female = true })
T.equal(Formatter.Format("{subject.sub|cap} {act|verb:subject} from {subject.pos} arm.", tokF),
    "She bleeds from her arm.", "female pronoun + 3sg verb")
local tokM = Formatter.AttachPronouns({ act = "be" }, "subject", { female = false })
T.equal(Formatter.Format("{subject.sub|cap} {act|verb:subject} hurt.", tokM),
    "He is hurt.", "male pronoun + irregular be")
local tokP = Formatter.AttachPronouns({ act = "bleed" }, "subject", {}, { plural = true })
T.equal(Formatter.Format("{subject.sub|cap} {act|verb:subject} together.", tokP),
    "They bleed together.", "plural pronoun + base verb")

-- 3. Contextual Lexicon expansion: personality style + optional night/rain clauses + variety
Lexicon.ResetHistory()
local hordeTpl = "{opener.relief|cap}, that was {adj.fight|a} {noun.pack} of {noun.zombie|s}. {clause.thanks_backup} {?clause.night_warning}"
local seen = {}
local uniqueCount = 0
local t0 = os.clock()
for i = 1, 1000 do
    local line = Lexicon.Expand(hordeTpl, {
        npcID = "npc_1",
        speakerStyle = (i % 2 == 0) and "tactical" or "shaken",
        isNightOrDusk = (i % 3 == 0),
    }, { ["addressee.name"] = "Pat" }, { salt = "ev:" .. tostring(i) })
    T.truthy(not string.find(line, "{", 1, true), "no raw braces left in: " .. line)
    if not seen[line] then
        seen[line] = true
        uniqueCount = uniqueCount + 1
    end
end
local elapsed = os.clock() - t0
T.truthy(uniqueCount >= 50, "high compositional variety from 1 template (got " .. tostring(uniqueCount) .. ")")

-- Verify optional night clause vanishes during day and appears at night
local dayLine = Lexicon.Expand("Clear. {?clause.night_warning}", { npcID = "n1", isNightOrDusk = false }, {}, { salt = "d1" })
local nightLine = Lexicon.Expand("Clear. {?clause.night_warning}", { npcID = "n1", isNightOrDusk = true }, {}, { salt = "n1" })
T.equal(dayLine, "Clear.", "night clause omitted in daytime")
T.truthy(#nightLine > #dayLine, "night clause included at night: " .. nightLine)

-- Verify actor-agnostic generated offers loaded from social_identity_exchange.convo
local offers = PNC.ConvoEngine.GeneratedOffers["semantic.question.identity"]
T.truthy(type(offers) == "table" and #offers == 3, "3 actor-agnostic identity offers generated")
T.equal(offers[1].utility, "openness", "real_name utility set")
T.equal(offers[2].utility, "caution", "refuse_name utility set")
T.equal(offers[3].utility, "deception", "lie_name utility set")

print(string.format("pnc_compositional_nlg_smoke: ok (1000 expansions in %.3fs, %d unique lines)", elapsed, uniqueCount))
