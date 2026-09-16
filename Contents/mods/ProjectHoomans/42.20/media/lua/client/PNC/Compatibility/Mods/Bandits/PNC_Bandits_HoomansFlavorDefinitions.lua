-- Project Hoomans' side of the Bandits interaction vocabulary.
--
-- These lines intentionally use the normal Hoomans SocialFlavor registry;
-- Bandits' captions remain in Bandit.SoundTab and never enter this registry.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore.SocialFlavor

Flavor.Register("compat.bandits.hooman_hurt", {
    id = "compat.bandits.hooman_hurt",
    family = "combat_commentary",
    npc = {
        "Bandits! {victimFirstName} is hit—get them behind cover!",
        "That was a bandit. Stay down, {victimFirstName}, we have you covered.",
        "Bandit fire! Keep moving, {victimFirstName}, and watch the flank.",
    },
    variants = {
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                "Bandits hit {victimFirstName}! Pull back to camp and regroup.",
                "Keep breathing, {victimFirstName}. We are not letting bandits take another colonist.",
                "Bandit fire! Cover {victimFirstName} while we get them patched up.",
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                "Bandits hit you, love. Stay close—I have got you.",
                "You are hurt, love. Keep your head down while I deal with those bandits.",
            },
        },
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                "Bandits hit {victimFirstName}! Stay together—we protect family.",
                "Hold on, {victimFirstName}. We are getting you clear of that bandit fire.",
            },
        },
    },
})

return PNC.SocialFlavorDefinitions
