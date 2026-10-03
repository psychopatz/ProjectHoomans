-- Deterministic social flavor registration shard.
local Definitions = PNC.SocialFlavorDefinitions
local Internal = Definitions.Internal
local Flavor = Internal.Flavor
local translatedLine = Internal.translatedLine

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

return Definitions
