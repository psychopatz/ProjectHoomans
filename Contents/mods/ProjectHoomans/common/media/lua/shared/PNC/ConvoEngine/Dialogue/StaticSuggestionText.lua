-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.semantic_suggestions.title",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "title",
            ["sourceId"] = "ui.semantic_suggestions.title",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_semantic_suggestions_title.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.semantic_suggestions",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "semantic_suggestions.title",
                ["textRows"] = {
                    {
                        ["key"] = "semantic_suggestions.title",
                        ["text"] = {
                            ["EN"] = "CONTEXTUAL SUGGESTIONS",
                            ["TL"] = "MGA MUNGKAHING PANG-USAP",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "CONTEXTUAL SUGGESTIONS",
                },
                ["TL"] = {
                    "MGA MUNGKAHING PANG-USAP",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.semantic_suggestions.title",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.semantic_suggestions.title.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_semantic_suggestions_title.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.back.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.back.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_back_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.back",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.back.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.back.label",
                        ["text"] = {
                            ["EN"] = "Back",
                            ["TL"] = "Bumalik",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Back",
                },
                ["TL"] = {
                    "Bumalik",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.back.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Back",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.back.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_back_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.check_in.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.check_in.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_check_in_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.check_in",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.check_in.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.check_in.label",
                        ["text"] = {
                            ["EN"] = "Check in with them",
                            ["TL"] = "Kumusta tayo",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Check in with them",
                },
                ["TL"] = {
                    "Kumusta tayo",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.check_in.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Check in with them",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.check_in.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_check_in_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.check_in.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.check_in.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_check_in_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.check_in",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.check_in.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.check_in.utterance",
                        ["text"] = {
                            ["EN"] = "How are we doing?",
                            ["TL"] = "Kumusta tayo?",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "How are we doing?",
                },
                ["TL"] = {
                    "Kumusta tayo?",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.check_in.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "How are we doing?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.check_in.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_check_in_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.companion_camp.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.companion_camp.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.companion_camp",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.companion_camp.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_camp.label",
                        ["text"] = {
                            ["EN"] = "Let's camp...",
                            ["TL"] = "Magkampo tayo...",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's camp...",
                },
                ["TL"] = {
                    "Magkampo tayo...",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let's camp...",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.companion_camp_here.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.companion_camp_here.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_here_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.companion_camp_here",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.companion_camp_here.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_camp_here.utterance",
                        ["text"] = {
                            ["EN"] = "Let's camp here.",
                            ["TL"] = "Magkampo tayo rito.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's camp here.",
                },
                ["TL"] = {
                    "Magkampo tayo rito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp_here.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let's camp here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp_here.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_here_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.companion_camp_room.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.companion_camp_room.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_room_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.companion_camp_room",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.companion_camp_room.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_camp_room.utterance",
                        ["text"] = {
                            ["EN"] = "Let's camp in the %1.",
                            ["TL"] = "Magkampo tayo sa %1.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's camp in the %1.",
                },
                ["TL"] = {
                    "Magkampo tayo sa %1.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp_room.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let's camp in the %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp_room.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_camp_room_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.companion_campfire.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.companion_campfire.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_campfire_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.companion_campfire",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.companion_campfire.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_campfire.utterance",
                        ["text"] = {
                            ["EN"] = "Let's camp by the campfire.",
                            ["TL"] = "Magkampo tayo sa tabi ng apoy.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's camp by the campfire.",
                },
                ["TL"] = {
                    "Magkampo tayo sa tabi ng apoy.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_campfire.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let's camp by the campfire.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_campfire.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_campfire_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.companion_orders.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.companion_orders.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_orders_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.companion_orders",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.companion_orders.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_orders.label",
                        ["text"] = {
                            ["EN"] = "I need you to do something...",
                            ["TL"] = "May ipapagawa ako sa iyo...",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "I need you to do something...",
                },
                ["TL"] = {
                    "May ipapagawa ako sa iyo...",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_orders.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I need you to do something...",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_orders.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_companion_orders_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.follow.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.follow.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_follow_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.follow",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.follow.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.follow.label",
                        ["text"] = {
                            ["EN"] = "Follow me.",
                            ["TL"] = "Sumunod ka sa akin.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Follow me.",
                },
                ["TL"] = {
                    "Sumunod ka sa akin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.follow.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Follow me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.follow.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_follow_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.follow.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.follow.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_follow_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.follow",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.follow.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.follow.utterance",
                        ["text"] = {
                            ["EN"] = "Follow me.",
                            ["TL"] = "Sumunod ka sa akin.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Follow me.",
                },
                ["TL"] = {
                    "Sumunod ka sa akin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.follow.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Follow me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.follow.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_follow_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.greeting_report_fine.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.greeting_report_fine.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.greeting_report_fine",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.greeting_report_fine.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_report_fine.label",
                        ["text"] = {
                            ["EN"] = "Say you're doing fine",
                            ["TL"] = "Sabihing ayos ka lang",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Say you're doing fine",
                },
                ["TL"] = {
                    "Sabihing ayos ka lang",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_report_fine.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Say you're doing fine",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_report_fine.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.greeting_report_fine.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.greeting_report_fine.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.greeting_report_fine",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.greeting_report_fine.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_report_fine.utterance",
                        ["text"] = {
                            ["EN"] = "I'm fine, thank you.",
                            ["TL"] = "Ayos lang ako, salamat.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "I'm fine, thank you.",
                },
                ["TL"] = {
                    "Ayos lang ako, salamat.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_report_fine.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm fine, thank you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_report_fine.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.greeting_thank.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.greeting_thank.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_thank_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.greeting_thank",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.greeting_thank.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_thank.label",
                        ["text"] = {
                            ["EN"] = "Thank them",
                            ["TL"] = "Pasalamatan siya",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Thank them",
                },
                ["TL"] = {
                    "Pasalamatan siya",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_thank.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Thank them",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_thank.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_thank_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.greeting_thank.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.greeting_thank.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_thank_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.greeting_thank",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.greeting_thank.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_thank.utterance",
                        ["text"] = {
                            ["EN"] = "Thanks.",
                            ["TL"] = "Salamat.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Thanks.",
                },
                ["TL"] = {
                    "Salamat.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_thank.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Thanks.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_thank.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_greeting_thank_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.actions.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.actions.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_actions_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.actions",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.actions.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.actions.label",
                        ["text"] = {
                            ["EN"] = "Conversation actions",
                            ["TL"] = "Mga aksyon sa usapan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Conversation actions",
                },
                ["TL"] = {
                    "Mga aksyon sa usapan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.actions.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Conversation actions",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.actions.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_actions_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.flow.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.flow.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_flow_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.flow",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.flow.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.flow.label",
                        ["text"] = {
                            ["EN"] = "Current conversation branch",
                            ["TL"] = "Kasalukuyang sangay ng usapan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Current conversation branch",
                },
                ["TL"] = {
                    "Kasalukuyang sangay ng usapan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.flow.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Current conversation branch",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.flow.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_flow_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.identity.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.identity.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_identity_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.identity",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.identity.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.identity.label",
                        ["text"] = {
                            ["EN"] = "Identity",
                            ["TL"] = "Pagkakakilanlan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Identity",
                },
                ["TL"] = {
                    "Pagkakakilanlan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.identity.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Identity",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.identity.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_identity_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.landing.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.landing.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_landing_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.landing",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.landing.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.landing.label",
                        ["text"] = {
                            ["EN"] = "Talk",
                            ["TL"] = "Usapan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Talk",
                },
                ["TL"] = {
                    "Usapan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.landing.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Talk",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.landing.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_landing_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.medical.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.medical.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_medical_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.medical",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.medical.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.medical.label",
                        ["text"] = {
                            ["EN"] = "Medical",
                            ["TL"] = "Medikal",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Medical",
                },
                ["TL"] = {
                    "Medikal",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.medical.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Medical",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.medical.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_medical_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.movement.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.movement.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_movement_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.movement",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.movement.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.movement.label",
                        ["text"] = {
                            ["EN"] = "Owned companion actions",
                            ["TL"] = "Mga utos sa kasamang pag-aari",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Owned companion actions",
                },
                ["TL"] = {
                    "Mga utos sa kasamang pag-aari",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.movement.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Owned companion actions",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.movement.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_movement_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.needs.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.needs.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_needs_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.needs",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.needs.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.needs.label",
                        ["text"] = {
                            ["EN"] = "Needs",
                            ["TL"] = "Pangangailangan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Needs",
                },
                ["TL"] = {
                    "Pangangailangan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.needs.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Needs",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.needs.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_needs_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.response.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.response.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_response_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.response",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.response.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.response.label",
                        ["text"] = {
                            ["EN"] = "NPC reply",
                            ["TL"] = "Sagot ng NPC",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "NPC reply",
                },
                ["TL"] = {
                    "Sagot ng NPC",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.response.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "NPC reply",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.response.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_response_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.time.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.time.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_time_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.time",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.time.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.time.label",
                        ["text"] = {
                            ["EN"] = "Time and date",
                            ["TL"] = "Oras at petsa",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Time and date",
                },
                ["TL"] = {
                    "Oras at petsa",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.time.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Time and date",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.time.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_time_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.utilities.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.utilities.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_utilities_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.utilities",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.utilities.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.utilities.label",
                        ["text"] = {
                            ["EN"] = "Conversation utilities",
                            ["TL"] = "Mga gamit sa usapan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Conversation utilities",
                },
                ["TL"] = {
                    "Mga gamit sa usapan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.utilities.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Conversation utilities",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.utilities.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_utilities_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.weather.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.weather.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_weather_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.weather",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.weather.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.weather.label",
                        ["text"] = {
                            ["EN"] = "Weather",
                            ["TL"] = "Panahon",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Weather",
                },
                ["TL"] = {
                    "Panahon",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.weather.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Weather",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.weather.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_weather_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.wellbeing.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.wellbeing.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_wellbeing_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.wellbeing",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.wellbeing.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.wellbeing.label",
                        ["text"] = {
                            ["EN"] = "Wellbeing",
                            ["TL"] = "Kalagayan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Wellbeing",
                },
                ["TL"] = {
                    "Kalagayan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.wellbeing.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Wellbeing",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.wellbeing.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_wellbeing_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.group.whats_up.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.whats_up.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.group.whats_up",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.group.whats_up.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.whats_up.label",
                        ["text"] = {
                            ["EN"] = "What's up",
                            ["TL"] = "Ano ang balita",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "What's up",
                },
                ["TL"] = {
                    "Ano ang balita",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.whats_up.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "What's up",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.whats_up.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_group_whats_up_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.lie.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.identity.lie.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_lie_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.identity.lie",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.identity.lie.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.lie.label",
                        ["text"] = {
                            ["EN"] = "Lie about your name",
                            ["TL"] = "Magsinungaling tungkol sa pangalan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Lie about your name",
                },
                ["TL"] = {
                    "Magsinungaling tungkol sa pangalan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.lie.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Lie about your name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.lie.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_lie_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.lie.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.identity.lie.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_lie_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.identity.lie",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.identity.lie.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.lie.utterance",
                        ["text"] = {
                            ["EN"] = "I'll go by a different name.",
                            ["TL"] = "Ibang pangalan ang gagamitin ko.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "I'll go by a different name.",
                },
                ["TL"] = {
                    "Ibang pangalan ang gagamitin ko.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.lie.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'll go by a different name.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.lie.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_lie_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.real.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.identity.real.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_real_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.identity.real",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.identity.real.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.real.label",
                        ["text"] = {
                            ["EN"] = "Say your real name",
                            ["TL"] = "Sabihin ang tunay mong pangalan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Say your real name",
                },
                ["TL"] = {
                    "Sabihin ang tunay mong pangalan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.real.label",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Say your real name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.real.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_real_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.real.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.identity.real.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_real_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
        ["namespace"] = "ui.suggestion.identity.real",
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
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textKey"] = "suggestion.identity.real.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.real.utterance",
                        ["text"] = {
                            ["EN"] = "My real name.",
                            ["TL"] = "Tunay kong pangalan.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "My real name.",
                },
                ["TL"] = {
                    "Tunay kong pangalan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.real.utterance",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "My real name.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.real.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_real_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
