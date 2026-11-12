-- Shared registration helpers for data-only built-in conversation modules.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Helpers = PNC.Conversation.DefinitionHelpers or {}
PNC.Conversation.DefinitionHelpers = Helpers

Helpers.MOD_ID = "ProjectHoomans"
Helpers.PREFIX = "projecthoomans:"

function Helpers.Source(target, textOwner)
    local domain = string.gsub(target, "/", ".")
    local TextCatalog = PsychopatzCore.Conversation.TextCatalog
    return TextCatalog.Source({
        modID = textOwner or Helpers.MOD_ID,
        target = target,
        domain = "pnc." .. domain,
    })
end

function Helpers.Outcome(id, responseKey, options)
    options = options or {}
    return {
        id = id,
        weight = options.weight or 1,
        responseKey = responseKey,
        npcReaction = options.npcReaction,
        next = options.next,
        close = options.close == true,
        effects = options.effects or {},
        gates = options.gates,
    }
end

function Helpers.ContinueChoice(id, effects)
    return {
        id = id,
        textKey = "choice." .. id,
        outcomes = {
            Helpers.Outcome("reply", "response." .. id, {
                next = "$root",
                effects = effects,
            }),
        },
    }
end

function Helpers.RegisterSimple(kind, audience, textTarget, options)
    options = options or {}
    return PNC.Conversation.Registry.RegisterBlock(
        Helpers.PREFIX .. kind .. "_" .. audience,
        {
            schemaVersion = 1,
            ownerModID = Helpers.MOD_ID,
            category = Helpers.PREFIX .. kind,
            audiences = { audience },
            priority = options.priority or 0,
            weight = options.weight or 100,
            textSource = Helpers.Source(textTarget, options.textOwner),
            entryNode = "opening",
            gates = options.gates,
            ["repeat"] = options["repeat"],
            nodes = options.nodes or {
                opening = {
                    textKey = "opening",
                    choices = options.choices or {},
                },
            },
        }
    )
end

return Helpers
