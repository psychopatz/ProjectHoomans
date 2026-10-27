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
    { id = "follow", commandID = "follow", act = "DIRECTIVE", fallback = "{names}, on me." },
    { id = "stay", commandID = "stay", act = "DIRECTIVE", fallback = "{names}, wait here." },
    { id = "camp", commandID = "camp", act = "DIRECTIVE", fallback = "Make camp here, {names}." },
    {
        id = "camp_none", commandID = "camp", outcome = "none",
        priority = 4, fallback = "...",
    },
    {
        id = "camp_rejected", commandID = "camp", outcome = "invalid",
        priority = 4,
        fallback = "We need a nearby room or campfire before we make camp.",
    },
    { id = "return_home", commandID = "return_home", act = "DIRECTIVE", fallback = "{names}, head home." },
    { id = "attack_auto", commandID = "attack_auto", act = "DIRECTIVE", fallback = "{name}, use your best judgment." },
    { id = "attack_melee", commandID = "attack_melee", act = "DIRECTIVE", fallback = "{name}, keep it close." },
    { id = "attack_ranged", commandID = "attack_ranged", act = "DIRECTIVE", fallback = "{name}, keep your distance." },
    { id = "attack_none", commandID = "attack_none", act = "DIRECTIVE", fallback = "{name}, stay out of the fight." },
    { id = "generic", fallback = "Understood, {names}." },
}

local REPLY = {
    { id = "follow", commandID = "follow", fallback = "Right behind you." },
    { id = "stay", commandID = "stay", fallback = "I'll stay here." },
    { id = "camp", commandID = "camp", fallback = "We'll make camp here." },
    { id = "return_home", commandID = "return_home", fallback = "Heading home." },
    { id = "attack_auto", commandID = "attack_auto", fallback = "I'll handle it." },
    { id = "attack_melee", commandID = "attack_melee", fallback = "Going in close." },
    { id = "attack_ranged", commandID = "attack_ranged", fallback = "I'll cover you." },
    { id = "attack_none", commandID = "attack_none", fallback = "I won't engage." },
    {
        id = "camp_rejected", commandID = "camp", outcome = "invalid",
        priority = 4,
        fallback = "I can't find a safe room or campfire nearby.",
    },
    {
        id = "generic_rejected", outcome = "invalid", priority = 2,
        fallback = "I can't do that right now.",
    },
    { id = "generic", fallback = "I hear you." },
}

local function whenFor(row)
    local when = {}
    if row.commandID then when.commandID = row.commandID end
    if row.outcome then when.commandOutcome = row.outcome end
    return when
end

local function variants(rows, poolID, act)
    local output = {}
    for index, row in ipairs(rows) do
        local semanticID = "semantic." .. poolID .. "." .. row.id
        local topic = poolID == "command.player"
            and "companion_command" or "companion_command_reply"
        output[#output + 1] = {
            id = semanticID,
            templateID = semanticID,
            fallback = row.fallback,
            contentOwner = OWNER,
            dialogueAct = row.act or act or "REPLY",
            topic = topic,
            when = whenFor(row),
            priority = tonumber(row.priority) or (row.commandID and 2 or 0),
            plan = {
                dialogueAct = row.act or act or "REPLY",
                sourcePoolID = "semantic." .. poolID,
                topic = topic,
                turns = { { segments = {
                    { kind = "literal", text = row.fallback },
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

return true
