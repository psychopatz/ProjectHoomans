-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_reaction",
        ["domainPath"] = "companion_reaction",
        ["exchangeFamily"] = {
            ["familyID"] = "companion.reaction",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Stay with me next time. We watch each other's backs.",
                                ["id"] = "abandonment",
                                ["templateID"] = "convo.companion.reaction.say.1.abandonment",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I can't find a safe room or campfire nearby.",
                                ["id"] = "camp_rejected",
                                ["templateID"] = "convo.companion.reaction.say.1.camp_rejected",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I heard you. We will handle it together.",
                                ["id"] = "default",
                                ["templateID"] = "convo.companion.reaction.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "companion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay with me next time. We watch each other's backs.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.say.1.abandonment",
                    ["variantID"] = "abandonment",
                },
                {
                    ["fallback"] = "I can't find a safe room or campfire nearby.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.say.1.camp_rejected",
                    ["variantID"] = "camp_rejected",
                },
                {
                    ["fallback"] = "I heard you. We will handle it together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.companion.reaction.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "companion.reaction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reaction",
            ["sourceId"] = "companion.reaction",
            ["sourcePath"] = "dialogue/companion_reaction/companion_reaction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionReaction",
        ["namespace"] = "companion",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Stay with me next time. We watch each other's backs.",
                                ["id"] = "abandonment",
                            },
                            {
                                ["fallback"] = "I can't find a safe room or campfire nearby.",
                                ["id"] = "camp_rejected",
                            },
                            {
                                ["fallback"] = "I heard you. We will handle it together.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "companion.reaction",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Stay with me next time. We watch each other's backs.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.companion.reaction.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_reaction/companion_reaction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay with me next time. We watch each other's backs.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.reaction.say.1.abandonment",
                ["variantID"] = "abandonment",
            },
            {
                ["fallback"] = "I can't find a safe room or campfire nearby.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.reaction.say.1.camp_rejected",
                ["variantID"] = "camp_rejected",
            },
            {
                ["fallback"] = "I heard you. We will handle it together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.companion.reaction.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
