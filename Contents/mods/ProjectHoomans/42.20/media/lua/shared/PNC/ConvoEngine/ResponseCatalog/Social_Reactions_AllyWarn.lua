-- Semantic ally threat-warning and reply response pools backed by CombatAllyWarning ConvoPlans.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/ConvoEngine/ResponseCatalog/EventReactions_Core"
local Templates = require "PNC/ConvoEngine/ResponseCatalog/Social_Reactions_AllyWarn_Templates"

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.events"
local CALLOUT_SITUATIONS = Templates.CALLOUT_SITUATIONS
local REPLY_TEMPLATE_MAP = Templates.REPLY_TEMPLATE_MAP
local REPLY_SITUATIONS = Templates.REPLY_SITUATIONS

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

local function registerCalloutPool(poolID, templatePrefix)
    local vars = {}
    for _, s in ipairs(CALLOUT_SITUATIONS) do
        vars[#vars + 1] = makeVariant(
            poolID, s.tpl, s.role,
            { combatReactionRole = s.role }, 95, "WARN"
        )
    end
    vars[#vars + 1] = makeVariant(poolID, templatePrefix .. "_hostile", "hostile", { combatReactionStyle = "hostile" }, 80, "WARN")
    vars[#vars + 1] = makeVariant(poolID, templatePrefix .. "_tactical", "tactical", { combatReactionStyle = "tactical" }, 75, "WARN")
    vars[#vars + 1] = makeVariant(poolID, templatePrefix .. "_neutral", "neutral", nil, 50, "WARN")
    Catalog.Register(poolID, { variants = vars })
end

registerCalloutPool("semantic.combat.ally_warn.callout.zombie", "combat.callout.threat.zombie")
registerCalloutPool("semantic.combat.ally_warn.callout.hostile", "combat.callout.threat.hostile")

local function replyVar(poolID, name, when, priority, act)
    local templateID = REPLY_TEMPLATE_MAP[name] or ("combat.callout.reply_engage." .. name)
    return makeVariant(poolID, templateID, name, when, priority, act)
end

local function appendReplySituations(vars, poolID, act)
    for _, s in ipairs(REPLY_SITUATIONS) do
        vars[#vars + 1] = replyVar(poolID, s.tpl, { combatReactionRole = s.role }, s.pri, act)
    end
    vars[#vars + 1] = makeVariant(
        poolID, "world.weather.rain_reply.rain_reply",
        "weather_rain_reply", { combatReactionRole = "weather_rain_reply" }, 97, act
    )
    vars[#vars + 1] = makeVariant(
        poolID, "condition.stamina.reply.cover_winded",
        "cover_winded", { combatReactionRole = "cover_winded" }, 97, act
    )
end

local function appendWingmanStats(vars, poolID)
    for _, v in ipairs({
        replyVar(poolID, "wingman_shaken", { combatReactionRole = "wingman", combatReactionStyle = "shaken" }, 95, "ACK"),
        replyVar(poolID, "wingman_brave", { combatReactionRole = "wingman", combatReactionStyle = "brave" }, 94, "ACK"),
        replyVar(poolID, "wingman_aggressive", { combatReactionRole = "wingman", combatReactionStyle = "aggressive" }, 95, "ACK"),
    }) do vars[#vars + 1] = v end
end

local P_ENG = "semantic.combat.ally_warn.reply.engaging"
local engVars = {}
appendWingmanStats(engVars, P_ENG)
for _, v in ipairs({
    replyVar(P_ENG, "anchor_tactical", { combatReactionRole = "anchor", combatReactionStyle = "tactical" }, 96, "ACK"),
    replyVar(P_ENG, "anchor_combat", { combatReactionRole = "anchor" }, 92, "ACK"),
    replyVar(P_ENG, "wingman_engaging_hostile", { combatReactionRole = "wingman", combatReactionStyle = "hostile" }, 95, "ACK"),
    replyVar(P_ENG, "wingman_engaging_tactical", { combatReactionRole = "wingman", combatReactionStyle = "tactical" }, 94, "ACK"),
    replyVar(P_ENG, "wingman_engaging_neutral", { combatReactionRole = "wingman" }, 90, "ACK"),
    replyVar(P_ENG, "engaging_shaken", { combatReactionStyle = "shaken" }, 82, "ACK"),
    replyVar(P_ENG, "engaging_hostile", { combatReactionStyle = "hostile" }, 80, "ACK"),
    replyVar(P_ENG, "engaging_aggressive", { combatReactionStyle = "aggressive" }, 79, "ACK"),
    replyVar(P_ENG, "engaging_exhausted", { combatReactionStyle = "exhausted" }, 78, "ACK"),
    replyVar(P_ENG, "engaging_brave", { combatReactionStyle = "brave" }, 77, "ACK"),
    replyVar(P_ENG, "engaging_supportive", { combatReactionStyle = "supportive" }, 76, "ACK"),
    replyVar(P_ENG, "engaging_tactical", { combatReactionStyle = "tactical" }, 75, "ACK"),
    replyVar(P_ENG, "engaging_neutral", nil, 50, "ACK"),
}) do engVars[#engVars + 1] = v end
Catalog.Register(P_ENG, { variants = engVars })

local P_ALT = "semantic.combat.ally_warn.reply.alerted"
local altVars = {}
appendWingmanStats(altVars, P_ALT)
for _, v in ipairs({
    replyVar(P_ALT, "anchor_tactical", { combatReactionRole = "anchor", combatReactionStyle = "tactical" }, 96, "ACK"),
    replyVar(P_ALT, "anchor_combat", { combatReactionRole = "anchor" }, 92, "ACK"),
    replyVar(P_ALT, "wingman_alerted_tactical", { combatReactionRole = "wingman", combatReactionStyle = "tactical" }, 95, "ACK"),
    replyVar(P_ALT, "wingman_alerted_neutral", { combatReactionRole = "wingman" }, 90, "ACK"),
    replyVar(P_ALT, "engaging_shaken", { combatReactionStyle = "shaken" }, 82, "ACK"),
    replyVar(P_ALT, "alerted_hostile", { combatReactionStyle = "hostile" }, 80, "ACK"),
    replyVar(P_ALT, "engaging_aggressive", { combatReactionStyle = "aggressive" }, 79, "ACK"),
    replyVar(P_ALT, "engaging_exhausted", { combatReactionStyle = "exhausted" }, 78, "ACK"),
    replyVar(P_ALT, "engaging_brave", { combatReactionStyle = "brave" }, 77, "ACK"),
    replyVar(P_ALT, "engaging_supportive", { combatReactionStyle = "supportive" }, 76, "ACK"),
    replyVar(P_ALT, "alerted_tactical", { combatReactionStyle = "tactical" }, 75, "ACK"),
    replyVar(P_ALT, "alerted_neutral", nil, 50, "ACK"),
}) do altVars[#altVars + 1] = v end
Catalog.Register(P_ALT, { variants = altVars })

local P_DEF = "semantic.combat.ally_warn.reply.defensive"
local defVars = {}
appendReplySituations(defVars, P_DEF, "ACK")
for _, v in ipairs({
    replyVar(P_DEF, "wingman_defensive", { combatReactionRole = "wingman" }, 90, "REACT"),
    replyVar(P_DEF, "defensive_shaken", { combatReactionStyle = "shaken" }, 75, "REACT"),
    replyVar(P_DEF, "defensive_neutral", nil, 50, "REACT"),
}) do defVars[#defVars + 1] = v end
Catalog.Register(P_DEF, { variants = defVars })

require "PNC/ConvoEngine/ResponseCatalog/Social_Reactions_CombatInjury"

return true
