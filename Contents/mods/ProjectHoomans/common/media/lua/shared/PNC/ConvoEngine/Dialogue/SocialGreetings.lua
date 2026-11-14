-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You're awake early too. Everything all right?",
                                        "Morning. I didn't expect to see you before sunrise.",
                                        "Couldn't sleep? Neither could I.",
                                        "Good, it's you. What brings you over this early?",
                                        "Dawn patrol, or did you need something?",
                                    },
                                    ["TL"] = {
                                        "Gising ka rin nang maaga. Ayos ba ang lahat?",
                                        "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                                        "hindi makatulog? Hindi ko rin kaya.",
                                        "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                                        "Dawn patrol, o may kailangan ka?",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You're awake early too. Everything all right?",
                            "Morning. I didn't expect to see you before sunrise.",
                            "Couldn't sleep? Neither could I.",
                            "Good, it's you. What brings you over this early?",
                            "Dawn patrol, or did you need something?",
                        },
                        ["TL"] = {
                            "Gising ka rin nang maaga. Ayos ba ang lahat?",
                            "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                            "hindi makatulog? Hindi ko rin kaya.",
                            "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                            "Dawn patrol, o may kailangan ka?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.acquaintance.dawn",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dawn.json",
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
            ["metadata"] = {
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:greetings",
                ["portraitAnimation"] = "greeting.wavehi",
                ["priority"] = 10,
                ["responseAct"] = "GREETING",
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_dawn",
                ["textDomain"] = "pnc.convo.social.greetings.neutral.acquaintance.dawn",
                ["textRows"] = {
                    {
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "You're awake early too. Everything all right?",
                            ["TL"] = "Gising ka rin nang maaga. Ayos ba ang lahat?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Morning. I didn't expect to see you before sunrise.",
                            ["TL"] = "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Couldn't sleep? Neither could I.",
                            ["TL"] = "hindi makatulog? Hindi ko rin kaya.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Good, it's you. What brings you over this early?",
                            ["TL"] = "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Dawn patrol, or did you need something?",
                            ["TL"] = "Dawn patrol, o may kailangan ka?",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You're awake early too. Everything all right?",
                                        "Morning. I didn't expect to see you before sunrise.",
                                        "Couldn't sleep? Neither could I.",
                                        "Good, it's you. What brings you over this early?",
                                        "Dawn patrol, or did you need something?",
                                    },
                                    ["TL"] = {
                                        "Gising ka rin nang maaga. Ayos ba ang lahat?",
                                        "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                                        "hindi makatulog? Hindi ko rin kaya.",
                                        "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                                        "Dawn patrol, o may kailangan ka?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dawn.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "You're awake early too. Everything all right?",
                        "Morning. I didn't expect to see you before sunrise.",
                        "Couldn't sleep? Neither could I.",
                        "Good, it's you. What brings you over this early?",
                        "Dawn patrol, or did you need something?",
                    },
                    ["TL"] = {
                        "Gising ka rin nang maaga. Ayos ba ang lahat?",
                        "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                        "hindi makatulog? Hindi ko rin kaya.",
                        "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                        "Dawn patrol, o may kailangan ka?",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Evening. Need something before we turn in?",
                                        "Good, it's only you. You startled me.",
                                        "Not much daylight left. Talk to me.",
                                        "Hey. Keeping watch, or just passing by?",
                                        "We should keep this quiet, but I'm listening.",
                                    },
                                    ["TL"] = {
                                        "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                                        "Buti, ikaw lang. Ginulat mo ako.",
                                        "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                                        "Hey. Nagmamasid, o dumadaan lang?",
                                        "Dapat tahimik lang tayo rito, pero nakikinig ako.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Evening. Need something before we turn in?",
                            "Good, it's only you. You startled me.",
                            "Not much daylight left. Talk to me.",
                            "Hey. Keeping watch, or just passing by?",
                            "We should keep this quiet, but I'm listening.",
                        },
                        ["TL"] = {
                            "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                            "Buti, ikaw lang. Ginulat mo ako.",
                            "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                            "Hey. Nagmamasid, o dumadaan lang?",
                            "Dapat tahimik lang tayo rito, pero nakikinig ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.acquaintance.dusk",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dusk.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Evening. Need something before we turn in?",
                            ["TL"] = "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Good, it's only you. You startled me.",
                            ["TL"] = "Buti, ikaw lang. Ginulat mo ako.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Not much daylight left. Talk to me.",
                            ["TL"] = "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Hey. Keeping watch, or just passing by?",
                            ["TL"] = "Hey. Nagmamasid, o dumadaan lang?",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "We should keep this quiet, but I'm listening.",
                            ["TL"] = "Dapat tahimik lang tayo rito, pero nakikinig ako.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Evening. Need something before we turn in?",
                                        "Good, it's only you. You startled me.",
                                        "Not much daylight left. Talk to me.",
                                        "Hey. Keeping watch, or just passing by?",
                                        "We should keep this quiet, but I'm listening.",
                                    },
                                    ["TL"] = {
                                        "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                                        "Buti, ikaw lang. Ginulat mo ako.",
                                        "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                                        "Hey. Nagmamasid, o dumadaan lang?",
                                        "Dapat tahimik lang tayo rito, pero nakikinig ako.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dusk.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Evening. Need something before we turn in?",
                        "Good, it's only you. You startled me.",
                        "Not much daylight left. Talk to me.",
                        "Hey. Keeping watch, or just passing by?",
                        "We should keep this quiet, but I'm listening.",
                    },
                    ["TL"] = {
                        "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                        "Buti, ikaw lang. Ginulat mo ako.",
                        "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                        "Hey. Nagmamasid, o dumadaan lang?",
                        "Dapat tahimik lang tayo rito, pero nakikinig ako.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Morning. Good to see a familiar face.",
                                        "Hey. How's the day treating you?",
                                        "There you are. Need a minute?",
                                        "Morning. You look like you have something on your mind.",
                                        "Nice to see you made it through another night.",
                                    },
                                    ["TL"] = {
                                        "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                                        "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                                        "Narito ka pala. Kailangan mo ba ng sandali?",
                                        "Umaga. Parang may iniisip ka.",
                                        "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Morning. Good to see a familiar face.",
                            "Hey. How's the day treating you?",
                            "There you are. Need a minute?",
                            "Morning. You look like you have something on your mind.",
                            "Nice to see you made it through another night.",
                        },
                        ["TL"] = {
                            "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                            "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                            "Narito ka pala. Kailangan mo ba ng sandali?",
                            "Umaga. Parang may iniisip ka.",
                            "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.acquaintance.sunrise",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunrise.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Morning. Good to see a familiar face.",
                            ["TL"] = "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Hey. How's the day treating you?",
                            ["TL"] = "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "There you are. Need a minute?",
                            ["TL"] = "Narito ka pala. Kailangan mo ba ng sandali?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Morning. You look like you have something on your mind.",
                            ["TL"] = "Umaga. Parang may iniisip ka.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Nice to see you made it through another night.",
                            ["TL"] = "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Morning. Good to see a familiar face.",
                                        "Hey. How's the day treating you?",
                                        "There you are. Need a minute?",
                                        "Morning. You look like you have something on your mind.",
                                        "Nice to see you made it through another night.",
                                    },
                                    ["TL"] = {
                                        "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                                        "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                                        "Narito ka pala. Kailangan mo ba ng sandali?",
                                        "Umaga. Parang may iniisip ka.",
                                        "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunrise.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Morning. Good to see a familiar face.",
                        "Hey. How's the day treating you?",
                        "There you are. Need a minute?",
                        "Morning. You look like you have something on your mind.",
                        "Nice to see you made it through another night.",
                    },
                    ["TL"] = {
                        "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                        "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                        "Narito ka pala. Kailangan mo ba ng sandali?",
                        "Umaga. Parang may iniisip ka.",
                        "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hey. Been a long day?",
                                        "Good timing. I was about to settle in.",
                                        "There you are. Find anything useful today?",
                                        "The day's winding down. What's up?",
                                        "You look tired. Everything okay?",
                                    },
                                    ["TL"] = {
                                        "Hey. Isang mahabang araw?",
                                        "Magandang timing. Malapit na akong tumira.",
                                        "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                                        "Palubog na ang araw. Anong meron?",
                                        "Mukha kang pagod. Ayos ka lang ba?",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Hey. Been a long day?",
                            "Good timing. I was about to settle in.",
                            "There you are. Find anything useful today?",
                            "The day's winding down. What's up?",
                            "You look tired. Everything okay?",
                        },
                        ["TL"] = {
                            "Hey. Isang mahabang araw?",
                            "Magandang timing. Malapit na akong tumira.",
                            "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                            "Palubog na ang araw. Anong meron?",
                            "Mukha kang pagod. Ayos ka lang ba?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.acquaintance.sunset",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunset.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Hey. Been a long day?",
                            ["TL"] = "Hey. Isang mahabang araw?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Good timing. I was about to settle in.",
                            ["TL"] = "Magandang timing. Malapit na akong tumira.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "There you are. Find anything useful today?",
                            ["TL"] = "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "The day's winding down. What's up?",
                            ["TL"] = "Palubog na ang araw. Anong meron?",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "You look tired. Everything okay?",
                            ["TL"] = "Mukha kang pagod. Ayos ka lang ba?",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Hey. Been a long day?",
                                        "Good timing. I was about to settle in.",
                                        "There you are. Find anything useful today?",
                                        "The day's winding down. What's up?",
                                        "You look tired. Everything okay?",
                                    },
                                    ["TL"] = {
                                        "Hey. Isang mahabang araw?",
                                        "Magandang timing. Malapit na akong tumira.",
                                        "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                                        "Palubog na ang araw. Anong meron?",
                                        "Mukha kang pagod. Ayos ka lang ba?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunset.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Hey. Been a long day?",
                        "Good timing. I was about to settle in.",
                        "There you are. Find anything useful today?",
                        "The day's winding down. What's up?",
                        "You look tired. Everything okay?",
                    },
                    ["TL"] = {
                        "Hey. Isang mahabang araw?",
                        "Magandang timing. Malapit na akong tumira.",
                        "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                        "Palubog na ang araw. Anong meron?",
                        "Mukha kang pagod. Ayos ka lang ba?",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Late night. What has you awake?",
                                        "It's good to see someone I recognize out here.",
                                        "Keep it down. Sound carries at night.",
                                        "You all right? It's late to be wandering.",
                                        "Hey. Make it quick before we draw attention.",
                                    },
                                    ["TL"] = {
                                        "Gabi na. Anong gising mo?",
                                        "Nakakatuwang makita ang isang taong kilala ko dito.",
                                        "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                                        "Ayos ka lang ba? Gabi na para magpagala-gala.",
                                        "Hey. Bilisan mo bago tayo makatawag ng pansin.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Late night. What has you awake?",
                            "It's good to see someone I recognize out here.",
                            "Keep it down. Sound carries at night.",
                            "You all right? It's late to be wandering.",
                            "Hey. Make it quick before we draw attention.",
                        },
                        ["TL"] = {
                            "Gabi na. Anong gising mo?",
                            "Nakakatuwang makita ang isang taong kilala ko dito.",
                            "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                            "Ayos ka lang ba? Gabi na para magpagala-gala.",
                            "Hey. Bilisan mo bago tayo makatawag ng pansin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.acquaintance.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.acquaintance.twilight",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_twilight.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Late night. What has you awake?",
                            ["TL"] = "Gabi na. Anong gising mo?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "It's good to see someone I recognize out here.",
                            ["TL"] = "Nakakatuwang makita ang isang taong kilala ko dito.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Keep it down. Sound carries at night.",
                            ["TL"] = "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "You all right? It's late to be wandering.",
                            ["TL"] = "Ayos ka lang ba? Gabi na para magpagala-gala.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Hey. Make it quick before we draw attention.",
                            ["TL"] = "Hey. Bilisan mo bago tayo makatawag ng pansin.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Late night. What has you awake?",
                                        "It's good to see someone I recognize out here.",
                                        "Keep it down. Sound carries at night.",
                                        "You all right? It's late to be wandering.",
                                        "Hey. Make it quick before we draw attention.",
                                    },
                                    ["TL"] = {
                                        "Gabi na. Anong gising mo?",
                                        "Nakakatuwang makita ang isang taong kilala ko dito.",
                                        "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                                        "Ayos ka lang ba? Gabi na para magpagala-gala.",
                                        "Hey. Bilisan mo bago tayo makatawag ng pansin.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_twilight.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Late night. What has you awake?",
                        "It's good to see someone I recognize out here.",
                        "Keep it down. Sound carries at night.",
                        "You all right? It's late to be wandering.",
                        "Hey. Make it quick before we draw attention.",
                    },
                    ["TL"] = {
                        "Gabi na. Anong gising mo?",
                        "Nakakatuwang makita ang isang taong kilala ko dito.",
                        "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                        "Ayos ka lang ba? Gabi na para magpagala-gala.",
                        "Hey. Bilisan mo bago tayo makatawag ng pansin.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Hold there. I don't know you, and dawn is a strange time for introductions.",
                                        "You're up before the dead settle down. Who are you?",
                                        "Easy. The light is barely up, and I wasn't expecting company.",
                                        "Morning, I suppose. Keep your hands where I can see them.",
                                        "First light and a new face. Tell me what you need.",
                                    },
                                    ["TL"] = {
                                        "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                                        "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                                        "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                                        "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                                        "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Hold there. I don't know you, and dawn is a strange time for introductions.",
                            "You're up before the dead settle down. Who are you?",
                            "Easy. The light is barely up, and I wasn't expecting company.",
                            "Morning, I suppose. Keep your hands where I can see them.",
                            "First light and a new face. Tell me what you need.",
                        },
                        ["TL"] = {
                            "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                            "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                            "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                            "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                            "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.firstmeet.dawn",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dawn.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Hold there. I don't know you, and dawn is a strange time for introductions.",
                            ["TL"] = "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "You're up before the dead settle down. Who are you?",
                            ["TL"] = "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Easy. The light is barely up, and I wasn't expecting company.",
                            ["TL"] = "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Morning, I suppose. Keep your hands where I can see them.",
                            ["TL"] = "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "First light and a new face. Tell me what you need.",
                            ["TL"] = "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Hold there. I don't know you, and dawn is a strange time for introductions.",
                                        "You're up before the dead settle down. Who are you?",
                                        "Easy. The light is barely up, and I wasn't expecting company.",
                                        "Morning, I suppose. Keep your hands where I can see them.",
                                        "First light and a new face. Tell me what you need.",
                                    },
                                    ["TL"] = {
                                        "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                                        "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                                        "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                                        "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                                        "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dawn.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Hold there. I don't know you, and dawn is a strange time for introductions.",
                        "You're up before the dead settle down. Who are you?",
                        "Easy. The light is barely up, and I wasn't expecting company.",
                        "Morning, I suppose. Keep your hands where I can see them.",
                        "First light and a new face. Tell me what you need.",
                    },
                    ["TL"] = {
                        "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                        "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                        "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                        "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                        "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stop there. Dusk makes strangers hard to read.",
                                        "Not much light left. Introduce yourself.",
                                        "You surprised me. What do you want?",
                                        "Keep your voice down and tell me why you're here.",
                                        "I can't make out your face. Come no closer.",
                                    },
                                    ["TL"] = {
                                        "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                                        "Wala nang gaanong ilaw. Magpakilala ka.",
                                        "Nagulat mo ako. Ano ang kailangan mo?",
                                        "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                                        "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Stop there. Dusk makes strangers hard to read.",
                            "Not much light left. Introduce yourself.",
                            "You surprised me. What do you want?",
                            "Keep your voice down and tell me why you're here.",
                            "I can't make out your face. Come no closer.",
                        },
                        ["TL"] = {
                            "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                            "Wala nang gaanong ilaw. Magpakilala ka.",
                            "Nagulat mo ako. Ano ang kailangan mo?",
                            "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                            "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.firstmeet.dusk",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dusk.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Stop there. Dusk makes strangers hard to read.",
                            ["TL"] = "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Not much light left. Introduce yourself.",
                            ["TL"] = "Wala nang gaanong ilaw. Magpakilala ka.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "You surprised me. What do you want?",
                            ["TL"] = "Nagulat mo ako. Ano ang kailangan mo?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Keep your voice down and tell me why you're here.",
                            ["TL"] = "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "I can't make out your face. Come no closer.",
                            ["TL"] = "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Stop there. Dusk makes strangers hard to read.",
                                        "Not much light left. Introduce yourself.",
                                        "You surprised me. What do you want?",
                                        "Keep your voice down and tell me why you're here.",
                                        "I can't make out your face. Come no closer.",
                                    },
                                    ["TL"] = {
                                        "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                                        "Wala nang gaanong ilaw. Magpakilala ka.",
                                        "Nagulat mo ako. Ano ang kailangan mo?",
                                        "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                                        "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dusk.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Stop there. Dusk makes strangers hard to read.",
                        "Not much light left. Introduce yourself.",
                        "You surprised me. What do you want?",
                        "Keep your voice down and tell me why you're here.",
                        "I can't make out your face. Come no closer.",
                    },
                    ["TL"] = {
                        "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                        "Wala nang gaanong ilaw. Magpakilala ka.",
                        "Nagulat mo ako. Ano ang kailangan mo?",
                        "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                        "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Morning. I haven't seen you around before.",
                                        "That's close enough. Start with your name.",
                                        "New face. Are you passing through or looking for something?",
                                        "Daylight makes this easier. Who are you?",
                                        "I don't recognize you. Talk, and keep it calm.",
                                    },
                                    ["TL"] = {
                                        "Umaga. Hindi pa kita nakikita kanina.",
                                        "Malapit na yun. Magsimula sa iyong pangalan.",
                                        "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                                        "Pinapadali ito ng liwanag ng araw. sino ka ba",
                                        "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Morning. I haven't seen you around before.",
                            "That's close enough. Start with your name.",
                            "New face. Are you passing through or looking for something?",
                            "Daylight makes this easier. Who are you?",
                            "I don't recognize you. Talk, and keep it calm.",
                        },
                        ["TL"] = {
                            "Umaga. Hindi pa kita nakikita kanina.",
                            "Malapit na yun. Magsimula sa iyong pangalan.",
                            "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                            "Pinapadali ito ng liwanag ng araw. sino ka ba",
                            "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.firstmeet.sunrise",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunrise.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Morning. I haven't seen you around before.",
                            ["TL"] = "Umaga. Hindi pa kita nakikita kanina.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "That's close enough. Start with your name.",
                            ["TL"] = "Malapit na yun. Magsimula sa iyong pangalan.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "New face. Are you passing through or looking for something?",
                            ["TL"] = "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Daylight makes this easier. Who are you?",
                            ["TL"] = "Pinapadali ito ng liwanag ng araw. sino ka ba",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "I don't recognize you. Talk, and keep it calm.",
                            ["TL"] = "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Morning. I haven't seen you around before.",
                                        "That's close enough. Start with your name.",
                                        "New face. Are you passing through or looking for something?",
                                        "Daylight makes this easier. Who are you?",
                                        "I don't recognize you. Talk, and keep it calm.",
                                    },
                                    ["TL"] = {
                                        "Umaga. Hindi pa kita nakikita kanina.",
                                        "Malapit na yun. Magsimula sa iyong pangalan.",
                                        "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                                        "Pinapadali ito ng liwanag ng araw. sino ka ba",
                                        "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunrise.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Morning. I haven't seen you around before.",
                        "That's close enough. Start with your name.",
                        "New face. Are you passing through or looking for something?",
                        "Daylight makes this easier. Who are you?",
                        "I don't recognize you. Talk, and keep it calm.",
                    },
                    ["TL"] = {
                        "Umaga. Hindi pa kita nakikita kanina.",
                        "Malapit na yun. Magsimula sa iyong pangalan.",
                        "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                        "Pinapadali ito ng liwanag ng araw. sino ka ba",
                        "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You picked a late hour to approach a stranger.",
                                        "The light is going. Say what you came to say.",
                                        "I don't know you, but I'm listening.",
                                        "Before it gets dark, tell me who you are.",
                                        "Another survivor. Friendly, I hope?",
                                    },
                                    ["TL"] = {
                                        "Huli na para lumapit sa isang estranghero.",
                                        "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                                        "Hindi kita kilala, pero nakikinig ako.",
                                        "Bago dumilim, sabihin mo sa akin kung sino ka.",
                                        "Isa pang nakaligtas. Friendly, sana?",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You picked a late hour to approach a stranger.",
                            "The light is going. Say what you came to say.",
                            "I don't know you, but I'm listening.",
                            "Before it gets dark, tell me who you are.",
                            "Another survivor. Friendly, I hope?",
                        },
                        ["TL"] = {
                            "Huli na para lumapit sa isang estranghero.",
                            "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                            "Hindi kita kilala, pero nakikinig ako.",
                            "Bago dumilim, sabihin mo sa akin kung sino ka.",
                            "Isa pang nakaligtas. Friendly, sana?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.firstmeet.sunset",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunset.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "You picked a late hour to approach a stranger.",
                            ["TL"] = "Huli na para lumapit sa isang estranghero.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "The light is going. Say what you came to say.",
                            ["TL"] = "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "I don't know you, but I'm listening.",
                            ["TL"] = "Hindi kita kilala, pero nakikinig ako.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Before it gets dark, tell me who you are.",
                            ["TL"] = "Bago dumilim, sabihin mo sa akin kung sino ka.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Another survivor. Friendly, I hope?",
                            ["TL"] = "Isa pang nakaligtas. Friendly, sana?",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You picked a late hour to approach a stranger.",
                                        "The light is going. Say what you came to say.",
                                        "I don't know you, but I'm listening.",
                                        "Before it gets dark, tell me who you are.",
                                        "Another survivor. Friendly, I hope?",
                                    },
                                    ["TL"] = {
                                        "Huli na para lumapit sa isang estranghero.",
                                        "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                                        "Hindi kita kilala, pero nakikinig ako.",
                                        "Bago dumilim, sabihin mo sa akin kung sino ka.",
                                        "Isa pang nakaligtas. Friendly, sana?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunset.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "You picked a late hour to approach a stranger.",
                        "The light is going. Say what you came to say.",
                        "I don't know you, but I'm listening.",
                        "Before it gets dark, tell me who you are.",
                        "Another survivor. Friendly, I hope?",
                    },
                    ["TL"] = {
                        "Huli na para lumapit sa isang estranghero.",
                        "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                        "Hindi kita kilala, pero nakikinig ako.",
                        "Bago dumilim, sabihin mo sa akin kung sino ka.",
                        "Isa pang nakaligtas. Friendly, sana?",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "It's dark out. Stay where I can see you.",
                                        "A stranger walking up at night usually means trouble.",
                                        "Keep your voice low. Who are you?",
                                        "You chose a bad time to sneak up on someone.",
                                        "Don't move any closer. We can talk from there.",
                                    },
                                    ["TL"] = {
                                        "Madilim sa labas. Manatili ka kung saan kita makikita.",
                                        "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                                        "Panatilihing mahina ang iyong boses. sino ka ba",
                                        "You chose a bad time to sneak up buhay someone.",
                                        "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "It's dark out. Stay where I can see you.",
                            "A stranger walking up at night usually means trouble.",
                            "Keep your voice low. Who are you?",
                            "You chose a bad time to sneak up on someone.",
                            "Don't move any closer. We can talk from there.",
                        },
                        ["TL"] = {
                            "Madilim sa labas. Manatili ka kung saan kita makikita.",
                            "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                            "Panatilihing mahina ang iyong boses. sino ka ba",
                            "You chose a bad time to sneak up buhay someone.",
                            "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.firstmeet.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.firstmeet.twilight",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_twilight.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "It's dark out. Stay where I can see you.",
                            ["TL"] = "Madilim sa labas. Manatili ka kung saan kita makikita.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "A stranger walking up at night usually means trouble.",
                            ["TL"] = "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Keep your voice low. Who are you?",
                            ["TL"] = "Panatilihing mahina ang iyong boses. sino ka ba",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "You chose a bad time to sneak up on someone.",
                            ["TL"] = "You chose a bad time to sneak up buhay someone.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Don't move any closer. We can talk from there.",
                            ["TL"] = "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "It's dark out. Stay where I can see you.",
                                        "A stranger walking up at night usually means trouble.",
                                        "Keep your voice low. Who are you?",
                                        "You chose a bad time to sneak up on someone.",
                                        "Don't move any closer. We can talk from there.",
                                    },
                                    ["TL"] = {
                                        "Madilim sa labas. Manatili ka kung saan kita makikita.",
                                        "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                                        "Panatilihing mahina ang iyong boses. sino ka ba",
                                        "You chose a bad time to sneak up buhay someone.",
                                        "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_twilight.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "It's dark out. Stay where I can see you.",
                        "A stranger walking up at night usually means trouble.",
                        "Keep your voice low. Who are you?",
                        "You chose a bad time to sneak up on someone.",
                        "Don't move any closer. We can talk from there.",
                    },
                    ["TL"] = {
                        "Madilim sa labas. Manatili ka kung saan kita makikita.",
                        "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                        "Panatilihing mahina ang iyong boses. sino ka ba",
                        "You chose a bad time to sneak up buhay someone.",
                        "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
                    },
                },
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
        ["id"] = "social.greetings.hostile.parley",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "parley",
            ["sourceId"] = "social.greetings.hostile.parley",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_hostile_parley.json",
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
            ["metadata"] = {
                ["audience"] = "hostile",
                ["category"] = "projecthoomans:greetings",
                ["priority"] = 100,
                ["runtimeBlockID"] = "projecthoomans:hostile_parley",
                ["textDomain"] = "pnc.convo.social.greetings.hostile.parley",
                ["textRows"] = {
                    {
                        ["key"] = "result.accepted",
                        ["text"] = {
                            ["EN"] = "Ceasefire accepted for one hour.",
                            ["TL"] = "Tinanggap ang tigil-putukan sa loob ng isang oras.",
                        },
                    },
                    {
                        ["key"] = "result.rejected",
                        ["text"] = {
                            ["EN"] = "Ceasefire refused.",
                            ["TL"] = "Tumanggi ang tigil-putukan.",
                        },
                    },
                },
                ["textTarget"] = "convo/social/greetings/hostile/parley",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "PARLEY",
                ["turns"] = {
                    {
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
                                ["label"] = {
                                    ["EN"] = {
                                        "Ceasefire. Stand down for now.",
                                    },
                                    ["TL"] = {
                                        "Ceasefire. Tumayo sa ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.ceasefire",
                                    ["close"] = true,
                                    ["effects"] = {
                                        {
                                            ["type"] = "pnc:ceasefire",
                                        },
                                    },
                                    ["responseKey"] = "response.ceasefire",
                                    ["responseText"] = {
                                        ["EN"] = "You ask for a short ceasefire.",
                                        ["TL"] = "Humihingi ka ng maikling tigil-putukan.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Ceasefire. Stand down for now.",
                                    },
                                    ["TL"] = {
                                        "Ceasefire. Tumayo sa ngayon.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The survivor watches you carefully, ready to fight.",
                            },
                            ["TL"] = {
                                "Maingat kang pinagmamasdan ng survivor, handang lumaban.",
                            },
                        },
                    },
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_hostile_parley.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_greetings",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You're awake already. I was hoping you'd sleep a little longer.",
                                        "Morning, love. Come here before the day starts.",
                                        "I missed you, and you were only asleep.",
                                        "First light looks better with you here.",
                                        "Couldn't sleep without checking on everyone, could you?",
                                    },
                                    ["TL"] = {
                                        "You're awake already. I was hoping you'd tulog a little longer.",
                                        "Umaga, mahal. Halika dito bago magsimula ang araw.",
                                        "Namiss kita, tulog ka lang.",
                                        "Mas maganda ang unang liwanag kapag kasama ka rito.",
                                        "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You're awake already. I was hoping you'd sleep a little longer.",
                            "Morning, love. Come here before the day starts.",
                            "I missed you, and you were only asleep.",
                            "First light looks better with you here.",
                            "Couldn't sleep without checking on everyone, could you?",
                        },
                        ["TL"] = {
                            "You're awake already. I was hoping you'd tulog a little longer.",
                            "Umaga, mahal. Halika dito bago magsimula ang araw.",
                            "Namiss kita, tulog ka lang.",
                            "Mas maganda ang unang liwanag kapag kasama ka rito.",
                            "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.lover.dawn",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dawn.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "You're awake already. I was hoping you'd sleep a little longer.",
                            ["TL"] = "You're awake already. I was hoping you'd tulog a little longer.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Morning, love. Come here before the day starts.",
                            ["TL"] = "Umaga, mahal. Halika dito bago magsimula ang araw.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "I missed you, and you were only asleep.",
                            ["TL"] = "Namiss kita, tulog ka lang.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "First light looks better with you here.",
                            ["TL"] = "Mas maganda ang unang liwanag kapag kasama ka rito.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Couldn't sleep without checking on everyone, could you?",
                            ["TL"] = "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You're awake already. I was hoping you'd sleep a little longer.",
                                        "Morning, love. Come here before the day starts.",
                                        "I missed you, and you were only asleep.",
                                        "First light looks better with you here.",
                                        "Couldn't sleep without checking on everyone, could you?",
                                    },
                                    ["TL"] = {
                                        "You're awake already. I was hoping you'd tulog a little longer.",
                                        "Umaga, mahal. Halika dito bago magsimula ang araw.",
                                        "Namiss kita, tulog ka lang.",
                                        "Mas maganda ang unang liwanag kapag kasama ka rito.",
                                        "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dawn.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "You're awake already. I was hoping you'd sleep a little longer.",
                        "Morning, love. Come here before the day starts.",
                        "I missed you, and you were only asleep.",
                        "First light looks better with you here.",
                        "Couldn't sleep without checking on everyone, could you?",
                    },
                    ["TL"] = {
                        "You're awake already. I was hoping you'd tulog a little longer.",
                        "Umaga, mahal. Halika dito bago magsimula ang araw.",
                        "Namiss kita, tulog ka lang.",
                        "Mas maganda ang unang liwanag kapag kasama ka rito.",
                        "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stay with me a minute before night watch.",
                                        "Evening, love. You look exhausted.",
                                        "You're safe. I can breathe again.",
                                        "Come closer. We don't get many quiet moments.",
                                        "I saved you a place by me.",
                                    },
                                    ["TL"] = {
                                        "Manatili sa akin ng isang minuto bago manood ng gabi.",
                                        "Gabi, mahal. Mukha kang pagod.",
                                        "Ligtas ka. Muli na akong makahihinga.",
                                        "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                                        "Iniligtas kita ng isang lugar sa tabi ko.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Stay with me a minute before night watch.",
                            "Evening, love. You look exhausted.",
                            "You're safe. I can breathe again.",
                            "Come closer. We don't get many quiet moments.",
                            "I saved you a place by me.",
                        },
                        ["TL"] = {
                            "Manatili sa akin ng isang minuto bago manood ng gabi.",
                            "Gabi, mahal. Mukha kang pagod.",
                            "Ligtas ka. Muli na akong makahihinga.",
                            "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                            "Iniligtas kita ng isang lugar sa tabi ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.lover.dusk",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dusk.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Stay with me a minute before night watch.",
                            ["TL"] = "Manatili sa akin ng isang minuto bago manood ng gabi.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Evening, love. You look exhausted.",
                            ["TL"] = "Gabi, mahal. Mukha kang pagod.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "You're safe. I can breathe again.",
                            ["TL"] = "Ligtas ka. Muli na akong makahihinga.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Come closer. We don't get many quiet moments.",
                            ["TL"] = "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "I saved you a place by me.",
                            ["TL"] = "Iniligtas kita ng isang lugar sa tabi ko.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Stay with me a minute before night watch.",
                                        "Evening, love. You look exhausted.",
                                        "You're safe. I can breathe again.",
                                        "Come closer. We don't get many quiet moments.",
                                        "I saved you a place by me.",
                                    },
                                    ["TL"] = {
                                        "Manatili sa akin ng isang minuto bago manood ng gabi.",
                                        "Gabi, mahal. Mukha kang pagod.",
                                        "Ligtas ka. Muli na akong makahihinga.",
                                        "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                                        "Iniligtas kita ng isang lugar sa tabi ko.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dusk.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Stay with me a minute before night watch.",
                        "Evening, love. You look exhausted.",
                        "You're safe. I can breathe again.",
                        "Come closer. We don't get many quiet moments.",
                        "I saved you a place by me.",
                    },
                    ["TL"] = {
                        "Manatili sa akin ng isang minuto bago manood ng gabi.",
                        "Gabi, mahal. Mukha kang pagod.",
                        "Ligtas ka. Muli na akong makahihinga.",
                        "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                        "Iniligtas kita ng isang lugar sa tabi ko.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Morning, love. You sleep all right?",
                                        "There you are. I was starting to miss you.",
                                        "Good morning. Stay close today, okay?",
                                        "Seeing you first thing still makes this place feel almost normal.",
                                        "Morning. Whatever happens today, we handle it together.",
                                    },
                                    ["TL"] = {
                                        "Umaga, mahal. Matulog ka na okay?",
                                        "Narito ka pala. Nagsisimula na kitang ma-miss.",
                                        "Magandang umaga po. Manatiling malapit ngayon, okay?",
                                        "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                                        "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Morning, love. You sleep all right?",
                            "There you are. I was starting to miss you.",
                            "Good morning. Stay close today, okay?",
                            "Seeing you first thing still makes this place feel almost normal.",
                            "Morning. Whatever happens today, we handle it together.",
                        },
                        ["TL"] = {
                            "Umaga, mahal. Matulog ka na okay?",
                            "Narito ka pala. Nagsisimula na kitang ma-miss.",
                            "Magandang umaga po. Manatiling malapit ngayon, okay?",
                            "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                            "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.lover.sunrise",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunrise.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Morning, love. You sleep all right?",
                            ["TL"] = "Umaga, mahal. Matulog ka na okay?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "There you are. I was starting to miss you.",
                            ["TL"] = "Narito ka pala. Nagsisimula na kitang ma-miss.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Good morning. Stay close today, okay?",
                            ["TL"] = "Magandang umaga po. Manatiling malapit ngayon, okay?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Seeing you first thing still makes this place feel almost normal.",
                            ["TL"] = "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Morning. Whatever happens today, we handle it together.",
                            ["TL"] = "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Morning, love. You sleep all right?",
                                        "There you are. I was starting to miss you.",
                                        "Good morning. Stay close today, okay?",
                                        "Seeing you first thing still makes this place feel almost normal.",
                                        "Morning. Whatever happens today, we handle it together.",
                                    },
                                    ["TL"] = {
                                        "Umaga, mahal. Matulog ka na okay?",
                                        "Narito ka pala. Nagsisimula na kitang ma-miss.",
                                        "Magandang umaga po. Manatiling malapit ngayon, okay?",
                                        "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                                        "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunrise.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Morning, love. You sleep all right?",
                        "There you are. I was starting to miss you.",
                        "Good morning. Stay close today, okay?",
                        "Seeing you first thing still makes this place feel almost normal.",
                        "Morning. Whatever happens today, we handle it together.",
                    },
                    ["TL"] = {
                        "Umaga, mahal. Matulog ka na okay?",
                        "Narito ka pala. Nagsisimula na kitang ma-miss.",
                        "Magandang umaga po. Manatiling malapit ngayon, okay?",
                        "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                        "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "There you are. I worried when you were gone so long.",
                                        "Come sit with me before the light goes.",
                                        "Long day. I'm glad you're here at the end of it.",
                                        "You made it back. That's all I needed to see.",
                                        "The sunset almost makes this place look peaceful.",
                                    },
                                    ["TL"] = {
                                        "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                                        "Halika maupo ka sa akin bago mamatay ang ilaw.",
                                        "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                                        "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                                        "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "There you are. I worried when you were gone so long.",
                            "Come sit with me before the light goes.",
                            "Long day. I'm glad you're here at the end of it.",
                            "You made it back. That's all I needed to see.",
                            "The sunset almost makes this place look peaceful.",
                        },
                        ["TL"] = {
                            "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                            "Halika maupo ka sa akin bago mamatay ang ilaw.",
                            "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                            "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                            "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.lover.sunset",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunset.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "There you are. I worried when you were gone so long.",
                            ["TL"] = "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Come sit with me before the light goes.",
                            ["TL"] = "Halika maupo ka sa akin bago mamatay ang ilaw.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Long day. I'm glad you're here at the end of it.",
                            ["TL"] = "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "You made it back. That's all I needed to see.",
                            ["TL"] = "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "The sunset almost makes this place look peaceful.",
                            ["TL"] = "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "There you are. I worried when you were gone so long.",
                                        "Come sit with me before the light goes.",
                                        "Long day. I'm glad you're here at the end of it.",
                                        "You made it back. That's all I needed to see.",
                                        "The sunset almost makes this place look peaceful.",
                                    },
                                    ["TL"] = {
                                        "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                                        "Halika maupo ka sa akin bago mamatay ang ilaw.",
                                        "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                                        "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                                        "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunset.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "There you are. I worried when you were gone so long.",
                        "Come sit with me before the light goes.",
                        "Long day. I'm glad you're here at the end of it.",
                        "You made it back. That's all I needed to see.",
                        "The sunset almost makes this place look peaceful.",
                    },
                    ["TL"] = {
                        "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                        "Halika maupo ka sa akin bago mamatay ang ilaw.",
                        "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                        "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                        "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Can't sleep? Neither can I.",
                                        "It's all right. I'm here.",
                                        "Come sit with me. We can keep watch together.",
                                        "You scared me walking around this late.",
                                        "Stay close tonight. I mean it.",
                                    },
                                    ["TL"] = {
                                        "Hindi makatulog? Hindi ko rin kaya.",
                                        "ayos lang. nandito ako.",
                                        "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                                        "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                                        "Manatili kang malapit ngayong gabi. Seryoso ako.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Can't sleep? Neither can I.",
                            "It's all right. I'm here.",
                            "Come sit with me. We can keep watch together.",
                            "You scared me walking around this late.",
                            "Stay close tonight. I mean it.",
                        },
                        ["TL"] = {
                            "Hindi makatulog? Hindi ko rin kaya.",
                            "ayos lang. nandito ako.",
                            "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                            "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                            "Manatili kang malapit ngayong gabi. Seryoso ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.lover.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.lover.twilight",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_twilight.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Can't sleep? Neither can I.",
                            ["TL"] = "Hindi makatulog? Hindi ko rin kaya.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "It's all right. I'm here.",
                            ["TL"] = "ayos lang. nandito ako.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Come sit with me. We can keep watch together.",
                            ["TL"] = "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "You scared me walking around this late.",
                            ["TL"] = "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Stay close tonight. I mean it.",
                            ["TL"] = "Manatili kang malapit ngayong gabi. Seryoso ako.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Can't sleep? Neither can I.",
                                        "It's all right. I'm here.",
                                        "Come sit with me. We can keep watch together.",
                                        "You scared me walking around this late.",
                                        "Stay close tonight. I mean it.",
                                    },
                                    ["TL"] = {
                                        "Hindi makatulog? Hindi ko rin kaya.",
                                        "ayos lang. nandito ako.",
                                        "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                                        "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                                        "Manatili kang malapit ngayong gabi. Seryoso ako.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_twilight.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Can't sleep? Neither can I.",
                        "It's all right. I'm here.",
                        "Come sit with me. We can keep watch together.",
                        "You scared me walking around this late.",
                        "Stay close tonight. I mean it.",
                    },
                    ["TL"] = {
                        "Hindi makatulog? Hindi ko rin kaya.",
                        "ayos lang. nandito ako.",
                        "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                        "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                        "Manatili kang malapit ngayong gabi. Seryoso ako.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You're up. Good—we have plenty to do.",
                                        "Morning. I already checked the perimeter.",
                                        "Couldn't sleep either? We may as well get started.",
                                        "First light. What's the plan today?",
                                        "Morning. Everyone else is still asleep, so it's just us.",
                                    },
                                    ["TL"] = {
                                        "Gising ka na. Mabuti—marami tayong gagawin.",
                                        "Umaga. Sinuri ko na ang perimeter.",
                                        "Hindi rin makatulog? Maaari rin tayong magsimula.",
                                        "Unang liwanag. Ano ang plano ngayon?",
                                        "Umaga. Tulog pa ang iba kaya kami na lang.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You're up. Good—we have plenty to do.",
                            "Morning. I already checked the perimeter.",
                            "Couldn't sleep either? We may as well get started.",
                            "First light. What's the plan today?",
                            "Morning. Everyone else is still asleep, so it's just us.",
                        },
                        ["TL"] = {
                            "Gising ka na. Mabuti—marami tayong gagawin.",
                            "Umaga. Sinuri ko na ang perimeter.",
                            "Hindi rin makatulog? Maaari rin tayong magsimula.",
                            "Unang liwanag. Ano ang plano ngayon?",
                            "Umaga. Tulog pa ang iba kaya kami na lang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.dawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dawn",
            ["sourceId"] = "social.greetings.member.dawn",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dawn.json",
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
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "You're up. Good—we have plenty to do.",
                            ["TL"] = "Gising ka na. Mabuti—marami tayong gagawin.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Morning. I already checked the perimeter.",
                            ["TL"] = "Umaga. Sinuri ko na ang perimeter.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Couldn't sleep either? We may as well get started.",
                            ["TL"] = "Hindi rin makatulog? Maaari rin tayong magsimula.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "First light. What's the plan today?",
                            ["TL"] = "Unang liwanag. Ano ang plano ngayon?",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Morning. Everyone else is still asleep, so it's just us.",
                            ["TL"] = "Umaga. Tulog pa ang iba kaya kami na lang.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You're up. Good—we have plenty to do.",
                                        "Morning. I already checked the perimeter.",
                                        "Couldn't sleep either? We may as well get started.",
                                        "First light. What's the plan today?",
                                        "Morning. Everyone else is still asleep, so it's just us.",
                                    },
                                    ["TL"] = {
                                        "Gising ka na. Mabuti—marami tayong gagawin.",
                                        "Umaga. Sinuri ko na ang perimeter.",
                                        "Hindi rin makatulog? Maaari rin tayong magsimula.",
                                        "Unang liwanag. Ano ang plano ngayon?",
                                        "Umaga. Tulog pa ang iba kaya kami na lang.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dawn.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "You're up. Good—we have plenty to do.",
                        "Morning. I already checked the perimeter.",
                        "Couldn't sleep either? We may as well get started.",
                        "First light. What's the plan today?",
                        "Morning. Everyone else is still asleep, so it's just us.",
                    },
                    ["TL"] = {
                        "Gising ka na. Mabuti—marami tayong gagawin.",
                        "Umaga. Sinuri ko na ang perimeter.",
                        "Hindi rin makatulog? Maaari rin tayong magsimula.",
                        "Unang liwanag. Ano ang plano ngayon?",
                        "Umaga. Tulog pa ang iba kaya kami na lang.",
                    },
                },
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
}
