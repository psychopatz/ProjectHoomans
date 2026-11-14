-- Generated Conversation discovery index; do not edit by hand.
return {
    ["social.apology.default"] = {
        ["domain"] = "social_apology",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialApology",
        },
        ["id"] = "social.apology.default",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_apology/social_apology_default.json",
    },
    ["social.apology.friendly"] = {
        ["dependents"] = {
            "behavior.acknowledge_repair",
            "behavior.reconcile",
        },
        ["domain"] = "social_apology",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialApology",
        },
        ["id"] = "social.apology.friendly",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_apology/social_apology.json",
    },
    ["social.apology.stressed"] = {
        ["domain"] = "social_apology",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialApology",
        },
        ["id"] = "social.apology.stressed",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_apology/social_apology_stressed.json",
    },
    ["social.apology.withdrawn"] = {
        ["domain"] = "social_apology",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialApology",
        },
        ["id"] = "social.apology.withdrawn",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_apology/social_apology_withdrawn.json",
    },
}
