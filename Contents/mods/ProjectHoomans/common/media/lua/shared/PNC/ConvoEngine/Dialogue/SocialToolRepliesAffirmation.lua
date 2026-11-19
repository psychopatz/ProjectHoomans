-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.accepted_generic",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hear you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.accepted_generic.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will keep that in mind.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.accepted_generic.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I hear you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.accepted_generic.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I will keep that in mind.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.accepted_generic.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.accepted_generic",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "accepted_generic",
            ["sourceId"] = "tool_reply.accepted_generic",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_accepted_generic.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hear you.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will keep that in mind.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.accepted_generic",
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
                            ["fallback"] = "I hear you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.accepted_generic.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_accepted_generic.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I hear you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.accepted_generic.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I will keep that in mind.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.accepted_generic.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.admire",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate that more than you know.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.admire.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is kind of you to say.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.admire.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You see more in me than most people do.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.admire.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "I appreciate that more than you know.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.admire.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That is kind of you to say.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.admire.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You see more in me than most people do.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.admire.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.admire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "admire",
            ["sourceId"] = "tool_reply.admire",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_admire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate that more than you know.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is kind of you to say.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You see more in me than most people do.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.admire",
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
                            ["fallback"] = "I appreciate that more than you know.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.admire.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_admire.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I appreciate that more than you know.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.admire.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That is kind of you to say.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.admire.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You see more in me than most people do.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.admire.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.apology",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "All right. Let us move on.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.apology.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I accept the apology.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.apology.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Fine. We can put it behind us.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.apology.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. Let us move on.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.apology.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I accept the apology.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.apology.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Fine. We can put it behind us.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.apology.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.apology",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "apology",
            ["sourceId"] = "tool_reply.apology",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_apology.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "All right. Let us move on.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I accept the apology.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Fine. We can put it behind us.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.apology",
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
                            ["fallback"] = "All right. Let us move on.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.apology.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_apology.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. Let us move on.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.apology.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I accept the apology.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.apology.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Fine. We can put it behind us.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.apology.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.ask_name.named",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am %s.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.named.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "The name is %s.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.named.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You can call me %s.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.named.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply.ask_name",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am %s.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.named.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "The name is %s.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.named.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You can call me %s.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.named.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.ask_name.named",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "named",
            ["sourceId"] = "tool_reply.ask_name.named",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_named.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply.ask_name",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am %s.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "The name is %s.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You can call me %s.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.ask_name.named",
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
                            ["fallback"] = "I am %s.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.ask_name.named.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_named.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am %s.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.named.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "The name is %s.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.named.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You can call me %s.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.named.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.ask_name.prompt",
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
                                ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.prompt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply.ask_name",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.prompt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.ask_name.prompt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "prompt",
            ["sourceId"] = "tool_reply.ask_name.prompt",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_prompt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply.ask_name",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
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
                                ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.ask_name.prompt",
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
                            ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.ask_name.prompt.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.prompt.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.ask_name.rejected",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not ready to share that yet.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Ask me again when we know each other better.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.rejected.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply.ask_name",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am not ready to share that yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.rejected.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Ask me again when we know each other better.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.rejected.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.ask_name.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rejected",
            ["sourceId"] = "tool_reply.ask_name.rejected",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply.ask_name",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not ready to share that yet.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Ask me again when we know each other better.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.ask_name.rejected",
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
                            ["fallback"] = "I am not ready to share that yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.ask_name.rejected.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am not ready to share that yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.rejected.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Ask me again when we know each other better.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.rejected.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.ask_name.unnamed",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You want to know my name? Give me a second.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "My name is a longer story than you might expect.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply.ask_name",
            ["textRoles"] = {
                {
                    ["fallback"] = "You want to know my name? Give me a second.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "My name is a longer story than you might expect.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.ask_name.unnamed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unnamed",
            ["sourceId"] = "tool_reply.ask_name.unnamed",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_unnamed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply.ask_name",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You want to know my name? Give me a second.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "My name is a longer story than you might expect.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.ask_name.unnamed",
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
                            ["fallback"] = "You want to know my name? Give me a second.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.ask_name.unnamed.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_ask_name_unnamed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You want to know my name? Give me a second.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "My name is a longer story than you might expect.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.ask_name.unnamed.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.comfort",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Thanks. I needed that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.comfort.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate you being here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.comfort.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That helps more than I expected.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.comfort.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thanks. I needed that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.comfort.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I appreciate you being here.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.comfort.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That helps more than I expected.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.comfort.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.comfort",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "comfort",
            ["sourceId"] = "tool_reply.comfort",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_comfort.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Thanks. I needed that.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate you being here.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That helps more than I expected.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.comfort",
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
                            ["fallback"] = "Thanks. I needed that.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.comfort.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_comfort.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thanks. I needed that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.comfort.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I appreciate you being here.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.comfort.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That helps more than I expected.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.comfort.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.compliment",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is kind of you to say.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.compliment.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate the compliment.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.compliment.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You noticed. Thank you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.compliment.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "That is kind of you to say.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.compliment.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I appreciate the compliment.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.compliment.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You noticed. Thank you.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.compliment.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.compliment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "compliment",
            ["sourceId"] = "tool_reply.compliment",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_compliment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is kind of you to say.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate the compliment.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You noticed. Thank you.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.compliment",
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
                            ["fallback"] = "That is kind of you to say.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.compliment.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_compliment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That is kind of you to say.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.compliment.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I appreciate the compliment.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.compliment.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You noticed. Thank you.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.compliment.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["domainPath"] = "social_tool_replies_affirmation",
        ["exchangeFamily"] = {
            ["familyID"] = "tool_reply.flirt",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Careful. You are making me smile.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.flirt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You always know how to get my attention.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.flirt.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is a dangerous thing to say to me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.tool_reply.flirt.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "tool_reply",
            ["textRoles"] = {
                {
                    ["fallback"] = "Careful. You are making me smile.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.flirt.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You always know how to get my attention.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.flirt.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That is a dangerous thing to say to me.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.tool_reply.flirt.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "tool_reply.flirt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "flirt",
            ["sourceId"] = "tool_reply.flirt",
            ["sourcePath"] = "dialogue/social_tool_replies_affirmation/tool_reply_flirt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialToolRepliesAffirmation",
        ["namespace"] = "tool_reply",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Careful. You are making me smile.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You always know how to get my attention.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is a dangerous thing to say to me.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "tool_reply.flirt",
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
                            ["fallback"] = "Careful. You are making me smile.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.tool_reply.flirt.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social_tool_replies_affirmation/tool_reply_flirt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Careful. You are making me smile.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.flirt.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You always know how to get my attention.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.flirt.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That is a dangerous thing to say to me.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.tool_reply.flirt.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
