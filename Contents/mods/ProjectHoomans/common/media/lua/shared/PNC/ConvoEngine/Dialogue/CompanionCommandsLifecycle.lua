-- Hand-maintained ProjectHoomans ConvoEngine module.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["domainPath"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "companion",
                    "command",
                    "camp",
                },
                ["labelFallback"] = "Set up camp",
                ["labelKey"] = "convo.command.camp.affordance.label",
                ["metadata"] = {
                    ["action"] = "CAMP",
                },
                ["textRole"] = "button_label",
            },
            ["bindings"] = {
                ["camp.locationPhrase"] = {
                    ["from"] = "result.data.site",
                    ["resolver"] = "pnc.camp.location_phrase",
                    ["type"] = "entity.location",
                },
            },
            ["execute"] = {
                ["mode"] = "request_response",
                ["use"] = "pnc.companion.camp",
                ["with"] = {
                    ["npcID"] = "$context.addressee.id",
                    ["target"] = "$slot.camp_site",
                },
            },
            ["familyID"] = "command.camp",
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
                                ["fallback"] = "Let's camp here.",
                                ["id"] = "default",
                                ["templateID"] = "convo.command.camp.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "CAMP",
                ["intent"] = "COMMAND",
            },
            ["namespace"] = "command",
            ["replies"] = {
                ["completed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "We're set up {camp.locationPhrase}.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.completed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't set up camp there.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.failed.say.1.default",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I'll head {camp.locationPhrase} and set up camp.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.pending.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["queued"] = {
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll set up camp there.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.command.camp.reply.queued.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll set up camp there. Sounds cozy.",
                                        ["id"] = "friendly",
                                        ["templateID"] = "convo.command.camp.reply.queued.say.1.friendly",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm still setting up camp there.",
                                        ["id"] = "repeated",
                                        ["templateID"] = "convo.command.camp.reply.queued.say.1.repeated",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "All right, I'll make camp there.",
                                        ["id"] = "trusted",
                                        ["templateID"] = "convo.command.camp.reply.queued.say.1.trusted",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'll set up camp there.",
                                        ["id"] = "withdrawn",
                                        ["templateID"] = "convo.command.camp.reply.queued.say.1.withdrawn",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't set up camp there right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.rejected.say.1.default",
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
                ["rejected_no_site"] = {
                    ["act"] = "REPLY",
                    ["outcome"] = "rejected_no_site",
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
                                        ["fallback"] = "I don't see a safe place to camp nearby.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.rejected_no_site.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "result.reasonClass",
                        ["value"] = "target_unavailable",
                    },
                },
                ["rejected_out_of_range"] = {
                    ["act"] = "REPLY",
                    ["outcome"] = "rejected_out_of_range",
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
                                        ["fallback"] = "That camp location is too far away right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.camp.reply.rejected_out_of_range.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "result.reasonClass",
                        ["value"] = "out_of_range",
                    },
                },
            },
            ["slots"] = {
                ["camp_site"] = {
                    ["limit"] = 4,
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["suggest"] = "camp_site_candidates",
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Set up camp",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.command.camp.affordance.label",
                },
                {
                    ["fallback"] = "Let's camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.camp.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "We're set up {camp.locationPhrase}.",
                    ["outcome"] = "completed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.completed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I couldn't set up camp there.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'll head {camp.locationPhrase} and set up camp.",
                    ["outcome"] = "pending",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.pending.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll set up camp there.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.queued.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Sure, I'll set up camp there. Sounds cozy.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.queued.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "I'm still setting up camp there.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.queued.say.1.repeated",
                    ["variantID"] = "repeated",
                },
                {
                    ["fallback"] = "All right, I'll make camp there.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.queued.say.1.trusted",
                    ["variantID"] = "trusted",
                },
                {
                    ["fallback"] = "I'll set up camp there.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.queued.say.1.withdrawn",
                    ["variantID"] = "withdrawn",
                },
                {
                    ["fallback"] = "I can't set up camp there right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I don't see a safe place to camp nearby.",
                    ["outcome"] = "rejected_no_site",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.rejected_no_site.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "That camp location is too far away right now.",
                    ["outcome"] = "rejected_out_of_range",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.camp.reply.rejected_out_of_range.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp",
            ["sourceId"] = "command.camp",
            ["sourcePath"] = "dialogue/companion_commands_lifecycle/command_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle",
        ["namespace"] = "command",
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
            ["action"] = {
                ["capability"] = "hoomans.camp.establish",
                ["mutating"] = true,
            },
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "companion",
                    "command",
                    "camp",
                },
                ["labelFallback"] = "Set up camp",
                ["metadata"] = {
                    ["action"] = "CAMP",
                },
                ["textRole"] = "button_label",
            },
            ["bindings"] = {
                ["camp.locationPhrase"] = {
                    ["from"] = "result.data.site",
                    ["resolver"] = "pnc.camp.location_phrase",
                    ["type"] = "entity.location",
                },
            },
            ["closure"] = {
                ["closureClass"] = "state_transition",
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["execute"] = {
                ["mode"] = "request_response",
                ["use"] = "pnc.companion.camp",
                ["with"] = {
                    ["npcID"] = "$context.addressee.id",
                    ["target"] = "$slot.camp_site",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["invoke"] = {
                ["action"] = "CAMP",
                ["intent"] = "COMMAND",
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
            },
            ["postconditions"] = {
                "companion.camping",
            },
            ["repeatPolicy"] = "state_retired",
            ["reply"] = {
                ["completed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "We're set up {camp.locationPhrase}.",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't set up camp there.",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I'll head {camp.locationPhrase} and set up camp.",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll set up camp there.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll set up camp there. Sounds cozy.",
                                        ["id"] = "friendly",
                                    },
                                    {
                                        ["fallback"] = "I'm still setting up camp there.",
                                        ["id"] = "repeated",
                                    },
                                    {
                                        ["fallback"] = "All right, I'll make camp there.",
                                        ["id"] = "trusted",
                                    },
                                    {
                                        ["fallback"] = "I'll set up camp there.",
                                        ["id"] = "withdrawn",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't set up camp there right now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected_no_site"] = {
                    ["act"] = "REPLY",
                    ["outcome"] = "rejected_no_site",
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
                                        ["fallback"] = "I don't see a safe place to camp nearby.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "result.reasonClass",
                        ["value"] = "target_unavailable",
                    },
                },
                ["rejected_out_of_range"] = {
                    ["act"] = "REPLY",
                    ["outcome"] = "rejected_out_of_range",
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
                                        ["fallback"] = "That camp location is too far away right now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "result.reasonClass",
                        ["value"] = "out_of_range",
                    },
                },
            },
            ["requiredCapabilities"] = {
                "hoomans.camp.establish",
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
                                ["fallback"] = "Let's camp here.",
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
                    ["id"] = "actor_blocked_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "actor_blocked_or_hostile",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.authorityEligible",
                                ["value"] = false,
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.status",
                                ["value"] = "hostile",
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "dead",
                                },
                            },
                        },
                    },
                },
                {
                    ["admission"] = "no_op",
                    ["id"] = "already_camping",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_camp",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "npcState.orderKind",
                        ["value"] = "camp",
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
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.camp",
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
                            ["fallback"] = "Let's camp here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.camp.say_1",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
            ["camp_site"] = {
                ["limit"] = 4,
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["suggest"] = "camp_site_candidates",
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/companion_commands_lifecycle/command_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Set up camp",
                ["role"] = "button_label",
                ["templateID"] = "convo.command.camp.affordance.label",
            },
            {
                ["fallback"] = "Let's camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.camp.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "We're set up {camp.locationPhrase}.",
                ["outcome"] = "completed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.completed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I couldn't set up camp there.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'll head {camp.locationPhrase} and set up camp.",
                ["outcome"] = "pending",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.pending.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll set up camp there.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.queued.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Sure, I'll set up camp there. Sounds cozy.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.queued.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "I'm still setting up camp there.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.queued.say.1.repeated",
                ["variantID"] = "repeated",
            },
            {
                ["fallback"] = "All right, I'll make camp there.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.queued.say.1.trusted",
                ["variantID"] = "trusted",
            },
            {
                ["fallback"] = "I'll set up camp there.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.queued.say.1.withdrawn",
                ["variantID"] = "withdrawn",
            },
            {
                ["fallback"] = "I can't set up camp there right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I don't see a safe place to camp nearby.",
                ["outcome"] = "rejected_no_site",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.rejected_no_site.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "That camp location is too far away right now.",
                ["outcome"] = "rejected_out_of_range",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.camp.reply.rejected_out_of_range.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["domainPath"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "command.follow",
            ["namespace"] = "command",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't start following you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.follow.reply.failed.say.1.default",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll follow you.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.command.follow.reply.queued.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Of course, I'll follow you.",
                                        ["id"] = "friendly",
                                        ["templateID"] = "convo.command.follow.reply.queued.say.1.friendly",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm still following you.",
                                        ["id"] = "repeated",
                                        ["templateID"] = "convo.command.follow.reply.queued.say.1.repeated",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I know you. I'll follow.",
                                        ["id"] = "trusted",
                                        ["templateID"] = "convo.command.follow.reply.queued.say.1.trusted",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'll follow.",
                                        ["id"] = "withdrawn",
                                        ["templateID"] = "convo.command.follow.reply.queued.say.1.withdrawn",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't follow you right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.follow.reply.rejected.say.1.default",
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
                    ["fallback"] = "I couldn't start following you.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll follow you.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.queued.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Of course, I'll follow you.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.queued.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "I'm still following you.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.queued.say.1.repeated",
                    ["variantID"] = "repeated",
                },
                {
                    ["fallback"] = "I know you. I'll follow.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.queued.say.1.trusted",
                    ["variantID"] = "trusted",
                },
                {
                    ["fallback"] = "I'll follow.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.queued.say.1.withdrawn",
                    ["variantID"] = "withdrawn",
                },
                {
                    ["fallback"] = "I can't follow you right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.follow.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "follow",
            ["sourceId"] = "command.follow",
            ["sourcePath"] = "dialogue/companion_commands_lifecycle/command_follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle",
        ["namespace"] = "command",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't start following you.",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll follow you.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Of course, I'll follow you.",
                                        ["id"] = "friendly",
                                    },
                                    {
                                        ["fallback"] = "I'm still following you.",
                                        ["id"] = "repeated",
                                    },
                                    {
                                        ["fallback"] = "I know you. I'll follow.",
                                        ["id"] = "trusted",
                                    },
                                    {
                                        ["fallback"] = "I'll follow.",
                                        ["id"] = "withdrawn",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't follow you right now.",
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
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_lifecycle/command_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't start following you.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll follow you.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.queued.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Of course, I'll follow you.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.queued.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "I'm still following you.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.queued.say.1.repeated",
                ["variantID"] = "repeated",
            },
            {
                ["fallback"] = "I know you. I'll follow.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.queued.say.1.trusted",
                ["variantID"] = "trusted",
            },
            {
                ["fallback"] = "I'll follow.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.queued.say.1.withdrawn",
                ["variantID"] = "withdrawn",
            },
            {
                ["fallback"] = "I can't follow you right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.follow.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["domainPath"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "command.return_home",
            ["namespace"] = "command",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't head home.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.return_home.reply.failed.say.1.default",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll head home.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.command.return_home.reply.queued.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll head home. See you back there soon!",
                                        ["id"] = "friendly",
                                        ["templateID"] = "convo.command.return_home.reply.queued.say.1.friendly",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm still heading home.",
                                        ["id"] = "repeated",
                                        ["templateID"] = "convo.command.return_home.reply.queued.say.1.repeated",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "All right, I'm heading home. Guard the rear.",
                                        ["id"] = "trusted",
                                        ["templateID"] = "convo.command.return_home.reply.queued.say.1.trusted",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'll head home.",
                                        ["id"] = "withdrawn",
                                        ["templateID"] = "convo.command.return_home.reply.queued.say.1.withdrawn",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't head home right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.return_home.reply.rejected.say.1.default",
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
                    ["fallback"] = "I couldn't head home.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll head home.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.queued.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Sure, I'll head home. See you back there soon!",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.queued.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "I'm still heading home.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.queued.say.1.repeated",
                    ["variantID"] = "repeated",
                },
                {
                    ["fallback"] = "All right, I'm heading home. Guard the rear.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.queued.say.1.trusted",
                    ["variantID"] = "trusted",
                },
                {
                    ["fallback"] = "I'll head home.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.queued.say.1.withdrawn",
                    ["variantID"] = "withdrawn",
                },
                {
                    ["fallback"] = "I can't head home right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.return_home.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "return_home",
            ["sourceId"] = "command.return_home",
            ["sourcePath"] = "dialogue/companion_commands_lifecycle/command_return_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle",
        ["namespace"] = "command",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't head home.",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll head home.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll head home. See you back there soon!",
                                        ["id"] = "friendly",
                                    },
                                    {
                                        ["fallback"] = "I'm still heading home.",
                                        ["id"] = "repeated",
                                    },
                                    {
                                        ["fallback"] = "All right, I'm heading home. Guard the rear.",
                                        ["id"] = "trusted",
                                    },
                                    {
                                        ["fallback"] = "I'll head home.",
                                        ["id"] = "withdrawn",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't head home right now.",
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
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_lifecycle/command_return_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't head home.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll head home.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.queued.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Sure, I'll head home. See you back there soon!",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.queued.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "I'm still heading home.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.queued.say.1.repeated",
                ["variantID"] = "repeated",
            },
            {
                ["fallback"] = "All right, I'm heading home. Guard the rear.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.queued.say.1.trusted",
                ["variantID"] = "trusted",
            },
            {
                ["fallback"] = "I'll head home.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.queued.say.1.withdrawn",
                ["variantID"] = "withdrawn",
            },
            {
                ["fallback"] = "I can't head home right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.return_home.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["domainPath"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "command.stay",
            ["namespace"] = "command",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't start the stay order.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.stay.reply.failed.say.1.default",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll stay here.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.command.stay.reply.queued.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll stay here. Take your time, friend!",
                                        ["id"] = "friendly",
                                        ["templateID"] = "convo.command.stay.reply.queued.say.1.friendly",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm already staying here.",
                                        ["id"] = "repeated",
                                        ["templateID"] = "convo.command.stay.reply.queued.say.1.repeated",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "All right, I'll stay. Watch your back out there.",
                                        ["id"] = "trusted",
                                        ["templateID"] = "convo.command.stay.reply.queued.say.1.trusted",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Okay, I'll stay.",
                                        ["id"] = "withdrawn",
                                        ["templateID"] = "convo.command.stay.reply.queued.say.1.withdrawn",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't stay here right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.stay.reply.rejected.say.1.default",
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
                    ["fallback"] = "I couldn't start the stay order.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll stay here.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.queued.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Sure, I'll stay here. Take your time, friend!",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.queued.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "I'm already staying here.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.queued.say.1.repeated",
                    ["variantID"] = "repeated",
                },
                {
                    ["fallback"] = "All right, I'll stay. Watch your back out there.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.queued.say.1.trusted",
                    ["variantID"] = "trusted",
                },
                {
                    ["fallback"] = "Okay, I'll stay.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.queued.say.1.withdrawn",
                    ["variantID"] = "withdrawn",
                },
                {
                    ["fallback"] = "I can't stay here right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stay.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stay",
            ["sourceId"] = "command.stay",
            ["sourcePath"] = "dialogue/companion_commands_lifecycle/command_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle",
        ["namespace"] = "command",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't start the stay order.",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll stay here.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Sure, I'll stay here. Take your time, friend!",
                                        ["id"] = "friendly",
                                    },
                                    {
                                        ["fallback"] = "I'm already staying here.",
                                        ["id"] = "repeated",
                                    },
                                    {
                                        ["fallback"] = "All right, I'll stay. Watch your back out there.",
                                        ["id"] = "trusted",
                                    },
                                    {
                                        ["fallback"] = "Okay, I'll stay.",
                                        ["id"] = "withdrawn",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't stay here right now.",
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
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_lifecycle/command_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't start the stay order.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll stay here.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.queued.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Sure, I'll stay here. Take your time, friend!",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.queued.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "I'm already staying here.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.queued.say.1.repeated",
                ["variantID"] = "repeated",
            },
            {
                ["fallback"] = "All right, I'll stay. Watch your back out there.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.queued.say.1.trusted",
                ["variantID"] = "trusted",
            },
            {
                ["fallback"] = "Okay, I'll stay.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.queued.say.1.withdrawn",
                ["variantID"] = "withdrawn",
            },
            {
                ["fallback"] = "I can't stay here right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stay.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["domainPath"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "command.stop_following",
            ["namespace"] = "command",
            ["replies"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't stop following.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.stop_following.reply.failed.say.1.default",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll stop following.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.command.stop_following.reply.queued.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Got it, I'll stop following. Take care out there, friend!",
                                        ["id"] = "friendly",
                                        ["templateID"] = "convo.command.stop_following.reply.queued.say.1.friendly",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I've already stopped following.",
                                        ["id"] = "repeated",
                                        ["templateID"] = "convo.command.stop_following.reply.queued.say.1.repeated",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Understood, I'll stop. I trust your solo judgment.",
                                        ["id"] = "trusted",
                                        ["templateID"] = "convo.command.stop_following.reply.queued.say.1.trusted",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Okay, I'll stop.",
                                        ["id"] = "withdrawn",
                                        ["templateID"] = "convo.command.stop_following.reply.queued.say.1.withdrawn",
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
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't stop following right now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.command.stop_following.reply.rejected.say.1.default",
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
                    ["fallback"] = "I couldn't stop following.",
                    ["outcome"] = "failed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.failed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Okay, I'll stop following.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.queued.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Got it, I'll stop following. Take care out there, friend!",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.queued.say.1.friendly",
                    ["variantID"] = "friendly",
                },
                {
                    ["fallback"] = "I've already stopped following.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.queued.say.1.repeated",
                    ["variantID"] = "repeated",
                },
                {
                    ["fallback"] = "Understood, I'll stop. I trust your solo judgment.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.queued.say.1.trusted",
                    ["variantID"] = "trusted",
                },
                {
                    ["fallback"] = "Okay, I'll stop.",
                    ["outcome"] = "queued",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.queued.say.1.withdrawn",
                    ["variantID"] = "withdrawn",
                },
                {
                    ["fallback"] = "I can't stop following right now.",
                    ["outcome"] = "rejected",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.command.stop_following.reply.rejected.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.stop_following",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stop_following",
            ["sourceId"] = "command.stop_following",
            ["sourcePath"] = "dialogue/companion_commands_lifecycle/command_stop_following.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle",
        ["namespace"] = "command",
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
            ["activities"] = {
                {
                    ["id"] = "companion_order",
                    ["role"] = "target",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "companion_commands",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "REPLY",
            },
            ["reply"] = {
                ["failed"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I couldn't stop following.",
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
                    ["act"] = "REPLY",
                    ["outcome"] = "queued",
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
                                        ["fallback"] = "Okay, I'll stop following.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "Got it, I'll stop following. Take care out there, friend!",
                                        ["id"] = "friendly",
                                    },
                                    {
                                        ["fallback"] = "I've already stopped following.",
                                        ["id"] = "repeated",
                                    },
                                    {
                                        ["fallback"] = "Understood, I'll stop. I trust your solo judgment.",
                                        ["id"] = "trusted",
                                    },
                                    {
                                        ["fallback"] = "Okay, I'll stop.",
                                        ["id"] = "withdrawn",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["rejected"] = {
                    ["act"] = "REPLY",
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
                                        ["fallback"] = "I can't stop following right now.",
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
                    ["domain"] = "companion_commands",
                    ["id"] = "companion_command",
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
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_lifecycle/command_stop_following.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't stop following.",
                ["outcome"] = "failed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.failed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Okay, I'll stop following.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.queued.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Got it, I'll stop following. Take care out there, friend!",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.queued.say.1.friendly",
                ["variantID"] = "friendly",
            },
            {
                ["fallback"] = "I've already stopped following.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.queued.say.1.repeated",
                ["variantID"] = "repeated",
            },
            {
                ["fallback"] = "Understood, I'll stop. I trust your solo judgment.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.queued.say.1.trusted",
                ["variantID"] = "trusted",
            },
            {
                ["fallback"] = "Okay, I'll stop.",
                ["outcome"] = "queued",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.queued.say.1.withdrawn",
                ["variantID"] = "withdrawn",
            },
            {
                ["fallback"] = "I can't stop following right now.",
                ["outcome"] = "rejected",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.command.stop_following.reply.rejected.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
