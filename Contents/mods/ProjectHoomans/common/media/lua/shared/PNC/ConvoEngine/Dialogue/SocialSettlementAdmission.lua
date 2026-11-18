-- Generated; do not edit by hand.
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Join my group.",
                                    },
                                    ["TL"] = {
                                        "Sumali ka sa grupo ko.",
                                    },
                                },
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
                                        ["translations"] = {
                                            ["EN"] = {
                                                "Alright, I'll join you.",
                                            },
                                            ["TL"] = {
                                                "Sige, sasama ako sa iyo.",
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
                                        ["translations"] = {
                                            ["EN"] = {
                                                "I'm already with your group.",
                                            },
                                            ["TL"] = {
                                                "Kasama na ako sa grupo mo.",
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
                                        ["fallback"] = "Not a chance.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
                                        ["textRole"] = "response",
                                        ["translations"] = {
                                            ["EN"] = {
                                                "Not a chance.",
                                            },
                                            ["TL"] = {
                                                "Hindi maaari.",
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
                    ["fallback"] = "Join my group.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.recruitment.offer.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Join my group.",
                        },
                        ["TL"] = {
                            "Sumali ka sa grupo ko.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, I'll join you.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.accepted.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Alright, I'll join you.",
                        },
                        ["TL"] = {
                            "Sige, sasama ako sa iyo.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm already with your group.",
                    ["outcome"] = "already_member",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.already_member.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm already with your group.",
                        },
                        ["TL"] = {
                            "Kasama na ako sa grupo mo.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Not a chance.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Not a chance.",
                        },
                        ["TL"] = {
                            "Hindi maaari.",
                        },
                    },
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
                                        ["id"] = "default",
                                        ["text"] = {
                                            ["EN"] = {
                                                "Alright, I'll join you.",
                                            },
                                            ["TL"] = {
                                                "Sige, sasama ako sa iyo.",
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
                                        ["id"] = "default",
                                        ["text"] = {
                                            ["EN"] = {
                                                "I'm already with your group.",
                                            },
                                            ["TL"] = {
                                                "Kasama na ako sa grupo mo.",
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
                                                "Not a chance.",
                                            },
                                            ["TL"] = {
                                                "Hindi maaari.",
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
                                        "Join my group.",
                                    },
                                    ["TL"] = {
                                        "Sumali ka sa grupo ko.",
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
                ["translations"] = {
                    ["EN"] = {
                        "Join my group.",
                    },
                    ["TL"] = {
                        "Sumali ka sa grupo ko.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, I'll join you.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.accepted.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Alright, I'll join you.",
                    },
                    ["TL"] = {
                        "Sige, sasama ako sa iyo.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm already with your group.",
                ["outcome"] = "already_member",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.already_member.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "I'm already with your group.",
                    },
                    ["TL"] = {
                        "Kasama na ako sa grupo mo.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Not a chance.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.recruitment.offer.reply.rejected.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Not a chance.",
                    },
                    ["TL"] = {
                        "Hindi maaari.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                                    },
                                    ["TL"] = {
                                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                            "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                        },
                        ["TL"] = {
                            "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                            "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                            "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "social.settlement_admission",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "settlement_admission",
            ["sourceId"] = "social.settlement_admission",
            ["sourcePath"] = "dialogue/social_settlement_admission/social_settlement_admission.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
                        ["key"] = "opening.001",
                        ["text"] = {
                            ["EN"] = "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                            ["TL"] = "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                        },
                    },
                    {
                        ["key"] = "opening.002",
                        ["text"] = {
                            ["EN"] = "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                            ["TL"] = "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                        },
                    },
                    {
                        ["key"] = "opening.003",
                        ["text"] = {
                            ["EN"] = "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                            ["TL"] = "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                        },
                    },
                    {
                        ["key"] = "response.settlement_admission.accepted.1",
                        ["text"] = {
                            ["EN"] = "Thank you. I thought I would have to keep walking until there was nowhere left to go.",
                            ["TL"] = "salamat po. Naisip ko na kailangan kong magpatuloy sa paglalakad hanggang sa wala na akong mapupuntahan.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                                    },
                                    ["TL"] = {
                                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
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
                ["translations"] = {
                    ["EN"] = {
                        "Please… let me stay. We have been walking for days, and I do not know how much longer the others can keep going.",
                        "I am not asking for much. A roof, a meal, and a chance to be useful. Please let us join you.",
                        "You have a settlement. We have nothing left but each other. If there is room, I will work for it.",
                    },
                    ["TL"] = {
                        "Please... hayaan mo akong manatili. Ilang araw na kaming naglalakad, at hindi ko alam kung gaano katagal kayang magpatuloy ang iba.",
                        "Hindi ako humihingi ng marami. Isang bubong, isang pagkain, at isang pagkakataon na maging kapaki-pakinabang. Mangyaring hayaan mo kaming samahan ka.",
                        "You have a pamayanan. We have nothing left but each other. If there is room, I will trabaho for it.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Claim this area as our territory.",
                                    },
                                    ["TL"] = {
                                        "Itakda natin ang lugar na ito bilang teritoryo natin.",
                                    },
                                },
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
                                        ["translations"] = {
                                            ["EN"] = {
                                                "Territory marked.",
                                            },
                                            ["TL"] = {
                                                "Naitakda na ang teritoryo.",
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
                                        ["translations"] = {
                                            ["EN"] = {
                                                "I don't belong to your settlement.",
                                            },
                                            ["TL"] = {
                                                "Hindi ako kabilang sa settlement mo.",
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
                    ["fallback"] = "Claim this area as our territory.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.territory.set.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Claim this area as our territory.",
                        },
                        ["TL"] = {
                            "Itakda natin ang lugar na ito bilang teritoryo natin.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Territory marked.",
                    ["outcome"] = "accepted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.territory.set.reply.accepted.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Territory marked.",
                        },
                        ["TL"] = {
                            "Naitakda na ang teritoryo.",
                        },
                    },
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I don't belong to your settlement.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.territory.set.reply.blocked.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "I don't belong to your settlement.",
                        },
                        ["TL"] = {
                            "Hindi ako kabilang sa settlement mo.",
                        },
                    },
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
                                        ["id"] = "default",
                                        ["text"] = {
                                            ["EN"] = {
                                                "Territory marked.",
                                            },
                                            ["TL"] = {
                                                "Naitakda na ang teritoryo.",
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
                                        ["id"] = "default",
                                        ["text"] = {
                                            ["EN"] = {
                                                "I don't belong to your settlement.",
                                            },
                                            ["TL"] = {
                                                "Hindi ako kabilang sa settlement mo.",
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
                                        "Claim this area as our territory.",
                                    },
                                    ["TL"] = {
                                        "Itakda natin ang lugar na ito bilang teritoryo natin.",
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
                ["translations"] = {
                    ["EN"] = {
                        "Claim this area as our territory.",
                    },
                    ["TL"] = {
                        "Itakda natin ang lugar na ito bilang teritoryo natin.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Territory marked.",
                ["outcome"] = "accepted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.territory.set.reply.accepted.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Territory marked.",
                    },
                    ["TL"] = {
                        "Naitakda na ang teritoryo.",
                    },
                },
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I don't belong to your settlement.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.territory.set.reply.blocked.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "I don't belong to your settlement.",
                    },
                    ["TL"] = {
                        "Hindi ako kabilang sa settlement mo.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
