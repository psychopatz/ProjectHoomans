-- Hoomans' authored side of the Necroa interaction vocabulary.
-- Necroa zombie speech does not enter this registry; it remains native.

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore.SocialFlavor

Flavor.Register("compat.necroa.mask_warning", {
    id = "compat.necroa.mask_warning",
    family = "necroa_mask_safety",
    npc = {
        { key = "UI_PNC_Flavor_Necroa_MaskWarning_NPC_1", fallback = "Put your mask back on, {victimFirstName}! Knox is airborne!" },
        { key = "UI_PNC_Flavor_Necroa_MaskWarning_NPC_2", fallback = "No mask? That is not safe, {victimFirstName}. Cover your face!" },
        { key = "UI_PNC_Flavor_Necroa_MaskWarning_NPC_3", fallback = "We need masks on. I am not watching another person turn." },
    },
    variants = {
        {
            id = "family",
            when = { socialRole = "family" },
            npc = {
                { key = "UI_PNC_Flavor_Necroa_MaskWarning_Family_1", fallback = "Put your mask on, family. I am not losing you to the air." },
                { key = "UI_PNC_Flavor_Necroa_MaskWarning_Family_2", fallback = "Mask up! I will not watch you gamble with Knox like that." },
            },
        },
        {
            id = "colonist",
            when = { socialRole = "colonist" },
            npc = {
                { key = "UI_PNC_Flavor_Necroa_MaskWarning_Colonist_1", fallback = "Mask up, {victimFirstName}. We keep the camp safe together." },
                { key = "UI_PNC_Flavor_Necroa_MaskWarning_Colonist_2", fallback = "Get a mask on before you come back inside, {victimFirstName}." },
            },
        },
    },
})

Flavor.Register("compat.necroa.player_mask_removed", {
    id = "compat.necroa.player_mask_removed",
    family = "necroa_mask_safety",
    npc = {
        { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_NPC_1", fallback = "What are you doing, {playerFirstName}? Put that mask back on!" },
        { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_NPC_2", fallback = "That is idiot behavior, {playerFirstName}. The air is not safe!" },
        { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_NPC_3", fallback = "Do you want to die? Mask up before you get us all sick!" },
    },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = {
                { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_Hostile_1", fallback = "Idiot. Put your mask back on before you become a problem." },
                { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_Hostile_2", fallback = "Take that mask off again and you are on your own, {playerFirstName}." },
            },
        },
        {
            id = "lover",
            when = { socialRole = "lover" },
            npc = {
                { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_Lover_1", fallback = "Please put your mask back on, love. This air is not safe." },
                { key = "UI_PNC_Flavor_Necroa_PlayerMaskRemoved_Lover_2", fallback = "Do not be an idiot, sweetheart. Mask up for me." },
            },
        },
    },
})

return PNC.SocialFlavorDefinitions
