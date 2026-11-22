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

local function makeVariant(poolID, templatePrefix, id, when, priority, act)
    local templateID = templatePrefix .. "_" .. id
    return {
        id = poolID .. "." .. id,
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
            makeVariant(poolID, templatePrefix, "hostile", { combatReactionStyle = "hostile" }, 80, act),
            makeVariant(poolID, templatePrefix, "tactical", { combatReactionStyle = "tactical" }, 75, act),
            makeVariant(poolID, templatePrefix, "neutral", nil, 50, act),
        },
    })
end

registerTonePool("semantic.combat.ally_warn.callout.zombie", "combat.ally_warn.callout.zombie", "WARN")
registerTonePool("semantic.combat.ally_warn.callout.hostile", "combat.ally_warn.callout.hostile", "WARN")
registerTonePool("semantic.combat.ally_warn.reply.engaging", "combat.ally_warn.reply.engaging", "ACK")
registerTonePool("semantic.combat.ally_warn.reply.alerted", "combat.ally_warn.reply.alerted", "ACK")

Catalog.Register("semantic.combat.ally_warn.reply.defensive", {
    variants = {
        makeVariant(
            "semantic.combat.ally_warn.reply.defensive",
            "combat.ally_warn.reply.defensive",
            "shaken",
            { combatReactionStyle = "shaken" },
            75,
            "REACT"
        ),
        makeVariant(
            "semantic.combat.ally_warn.reply.defensive",
            "combat.ally_warn.reply.defensive",
            "neutral",
            nil,
            50,
            "REACT"
        ),
    },
})

return true
