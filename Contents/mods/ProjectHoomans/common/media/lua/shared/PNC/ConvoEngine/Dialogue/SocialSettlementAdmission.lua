-- Hand-maintained ProjectHoomans ConvoEngine module.
return {
    {
        ["domain"] = "social_settlement_admission",
        ["domainPath"] = "social_settlement_admission",
        ["exchangeFamily"] = {
            ["familyID"] = "social.recruitment.offer",
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
                                ["fallback"] = "Join my group.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.recruitment.offer.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "RECRUIT",
                ["intent"] = "REQUEST",
            },
            ["namespace"] = "social.recruitment",
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
                                        ["fallback"] = "Alright, I'll join you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.recruitment.offer.reply.accepted.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_member"] = {
                    ["outcome"] = "already_member",
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
                                        ["fallback"] = "I'm already with your group.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.recruitment.offer.reply.already_member.say.1.default",
                                        ["textRole"] = "response",
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
                                        ["fallback"] = "Not a chance.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
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
                    ["fallback"] = "Join my group.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.recruitment.offer.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, I'll join you.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.accepted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm already with your group.",
                    ["outcome"] = "already_member",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.already_member.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Not a chance.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.recruitment.offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "offer",
            ["sourceId"] = "social.recruitment.offer",
            ["sourcePath"] = "dialogue/social_settlement_admission/social_recruitment_offer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialSettlementAdmission",
        ["namespace"] = "social.recruitment",
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
                ["action"] = "RECRUIT",
                ["intent"] = "REQUEST",
            },
            ["postconditions"] = {
                "npc.companion_member",
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
                                        ["fallback"] = "Alright, I'll join you.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["already_member"] = {
                    ["metadata"] = {
                        ["templateID"] = "recruitment.reject.member.1",
                    },
                    ["outcome"] = "already_member",
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
                                        ["fallback"] = "I'm already with your group.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["metadata"] = {
                        ["templateID"] = "recruitment.reject.hostile.1",
                    },
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
                                        ["fallback"] = "Not a chance.",
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
                                ["fallback"] = "Join my group.",
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
                    ["id"] = "already_member",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_member",
                    ["replyOutcome"] = "already_member",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.companion",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.owned",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "no_op",
                    ["id"] = "hostile_or_ineligible",
                    ["outcome"] = "blocked",
                    ["reason"] = "actor_blocked_or_hostile",
                    ["replyOutcome"] = "rejected",
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
                    ["domain"] = "settlement_relationship",
                    ["id"] = "settlement",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.recruitment.offer",
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
                            ["fallback"] = "Join my group.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.recruitment.offer.say_1",
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
        ["sourceShard"] = "dialogue/social_settlement_admission/social_recruitment_offer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Join my group.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.recruitment.offer.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, I'll join you.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.accepted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm already with your group.",
                ["outcome"] = "already_member",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.already_member.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Not a chance.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_settlement_admission",
        ["domainPath"] = "social_settlement_admission",
        ["exchangeFamily"] = {
            ["familyID"] = "social.settlement_admission",
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
                                ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social",
            ["textRoles"] = {
                {
                    ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.settlement_admission",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "settlement_admission",
            ["sourceId"] = "social.settlement_admission",
            ["sourcePath"] = "dialogue/social_settlement_admission/social_settlement_admission.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialSettlementAdmission",
        ["namespace"] = "social",
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
                ["audiences"] = {
                    "neutral",
                    "member",
                    "special",
                },
                ["category"] = "projecthoomans:greetings",
                ["priority"] = 1000,
                ["responseAct"] = "SETTLEMENT_ADMISSION",
                ["runtimeBlockID"] = "projecthoomans:settlement_admission",
                ["textDomain"] = "pnc.convo.social.greetings.settlement_admission.arrival",
                ["textRows"] = {
                    {
                        ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                        ["key"] = "opening.001",
                    },
                    {
                        ["fallback"] = "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                        ["key"] = "opening.002",
                    },
                    {
                        ["fallback"] = "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                        ["key"] = "opening.003",
                    },
                    {
                        ["fallback"] = "Thank you. I thought I would have to keep walking until there was nowhere left to go.",
                        ["key"] = "response.settlement_admission.accepted.1",
                    },
                },
                ["textTarget"] = "convo/social/greetings/settlement_admission/arrival",
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
                                ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
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
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "SETTLEMENT_ADMISSION",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.settlement_admission",
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
                            ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.settlement_admission.say_1",
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
        ["sourceShard"] = "dialogue/social_settlement_admission/social_settlement_admission.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.settlement_admission.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "relationship.settlementVisit.active",
            ["value"] = true,
        },
    },
    {
        ["domain"] = "social_settlement_admission",
        ["domainPath"] = "social_settlement_admission",
        ["exchangeFamily"] = {
            ["familyID"] = "social.territory.set",
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
                                ["fallback"] = "Claim this area as our territory.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.territory.set.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "SET_TERRITORY",
                ["intent"] = "COMMAND",
            },
            ["namespace"] = "social.territory",
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
                                        ["fallback"] = "Territory marked.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.territory.set.reply.accepted.say.1.default",
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
                                        ["fallback"] = "I don't belong to your settlement.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.territory.set.reply.blocked.say.1.default",
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
                    ["fallback"] = "Claim this area as our territory.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.territory.set.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Territory marked.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.territory.set.reply.accepted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I don't belong to your settlement.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.territory.set.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.territory.set",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "set",
            ["sourceId"] = "social.territory.set",
            ["sourcePath"] = "dialogue/social_settlement_admission/social_territory_set.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialSettlementAdmission",
        ["namespace"] = "social.territory",
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
                ["action"] = "SET_TERRITORY",
                ["intent"] = "COMMAND",
            },
            ["postconditions"] = {
                "settlement.territory_updated",
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
                                        ["fallback"] = "Territory marked.",
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
                                        ["fallback"] = "I don't belong to your settlement.",
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
                                ["fallback"] = "Claim this area as our territory.",
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
                    ["id"] = "not_member",
                    ["outcome"] = "blocked",
                    ["reason"] = "not_settlement_member",
                    ["replyOutcome"] = "blocked",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "roles.companion",
                        ["value"] = false,
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
                    ["id"] = "settlement",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.territory.set",
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
                            ["fallback"] = "Claim this area as our territory.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.territory.set.say_1",
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
        ["sourceShard"] = "dialogue/social_settlement_admission/social_territory_set.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Claim this area as our territory.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.territory.set.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Territory marked.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.territory.set.reply.accepted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I don't belong to your settlement.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.territory.set.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
