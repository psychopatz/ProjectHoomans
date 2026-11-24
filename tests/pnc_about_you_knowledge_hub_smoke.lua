-- Verifies the "Tell me about yourself" (about_you) knowledge subcategory hub,
-- familiarity/relationship gating, hiding of already-known facets, and
-- escalating repeat-ask annoyance branching when re-asked via text input.

local T = require "tests/support/test"
T.addPackagePaths()

local coreRepository = os.getenv("PZ_TEST_CORE_REPOSITORY")
    or "../psychopatzCore"
package.path = coreRepository
    .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. package.path

local AboutYou = require "PNC/ConvoEngine/Suggestions/AboutYouCatalog"
local RepeatAsk = require "PNC/ConvoEngine/Dialogue/LocalResponse_RepeatAsk"
local StaticProvider = require "PNC/ConvoEngine/Suggestions/StaticProvider"

local function findByID(list, id)
    for _, item in ipairs(list or {}) do
        if item.id == id then return item end
    end
    return nil
end

-- 1. Unknown NPC: root shows "question.identity", hides "question.about_you"
--    and hides individual identity facets from root clutter.
local unknownCtx = {
    identityState = "unknown",
    npcKnowledge = {},
    familiarity = 0,
}
local unknownRoot = StaticProvider.collect(unknownCtx)
T.truthy(findByID(unknownRoot, "question.identity"),
    "unknown NPC root exposes ask-name")
T.falsy(findByID(unknownRoot, "question.about_you"),
    "unknown NPC root hides Tell me about yourself")
T.falsy(findByID(unknownRoot, "question.identity_faction"),
    "identity_faction is not cluttered on root")

-- 2. Known-name NPC: root hides "question.identity" and shows "question.about_you"
local knownCtx = {
    identityState = "known",
    npcName = "Elena Parker",
    npcKnowledge = {
        nameKnown = true,
        knownName = "Elena Parker",
        factionKnown = false,
        identity = { displayName = "Elena Parker" },
    },
    familiarity = 5,
    semanticContextState = {},
}
local knownRoot = StaticProvider.collect(knownCtx)
T.falsy(findByID(knownRoot, "question.identity"),
    "known-name NPC root hides ask-name")
T.truthy(findByID(knownRoot, "question.about_you"),
    "known-name NPC root exposes Tell me about yourself")

-- 3. Opening about_you hub: NPC prompts with tone-aware variant; submenu
--    shows familiarity-appropriate facets and hides deep 75-tier facets at fam=5.
local prompt = RepeatAsk.ResolveAboutYou({}, {}, knownCtx)
T.equal(prompt.topic, "about_you", "about_you prompt sets topic")
T.equal(prompt.tone, "guarded", "low familiarity uses guarded prompt tone")

knownCtx.activeHubID = "about_you"
local hubLow = StaticProvider.collect(knownCtx)
T.truthy(findByID(hubLow, "question.identity_nickname"),
    "hub exposes nickname at fam=5")
T.truthy(findByID(hubLow, "question.identity_faction"),
    "hub exposes faction (next-tier preview) at fam=5")
T.falsy(findByID(hubLow, "question.backstory.tragedy"),
    "hub hides sensitive 75-tier tragedy facet at fam=5")

-- 4. Relationship gate refusal when asking faction below minFamiliarity=10
local gated = RepeatAsk.ResolveRelationshipGate("faction", 10, knownCtx)
T.equal(gated.uncertainty, "gated", "below-gate faction returns gated refusal")
T.equal(gated.tone, "guarded", "gated refusal is guarded")

-- 5. Once faction & nickname are known, they disappear from the submenu
knownCtx.npcKnowledge.factionKnown = true
knownCtx.npcKnowledge.factionName = "Maple Enclave"
knownCtx.npcKnowledge.nicknameKnown = true
knownCtx.npcKnowledge.knownNickname = "Ellie"
knownCtx.familiarity = 60
local hubMid = StaticProvider.collect(knownCtx)
T.falsy(findByID(hubMid, "question.identity_faction"),
    "known faction is hidden from about_you submenu")
T.falsy(findByID(hubMid, "question.identity_nickname"),
    "known nickname is hidden from about_you submenu")
T.truthy(findByID(hubMid, "question.backstory.former_job"),
    "unknown 25-tier former_job is visible at fam=60")
T.truthy(findByID(hubMid, "question.backstory.tragedy"),
    "75-tier tragedy is visible as next-tier at fam=60")

-- 6. Repeat-ask escalation when player keeps asking via text input box
local r1 = RepeatAsk.BuildKnownRepeatResponse("identity", "Elena Parker", knownCtx)
local r2 = RepeatAsk.BuildKnownRepeatResponse("identity", "Elena Parker", knownCtx)
local r3 = RepeatAsk.BuildKnownRepeatResponse("identity", "Elena Parker", knownCtx)
T.equal(r1.tone, "direct", "1st repeat is a mild reminder")
T.equal(r2.tone, "pointed", "2nd repeat is pointed/skeptical")
T.equal(r3.tone, "annoyed", "3rd repeat is annoyed")
T.contains(r3.fallback, "Elena Parker", "annoyed reply still states name")

print("pnc_about_you_knowledge_hub_smoke: PASS")
