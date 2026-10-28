local T = require "tests/support/test"

T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Realization = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SpeechRealization.lua"
)
local Registry = PNC.Semantics.ConversationRegistry

T.truthy(Registry and Registry.FamilyFor,
    "generated Conversation registry is available to production realization")
T.truthy(Registry.PHRASE_FAMILIES["semantic.leader_loss.default"],
    "migrated leader-loss variant has a stable phrase family")
T.equal(
    Registry.PHRASE_FAMILIES["semantic.leader_loss.default"].contentOwner,
        "projecthoomans.dialogue_content.events",
    "event wording exposes the canonical content owner"
)

local function realize(poolID, context)
    Catalog.ResetSelections()
    context = context or {}
    context.npcID = context.npcID or "npc-p7"
    local selected = T.truthy(
        Catalog.Select(poolID, context, "p7-content"),
        poolID .. " selects through the production ResponseCatalog"
    )
    T.equal(selected.contentOwner,
        poolID:find("semantic.compat.", 1, true) == 1
            and "projecthoomans.dialogue_content.compatibility"
            or poolID:find("semantic.tool_reply.", 1, true) == 1
                and "projecthoomans.dialogue_content.tool_replies"
            or "projecthoomans.dialogue_content.events",
        poolID .. " keeps wording below semantic authority")
    if selected.plan then
        T.truthy(selected.plan.turns,
            poolID .. " keeps its bounded ResponsePlan")
        local segment = selected.plan.turns[1].segments[1]
        T.equal(segment.kind, "translation",
            poolID .. " promotes literal plan wording through the content seam")
        T.equal(segment.templateID, selected.templateID,
            poolID .. " keeps semantic variant identity on the plan segment")
    end
    local rendered = Realization.Apply({
        selectionID = selected.id,
        templateID = selected.templateID,
        fallback = selected.fallback,
        plan = selected.plan,
    }, context)
    T.truthy(rendered.phraseID,
        poolID .. " receives a canonical phrase selection")
    T.truthy(rendered.phraseSelection,
        poolID .. " exposes phrase provenance")
    T.equal(rendered.semanticVariantID, selected.id,
        poolID .. " keeps semantic selection separate from phrase selection")
    return selected, rendered
end

local leader, leaderRendered = realize("semantic.leader_loss.reaction", {
    leaderGrief = "devoted",
})
T.equal(leader.id, "semantic.leader_loss.devoted",
    "leader-loss semantic variant remains the selected meaning")
T.equal(leaderRendered.phraseID,
    "phrase.semantic.leader_loss.devoted.neutral.01",
    "leader-loss wording comes from a stable Dialogue Content phrase")

local medical = realize("semantic.medical.distress.call", {
    downedNeed = "bleedout",
})
T.equal(medical.id, "semantic.medical.distress.call.bleedout",
    "medical semantic condition remains ResponseCatalog-owned")

local tool = realize("semantic.tool_reply.order.camp")
T.truthy(string.find(tool.templateID, "semantic.tool_reply.order_camp.", 1, true),
    "ToolReply wording uses stable semantic content identity")

local compatibility = realize("semantic.compat.bandits.hooman_hurt", {
    socialRole = "colonist",
})
T.truthy(string.find(compatibility.id, "semantic.compat.bandits.hooman_hurt.", 1, true),
    "compatibility event meaning remains selected by semantic conditions")

T.finish("pnc_unified_authority_p7_content_smoke")
