-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.colonist",
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
                                ["fallback"] = "Watch your perimeter out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.colonist.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Watch your perimeter out there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.colonist.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "colonist",
            ["sourceId"] = "flow.farewell.colonist",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_colonist.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Watch your perimeter out there.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.colonist",
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
                            ["fallback"] = "Watch your perimeter out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.colonist.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_colonist.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Watch your perimeter out there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.colonist.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.default",
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
                                ["fallback"] = "Take care.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take care.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "default",
            ["sourceId"] = "flow.farewell.default",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Take care.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.default",
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
                            ["fallback"] = "Take care.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.default.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take care.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.default.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.family",
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
                                ["fallback"] = "Be careful out there. You know how much you mean to me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.family.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Be careful out there. You know how much you mean to me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.family.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.family",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "family",
            ["sourceId"] = "flow.farewell.family",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_family.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Be careful out there. You know how much you mean to me.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.family",
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
                            ["fallback"] = "Be careful out there. You know how much you mean to me.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.family.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_family.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Be careful out there. You know how much you mean to me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.family.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.friend",
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
                                ["fallback"] = "Stay safe out there, friend. Come back in one piece.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.friend.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay safe out there, friend. Come back in one piece.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.friend.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.friend",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friend",
            ["sourceId"] = "flow.farewell.friend",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_friend.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Stay safe out there, friend. Come back in one piece.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.friend",
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
                            ["fallback"] = "Stay safe out there, friend. Come back in one piece.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.friend.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_friend.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay safe out there, friend. Come back in one piece.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.friend.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.friendly",
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
                                ["fallback"] = "Take care. I will see you soon.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take care. I will see you soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friendly",
            ["sourceId"] = "flow.farewell.friendly",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Take care. I will see you soon.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.friendly",
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
                            ["fallback"] = "Take care. I will see you soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.friendly.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take care. I will see you soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.friendly.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.hostile",
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
                                ["fallback"] = "Get out of my sight.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.hostile.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Get out of my sight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.hostile.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile",
            ["sourceId"] = "flow.farewell.hostile",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Get out of my sight.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.hostile",
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
                            ["fallback"] = "Get out of my sight.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.hostile.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Get out of my sight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.hostile.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.lover",
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
                                ["fallback"] = "Come back to me safely. Please don't stay gone long.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.lover.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Come back to me safely. Please don't stay gone long.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.lover.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.lover",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "lover",
            ["sourceId"] = "flow.farewell.lover",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_lover.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Come back to me safely. Please don't stay gone long.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.lover",
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
                            ["fallback"] = "Come back to me safely. Please don't stay gone long.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.lover.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_lover.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Come back to me safely. Please don't stay gone long.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.lover.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_colonist",
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
                                ["fallback"] = "Keep holding the line. I'll check back soon.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_colonist.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Keep holding the line. I'll check back soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_colonist.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_colonist",
            ["sourceId"] = "flow.farewell.player_colonist",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_colonist.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Keep holding the line. I'll check back soon.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_colonist",
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
                            ["fallback"] = "Keep holding the line. I'll check back soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_colonist.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_colonist.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Keep holding the line. I'll check back soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_colonist.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_default",
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
                                ["fallback"] = "Stay safe out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay safe out there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_default.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_default",
            ["sourceId"] = "flow.farewell.player_default",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Stay safe out there.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_default",
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
                            ["fallback"] = "Stay safe out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_default.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay safe out there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_default.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_family",
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
                                ["fallback"] = "Be safe while I'm out. I'll be right back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_family.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Be safe while I'm out. I'll be right back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_family.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_family",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_family",
            ["sourceId"] = "flow.farewell.player_family",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_family.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Be safe while I'm out. I'll be right back.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_family",
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
                            ["fallback"] = "Be safe while I'm out. I'll be right back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_family.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_family.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Be safe while I'm out. I'll be right back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_family.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_friend",
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
                                ["fallback"] = "Take care of yourself, friend. Talk soon.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_friend.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Take care of yourself, friend. Talk soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_friend.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_friend",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_friend",
            ["sourceId"] = "flow.farewell.player_friend",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_friend.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Take care of yourself, friend. Talk soon.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_friend",
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
                            ["fallback"] = "Take care of yourself, friend. Talk soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_friend.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_friend.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Take care of yourself, friend. Talk soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_friend.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_hostile",
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
                                ["fallback"] = "We're done talking.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_hostile.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "We're done talking.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_hostile.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_hostile",
            ["sourceId"] = "flow.farewell.player_hostile",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "We're done talking.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_hostile",
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
                            ["fallback"] = "We're done talking.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_hostile.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We're done talking.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_hostile.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_lover",
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
                                ["fallback"] = "Stay safe for me. I'll come right back to you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_lover.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay safe for me. I'll come right back to you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_lover.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_lover",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_lover",
            ["sourceId"] = "flow.farewell.player_lover",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_lover.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Stay safe for me. I'll come right back to you.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_lover",
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
                            ["fallback"] = "Stay safe for me. I'll come right back to you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_lover.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_lover.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay safe for me. I'll come right back to you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_lover.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.player_wary",
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
                                ["fallback"] = "I'm heading out. Stay sharp.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.player_wary.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 8,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm heading out. Stay sharp.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.player_wary.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.player_wary",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_wary",
            ["sourceId"] = "flow.farewell.player_wary",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_player_wary.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "I'm heading out. Stay sharp.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.player_wary",
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
                            ["fallback"] = "I'm heading out. Stay sharp.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.player_wary.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_player_wary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm heading out. Stay sharp.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.player_wary.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_farewell",
        ["domainPath"] = "event_reactions_farewell",
        ["exchangeFamily"] = {
            ["familyID"] = "flow.farewell.wary",
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
                                ["fallback"] = "Keep your distance out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.flow.farewell.wary.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 9,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "flow.farewell",
            ["textRoles"] = {
                {
                    ["fallback"] = "Keep your distance out there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.flow.farewell.wary.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "flow.farewell.wary",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wary",
            ["sourceId"] = "flow.farewell.wary",
            ["sourcePath"] = "dialogue/event_reactions_farewell/flow_farewell_wary.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsFarewell",
        ["namespace"] = "flow.farewell",
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
                ["responseAct"] = "FAREWELL",
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
                                ["fallback"] = "Keep your distance out there.",
                                ["id"] = "neutral",
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
            ["dialogueAct"] = "FAREWELL",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "flow.farewell.wary",
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
                            ["fallback"] = "Keep your distance out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.flow.farewell.wary.say_1",
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
        ["sourceShard"] = "dialogue/event_reactions_farewell/flow_farewell_wary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Keep your distance out there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.flow.farewell.wary.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
