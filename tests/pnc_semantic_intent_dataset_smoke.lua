-- End-to-end Tier-3 IntentClassifier + ProjectHoomans compiled intent dataset smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path

local T = require "support.test"

local Registry = require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Parser = require "PsychopatzCore/Semantics/PsychopatzSemanticParser"
local Classifier = require "PsychopatzCore/Semantics/PsychopatzSemanticIntentClassifier"

Registry.Reset()
Classifier.ResetDatasets()
local ds = require "PNC/ConvoEngine/Intents/IntentDataset_EN"
Classifier.RegisterDataset("project_hoomans_en", ds)

local participants = {
    { id = "npc_meghan", name = "Meghan patz", firstName = "Meghan" },
    { id = "npc_rory", name = "Rory patz", firstName = "Rory" },
}

-- 1) Exact user screenshot failure: "come lets goo" -> FOLLOW!
local ir1 = Parser.Parse("come lets goo", { groupParticipants = participants })
T.equal(ir1.action, "FOLLOW", "come lets goo resolves to FOLLOW")
T.truthy((ir1.confidence or 0) >= 0.68, "come lets goo has high confidence")

-- 2) Named individual + colloquial idiom + expressive elongation:
local ir2 = Parser.Parse("Meghan, come lets goo!", { groupParticipants = participants })
T.equal(ir2.action, "FOLLOW", "Meghan, come lets goo -> FOLLOW")
T.equal(ir2.extensions.audienceScope.scope, "INDIVIDUAL", "targets individual")
T.equal(ir2.extensions.audienceScope.targetIDs[1], "npc_meghan", "targets Meghan")

-- 3) Group broadcast + idiom:
local ir3 = Parser.Parse("you all roll out", { groupParticipants = participants })
T.equal(ir3.action, "FOLLOW", "you all roll out -> FOLLOW")
T.equal(ir3.extensions.audienceScope.scope, "GROUP", "group scope")

-- 4) Diverse survival idioms across intents:
T.equal(Parser.Parse("chill here").action, "STAY", "chill here -> STAY")
T.equal(Parser.Parse("watch my six").action, "GUARD", "watch my six -> GUARD")
T.equal(Parser.Parse("patch me up").action, "HEAL", "patch me up -> HEAL")
T.equal(Parser.Parse("clear the bodies").action, "HAUL_CORPSES", "clear the bodies -> HAUL_CORPSES")
T.equal(Parser.Parse("check your bag").action, "OPEN_INVENTORY", "check your bag -> OPEN_INVENTORY")
T.equal(Parser.Parse("hit the sack").action, "SLEEP", "hit the sack -> SLEEP")
T.equal(Parser.Parse("back to base").action, "CAMP", "back to base -> CAMP")

-- 5) Typo-tolerant char 3-gram prototype match:
T.equal(Parser.Parse("watch my bck").action, "GUARD", "typo 'watch my bck' -> GUARD")
T.equal(Parser.Parse("patche me up").action, "HEAL", "typo 'patche me up' -> HEAL")

-- 6) Negation + idiom inversion:
local irNeg = Parser.Parse("don't roll out")
T.equal(irNeg.action, "STAY", "don't roll out -> STAY")
T.equal(irNeg.polarity, "negative", "negative polarity preserved")

-- 7) Gibberish rejection (must NOT false-positive!):
local irGib1 = Parser.Parse("purple elephant saxophone")
T.equal(irGib1.confidence, 0, "gibberish 1 rejected cleanly")
local irGib2 = Parser.Parse("asdf qwerty zxcv")
T.equal(irGib2.confidence, 0, "gibberish 2 rejected cleanly")

print("pnc_semantic_intent_dataset_smoke: OK")
