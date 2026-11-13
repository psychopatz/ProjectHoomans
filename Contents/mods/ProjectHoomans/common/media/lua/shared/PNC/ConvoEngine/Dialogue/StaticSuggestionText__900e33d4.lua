-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.rude.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.identity.rude.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.identity.rude",
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
                ["textKey"] = "suggestion.identity.rude.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.rude.label",
                        ["text"] = {
                            ["EN"] = "Don't tell your name",
                            ["TL"] = "Huwag sabihin ang pangalan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Don't tell your name",
                },
                ["TL"] = {
                    "Huwag sabihin ang pangalan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.rude.label",
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
                            ["fallback"] = "Don't tell your name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.rude.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.identity.rude.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.identity.rude.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.identity.rude",
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
                ["textKey"] = "suggestion.identity.rude.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.rude.utterance",
                        ["text"] = {
                            ["EN"] = "That's none of your business.",
                            ["TL"] = "Wala ka nang pakialam.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "That's none of your business.",
                },
                ["TL"] = {
                    "Wala ka nang pakialam.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.rude.utterance",
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
                            ["fallback"] = "That's none of your business.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.rude.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.needs_destination.tooltip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.needs_destination.tooltip",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_needs_destination_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.needs_destination",
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
                ["textKey"] = "suggestion.needs_destination.tooltip",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.needs_destination.tooltip",
                        ["text"] = {
                            ["EN"] = "Choose a destination first.",
                            ["TL"] = "Pumili muna ng pupuntahan.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Choose a destination first.",
                },
                ["TL"] = {
                    "Pumili muna ng pupuntahan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.needs_destination.tooltip",
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
                            ["fallback"] = "Choose a destination first.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.needs_destination.tooltip.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_needs_destination_tooltip.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.personal_check_in.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.personal_check_in.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.personal_check_in",
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
                ["textKey"] = "suggestion.personal_check_in.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.personal_check_in.label",
                        ["text"] = {
                            ["EN"] = "Ask what's on their mind",
                            ["TL"] = "Alamin kung may bumabagabag sa kanya",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Ask what's on their mind",
                },
                ["TL"] = {
                    "Alamin kung may bumabagabag sa kanya",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.personal_check_in.label",
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
                            ["fallback"] = "Ask what's on their mind",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.personal_check_in.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.personal_check_in.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.personal_check_in.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.personal_check_in",
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
                ["textKey"] = "suggestion.personal_check_in.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.personal_check_in.utterance",
                        ["text"] = {
                            ["EN"] = "Anything bothering you?",
                            ["TL"] = "May bumabagabag ba sa'yo?",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Anything bothering you?",
                },
                ["TL"] = {
                    "May bumabagabag ba sa'yo?",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.personal_check_in.utterance",
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
                            ["fallback"] = "Anything bothering you?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.personal_check_in.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.stay.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.stay.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.stay",
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
                ["textKey"] = "suggestion.stay.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.stay.label",
                        ["text"] = {
                            ["EN"] = "Wait here.",
                            ["TL"] = "Dito ka maghintay.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Wait here.",
                },
                ["TL"] = {
                    "Dito ka maghintay.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.stay.label",
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
                            ["fallback"] = "Wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.stay.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.stay.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.stay.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.stay",
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
                ["textKey"] = "suggestion.stay.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.stay.utterance",
                        ["text"] = {
                            ["EN"] = "Wait here.",
                            ["TL"] = "Dito ka maghintay.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Wait here.",
                },
                ["TL"] = {
                    "Dito ka maghintay.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.stay.utterance",
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
                            ["fallback"] = "Wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.stay.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.talk_again_about.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_again_about.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.talk_again_about",
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
                ["textKey"] = "suggestion.talk_again_about.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.talk_again_about.label",
                        ["text"] = {
                            ["EN"] = "Talk again about",
                            ["TL"] = "Pag-usapan muli ang",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Talk again about",
                },
                ["TL"] = {
                    "Pag-usapan muli ang",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.talk_again_about.label",
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
                            ["fallback"] = "Talk again about",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.talk_again_about.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.talk_something_else.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_something_else.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.talk_something_else",
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
                ["textKey"] = "suggestion.talk_something_else.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.talk_something_else.label",
                        ["text"] = {
                            ["EN"] = "Let's talk something else",
                            ["TL"] = "Iba naman ang pag-usapan natin",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's talk something else",
                },
                ["TL"] = {
                    "Iba naman ang pag-usapan natin",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.talk_something_else.label",
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
                            ["fallback"] = "Let's talk something else",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.talk_something_else.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.trade.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.trade.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.trade",
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
                ["textKey"] = "suggestion.trade.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.trade.label",
                        ["text"] = {
                            ["EN"] = "Open trading",
                            ["TL"] = "Buksan ang kalakalan",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Open trading",
                },
                ["TL"] = {
                    "Buksan ang kalakalan",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.trade.label",
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
                            ["fallback"] = "Open trading",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.trade.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.trade.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.trade.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.trade",
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
                ["textKey"] = "suggestion.trade.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.trade.utterance",
                        ["text"] = {
                            ["EN"] = "Let's trade.",
                            ["TL"] = "Magpalitan tayo.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Let's trade.",
                },
                ["TL"] = {
                    "Magpalitan tayo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.trade.utterance",
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
                            ["fallback"] = "Let's trade.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.trade.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.unavailable.tooltip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.unavailable.tooltip",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.unavailable",
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
                ["textKey"] = "suggestion.unavailable.tooltip",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.unavailable.tooltip",
                        ["text"] = {
                            ["EN"] = "Unavailable in the current situation.",
                            ["TL"] = "Hindi magagamit sa kasalukuyang sitwasyon.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Unavailable in the current situation.",
                },
                ["TL"] = {
                    "Hindi magagamit sa kasalukuyang sitwasyon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.unavailable.tooltip",
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
                            ["fallback"] = "Unavailable in the current situation.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.unavailable.tooltip.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.wait_at.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.wait_at.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.wait_at",
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
                ["textKey"] = "suggestion.wait_at.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.wait_at.label",
                        ["text"] = {
                            ["EN"] = "Ask them to wait there",
                            ["TL"] = "Sabihing maghintay siya roon",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Ask them to wait there",
                },
                ["TL"] = {
                    "Sabihing maghintay siya roon",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.wait_at.label",
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
                            ["fallback"] = "Ask them to wait there",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.wait_at.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.wait_at.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.wait_at.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.wait_at",
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
                ["textKey"] = "suggestion.wait_at.utterance",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.wait_at.utterance",
                        ["text"] = {
                            ["EN"] = "Wait there.",
                            ["TL"] = "Maghintay ka roon.",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "Wait there.",
                },
                ["TL"] = {
                    "Maghintay ka roon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.wait_at.utterance",
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
                            ["fallback"] = "Wait there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.wait_at.utterance.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_utterance.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["id"] = "ui.suggestion.whats_up.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.whats_up.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__900e33d4",
        ["namespace"] = "ui.suggestion.whats_up",
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
                ["textKey"] = "suggestion.whats_up.label",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.whats_up.label",
                        ["text"] = {
                            ["EN"] = "What's up?",
                            ["TL"] = "Ano ang balita?",
                        },
                    },
                },
                ["textTarget"] = "UI_PNC_Conversation",
            },
            ["text"] = {
                ["EN"] = {
                    "What's up?",
                },
                ["TL"] = {
                    "Ano ang balita?",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.whats_up.label",
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
                            ["fallback"] = "What's up?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.whats_up.label.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
