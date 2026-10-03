-- Deterministic social flavor registration shard.
local Definitions = PNC.SocialFlavorDefinitions
local Internal = Definitions.Internal
local Flavor = Internal.Flavor
local translatedLine = Internal.translatedLine

Flavor.Register("social.conversation_farewell", {
    id = "social.conversation_farewell",
    family = "conversation_farewell",
    player = {
        "We are done here. Take care, {npcFirstName}.",
        "I should let you get back to it. Stay safe, {npcFirstName}.",
        "That is enough for now. See you around, {npcFirstName}.",
    },
    npc = {
        "Take care, {playerFirstName}.",
        "Stay safe out there, {playerFirstName}.",
        "See you around, {playerFirstName}.",
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            player = {
                "We are finished. Keep your distance.",
                "That is enough. Do not follow me.",
                "I am leaving. Stay out of my way.",
            },
            npc = {
                "Keep walking.",
                "Do not make this a habit.",
                "Stay out of my way.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            player = {
                "I will let you get back to it, love. Stay safe.",
                "See you soon, love. Come back safe.",
                "That is enough for now, sweetheart. I will see you soon.",
            },
            npc = {
                "Come back safe, love.",
                "I will see you soon, sweetheart.",
                "Stay safe for me, love.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            player = {
                "Take care of yourself. I will see you soon.",
                "I should let you go. Stay safe, family.",
                "See you around. Keep your guard up.",
            },
            npc = {
                "Take care of yourself.",
                "See you soon. Keep your guard up.",
                "Stay safe out there, family.",
            },
        },
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            player = {
                "I will let you get back to camp. Stay safe.",
                "See you at camp. Keep your eyes open.",
                "That is enough for now. Watch yourself out there.",
            },
            npc = {
                "Stay safe out there.",
                "See you at camp.",
                "Keep your eyes open. I will see you around.",
            },
        },
    },
})

Flavor.Register("social.witnessed_player_kill", {
    id = "social.witnessed_player_kill",
    family = "combat_commentary",
    npc = {
        "That was clean, {playerFirstName}. I did not expect you to handle it that well.",
        "One less corpse to worry about, {playerFirstName}. Nice work.",
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                "Damn. I was hoping that one would take you down, {playerFirstName}.",
                "You got lucky, {playerFirstName}. Do not get cocky.",
                "Not bad, {playerFirstName}. I still would have enjoyed watching it get you.",
            },
        },
        {
            id = "neutral",
            when = { socialRole = "neutral" },
            npc = {
                "That was clean, {playerFirstName}. I did not expect you to handle it that well.",
                "I will admit it, {playerFirstName}, that was impressive.",
                "You made short work of it, {playerFirstName}. Good to know.",
            },
        },
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "Good work, {playerFirstName}. That is how we keep the camp safe.",
                "That is my survivor, {playerFirstName}. Keep it up, I am proud of you.",
                "One less threat for all of us, {playerFirstName}. Well handled.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "I knew you could do it, {playerFirstName}. Just do not scare me like that again.",
                "You are safe, {playerFirstName}. That is what matters. Nice work, love.",
                "I am proud of you, {playerFirstName}, but please do not take risks like that.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "That is my family, {playerFirstName}. Good work, and stay close.",
                "You handled it, {playerFirstName}. I knew you would. Keep your guard up.",
                "One less thing trying to kill us, {playerFirstName}. Nice job, family.",
            },
        },
    },
})

Flavor.Register("social.witnessed_teammate_hurt", {
    id = "social.witnessed_teammate_hurt",
    family = "combat_commentary",
    npc = {
        "{victimFirstName}, you okay? Stay with me.",
        "Keep breathing, {victimFirstName}. I have got you.",
        "You are hit, {victimFirstName}. Fall back and let me cover you.",
    },
    variants = {
        {
            id = "bandage_request_resolved",
            when = { medicalSupplyRequestStatus = "resolved" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_MedicalBandage_Resolved_1",
                    "Never mind, {victimFirstName}. We don't need you to find a bandage for that request now."
                ),
            },
        },
        {
            id = "bandage_request_fulfilled",
            when = {
                medicalBandageRequired = true,
                medicalBandageStatus = "found",
            },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_MedicalBandage_Found_1",
                    "We found a bandage for you, {victimFirstName}. Hold still while I patch you up."
                ),
                translatedLine(
                    "UI_PNC_Conversation_MedicalBandage_Found_2",
                    "I've got a bandage now, {victimFirstName}. Let me take care of that wound."
                ),
            },
        },
        {
            id = "out_of_bandages",
            when = {
                medicalBandageRequired = true,
                medicalBandageStatus = "missing",
            },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_MedicalBandage_Missing_1",
                    "I'm out of bandages. Can you or someone in the group spare one for {victimFirstName}?"
                ),
                translatedLine(
                    "UI_PNC_Conversation_MedicalBandage_Missing_2",
                    "I need a bandage for {victimFirstName}. Does anyone in the group have one to share?"
                ),
            },
        },
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                "Get up, {victimFirstName}. Do not make me drag you.",
                "You are not dying here, {victimFirstName}. Move.",
                "Keep fighting, {victimFirstName}. I will not cover a corpse.",
            },
        },
        {
            id = "neutral",
            when = { socialRole = "neutral" },
            npc = {
                "You okay, {victimFirstName}? Keep your head down.",
                "That looked bad, {victimFirstName}. Stay behind me.",
                "You are hit, {victimFirstName}. Tell me if you need help.",
            },
        },
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "You alright, {victimFirstName}? I have got you.",
                "Stay with us, {victimFirstName}. We will get you patched up.",
                "Take cover, {victimFirstName}. Nobody gets left behind.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "Are you okay, {victimFirstName}? Please stay close to me.",
                "You are hurt, {victimFirstName}. I am right here, love.",
                "Keep breathing, {victimFirstName}. We are getting you safe.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "You okay, {victimFirstName}? Stay with the family.",
                "Hold on, {victimFirstName}. We have got your back.",
                "Get behind us, {victimFirstName}. We are not losing family today.",
            },
        },
    },
})

return Definitions
