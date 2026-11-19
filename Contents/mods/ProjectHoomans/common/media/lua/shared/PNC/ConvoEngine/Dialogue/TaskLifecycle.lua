-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift",
            ["replies"] = {
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Thank you for the gift.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.gift.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't accept that gift.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.gift.reply.failed.say.1.default",
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
                ["pending"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "pending",
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
                                        ["fallback"] = "I'll take a look at that gift.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.gift.reply.pending.say.1.default",
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
                                        ["fallback"] = "I can't accept that gift right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.gift.reply.rejected.say.1.default",
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
                ["selection_required"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "selection_required",
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
                                        ["fallback"] = "I need to see what you brought me first.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.gift.reply.selection_required.say.1.default",
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
                    ["fallback"] = "Thank you for the gift.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.gift.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't accept that gift.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.gift.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll take a look at that gift.",
                    ["outcome"] = "pending",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.gift.reply.pending.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't accept that gift right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.gift.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I need to see what you brought me first.",
                    ["outcome"] = "selection_required",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.gift.reply.selection_required.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "gift",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["sourceId"] = "gift",
            ["sourcePath"] = "dialogue/task_lifecycle/gift.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Thank you for the gift.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't accept that gift.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["pending"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "pending",
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
                                        ["fallback"] = "I'll take a look at that gift.",
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
                                        ["fallback"] = "I can't accept that gift right now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["selection_required"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "selection_required",
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
                                        ["fallback"] = "I need to see what you brought me first.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/gift.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thank you for the gift.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.gift.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't accept that gift.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.gift.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll take a look at that gift.",
                ["outcome"] = "pending",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.gift.reply.pending.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't accept that gift right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.gift.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I need to see what you brought me first.",
                ["outcome"] = "selection_required",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.gift.reply.selection_required.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "I'm using that now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.consume.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll use that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.consume.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "That's done.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.consume.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't use that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.consume.reply.failed.say.1.default",
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
                                        ["fallback"] = "I can't use that right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.consume.reply.rejected.say.1.default",
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
                    ["fallback"] = "I'm using that now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.consume.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll use that.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.consume.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "That's done.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.consume.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't use that.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.consume.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't use that right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.consume.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.consume",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "consume",
            ["sourceId"] = "task.consume",
            ["sourcePath"] = "dialogue/task_lifecycle/task_consume.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "I'm using that now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll use that.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "That's done.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't use that.",
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
                                        ["fallback"] = "I can't use that right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_consume.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm using that now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.consume.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll use that.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.consume.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "That's done.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.consume.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't use that.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.consume.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't use that right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.consume.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Taking a drink now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.drink.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll have a drink.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.drink.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Much better. Thirst is gone.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.drink.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't get a drink.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.drink.reply.failed.say.1.default",
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
                                        ["fallback"] = "I'm not thirsty right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.drink.reply.rejected.say.1.default",
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
                    ["fallback"] = "Taking a drink now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.drink.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll have a drink.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.drink.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Much better. Thirst is gone.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.drink.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't get a drink.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.drink.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm not thirsty right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.drink.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.drink",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "drink",
            ["sourceId"] = "task.drink",
            ["sourcePath"] = "dialogue/task_lifecycle/task_drink.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Taking a drink now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll have a drink.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Much better. Thirst is gone.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't get a drink.",
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
                                        ["fallback"] = "I'm not thirsty right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_drink.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Taking a drink now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.drink.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll have a drink.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.drink.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Much better. Thirst is gone.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.drink.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't get a drink.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.drink.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm not thirsty right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.drink.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Eating now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.eat.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll eat that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.eat.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Finished eating. Feeling much better.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.eat.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't eat that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.eat.reply.failed.say.1.default",
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
                                        ["fallback"] = "I'm not hungry right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.eat.reply.rejected.say.1.default",
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
                    ["fallback"] = "Eating now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.eat.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll eat that.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.eat.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Finished eating. Feeling much better.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.eat.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't eat that.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.eat.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm not hungry right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.eat.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.eat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "eat",
            ["sourceId"] = "task.eat",
            ["sourcePath"] = "dialogue/task_lifecycle/task_eat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Eating now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll eat that.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Finished eating. Feeling much better.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't eat that.",
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
                                        ["fallback"] = "I'm not hungry right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_eat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Eating now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.eat.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll eat that.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.eat.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Finished eating. Feeling much better.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.eat.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't eat that.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.eat.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm not hungry right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.eat.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "I'm working on that now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.fetch.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll fetch that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.fetch.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Here you go.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.fetch.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't fetch that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.fetch.reply.failed.say.1.default",
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
                                        ["fallback"] = "I can't fetch that right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.fetch.reply.rejected.say.1.default",
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
                    ["fallback"] = "I'm working on that now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.fetch.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll fetch that.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.fetch.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Here you go.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.fetch.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't fetch that.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.fetch.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't fetch that right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.fetch.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.fetch",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "fetch",
            ["sourceId"] = "task.fetch",
            ["sourcePath"] = "dialogue/task_lifecycle/task_fetch.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "I'm working on that now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll fetch that.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Here you go.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't fetch that.",
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
                                        ["fallback"] = "I can't fetch that right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_fetch.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm working on that now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.fetch.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll fetch that.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.fetch.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Here you go.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.fetch.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't fetch that.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.fetch.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't fetch that right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.fetch.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Handing that over now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.give.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll give that to you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.give.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "There you go.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.give.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't give that to you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.give.reply.failed.say.1.default",
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
                                        ["fallback"] = "I can't give that to you right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.give.reply.rejected.say.1.default",
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
                    ["fallback"] = "Handing that over now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.give.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll give that to you.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.give.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "There you go.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.give.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't give that to you.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.give.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't give that to you right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.give.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.give",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "give",
            ["sourceId"] = "task.give",
            ["sourcePath"] = "dialogue/task_lifecycle/task_give.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Handing that over now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll give that to you.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "There you go.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't give that to you.",
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
                                        ["fallback"] = "I can't give that to you right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_give.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Handing that over now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.give.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll give that to you.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.give.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "There you go.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.give.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't give that to you.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.give.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't give that to you right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.give.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Refilling the container now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.refill.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll refill that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.refill.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "All topped off. Container is full.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.refill.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't refill that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.refill.reply.failed.say.1.default",
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
                                        ["fallback"] = "I can't refill that right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.refill.reply.rejected.say.1.default",
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
                    ["fallback"] = "Refilling the container now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.refill.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll refill that.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.refill.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "All topped off. Container is full.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.refill.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't refill that.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.refill.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't refill that right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.refill.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.refill",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "refill",
            ["sourceId"] = "task.refill",
            ["sourcePath"] = "dialogue/task_lifecycle/task_refill.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Refilling the container now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "I'll refill that.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "All topped off. Container is full.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't refill that.",
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
                                        ["fallback"] = "I can't refill that right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_refill.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Refilling the container now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.refill.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll refill that.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.refill.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "All topped off. Container is full.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.refill.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't refill that.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.refill.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't refill that right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.refill.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["domainPath"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.wait_at",
            ["namespace"] = "task",
            ["replies"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Waiting here now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.wait_at.reply.active.say.1.default",
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
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "Okay, I'll wait there.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.wait_at.reply.admitted.say.1.default",
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
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Finished waiting.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.wait_at.reply.completed.say.1.default",
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
                                        ["fallback"] = "I couldn't wait there.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.wait_at.reply.failed.say.1.default",
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
                                        ["fallback"] = "I can't wait there right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.task.wait_at.reply.rejected.say.1.default",
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
                    ["fallback"] = "Waiting here now.",
                    ["outcome"] = "active",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.wait_at.reply.active.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll wait there.",
                    ["outcome"] = "admitted",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.wait_at.reply.admitted.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Finished waiting.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.wait_at.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't wait there.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.wait_at.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I can't wait there right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.task.wait_at.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "task.wait_at",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wait_at",
            ["sourceId"] = "task.wait_at",
            ["sourcePath"] = "dialogue/task_lifecycle/task_wait_at.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
            },
            ["reply"] = {
                ["active"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "active",
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
                                        ["fallback"] = "Waiting here now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["admitted"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "admitted",
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
                                        ["fallback"] = "Okay, I'll wait there.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["completed"] = {
                    ["act"] = "REACT",
                    ["outcome"] = "completed",
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
                                        ["fallback"] = "Finished waiting.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                        ["fallback"] = "I couldn't wait there.",
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
                                        ["fallback"] = "I can't wait there right now.",
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
        ["sourceShard"] = "dialogue/task_lifecycle/task_wait_at.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Waiting here now.",
                ["outcome"] = "active",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.wait_at.reply.active.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll wait there.",
                ["outcome"] = "admitted",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.wait_at.reply.admitted.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Finished waiting.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.wait_at.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't wait there.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.wait_at.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I can't wait there right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.task.wait_at.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
