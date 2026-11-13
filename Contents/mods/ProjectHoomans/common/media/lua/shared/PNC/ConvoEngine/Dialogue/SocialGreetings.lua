-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_dawn",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.dawn",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/dawn",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're awake early too. Everything all right?",
                            },
                            ["TL"] = {
                                "Gising ka rin nang maaga. Ayos ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. I didn't expect to see you before sunrise.",
                            },
                            ["TL"] = {
                                "Umaga. Hindi ko inaasahan na makikita kita bago sumikat ang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't sleep? Neither could I.",
                            },
                            ["TL"] = {
                                "hindi makatulog? Hindi ko rin kaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good, it's you. What brings you over this early?",
                            },
                            ["TL"] = {
                                "Buti, ikaw pala. Ano ang nagdudulot sa iyo ng ganito kaaga?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Dawn patrol, or did you need something?",
                            },
                            ["TL"] = {
                                "Dawn patrol, o may kailangan ka?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.dusk",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/dusk",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Evening. Need something before we turn in?",
                            },
                            ["TL"] = {
                                "Gabi. Kailangan mo ng isang bagay bago tayo lumiko?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good, it's only you. You startled me.",
                            },
                            ["TL"] = {
                                "Buti, ikaw lang. Ginulat mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not much daylight left. Talk to me.",
                            },
                            ["TL"] = {
                                "Wala na masyadong liwanag ng araw. kausapin mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Keeping watch, or just passing by?",
                            },
                            ["TL"] = {
                                "Hey. Nagmamasid, o dumadaan lang?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We should keep this quiet, but I'm listening.",
                            },
                            ["TL"] = {
                                "Dapat tahimik lang tayo rito, pero nakikinig ako.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.sunrise",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/sunrise",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Good to see a familiar face.",
                            },
                            ["TL"] = {
                                "Umaga. Ang sarap makakita ng pamilyar na mukha.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How's the day treating you?",
                            },
                            ["TL"] = {
                                "Hey. Kumusta ang pagtrato sa iyo ng araw?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Need a minute?",
                            },
                            ["TL"] = {
                                "Narito ka pala. Kailangan mo ba ng sandali?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. You look like you have something on your mind.",
                            },
                            ["TL"] = {
                                "Umaga. Parang may iniisip ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nice to see you made it through another night.",
                            },
                            ["TL"] = {
                                "Natutuwa akong makita kang nagtagumpay sa isa pang gabi.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.sunset",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/sunset",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Been a long day?",
                            },
                            ["TL"] = {
                                "Hey. Isang mahabang araw?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good timing. I was about to settle in.",
                            },
                            ["TL"] = {
                                "Magandang timing. Malapit na akong tumira.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Find anything useful today?",
                            },
                            ["TL"] = {
                                "Narito ka pala. May nakita ka bang kapaki-pakinabang ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The day's winding down. What's up?",
                            },
                            ["TL"] = {
                                "Palubog na ang araw. Anong meron?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You look tired. Everything okay?",
                            },
                            ["TL"] = {
                                "Mukha kang pagod. Ayos ka lang ba?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_acquaintance_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.acquaintance.twilight",
                ["textTarget"] = "psdl/social/greetings/neutral/acquaintance/twilight",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Late night. What has you awake?",
                            },
                            ["TL"] = {
                                "Gabi na. Anong gising mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's good to see someone I recognize out here.",
                            },
                            ["TL"] = {
                                "Nakakatuwang makita ang isang taong kilala ko dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep it down. Sound carries at night.",
                            },
                            ["TL"] = {
                                "Panatilihin ito pababa. Ang tunog ay nagdadala sa gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You all right? It's late to be wandering.",
                            },
                            ["TL"] = {
                                "Ayos ka lang ba? Gabi na para magpagala-gala.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Make it quick before we draw attention.",
                            },
                            ["TL"] = {
                                "Hey. Bilisan mo bago tayo makatawag ng pansin.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_acquaintance_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dawn",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.dawn",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/dawn",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hold there. I don't know you, and dawn is a strange time for introductions.",
                            },
                            ["TL"] = {
                                "Humawak ka dyan. Hindi kita kilala, at ang bukang-liwayway ay isang kakaibang oras para sa pagpapakilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're up before the dead settle down. Who are you?",
                            },
                            ["TL"] = {
                                "Gising ka bago pa manahimik ang mga patay. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Easy. The light is barely up, and I wasn't expecting company.",
                            },
                            ["TL"] = {
                                "Madali. Bahagyang nakapatay ang ilaw, at hindi ko inaasahan ang makakasama ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning, I suppose. Keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Umaga, kumbaga. Itago ang iyong mga kamay kung saan ko sila makikita.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "First light and a new face. Tell me what you need.",
                            },
                            ["TL"] = {
                                "Unang liwanag at bagong mukha. Sabihin mo sa akin kung ano ang kailangan mo.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.dusk",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/dusk",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stop there. Dusk makes strangers hard to read.",
                            },
                            ["TL"] = {
                                "Tumigil ka dyan. Dahil sa takipsilim, mahirap basahin ang mga estranghero.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not much light left. Introduce yourself.",
                            },
                            ["TL"] = {
                                "Wala nang gaanong ilaw. Magpakilala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You surprised me. What do you want?",
                            },
                            ["TL"] = {
                                "Nagulat mo ako. Ano ang kailangan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your voice down and tell me why you're here.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses mo at sabihin sa akin kung bakit ka nandito.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't make out your face. Come no closer.",
                            },
                            ["TL"] = {
                                "Hindi ko maaninag ang mukha mo. Huwag kang lalapit.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.sunrise",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/sunrise",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. I haven't seen you around before.",
                            },
                            ["TL"] = {
                                "Umaga. Hindi pa kita nakikita kanina.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's close enough. Start with your name.",
                            },
                            ["TL"] = {
                                "Malapit na yun. Magsimula sa iyong pangalan.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "New face. Are you passing through or looking for something?",
                            },
                            ["TL"] = {
                                "Bagong mukha. Ikaw ba ay dumadaan o may hinahanap?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Daylight makes this easier. Who are you?",
                            },
                            ["TL"] = {
                                "Pinapadali ito ng liwanag ng araw. sino ka ba",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't recognize you. Talk, and keep it calm.",
                            },
                            ["TL"] = {
                                "hindi kita kilala. Mag-usap, at panatilihin itong kalmado.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.sunset",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/sunset",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You picked a late hour to approach a stranger.",
                            },
                            ["TL"] = {
                                "Huli na para lumapit sa isang estranghero.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The light is going. Say what you came to say.",
                            },
                            ["TL"] = {
                                "Ang ilaw ay pupunta. Sabihin mo kung ano ang gusto mong sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know you, but I'm listening.",
                            },
                            ["TL"] = {
                                "Hindi kita kilala, pero nakikinig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Before it gets dark, tell me who you are.",
                            },
                            ["TL"] = {
                                "Bago dumilim, sabihin mo sa akin kung sino ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Another survivor. Friendly, I hope?",
                            },
                            ["TL"] = {
                                "Isa pang nakaligtas. Friendly, sana?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_firstmeet_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.neutral.first_meet.twilight",
                ["textTarget"] = "psdl/social/greetings/neutral/first_meet/twilight",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's dark out. Stay where I can see you.",
                            },
                            ["TL"] = {
                                "Madilim sa labas. Manatili ka kung saan kita makikita.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A stranger walking up at night usually means trouble.",
                            },
                            ["TL"] = {
                                "Ang isang estranghero na naglalakad sa gabi ay karaniwang nangangahulugan ng problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your voice low. Who are you?",
                            },
                            ["TL"] = {
                                "Panatilihing mahina ang iyong boses. sino ka ba",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You chose a bad time to sneak up on someone.",
                            },
                            ["TL"] = {
                                "You chose a bad time to sneak up buhay someone.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't move any closer. We can talk from there.",
                            },
                            ["TL"] = {
                                "Huwag kang lalapit. Maaari tayong mag-usap mula doon.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_firstmeet_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["textDomain"] = "pnc.psdl.social.greetings.hostile.parley",
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
                ["textTarget"] = "psdl/social/greetings/hostile/parley",
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
                            ["labelKey"] = "psdl.social.greetings.hostile.parley.offer.ceasefire.label",
                            ["utteranceFallback"] = "Ceasefire. Stand down for now.",
                            ["utteranceKey"] = "psdl.social.greetings.hostile.parley.offer.ceasefire.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "The survivor watches you carefully, ready to fight.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.greetings.hostile.parley.opening",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_dawn",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.dawn",
                ["textTarget"] = "psdl/social/greetings/special/lover/dawn",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're awake already. I was hoping you'd sleep a little longer.",
                            },
                            ["TL"] = {
                                "You're awake already. I was hoping you'd tulog a little longer.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning, love. Come here before the day starts.",
                            },
                            ["TL"] = {
                                "Umaga, mahal. Halika dito bago magsimula ang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I missed you, and you were only asleep.",
                            },
                            ["TL"] = {
                                "Namiss kita, tulog ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "First light looks better with you here.",
                            },
                            ["TL"] = {
                                "Mas maganda ang unang liwanag kapag kasama ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't sleep without checking on everyone, could you?",
                            },
                            ["TL"] = {
                                "Hindi makatulog nang hindi sinusuri ang lahat, hindi ba?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.dusk",
                ["textTarget"] = "psdl/social/greetings/special/lover/dusk",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay with me a minute before night watch.",
                            },
                            ["TL"] = {
                                "Manatili sa akin ng isang minuto bago manood ng gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Evening, love. You look exhausted.",
                            },
                            ["TL"] = {
                                "Gabi, mahal. Mukha kang pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're safe. I can breathe again.",
                            },
                            ["TL"] = {
                                "Ligtas ka. Muli na akong makahihinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Come closer. We don't get many quiet moments.",
                            },
                            ["TL"] = {
                                "Lumapit ka. Hindi kami nakakakuha ng maraming tahimik na sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I saved you a place by me.",
                            },
                            ["TL"] = {
                                "Iniligtas kita ng isang lugar sa tabi ko.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.sunrise",
                ["textTarget"] = "psdl/social/greetings/special/lover/sunrise",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning, love. You sleep all right?",
                            },
                            ["TL"] = {
                                "Umaga, mahal. Matulog ka na okay?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There you are. I was starting to miss you.",
                            },
                            ["TL"] = {
                                "Narito ka pala. Nagsisimula na kitang ma-miss.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good morning. Stay close today, okay?",
                            },
                            ["TL"] = {
                                "Magandang umaga po. Manatiling malapit ngayon, okay?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Seeing you first thing still makes this place feel almost normal.",
                            },
                            ["TL"] = {
                                "Ang una mong makita ay halos normal pa rin ang pakiramdam ng lugar na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Whatever happens today, we handle it together.",
                            },
                            ["TL"] = {
                                "Umaga. Kung ano man ang mangyari ngayon, sabay nating haharapin.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.sunset",
                ["textTarget"] = "psdl/social/greetings/special/lover/sunset",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "There you are. I worried when you were gone so long.",
                            },
                            ["TL"] = {
                                "Narito ka pala. Nag-alala ako nang matagal kang wala.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Come sit with me before the light goes.",
                            },
                            ["TL"] = {
                                "Halika maupo ka sa akin bago mamatay ang ilaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Long day. I'm glad you're here at the end of it.",
                            },
                            ["TL"] = {
                                "Mahabang araw. Natutuwa akong narito ka sa dulo nito.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You made it back. That's all I needed to see.",
                            },
                            ["TL"] = {
                                "Nakabalik ka. Iyon lang ang kailangan kong makita.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The sunset almost makes this place look peaceful.",
                            },
                            ["TL"] = {
                                "Halos nagmumukhang payapa ang lugar na ito sa dapit-hapon.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_lover_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.special.lover.twilight",
                ["textTarget"] = "psdl/social/greetings/special/lover/twilight",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't sleep? Neither can I.",
                            },
                            ["TL"] = {
                                "Hindi makatulog? Hindi ko rin kaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. I'm here.",
                            },
                            ["TL"] = {
                                "ayos lang. nandito ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Come sit with me. We can keep watch together.",
                            },
                            ["TL"] = {
                                "Halika upo sa akin. Maaari tayong magbantay nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You scared me walking around this late.",
                            },
                            ["TL"] = {
                                "Tinakot mo ako sa paglalakad nang ganito kagabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay close tonight. I mean it.",
                            },
                            ["TL"] = {
                                "Manatili kang malapit ngayong gabi. Seryoso ako.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_lover_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dawn",
                ["textDomain"] = "pnc.psdl.social.greetings.member.dawn",
                ["textTarget"] = "psdl/social/greetings/member/dawn",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're up. Good—we have plenty to do.",
                            },
                            ["TL"] = {
                                "Gising ka na. Mabuti—marami tayong gagawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. I already checked the perimeter.",
                            },
                            ["TL"] = {
                                "Umaga. Sinuri ko na ang perimeter.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't sleep either? We may as well get started.",
                            },
                            ["TL"] = {
                                "Hindi rin makatulog? Maaari rin tayong magsimula.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "First light. What's the plan today?",
                            },
                            ["TL"] = {
                                "Unang liwanag. Ano ang plano ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Everyone else is still asleep, so it's just us.",
                            },
                            ["TL"] = {
                                "Umaga. Tulog pa ang iba kaya kami na lang.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
        ["id"] = "social.greetings.member.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.member.dusk",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dusk.json",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.member.dusk",
                ["textTarget"] = "psdl/social/greetings/member/dusk",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Evening. Perimeter looks clear.",
                            },
                            ["TL"] = {
                                "Gabi. Mukhang malinaw ang perimeter.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need me for something before night watch?",
                            },
                            ["TL"] = {
                                "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're all still here. I'll call that a good day.",
                            },
                            ["TL"] = {
                                "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep it quiet. The others are settling down.",
                            },
                            ["TL"] = {
                                "Manahimik ka. Umayos na yung iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can take first watch if you need the rest.",
                            },
                            ["TL"] = {
                                "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dusk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
        ["id"] = "social.greetings.member.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.member.sunrise",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunrise.json",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.member.sunrise",
                ["textTarget"] = "psdl/social/greetings/member/sunrise",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Ready when you are.",
                            },
                            ["TL"] = {
                                "Umaga. Handa kung kailan ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good, you're here. What are we doing today?",
                            },
                            ["TL"] = {
                                "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Another day with the crew. Could be worse.",
                            },
                            ["TL"] = {
                                "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Supplies are holding for now.",
                            },
                            ["TL"] = {
                                "Umaga. Ang mga suplay ay hawak sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I was about to look for you. What's up?",
                            },
                            ["TL"] = {
                                "Hinahanap na sana kita. Anong meron?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunrise.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
        ["id"] = "social.greetings.member.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.member.sunset",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunset.json",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.member.sunset",
                ["textTarget"] = "psdl/social/greetings/member/sunset",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We made it through the day. That's something.",
                            },
                            ["TL"] = {
                                "Nalampasan natin ang araw. May halaga iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Need a hand before we wrap up?",
                            },
                            ["TL"] = {
                                "Hey. Kailangan ng kamay bago tayo magtapos?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Long day, but I'm still ready if you need me.",
                            },
                            ["TL"] = {
                                "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Everyone accounted for?",
                            },
                            ["TL"] = {
                                "Lahat ng tao accounted para sa?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The light's fading. We should finish up soon.",
                            },
                            ["TL"] = {
                                "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunset.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
        ["id"] = "social.greetings.member.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.member.twilight",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_twilight.json",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.member.twilight",
                ["textTarget"] = "psdl/social/greetings/member/twilight",
                ["weight"] = 100,
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "greeting.001",
                        ["metadata"] = {
                            ["textKey"] = "greeting.001",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're supposed to be resting. What's wrong?",
                            },
                            ["TL"] = {
                                "Dapat nagpapahinga ka. Ano ang problema?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.002",
                        ["metadata"] = {
                            ["textKey"] = "greeting.002",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet night so far. Let's keep it that way.",
                            },
                            ["TL"] = {
                                "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.003",
                        ["metadata"] = {
                            ["textKey"] = "greeting.003",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm on watch. Did you need something?",
                            },
                            ["TL"] = {
                                "Nakabantay ako. may kailangan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.004",
                        ["metadata"] = {
                            ["textKey"] = "greeting.004",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good, it's you. I heard footsteps.",
                            },
                            ["TL"] = {
                                "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                            },
                        },
                    },
                    {
                        ["id"] = "greeting.005",
                        ["metadata"] = {
                            ["textKey"] = "greeting.005",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't sleep? Pull up a chair, but keep your voice low.",
                            },
                            ["TL"] = {
                                "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_twilight.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
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
