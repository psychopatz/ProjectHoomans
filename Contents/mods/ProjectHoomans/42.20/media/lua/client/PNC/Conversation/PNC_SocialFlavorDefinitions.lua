-- Project Hoomans' authored relationship-aware social flavor definitions.
-- Registration is client-side presentation data; gameplay remains authoritative
-- in the server relationship service.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore.SocialFlavor

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

return PNC.SocialFlavorDefinitions
