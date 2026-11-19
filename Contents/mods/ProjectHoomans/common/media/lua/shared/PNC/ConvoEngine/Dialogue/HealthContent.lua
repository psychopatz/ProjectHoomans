-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["domainPath"] = "health_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.health_state",
            ["namespace"] = "question",
            ["replies"] = {
                ["healthy"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "healthy",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm doing okay.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.health_state.reply.healthy.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm fine. Don't make a thing of it.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.health_state.reply.healthy.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm okay.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.health_state.reply.healthy.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm doing okay. Thanks for checking in.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.health_state.reply.healthy.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["injured"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "injured",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm hurt, but I'm managing.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.health_state.reply.injured.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm hurt. Give me space.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.health_state.reply.injured.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm hurt.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.health_state.reply.injured.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm hurt, but I'm managing. Thanks for asking.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.health_state.reply.injured.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "unknown",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I can't confirm my health status right now.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.health_state.reply.unknown.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I can't confirm that.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.health_state.reply.unknown.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Can't confirm.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.health_state.reply.unknown.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I can't confirm it right now, but thanks for asking.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.health_state.reply.unknown.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
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
                    ["fallback"] = "I'm doing okay.",
                    ["outcome"] = "healthy",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.healthy.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm fine. Don't make a thing of it.",
                    ["outcome"] = "healthy",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.healthy.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "I'm okay.",
                    ["outcome"] = "healthy",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.healthy.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm doing okay. Thanks for checking in.",
                    ["outcome"] = "healthy",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.healthy.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "I'm hurt, but I'm managing.",
                    ["outcome"] = "injured",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.injured.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm hurt. Give me space.",
                    ["outcome"] = "injured",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.injured.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "I'm hurt.",
                    ["outcome"] = "injured",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.injured.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm hurt, but I'm managing. Thanks for asking.",
                    ["outcome"] = "injured",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.injured.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "I can't confirm my health status right now.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I can't confirm that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.unknown.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Can't confirm.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.unknown.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I can't confirm it right now, but thanks for asking.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.health_state.reply.unknown.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.health_state",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "health_state",
            ["sourceId"] = "question.health_state",
            ["sourcePath"] = "dialogue/health_content/question_health_state.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "question",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["healthy"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "healthy",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm doing okay.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I'm fine. Don't make a thing of it.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "I'm okay.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I'm doing okay. Thanks for checking in.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["injured"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "injured",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm hurt, but I'm managing.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I'm hurt. Give me space.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "I'm hurt.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I'm hurt, but I'm managing. Thanks for asking.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "unknown",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I can't confirm my health status right now.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I can't confirm that.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "Can't confirm.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I can't confirm it right now, but thanks for asking.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
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
        ["sourceShard"] = "dialogue/health_content/question_health_state.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm doing okay.",
                ["outcome"] = "healthy",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.healthy.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm fine. Don't make a thing of it.",
                ["outcome"] = "healthy",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.healthy.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "I'm okay.",
                ["outcome"] = "healthy",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.healthy.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm doing okay. Thanks for checking in.",
                ["outcome"] = "healthy",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.healthy.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "I'm hurt, but I'm managing.",
                ["outcome"] = "injured",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.injured.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm hurt. Give me space.",
                ["outcome"] = "injured",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.injured.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "I'm hurt.",
                ["outcome"] = "injured",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.injured.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm hurt, but I'm managing. Thanks for asking.",
                ["outcome"] = "injured",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.injured.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "I can't confirm my health status right now.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I can't confirm that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.unknown.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Can't confirm.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.unknown.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I can't confirm it right now, but thanks for asking.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.health_state.reply.unknown.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["domainPath"] = "health_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.medical_bite",
            ["namespace"] = "question",
            ["replies"] = {
                ["negative"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "negative",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "No, I don't have a recorded bite.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "No bite. Leave it there.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "No bite.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "No, I don't have a recorded bite. Thanks for checking.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["positive"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "positive",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "Yes, I've been bitten.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten. That's all.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten, and I appreciate you checking.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "unknown",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I can't confirm whether I've been bitten.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I can't confirm that. Don't press me.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Can't confirm.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I can't confirm it, but thanks for checking.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
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
                    ["fallback"] = "No, I don't have a recorded bite.",
                    ["outcome"] = "negative",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No bite. Leave it there.",
                    ["outcome"] = "negative",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "No bite.",
                    ["outcome"] = "negative",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "No, I don't have a recorded bite. Thanks for checking.",
                    ["outcome"] = "negative",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "Yes, I've been bitten.",
                    ["outcome"] = "positive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Yes. I've been bitten. That's all.",
                    ["outcome"] = "positive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Yes. I've been bitten.",
                    ["outcome"] = "positive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Yes. I've been bitten, and I appreciate you checking.",
                    ["outcome"] = "positive",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "I can't confirm whether I've been bitten.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I can't confirm that. Don't press me.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Can't confirm.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I can't confirm it, but thanks for checking.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.medical_bite",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "medical_bite",
            ["sourceId"] = "question.medical_bite",
            ["sourcePath"] = "dialogue/health_content/question_medical_bite.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "question",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["negative"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "negative",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "No, I don't have a recorded bite.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "No bite. Leave it there.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "No bite.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "No, I don't have a recorded bite. Thanks for checking.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["positive"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "positive",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "Yes, I've been bitten.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten. That's all.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "Yes. I've been bitten, and I appreciate you checking.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "unknown",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I can't confirm whether I've been bitten.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I can't confirm that. Don't press me.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "Can't confirm.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I can't confirm it, but thanks for checking.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
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
        ["sourceShard"] = "dialogue/health_content/question_medical_bite.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No, I don't have a recorded bite.",
                ["outcome"] = "negative",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No bite. Leave it there.",
                ["outcome"] = "negative",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "No bite.",
                ["outcome"] = "negative",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "No, I don't have a recorded bite. Thanks for checking.",
                ["outcome"] = "negative",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.negative.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "Yes, I've been bitten.",
                ["outcome"] = "positive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Yes. I've been bitten. That's all.",
                ["outcome"] = "positive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Yes. I've been bitten.",
                ["outcome"] = "positive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Yes. I've been bitten, and I appreciate you checking.",
                ["outcome"] = "positive",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.positive.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "I can't confirm whether I've been bitten.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I can't confirm that. Don't press me.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Can't confirm.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I can't confirm it, but thanks for checking.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.medical_bite.reply.unknown.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
