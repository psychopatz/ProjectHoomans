-- Shared builders for cohesive SpeechRealization content packs.

local Builders = {}

function Builders.phraseFamily(prefix, neutral, warm, terse, guarded)
    local base = "UI_PNC_Conversation_Semantic_Realization"
        .. tostring(prefix)
    return {
        neutral = { key = base .. "Neutral", fallback = neutral },
        warm = { key = base .. "Warm", fallback = warm },
        terse = { key = base .. "Terse", fallback = terse },
        guarded = { key = base .. "Guarded", fallback = guarded },
    }
end

function Builders.bondPhraseFamily(prefix, neutral, warm, terse, guarded)
    local family = Builders.phraseFamily(
        prefix, neutral, warm, terse, guarded
    )
    local base = "UI_PNC_Conversation_Semantic_Realization"
        .. tostring(prefix) .. "Bond"
    family.bond = {
        any = {
            neutral = {
                key = base .. "Neutral", fallback = neutral,
                argument = "familyAddress", forceKey = true,
            },
            warm = {
                key = base .. "Warm", fallback = warm,
                argument = "familyAddress", forceKey = true,
            },
            terse = {
                key = base .. "Terse", fallback = terse,
                argument = "familyAddress", forceKey = true,
            },
            guarded = {
                key = base .. "Guarded", fallback = guarded,
                argument = "familyAddress", forceKey = true,
            },
        },
    }
    return family
end

return Builders
