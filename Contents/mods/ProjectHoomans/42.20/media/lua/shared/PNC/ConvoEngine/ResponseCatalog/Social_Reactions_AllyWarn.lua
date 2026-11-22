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

local CALLOUT_SITUATIONS = {
    { role = "crawler", tpl = "combat.callout.threat.crawler" },
    { role = "blindside", tpl = "combat.callout.threat.blindside" },
    { role = "last_one", tpl = "combat.callout.threat.last_one" },
    { role = "bandaging_self", tpl = "medical.bandage.cover_warn.self" },
    { role = "bandaging_ally", tpl = "medical.bandage.cover_warn.ally" },
    { role = "checkin_injured", tpl = "combat.checkin.warn.injured" },
    { role = "checkin_clear", tpl = "combat.checkin.warn.clear" },
    { role = "weather_rain_open", tpl = "world.weather.rain_warn.rain_open" },
    { role = "stamina_winded", tpl = "condition.stamina.warn.winded" },
    { role = "stamina_exhausted", tpl = "condition.stamina.warn.exhausted" },
}

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

local REPLY_TEMPLATE_MAP = {
    engaging_neutral = "combat.callout.reply_engage.engaging_neutral",
    engaging_tactical = "combat.callout.reply_engage.engaging_tactical",
    engaging_hostile = "combat.callout.reply_engage.engaging_hostile",
    engaging_shaken = "combat.callout.reply_engage.engaging_shaken",
    engaging_brave = "combat.callout.reply_engage.engaging_brave",
    engaging_aggressive = "combat.callout.reply_engage.engaging_aggressive",
    engaging_supportive = "combat.callout.reply_engage.engaging_supportive",
    engaging_exhausted = "combat.callout.reply_engage.engaging_exhausted",
    anchor_combat = "combat.callout.reply_engage.anchor_combat",
    anchor_tactical = "combat.callout.reply_engage.anchor_tactical",
    alerted_neutral = "combat.callout.reply_alerted.alerted_neutral",
    alerted_tactical = "combat.callout.reply_alerted.alerted_tactical",
    alerted_hostile = "combat.callout.reply_alerted.alerted_hostile",
    blindside_reply = "combat.callout.reply_alerted.blindside_reply",
    last_one_reply = "combat.callout.reply_alerted.last_one_reply",
    defensive_neutral = "combat.callout.reply_defensive.defensive_neutral",
    defensive_shaken = "combat.callout.reply_defensive.defensive_shaken",
    wingman_defensive = "combat.callout.reply_defensive.wingman_defensive",
    wingman_engaging_neutral = "combat.callout.reply_wingman.engaging_neutral",
    wingman_engaging_tactical = "combat.callout.reply_wingman.engaging_tactical",
    wingman_engaging_hostile = "combat.callout.reply_wingman.engaging_hostile",
    wingman_shaken = "combat.callout.reply_wingman.shaken",
    wingman_brave = "combat.callout.reply_wingman.brave",
    wingman_aggressive = "combat.callout.reply_wingman.aggressive",
    wingman_alerted_neutral = "combat.callout.reply_wingman.alerted_neutral",
    wingman_alerted_tactical = "combat.callout.reply_wingman.alerted_tactical",
    cover_bandage_reply = "medical.bandage.cover_reply.cover_bandage",
    injured_has_bandage_reply = "medical.injury.status_reply.injured_has_bandage",
    injured_no_bandage_reply = "medical.injury.status_reply.injured_no_bandage",
    medic_has_bandage_reply = "medical.injury.status_reply.medic_has_bandage",
    medic_no_bandage_reply = "medical.injury.status_reply.medic_no_bandage",
    checkin_ok_reply = "combat.checkin.reply.ok",
}

local function replyVar(poolID, name, when, priority, act)
    local templateID = REPLY_TEMPLATE_MAP[name] or ("combat.callout.reply_engage." .. name)
    return makeVariant(poolID, templateID, name, when, priority, act)
end

local REPLY_SITUATIONS = {
    { role = "blindside_reply", tpl = "blindside_reply", pri = 97 },
    { role = "last_one_reply", tpl = "last_one_reply", pri = 97 },
    { role = "cover_bandage", tpl = "cover_bandage_reply", pri = 97 },
    { role = "injured_has_bandage", tpl = "injured_has_bandage_reply", pri = 97 },
    { role = "injured_no_bandage", tpl = "injured_no_bandage_reply", pri = 97 },
    { role = "medic_has_bandage", tpl = "medic_has_bandage_reply", pri = 97 },
    { role = "medic_no_bandage", tpl = "medic_no_bandage_reply", pri = 97 },
    { role = "checkin_ok", tpl = "checkin_ok_reply", pri = 97 },
}

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

return true
