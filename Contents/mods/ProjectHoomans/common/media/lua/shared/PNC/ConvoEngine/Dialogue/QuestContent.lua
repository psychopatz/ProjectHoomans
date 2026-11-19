-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["domainPath"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.accept",
            ["namespace"] = "quest.clinic_supplies",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't accept that request.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.accept.reply.failed.say.1.default",
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
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll bring the clinic supplies.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.accept.reply.queued.say.1.default",
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
                ["rejected"] = {
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't accept that request right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.accept.reply.rejected.say.1.default",
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
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't accept that request.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll bring the clinic supplies.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.reply.queued.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't accept that request right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.accept",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "accept",
            ["sourceId"] = "quest.clinic_supplies.accept",
            ["sourcePath"] = "dialogue/quest_content/quest_clinic_supplies_accept.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies",
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
                    ["domain"] = "quest",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't accept that request.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll bring the clinic supplies.",
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
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't accept that request right now.",
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
            ["topics"] = {
                {
                    ["domain"] = "quest",
                    ["id"] = "quest",
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/quest_content/quest_clinic_supplies_accept.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't accept that request.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.accept.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll bring the clinic supplies.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.accept.reply.queued.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't accept that request right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.accept.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["domainPath"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.offer",
            ["namespace"] = "quest.clinic_supplies",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't check that clinic-supplies request.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.offer.reply.failed.say.1.default",
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
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I can help with the clinic supplies.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.offer.reply.queued.say.1.default",
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
                ["rejected"] = {
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't take that clinic-supplies request right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.offer.reply.rejected.say.1.default",
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
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't check that clinic-supplies request.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can help with the clinic supplies.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.reply.queued.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't take that clinic-supplies request right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "offer",
            ["sourceId"] = "quest.clinic_supplies.offer",
            ["sourcePath"] = "dialogue/quest_content/quest_clinic_supplies_offer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies",
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
                    ["domain"] = "quest",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't check that clinic-supplies request.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I can help with the clinic supplies.",
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
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't take that clinic-supplies request right now.",
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
            ["topics"] = {
                {
                    ["domain"] = "quest",
                    ["id"] = "quest",
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/quest_content/quest_clinic_supplies_offer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't check that clinic-supplies request.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.offer.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can help with the clinic supplies.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.offer.reply.queued.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't take that clinic-supplies request right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.offer.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["domainPath"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.status",
            ["namespace"] = "quest.clinic_supplies",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't check that request.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.status.reply.failed.say.1.default",
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
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll check the clinic-supplies request.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.status.reply.queued.say.1.default",
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
                ["rejected"] = {
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't check that request right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.status.reply.rejected.say.1.default",
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
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't check that request.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.status.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll check the clinic-supplies request.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.status.reply.queued.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't check that request right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.status.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.status",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "status",
            ["sourceId"] = "quest.clinic_supplies.status",
            ["sourcePath"] = "dialogue/quest_content/quest_clinic_supplies_status.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies",
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
                    ["domain"] = "quest",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't check that request.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll check the clinic-supplies request.",
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
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't check that request right now.",
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
            ["topics"] = {
                {
                    ["domain"] = "quest",
                    ["id"] = "quest",
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/quest_content/quest_clinic_supplies_status.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't check that request.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.status.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll check the clinic-supplies request.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.status.reply.queued.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't check that request right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.status.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["domainPath"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.turn_in",
            ["namespace"] = "quest.clinic_supplies",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't turn in the clinic supplies.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.failed.say.1.default",
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
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll turn in the clinic supplies.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.queued.say.1.default",
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
                ["rejected"] = {
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't turn that in yet.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.rejected.say.1.default",
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
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't turn in the clinic supplies.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll turn in the clinic supplies.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.queued.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't turn that in yet.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.turn_in",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "turn_in",
            ["sourceId"] = "quest.clinic_supplies.turn_in",
            ["sourcePath"] = "dialogue/quest_content/quest_clinic_supplies_turn_in.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies",
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
                    ["domain"] = "quest",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "failed",
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
                                        ["fallback"] = "I couldn't turn in the clinic supplies.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["queued"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "I'll turn in the clinic supplies.",
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
                    ["act"] = "REACT",
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
                                        ["fallback"] = "I can't turn that in yet.",
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
            ["topics"] = {
                {
                    ["domain"] = "quest",
                    ["id"] = "quest",
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/quest_content/quest_clinic_supplies_turn_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't turn in the clinic supplies.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll turn in the clinic supplies.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.queued.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't turn that in yet.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
