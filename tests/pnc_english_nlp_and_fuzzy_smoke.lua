local T = require "tests/support/test"

T.addPackagePaths()

local NLP = require "PsychopatzCore/Semantics/PsychopatzSemanticEnglishNLP"
local Normalizer = require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Registry = require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Fuzzy = require "PsychopatzCore/Semantics/PsychopatzSemanticFuzzyMatcher"
local Parser = require "PsychopatzCore/Semantics/PsychopatzSemanticParser"

-- 1. Shorthand, dropped apostrophes & elongation collapse
local n1 = Normalizer.Normalize("heyyyyy bro wats ur name???")
T.equal(n1.normalizedText, "hey bro what is your name", "shorthand + elongation normalized")
T.equal(table.concat(n1.cleanTokens, " "), "hey what is your name", "fillers stripped cleanly")
T.equal(n1.playerTone, "casual", "casual tone detected")
T.equal(n1.isQuestion, true, "question flag detected")

local n2 = Normalizer.Normalize("pls gimme meds quick!!")
T.equal(n2.normalizedText, "please give me medicine quick", "gaming shorthand expanded")
T.equal(n2.playerTone, "urgent", "urgent tone detected from quick + !")
T.equal(n2.isExclamation, true, "exclamation flag detected")

local n3 = Normalizer.Normalize("shut up idiot")
T.equal(n3.playerTone, "hostile", "hostile tone detected")

local n4 = Normalizer.Normalize("thanks please help")
T.equal(n4.playerTone, "polite", "polite tone detected")

-- 2. Lemmatizer (irregulars + regular rules)
T.equal(NLP.Lemmatize("bleeding"), "bleed", "irregular bleeding->bleed")
T.equal(NLP.Lemmatize("fought"), "fight", "irregular fought->fight")
T.equal(NLP.Lemmatize("bandaged"), "bandage", "irregular bandaged->bandage")
T.equal(NLP.Lemmatize("zombies"), "zombie", "irregular zombies->zombie")
T.equal(NLP.Lemmatize("running"), "run", "irregular running->run")
T.equal(NLP.Lemmatize("berries"), "berry", "ies->y lemmatization")

-- 3. O(1) Phonetic skeleton & lemma fuzzy matching
Registry.RegisterConcept({ id = "TEST_MEDICINE", category = "item", aliases = { "medicine" }, priority = 10 })
Registry.RegisterConcept({ id = "TEST_ZOMBIE", category = "entity", aliases = { "zombie" }, priority = 10 })
Registry.RegisterConcept({ id = "TEST_BLEED", category = "action", aliases = { "bleed" }, priority = 10 })
Fuzzy.Rebuild()

local phMed = Fuzzy.Find("medisin")
T.truthy(phMed and phMed.matches and phMed.matches[1].id == "TEST_MEDICINE", "phonetic match medisin->medicine")

local phZom = Fuzzy.Find("zomby")
T.truthy(phZom and phZom.matches and phZom.matches[1].id == "TEST_ZOMBIE", "phonetic match zomby->zombie")

local lmBleed = Fuzzy.Find("bleeding")
T.truthy(lmBleed and lmBleed.matches and lmBleed.matches[1].id == "TEST_BLEED", "lemma match bleeding->bleed")

-- 4. Parse ring-buffer cache consistency & immutability
Parser.ResetCache()
local r1 = Parser.ParseCandidates("heyyyyy bro wats ur name???")
local r2 = Parser.ParseCandidates("heyyyyy bro wats ur name???")
T.equal(r1.normalizedText, r2.normalizedText, "cached parse returns identical normalizedText")
T.equal(r1.diagnostics.playerTone, "casual", "playerTone attached to diagnostics")
r1.normalizedText = "MUTATED"
local r3 = Parser.ParseCandidates("heyyyyy bro wats ur name???")
T.equal(r3.normalizedText, "hey bro what is your name", "cached parse is safely cloned (immutable)")

print("pnc_english_nlp_and_fuzzy_smoke: ok")
