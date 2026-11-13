-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.small_talk.member",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_member",
                ["textDomain"] = "pnc.psdl.social.small_talk.member",
                ["textTarget"] = "psdl/social/small_talk/member",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WEATHER",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "weather",
                                ["label"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseText"] = {
                                        ["EN"] = "Could be worse. We've worked through worse.",
                                        ["TL"] = "Maaaring mas masahol pa. Mas malala ang pinagdaanan namin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "DAY",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "quiet_day",
                                ["label"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseText"] = {
                                        ["EN"] = "The crew earned one.",
                                        ["TL"] = "Karapat-dapat iyon ng grupo.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A quiet conversation sounds good right now.",
                            },
                            ["TL"] = {
                                "Ang isang tahimik na pag-uusap ay pakinggan ngayon.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SMALL_TALK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.small_talk.member",
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
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WEATHER",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "weather",
                            ["labelFallback"] = "Some weather we're having.",
                            ["labelKey"] = "psdl.social.small_talk.member.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.member.offer.weather.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["op"] = "gte",
                                ["path"] = "relationship.speakerToAddressee.familiarity",
                                ["value"] = 1,
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "DAY",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "quiet_day",
                            ["labelFallback"] = "Quiet day so far.",
                            ["labelKey"] = "psdl.social.small_talk.member.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.member.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "A quiet conversation sounds good right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.member.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.small_talk.neutral",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_neutral",
                ["textDomain"] = "pnc.psdl.social.small_talk.neutral",
                ["textTarget"] = "psdl/social/small_talk/neutral",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WEATHER",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "weather",
                                ["label"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseText"] = {
                                        ["EN"] = "At least the rain covers our footsteps.",
                                        ["TL"] = "At least natatakpan ng ulan ang mga yapak namin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "DAY",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "quiet_day",
                                ["label"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseText"] = {
                                        ["EN"] = "Do not tempt fate, but I'll take it.",
                                        ["TL"] = "Huwag tuksuhin ang kapalaran, ngunit kukunin ko ito.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. We can talk for a minute.",
                            },
                            ["TL"] = {
                                "Sige. Maaari tayong mag-usap sandali.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SMALL_TALK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.small_talk.neutral",
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
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WEATHER",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "weather",
                            ["labelFallback"] = "Some weather we're having.",
                            ["labelKey"] = "psdl.social.small_talk.neutral.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.neutral.offer.weather.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["op"] = "gte",
                                ["path"] = "relationship.speakerToAddressee.familiarity",
                                ["value"] = 1,
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "DAY",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "quiet_day",
                            ["labelFallback"] = "Quiet day so far.",
                            ["labelKey"] = "psdl.social.small_talk.neutral.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.neutral.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "All right. We can talk for a minute.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.neutral.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.small_talk.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.small_talk.special",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_special",
                ["textDomain"] = "pnc.psdl.social.small_talk.special",
                ["textTarget"] = "psdl/social/small_talk/special",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WEATHER",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "weather",
                                ["label"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseText"] = {
                                        ["EN"] = "I barely noticed. I was watching you.",
                                        ["TL"] = "bahagya kong napansin. pinapanood kita.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Some weather we're having.",
                                    },
                                    ["TL"] = {
                                        "Ilang panahon ang nararanasan natin.",
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "DAY",
                                    ["topic"] = "small_talk",
                                },
                                ["id"] = "quiet_day",
                                ["label"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseText"] = {
                                        ["EN"] = "Then spend part of it with me.",
                                        ["TL"] = "Kung gayon, gugulin mo ang bahagi nito kasama ako.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Quiet day so far.",
                                    },
                                    ["TL"] = {
                                        "Tahimik na araw hanggang ngayon.",
                                    },
                                },
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I always have time for you, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Palagi akong may oras para sa iyo, {addressee.name}.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SMALL_TALK",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.small_talk.special",
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
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WEATHER",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "weather",
                            ["labelFallback"] = "Some weather we're having.",
                            ["labelKey"] = "psdl.social.small_talk.special.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "psdl.social.small_talk.special.offer.weather.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["op"] = "gte",
                                ["path"] = "relationship.speakerToAddressee.familiarity",
                                ["value"] = 1,
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "DAY",
                                ["topic"] = "small_talk",
                            },
                            ["id"] = "quiet_day",
                            ["labelFallback"] = "Quiet day so far.",
                            ["labelKey"] = "psdl.social.small_talk.special.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "psdl.social.small_talk.special.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I always have time for you, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.small_talk.special.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.wellbeing.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.wellbeing.member",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_member",
                ["textDomain"] = "pnc.psdl.social.wellbeing.member",
                ["textTarget"] = "psdl/social/wellbeing/member",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WELLBEING",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "condition",
                                ["label"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.condition",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 1,
                                            ["familiarity"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.condition",
                                    ["responseText"] = {
                                        ["EN"] = "Tired, but ready if the group needs me.",
                                        ["TL"] = "Tired, but ready if the grupo needs me.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 1,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.familiarity",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "HELP",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "offer_help",
                                ["label"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.offer_help",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["respect"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.offer_help",
                                    ["responseText"] = {
                                        ["EN"] = "A little rest would help. I appreciate you asking.",
                                        ["TL"] = "Makakatulong ang kaunting pahinga. Pinahahalagahan ko ang pagtatanong mo.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 2,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.respect",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still standing. Go ahead.",
                            },
                            ["TL"] = {
                                "Nakatayo pa rin. Sige na.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "CHECK_IN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.wellbeing.member",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 1,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.familiarity",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WELLBEING",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "condition",
                            ["labelFallback"] = "How are you holding up?",
                            ["labelKey"] = "psdl.social.wellbeing.member.offer.condition.label",
                            ["utteranceFallback"] = "How are you holding up?",
                            ["utteranceKey"] = "psdl.social.wellbeing.member.offer.condition.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 2,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.respect",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "HELP",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "offer_help",
                            ["labelFallback"] = "Do you need any help?",
                            ["labelKey"] = "psdl.social.wellbeing.member.offer.offer_help.label",
                            ["utteranceFallback"] = "Do you need any help?",
                            ["utteranceKey"] = "psdl.social.wellbeing.member.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Still standing. Go ahead.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.wellbeing.member.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.wellbeing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.wellbeing.neutral",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_neutral",
                ["textDomain"] = "pnc.psdl.social.wellbeing.neutral",
                ["textTarget"] = "psdl/social/wellbeing/neutral",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WELLBEING",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "condition",
                                ["label"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.condition",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 1,
                                            ["familiarity"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.condition",
                                    ["responseText"] = {
                                        ["EN"] = "I'm still breathing. That's enough for now.",
                                        ["TL"] = "humihinga pa ako. Tama na sa ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 1,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.familiarity",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "HELP",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "offer_help",
                                ["label"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.offer_help",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["respect"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.offer_help",
                                    ["responseText"] = {
                                        ["EN"] = "I'll manage, but thanks for asking.",
                                        ["TL"] = "Aayusin ko, pero salamat sa pagtatanong.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 2,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.respect",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing. What did you want to ask?",
                            },
                            ["TL"] = {
                                "pinamamahalaan ko. Ano ang gusto mong itanong?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "CHECK_IN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.wellbeing.neutral",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 1,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.familiarity",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WELLBEING",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "condition",
                            ["labelFallback"] = "How are you holding up?",
                            ["labelKey"] = "psdl.social.wellbeing.neutral.offer.condition.label",
                            ["utteranceFallback"] = "How are you holding up?",
                            ["utteranceKey"] = "psdl.social.wellbeing.neutral.offer.condition.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 2,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.respect",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "HELP",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "offer_help",
                            ["labelFallback"] = "Do you need any help?",
                            ["labelKey"] = "psdl.social.wellbeing.neutral.offer.offer_help.label",
                            ["utteranceFallback"] = "Do you need any help?",
                            ["utteranceKey"] = "psdl.social.wellbeing.neutral.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm managing. What did you want to ask?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.wellbeing.neutral.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.wellbeing.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.wellbeing.special",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_special",
                ["textDomain"] = "pnc.psdl.social.wellbeing.special",
                ["textTarget"] = "psdl/social/wellbeing/special",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
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
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WELLBEING",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "condition",
                                ["label"] = {
                                    ["EN"] = {
                                        "How are you really doing?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na talaga?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.condition",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 1,
                                            ["familiarity"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.condition",
                                    ["responseText"] = {
                                        ["EN"] = "Better now that you're here.",
                                        ["TL"] = "Mas mabuti na ngayong nandito ka na.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "How are you really doing?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na talaga?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 1,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.familiarity",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "HELP",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "offer_help",
                                ["label"] = {
                                    ["EN"] = {
                                        "Let me help.",
                                    },
                                    ["TL"] = {
                                        "Hayaan mo akong tumulong.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.offer_help",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["respect"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.offer_help",
                                    ["responseText"] = {
                                        ["EN"] = "All right. Just stay close for a minute.",
                                        ["TL"] = "Sige. Manatiling malapit sa isang minuto.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Let me help.",
                                    },
                                    ["TL"] = {
                                        "Hayaan mo akong tumulong.",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 2,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.respect",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'll be honest with you, {addressee.name}. Ask.",
                            },
                            ["TL"] = {
                                "Magiging tapat ako sa iyo, {addressee.name}. Magtanong.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "CHECK_IN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.wellbeing.special",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 1,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.familiarity",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WELLBEING",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "condition",
                            ["labelFallback"] = "How are you really doing?",
                            ["labelKey"] = "psdl.social.wellbeing.special.offer.condition.label",
                            ["utteranceFallback"] = "How are you really doing?",
                            ["utteranceKey"] = "psdl.social.wellbeing.special.offer.condition.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 2,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.respect",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "HELP",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "offer_help",
                            ["labelFallback"] = "Let me help.",
                            ["labelKey"] = "psdl.social.wellbeing.special.offer.offer_help.label",
                            ["utteranceFallback"] = "Let me help.",
                            ["utteranceKey"] = "psdl.social.wellbeing.special.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'll be honest with you, {addressee.name}. Ask.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.wellbeing.special.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
