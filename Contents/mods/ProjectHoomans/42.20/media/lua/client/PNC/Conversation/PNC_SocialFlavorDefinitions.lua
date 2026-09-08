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

Flavor.Register("social.follower_abandoned_zombie", {
    id = "social.follower_abandoned_zombie",
    family = "relationship_commentary",
    npc = {
        "You left me with the dead back there, {playerFirstName}. Do not do that again.",
        "I was still fighting those dead when you ran. Stay with me next time, {playerFirstName}.",
    },
    variants = {
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "You left me with the dead back there, {playerFirstName}. We are supposed to watch each other's backs.",
                "I was still fighting those dead when you ran. Do not leave a colonist behind again, {playerFirstName}.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "You left me with the dead, love. I needed you to stay.",
                "I was still fighting those dead when you ran. Please do not leave me like that again.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "You left family with the dead back there, {playerFirstName}. We stay together.",
                "I was still fighting those dead when you ran. Do not abandon family again.",
            },
        },
    },
})

Flavor.Register("social.follower_abandoned_hostile_npc", {
    id = "social.follower_abandoned_hostile_npc",
    family = "relationship_commentary",
    npc = {
        "You left me to deal with that hostile alone, {playerFirstName}. Do not do that again.",
        "That hostile was still on me when you ran. Stay and help next time, {playerFirstName}.",
    },
    variants = {
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "You left me to deal with that hostile alone, {playerFirstName}. We are supposed to cover each other.",
                "That hostile was still on me when you ran. Do not leave a colonist behind again.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "You left me alone with that hostile, love. I needed you to stay.",
                "That hostile was still on me when you ran. Please do not do that again.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "You left family alone with that hostile, {playerFirstName}. We stay together.",
                "That hostile was still on me when you ran. Do not abandon family again.",
            },
        },
    },
})

Flavor.Register("social.player_spoke", {
    id = "social.player_spoke",
    family = "player_speech_reaction",
    npc = {
        "I heard you, {playerFirstName}.",
        "Right, {playerFirstName}. I am listening.",
        "Understood, {playerFirstName}.",
    },
    variants = {
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "I heard you, {playerFirstName}. We will handle it together.",
                "Understood, {playerFirstName}. I am with you.",
            },
        },
    },
})

Flavor.Register("social.conversation_safety_danger", {
    id = "social.conversation_safety_danger",
    family = "conversation_safety",
    npc = {
        "Not safe to talk right now, {playerFirstName}. Eyes up and stay vigilant.",
        "Hold that thought. Trouble is close; stay vigilant, {playerFirstName}.",
        "We need to stop talking for now. Keep watch, {playerFirstName}.",
        "Not here. Something dangerous is too close; keep your guard up.",
        "Let's pause this. We can finish when the area is clear.",
        "I hear trouble nearby. Stay ready and watch our surroundings.",
        "Conversation can wait. Surviving this comes first.",
        "We are exposed right now. Keep watch until it is safe.",
        "Something is moving out there. Stay alert and stay close.",
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                "We're done here. Danger is closing in; stay vigilant.",
                "Not safe to talk with that threat nearby. Keep your eyes open.",
                "Eyes up. I won't keep you exposed. Stay vigilant.",
                "Enough. Deal with the danger first, then we can talk.",
                "Something nearby wants us dead. Stay ready.",
                "Back to business. Conversation can wait until we're clear.",
                "Move. I hear trouble close by.",
                "We can settle this later. Survive the next minute first.",
                "Do not stand still. The threat is too close for talk.",
            },
        },
        {
            id = "neutral",
            when = { socialRole = "neutral" },
            npc = {
                "Not safe to talk right now, {playerFirstName}. Stay vigilant.",
                "Something is moving nearby. We should stop talking and stay vigilant.",
                "Let's pause this. Keep watch until the danger passes.",
                "Hold on. This area isn't safe enough for a conversation.",
                "I hear trouble close by. Keep your guard up.",
                "We should keep watch instead of talking right now.",
                "Let's pick this up after the threat moves on.",
                "Something is wrong nearby. Stay ready, {playerFirstName}.",
                "Conversation can wait. Watch your surroundings.",
            },
        },
        {
            id = "colonist",
            when = { socialRole = { "colonist", "member" } },
            npc = {
                "Conversation's over for now. Something's close; stay vigilant, {playerFirstName}.",
                "Eyes up, {playerFirstName}. We can talk again when the camp is safe.",
                "Hold on the discussion. Keep watch and stay vigilant, everyone.",
                "Threat nearby. Stay with the group and keep your weapon ready.",
                "We need all eyes outside the camp, not on this conversation.",
                "Let's secure the area first. We'll finish this afterward.",
                "Something has us exposed. Fall quiet and watch the perimeter.",
                "Stay close, {playerFirstName}. We can talk when the danger clears.",
                "The camp comes first. Keep watch until we're safe.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "We need to stop talking, love. Something's close; stay vigilant.",
                "Not safe to talk right now, {playerFirstName}. Stay close and keep watch.",
                "Eyes up, love. We'll finish this when the danger passes.",
                "Please stay with me. I hear something nearby.",
                "Forget the conversation for now. I need you watching our backs.",
                "We're exposed, love. Keep your guard up and stay ready.",
                "Talk later. I want us both focused on getting through this.",
                "Something is too close. Stay beside me until it's clear.",
                "I won't risk you for a conversation. Keep watch, love.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "Not safe to talk right now, {playerFirstName}. Stay close and stay vigilant.",
                "Something's nearby. We can talk later; keep your guard up, family.",
                "Hold that thought. Watch each other's backs until it's clear.",
                "Stay with the family. We need to handle this danger first.",
                "Eyes up, {playerFirstName}. We'll finish talking when we're safe.",
                "Trouble is close. Keep everyone together and stay ready.",
                "We have company nearby. Stay quiet and watch the perimeter.",
                "The conversation can wait. Family comes first right now.",
                "Let's move carefully and talk once the danger has passed.",
            },
        },
    },
})

return PNC.SocialFlavorDefinitions
