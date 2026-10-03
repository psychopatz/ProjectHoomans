-- Deterministic social flavor registration shard.
local Definitions = PNC.SocialFlavorDefinitions
local Internal = Definitions.Internal
local Flavor = Internal.Flavor
local translatedLine = Internal.translatedLine

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

Flavor.Register("social.zombie_horde_detected", {
    id = "social.zombie_horde_detected",
    family = "zombie_awareness",
    npc = {
        translatedLine(
            "UI_PNC_Conversation_ZombieHorde_01",
            "Too many of the dead. We need to get clear."
        ),
        translatedLine(
            "UI_PNC_Conversation_ZombieHorde_02",
            "There are too many of them. Let's make some space."
        ),
        translatedLine(
            "UI_PNC_Conversation_ZombieHorde_03",
            "They're closing in. Circle around and keep moving."
        ),
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_04",
                    "That pack is too big for you. Move."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_05",
                    "I'm not dying for your bad call. Fall back."
                ),
            },
        },
        {
            id = "neutral",
            when = { socialRole = "neutral" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_06",
                    "There are too many. Let's get some distance."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_07",
                    "We should move before they close in."
                ),
            },
        },
        {
            id = "colonist",
            when = { socialRole = { "colonist", "member" } },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_08",
                    "Too many for a straight fight. Keep our group together."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_09",
                    "Watch our rear while we move. Don't let anyone fall behind."
                ),
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_10",
                    "Stay close. I don't like how many there are."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_11",
                    "Come with me. We'll get around them together."
                ),
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_12",
                    "Keep beside me until we're clear."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieHorde_13",
                    "Don't get separated. We need to stay together."
                ),
            },
        },
    },
})

Flavor.Register("social.zombie_stamina_retreat", {
    id = "social.zombie_stamina_retreat",
    family = "zombie_awareness",
    npc = {
        translatedLine(
            "UI_PNC_Conversation_ZombieRetreat_01",
            "I need a moment before I can swing again."
        ),
        translatedLine(
            "UI_PNC_Conversation_ZombieRetreat_02",
            "I'm winded. Keep those dead back while I recover."
        ),
        translatedLine(
            "UI_PNC_Conversation_ZombieRetreat_03",
            "I can't keep this pace. I'm falling back."
        ),
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_04",
                    "Cover me. I need a moment, and I won't ask twice."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_05",
                    "I'm winded. Keep up or handle them yourself."
                ),
            },
        },
        {
            id = "neutral",
            when = { socialRole = "neutral" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_06",
                    "I need to catch my breath. Let's put some distance between us."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_07",
                    "I'm running out of steam. Keep them back."
                ),
            },
        },
        {
            id = "colonist",
            when = { socialRole = { "colonist", "member" } },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_08",
                    "Cover me while I catch my breath!"
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_09",
                    "I need a moment. Keep the group moving."
                ),
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_10",
                    "Stay close while I catch my breath."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_11",
                    "I need to slow down. Keep them away from us."
                ),
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_12",
                    "Wait for me. I'm not leaving you behind."
                ),
                translatedLine(
                    "UI_PNC_Conversation_ZombieRetreat_13",
                    "Give me a moment. We need to get somewhere safe."
                ),
            },
        },
    },
})

return Definitions
