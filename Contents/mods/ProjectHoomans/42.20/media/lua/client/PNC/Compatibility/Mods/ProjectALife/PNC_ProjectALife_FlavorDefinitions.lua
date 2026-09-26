-- Localized Hoomans dialogue for Project A-Life world events.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

local Flavor = PsychopatzCore.SocialFlavor

local function translatedLine(key, fallback)
    local translation = PNC.Translation
    local value = translation and type(translation.GetKey) == "function"
        and translation.GetKey(key, fallback) or fallback
    return { key = key, fallback = value }
end

local definitions = {
    {
        id = "projectalife.meta_gunfire",
        keys = {
            "UI_PNC_Conversation_ProjectALife_MetaGunfire_01",
            "UI_PNC_Conversation_ProjectALife_MetaGunfire_02",
        },
        fallback = {
            "Someone is shooting out there. Keep your head down, {playerFirstName}.",
            "Hear those shots? Let's stay alert, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.meta_aircraft",
        keys = {
            "UI_PNC_Conversation_ProjectALife_MetaAircraft_01",
            "UI_PNC_Conversation_ProjectALife_MetaAircraft_02",
        },
        fallback = {
            "Something is flying over us. Keep listening, {playerFirstName}.",
            "That aircraft sounds close. We should stay sharp.",
        },
    },
    {
        id = "projectalife.meta_crash",
        keys = {
            "UI_PNC_Conversation_ProjectALife_MetaCrash_01",
            "UI_PNC_Conversation_ProjectALife_MetaCrash_02",
        },
        fallback = {
            "That crash sounded close. Let's be careful.",
            "Something went down nearby. Keep your eyes open, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.meta_ambience",
        keys = {
            "UI_PNC_Conversation_ProjectALife_MetaAmbience_01",
            "UI_PNC_Conversation_ProjectALife_MetaAmbience_02",
        },
        fallback = {
            "I do not like that sound. Stay close, {playerFirstName}.",
            "Something feels wrong out there. Keep your guard up.",
        },
    },
    {
        id = "projectalife.encounter_friendly",
        keys = {
            "UI_PNC_Conversation_ProjectALife_EncounterFriendly_01",
            "UI_PNC_Conversation_ProjectALife_EncounterFriendly_02",
        },
        fallback = {
            "Those survivors seem friendly. Let's approach carefully.",
            "They might be willing to talk. Keep your hands visible, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.encounter_hostile",
        keys = {
            "UI_PNC_Conversation_ProjectALife_EncounterHostile_01",
            "UI_PNC_Conversation_ProjectALife_EncounterHostile_02",
        },
        fallback = {
            "That group looks hostile. Keep cover between us and them.",
            "They are not here to make friends. Stay close, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.encounter_unknown",
        keys = {
            "UI_PNC_Conversation_ProjectALife_EncounterUnknown_01",
            "UI_PNC_Conversation_ProjectALife_EncounterUnknown_02",
        },
        fallback = {
            "Someone is out there. Let's watch before we approach.",
            "Keep your distance until we know what they want, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.faction_hostile",
        keys = {
            "UI_PNC_Conversation_ProjectALife_FactionHostile_01",
            "UI_PNC_Conversation_ProjectALife_FactionHostile_02",
        },
        fallback = {
            "The {factionName} may be hostile toward us now. Stay alert.",
            "Word has reached the {factionName}. Keep your guard up, {playerFirstName}.",
        },
    },
    {
        id = "projectalife.faction_conflict_incoming",
        keys = {
            "UI_PNC_Conversation_ProjectALife_FactionConflictIncoming_01",
            "UI_PNC_Conversation_ProjectALife_FactionConflictIncoming_02",
        },
        fallback = {
            "The {factionName} just opened fire on us. Stay close, {playerFirstName}.",
            "We were hit by the {factionName}. Expect them to come back.",
        },
    },
    {
        id = "projectalife.faction_conflict_outgoing",
        keys = {
            "UI_PNC_Conversation_ProjectALife_FactionConflictOutgoing_01",
            "UI_PNC_Conversation_ProjectALife_FactionConflictOutgoing_02",
        },
        fallback = {
            "We hit the {factionName}. They may retaliate soon.",
            "That fight changed things with the {factionName}. Keep watch, {playerFirstName}.",
        },
    },
}

for index = 1, #definitions do
    local definition = definitions[index]
    local lines = {}
    for lineIndex = 1, #definition.keys do
        lines[lineIndex] = translatedLine(
            definition.keys[lineIndex],
            definition.fallback[lineIndex])
    end
    Flavor.Register(definition.id, {
        id = definition.id,
        family = "projectalife_world_event",
        npc = lines,
    })
end

return Flavor
