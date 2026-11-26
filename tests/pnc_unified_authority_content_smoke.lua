local T = require "tests/support/test"

T.addPackagePaths()

PNC = { Semantics = {} }
PNC.ConvoEngine = PNC.ConvoEngine or {}
require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua"
)
local Realization = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/SpeechRealization.lua"
)
local Registry = PNC.ConvoEngine.Registry

T.truthy(Registry and Registry.FamilyFor,
    "Conversation registry is available to production realization")

local function realize(poolID, context)
    Catalog.ResetSelections()
    context = context or {}
    context.npcID = context.npcID or "npc-content"
    local selected = T.truthy(
        Catalog.Select(poolID, context, "content-authority"),
        poolID .. " selects through the production ResponseCatalog"
    )
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
    T.truthy(tostring(rendered.text or rendered.fallback or "") ~= "",
        poolID .. " realizes non-empty wording")
    T.equal(rendered.semanticVariantID, selected.id,
        poolID .. " keeps semantic selection separate from phrase selection")
    return selected, rendered
end

local leader, leaderRendered = realize("semantic.leader_loss.reaction", {
    leaderGrief = "devoted",
})
T.equal(leader.id, "semantic.leader_loss.reaction.devoted",
    "leader-loss semantic variant remains the selected meaning")
T.truthy(tostring(leaderRendered.text or leaderRendered.fallback or "") ~= "",
    "leader-loss wording comes from the authoritative ConvoDSL pool")

local medical = realize("semantic.medical.distress.call", {
    downedNeed = "bleedout",
})
T.equal(medical.id, "semantic.medical.distress.call.bleedout",
    "medical semantic condition remains ResponseCatalog-owned")

local tool = realize("semantic.tool_reply.order.camp")
T.truthy(string.find(tool.templateID, "tool_reply.order.camp.", 1, true),
    "ToolReply wording uses stable semantic content identity")

local compatibility = realize("semantic.compat.bandits.hooman_hurt", {
    socialRole = "colonist",
})
T.truthy(string.find(compatibility.id, "semantic.compat.bandits.hooman_hurt.", 1, true),
    "compatibility event meaning remains selected by semantic conditions")

T.finish("pnc_unified_authority_content_smoke")
