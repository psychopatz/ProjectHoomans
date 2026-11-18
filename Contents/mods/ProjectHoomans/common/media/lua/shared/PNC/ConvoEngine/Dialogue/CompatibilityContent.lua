-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.bandits.hooman_hurt",
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
                                ["fallback"] = "Bandit fire! Pull back and cover the wounded colonist.",
                                ["id"] = "colonist",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.colonist",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                ["id"] = "default",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                                ["id"] = "family",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.family",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Bandit fire. Stay close; I have got you.",
                                ["id"] = "lover",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.lover",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Bandit fire. Stay close; I have got you.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire. Stay close; I have got you.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.bandits",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Bandit fire! Pull back and cover the wounded colonist.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.colonist",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Pull back and cover the wounded colonist.",
                        },
                        ["TL"] = {
                            "Bandit fire! Pull back and cover the wounded colonist.",
                        },
                    },
                    ["variantID"] = "colonist",
                },
                {
                    ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Stay with the wounded survivor and watch the flank.",
                        },
                        ["TL"] = {
                            "Bandit fire! Stay with the wounded survivor and watch the flank.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.family",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Stay together and cover the wounded family member.",
                        },
                        ["TL"] = {
                            "Bandit fire! Stay together and cover the wounded family member.",
                        },
                    },
                    ["variantID"] = "family",
                },
                {
                    ["fallback"] = "Bandit fire. Stay close; I have got you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.lover",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire. Stay close; I have got you.",
                        },
                        ["TL"] = {
                            "Bandit fire. Stay close; I have got you.",
                        },
                    },
                    ["variantID"] = "lover",
                },
            },
        },
        ["id"] = "integration.bandits.hooman_hurt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hooman_hurt",
            ["sourceId"] = "integration.bandits.hooman_hurt",
            ["sourcePath"] = "dialogue/compatibility_content/integration_bandits_hooman_hurt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.bandits",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "colonist",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                },
                            },
                            {
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                },
                            },
                            {
                                ["id"] = "family",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                },
                            },
                            {
                                ["id"] = "lover",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire. Stay close; I have got you.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire. Stay close; I have got you.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "bandits",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.bandits.hooman_hurt",
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
                            ["fallback"] = "Bandit fire! Pull back and cover the wounded colonist.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.bandits.hooman_hurt.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/compatibility_content/integration_bandits_hooman_hurt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Bandit fire! Pull back and cover the wounded colonist.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.colonist",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Pull back and cover the wounded colonist.",
                    },
                    ["TL"] = {
                        "Bandit fire! Pull back and cover the wounded colonist.",
                    },
                },
                ["variantID"] = "colonist",
            },
            {
                ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    },
                    ["TL"] = {
                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.family",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Stay together and cover the wounded family member.",
                    },
                    ["TL"] = {
                        "Bandit fire! Stay together and cover the wounded family member.",
                    },
                },
                ["variantID"] = "family",
            },
            {
                ["fallback"] = "Bandit fire. Stay close; I have got you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.say.1.lover",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire. Stay close; I have got you.",
                    },
                    ["TL"] = {
                        "Bandit fire. Stay close; I have got you.",
                    },
                },
                ["variantID"] = "lover",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.feed",
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
                                ["fallback"] = "Here you go, good girl.",
                                ["id"] = "female",
                                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.female",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Here you go, good girl.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good girl.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Here you go, good boy.",
                                ["id"] = "male",
                                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.male",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Here you go, good boy.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good boy.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Here you go, good dog.",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Here you go, good dog.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good dog.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs",
            ["slots"] = {
                ["subject"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Here you go, good girl.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.say.1.female",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good girl.",
                        },
                        ["TL"] = {
                            "Here you go, good girl.",
                        },
                    },
                    ["variantID"] = "female",
                },
                {
                    ["fallback"] = "Here you go, good boy.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.say.1.male",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good boy.",
                        },
                        ["TL"] = {
                            "Here you go, good boy.",
                        },
                    },
                    ["variantID"] = "male",
                },
                {
                    ["fallback"] = "Here you go, good dog.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.say.1.unknown",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good dog.",
                        },
                        ["TL"] = {
                            "Here you go, good dog.",
                        },
                    },
                    ["variantID"] = "unknown",
                },
            },
        },
        ["id"] = "integration.companion_dogs.feed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "feed",
            ["sourceId"] = "integration.companion_dogs.feed",
            ["sourcePath"] = "dialogue/compatibility_content/integration_companion_dogs_feed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "female",
                                ["text"] = {
                                    ["EN"] = {
                                        "Here you go, good girl.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good girl.",
                                    },
                                },
                            },
                            {
                                ["id"] = "male",
                                ["text"] = {
                                    ["EN"] = {
                                        "Here you go, good boy.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good boy.",
                                    },
                                },
                            },
                            {
                                ["id"] = "unknown",
                                ["text"] = {
                                    ["EN"] = {
                                        "Here you go, good dog.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good dog.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "companion_dogs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.feed",
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
                            ["fallback"] = "Here you go, good girl.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.companion_dogs.feed.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
            ["subject"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.any",
            },
        },
        ["sourceShard"] = "dialogue/compatibility_content/integration_companion_dogs_feed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Here you go, good girl.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.female",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good girl.",
                    },
                    ["TL"] = {
                        "Here you go, good girl.",
                    },
                },
                ["variantID"] = "female",
            },
            {
                ["fallback"] = "Here you go, good boy.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.male",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good boy.",
                    },
                    ["TL"] = {
                        "Here you go, good boy.",
                    },
                },
                ["variantID"] = "male",
            },
            {
                ["fallback"] = "Here you go, good dog.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.feed.say.1.unknown",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good dog.",
                    },
                    ["TL"] = {
                        "Here you go, good dog.",
                    },
                },
                ["variantID"] = "unknown",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.greeting",
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
                                ["fallback"] = "Who is a good girl?",
                                ["id"] = "female",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.female",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Who is a good girl?",
                                    },
                                    ["TL"] = {
                                        "Who is a good girl?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Who is a good boy?",
                                ["id"] = "male",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.male",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Who is a good boy?",
                                    },
                                    ["TL"] = {
                                        "Who is a good boy?",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Who is a good dog?",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Who is a good dog?",
                                    },
                                    ["TL"] = {
                                        "Who is a good dog?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs",
            ["slots"] = {
                ["subject"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Who is a good girl?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.female",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good girl?",
                        },
                        ["TL"] = {
                            "Who is a good girl?",
                        },
                    },
                    ["variantID"] = "female",
                },
                {
                    ["fallback"] = "Who is a good boy?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.male",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good boy?",
                        },
                        ["TL"] = {
                            "Who is a good boy?",
                        },
                    },
                    ["variantID"] = "male",
                },
                {
                    ["fallback"] = "Who is a good dog?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.unknown",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good dog?",
                        },
                        ["TL"] = {
                            "Who is a good dog?",
                        },
                    },
                    ["variantID"] = "unknown",
                },
            },
        },
        ["id"] = "integration.companion_dogs.greeting",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "greeting",
            ["sourceId"] = "integration.companion_dogs.greeting",
            ["sourcePath"] = "dialogue/compatibility_content/integration_companion_dogs_greeting.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "female",
                                ["text"] = {
                                    ["EN"] = {
                                        "Who is a good girl?",
                                    },
                                    ["TL"] = {
                                        "Who is a good girl?",
                                    },
                                },
                            },
                            {
                                ["id"] = "male",
                                ["text"] = {
                                    ["EN"] = {
                                        "Who is a good boy?",
                                    },
                                    ["TL"] = {
                                        "Who is a good boy?",
                                    },
                                },
                            },
                            {
                                ["id"] = "unknown",
                                ["text"] = {
                                    ["EN"] = {
                                        "Who is a good dog?",
                                    },
                                    ["TL"] = {
                                        "Who is a good dog?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "companion_dogs",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.greeting",
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
                            ["fallback"] = "Who is a good girl?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.companion_dogs.greeting.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
            ["subject"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.any",
            },
        },
        ["sourceShard"] = "dialogue/compatibility_content/integration_companion_dogs_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Who is a good girl?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.female",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good girl?",
                    },
                    ["TL"] = {
                        "Who is a good girl?",
                    },
                },
                ["variantID"] = "female",
            },
            {
                ["fallback"] = "Who is a good boy?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.male",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good boy?",
                    },
                    ["TL"] = {
                        "Who is a good boy?",
                    },
                },
                ["variantID"] = "male",
            },
            {
                ["fallback"] = "Who is a good dog?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.greeting.say.1.unknown",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good dog?",
                    },
                    ["TL"] = {
                        "Who is a good dog?",
                    },
                },
                ["variantID"] = "unknown",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.mask_warning",
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
                                ["fallback"] = "Mask up. We keep the camp safe together.",
                                ["id"] = "colonist",
                                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.colonist",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                    ["TL"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Put your mask back on. Knox is airborne.",
                                ["id"] = "default",
                                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                                ["id"] = "family",
                                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.family",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Put your mask on, family. I am not losing you to the air.",
                                    },
                                    ["TL"] = {
                                        "Put your mask on, family. I am not losing you to the air.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Mask up. We keep the camp safe together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.say.1.colonist",
                    ["translations"] = {
                        ["EN"] = {
                            "Mask up. We keep the camp safe together.",
                        },
                        ["TL"] = {
                            "Mask up. We keep the camp safe together.",
                        },
                    },
                    ["variantID"] = "colonist",
                },
                {
                    ["fallback"] = "Put your mask back on. Knox is airborne.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on. Knox is airborne.",
                        },
                        ["TL"] = {
                            "Put your mask back on. Knox is airborne.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.say.1.family",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask on, family. I am not losing you to the air.",
                        },
                        ["TL"] = {
                            "Put your mask on, family. I am not losing you to the air.",
                        },
                    },
                    ["variantID"] = "family",
                },
            },
        },
        ["id"] = "integration.necroa.mask_warning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "mask_warning",
            ["sourceId"] = "integration.necroa.mask_warning",
            ["sourcePath"] = "dialogue/compatibility_content/integration_necroa_mask_warning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "colonist",
                                ["text"] = {
                                    ["EN"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                    ["TL"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                },
                            },
                            {
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                },
                            },
                            {
                                ["id"] = "family",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask on, family. I am not losing you to the air.",
                                    },
                                    ["TL"] = {
                                        "Put your mask on, family. I am not losing you to the air.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "necroa",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.mask_warning",
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
                            ["fallback"] = "Mask up. We keep the camp safe together.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.necroa.mask_warning.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/compatibility_content/integration_necroa_mask_warning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Mask up. We keep the camp safe together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.colonist",
                ["translations"] = {
                    ["EN"] = {
                        "Mask up. We keep the camp safe together.",
                    },
                    ["TL"] = {
                        "Mask up. We keep the camp safe together.",
                    },
                },
                ["variantID"] = "colonist",
            },
            {
                ["fallback"] = "Put your mask back on. Knox is airborne.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on. Knox is airborne.",
                    },
                    ["TL"] = {
                        "Put your mask back on. Knox is airborne.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.mask_warning.say.1.family",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask on, family. I am not losing you to the air.",
                    },
                    ["TL"] = {
                        "Put your mask on, family. I am not losing you to the air.",
                    },
                },
                ["variantID"] = "family",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.player_mask_removed",
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
                                ["fallback"] = "Put your mask back on. The air is not safe.",
                                ["id"] = "default",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Put your mask back on before you become a problem.",
                                ["id"] = "hostile",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.hostile",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                                ["id"] = "lover",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.lover",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Please put your mask back on, love. This air is not safe.",
                                    },
                                    ["TL"] = {
                                        "Please put your mask back on, love. This air is not safe.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa",
            ["slots"] = {
                ["threat"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.threat",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Put your mask back on. The air is not safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on. The air is not safe.",
                        },
                        ["TL"] = {
                            "Put your mask back on. The air is not safe.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Put your mask back on before you become a problem.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.hostile",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on before you become a problem.",
                        },
                        ["TL"] = {
                            "Put your mask back on before you become a problem.",
                        },
                    },
                    ["variantID"] = "hostile",
                },
                {
                    ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.lover",
                    ["translations"] = {
                        ["EN"] = {
                            "Please put your mask back on, love. This air is not safe.",
                        },
                        ["TL"] = {
                            "Please put your mask back on, love. This air is not safe.",
                        },
                    },
                    ["variantID"] = "lover",
                },
            },
        },
        ["id"] = "integration.necroa.player_mask_removed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "player_mask_removed",
            ["sourceId"] = "integration.necroa.player_mask_removed",
            ["sourcePath"] = "dialogue/compatibility_content/integration_necroa_player_mask_removed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                },
                            },
                            {
                                ["id"] = "hostile",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                },
                            },
                            {
                                ["id"] = "lover",
                                ["text"] = {
                                    ["EN"] = {
                                        "Please put your mask back on, love. This air is not safe.",
                                    },
                                    ["TL"] = {
                                        "Please put your mask back on, love. This air is not safe.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "necroa",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.player_mask_removed",
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
                            ["fallback"] = "Put your mask back on. The air is not safe.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.necroa.player_mask_removed.say_1",
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
            ["threat"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.threat",
            },
        },
        ["sourceShard"] = "dialogue/compatibility_content/integration_necroa_player_mask_removed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Put your mask back on. The air is not safe.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on. The air is not safe.",
                    },
                    ["TL"] = {
                        "Put your mask back on. The air is not safe.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Put your mask back on before you become a problem.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.hostile",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on before you become a problem.",
                    },
                    ["TL"] = {
                        "Put your mask back on before you become a problem.",
                    },
                },
                ["variantID"] = "hostile",
            },
            {
                ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.player_mask_removed.say.1.lover",
                ["translations"] = {
                    ["EN"] = {
                        "Please put your mask back on, love. This air is not safe.",
                    },
                    ["TL"] = {
                        "Please put your mask back on, love. This air is not safe.",
                    },
                },
                ["variantID"] = "lover",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.encounter",
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
                                ["fallback"] = "Those survivors seem friendly. Keep your hands visible.",
                                ["id"] = "friendly",
                                ["templateID"] = "convo.integration.projectalife.encounter.say.1.friendly",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                    ["TL"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                                ["id"] = "hostile",
                                ["templateID"] = "convo.integration.projectalife.encounter.say.1.hostile",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                    ["TL"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Someone is out there. Let us watch before we approach.",
                                ["id"] = "unknown",
                                ["templateID"] = "convo.integration.projectalife.encounter.say.1.unknown",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone is out there. Let us watch before we approach.",
                                    },
                                    ["TL"] = {
                                        "Someone is out there. Let us watch before we approach.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife",
            ["textRoles"] = {
                {
                    ["fallback"] = "Those survivors seem friendly. Keep your hands visible.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.say.1.friendly",
                    ["translations"] = {
                        ["EN"] = {
                            "Those survivors seem friendly. Keep your hands visible.",
                        },
                        ["TL"] = {
                            "Those survivors seem friendly. Keep your hands visible.",
                        },
                    },
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.say.1.hostile",
                    ["translations"] = {
                        ["EN"] = {
                            "That group looks hostile. Keep cover between us and them.",
                        },
                        ["TL"] = {
                            "That group looks hostile. Keep cover between us and them.",
                        },
                    },
                    ["variantID"] = "hostile",
                },
                {
                    ["fallback"] = "Someone is out there. Let us watch before we approach.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.say.1.unknown",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is out there. Let us watch before we approach.",
                        },
                        ["TL"] = {
                            "Someone is out there. Let us watch before we approach.",
                        },
                    },
                    ["variantID"] = "unknown",
                },
            },
        },
        ["id"] = "integration.projectalife.encounter",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "encounter",
            ["sourceId"] = "integration.projectalife.encounter",
            ["sourcePath"] = "dialogue/compatibility_content/integration_projectalife_encounter.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "friendly",
                                ["text"] = {
                                    ["EN"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                    ["TL"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                },
                            },
                            {
                                ["id"] = "hostile",
                                ["text"] = {
                                    ["EN"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                    ["TL"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                },
                            },
                            {
                                ["id"] = "unknown",
                                ["text"] = {
                                    ["EN"] = {
                                        "Someone is out there. Let us watch before we approach.",
                                    },
                                    ["TL"] = {
                                        "Someone is out there. Let us watch before we approach.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "projectalife",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.encounter",
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
                            ["fallback"] = "Those survivors seem friendly. Keep your hands visible.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.projectalife.encounter.say_1",
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
        ["sourceShard"] = "dialogue/compatibility_content/integration_projectalife_encounter.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Those survivors seem friendly. Keep your hands visible.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.encounter.say.1.friendly",
                ["translations"] = {
                    ["EN"] = {
                        "Those survivors seem friendly. Keep your hands visible.",
                    },
                    ["TL"] = {
                        "Those survivors seem friendly. Keep your hands visible.",
                    },
                },
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.encounter.say.1.hostile",
                ["translations"] = {
                    ["EN"] = {
                        "That group looks hostile. Keep cover between us and them.",
                    },
                    ["TL"] = {
                        "That group looks hostile. Keep cover between us and them.",
                    },
                },
                ["variantID"] = "hostile",
            },
            {
                ["fallback"] = "Someone is out there. Let us watch before we approach.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.encounter.say.1.unknown",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is out there. Let us watch before we approach.",
                    },
                    ["TL"] = {
                        "Someone is out there. Let us watch before we approach.",
                    },
                },
                ["variantID"] = "unknown",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.faction",
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
                                ["fallback"] = "That faction may be hostile toward us now. Stay alert.",
                                ["id"] = "hostile",
                                ["templateID"] = "convo.integration.projectalife.faction.say.1.hostile",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                    ["TL"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "They just opened fire on us. Stay close.",
                                ["id"] = "incoming",
                                ["templateID"] = "convo.integration.projectalife.faction.say.1.incoming",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                    ["TL"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "We hit them. They may retaliate soon.",
                                ["id"] = "outgoing",
                                ["templateID"] = "convo.integration.projectalife.faction.say.1.outgoing",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We hit them. They may retaliate soon.",
                                    },
                                    ["TL"] = {
                                        "We hit them. They may retaliate soon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife",
            ["textRoles"] = {
                {
                    ["fallback"] = "That faction may be hostile toward us now. Stay alert.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.say.1.hostile",
                    ["translations"] = {
                        ["EN"] = {
                            "That faction may be hostile toward us now. Stay alert.",
                        },
                        ["TL"] = {
                            "That faction may be hostile toward us now. Stay alert.",
                        },
                    },
                    ["variantID"] = "hostile",
                },
                {
                    ["fallback"] = "They just opened fire on us. Stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.say.1.incoming",
                    ["translations"] = {
                        ["EN"] = {
                            "They just opened fire on us. Stay close.",
                        },
                        ["TL"] = {
                            "They just opened fire on us. Stay close.",
                        },
                    },
                    ["variantID"] = "incoming",
                },
                {
                    ["fallback"] = "We hit them. They may retaliate soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.say.1.outgoing",
                    ["translations"] = {
                        ["EN"] = {
                            "We hit them. They may retaliate soon.",
                        },
                        ["TL"] = {
                            "We hit them. They may retaliate soon.",
                        },
                    },
                    ["variantID"] = "outgoing",
                },
            },
        },
        ["id"] = "integration.projectalife.faction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "faction",
            ["sourceId"] = "integration.projectalife.faction",
            ["sourcePath"] = "dialogue/compatibility_content/integration_projectalife_faction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "hostile",
                                ["text"] = {
                                    ["EN"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                    ["TL"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                },
                            },
                            {
                                ["id"] = "incoming",
                                ["text"] = {
                                    ["EN"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                    ["TL"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                },
                            },
                            {
                                ["id"] = "outgoing",
                                ["text"] = {
                                    ["EN"] = {
                                        "We hit them. They may retaliate soon.",
                                    },
                                    ["TL"] = {
                                        "We hit them. They may retaliate soon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "projectalife",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.faction",
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
                            ["fallback"] = "That faction may be hostile toward us now. Stay alert.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.projectalife.faction.say_1",
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
        ["sourceShard"] = "dialogue/compatibility_content/integration_projectalife_faction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That faction may be hostile toward us now. Stay alert.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.faction.say.1.hostile",
                ["translations"] = {
                    ["EN"] = {
                        "That faction may be hostile toward us now. Stay alert.",
                    },
                    ["TL"] = {
                        "That faction may be hostile toward us now. Stay alert.",
                    },
                },
                ["variantID"] = "hostile",
            },
            {
                ["fallback"] = "They just opened fire on us. Stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.faction.say.1.incoming",
                ["translations"] = {
                    ["EN"] = {
                        "They just opened fire on us. Stay close.",
                    },
                    ["TL"] = {
                        "They just opened fire on us. Stay close.",
                    },
                },
                ["variantID"] = "incoming",
            },
            {
                ["fallback"] = "We hit them. They may retaliate soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.faction.say.1.outgoing",
                ["translations"] = {
                    ["EN"] = {
                        "We hit them. They may retaliate soon.",
                    },
                    ["TL"] = {
                        "We hit them. They may retaliate soon.",
                    },
                },
                ["variantID"] = "outgoing",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["domainPath"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta",
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
                                ["fallback"] = "Something is flying over us. Keep listening.",
                                ["id"] = "aircraft.heli",
                                ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.heli",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                    ["TL"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "That aircraft sounds close. Stay sharp.",
                                ["id"] = "aircraft.military",
                                ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.military",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                    ["TL"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "I do not like that sound. Stay close.",
                                ["id"] = "ambience",
                                ["templateID"] = "convo.integration.projectalife.meta.say.1.ambience",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                    ["TL"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                                ["id"] = "crash",
                                ["templateID"] = "convo.integration.projectalife.meta.say.1.crash",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                },
                            },
                            {
                                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                                ["id"] = "gunfire",
                                ["templateID"] = "convo.integration.projectalife.meta.say.1.gunfire",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife",
            ["textRoles"] = {
                {
                    ["fallback"] = "Something is flying over us. Keep listening.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.heli",
                    ["translations"] = {
                        ["EN"] = {
                            "Something is flying over us. Keep listening.",
                        },
                        ["TL"] = {
                            "Something is flying over us. Keep listening.",
                        },
                    },
                    ["variantID"] = "aircraft.heli",
                },
                {
                    ["fallback"] = "That aircraft sounds close. Stay sharp.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.military",
                    ["translations"] = {
                        ["EN"] = {
                            "That aircraft sounds close. Stay sharp.",
                        },
                        ["TL"] = {
                            "That aircraft sounds close. Stay sharp.",
                        },
                    },
                    ["variantID"] = "aircraft.military",
                },
                {
                    ["fallback"] = "I do not like that sound. Stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.say.1.ambience",
                    ["translations"] = {
                        ["EN"] = {
                            "I do not like that sound. Stay close.",
                        },
                        ["TL"] = {
                            "I do not like that sound. Stay close.",
                        },
                    },
                    ["variantID"] = "ambience",
                },
                {
                    ["fallback"] = "That crash sounded close. Keep your eyes open.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.say.1.crash",
                    ["translations"] = {
                        ["EN"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                        ["TL"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                    },
                    ["variantID"] = "crash",
                },
                {
                    ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.say.1.gunfire",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                        ["TL"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                    },
                    ["variantID"] = "gunfire",
                },
            },
        },
        ["id"] = "integration.projectalife.meta",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "meta",
            ["sourceId"] = "integration.projectalife.meta",
            ["sourcePath"] = "dialogue/compatibility_content/integration_projectalife_meta.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife",
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
                    ["domain"] = "integration",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
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
                                ["id"] = "aircraft.heli",
                                ["text"] = {
                                    ["EN"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                    ["TL"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                },
                            },
                            {
                                ["id"] = "aircraft.military",
                                ["text"] = {
                                    ["EN"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                    ["TL"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                },
                            },
                            {
                                ["id"] = "ambience",
                                ["text"] = {
                                    ["EN"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                    ["TL"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                },
                            },
                            {
                                ["id"] = "crash",
                                ["text"] = {
                                    ["EN"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                },
                            },
                            {
                                ["id"] = "gunfire",
                                ["text"] = {
                                    ["EN"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Someone is shooting nearby. Keep your head down.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "integration",
                    ["id"] = "projectalife",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta",
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
                            ["fallback"] = "Something is flying over us. Keep listening.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.integration.projectalife.meta.say_1",
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
        ["sourceShard"] = "dialogue/compatibility_content/integration_projectalife_meta.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Something is flying over us. Keep listening.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.heli",
                ["translations"] = {
                    ["EN"] = {
                        "Something is flying over us. Keep listening.",
                    },
                    ["TL"] = {
                        "Something is flying over us. Keep listening.",
                    },
                },
                ["variantID"] = "aircraft.heli",
            },
            {
                ["fallback"] = "That aircraft sounds close. Stay sharp.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.say.1.aircraft.military",
                ["translations"] = {
                    ["EN"] = {
                        "That aircraft sounds close. Stay sharp.",
                    },
                    ["TL"] = {
                        "That aircraft sounds close. Stay sharp.",
                    },
                },
                ["variantID"] = "aircraft.military",
            },
            {
                ["fallback"] = "I do not like that sound. Stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.say.1.ambience",
                ["translations"] = {
                    ["EN"] = {
                        "I do not like that sound. Stay close.",
                    },
                    ["TL"] = {
                        "I do not like that sound. Stay close.",
                    },
                },
                ["variantID"] = "ambience",
            },
            {
                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.say.1.crash",
                ["translations"] = {
                    ["EN"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                    ["TL"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                },
                ["variantID"] = "crash",
            },
            {
                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.say.1.gunfire",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                    ["TL"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                },
                ["variantID"] = "gunfire",
            },
        },
        ["when"] = nil,
    },
}
