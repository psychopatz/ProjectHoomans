-- Semantic ally threat-warning and reply response pools backed by CombatAllyWarning ConvoPlans.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/ConvoEngine/ResponseCatalog/EventReactions_Core"

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.events"

local function makeVariant(poolID, templateID, variantID, when, priority, act)
    return {
        id = poolID .. "." .. variantID,
        templateID = templateID,
        contentOwner = CONTENT_OWNER,
        when = when,
        priority = priority or 0,
        plan = {
            dialogueAct = act,
            sourcePoolID = poolID,
            topic = "combat",
            presentationClass = "BARK",
            turns = { {
                segments = {
                    { kind = "translation", templateID = templateID },
                },
                offers = {},
            } },
        },
    }
end

local function registerTonePool(poolID, templatePrefix, act)
    Catalog.Register(poolID, {
        variants = {
            makeVariant(poolID, templatePrefix .. "_hostile", "hostile", { combatReactionStyle = "hostile" }, 80, act),
            makeVariant(poolID, templatePrefix .. "_tactical", "tactical", { combatReactionStyle = "tactical" }, 75, act),
            makeVariant(poolID, templatePrefix .. "_neutral", "neutral", nil, 50, act),
        },
    })
end

registerTonePool("semantic.combat.ally_warn.callout.zombie", "combat.ally_warn.callout.zombie", "WARN")
registerTonePool("semantic.combat.ally_warn.callout.hostile", "combat.ally_warn.callout.hostile", "WARN")

local function replyVar(poolID, name, when, priority, act)
    return makeVariant(poolID, "combat.ally_warn.reply." .. name, name, when, priority, act)
end

local P_ENG = "semantic.combat.ally_warn.reply.engaging"
Catalog.Register(P_ENG, {
    variants = {
        replyVar(P_ENG, "anchor_tactical", { combatReactionRole = "anchor", combatReactionStyle = "tactical" }, 96, "ACK"),
        replyVar(P_ENG, "anchor_combat", { combatReactionRole = "anchor" }, 92, "ACK"),
        replyVar(P_ENG, "wingman_engaging_hostile", { combatReactionRole = "wingman", combatReactionStyle = "hostile" }, 95, "ACK"),
        replyVar(P_ENG, "wingman_engaging_tactical", { combatReactionRole = "wingman", combatReactionStyle = "tactical" }, 94, "ACK"),
        replyVar(P_ENG, "wingman_engaging_neutral", { combatReactionRole = "wingman" }, 90, "ACK"),
        replyVar(P_ENG, "engaging_hostile", { combatReactionStyle = "hostile" }, 80, "ACK"),
        replyVar(P_ENG, "engaging_tactical", { combatReactionStyle = "tactical" }, 75, "ACK"),
        replyVar(P_ENG, "engaging_neutral", nil, 50, "ACK"),
    },
})

local P_ALT = "semantic.combat.ally_warn.reply.alerted"
Catalog.Register(P_ALT, {
    variants = {
        replyVar(P_ALT, "anchor_tactical", { combatReactionRole = "anchor", combatReactionStyle = "tactical" }, 96, "ACK"),
        replyVar(P_ALT, "anchor_combat", { combatReactionRole = "anchor" }, 92, "ACK"),
        replyVar(P_ALT, "wingman_alerted_tactical", { combatReactionRole = "wingman", combatReactionStyle = "tactical" }, 95, "ACK"),
        replyVar(P_ALT, "wingman_alerted_neutral", { combatReactionRole = "wingman" }, 90, "ACK"),
        replyVar(P_ALT, "alerted_hostile", { combatReactionStyle = "hostile" }, 80, "ACK"),
        replyVar(P_ALT, "alerted_tactical", { combatReactionStyle = "tactical" }, 75, "ACK"),
        replyVar(P_ALT, "alerted_neutral", nil, 50, "ACK"),
    },
})

local P_DEF = "semantic.combat.ally_warn.reply.defensive"
Catalog.Register(P_DEF, {
    variants = {
        replyVar(P_DEF, "wingman_defensive", { combatReactionRole = "wingman" }, 90, "REACT"),
        replyVar(P_DEF, "defensive_shaken", { combatReactionStyle = "shaken" }, 75, "REACT"),
        replyVar(P_DEF, "defensive_neutral", nil, 50, "REACT"),
    },
})

return true
