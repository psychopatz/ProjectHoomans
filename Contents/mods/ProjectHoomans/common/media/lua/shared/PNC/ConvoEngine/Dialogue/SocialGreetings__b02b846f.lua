-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_greetings",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Evening. Perimeter looks clear.",
                                        "Need me for something before night watch?",
                                        "We're all still here. I'll call that a good day.",
                                        "Keep it quiet. The others are settling down.",
                                        "I can take first watch if you need the rest.",
                                    },
                                    ["TL"] = {
                                        "Gabi. Mukhang malinaw ang perimeter.",
                                        "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                                        "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                                        "Manahimik ka. Umayos na yung iba.",
                                        "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
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
                    ["fallback"] = "Evening. Perimeter looks clear.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.dusk.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Evening. Perimeter looks clear.",
                            "Need me for something before night watch?",
                            "We're all still here. I'll call that a good day.",
                            "Keep it quiet. The others are settling down.",
                            "I can take first watch if you need the rest.",
                        },
                        ["TL"] = {
                            "Gabi. Mukhang malinaw ang perimeter.",
                            "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                            "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                            "Manahimik ka. Umayos na yung iba.",
                            "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.dusk",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dusk",
            ["sourceId"] = "social.greetings.member.dusk",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dusk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings__b02b846f",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_dusk",
                ["textDomain"] = "pnc.psdl.social.greetings.member.dusk",
                ["textRows"] = {
                    {
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Evening. Perimeter looks clear.",
                            ["TL"] = "Gabi. Mukhang malinaw ang perimeter.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Need me for something before night watch?",
                            ["TL"] = "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "We're all still here. I'll call that a good day.",
                            ["TL"] = "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Keep it quiet. The others are settling down.",
                            ["TL"] = "Manahimik ka. Umayos na yung iba.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "I can take first watch if you need the rest.",
                            ["TL"] = "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/member/dusk",
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
                                        "Evening. Perimeter looks clear.",
                                        "Need me for something before night watch?",
                                        "We're all still here. I'll call that a good day.",
                                        "Keep it quiet. The others are settling down.",
                                        "I can take first watch if you need the rest.",
                                    },
                                    ["TL"] = {
                                        "Gabi. Mukhang malinaw ang perimeter.",
                                        "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                                        "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                                        "Manahimik ka. Umayos na yung iba.",
                                        "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
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
                            ["templateID"] = "psdl.social.greetings.member.dusk.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_dusk.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Evening. Perimeter looks clear.",
                        "Need me for something before night watch?",
                        "We're all still here. I'll call that a good day.",
                        "Keep it quiet. The others are settling down.",
                        "I can take first watch if you need the rest.",
                    },
                    ["TL"] = {
                        "Gabi. Mukhang malinaw ang perimeter.",
                        "Kailangan mo ba ako bago ang pagbabantay sa gabi?",
                        "Narito pa rin tayong lahat. Ituturing ko iyong magandang araw.",
                        "Manahimik ka. Umayos na yung iba.",
                        "Maaari akong kumuha ng unang panonood kung kailangan mo ang iba pa.",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Morning. Ready when you are.",
                                        "Good, you're here. What are we doing today?",
                                        "Another day with the crew. Could be worse.",
                                        "Morning. Supplies are holding for now.",
                                        "I was about to look for you. What's up?",
                                    },
                                    ["TL"] = {
                                        "Umaga. Handa kung kailan ka na.",
                                        "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                                        "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                                        "Umaga. Ang mga suplay ay hawak sa ngayon.",
                                        "Hinahanap na sana kita. Anong meron?",
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
                    ["fallback"] = "Morning. Ready when you are.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.sunrise.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Morning. Ready when you are.",
                            "Good, you're here. What are we doing today?",
                            "Another day with the crew. Could be worse.",
                            "Morning. Supplies are holding for now.",
                            "I was about to look for you. What's up?",
                        },
                        ["TL"] = {
                            "Umaga. Handa kung kailan ka na.",
                            "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                            "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                            "Umaga. Ang mga suplay ay hawak sa ngayon.",
                            "Hinahanap na sana kita. Anong meron?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.sunrise",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunrise",
            ["sourceId"] = "social.greetings.member.sunrise",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunrise.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings__b02b846f",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunrise",
                ["textDomain"] = "pnc.psdl.social.greetings.member.sunrise",
                ["textRows"] = {
                    {
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "Morning. Ready when you are.",
                            ["TL"] = "Umaga. Handa kung kailan ka na.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Good, you're here. What are we doing today?",
                            ["TL"] = "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Another day with the crew. Could be worse.",
                            ["TL"] = "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Morning. Supplies are holding for now.",
                            ["TL"] = "Umaga. Ang mga suplay ay hawak sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "I was about to look for you. What's up?",
                            ["TL"] = "Hinahanap na sana kita. Anong meron?",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/member/sunrise",
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
                                        "Morning. Ready when you are.",
                                        "Good, you're here. What are we doing today?",
                                        "Another day with the crew. Could be worse.",
                                        "Morning. Supplies are holding for now.",
                                        "I was about to look for you. What's up?",
                                    },
                                    ["TL"] = {
                                        "Umaga. Handa kung kailan ka na.",
                                        "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                                        "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                                        "Umaga. Ang mga suplay ay hawak sa ngayon.",
                                        "Hinahanap na sana kita. Anong meron?",
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
                            ["templateID"] = "psdl.social.greetings.member.sunrise.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunrise.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Morning. Ready when you are.",
                        "Good, you're here. What are we doing today?",
                        "Another day with the crew. Could be worse.",
                        "Morning. Supplies are holding for now.",
                        "I was about to look for you. What's up?",
                    },
                    ["TL"] = {
                        "Umaga. Handa kung kailan ka na.",
                        "Buti nandito ka. Ano ang ginagawa natin ngayon?",
                        "Panibagong araw kasama ang crew. Maaaring mas masahol pa.",
                        "Umaga. Ang mga suplay ay hawak sa ngayon.",
                        "Hinahanap na sana kita. Anong meron?",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "We made it through the day. That's something.",
                                        "Hey. Need a hand before we wrap up?",
                                        "Long day, but I'm still ready if you need me.",
                                        "Everyone accounted for?",
                                        "The light's fading. We should finish up soon.",
                                    },
                                    ["TL"] = {
                                        "Nalampasan natin ang araw. May halaga iyon.",
                                        "Hey. Kailangan ng kamay bago tayo magtapos?",
                                        "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                                        "Lahat ng tao accounted para sa?",
                                        "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
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
                    ["fallback"] = "We made it through the day. That's something.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.sunset.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We made it through the day. That's something.",
                            "Hey. Need a hand before we wrap up?",
                            "Long day, but I'm still ready if you need me.",
                            "Everyone accounted for?",
                            "The light's fading. We should finish up soon.",
                        },
                        ["TL"] = {
                            "Nalampasan natin ang araw. May halaga iyon.",
                            "Hey. Kailangan ng kamay bago tayo magtapos?",
                            "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                            "Lahat ng tao accounted para sa?",
                            "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.sunset",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "sunset",
            ["sourceId"] = "social.greetings.member.sunset",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunset.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings__b02b846f",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_sunset",
                ["textDomain"] = "pnc.psdl.social.greetings.member.sunset",
                ["textRows"] = {
                    {
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "We made it through the day. That's something.",
                            ["TL"] = "Nalampasan natin ang araw. May halaga iyon.",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Hey. Need a hand before we wrap up?",
                            ["TL"] = "Hey. Kailangan ng kamay bago tayo magtapos?",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "Long day, but I'm still ready if you need me.",
                            ["TL"] = "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Everyone accounted for?",
                            ["TL"] = "Lahat ng tao accounted para sa?",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "The light's fading. We should finish up soon.",
                            ["TL"] = "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/member/sunset",
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
                                        "We made it through the day. That's something.",
                                        "Hey. Need a hand before we wrap up?",
                                        "Long day, but I'm still ready if you need me.",
                                        "Everyone accounted for?",
                                        "The light's fading. We should finish up soon.",
                                    },
                                    ["TL"] = {
                                        "Nalampasan natin ang araw. May halaga iyon.",
                                        "Hey. Kailangan ng kamay bago tayo magtapos?",
                                        "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                                        "Lahat ng tao accounted para sa?",
                                        "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
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
                            ["templateID"] = "psdl.social.greetings.member.sunset.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_sunset.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "We made it through the day. That's something.",
                        "Hey. Need a hand before we wrap up?",
                        "Long day, but I'm still ready if you need me.",
                        "Everyone accounted for?",
                        "The light's fading. We should finish up soon.",
                    },
                    ["TL"] = {
                        "Nalampasan natin ang araw. May halaga iyon.",
                        "Hey. Kailangan ng kamay bago tayo magtapos?",
                        "Mahabang araw, pero handa pa rin ako kung kailangan mo ako.",
                        "Lahat ng tao accounted para sa?",
                        "Kumukupas na ang liwanag. Dapat na tayong magtapos.",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You're supposed to be resting. What's wrong?",
                                        "Quiet night so far. Let's keep it that way.",
                                        "I'm on watch. Did you need something?",
                                        "Good, it's you. I heard footsteps.",
                                        "Can't sleep? Pull up a chair, but keep your voice low.",
                                    },
                                    ["TL"] = {
                                        "Dapat nagpapahinga ka. Ano ang problema?",
                                        "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                                        "Nakabantay ako. may kailangan ka ba?",
                                        "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                                        "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
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
                    ["fallback"] = "You're supposed to be resting. What's wrong?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.greetings.member.twilight.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You're supposed to be resting. What's wrong?",
                            "Quiet night so far. Let's keep it that way.",
                            "I'm on watch. Did you need something?",
                            "Good, it's you. I heard footsteps.",
                            "Can't sleep? Pull up a chair, but keep your voice low.",
                        },
                        ["TL"] = {
                            "Dapat nagpapahinga ka. Ano ang problema?",
                            "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                            "Nakabantay ako. may kailangan ka ba?",
                            "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                            "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.greetings.member.twilight",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "twilight",
            ["sourceId"] = "social.greetings.member.twilight",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_twilight.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialGreetings__b02b846f",
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
                ["runtimeBlockID"] = "projecthoomans:greeting_member_twilight",
                ["textDomain"] = "pnc.psdl.social.greetings.member.twilight",
                ["textRows"] = {
                    {
                        ["key"] = "greeting.001",
                        ["text"] = {
                            ["EN"] = "You're supposed to be resting. What's wrong?",
                            ["TL"] = "Dapat nagpapahinga ka. Ano ang problema?",
                        },
                    },
                    {
                        ["key"] = "greeting.002",
                        ["text"] = {
                            ["EN"] = "Quiet night so far. Let's keep it that way.",
                            ["TL"] = "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                        },
                    },
                    {
                        ["key"] = "greeting.003",
                        ["text"] = {
                            ["EN"] = "I'm on watch. Did you need something?",
                            ["TL"] = "Nakabantay ako. may kailangan ka ba?",
                        },
                    },
                    {
                        ["key"] = "greeting.004",
                        ["text"] = {
                            ["EN"] = "Good, it's you. I heard footsteps.",
                            ["TL"] = "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                        },
                    },
                    {
                        ["key"] = "greeting.005",
                        ["text"] = {
                            ["EN"] = "Can't sleep? Pull up a chair, but keep your voice low.",
                            ["TL"] = "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
                        },
                    },
                },
                ["textTarget"] = "psdl/social/greetings/member/twilight",
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
                                        "You're supposed to be resting. What's wrong?",
                                        "Quiet night so far. Let's keep it that way.",
                                        "I'm on watch. Did you need something?",
                                        "Good, it's you. I heard footsteps.",
                                        "Can't sleep? Pull up a chair, but keep your voice low.",
                                    },
                                    ["TL"] = {
                                        "Dapat nagpapahinga ka. Ano ang problema?",
                                        "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                                        "Nakabantay ako. may kailangan ka ba?",
                                        "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                                        "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
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
                            ["templateID"] = "psdl.social.greetings.member.twilight.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_greetings/social_greetings_member_twilight.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "You're supposed to be resting. What's wrong?",
                        "Quiet night so far. Let's keep it that way.",
                        "I'm on watch. Did you need something?",
                        "Good, it's you. I heard footsteps.",
                        "Can't sleep? Pull up a chair, but keep your voice low.",
                    },
                    ["TL"] = {
                        "Dapat nagpapahinga ka. Ano ang problema?",
                        "Tahimik na gabi hanggang ngayon. Panatilihin natin itong paraan.",
                        "Nakabantay ako. may kailangan ka ba?",
                        "Buti, ikaw pala. Nakarinig ako ng mga yabag.",
                        "Hindi makatulog? Hilahin ang isang upuan, ngunit panatilihing mahina ang iyong boses.",
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
