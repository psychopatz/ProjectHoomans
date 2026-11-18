-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.companion.camp",
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
                                ["templateID"] = "convo.command.companion.camp.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's camp here.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito.",
                                    },
                                },
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
            ["namespace"] = "command.companion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.companion.camp.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp here.",
                        },
                        ["TL"] = {
                            "Magkampo tayo rito.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.companion.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp",
            ["sourceId"] = "command.companion.camp",
            ["sourcePath"] = "dialogue/companion_commands_player/command_companion_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.companion",
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
                ["action"] = "CAMP",
                ["intent"] = "COMMAND",
            },
            ["postconditions"] = {
                "companion.camping",
            },
            ["repeatPolicy"] = "state_retired",
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
                                        "Let's camp here.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito.",
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.companion.camp",
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
                            ["templateID"] = "convo.command.companion.camp.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_companion_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.companion.camp.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp here.",
                    },
                    ["TL"] = {
                        "Magkampo tayo rito.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.companion.follow",
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
                                ["fallback"] = "Follow me.",
                                ["id"] = "default",
                                ["templateID"] = "convo.command.companion.follow.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Follow me.",
                                    },
                                    ["TL"] = {
                                        "Sumunod ka sa akin.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "FOLLOW",
                ["intent"] = "COMMAND",
            },
            ["namespace"] = "command.companion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Follow me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.companion.follow.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Follow me.",
                        },
                        ["TL"] = {
                            "Sumunod ka sa akin.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.companion.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "follow",
            ["sourceId"] = "command.companion.follow",
            ["sourcePath"] = "dialogue/companion_commands_player/command_companion_follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.companion",
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
                ["action"] = "FOLLOW",
                ["intent"] = "COMMAND",
            },
            ["postconditions"] = {
                "companion.following",
            },
            ["repeatPolicy"] = "state_retired",
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
                                        "Follow me.",
                                    },
                                    ["TL"] = {
                                        "Sumunod ka sa akin.",
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
                    ["id"] = "already_following",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_follow",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "eq",
                                ["path"] = "npcState.orderKind",
                                ["value"] = "follow",
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "follow",
                                    "following",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "followState.mode",
                                ["value"] = "follow",
                            },
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
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.companion.follow",
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
                            ["fallback"] = "Follow me.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.companion.follow.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_companion_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Follow me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.companion.follow.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.companion.return_home",
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
                                ["fallback"] = "Go home.",
                                ["id"] = "default",
                                ["templateID"] = "convo.command.companion.return_home.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Go home.",
                                    },
                                    ["TL"] = {
                                        "Umuwi ka na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "RETURN_HOME",
                ["intent"] = "COMMAND",
            },
            ["namespace"] = "command.companion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Go home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.companion.return_home.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Go home.",
                        },
                        ["TL"] = {
                            "Umuwi ka na.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.companion.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "return_home",
            ["sourceId"] = "command.companion.return_home",
            ["sourcePath"] = "dialogue/companion_commands_player/command_companion_return_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.companion",
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
                ["action"] = "RETURN_HOME",
                ["intent"] = "COMMAND",
            },
            ["postconditions"] = {
                "companion.returning_home",
            },
            ["repeatPolicy"] = "state_retired",
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
                                        "Go home.",
                                    },
                                    ["TL"] = {
                                        "Umuwi ka na.",
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
                    ["id"] = "already_returning",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_return_home",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "npcState.orderKind",
                        ["value"] = "return",
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
            ["responsePlanID"] = "command.companion.return_home",
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
                            ["fallback"] = "Go home.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.companion.return_home.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_companion_return_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Go home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.companion.return_home.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Go home.",
                    },
                    ["TL"] = {
                        "Umuwi ka na.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.companion.stay",
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
                                ["fallback"] = "Stay here.",
                                ["id"] = "default",
                                ["templateID"] = "convo.command.companion.stay.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stay here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka lang.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["action"] = "STAY",
                ["intent"] = "COMMAND",
            },
            ["namespace"] = "command.companion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Stay here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.companion.stay.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Stay here.",
                        },
                        ["TL"] = {
                            "Dito ka lang.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "command.companion.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stay",
            ["sourceId"] = "command.companion.stay",
            ["sourcePath"] = "dialogue/companion_commands_player/command_companion_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.companion",
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
                ["action"] = "STAY",
                ["intent"] = "COMMAND",
            },
            ["postconditions"] = {
                "companion.staying",
            },
            ["repeatPolicy"] = "state_retired",
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
                                        "Stay here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka lang.",
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
                    ["id"] = "already_staying",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "already_stay",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "npcState.orderKind",
                        ["value"] = "stay",
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
            ["responsePlanID"] = "command.companion.stay",
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
                            ["fallback"] = "Stay here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.companion.stay.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_companion_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Stay here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.companion.stay.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Stay here.",
                    },
                    ["TL"] = {
                        "Dito ka lang.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_auto",
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
                                ["fallback"] = "{addressee.name}, use your best judgment.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, use your best judgment.",
                                        "{addressee.name}, handle threats as you see fit.",
                                        "Watch our backs, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, gamitin ang iyong pasya.",
                                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                                        "Bantayan mo kami, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, use your best judgment.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, use your best judgment.",
                            "{addressee.name}, handle threats as you see fit.",
                            "Watch our backs, {addressee.name}.",
                        },
                        ["TL"] = {
                            "{addressee.name}, gamitin ang iyong pasya.",
                            "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                            "Bantayan mo kami, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_auto",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_auto",
            ["sourceId"] = "command.player.attack_auto",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_attack_auto.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, use your best judgment.",
                                        "{addressee.name}, handle threats as you see fit.",
                                        "Watch our backs, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, gamitin ang iyong pasya.",
                                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                                        "Bantayan mo kami, {addressee.name}.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_auto",
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
                            ["fallback"] = "{addressee.name}, use your best judgment.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.attack_auto.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_attack_auto.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, use your best judgment.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_auto.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, use your best judgment.",
                        "{addressee.name}, handle threats as you see fit.",
                        "Watch our backs, {addressee.name}.",
                    },
                    ["TL"] = {
                        "{addressee.name}, gamitin ang iyong pasya.",
                        "{addressee.name}, harapin ang banta ayon sa iyong pasya.",
                        "Bantayan mo kami, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_melee",
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
                                ["fallback"] = "{addressee.name}, keep it close.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep it close.",
                                        "Take the front line, {addressee.name}.",
                                        "{addressee.name}, save your ammunition.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, lumaban nang malapitan.",
                                        "Ikaw sa unahan, {addressee.name}.",
                                        "{addressee.name}, itabi ang bala.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, keep it close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, keep it close.",
                            "Take the front line, {addressee.name}.",
                            "{addressee.name}, save your ammunition.",
                        },
                        ["TL"] = {
                            "{addressee.name}, lumaban nang malapitan.",
                            "Ikaw sa unahan, {addressee.name}.",
                            "{addressee.name}, itabi ang bala.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_melee",
            ["sourceId"] = "command.player.attack_melee",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_attack_melee.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, keep it close.",
                                        "Take the front line, {addressee.name}.",
                                        "{addressee.name}, save your ammunition.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, lumaban nang malapitan.",
                                        "Ikaw sa unahan, {addressee.name}.",
                                        "{addressee.name}, itabi ang bala.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_melee",
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
                            ["fallback"] = "{addressee.name}, keep it close.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.attack_melee.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_attack_melee.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, keep it close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_melee.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, keep it close.",
                        "Take the front line, {addressee.name}.",
                        "{addressee.name}, save your ammunition.",
                    },
                    ["TL"] = {
                        "{addressee.name}, lumaban nang malapitan.",
                        "Ikaw sa unahan, {addressee.name}.",
                        "{addressee.name}, itabi ang bala.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_none",
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
                                ["fallback"] = "{addressee.name}, stay out of the fight.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, stay out of the fight.",
                                        "Avoid trouble, {addressee.name}.",
                                        "{addressee.name}, don't engage unless I change the order.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, huwag sumali sa laban.",
                                        "Iwasan ang gulo, {addressee.name}.",
                                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, stay out of the fight.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, stay out of the fight.",
                            "Avoid trouble, {addressee.name}.",
                            "{addressee.name}, don't engage unless I change the order.",
                        },
                        ["TL"] = {
                            "{addressee.name}, huwag sumali sa laban.",
                            "Iwasan ang gulo, {addressee.name}.",
                            "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_none",
            ["sourceId"] = "command.player.attack_none",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_attack_none.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, stay out of the fight.",
                                        "Avoid trouble, {addressee.name}.",
                                        "{addressee.name}, don't engage unless I change the order.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, huwag sumali sa laban.",
                                        "Iwasan ang gulo, {addressee.name}.",
                                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_none",
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
                            ["fallback"] = "{addressee.name}, stay out of the fight.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.attack_none.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_attack_none.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, stay out of the fight.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_none.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, stay out of the fight.",
                        "Avoid trouble, {addressee.name}.",
                        "{addressee.name}, don't engage unless I change the order.",
                    },
                    ["TL"] = {
                        "{addressee.name}, huwag sumali sa laban.",
                        "Iwasan ang gulo, {addressee.name}.",
                        "{addressee.name}, huwag lumaban hangga't hindi ko binabago ang utos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.attack_ranged",
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
                                ["fallback"] = "{addressee.name}, keep your distance.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, keep your distance.",
                                        "Give us ranged cover, {addressee.name}.",
                                        "{addressee.name}, engage from a safe distance.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, panatilihin ang distansya.",
                                        "Takpan kami mula sa malayo, {addressee.name}.",
                                        "{addressee.name}, lumaban mula sa ligtas na layo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, keep your distance.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, keep your distance.",
                            "Give us ranged cover, {addressee.name}.",
                            "{addressee.name}, engage from a safe distance.",
                        },
                        ["TL"] = {
                            "{addressee.name}, panatilihin ang distansya.",
                            "Takpan kami mula sa malayo, {addressee.name}.",
                            "{addressee.name}, lumaban mula sa ligtas na layo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "attack_ranged",
            ["sourceId"] = "command.player.attack_ranged",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_attack_ranged.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, keep your distance.",
                                        "Give us ranged cover, {addressee.name}.",
                                        "{addressee.name}, engage from a safe distance.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, panatilihin ang distansya.",
                                        "Takpan kami mula sa malayo, {addressee.name}.",
                                        "{addressee.name}, lumaban mula sa ligtas na layo.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.attack_ranged",
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
                            ["fallback"] = "{addressee.name}, keep your distance.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.attack_ranged.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_attack_ranged.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, keep your distance.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.attack_ranged.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, keep your distance.",
                        "Give us ranged cover, {addressee.name}.",
                        "{addressee.name}, engage from a safe distance.",
                    },
                    ["TL"] = {
                        "{addressee.name}, panatilihin ang distansya.",
                        "Takpan kami mula sa malayo, {addressee.name}.",
                        "{addressee.name}, lumaban mula sa ligtas na layo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp",
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
                                ["fallback"] = "Make camp here, {addressee.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Make camp here, {addressee.name}.",
                                        "Settle in here, {addressee.name}.",
                                        "We'll camp here for now, {addressee.name}.",
                                        "We could make camp here, {addressee.name}.",
                                        "Let's make this our camp, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito, {addressee.name}.",
                                        "Manatili tayo rito, {addressee.name}.",
                                        "Magkakampo muna tayo rito, {addressee.name}.",
                                        "Maaari tayong magkampo rito, {addressee.name}.",
                                        "Gawin nating kampo ito, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "Make camp here, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Make camp here, {addressee.name}.",
                            "Settle in here, {addressee.name}.",
                            "We'll camp here for now, {addressee.name}.",
                            "We could make camp here, {addressee.name}.",
                            "Let's make this our camp, {addressee.name}.",
                        },
                        ["TL"] = {
                            "Magkampo tayo rito, {addressee.name}.",
                            "Manatili tayo rito, {addressee.name}.",
                            "Magkakampo muna tayo rito, {addressee.name}.",
                            "Maaari tayong magkampo rito, {addressee.name}.",
                            "Gawin nating kampo ito, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp",
            ["sourceId"] = "command.player.camp",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_camp.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "Make camp here, {addressee.name}.",
                                        "Settle in here, {addressee.name}.",
                                        "We'll camp here for now, {addressee.name}.",
                                        "We could make camp here, {addressee.name}.",
                                        "Let's make this our camp, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo rito, {addressee.name}.",
                                        "Manatili tayo rito, {addressee.name}.",
                                        "Magkakampo muna tayo rito, {addressee.name}.",
                                        "Maaari tayong magkampo rito, {addressee.name}.",
                                        "Gawin nating kampo ito, {addressee.name}.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp",
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
                            ["fallback"] = "Make camp here, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.camp.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Make camp here, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Make camp here, {addressee.name}.",
                        "Settle in here, {addressee.name}.",
                        "We'll camp here for now, {addressee.name}.",
                        "We could make camp here, {addressee.name}.",
                        "Let's make this our camp, {addressee.name}.",
                    },
                    ["TL"] = {
                        "Magkampo tayo rito, {addressee.name}.",
                        "Manatili tayo rito, {addressee.name}.",
                        "Magkakampo muna tayo rito, {addressee.name}.",
                        "Maaari tayong magkampo rito, {addressee.name}.",
                        "Gawin nating kampo ito, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp_none",
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
                                ["fallback"] = "...",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "...",
                                    },
                                    ["TL"] = {
                                        "...",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "...",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "...",
                        },
                        ["TL"] = {
                            "...",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp_none",
            ["sourceId"] = "command.player.camp_none",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_camp_none.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "...",
                                    },
                                    ["TL"] = {
                                        "...",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp_none",
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
                            ["fallback"] = "...",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.camp_none.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_camp_none.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "...",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp_none.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "...",
                    },
                    ["TL"] = {
                        "...",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.camp_rejected",
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
                                ["fallback"] = "I can't find a safe room or campfire nearby.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't find a safe room or campfire nearby.",
                                        "We need a nearby room or campfire before we make camp.",
                                        "No usable camp site is visible from here.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                                        "Walang angkop na lugar ng kampo rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't find a safe room or campfire nearby.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't find a safe room or campfire nearby.",
                            "We need a nearby room or campfire before we make camp.",
                            "No usable camp site is visible from here.",
                        },
                        ["TL"] = {
                            "Wala akong makitang ligtas na silid o apoy dito.",
                            "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                            "Walang angkop na lugar ng kampo rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.camp_rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "camp_rejected",
            ["sourceId"] = "command.player.camp_rejected",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_camp_rejected.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "I can't find a safe room or campfire nearby.",
                                        "We need a nearby room or campfire before we make camp.",
                                        "No usable camp site is visible from here.",
                                    },
                                    ["TL"] = {
                                        "Wala akong makitang ligtas na silid o apoy dito.",
                                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                                        "Walang angkop na lugar ng kampo rito.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.camp_rejected",
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
                            ["fallback"] = "I can't find a safe room or campfire nearby.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.camp_rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_camp_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't find a safe room or campfire nearby.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.camp_rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't find a safe room or campfire nearby.",
                        "We need a nearby room or campfire before we make camp.",
                        "No usable camp site is visible from here.",
                    },
                    ["TL"] = {
                        "Wala akong makitang ligtas na silid o apoy dito.",
                        "Kailangan natin ng malapit na silid o apoy bago magkampo.",
                        "Walang angkop na lugar ng kampo rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.follow",
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
                                ["fallback"] = "{addressee.name}, on me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.follow.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, on me.",
                                        "Stay close, {addressee.name}.",
                                        "{addressee.name}, let's move.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, sumunod kayo sa akin.",
                                        "Manatili kayong malapit, {addressee.name}.",
                                        "{addressee.name}, umalis na tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, on me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.follow.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, on me.",
                            "Stay close, {addressee.name}.",
                            "{addressee.name}, let's move.",
                        },
                        ["TL"] = {
                            "{addressee.name}, sumunod kayo sa akin.",
                            "Manatili kayong malapit, {addressee.name}.",
                            "{addressee.name}, umalis na tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "follow",
            ["sourceId"] = "command.player.follow",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_follow.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, on me.",
                                        "Stay close, {addressee.name}.",
                                        "{addressee.name}, let's move.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, sumunod kayo sa akin.",
                                        "Manatili kayong malapit, {addressee.name}.",
                                        "{addressee.name}, umalis na tayo.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.follow",
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
                            ["fallback"] = "{addressee.name}, on me.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.follow.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, on me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.follow.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, on me.",
                        "Stay close, {addressee.name}.",
                        "{addressee.name}, let's move.",
                    },
                    ["TL"] = {
                        "{addressee.name}, sumunod kayo sa akin.",
                        "Manatili kayong malapit, {addressee.name}.",
                        "{addressee.name}, umalis na tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.generic",
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
                                ["fallback"] = "Understood, {addressee.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.generic.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Understood, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Naiintindihan ko, {addressee.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "Understood, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.generic.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Understood, {addressee.name}.",
                        },
                        ["TL"] = {
                            "Naiintindihan ko, {addressee.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.generic",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "generic",
            ["sourceId"] = "command.player.generic",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_generic.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "Understood, {addressee.name}.",
                                    },
                                    ["TL"] = {
                                        "Naiintindihan ko, {addressee.name}.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.generic",
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
                            ["fallback"] = "Understood, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.generic.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_generic.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Understood, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.generic.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Understood, {addressee.name}.",
                    },
                    ["TL"] = {
                        "Naiintindihan ko, {addressee.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.return_home",
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
                                ["fallback"] = "{addressee.name}, head home.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, head home.",
                                        "Return to the base, {addressee.name}.",
                                        "{addressee.name}, get back home safely.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, umuwi na kayo.",
                                        "Bumalik sa base, {addressee.name}.",
                                        "{addressee.name}, ligtas na umuwi.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, head home.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, head home.",
                            "Return to the base, {addressee.name}.",
                            "{addressee.name}, get back home safely.",
                        },
                        ["TL"] = {
                            "{addressee.name}, umuwi na kayo.",
                            "Bumalik sa base, {addressee.name}.",
                            "{addressee.name}, ligtas na umuwi.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.return_home",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "return_home",
            ["sourceId"] = "command.player.return_home",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_return_home.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, head home.",
                                        "Return to the base, {addressee.name}.",
                                        "{addressee.name}, get back home safely.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, umuwi na kayo.",
                                        "Bumalik sa base, {addressee.name}.",
                                        "{addressee.name}, ligtas na umuwi.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.return_home",
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
                            ["fallback"] = "{addressee.name}, head home.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.return_home.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_return_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, head home.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.return_home.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, head home.",
                        "Return to the base, {addressee.name}.",
                        "{addressee.name}, get back home safely.",
                    },
                    ["TL"] = {
                        "{addressee.name}, umuwi na kayo.",
                        "Bumalik sa base, {addressee.name}.",
                        "{addressee.name}, ligtas na umuwi.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_player",
        ["domainPath"] = "companion_commands_player",
        ["exchangeFamily"] = {
            ["familyID"] = "command.player.stay",
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
                                ["fallback"] = "{addressee.name}, wait here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.player.stay.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{addressee.name}, wait here.",
                                        "Hold this position, {addressee.name}.",
                                        "{addressee.name}, stay put for now.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, maghintay kayo rito.",
                                        "Panatilihin ang posisyon, {addressee.name}.",
                                        "{addressee.name}, manatili muna rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.player",
            ["textRoles"] = {
                {
                    ["fallback"] = "{addressee.name}, wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.player.stay.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{addressee.name}, wait here.",
                            "Hold this position, {addressee.name}.",
                            "{addressee.name}, stay put for now.",
                        },
                        ["TL"] = {
                            "{addressee.name}, maghintay kayo rito.",
                            "Panatilihin ang posisyon, {addressee.name}.",
                            "{addressee.name}, manatili muna rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.player.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stay",
            ["sourceId"] = "command.player.stay",
            ["sourcePath"] = "dialogue/companion_commands_player/command_player_stay.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsPlayer",
        ["namespace"] = "command.player",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseAct"] = "DIRECTIVE",
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
                                        "{addressee.name}, wait here.",
                                        "Hold this position, {addressee.name}.",
                                        "{addressee.name}, stay put for now.",
                                    },
                                    ["TL"] = {
                                        "{addressee.name}, maghintay kayo rito.",
                                        "Panatilihin ang posisyon, {addressee.name}.",
                                        "{addressee.name}, manatili muna rito.",
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
            ["dialogueAct"] = "DIRECTIVE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.player.stay",
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
                            ["fallback"] = "{addressee.name}, wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.command.player.stay.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/companion_commands_player/command_player_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{addressee.name}, wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.player.stay.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{addressee.name}, wait here.",
                        "Hold this position, {addressee.name}.",
                        "{addressee.name}, stay put for now.",
                    },
                    ["TL"] = {
                        "{addressee.name}, maghintay kayo rito.",
                        "Panatilihin ang posisyon, {addressee.name}.",
                        "{addressee.name}, manatili muna rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
