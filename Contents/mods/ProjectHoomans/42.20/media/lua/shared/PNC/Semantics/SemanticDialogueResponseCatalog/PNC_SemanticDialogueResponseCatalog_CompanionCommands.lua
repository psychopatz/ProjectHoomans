-- Semantic meaning pools for companion directives and their bounded replies.
-- Wording is applied only by SpeechRealization/Dialogue Content.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local OWNER = "projecthoomans.dialogue_content.commands_emotes"

local PLAYER = {
    { id = "follow", commandID = "follow", act = "DIRECTIVE" },
    { id = "stay", commandID = "stay", act = "DIRECTIVE" },
    { id = "camp", commandID = "camp", act = "DIRECTIVE" },
    {
        id = "camp_none", commandID = "camp", outcome = "none",
        priority = 4,
    },
    {
        id = "camp_rejected", commandID = "camp", outcome = "invalid",
        priority = 4,
    },
    { id = "return_home", commandID = "return_home", act = "DIRECTIVE" },
    { id = "attack_auto", commandID = "attack_auto", act = "DIRECTIVE" },
    { id = "attack_melee", commandID = "attack_melee", act = "DIRECTIVE" },
    { id = "attack_ranged", commandID = "attack_ranged", act = "DIRECTIVE" },
    { id = "attack_none", commandID = "attack_none", act = "DIRECTIVE" },
    { id = "generic" },
}

local HORDE_ACK = {
    {
        id = "engage_eager",
        commandID = "combat_engage",
        combatReactionStyle = { "aggressive", "brave" },
        priority = 4,
    },
    {
        id = "engage_hesitant",
        commandID = "combat_engage",
        combatReactionStyle = "shaken",
        priority = 4,
    },
    {
        id = "engage_reserved",
        commandID = "combat_engage",
        combatReactionStyle = { "reserved", "cold" },
        priority = 3,
    },
    { id = "engage_default", commandID = "combat_engage" },
    {
        id = "avoid_relief",
        commandID = "combat_avoid",
        combatReactionStyle = { "shaken", "supportive" },
        priority = 4,
    },
    { id = "avoid_default", commandID = "combat_avoid" },
    {
        id = "hold_eager",
        commandID = "combat_hold",
        combatReactionStyle = { "aggressive", "brave" },
        priority = 3,
    },
    {
        id = "hold_hesitant",
        commandID = "combat_hold",
        combatReactionStyle = "shaken",
        priority = 3,
    },
    { id = "hold_default", commandID = "combat_hold" },
}

local REPLY = {
    { id = "follow", commandID = "follow" },
    { id = "stay", commandID = "stay" },
    { id = "camp", commandID = "camp" },
    { id = "return_home", commandID = "return_home" },
    { id = "attack_auto", commandID = "attack_auto" },
    { id = "attack_melee", commandID = "attack_melee" },
    { id = "attack_ranged", commandID = "attack_ranged" },
    { id = "attack_none", commandID = "attack_none" },
    {
        id = "camp_rejected", commandID = "camp", outcome = "invalid",
        priority = 4,
    },
    {
        id = "generic_rejected", outcome = "invalid", priority = 2,
    },
    { id = "generic" },
}

local function whenFor(row)
    local when = {}
    if row.commandID then when.commandID = row.commandID end
    if row.outcome then when.commandOutcome = row.outcome end
    if row.combatReactionStyle then
        when.combatReactionStyle = row.combatReactionStyle
    end
    return when
end

local function variants(rows, poolID, act, presentationClass)
    local output = {}
    for index, row in ipairs(rows) do
        local semanticID = "semantic." .. poolID .. "." .. row.id
        local topic = poolID == "command.player"
            and "companion_command" or "companion_command_reply"
        output[#output + 1] = {
            id = semanticID,
            templateID = semanticID,
            contentOwner = OWNER,
            dialogueAct = row.act or act or "REPLY",
            topic = topic,
            when = whenFor(row),
            priority = tonumber(row.priority) or (row.commandID and 2 or 0),
            plan = {
                dialogueAct = row.act or act or "REPLY",
                sourcePoolID = "semantic." .. poolID,
                topic = topic,
                presentationClass = presentationClass,
                turns = { { segments = {
                    { kind = "translation", templateID = semanticID },
                } } },
            },
        }
    end
    return output
end

Catalog.Register("semantic.command.player", {
    variants = variants(PLAYER, "command.player", "DIRECTIVE"),
})
Catalog.Register("semantic.command.reply", {
    variants = variants(REPLY, "command.reply", "ACK"),
})
Catalog.Register("semantic.combat.horde.ack", {
    variants = variants(HORDE_ACK, "combat.horde.ack", "ACK", "BARK"),
})

return true
