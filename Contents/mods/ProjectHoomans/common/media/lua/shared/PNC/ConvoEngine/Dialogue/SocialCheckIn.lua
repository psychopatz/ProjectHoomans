-- Hand-maintained ProjectHoomans ConvoEngine module.
return {
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["exchangeFamily"] = {
            ["familyID"] = "social.effectful.wellbeing_trust",
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
                                ["fallback"] = "I appreciate you watching my back.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.effectful.wellbeing_trust.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.effectful",
            ["replies"] = {
                ["accepted"] = {
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Always.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.accepted.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["blocked"] = {
                    ["outcome"] = "blocked",
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
                                        ["fallback"] = "Save it.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I appreciate you watching my back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.effectful.wellbeing_trust.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Always.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.accepted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Save it.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.effectful.wellbeing_trust",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing_trust",
            ["sourceId"] = "social.effectful.wellbeing_trust",
            ["sourcePath"] = "dialogue/social_check_in/social_effectful_wellbeing_trust.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.effectful",
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
            ["closure"] = {
                ["closureClass"] = "resolved_episode",
                ["episodeId"] = "social_wellbeing_trust",
            },
            ["cooldownTurns"] = 3,
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["modifiers"] = {
                {
                    ["delta"] = 1,
                    ["domain"] = "relationship",
                    ["field"] = "trust",
                    ["id"] = "trust_check_in_boost",
                    ["retention"] = {
                        ["durationMinutes"] = 1440,
                        ["kind"] = "TIMED",
                    },
                    ["stacking"] = "ignore",
                    ["targetRole"] = "addressee",
                },
            },
            ["postconditions"] = {
                "social.trust_check_in_recorded",
            },
            ["repeatPolicy"] = "cooldown",
            ["reply"] = {
                ["accepted"] = {
                    ["outcome"] = "accepted",
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
                                        ["fallback"] = "Always.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["blocked"] = {
                    ["outcome"] = "blocked",
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
                                        ["fallback"] = "Save it.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                ["fallback"] = "I appreciate you watching my back.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "hostile_blocked",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_npc",
                    ["replyOutcome"] = "blocked",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "roles.hostile",
                        ["value"] = true,
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.effectful.wellbeing_trust",
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
                            ["fallback"] = "I appreciate you watching my back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.effectful.wellbeing_trust.say_1",
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
        ["sourceShard"] = "dialogue/social_check_in/social_effectful_wellbeing_trust.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I appreciate you watching my back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.effectful.wellbeing_trust.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Always.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.accepted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Save it.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.effectful.wellbeing_trust.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.small_talk.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "member",
            ["sourceId"] = "social.small_talk.member",
            ["sourcePath"] = "dialogue/social_check_in/social_small_talk_member.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.small_talk",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_member",
                ["textDomain"] = "pnc.convo.social.small_talk.member",
                ["textTarget"] = "convo/social/small_talk/member",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
                ["turns"] = {
                    {
                        ["fallback"] = "A quiet conversation sounds good right now.",
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
                                ["labelFallback"] = "Some weather we're having.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseTextFallback"] = "Could be worse. We've worked through worse.",
                                },
                                ["utteranceFallback"] = "Some weather we're having.",
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
                                ["labelFallback"] = "Quiet day so far.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseTextFallback"] = "The crew earned one.",
                                },
                                ["utteranceFallback"] = "Quiet day so far.",
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                    },
                },
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
                            ["labelKey"] = "convo.social.small_talk.member.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "convo.social.small_talk.member.offer.weather.utterance",
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
                            ["labelKey"] = "convo.social.small_talk.member.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "convo.social.small_talk.member.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "A quiet conversation sounds good right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.small_talk.member.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_small_talk_member.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.small_talk.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "social.small_talk.neutral",
            ["sourcePath"] = "dialogue/social_check_in/social_small_talk.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.small_talk",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_neutral",
                ["textDomain"] = "pnc.convo.social.small_talk.neutral",
                ["textTarget"] = "convo/social/small_talk/neutral",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
                ["turns"] = {
                    {
                        ["fallback"] = "All right. We can talk for a minute.",
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
                                ["labelFallback"] = "Some weather we're having.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseTextFallback"] = "Could be worse out there. I just keep moving.",
                                },
                                ["utteranceFallback"] = "Some weather we're having.",
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
                                ["labelFallback"] = "Quiet day so far.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseTextFallback"] = "Do not tempt fate, but I'll take it.",
                                },
                                ["utteranceFallback"] = "Quiet day so far.",
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                    },
                },
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
                            ["labelKey"] = "convo.social.small_talk.neutral.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "convo.social.small_talk.neutral.offer.weather.utterance",
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
                            ["labelKey"] = "convo.social.small_talk.neutral.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "convo.social.small_talk.neutral.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "All right. We can talk for a minute.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.small_talk.neutral.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_small_talk.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.small_talk.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "special",
            ["sourceId"] = "social.small_talk.special",
            ["sourcePath"] = "dialogue/social_check_in/social_small_talk_special.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.small_talk",
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
                ["category"] = "projecthoomans:small_talk",
                ["runtimeBlockID"] = "projecthoomans:small_talk_special",
                ["textDomain"] = "pnc.convo.social.small_talk.special",
                ["textTarget"] = "convo/social/small_talk/special",
            },
            ["response"] = {
                ["act"] = "SMALL_TALK",
                ["turns"] = {
                    {
                        ["fallback"] = "I always have time for you, {addressee.name}.",
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
                                ["labelFallback"] = "Some weather we're having.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.weather",
                                    ["responseKey"] = "response.weather",
                                    ["responseTextFallback"] = "I barely noticed. I was watching you.",
                                },
                                ["utteranceFallback"] = "Some weather we're having.",
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
                                ["labelFallback"] = "Quiet day so far.",
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.quiet_day",
                                    ["responseKey"] = "response.quiet_day",
                                    ["responseTextFallback"] = "Then spend part of it with me.",
                                },
                                ["utteranceFallback"] = "Quiet day so far.",
                                ["when"] = {
                                    ["op"] = "gte",
                                    ["path"] = "relationship.speakerToAddressee.familiarity",
                                    ["value"] = 1,
                                },
                            },
                        },
                    },
                },
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
                            ["labelKey"] = "convo.social.small_talk.special.offer.weather.label",
                            ["utteranceFallback"] = "Some weather we're having.",
                            ["utteranceKey"] = "convo.social.small_talk.special.offer.weather.utterance",
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
                            ["labelKey"] = "convo.social.small_talk.special.offer.quiet_day.label",
                            ["utteranceFallback"] = "Quiet day so far.",
                            ["utteranceKey"] = "convo.social.small_talk.special.offer.quiet_day.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I always have time for you, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.small_talk.special.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_small_talk_special.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.wellbeing.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "member",
            ["sourceId"] = "social.wellbeing.member",
            ["sourcePath"] = "dialogue/social_check_in/social_wellbeing_member.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.wellbeing",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_member",
                ["textDomain"] = "pnc.convo.social.wellbeing.member",
                ["textTarget"] = "convo/social/wellbeing/member",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
                ["turns"] = {
                    {
                        ["fallback"] = "Still standing. Go ahead.",
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
                                ["labelFallback"] = "How are you holding up?",
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
                                    ["responseTextFallback"] = "Tired, but ready if the group needs me.",
                                },
                                ["utteranceFallback"] = "How are you holding up?",
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
                                ["labelFallback"] = "Do you need any help?",
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
                                    ["responseTextFallback"] = "A little rest would help. I appreciate you asking.",
                                },
                                ["utteranceFallback"] = "Do you need any help?",
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
                    },
                },
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
                            ["labelKey"] = "convo.social.wellbeing.member.offer.condition.label",
                            ["utteranceFallback"] = "How are you holding up?",
                            ["utteranceKey"] = "convo.social.wellbeing.member.offer.condition.utterance",
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
                            ["labelKey"] = "convo.social.wellbeing.member.offer.offer_help.label",
                            ["utteranceFallback"] = "Do you need any help?",
                            ["utteranceKey"] = "convo.social.wellbeing.member.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Still standing. Go ahead.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.wellbeing.member.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_wellbeing_member.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.wellbeing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "social.wellbeing.neutral",
            ["sourcePath"] = "dialogue/social_check_in/social_wellbeing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.wellbeing",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_neutral",
                ["textDomain"] = "pnc.convo.social.wellbeing.neutral",
                ["textTarget"] = "convo/social/wellbeing/neutral",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
                ["turns"] = {
                    {
                        ["fallback"] = "I'm managing. What did you want to ask?",
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
                                ["labelFallback"] = "How are you holding up?",
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
                                    ["responseTextFallback"] = "I'm still breathing. That's enough for now.",
                                },
                                ["utteranceFallback"] = "How are you holding up?",
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
                                ["labelFallback"] = "Do you need any help?",
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
                                    ["responseTextFallback"] = "I'll manage, but thanks for asking.",
                                },
                                ["utteranceFallback"] = "Do you need any help?",
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
                    },
                },
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
                            ["labelKey"] = "convo.social.wellbeing.neutral.offer.condition.label",
                            ["utteranceFallback"] = "How are you holding up?",
                            ["utteranceKey"] = "convo.social.wellbeing.neutral.offer.condition.utterance",
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
                            ["labelKey"] = "convo.social.wellbeing.neutral.offer.offer_help.label",
                            ["utteranceFallback"] = "Do you need any help?",
                            ["utteranceKey"] = "convo.social.wellbeing.neutral.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm managing. What did you want to ask?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.wellbeing.neutral.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_wellbeing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_check_in",
        ["domainPath"] = "social_check_in",
        ["id"] = "social.wellbeing.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "special",
            ["sourceId"] = "social.wellbeing.special",
            ["sourcePath"] = "dialogue/social_check_in/social_wellbeing_special.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialCheckIn",
        ["namespace"] = "social.wellbeing",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_special",
                ["textDomain"] = "pnc.convo.social.wellbeing.special",
                ["textTarget"] = "convo/social/wellbeing/special",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
                ["turns"] = {
                    {
                        ["fallback"] = "I'll be honest with you, {addressee.name}. Ask.",
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
                                ["labelFallback"] = "How are you really doing?",
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
                                    ["responseTextFallback"] = "Better now that you're here.",
                                },
                                ["utteranceFallback"] = "How are you really doing?",
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
                                ["labelFallback"] = "Let me help.",
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
                                    ["responseTextFallback"] = "All right. Just stay close for a minute.",
                                },
                                ["utteranceFallback"] = "Let me help.",
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
                    },
                },
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
                            ["labelKey"] = "convo.social.wellbeing.special.offer.condition.label",
                            ["utteranceFallback"] = "How are you really doing?",
                            ["utteranceKey"] = "convo.social.wellbeing.special.offer.condition.utterance",
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
                            ["labelKey"] = "convo.social.wellbeing.special.offer.offer_help.label",
                            ["utteranceFallback"] = "Let me help.",
                            ["utteranceKey"] = "convo.social.wellbeing.special.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'll be honest with you, {addressee.name}. Ask.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.wellbeing.special.opening",
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
        ["sourceShard"] = "dialogue/social_check_in/social_wellbeing_special.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
