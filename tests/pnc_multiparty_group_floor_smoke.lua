-- Smoke test for multi-party GroupAddressing, shared GroupFloor, responder bidding,
-- 1-hop NPC-to-NPC interjections, and group.interjection .convo realization.

local T = require "tests/support/test"
T.addPackagePaths()

local Addressing = require "PsychopatzCore/Semantics/PsychopatzSemanticGroupAddressing"
require "PNC/ConvoEngine/PatienceTracker"
require "PNC/ConvoEngine/TokenFormatter"
require "PNC/ConvoEngine/Lexicon"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
local GroupFloor = require "PNC/ConvoEngine/GroupFloor"

local Catalog = PNC.ConvoEngine.ResponseCatalog
local Lex = PNC.ConvoEngine.Lexicon

local participants = {
    { id = "npc_marcus", name = "Marcus Hale", isFemale = false, orderKind = "follow", socialStyle = "aggressive" },
    { id = "npc_sarah", name = "Sarah Lin", isFemale = true, orderKind = "none", socialStyle = "friendly" },
    { id = "npc_cole", name = "Cole Mercer", isFemale = false, orderKind = "none", socialStyle = "neutral" },
}

-- 1. Vocative addressing targets only Marcus and strips the vocative cleanly
local voc = Addressing.Resolve("Hey Marcus, stay here", participants)
T.equal(voc.scope, "single", "vocative sets single scope")
T.equal(voc.vocative, true, "vocative flag set")
T.equal(voc.targetID, "npc_marcus", "vocative targets Marcus")
T.equal(voc.cleanedText, "stay here", "vocative stripped cleanly")

-- 2. Group broadcast ("everyone follow me") sets group scope and strips prefix
local bc = Addressing.Resolve("everyone, follow me", participants)
T.equal(bc.scope, "group", "broadcast sets group scope")
T.equal(bc.broadcast, true, "broadcast flag set")
T.equal(bc.cleanedText, "follow me", "broadcast prefix stripped cleanly")

-- 3. Responder bidding on broadcast FOLLOW:
--    - non-following companions execute (Sarah & Cole, NOT Marcus who is already following)
--    - Sarah speaks primary, Cole chimes in (no 3-way bubble spam)
GroupFloor.Reset()
local res = GroupFloor.SelectResponders("grp_1", participants, {
    action = "FOLLOW",
    intent = "REQUEST",
    addressing = bc,
})
T.equal(res.scope, "group", "responder scope is group")
T.equal(res.primaryID, "npc_sarah", "non-following friendly NPC bids highest as primary")
T.equal(#res.executors, 2, "only non-following companions execute FOLLOW")
T.truthy(res.interjection ~= nil and res.interjection.kind == "chime_in", "1 secondary NPC chimes in")
T.truthy(res.interjection.actorID ~= res.primaryID, "interjector is different from primary")

-- Realize chime_in line via .convo
local vChime = Catalog.Select("group.interjection", res.interjection.context, "ch1")
T.equal(vChime and vChime.id, "group.interjection.chime_in_broadcast", "chime_in_broadcast selected")
local chimeLine = Lex.Expand(vChime.fallback, res.interjection.context, res.interjection.tokens, { salt = "ch1" })
T.truthy(string.find(chimeLine, "Sarah Lin", 1, true) ~= nil, "chime_in names primary speaker: " .. chimeLine)

-- 4. 3rd-party pronoun resolution ("is she okay?") resolves to Sarah via floor recency/gender
GroupFloor.RecordTurn("grp_1", {
    speakerID = "npc_sarah",
    speakerName = "Sarah Lin",
    speakerIsPlayer = false,
    intent = "INFORM",
    speakerInjured = true,
})
local floor = GroupFloor.Get("grp_1")
local pron = Addressing.Resolve("is she okay?", participants, floor, { speakerID = "player:pat" })
T.equal(pron.referencedActorID, "npc_sarah", "3rd-party 'she' resolves to Sarah")
T.equal(pron.implicitTargetID, "npc_sarah", "implicit target binds to last floor speaker")

-- 5. Cross-NPC 1-hop interjection when Marcus snaps (fed_up): friendly Sarah calms him down
local calmInterj = GroupFloor.PickInterjection("grp_1", participants, {
    speakerID = "npc_marcus",
    speakerName = "Marcus Hale",
    speakerIsPlayer = false,
    npcAnnoyed = true,
    npcFedUp = true,
})
T.truthy(calmInterj ~= nil, "interjection picked when Marcus snaps")
T.equal(calmInterj.actorID, "npc_sarah", "friendly Sarah steps in to calm Marcus")
T.equal(calmInterj.kind, "calm_down", "interjection kind is calm_down")
local vCalm = Catalog.Select("group.interjection", calmInterj.context, "calm1")
T.equal(vCalm and vCalm.id, "group.interjection.calm_down", "calm_down variant selected")
local calmLine = Lex.Expand(vCalm.fallback, calmInterj.context, calmInterj.tokens, { salt = "calm1" })
T.truthy(string.find(calmLine, "Marcus Hale", 1, true) ~= nil, "calm_down addresses Marcus: " .. calmLine)

-- 6. Strict 1-hop anti-loop guard: interjection never triggers another interjection
local noLoop = GroupFloor.PickInterjection("grp_1", participants, {
    speakerID = "npc_sarah",
    speakerName = "Sarah Lin",
    isInterjection = true,
    npcAnnoyed = true,
})
T.equal(noLoop, nil, "interjection never chains into a second interjection")

print("pnc_multiparty_group_floor_smoke: ok")
