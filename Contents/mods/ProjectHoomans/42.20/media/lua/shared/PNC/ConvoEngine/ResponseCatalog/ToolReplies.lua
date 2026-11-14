-- Semantic response pools for first-party tool outcomes.
--
-- Tool execution remains authoritative in the gameplay/tool handlers. This
-- provider only maps bounded result facts to one semantic realization; it

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.tool_replies"

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local function installConvoLine(id)
    local planID, key = string.match(tostring(id or ""), "^(.-)%.(%d+)$")
    if planID and key then
        local installAs = planID .. ".say." .. key
        ConvoPlanFamily.install(planID, {
            planID = planID,
            realizationKey = key,
            installAs = installAs,
            defaultContentOwner = CONTENT_OWNER,
        })
        return installAs
    end
    ConvoPlanFamily.install(id, {
        planID = id,
        installAs = id,
        defaultContentOwner = CONTENT_OWNER,
    })
    return id
end

local function line(id)
    local installAs = installConvoLine(id)
    return {
        id = id,
        templateID = installAs,
        contentOwner = CONTENT_OWNER,
    }
end

local function register(id, variants)
    return Catalog.Register(id, { variants = variants })
end

-- Accepted social reactions.
register("semantic.tool_reply.social.accepted.compliment", {
    line("tool_reply.compliment.1"),
    line("tool_reply.compliment.2"),
    line("tool_reply.compliment.3"),
})
register("semantic.tool_reply.social.accepted.romantic_interest", {
    line("tool_reply.romantic.1"),
    line("tool_reply.romantic.2"),
    line("tool_reply.romantic.3"),
})
register("semantic.tool_reply.social.accepted.sexual_advance", {
    line("tool_reply.sexual.1"),
    line("tool_reply.sexual.2"),
    line("tool_reply.sexual.3"),
})
register("semantic.tool_reply.social.accepted.hostile_abuse", {
    line("tool_reply.hostile.1"),
    line("tool_reply.hostile.2"),
    line("tool_reply.hostile.3"),
})
register("semantic.tool_reply.social.accepted.admire", {
    line("tool_reply.admire.1"),
    line("tool_reply.admire.2"),
    line("tool_reply.admire.3"),
})
register("semantic.tool_reply.social.accepted.praise", {
    line("tool_reply.praise.1"),
    line("tool_reply.praise.2"),
    line("tool_reply.praise.3"),
})
register("semantic.tool_reply.social.accepted.comfort", {
    line("tool_reply.comfort.1"),
    line("tool_reply.comfort.2"),
    line("tool_reply.comfort.3"),
})
register("semantic.tool_reply.social.accepted.apologize", {
    line("tool_reply.apology.1"),
    line("tool_reply.apology.2"),
    line("tool_reply.apology.3"),
})
register("semantic.tool_reply.social.accepted.flirt", {
    line("tool_reply.flirt.1"),
    line("tool_reply.flirt.2"),
    line("tool_reply.flirt.3"),
})
register("semantic.tool_reply.social.accepted.insult", {
    line("tool_reply.insult.1"),
    line("tool_reply.insult.2"),
    line("tool_reply.insult.3"),
})
register("semantic.tool_reply.social.accepted.generic", {
    line("tool_reply.accepted_generic.1"),
    line("tool_reply.accepted_generic.2"),
})

