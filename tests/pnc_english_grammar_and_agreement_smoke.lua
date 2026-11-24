-- Smoke test: Shared NLU + NLG English grammar, pronoun classification,
-- past indicative vs past subjunctive ("were"), family/kinship subject-verb
-- agreement, verb conjugation, articles, and dynamic TokenFormatter realization.

local repoRoot = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
local coreRoot = "/home/psychopatz/Zomboid/Workshop/psychopatzCore"

package.path = table.concat({
    repoRoot .. "/Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua",
    coreRoot .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

local function assertEq(actual, expected, msg)
    if actual ~= expected then
        error("ASSERT FAILED (" .. tostring(msg) .. "): expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local Sem = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Grammar = require "PsychopatzCore/Semantics/PsychopatzSemanticEnglishGrammar"
local Formatter = require "PNC/ConvoEngine/TokenFormatter"

-- 1. Pronoun classification: "Us", "I", "She", "They"
local pUs = Grammar.ClassifyPronoun("us")
assertEq(pUs.person, 1, "us person")
assertEq(pUs.number, "pl", "us number")
assertEq(pUs.case, "obj", "us case")

local pI = Grammar.ClassifyPronoun("I")
assertEq(pI.person, 1, "I person")
assertEq(pI.number, "sg", "I number")
assertEq(pI.case, "subj", "I case")

-- 2. NLU sentence analysis (tense, mood, pronouns, kinship, compound subjects)
local n1 = Sem.Normalizer.Normalize("I walked home")
assertEq(n1.grammar.tense, "past", "I walked home tense")
assertEq(n1.grammar.mood, "indicative", "I walked home mood")
assertEq(n1.grammar.subjectPerson, 1, "I walked home subjectPerson")
assertEq(n1.grammar.subjectNumber, "sg", "I walked home subjectNumber")

local n2 = Sem.Normalizer.Normalize("She told us")
assertEq(n2.grammar.tense, "past", "She told us tense")
assertEq(n2.grammar.subjectPerson, 3, "She told us subjectPerson")
assertEq(n2.grammar.subjectGender, "female", "She told us subjectGender")
assertEq(n2.grammar.pronouns[2].case, "obj", "us in 'She told us' is obj")
assertEq(n2.grammar.pronouns[2].number, "pl", "us in 'She told us' is pl")

local n3 = Sem.Normalizer.Normalize("If I were you")
assertEq(n3.grammar.tense, "past", "If I were you tense")
assertEq(n3.grammar.mood, "subjunctive", "If I were you mood")

local n4 = Sem.Normalizer.Normalize("We were in Rosewood")
assertEq(n4.grammar.tense, "past", "We were tense")
assertEq(n4.grammar.mood, "indicative", "We were mood")
assertEq(n4.grammar.subjectPerson, 1, "We were subjectPerson")
assertEq(n4.grammar.subjectNumber, "pl", "We were subjectNumber")

local n5 = Sem.Normalizer.Normalize("My dad and I weren't there")
assertEq(n5.grammar.tense, "past", "dad and I weren't tense")
assertEq(n5.grammar.subjectPerson, 1, "dad and I compound subjectPerson=1")
assertEq(n5.grammar.subjectNumber, "pl", "dad and I compound subjectNumber=pl")
assertEq(n5.grammar.kinship[1].gender, "male", "dad kinship gender")

-- 3. NLG Surface Inflection & Family Agreement (single template, multiple contexts!)
local familyTemplate = "{subj.pron} {subj.be} {gram.a:mechanic} and {subj.pron} {gram.v:walk} home."

local dadAlive = Formatter.Format(familyTemplate, {
    _subject = { person = 3, number = "sg", gender = "male", tense = "present" },
})
assertEq(dadAlive, "he is a mechanic and he walks home.", "dad alive present")

local dadPast = Formatter.Format(familyTemplate, {
    _subject = { person = 3, number = "sg", gender = "male", tense = "past" },
})
assertEq(dadPast, "he was a mechanic and he walked home.", "dad deceased/past")

local momPast = Formatter.Format("{subj.pron} {gram.v:tell} {other.obj}.", {
    _subject = { person = 3, number = "sg", gender = "female", tense = "past" },
    ["other.obj"] = Grammar.Pronoun(1, "pl", nil, "obj"),
})
assertEq(momPast, "she told us.", "she told us realization")

local subjunctiveLine = Formatter.Format("If {subj.pron} {subj.be} you, I'd stay close.", {
    _subject = { person = 1, number = "sg", tense = "past", mood = "subjunctive" },
})
assertEq(subjunctiveLine, "If I were you, I'd stay close.", "past subjunctive 'If I were you'")

local parentsPlural = Formatter.Format("My parents {subj.be} still out there; {subj.pron} {subj.be_past} in Rosewood.", {
    _subject = { person = 3, number = "pl", tense = "present" },
})
assertEq(parentsPlural, "My parents are still out there; they were in Rosewood.", "plural parents agreement")

-- 4. Articles & Possessives
assertEq(Grammar.Article("hour"), "an", "an hour")
assertEq(Grammar.Article("university"), "a", "a university")
assertEq(Grammar.Article("office"), "an", "an office")
assertEq(Grammar.Possessive("Marcus"), "Marcus'", "Marcus'")
assertEq(Grammar.Possessive("Joe"), "Joe's", "Joe's")

print("PASS pnc_english_grammar_and_agreement_smoke")
