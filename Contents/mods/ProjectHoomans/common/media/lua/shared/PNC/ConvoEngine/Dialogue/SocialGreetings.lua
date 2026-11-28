-- Hand-maintained ProjectHoomans ConvoEngine module.
return {
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.acquaintance.dawn",
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
                                ["fallback"] = "You're awake early too. Everything all right?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.acquaintance.dawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.acquaintance",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're awake early too. Everything all right?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.acquaintance.dawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.acquaintance.dawn",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_acquaintance_dawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.acquaintance",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["modernizationRetention"] = {
                    ["evidenceCode"] = "NON_PARAMETERIZABLE_PREDICATES",
                    ["nonParameterizableBy"] = "runtimeBlockID",
                    ["reason"] = "Each greeting block projects to a distinct runtimeBlockID, textTarget, and block.gates entry in Conversation.Registry (plus hostile.parley response/offers/effects), which Conversation.Selector.SelectBlock dispatches at block granularity.",
                },
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_dawn",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.dawn",
                ["textRows"] = {
                    {
                        ["fallback"] = "You're awake early too. Everything all right?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Morning. I didn't expect to see you before sunrise.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Couldn't sleep? Neither could I.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Good, it's you. What brings you over this early?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Dawn patrol, or did you need something?",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/acquaintance/dawn",
                ["weight"] = 100,
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
                                ["fallback"] = "You're awake early too. Everything all right?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.acquaintance.dawn",
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
                            ["fallback"] = "You're awake early too. Everything all right?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.acquaintance.dawn.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_acquaintance_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're awake early too. Everything all right?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.acquaintance.dawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.acquaintance.dusk",
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
                                ["fallback"] = "Evening. Need something before we turn in?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.acquaintance.dusk.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.acquaintance",
            ["textRoles"] = {
                {
                    ["fallback"] = "Evening. Need something before we turn in?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.acquaintance.dusk.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.acquaintance.dusk",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_acquaintance_dusk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.acquaintance",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_dusk",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.dusk",
                ["textRows"] = {
                    {
                        ["fallback"] = "Evening. Need something before we turn in?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Good, it's only you. You startled me.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Not much daylight left. Talk to me.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Hey. Keeping watch, or just passing by?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "We should keep this quiet, but I'm listening.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/acquaintance/dusk",
                ["weight"] = 100,
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
                                ["fallback"] = "Evening. Need something before we turn in?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.acquaintance.dusk",
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
                            ["fallback"] = "Evening. Need something before we turn in?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.acquaintance.dusk.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_acquaintance_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Evening. Need something before we turn in?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.acquaintance.dusk.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.acquaintance.sunrise",
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
                                ["fallback"] = "Morning. Good to see a familiar face.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.acquaintance.sunrise.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.acquaintance",
            ["textRoles"] = {
                {
                    ["fallback"] = "Morning. Good to see a familiar face.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.acquaintance.sunrise.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.acquaintance.sunrise",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_acquaintance_sunrise.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.acquaintance",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_sunrise",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.sunrise",
                ["textRows"] = {
                    {
                        ["fallback"] = "Morning. Good to see a familiar face.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Hey. How's the day treating you?",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "There you are. Need a minute?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Morning. You look like you have something on your mind.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Nice to see you made it through another night.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/acquaintance/sunrise",
                ["weight"] = 100,
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
                                ["fallback"] = "Morning. Good to see a familiar face.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.acquaintance.sunrise",
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
                            ["fallback"] = "Morning. Good to see a familiar face.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.acquaintance.sunrise.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_acquaintance_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Morning. Good to see a familiar face.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.acquaintance.sunrise.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.acquaintance.sunset",
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
                                ["fallback"] = "Hey. Been a long day?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.acquaintance.sunset.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.acquaintance",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hey. Been a long day?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.acquaintance.sunset.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.acquaintance.sunset",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_acquaintance_sunset.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.acquaintance",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_sunset",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.sunset",
                ["textRows"] = {
                    {
                        ["fallback"] = "Hey. Been a long day?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Good timing. I was about to settle in.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "There you are. Find anything useful today?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "The day's winding down. What's up?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "You look tired. Everything okay?",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/acquaintance/sunset",
                ["weight"] = 100,
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
                                ["fallback"] = "Hey. Been a long day?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.acquaintance.sunset",
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
                            ["fallback"] = "Hey. Been a long day?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.acquaintance.sunset.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_acquaintance_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hey. Been a long day?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.acquaintance.sunset.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.acquaintance.twilight",
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
                                ["fallback"] = "Late night. What has you awake?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.acquaintance.twilight.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.acquaintance",
            ["textRoles"] = {
                {
                    ["fallback"] = "Late night. What has you awake?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.acquaintance.twilight.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.acquaintance.twilight",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_acquaintance_twilight.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.acquaintance",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_twilight",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.twilight",
                ["textRows"] = {
                    {
                        ["fallback"] = "Late night. What has you awake?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "It's good to see someone I recognize out here.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Keep it down. Sound carries at night.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "You all right? It's late to be wandering.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Hey. Make it quick before we draw attention.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/acquaintance/twilight",
                ["weight"] = 100,
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
                                ["fallback"] = "Late night. What has you awake?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.acquaintance.twilight",
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
                            ["fallback"] = "Late night. What has you awake?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.acquaintance.twilight.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_acquaintance_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Late night. What has you awake?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.acquaintance.twilight.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Acquaintance",
                },
                {
                    ["any"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.firstmeet.dawn",
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
                                ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.firstmeet.dawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.firstmeet",
            ["textRoles"] = {
                {
                    ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.firstmeet.dawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.firstmeet.dawn",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_firstmeet_dawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.firstmeet",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dawn",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.first_meet.dawn",
                ["textRows"] = {
                    {
                        ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "You're up before the dead settle down. Who are you?",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Easy. The light is barely up, and I wasn't expecting company.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Morning, I suppose. Keep your hands where I can see them.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "First light and a new face. Tell me what you need.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/first_meet/dawn",
                ["weight"] = 100,
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
                                ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.firstmeet.dawn",
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
                            ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.firstmeet.dawn.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_firstmeet_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.firstmeet.dawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "FirstMeet",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.firstmeet.dusk",
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
                                ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.firstmeet.dusk.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.firstmeet",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.firstmeet.dusk.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.firstmeet.dusk",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_firstmeet_dusk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.firstmeet",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dusk",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.first_meet.dusk",
                ["textRows"] = {
                    {
                        ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Not much light left. Introduce yourself.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "You surprised me. What do you want?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Keep your voice down and tell me why you're here.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "I can't make out your face. Come no closer.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/first_meet/dusk",
                ["weight"] = 100,
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
                                ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.firstmeet.dusk",
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
                            ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.firstmeet.dusk.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_firstmeet_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stop there. Dusk makes strangers hard to read.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.firstmeet.dusk.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "FirstMeet",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.firstmeet.sunrise",
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
                                ["fallback"] = "Morning. I haven't seen you around before.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.firstmeet.sunrise.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.firstmeet",
            ["textRoles"] = {
                {
                    ["fallback"] = "Morning. I haven't seen you around before.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.firstmeet.sunrise.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.firstmeet.sunrise",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_firstmeet_sunrise.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.firstmeet",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_sunrise",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.first_meet.sunrise",
                ["textRows"] = {
                    {
                        ["fallback"] = "Morning. I haven't seen you around before.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "That's close enough. Start with your name.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "New face. Are you passing through or looking for something?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Daylight makes this easier. Who are you?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "I don't recognize you. Talk, and keep it calm.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/first_meet/sunrise",
                ["weight"] = 100,
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
                                ["fallback"] = "Morning. I haven't seen you around before.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.firstmeet.sunrise",
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
                            ["fallback"] = "Morning. I haven't seen you around before.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.firstmeet.sunrise.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_firstmeet_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Morning. I haven't seen you around before.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.firstmeet.sunrise.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "FirstMeet",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.firstmeet.sunset",
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
                                ["fallback"] = "You picked a late hour to approach a stranger.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.firstmeet.sunset.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.firstmeet",
            ["textRoles"] = {
                {
                    ["fallback"] = "You picked a late hour to approach a stranger.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.firstmeet.sunset.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.firstmeet.sunset",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_firstmeet_sunset.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.firstmeet",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_sunset",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.first_meet.sunset",
                ["textRows"] = {
                    {
                        ["fallback"] = "You picked a late hour to approach a stranger.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "The light is going. Say what you came to say.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "I don't know you, but I'm listening.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Before it gets dark, tell me who you are.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Another survivor. Friendly, I hope?",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/first_meet/sunset",
                ["weight"] = 100,
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
                                ["fallback"] = "You picked a late hour to approach a stranger.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.firstmeet.sunset",
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
                            ["fallback"] = "You picked a late hour to approach a stranger.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.firstmeet.sunset.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_firstmeet_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You picked a late hour to approach a stranger.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.firstmeet.sunset.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "FirstMeet",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.firstmeet.twilight",
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
                                ["fallback"] = "It's dark out. Stay where I can see you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.firstmeet.twilight.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.firstmeet",
            ["textRoles"] = {
                {
                    ["fallback"] = "It's dark out. Stay where I can see you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.firstmeet.twilight.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.firstmeet.twilight",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_firstmeet_twilight.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.firstmeet",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_twilight",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.first_meet.twilight",
                ["textRows"] = {
                    {
                        ["fallback"] = "It's dark out. Stay where I can see you.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "A stranger walking up at night usually means trouble.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Keep your voice low. Who are you?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "You chose a bad time to sneak up on someone.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Don't move any closer. We can talk from there.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/neutral/first_meet/twilight",
                ["weight"] = 100,
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
                                ["fallback"] = "It's dark out. Stay where I can see you.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.firstmeet.twilight",
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
                            ["fallback"] = "It's dark out. Stay where I can see you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.firstmeet.twilight.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_firstmeet_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "It's dark out. Stay where I can see you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.firstmeet.twilight.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "FirstMeet",
                },
                {
                    ["any"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["id"] = "social.greetings.hostile.parley",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "parley",
            ["sourceId"] = "social.greetings.hostile.parley",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_hostile_parley.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.hostile",
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
                ["audience"] = "hostile",
                ["category"] = "projecthoomans:greetings",
                ["priority"] = 100,
                ["runtimeBlockID"] = "projecthoomans:hostile_parley",
                ["textDomain"] = "pnc.convo.social.greetings.hostile.parley",
                ["textRows"] = {
                    {
                        ["fallback"] = "Ceasefire accepted for one hour.",
                        ["key"] = "result.accepted",
                    },
                    {
                        ["fallback"] = "Ceasefire refused.",
                        ["key"] = "result.rejected",
                    },
                },
                ["textTarget"] = "convo/social/greetings/hostile/parley",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "PARLEY",
                ["turns"] = {
                    {
                        ["fallback"] = "The survivor watches you carefully, ready to fight.",
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "REQUEST",
                                    ["speechAct"] = "REQUEST",
                                    ["subject"] = "CEASEFIRE",
                                    ["topic"] = "parley",
                                },
                                ["id"] = "ceasefire",
                                ["labelFallback"] = "Ceasefire. Stand down for now.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.ceasefire",
                                    ["close"] = true,
                                    ["effects"] = {
                                        {
                                            ["type"] = "pnc:ceasefire",
                                        },
                                    },
                                    ["responseKey"] = "response.ceasefire",
                                    ["responseTextFallback"] = "You ask for a short ceasefire.",
                                },
                                ["utteranceFallback"] = "Ceasefire. Stand down for now.",
                            },
                        },
                    },
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "PARLEY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.hostile.parley",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "REQUEST",
                                ["speechAct"] = "REQUEST",
                                ["subject"] = "CEASEFIRE",
                                ["topic"] = "parley",
                            },
                            ["id"] = "ceasefire",
                            ["labelFallback"] = "Ceasefire. Stand down for now.",
                            ["labelKey"] = "convo.social.greetings.hostile.parley.offer.ceasefire.label",
                            ["utteranceFallback"] = "Ceasefire. Stand down for now.",
                            ["utteranceKey"] = "convo.social.greetings.hostile.parley.offer.ceasefire.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "The survivor watches you carefully, ready to fight.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.hostile.parley.opening",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_hostile_parley.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.lover.dawn",
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
                                ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.lover.dawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.lover",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.lover.dawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.lover.dawn",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_lover_dawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.lover",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_dawn",
                ["textDomain"] = "pnc.convo.social.greetings.special.lover.dawn",
                ["textRows"] = {
                    {
                        ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Morning, love. Come here before the day starts.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "I missed you, and you were only asleep.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "First light looks better with you here.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Couldn't sleep without checking on everyone, could you?",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/special/lover/dawn",
                ["weight"] = 100,
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
                                ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.lover.dawn",
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
                            ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.lover.dawn.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_lover_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're awake already. I was hoping you'd sleep a little longer.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.lover.dawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Lover",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.lover.dusk",
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
                                ["fallback"] = "Stay with me a minute before night watch.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.lover.dusk.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.lover",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay with me a minute before night watch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.lover.dusk.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.lover.dusk",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_lover_dusk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.lover",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_dusk",
                ["textDomain"] = "pnc.convo.social.greetings.special.lover.dusk",
                ["textRows"] = {
                    {
                        ["fallback"] = "Stay with me a minute before night watch.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Evening, love. You look exhausted.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "You're safe. I can breathe again.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Come closer. We don't get many quiet moments.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "I saved you a place by me.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/special/lover/dusk",
                ["weight"] = 100,
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
                                ["fallback"] = "Stay with me a minute before night watch.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.lover.dusk",
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
                            ["fallback"] = "Stay with me a minute before night watch.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.lover.dusk.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_lover_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay with me a minute before night watch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.lover.dusk.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Lover",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.lover.sunrise",
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
                                ["fallback"] = "Morning, love. You sleep all right?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.lover.sunrise.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.lover",
            ["textRoles"] = {
                {
                    ["fallback"] = "Morning, love. You sleep all right?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.lover.sunrise.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.lover.sunrise",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_lover_sunrise.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.lover",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_sunrise",
                ["textDomain"] = "pnc.convo.social.greetings.special.lover.sunrise",
                ["textRows"] = {
                    {
                        ["fallback"] = "Morning, love. You sleep all right?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "There you are. I was starting to miss you.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Good morning. Stay close today, okay?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Seeing you first thing still makes this place feel almost normal.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Morning. Whatever happens today, we handle it together.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/special/lover/sunrise",
                ["weight"] = 100,
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
                                ["fallback"] = "Morning, love. You sleep all right?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.lover.sunrise",
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
                            ["fallback"] = "Morning, love. You sleep all right?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.lover.sunrise.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_lover_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Morning, love. You sleep all right?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.lover.sunrise.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Lover",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.lover.sunset",
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
                                ["fallback"] = "There you are. I worried when you were gone so long.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.lover.sunset.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.lover",
            ["textRoles"] = {
                {
                    ["fallback"] = "There you are. I worried when you were gone so long.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.lover.sunset.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.lover.sunset",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_lover_sunset.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.lover",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_sunset",
                ["textDomain"] = "pnc.convo.social.greetings.special.lover.sunset",
                ["textRows"] = {
                    {
                        ["fallback"] = "There you are. I worried when you were gone so long.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Come sit with me before the light goes.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Long day. I'm glad you're here at the end of it.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "You made it back. That's all I needed to see.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "The sunset almost makes this place look peaceful.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/special/lover/sunset",
                ["weight"] = 100,
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
                                ["fallback"] = "There you are. I worried when you were gone so long.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.lover.sunset",
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
                            ["fallback"] = "There you are. I worried when you were gone so long.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.lover.sunset.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_lover_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "There you are. I worried when you were gone so long.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.lover.sunset.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Lover",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.lover.twilight",
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
                                ["fallback"] = "Can't sleep? Neither can I.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.lover.twilight.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.lover",
            ["textRoles"] = {
                {
                    ["fallback"] = "Can't sleep? Neither can I.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.lover.twilight.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.lover.twilight",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_lover_twilight.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.lover",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_twilight",
                ["textDomain"] = "pnc.convo.social.greetings.special.lover.twilight",
                ["textRows"] = {
                    {
                        ["fallback"] = "Can't sleep? Neither can I.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "It's all right. I'm here.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Come sit with me. We can keep watch together.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "You scared me walking around this late.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Stay close tonight. I mean it.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/special/lover/twilight",
                ["weight"] = 100,
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
                                ["fallback"] = "Can't sleep? Neither can I.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.lover.twilight",
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
                            ["fallback"] = "Can't sleep? Neither can I.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.lover.twilight.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_lover_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Can't sleep? Neither can I.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.lover.twilight.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Lover",
                },
                {
                    ["any"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.member.dawn",
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
                                ["fallback"] = "You're up. Good—we have plenty to do.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.member.dawn.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.member",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're up. Good—we have plenty to do.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.dawn.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.member.dawn",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_member_dawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dawn",
                ["textDomain"] = "pnc.convo.social.greetings.member.dawn",
                ["textRows"] = {
                    {
                        ["fallback"] = "You're up. Good—we have plenty to do.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Morning. I already checked the perimeter.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Couldn't sleep either? We may as well get started.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "First light. What's the plan today?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Morning. Everyone else is still asleep, so it's just us.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/member/dawn",
                ["weight"] = 100,
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
                                ["fallback"] = "You're up. Good—we have plenty to do.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.member.dawn",
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
                            ["fallback"] = "You're up. Good—we have plenty to do.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.member.dawn.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_member_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're up. Good—we have plenty to do.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.member.dawn.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Member",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.member.dusk",
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
                                ["fallback"] = "Evening. Perimeter looks clear.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.member.dusk.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.member",
            ["textRoles"] = {
                {
                    ["fallback"] = "Evening. Perimeter looks clear.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.dusk.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.member.dusk",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_member_dusk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dusk",
                ["textDomain"] = "pnc.convo.social.greetings.member.dusk",
                ["textRows"] = {
                    {
                        ["fallback"] = "Evening. Perimeter looks clear.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Need me for something before night watch?",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "We're all still here. I'll call that a good day.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Keep it quiet. The others are settling down.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "I can take first watch if you need the rest.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/member/dusk",
                ["weight"] = 100,
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
                                ["fallback"] = "Evening. Perimeter looks clear.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.member.dusk",
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
                            ["fallback"] = "Evening. Perimeter looks clear.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.member.dusk.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_member_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Evening. Perimeter looks clear.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.member.dusk.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Member",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.member.sunrise",
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
                                ["fallback"] = "Morning. Ready when you are.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.member.sunrise.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.member",
            ["textRoles"] = {
                {
                    ["fallback"] = "Morning. Ready when you are.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.sunrise.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.member.sunrise",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_member_sunrise.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunrise",
                ["textDomain"] = "pnc.convo.social.greetings.member.sunrise",
                ["textRows"] = {
                    {
                        ["fallback"] = "Morning. Ready when you are.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Good, you're here. What are we doing today?",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Another day with the crew. Could be worse.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Morning. Supplies are holding for now.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "I was about to look for you. What's up?",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/member/sunrise",
                ["weight"] = 100,
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
                                ["fallback"] = "Morning. Ready when you are.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.member.sunrise",
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
                            ["fallback"] = "Morning. Ready when you are.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.member.sunrise.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_member_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Morning. Ready when you are.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.member.sunrise.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Member",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 6.5,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.member.sunset",
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
                                ["fallback"] = "We made it through the day. That's something.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.member.sunset.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.member",
            ["textRoles"] = {
                {
                    ["fallback"] = "We made it through the day. That's something.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.sunset.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.member.sunset",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_member_sunset.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunset",
                ["textDomain"] = "pnc.convo.social.greetings.member.sunset",
                ["textRows"] = {
                    {
                        ["fallback"] = "We made it through the day. That's something.",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Hey. Need a hand before we wrap up?",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "Long day, but I'm still ready if you need me.",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Everyone accounted for?",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "The light's fading. We should finish up soon.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/member/sunset",
                ["weight"] = 100,
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
                                ["fallback"] = "We made it through the day. That's something.",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.member.sunset",
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
                            ["fallback"] = "We made it through the day. That's something.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.member.sunset.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_member_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We made it through the day. That's something.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.member.sunset.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Member",
                },
                {
                    ["all"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 12,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 18,
                        },
                    },
                },
            },
        },
    },
    {
        ["domain"] = "social_greetings",
        ["domainPath"] = "social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "social.greetings.member.twilight",
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
                                ["fallback"] = "You're supposed to be resting. What's wrong?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.greetings.member.twilight.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 5,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.greetings.member",
            ["textRoles"] = {
                {
                    ["fallback"] = "You're supposed to be resting. What's wrong?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.twilight.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.member.twilight",
            ["sourcePath"] = "dialogue/social_greetings/social_greetings_member_twilight.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings",
        ["namespace"] = "social.greetings.member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_member_twilight",
                ["textDomain"] = "pnc.convo.social.greetings.member.twilight",
                ["textRows"] = {
                    {
                        ["fallback"] = "You're supposed to be resting. What's wrong?",
                        ["key"] = "greeting.001",
                    },
                    {
                        ["fallback"] = "Quiet night so far. Let's keep it that way.",
                        ["key"] = "greeting.002",
                    },
                    {
                        ["fallback"] = "I'm on watch. Did you need something?",
                        ["key"] = "greeting.003",
                    },
                    {
                        ["fallback"] = "Good, it's you. I heard footsteps.",
                        ["key"] = "greeting.004",
                    },
                    {
                        ["fallback"] = "Can't sleep? Pull up a chair, but keep your voice low.",
                        ["key"] = "greeting.005",
                    },
                },
                ["textTarget"] = "convo/social/greetings/member/twilight",
                ["weight"] = 100,
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
                                ["fallback"] = "You're supposed to be resting. What's wrong?",
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
                    ["id"] = "greeting",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "GREETING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.greetings.member.twilight",
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
                            ["fallback"] = "You're supposed to be resting. What's wrong?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.greetings.member.twilight.say_1",
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
        ["sourceShard"] = "dialogue/social_greetings/social_greetings_member_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You're supposed to be resting. What's wrong?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.greetings.member.twilight.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "relationship.speakerToAddressee.state",
                    ["value"] = "Member",
                },
                {
                    ["any"] = {
                        {
                            ["op"] = "gte",
                            ["path"] = "world.time.hour",
                            ["value"] = 21,
                        },
                        {
                            ["op"] = "lt",
                            ["path"] = "world.time.hour",
                            ["value"] = 5,
                        },
                    },
                },
            },
        },
    },
}
