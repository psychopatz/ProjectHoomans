-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.bandits.hooman_hurt.colonist",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.colonist.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.bandits.hooman_hurt",
            ["textRoles"] = {
                {
                    ["fallback"] = "Bandit fire! Pull back and cover the wounded colonist.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.colonist.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Pull back and cover the wounded colonist.",
                        },
                        ["TL"] = {
                            "Bandit fire! Pull back and cover the wounded colonist.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.bandits.hooman_hurt.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "colonist",
            ["sourceId"] = "integration.bandits.hooman_hurt.colonist",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_colonist.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.bandits.hooman_hurt",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Pull back and cover the wounded colonist.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.bandits.hooman_hurt.colonist",
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
                            ["templateID"] = "psdl.integration.bandits.hooman_hurt.colonist.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_colonist.json",
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
                ["templateID"] = "convo.integration.bandits.hooman_hurt.colonist.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Pull back and cover the wounded colonist.",
                    },
                    ["TL"] = {
                        "Bandit fire! Pull back and cover the wounded colonist.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.bandits.hooman_hurt.default",
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
                                ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.default.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.bandits.hooman_hurt",
            ["textRoles"] = {
                {
                    ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Stay with the wounded survivor and watch the flank.",
                        },
                        ["TL"] = {
                            "Bandit fire! Stay with the wounded survivor and watch the flank.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.bandits.hooman_hurt.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "integration.bandits.hooman_hurt.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.bandits.hooman_hurt",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.bandits.hooman_hurt.default",
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
                            ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.bandits.hooman_hurt.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Bandit fire! Stay with the wounded survivor and watch the flank.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    },
                    ["TL"] = {
                        "Bandit fire! Stay with the wounded survivor and watch the flank.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.bandits.hooman_hurt.family",
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
                                ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.family.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.bandits.hooman_hurt",
            ["textRoles"] = {
                {
                    ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.family.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire! Stay together and cover the wounded family member.",
                        },
                        ["TL"] = {
                            "Bandit fire! Stay together and cover the wounded family member.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.bandits.hooman_hurt.family",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "family",
            ["sourceId"] = "integration.bandits.hooman_hurt.family",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_family.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.bandits.hooman_hurt",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                    ["TL"] = {
                                        "Bandit fire! Stay together and cover the wounded family member.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.bandits.hooman_hurt.family",
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
                            ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.bandits.hooman_hurt.family.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_family.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Bandit fire! Stay together and cover the wounded family member.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.family.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire! Stay together and cover the wounded family member.",
                    },
                    ["TL"] = {
                        "Bandit fire! Stay together and cover the wounded family member.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.bandits.hooman_hurt.lover",
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
                                ["fallback"] = "Bandit fire. Stay close; I have got you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.bandits.hooman_hurt.lover.say.1.neutral",
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
            ["namespace"] = "integration.bandits.hooman_hurt",
            ["textRoles"] = {
                {
                    ["fallback"] = "Bandit fire. Stay close; I have got you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.bandits.hooman_hurt.lover.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Bandit fire. Stay close; I have got you.",
                        },
                        ["TL"] = {
                            "Bandit fire. Stay close; I have got you.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.bandits.hooman_hurt.lover",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "lover",
            ["sourceId"] = "integration.bandits.hooman_hurt.lover",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_lover.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.bandits.hooman_hurt",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.bandits.hooman_hurt.lover",
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
                            ["fallback"] = "Bandit fire. Stay close; I have got you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.bandits.hooman_hurt.lover.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_bandits_hooman_hurt_lover.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Bandit fire. Stay close; I have got you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.bandits.hooman_hurt.lover.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Bandit fire. Stay close; I have got you.",
                    },
                    ["TL"] = {
                        "Bandit fire. Stay close; I have got you.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.feed.female",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.feed.female.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs.feed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Here you go, good girl.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.female.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good girl.",
                        },
                        ["TL"] = {
                            "Here you go, good girl.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.feed.female",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "female",
            ["sourceId"] = "integration.companion_dogs.feed.female",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_female.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.feed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Here you go, good girl.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good girl.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.feed.female",
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
                            ["templateID"] = "psdl.integration.companion_dogs.feed.female.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_female.json",
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
                ["templateID"] = "convo.integration.companion_dogs.feed.female.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good girl.",
                    },
                    ["TL"] = {
                        "Here you go, good girl.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.feed.male",
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
                                ["fallback"] = "Here you go, good boy.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.feed.male.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs.feed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Here you go, good boy.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.male.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good boy.",
                        },
                        ["TL"] = {
                            "Here you go, good boy.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.feed.male",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "male",
            ["sourceId"] = "integration.companion_dogs.feed.male",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_male.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.feed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Here you go, good boy.",
                                    },
                                    ["TL"] = {
                                        "Here you go, good boy.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.feed.male",
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
                            ["fallback"] = "Here you go, good boy.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.companion_dogs.feed.male.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_male.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Here you go, good boy.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.feed.male.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good boy.",
                    },
                    ["TL"] = {
                        "Here you go, good boy.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.feed.unknown",
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
                                ["fallback"] = "Here you go, good dog.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.feed.unknown.say.1.neutral",
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
            ["namespace"] = "integration.companion_dogs.feed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Here you go, good dog.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.feed.unknown.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go, good dog.",
                        },
                        ["TL"] = {
                            "Here you go, good dog.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.feed.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unknown",
            ["sourceId"] = "integration.companion_dogs.feed.unknown",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.feed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.feed.unknown",
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
                            ["fallback"] = "Here you go, good dog.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.companion_dogs.feed.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_feed_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Here you go, good dog.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.feed.unknown.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go, good dog.",
                    },
                    ["TL"] = {
                        "Here you go, good dog.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.greeting.female",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.female.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "Who is a good girl?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.female.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good girl?",
                        },
                        ["TL"] = {
                            "Who is a good girl?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.greeting.female",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "female",
            ["sourceId"] = "integration.companion_dogs.greeting.female",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_female.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.greeting",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Who is a good girl?",
                                    },
                                    ["TL"] = {
                                        "Who is a good girl?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.greeting.female",
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
                            ["templateID"] = "psdl.integration.companion_dogs.greeting.female.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_female.json",
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
                ["templateID"] = "convo.integration.companion_dogs.greeting.female.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good girl?",
                    },
                    ["TL"] = {
                        "Who is a good girl?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.greeting.male",
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
                                ["fallback"] = "Who is a good boy?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.male.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.companion_dogs.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "Who is a good boy?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.male.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good boy?",
                        },
                        ["TL"] = {
                            "Who is a good boy?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.greeting.male",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "male",
            ["sourceId"] = "integration.companion_dogs.greeting.male",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_male.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.greeting",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Who is a good boy?",
                                    },
                                    ["TL"] = {
                                        "Who is a good boy?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.greeting.male",
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
                            ["fallback"] = "Who is a good boy?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.companion_dogs.greeting.male.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_male.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Who is a good boy?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.greeting.male.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good boy?",
                    },
                    ["TL"] = {
                        "Who is a good boy?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.companion_dogs.greeting.unknown",
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
                                ["fallback"] = "Who is a good dog?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.companion_dogs.greeting.unknown.say.1.neutral",
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
            ["namespace"] = "integration.companion_dogs.greeting",
            ["textRoles"] = {
                {
                    ["fallback"] = "Who is a good dog?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.companion_dogs.greeting.unknown.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Who is a good dog?",
                        },
                        ["TL"] = {
                            "Who is a good dog?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.companion_dogs.greeting.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unknown",
            ["sourceId"] = "integration.companion_dogs.greeting.unknown",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.companion_dogs.greeting",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.companion_dogs.greeting.unknown",
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
                            ["fallback"] = "Who is a good dog?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.companion_dogs.greeting.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_companion_dogs_greeting_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Who is a good dog?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.companion_dogs.greeting.unknown.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Who is a good dog?",
                    },
                    ["TL"] = {
                        "Who is a good dog?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.mask_warning.colonist",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.mask_warning.colonist.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa.mask_warning",
            ["textRoles"] = {
                {
                    ["fallback"] = "Mask up. We keep the camp safe together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.colonist.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Mask up. We keep the camp safe together.",
                        },
                        ["TL"] = {
                            "Mask up. We keep the camp safe together.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.mask_warning.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "colonist",
            ["sourceId"] = "integration.necroa.mask_warning.colonist",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_colonist.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.mask_warning",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                    ["TL"] = {
                                        "Mask up. We keep the camp safe together.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.mask_warning.colonist",
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
                            ["templateID"] = "psdl.integration.necroa.mask_warning.colonist.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_colonist.json",
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
                ["templateID"] = "convo.integration.necroa.mask_warning.colonist.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Mask up. We keep the camp safe together.",
                    },
                    ["TL"] = {
                        "Mask up. We keep the camp safe together.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.mask_warning.default",
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
                                ["fallback"] = "Put your mask back on. Knox is airborne.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.mask_warning.default.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa.mask_warning",
            ["textRoles"] = {
                {
                    ["fallback"] = "Put your mask back on. Knox is airborne.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on. Knox is airborne.",
                        },
                        ["TL"] = {
                            "Put your mask back on. Knox is airborne.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.mask_warning.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "integration.necroa.mask_warning.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.mask_warning",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. Knox is airborne.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.mask_warning.default",
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
                            ["fallback"] = "Put your mask back on. Knox is airborne.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.necroa.mask_warning.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Put your mask back on. Knox is airborne.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.mask_warning.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on. Knox is airborne.",
                    },
                    ["TL"] = {
                        "Put your mask back on. Knox is airborne.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.mask_warning.family",
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
                                ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.mask_warning.family.say.1.neutral",
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
            ["namespace"] = "integration.necroa.mask_warning",
            ["textRoles"] = {
                {
                    ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.mask_warning.family.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask on, family. I am not losing you to the air.",
                        },
                        ["TL"] = {
                            "Put your mask on, family. I am not losing you to the air.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.mask_warning.family",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "family",
            ["sourceId"] = "integration.necroa.mask_warning.family",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_family.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.mask_warning",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.mask_warning.family",
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
                            ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.necroa.mask_warning.family.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_mask_warning_family.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Put your mask on, family. I am not losing you to the air.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.mask_warning.family.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask on, family. I am not losing you to the air.",
                    },
                    ["TL"] = {
                        "Put your mask on, family. I am not losing you to the air.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.player_mask_removed.default",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.default.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa.player_mask_removed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Put your mask back on. The air is not safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on. The air is not safe.",
                        },
                        ["TL"] = {
                            "Put your mask back on. The air is not safe.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.player_mask_removed.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "integration.necroa.player_mask_removed.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.player_mask_removed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on. The air is not safe.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.player_mask_removed.default",
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
                            ["templateID"] = "psdl.integration.necroa.player_mask_removed.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_default.json",
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
                ["templateID"] = "convo.integration.necroa.player_mask_removed.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on. The air is not safe.",
                    },
                    ["TL"] = {
                        "Put your mask back on. The air is not safe.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.player_mask_removed.hostile",
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
                                ["fallback"] = "Put your mask back on before you become a problem.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.hostile.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.necroa.player_mask_removed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Put your mask back on before you become a problem.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.hostile.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Put your mask back on before you become a problem.",
                        },
                        ["TL"] = {
                            "Put your mask back on before you become a problem.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.player_mask_removed.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hostile",
            ["sourceId"] = "integration.necroa.player_mask_removed.hostile",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.player_mask_removed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                    ["TL"] = {
                                        "Put your mask back on before you become a problem.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.player_mask_removed.hostile",
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
                            ["fallback"] = "Put your mask back on before you become a problem.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.necroa.player_mask_removed.hostile.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Put your mask back on before you become a problem.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.player_mask_removed.hostile.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Put your mask back on before you become a problem.",
                    },
                    ["TL"] = {
                        "Put your mask back on before you become a problem.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.necroa.player_mask_removed.lover",
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
                                ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.necroa.player_mask_removed.lover.say.1.neutral",
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
            ["namespace"] = "integration.necroa.player_mask_removed",
            ["textRoles"] = {
                {
                    ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.necroa.player_mask_removed.lover.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Please put your mask back on, love. This air is not safe.",
                        },
                        ["TL"] = {
                            "Please put your mask back on, love. This air is not safe.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.necroa.player_mask_removed.lover",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "lover",
            ["sourceId"] = "integration.necroa.player_mask_removed.lover",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_lover.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.necroa.player_mask_removed",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.necroa.player_mask_removed.lover",
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
                            ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.necroa.player_mask_removed.lover.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_necroa_player_mask_removed_lover.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Please put your mask back on, love. This air is not safe.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.necroa.player_mask_removed.lover.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Please put your mask back on, love. This air is not safe.",
                    },
                    ["TL"] = {
                        "Please put your mask back on, love. This air is not safe.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.encounter.friendly",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.encounter.friendly.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.encounter",
            ["textRoles"] = {
                {
                    ["fallback"] = "Those survivors seem friendly. Keep your hands visible.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.friendly.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Those survivors seem friendly. Keep your hands visible.",
                        },
                        ["TL"] = {
                            "Those survivors seem friendly. Keep your hands visible.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.encounter.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "friendly",
            ["sourceId"] = "integration.projectalife.encounter.friendly",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.encounter",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                    ["TL"] = {
                                        "Those survivors seem friendly. Keep your hands visible.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.encounter.friendly",
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
                            ["templateID"] = "psdl.integration.projectalife.encounter.friendly.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter.json",
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
                ["templateID"] = "convo.integration.projectalife.encounter.friendly.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Those survivors seem friendly. Keep your hands visible.",
                    },
                    ["TL"] = {
                        "Those survivors seem friendly. Keep your hands visible.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.encounter.hostile",
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
                                ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.encounter.hostile.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.encounter",
            ["textRoles"] = {
                {
                    ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.hostile.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That group looks hostile. Keep cover between us and them.",
                        },
                        ["TL"] = {
                            "That group looks hostile. Keep cover between us and them.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.encounter.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hostile",
            ["sourceId"] = "integration.projectalife.encounter.hostile",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.encounter",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                    ["TL"] = {
                                        "That group looks hostile. Keep cover between us and them.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.encounter.hostile",
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
                            ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.encounter.hostile.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That group looks hostile. Keep cover between us and them.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.encounter.hostile.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That group looks hostile. Keep cover between us and them.",
                    },
                    ["TL"] = {
                        "That group looks hostile. Keep cover between us and them.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.encounter.unknown",
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
                                ["fallback"] = "Someone is out there. Let us watch before we approach.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.encounter.unknown.say.1.neutral",
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
            ["namespace"] = "integration.projectalife.encounter",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone is out there. Let us watch before we approach.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.encounter.unknown.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is out there. Let us watch before we approach.",
                        },
                        ["TL"] = {
                            "Someone is out there. Let us watch before we approach.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.encounter.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unknown",
            ["sourceId"] = "integration.projectalife.encounter.unknown",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.encounter",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.encounter.unknown",
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
                            ["fallback"] = "Someone is out there. Let us watch before we approach.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.encounter.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_encounter_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone is out there. Let us watch before we approach.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.encounter.unknown.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is out there. Let us watch before we approach.",
                    },
                    ["TL"] = {
                        "Someone is out there. Let us watch before we approach.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.faction.hostile",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.faction.hostile.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.faction",
            ["textRoles"] = {
                {
                    ["fallback"] = "That faction may be hostile toward us now. Stay alert.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.hostile.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That faction may be hostile toward us now. Stay alert.",
                        },
                        ["TL"] = {
                            "That faction may be hostile toward us now. Stay alert.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.faction.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hostile",
            ["sourceId"] = "integration.projectalife.faction.hostile",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.faction",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                    ["TL"] = {
                                        "That faction may be hostile toward us now. Stay alert.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.faction.hostile",
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
                            ["templateID"] = "psdl.integration.projectalife.faction.hostile.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_hostile.json",
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
                ["templateID"] = "convo.integration.projectalife.faction.hostile.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That faction may be hostile toward us now. Stay alert.",
                    },
                    ["TL"] = {
                        "That faction may be hostile toward us now. Stay alert.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.faction.incoming",
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
                                ["fallback"] = "They just opened fire on us. Stay close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.faction.incoming.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.faction",
            ["textRoles"] = {
                {
                    ["fallback"] = "They just opened fire on us. Stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.incoming.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "They just opened fire on us. Stay close.",
                        },
                        ["TL"] = {
                            "They just opened fire on us. Stay close.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.faction.incoming",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "incoming",
            ["sourceId"] = "integration.projectalife.faction.incoming",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_incoming.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.faction",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                    ["TL"] = {
                                        "They just opened fire on us. Stay close.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.faction.incoming",
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
                            ["fallback"] = "They just opened fire on us. Stay close.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.faction.incoming.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_incoming.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They just opened fire on us. Stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.faction.incoming.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "They just opened fire on us. Stay close.",
                    },
                    ["TL"] = {
                        "They just opened fire on us. Stay close.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.faction.outgoing",
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
                                ["fallback"] = "We hit them. They may retaliate soon.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.faction.outgoing.say.1.neutral",
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
            ["namespace"] = "integration.projectalife.faction",
            ["textRoles"] = {
                {
                    ["fallback"] = "We hit them. They may retaliate soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.faction.outgoing.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We hit them. They may retaliate soon.",
                        },
                        ["TL"] = {
                            "We hit them. They may retaliate soon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.faction.outgoing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "outgoing",
            ["sourceId"] = "integration.projectalife.faction.outgoing",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_outgoing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.faction",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.faction.outgoing",
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
                            ["fallback"] = "We hit them. They may retaliate soon.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.faction.outgoing.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_faction_outgoing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We hit them. They may retaliate soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.faction.outgoing.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We hit them. They may retaliate soon.",
                    },
                    ["TL"] = {
                        "We hit them. They may retaliate soon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.aircraft.heli",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.aircraft.heli.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta.aircraft",
            ["textRoles"] = {
                {
                    ["fallback"] = "Something is flying over us. Keep listening.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.aircraft.heli.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Something is flying over us. Keep listening.",
                        },
                        ["TL"] = {
                            "Something is flying over us. Keep listening.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.aircraft.heli",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "heli",
            ["sourceId"] = "integration.projectalife.meta.aircraft.heli",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_aircraft_heli.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.meta.aircraft",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                    ["TL"] = {
                                        "Something is flying over us. Keep listening.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.aircraft.heli",
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
                            ["templateID"] = "psdl.integration.projectalife.meta.aircraft.heli.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_aircraft_heli.json",
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
                ["templateID"] = "convo.integration.projectalife.meta.aircraft.heli.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Something is flying over us. Keep listening.",
                    },
                    ["TL"] = {
                        "Something is flying over us. Keep listening.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.aircraft.military",
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
                                ["fallback"] = "That aircraft sounds close. Stay sharp.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.aircraft.military.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta.aircraft",
            ["textRoles"] = {
                {
                    ["fallback"] = "That aircraft sounds close. Stay sharp.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.aircraft.military.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That aircraft sounds close. Stay sharp.",
                        },
                        ["TL"] = {
                            "That aircraft sounds close. Stay sharp.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.aircraft.military",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "military",
            ["sourceId"] = "integration.projectalife.meta.aircraft.military",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_aircraft_military.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.meta.aircraft",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                    ["TL"] = {
                                        "That aircraft sounds close. Stay sharp.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.aircraft.military",
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
                            ["fallback"] = "That aircraft sounds close. Stay sharp.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.meta.aircraft.military.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_aircraft_military.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That aircraft sounds close. Stay sharp.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.aircraft.military.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That aircraft sounds close. Stay sharp.",
                    },
                    ["TL"] = {
                        "That aircraft sounds close. Stay sharp.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.ambience",
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
                                ["fallback"] = "I do not like that sound. Stay close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.ambience.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta",
            ["textRoles"] = {
                {
                    ["fallback"] = "I do not like that sound. Stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.ambience.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I do not like that sound. Stay close.",
                        },
                        ["TL"] = {
                            "I do not like that sound. Stay close.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.ambience",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "ambience",
            ["sourceId"] = "integration.projectalife.meta.ambience",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_ambience.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.meta",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                    ["TL"] = {
                                        "I do not like that sound. Stay close.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.ambience",
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
                            ["fallback"] = "I do not like that sound. Stay close.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.meta.ambience.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_ambience.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I do not like that sound. Stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.ambience.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I do not like that sound. Stay close.",
                    },
                    ["TL"] = {
                        "I do not like that sound. Stay close.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.crash",
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
                                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
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
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "integration.projectalife.meta",
            ["textRoles"] = {
                {
                    ["fallback"] = "That crash sounded close. Keep your eyes open.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                        ["TL"] = {
                            "That crash sounded close. Keep your eyes open.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.crash",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "crash",
            ["sourceId"] = "integration.projectalife.meta.crash",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_crash.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.meta",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "That crash sounded close. Keep your eyes open.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.crash",
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
                            ["fallback"] = "That crash sounded close. Keep your eyes open.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.meta.crash.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_crash.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That crash sounded close. Keep your eyes open.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.crash.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                    ["TL"] = {
                        "That crash sounded close. Keep your eyes open.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "compatibility_content",
        ["exchangeFamily"] = {
            ["familyID"] = "integration.projectalife.meta.gunfire",
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
                                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
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
            ["namespace"] = "integration.projectalife.meta",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                        ["TL"] = {
                            "Someone is shooting nearby. Keep your head down.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "integration.projectalife.meta.gunfire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "gunfire",
            ["sourceId"] = "integration.projectalife.meta.gunfire",
            ["sourcePath"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_gunfire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompatibilityContent",
        ["namespace"] = "integration.projectalife.meta",
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
            ["metadata"] = {
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
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
                                ["id"] = "neutral",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "integration.projectalife.meta.gunfire",
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
                            ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.integration.projectalife.meta.gunfire.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/compatibility_content/integration_projectalife_meta_gunfire.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone is shooting nearby. Keep your head down.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.integration.projectalife.meta.gunfire.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                    ["TL"] = {
                        "Someone is shooting nearby. Keep your head down.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
