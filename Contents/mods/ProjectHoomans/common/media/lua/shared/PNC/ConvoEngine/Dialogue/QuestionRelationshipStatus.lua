-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question_relationship_status",
        ["domainPath"] = "question_relationship_status",
        ["exchangeFamily"] = {
            ["familyID"] = "question.relationship_status.responses",
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
                                ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's kind of you to ask. I don't have a clear answer right now.",
                                    },
                                    ["TL"] = {
                                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.relationship_status",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's kind of you to ask. I don't have a clear answer right now.",
                        },
                        ["TL"] = {
                            "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.relationship_status.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "question.relationship_status.responses",
            ["sourcePath"] = "dialogue/question_relationship_status/question_relationship_status.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestionRelationshipStatus",
        ["namespace"] = "question.relationship_status",
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
                    ["domain"] = "settlement_relationship",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterCompliment",
                        ["text"] = {
                            ["EN"] = "That's kind of you to ask. I don't have a clear answer right now.",
                            ["TL"] = "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentAlt",
                        ["text"] = {
                            ["EN"] = "Thanks for saying that. I can't give you a clear answer about relationships right now.",
                            ["TL"] = "Salamat sa sinabi mo. Hindi ko pa masagot nang malinaw ang tungkol sa relasyon ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentCommitted",
                        ["text"] = {
                            ["EN"] = "Thanks for the compliment, but I thought we were already together.",
                            ["TL"] = "Salamat sa papuri, pero akala ko tayo na.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentWithdrawn",
                        ["text"] = {
                            ["EN"] = "Thanks, but I'd rather keep that personal.",
                            ["TL"] = "Salamat, pero mas gusto kong sarilinin muna iyan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusCommitted",
                        ["text"] = {
                            ["EN"] = "I thought we were already together.",
                            ["TL"] = "Akala ko tayo na.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertain",
                        ["text"] = {
                            ["EN"] = "I haven't really thought about dating. Right now, I'm focused on surviving.",
                            ["TL"] = "Hindi ko pa talaga naiisip ang makipag-date. Mas iniisip ko muna kung paano makakaligtas.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertainAlt",
                        ["text"] = {
                            ["EN"] = "Honestly, I haven't had much room to think about relationships lately.",
                            ["TL"] = "Sa totoo lang, wala akong gaanong panahon para isipin ang tungkol sa relasyon ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusWithdrawn",
                        ["text"] = {
                            ["EN"] = "I'd rather not get into that. There's too much going on right now.",
                            ["TL"] = "Mas gusto kong huwag munang pag-usapan iyan. Marami pa tayong pinagdaraanan ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledged",
                        ["text"] = {
                            ["EN"] = "Thanks for understanding. It's hard to think about relationships with everything going on.",
                            ["TL"] = "Salamat sa pag-unawa. Mahirap isipin ang relasyon sa dami ng nangyayari ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedAlt",
                        ["text"] = {
                            ["EN"] = "I appreciate you listening. It's hard to make plans while we're trying to survive.",
                            ["TL"] = "Salamat sa pakikinig. Mahirap magplano habang sinusubukan nating mabuhay.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedWithdrawn",
                        ["text"] = {
                            ["EN"] = "Thanks. I'd rather leave it there for now.",
                            ["TL"] = "Salamat. Mas gusto kong hanggang dito na lang muna.",
                        },
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
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
                                        "That's kind of you to ask. I don't have a clear answer right now.",
                                    },
                                    ["TL"] = {
                                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
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
                    ["domain"] = "settlement_relationship",
                    ["id"] = "relationship",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.relationship_status.responses",
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
                            ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.relationship_status.responses.say_1",
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
        ["sourceShard"] = "dialogue/question_relationship_status/question_relationship_status.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's kind of you to ask. I don't have a clear answer right now.",
                    },
                    ["TL"] = {
                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "question_relationship_status",
        ["domainPath"] = "question_relationship_status",
        ["exchangeFamily"] = {
            ["familyID"] = "social.relationship.proposal",
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
                                ["fallback"] = "Be my partner.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.relationship.proposal.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Be my partner.",
                                    },
                                    ["TL"] = {
                                        "Maging kapareha kita.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "RELATIONSHIP_PROPOSAL",
                ["intent"] = "REQUEST",
            },
            ["namespace"] = "social.relationship",
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
                                        ["fallback"] = "Yes, I want that too.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.relationship.proposal.reply.accepted.say.1.default",
                                        ["textRole"] = "response",
                                        ["translations"] = {
                                            ["EN"] = {
                                                "Yes, I want that too.",
                                            },
                                            ["TL"] = {
                                                "Oo, gusto ko rin iyon.",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_partner"] = {
                    ["outcome"] = "already_partner",
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
                                        ["fallback"] = "We're already together.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.relationship.proposal.reply.already_partner.say.1.default",
                                        ["textRole"] = "response",
                                        ["translations"] = {
                                            ["EN"] = {
                                                "We're already together.",
                                            },
                                            ["TL"] = {
                                                "Magkasama na tayo.",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["outcome"] = "rejected",
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
                                        ["fallback"] = "I'm not ready for that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.relationship.proposal.reply.rejected.say.1.default",
                                        ["textRole"] = "response",
                                        ["translations"] = {
                                            ["EN"] = {
                                                "I'm not ready for that.",
                                            },
                                            ["TL"] = {
                                                "Hindi pa ako handa para diyan.",
                                            },
                                        },
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
                    ["fallback"] = "Be my partner.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.relationship.proposal.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Be my partner.",
                        },
                        ["TL"] = {
                            "Maging kapareha kita.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Yes, I want that too.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.relationship.proposal.reply.accepted.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Yes, I want that too.",
                        },
                        ["TL"] = {
                            "Oo, gusto ko rin iyon.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "We're already together.",
                    ["outcome"] = "already_partner",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.relationship.proposal.reply.already_partner.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "We're already together.",
                        },
                        ["TL"] = {
                            "Magkasama na tayo.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm not ready for that.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.relationship.proposal.reply.rejected.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not ready for that.",
                        },
                        ["TL"] = {
                            "Hindi pa ako handa para diyan.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.relationship.proposal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "proposal",
            ["sourceId"] = "social.relationship.proposal",
            ["sourcePath"] = "dialogue/question_relationship_status/social_relationship_proposal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestionRelationshipStatus",
        ["namespace"] = "social.relationship",
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
                ["closureClass"] = "state_transition",
            },
            ["domains"] = {
                {
                    ["domain"] = "settlement_relationship",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["invoke"] = {
                ["action"] = "RELATIONSHIP_PROPOSAL",
                ["intent"] = "REQUEST",
            },
            ["postconditions"] = {
                "relationship.partner_accepted",
            },
            ["repeatPolicy"] = "state_retired",
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
                                        ["id"] = "default",
                                        ["text"] = {
                                            ["EN"] = {
                                                "Yes, I want that too.",
                                            },
                                            ["TL"] = {
                                                "Oo, gusto ko rin iyon.",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_partner"] = {
                    ["outcome"] = "already_partner",
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
                                                "We're already together.",
                                            },
                                            ["TL"] = {
                                                "Magkasama na tayo.",
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["outcome"] = "rejected",
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
                                                "I'm not ready for that.",
                                            },
                                            ["TL"] = {
                                                "Hindi pa ako handa para diyan.",
                                            },
                                        },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Be my partner.",
                                    },
                                    ["TL"] = {
                                        "Maging kapareha kita.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "already_partner",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_partner",
                    ["replyOutcome"] = "already_partner",
                    ["when"] = {
                        ["op"] = "in",
                        ["path"] = "relationship.state",
                        ["values"] = {
                            "lover",
                            "partner",
                            "spouse",
                        },
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
                    ["domain"] = "settlement_relationship",
                    ["id"] = "relationship",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.relationship.proposal",
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
                            ["fallback"] = "Be my partner.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.relationship.proposal.say_1",
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
        ["sourceShard"] = "dialogue/question_relationship_status/social_relationship_proposal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Be my partner.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.relationship.proposal.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Be my partner.",
                    },
                    ["TL"] = {
                        "Maging kapareha kita.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Yes, I want that too.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.relationship.proposal.reply.accepted.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Yes, I want that too.",
                    },
                    ["TL"] = {
                        "Oo, gusto ko rin iyon.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "We're already together.",
                ["outcome"] = "already_partner",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.relationship.proposal.reply.already_partner.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "We're already together.",
                    },
                    ["TL"] = {
                        "Magkasama na tayo.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm not ready for that.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.relationship.proposal.reply.rejected.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not ready for that.",
                    },
                    ["TL"] = {
                        "Hindi pa ako handa para diyan.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