-- Network-queued reactions remain explicitly non-committal.
register("semantic.tool_reply.social.queued.compliment", {
    line("tool_reply.queued_compliment.1"),
    line("tool_reply.queued_compliment.2"),
})
register("semantic.tool_reply.social.queued.romantic_interest", {
    line("tool_reply.queued_romantic.1"),
    line("tool_reply.queued_romantic.2"),
})
register("semantic.tool_reply.social.queued.sexual_advance", {
    line("tool_reply.queued_sexual.1"),
    line("tool_reply.queued_sexual.2"),
})
register("semantic.tool_reply.social.queued.hostile_abuse", {
    line("tool_reply.queued_hostile.1"),
    line("tool_reply.queued_hostile.2"),
})
register("semantic.tool_reply.social.queued.admire", {
    line("tool_reply.queued_admire.1"),
    line("tool_reply.queued_admire.2"),
})
register("semantic.tool_reply.social.queued.praise", {
    line("tool_reply.queued_praise.1"),
    line("tool_reply.queued_praise.2"),
})
register("semantic.tool_reply.social.queued.comfort", {
    line("tool_reply.queued_comfort.1"),
    line("tool_reply.queued_comfort.2"),
})
register("semantic.tool_reply.social.queued.apologize", {
    line("tool_reply.queued_apology.1"),
    line("tool_reply.queued_apology.2"),
})
register("semantic.tool_reply.social.queued.flirt", {
    line("tool_reply.queued_flirt.1"),
    line("tool_reply.queued_flirt.2"),
})
register("semantic.tool_reply.social.queued.insult", {
    line("tool_reply.queued_insult.1"),
    line("tool_reply.queued_insult.2"),
})
register("semantic.tool_reply.social.queued.generic", {
    line("tool_reply.queued_generic.1"),
    line("tool_reply.queued_generic.2"),
})

-- Rejections preserve the result reason/boundary chosen by the tool handler.
register("semantic.tool_reply.social.rejected.positive_cooldown_active", {
    line("tool_reply.cooldown.1"),
    line("tool_reply.cooldown.2"),
})
register("semantic.tool_reply.social.rejected.relationship_gate", {
    line("tool_reply.relationship.1"),
    line("tool_reply.relationship.2"),
})
register("semantic.tool_reply.social.rejected.personality_gate", {
    line("tool_reply.personality.1"),
    line("tool_reply.personality.2"),
})
register("semantic.tool_reply.social.rejected.orientation_gate", {
    line("tool_reply.orientation.1"),
    line("tool_reply.orientation.2"),
})
register("semantic.tool_reply.social.rejected.rejected_by_game", {
    line("tool_reply.rejected_game.1"),
    line("tool_reply.rejected_game.2"),
})
register("semantic.tool_reply.social.rejected.sexual_advance", {
    line("tool_reply.rejected_sexual.1"),
    line("tool_reply.rejected_sexual.2"),
    line("tool_reply.rejected_sexual.3"),
})
register("semantic.tool_reply.social.rejected.hostile_abuse", {
    line("tool_reply.rejected_hostile.1"),
    line("tool_reply.rejected_hostile.2"),
})
register("semantic.tool_reply.social.rejected.generic", {
    line("tool_reply.rejected_generic.1"),
    line("tool_reply.rejected_generic.2"),
})

register("semantic.tool_reply.ask_name.prompt", {
    line("tool_reply.ask_name.prompt"),
})
register("semantic.tool_reply.ask_name.named", {
    line("tool_reply.ask_name.named.1"),
    line("tool_reply.ask_name.named.2"),
    line("tool_reply.ask_name.named.3"),
})
register("semantic.tool_reply.ask_name.unnamed", {
    line("tool_reply.ask_name.unnamed.1"),
    line("tool_reply.ask_name.unnamed.2"),
})
register("semantic.tool_reply.ask_name.rejected", {
    line("tool_reply.ask_name.rejected.1"),
    line("tool_reply.ask_name.rejected.2"),
})

register("semantic.tool_reply.order.follow", {
    line("tool_reply.order_follow.1"),
    line("tool_reply.order_follow.2"),
    line("tool_reply.order_follow.3"),
})
register("semantic.tool_reply.order.stay", {
    line("tool_reply.order_stay.1"),
    line("tool_reply.order_stay.2"),
})
register("semantic.tool_reply.order.camp", {
    line("tool_reply.order_camp.1"),
    line("tool_reply.order_camp.2"),
    line("tool_reply.order_camp.3"),
})
register("semantic.tool_reply.order.accepted.generic", {
    line("tool_reply.order_generic.1"),
    line("tool_reply.order_generic.2"),
    line("tool_reply.order_generic.3"),
})
register("semantic.tool_reply.order.rejected", {
    line("tool_reply.order_rejected.1"),
    line("tool_reply.order_rejected.2"),
})

return true
