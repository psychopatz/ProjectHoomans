-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "colony.work.status_exchange",
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
                                ["fallback"] = "Back fence still has a loose plank, and the rain barrels need checking. How are we looking on chores?",
                                ["id"] = "default",
                                ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "colony.work",
            ["replies"] = {
                ["agreed"] = {
                    ["outcome"] = "agreed",
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
                                        ["fallback"] = "Good. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["checked_in"] = {
                    ["outcome"] = "checked_in",
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
                                        ["fallback"] = "It's holding for now, just needs another pair of hands when we get a quiet hour.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
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
                    ["fallback"] = "Back fence still has a loose plank, and the rain barrels need checking. How are we looking on chores?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Good. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                    ["outcome"] = "agreed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "It's holding for now, just needs another pair of hands when we get a quiet hour.",
                    ["outcome"] = "checked_in",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "colony.work.status_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "status_exchange",
            ["sourceId"] = "colony.work.status_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/colony_work_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToSocialConflictMediateExchange",
        ["namespace"] = "colony.work",
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
                ["episodeId"] = "colony_work_status_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "colony",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "colony.work.status_exchange",
                    ["initial"] = "check_chore_status",
                    ["nodes"] = {
                        ["agreed"] = {
                            ["terminal"] = true,
                        },
                        ["check_chore_status"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "SUGGEST",
                                    ["speechAct"] = "SUGGEST",
                                    ["stateValue"] = "deferred",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "COLONY_WORK",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.offer_help",
                                    ["labelFallback"] = "Pitch in on the chore",
                                    ["labelKey"] = "UI_PNC_ColonyWork_OfferHelp_Label",
                                    ["utteranceFallback"] = "Need another pair of hands on that?",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_OfferHelp_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.clarify_task",
                                    ["labelFallback"] = "Ask which job needs doing",
                                    ["labelKey"] = "UI_PNC_ColonyWork_ClarifyTask_Label",
                                    ["utteranceFallback"] = "Are we talking about the back fence or the rain barrels?",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_ClarifyTask_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "SUGGEST",
                                        ["speechAct"] = "SUGGEST",
                                        ["stateValue"] = "deferred",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.defer_shift",
                                    ["labelFallback"] = "Hold off until later",
                                    ["labelKey"] = "UI_PNC_ColonyWork_DeferShift_Label",
                                    ["utteranceFallback"] = "Better leave the hammering until morning.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_DeferShift_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_chore",
                            ["onMatch"] = "confirm_assignment",
                            ["onRefuse"] = "declined",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["settlement"] = {
                                    ["owner"] = "colony.work.status_exchange",
                                    ["source"] = "slots.settlement.value",
                                    ["type"] = "string",
                                },
                                ["task"] = {
                                    ["owner"] = "colony.work.status_exchange",
                                    ["source"] = "slots.task.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["clarify_chore"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COLONY_WORK",
                                },
                            },
                            ["onMatch"] = "confirm_assignment",
                            ["onRefuse"] = "declined",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["task"] = {
                                    ["owner"] = "colony.work.status_exchange",
                                    ["source"] = "slots.task.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["confirm_assignment"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COLONY_WORK",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["subject"] = "COLONY_WORK",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.agree_plan",
                                    ["labelFallback"] = "Agree to split the work",
                                    ["labelKey"] = "UI_PNC_ColonyWork_AgreePlan_Label",
                                    ["utteranceFallback"] = "Alright, I'll grab the hammer and meet you out back.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_AgreePlan_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "COLONY_WORK",
                                    },
                                    ["id"] = "colony.work.pause_later",
                                    ["labelFallback"] = "Pick it up later",
                                    ["labelKey"] = "UI_PNC_ColonyWork_PauseLater_Label",
                                    ["utteranceFallback"] = "Keep an eye on it; we'll finish it at first light.",
                                    ["utteranceKey"] = "UI_PNC_ColonyWork_PauseLater_Utterance",
                                },
                            },
                            ["onMatch"] = "agreed",
                            ["onRefuse"] = "declined",
                            ["onUnrelated"] = "suspend",
                        },
                        ["declined"] = {
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["agreed"] = {
                        ["outcome"] = "agreed",
                        ["stance"] = "positive",
                    },
                    ["checked_in"] = {
                        ["outcome"] = "checked_in",
                        ["stance"] = "neutral",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "COLONY_WORK",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["subject"] = "COLONY_WORK",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["agreed"] = {
                    ["outcome"] = "agreed",
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
                                        ["fallback"] = "Good. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["checked_in"] = {
                    ["outcome"] = "checked_in",
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
                                        ["fallback"] = "It's holding for now, just needs another pair of hands when we get a quiet hour.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
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
                                ["fallback"] = "Back fence still has a loose plank, and the rain barrels need checking. How are we looking on chores?",
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
                    ["id"] = "blocked_unsafe_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_combat_or_incapacitated",
                    ["replyOutcome"] = "refused",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "colony_work_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "colony",
                    ["id"] = "colony_work",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "colony.work.status_exchange",
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
                            ["fallback"] = "Back fence still has a loose plank, and the rain barrels need checking. How are we looking on chores?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.colony.work.status_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/colony_work_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Back fence still has a loose plank, and the rain barrels need checking. How are we looking on chores?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.colony.work.status_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Good. Grab a hammer and some nails—we'll get it buttoned up before dark.",
                ["outcome"] = "agreed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.agreed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "It's holding for now, just needs another pair of hands when we get a quiet hour.",
                ["outcome"] = "checked_in",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.checked_in.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fair enough. Let's leave the heavy hammering until morning so we don't draw anything.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Not the time for chores. Keep your eyes on the yard.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.colony.work.status_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.aftermath.debrief_exchange",
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
                                ["fallback"] = "That got ugly fast. You catch any scratches or bites back there?",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.aftermath",
            ["replies"] = {
                ["cleared"] = {
                    ["outcome"] = "cleared",
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
                                        ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["debriefed"] = {
                    ["outcome"] = "debriefed",
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
                                        ["fallback"] = "Nothing through the jacket, thank God. Door's wedged shut—let's catch our breath and check our gear.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Don't crowd me right now. Watch the window.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shaken"] = {
                    ["outcome"] = "shaken",
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
                                        ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
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
                    ["fallback"] = "That got ugly fast. You catch any scratches or bites back there?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                    ["outcome"] = "cleared",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Nothing through the jacket, thank God. Door's wedged shut—let's catch our breath and check our gear.",
                    ["outcome"] = "debriefed",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Don't crowd me right now. Watch the window.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                    ["outcome"] = "shaken",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.aftermath.debrief_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "debrief_exchange",
            ["sourceId"] = "combat.aftermath.debrief_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/combat_aftermath_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToSocialConflictMediateExchange",
        ["namespace"] = "combat.aftermath",
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
                ["episodeId"] = "combat_aftermath_debrief_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "combat.aftermath.debrief_exchange",
                    ["initial"] = "catch_breath",
                    ["nodes"] = {
                        ["assess_aftermath"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "clear",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "shaken",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "AGREE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "clear",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.steady_down",
                                    ["labelFallback"] = "Confirm the alley is clear",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_SteadyDown_Label",
                                    ["utteranceFallback"] = "Looks like we lost the rest of them down the side street.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_SteadyDown_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "shaken",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "combat.aftermath.admit_shaken",
                                    ["labelFallback"] = "Take a minute to steady",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Label",
                                    ["utteranceFallback"] = "My hands are still shaking. Just give me a minute.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_AdmitShaken_Utterance",
                                },
                            },
                            ["onMatch"] = "debriefed",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                        },
                        ["catch_breath"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "WELLBEING",
                                },
                                {
                                    ["intent"] = "OFFER",
                                    ["speechAct"] = "OFFER",
                                    ["subject"] = "COMBAT_AFTERMATH",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "WELLBEING",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "WELLBEING",
                                    },
                                    ["id"] = "combat.aftermath.check_wounds",
                                    ["labelFallback"] = "Check for bites or tears",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_CheckWounds_Label",
                                    ["utteranceFallback"] = "You alright? Any scratches or rips in your jacket?",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_CheckWounds_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "OFFER",
                                        ["speechAct"] = "OFFER",
                                        ["subject"] = "COMBAT_AFTERMATH",
                                    },
                                    ["id"] = "combat.aftermath.secure_area",
                                    ["labelFallback"] = "Bar the back door",
                                    ["labelKey"] = "UI_PNC_CombatAftermath_SecureArea_Label",
                                    ["utteranceFallback"] = "I'll wedge a chair under the back door while you catch your breath.",
                                    ["utteranceKey"] = "UI_PNC_CombatAftermath_SecureArea_Utterance",
                                },
                            },
                            ["onMatch"] = "assess_aftermath",
                            ["onRefuse"] = "shaken_withdrawal",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["location"] = {
                                    ["owner"] = "combat.aftermath.debrief_exchange",
                                    ["source"] = "slots.location.value",
                                    ["type"] = "string",
                                },
                                ["threat"] = {
                                    ["owner"] = "combat.aftermath.debrief_exchange",
                                    ["source"] = "slots.threat.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["debriefed"] = {
                            ["terminal"] = true,
                        },
                        ["shaken_withdrawal"] = {
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["cleared"] = {
                        ["outcome"] = "cleared",
                        ["stance"] = "neutral",
                    },
                    ["debriefed"] = {
                        ["outcome"] = "debriefed",
                        ["stance"] = "positive",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                    ["shaken"] = {
                        ["outcome"] = "shaken",
                        ["stance"] = "contextual",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "COMBAT_AFTERMATH",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["subject"] = "COMBAT_AFTERMATH",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["cleared"] = {
                    ["outcome"] = "cleared",
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
                                        ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["debriefed"] = {
                    ["outcome"] = "debriefed",
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
                                        ["fallback"] = "Nothing through the jacket, thank God. Door's wedged shut—let's catch our breath and check our gear.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Don't crowd me right now. Watch the window.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["shaken"] = {
                    ["outcome"] = "shaken",
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
                                        ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
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
                                ["fallback"] = "That got ugly fast. You catch any scratches or bites back there?",
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
                    ["id"] = "blocked_unsafe_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_combat_or_incapacitated",
                    ["replyOutcome"] = "refused",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "combat_aftermath_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_aftermath",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.aftermath.debrief_exchange",
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
                            ["fallback"] = "That got ugly fast. You catch any scratches or bites back there?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.aftermath.debrief_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/combat_aftermath_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That got ugly fast. You catch any scratches or bites back there?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Looks like the rest of them wandered off down the alley. Keep it quiet for a minute.",
                ["outcome"] = "cleared",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.cleared.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Nothing through the jacket, thank God. Door's wedged shut—let's catch our breath and check our gear.",
                ["outcome"] = "debriefed",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.debriefed.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Don't crowd me right now. Watch the window.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I'm not bit, just rattled. Give me a second to get my hands steady.",
                ["outcome"] = "shaken",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.aftermath.debrief_exchange.reply.shaken.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "knowledge.gossip.exchange",
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
                                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                                ["id"] = "default",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Good catching you here—heard anything useful about clear roads or decent supplies nearby?",
                                ["id"] = "positive",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                                ["id"] = "negative",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                                ["id"] = "contextual",
                                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "knowledge.gossip",
            ["replies"] = {
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
                                        ["fallback"] = "Not the time for rumors—keep your head down.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Save the chatter. Watch the street.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["known"] = {
                    ["outcome"] = "known",
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
                                        ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                                        ["id"] = "positive",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Can vouch for part of it: saw fresh tracks and open shutters near the strip mall yesterday.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                                        ["id"] = "negative",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["uncertain"] = {
                    ["outcome"] = "uncertain",
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
                                        ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                                        ["id"] = "contextual",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                    {
                                        ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
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
            ["slots"] = {
                ["location"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Good catching you here—heard anything useful about clear roads or decent supplies nearby?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Not the time for rumors—keep your head down.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Save the chatter. Watch the street.",
                    ["outcome"] = "blocked",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                    ["variantID"] = "positive",
                },
                {
                    ["fallback"] = "Can vouch for part of it: saw fresh tracks and open shutters near the strip mall yesterday.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
                    ["variantID"] = "negative",
                },
                {
                    ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                    ["outcome"] = "uncertain",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                    ["outcome"] = "uncertain",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                    ["variantID"] = "contextual",
                },
                {
                    ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "knowledge.gossip.exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "exchange",
            ["sourceId"] = "knowledge.gossip.exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/knowledge_gossip_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToSocialConflictMediateExchange",
        ["namespace"] = "knowledge.gossip",
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
                ["closureClass"] = "none",
            },
            ["domains"] = {
                {
                    ["domain"] = "knowledge",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["category"] = "projecthoomans:thematic_interactive",
                ["contentOwner"] = "projecthoomans.dialogue_content.knowledge",
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "knowledge.gossip.exchange",
                    ["initial"] = "ask_word_around",
                    ["nodes"] = {
                        ["ask_word_around"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.ask_roads",
                                    ["labelFallback"] = "Ask about nearby roads",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipAskRoads_Label",
                                    ["utteranceFallback"] = "Heard any word on whether the highway north is clear or choked with wrecks?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipAskRoads_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.share_rumor",
                                    ["labelFallback"] = "Share what you heard",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipShareRumor_Label",
                                    ["utteranceFallback"] = "Someone swore there's still power running in a few blocks west of here, though I haven't seen it myself.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipShareRumor_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.clarify_source",
                                    ["labelFallback"] = "Ask who saw it",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipClarifySource_Label",
                                    ["utteranceFallback"] = "Did you see that with your own eyes, or hear it secondhand?",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipClarifySource_Utterance",
                                },
                            },
                            ["onClarify"] = "clarify_source",
                            ["onMatch"] = "weigh_rumor",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.opening",
                            ["slots"] = {
                                ["event"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.event",
                                    ["type"] = "string",
                                },
                                ["faction"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.faction",
                                    ["type"] = "string",
                                },
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["clarify_source"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "NEWS",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["subject"] = "NEWS",
                                    },
                                    ["id"] = "knowledge.gossip.confirm_firsthand",
                                    ["labelFallback"] = "Say you saw signs yourself",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipFirsthand_Label",
                                    ["utteranceFallback"] = "Saw the smoke from the rooftops two days back—wasn't just radio talk.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipFirsthand_Utterance",
                                },
                            },
                            ["onMatch"] = "weigh_rumor",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.clarify",
                            ["slots"] = {
                                ["event"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.event",
                                    ["type"] = "string",
                                },
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                                ["person"] = {
                                    ["owner"] = "social",
                                    ["source"] = "slots.person",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["close_exchange"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "THANK",
                                    ["speechAct"] = "THANK",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "THANK",
                                        ["speechAct"] = "THANK",
                                    },
                                    ["id"] = "knowledge.gossip.thank_word",
                                    ["labelFallback"] = "Thank for the heads-up",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipThanks_Label",
                                    ["utteranceFallback"] = "Good to know. If you hear anything else on the radio or the road, pass it along.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipThanks_Utterance",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.close",
                        },
                        ["complete"] = {
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.complete",
                            ["terminal"] = true,
                        },
                        ["refused_rumor"] = {
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.refused",
                            ["terminal"] = true,
                        },
                        ["weigh_rumor"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "RUMOR",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "known",
                                    },
                                    ["id"] = "knowledge.gossip.mark_known",
                                    ["labelFallback"] = "Confirm the details",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipConfirm_Label",
                                    ["utteranceFallback"] = "Lines up with what I saw near the strip mall—worth keeping in mind.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipConfirm_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "uncertain",
                                        ["subject"] = "RUMOR",
                                    },
                                    ["id"] = "knowledge.gossip.mark_uncertain",
                                    ["labelFallback"] = "Stay skeptical",
                                    ["labelKey"] = "UI_PNC_Conversation_Suggestion_GossipDoubt_Label",
                                    ["utteranceFallback"] = "Could be true, could be folks talking out of fear. I wouldn't bet my neck on it.",
                                    ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GossipDoubt_Utterance",
                                },
                            },
                            ["onMatch"] = "close_exchange",
                            ["onRefuse"] = "refused_rumor",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.knowledge.gossip.exchange.weigh",
                            ["slots"] = {
                                ["event"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.event",
                                    ["type"] = "string",
                                },
                                ["item"] = {
                                    ["owner"] = "inventory",
                                    ["source"] = "slots.item",
                                    ["type"] = "string",
                                },
                                ["location"] = {
                                    ["owner"] = "world",
                                    ["source"] = "slots.location",
                                    ["type"] = "string",
                                },
                            },
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["outcomes"] = {
                    "known",
                    "unknown",
                    "uncertain",
                    "refused",
                },
                ["stances"] = {
                    "positive",
                    "neutral",
                    "negative",
                    "contextual",
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "NEWS",
                    },
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "RUMOR",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
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
                                        ["fallback"] = "Not the time for rumors—keep your head down.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Save the chatter. Watch the street.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["known"] = {
                    ["outcome"] = "known",
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
                                        ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                                        ["id"] = "positive",
                                    },
                                    {
                                        ["fallback"] = "Can vouch for part of it: saw fresh tracks and open shutters near the strip mall yesterday.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                                        ["id"] = "negative",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["uncertain"] = {
                    ["outcome"] = "uncertain",
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
                                        ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                                        ["id"] = "contextual",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                                        ["id"] = "default",
                                    },
                                    {
                                        ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                                        ["id"] = "neutral",
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
                                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                                ["id"] = "default",
                            },
                            {
                                ["fallback"] = "Good catching you here—heard anything useful about clear roads or decent supplies nearby?",
                                ["id"] = "positive",
                            },
                            {
                                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                                ["id"] = "negative",
                            },
                            {
                                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                                ["id"] = "contextual",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "blocked_unavailable_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_busy_or_incapacitated",
                    ["replyOutcome"] = "blocked",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                },
                {
                    ["admission"] = "no_op",
                    ["id"] = "blocked_uninformed",
                    ["outcome"] = "blocked",
                    ["reason"] = "uninformed",
                    ["replyOutcome"] = "unknown",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "npcState.uninformed",
                        ["value"] = true,
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "gossip_exchange_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "knowledge",
                    ["id"] = "news",
                },
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
            ["responsePlanID"] = "knowledge.gossip.exchange",
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
                            ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.knowledge.gossip.exchange.say_1",
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
            ["location"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/thematic_interactive/knowledge_gossip_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heard any word from down the road? Trying to piece together what's still standing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Good catching you here—heard anything useful about clear roads or decent supplies nearby?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "What's the word around here lately—anything moving on the highway or near town?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Lot of wild rumors flying around lately. You heard anything that actually checks out?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Saw smoke rising east of the river earlier, and the chopper's been rattling nerves all week. Heard anything?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.knowledge.gossip.exchange.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Not the time for rumors—keep your head down.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Save the chatter. Watch the street.",
                ["outcome"] = "blocked",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.blocked.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Yeah, I saw that myself—{slot.location} is choked up, so steer clear if you're smart.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Actually, yes—{addressee.name}, word is solid on that. Worth keeping in your pocket.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.positive",
                ["variantID"] = "positive",
            },
            {
                ["fallback"] = "Can vouch for part of it: saw fresh tracks and open shutters near the strip mall yesterday.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.known.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "I don't trade in gossip. Ask somebody else.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Keep me out of it. Word gets around, and so does trouble.",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.refused.say.1.negative",
                ["variantID"] = "negative",
            },
            {
                ["fallback"] = "Heard folks talking about it, sure, but nobody I'd bet my boots on.",
                ["outcome"] = "uncertain",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Could be true, could be somebody spooked by shadows. Treat it like a rumor until you see it.",
                ["outcome"] = "uncertain",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.uncertain.say.1.contextual",
                ["variantID"] = "contextual",
            },
            {
                ["fallback"] = "Couldn't tell you. Haven't heard a peep about that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "No idea—I've been keeping my head down on this block, haven't caught any news.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.knowledge.gossip.exchange.reply.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "thematic_interactive",
        ["domainPath"] = "thematic_interactive",
        ["exchangeFamily"] = {
            ["familyID"] = "social.conflict.mediate_exchange",
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
                                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry. We need to sort this out before someone walks out.",
                                ["id"] = "default",
                                ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "social.conflict",
            ["replies"] = {
                ["acknowledged"] = {
                    ["outcome"] = "acknowledged",
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
                                        ["fallback"] = "I hear you. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reconciled"] = {
                    ["outcome"] = "reconciled",
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
                                        ["fallback"] = "Alright. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["strained"] = {
                    ["outcome"] = "strained",
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
                                        ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
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
                    ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry. We need to sort this out before someone walks out.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I hear you. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                    ["outcome"] = "acknowledged",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                    ["outcome"] = "deferred",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                    ["outcome"] = "reconciled",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                    ["outcome"] = "strained",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "social.conflict.mediate_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "mediate_exchange",
            ["sourceId"] = "social.conflict.mediate_exchange",
            ["sourcePath"] = "dialogue/thematic_interactive/relationship_conflict_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToSocialConflictMediateExchange",
        ["namespace"] = "social.conflict",
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
                ["episodeId"] = "social_conflict_mediate_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                        },
                    },
                    ["id"] = "social.conflict.mediate_exchange",
                    ["initial"] = "air_grievance",
                    ["nodes"] = {
                        ["air_grievance"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["subject"] = "CONFLICT",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.listen_calmly",
                                    ["labelFallback"] = "Hear them out calmly",
                                    ["labelKey"] = "UI_PNC_SocialConflict_ListenCalmly_Label",
                                    ["utteranceFallback"] = "Alright, tell me what happened without shouting.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_ListenCalmly_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.push_back",
                                    ["labelFallback"] = "Push back on the blame",
                                    ["labelKey"] = "UI_PNC_SocialConflict_PushBack_Label",
                                    ["utteranceFallback"] = "That's not fair and you know it.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_PushBack_Utterance",
                                },
                            },
                            ["onClarify"] = "seek_middle_ground",
                            ["onMatch"] = "seek_middle_ground",
                            ["onRefuse"] = "strained",
                            ["onUnrelated"] = "suspend",
                            ["slots"] = {
                                ["person"] = {
                                    ["owner"] = "social.conflict.mediate_exchange",
                                    ["source"] = "slots.person.value",
                                    ["type"] = "string",
                                },
                                ["task"] = {
                                    ["owner"] = "social.conflict.mediate_exchange",
                                    ["source"] = "slots.task.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["reconciled"] = {
                            ["terminal"] = true,
                        },
                        ["seek_middle_ground"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "CONFLICT",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                },
                                {
                                    ["intent"] = "DEFER",
                                    ["speechAct"] = "DEFER",
                                    ["subject"] = "CONFLICT",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.reconcile",
                                    ["labelFallback"] = "Call it even",
                                    ["labelKey"] = "UI_PNC_SocialConflict_Reconcile_Label",
                                    ["utteranceFallback"] = "Fine. We both made a mess of it. Let's drop it and move on.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_Reconcile_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DEFER",
                                        ["speechAct"] = "DEFER",
                                        ["subject"] = "CONFLICT",
                                    },
                                    ["id"] = "social.conflict.cool_off",
                                    ["labelFallback"] = "Take some space",
                                    ["labelKey"] = "UI_PNC_SocialConflict_CoolOff_Label",
                                    ["utteranceFallback"] = "Let's leave it alone until we've both had some sleep.",
                                    ["utteranceKey"] = "UI_PNC_SocialConflict_CoolOff_Utterance",
                                },
                            },
                            ["onMatch"] = "reconciled",
                            ["onRefuse"] = "strained",
                            ["onUnrelated"] = "suspend",
                        },
                        ["strained"] = {
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["acknowledged"] = {
                        ["outcome"] = "acknowledged",
                        ["stance"] = "neutral",
                    },
                    ["deferred"] = {
                        ["outcome"] = "deferred",
                        ["stance"] = "contextual",
                    },
                    ["reconciled"] = {
                        ["outcome"] = "reconciled",
                        ["stance"] = "positive",
                    },
                    ["strained"] = {
                        ["outcome"] = "strained",
                        ["stance"] = "negative",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "COMPLAIN",
                        ["subject"] = "CONFLICT",
                    },
                    {
                        ["intent"] = "MEDIATION",
                        ["subject"] = "CONFLICT",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["acknowledged"] = {
                    ["outcome"] = "acknowledged",
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
                                        ["fallback"] = "I hear you. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["deferred"] = {
                    ["outcome"] = "deferred",
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
                                        ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reconciled"] = {
                    ["outcome"] = "reconciled",
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
                                        ["fallback"] = "Alright. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["strained"] = {
                    ["outcome"] = "strained",
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
                                        ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
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
                                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry. We need to sort this out before someone walks out.",
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
                    ["id"] = "blocked_unsafe_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_combat_or_incapacitated",
                    ["replyOutcome"] = "strained",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "situation.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "combat",
                                    "busy",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "social_conflict_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "relationship_conflict",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.conflict.mediate_exchange",
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
                            ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry. We need to sort this out before someone walks out.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.social.conflict.mediate_exchange.say_1",
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
        ["sourceShard"] = "dialogue/thematic_interactive/relationship_conflict_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Everyone's snapping at each other over the watch schedule and the pantry. We need to sort this out before someone walks out.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.social.conflict.mediate_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I hear you. Nobody's trying to shortchange anyone here—we just need clearer rules.",
                ["outcome"] = "acknowledged",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.acknowledged.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Fine. Let's cool off and talk about it after we've both had some water and rest.",
                ["outcome"] = "deferred",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.deferred.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright. We're all tired and short on sleep. Let's split the watch evenly and drop it.",
                ["outcome"] = "reconciled",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.reconciled.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Forget it. Not much point talking when nobody's listening.",
                ["outcome"] = "strained",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.social.conflict.mediate_exchange.reply.strained.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
