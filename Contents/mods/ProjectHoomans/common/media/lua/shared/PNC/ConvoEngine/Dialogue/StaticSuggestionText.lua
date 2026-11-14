-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.semantic_suggestions.title",
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
                                ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.semantic_suggestions.title.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "CONTEXTUAL SUGGESTIONS",
                                    },
                                    ["TL"] = {
                                        "MGA MUNGKAHING PANG-USAP",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.semantic_suggestions",
            ["textRoles"] = {
                {
                    ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.semantic_suggestions.title.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "CONTEXTUAL SUGGESTIONS",
                        },
                        ["TL"] = {
                            "MGA MUNGKAHING PANG-USAP",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "CONTEXTUAL SUGGESTIONS",
                                    },
                                    ["TL"] = {
                                        "MGA MUNGKAHING PANG-USAP",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.semantic_suggestions.title",
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
                            ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.semantic_suggestions.title.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.semantic_suggestions.title.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "CONTEXTUAL SUGGESTIONS",
                    },
                    ["TL"] = {
                        "MGA MUNGKAHING PANG-USAP",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.back.label",
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
                                ["fallback"] = "Back",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.back.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Back",
                                    },
                                    ["TL"] = {
                                        "Bumalik",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.back",
            ["textRoles"] = {
                {
                    ["fallback"] = "Back",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.back.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Back",
                        },
                        ["TL"] = {
                            "Bumalik",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Back",
                                    },
                                    ["TL"] = {
                                        "Bumalik",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.back.label",
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
                            ["fallback"] = "Back",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.back.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Back",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.back.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Back",
                    },
                    ["TL"] = {
                        "Bumalik",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.check_in.label",
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
                                ["fallback"] = "Check in with them",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.check_in.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Check in with them",
                                    },
                                    ["TL"] = {
                                        "Kumusta tayo",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.check_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "Check in with them",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.check_in.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Check in with them",
                        },
                        ["TL"] = {
                            "Kumusta tayo",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Check in with them",
                                    },
                                    ["TL"] = {
                                        "Kumusta tayo",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.check_in.label",
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
                            ["fallback"] = "Check in with them",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.check_in.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Check in with them",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.check_in.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Check in with them",
                    },
                    ["TL"] = {
                        "Kumusta tayo",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.check_in.utterance",
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
                                ["fallback"] = "How are we doing?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.check_in.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "How are we doing?",
                                    },
                                    ["TL"] = {
                                        "Kumusta tayo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.check_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "How are we doing?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.check_in.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "How are we doing?",
                        },
                        ["TL"] = {
                            "Kumusta tayo?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "How are we doing?",
                                    },
                                    ["TL"] = {
                                        "Kumusta tayo?",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.check_in.utterance",
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
                            ["fallback"] = "How are we doing?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.check_in.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "How are we doing?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.check_in.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "How are we doing?",
                    },
                    ["TL"] = {
                        "Kumusta tayo?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.companion_camp.label",
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
                                ["fallback"] = "Let's camp...",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.companion_camp.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's camp...",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo...",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.companion_camp",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp...",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp...",
                        },
                        ["TL"] = {
                            "Magkampo tayo...",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Let's camp...",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo...",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp.label",
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
                            ["fallback"] = "Let's camp...",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp...",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp...",
                    },
                    ["TL"] = {
                        "Magkampo tayo...",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.companion_camp_here.utterance",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.companion_camp_here.utterance.say.1.neutral",
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
            ["namespace"] = "ui.suggestion.companion_camp_here",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp_here.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp here.",
                        },
                        ["TL"] = {
                            "Magkampo tayo rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Let's camp here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp_here.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp_here.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp here.",
                    },
                    ["TL"] = {
                        "Magkampo tayo rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.companion_camp_room.utterance",
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
                                ["fallback"] = "Let's camp in the %1.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.companion_camp_room.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's camp in the %1.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo sa %1.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.companion_camp_room",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp in the %1.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp_room.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp in the %1.",
                        },
                        ["TL"] = {
                            "Magkampo tayo sa %1.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Let's camp in the %1.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo sa %1.",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp_room.utterance",
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
                            ["fallback"] = "Let's camp in the %1.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_camp_room.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp in the %1.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp_room.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp in the %1.",
                    },
                    ["TL"] = {
                        "Magkampo tayo sa %1.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.companion_campfire.utterance",
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
                                ["fallback"] = "Let's camp by the campfire.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.companion_campfire.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's camp by the campfire.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo sa tabi ng apoy.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.companion_campfire",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp by the campfire.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_campfire.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp by the campfire.",
                        },
                        ["TL"] = {
                            "Magkampo tayo sa tabi ng apoy.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Let's camp by the campfire.",
                                    },
                                    ["TL"] = {
                                        "Magkampo tayo sa tabi ng apoy.",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_campfire.utterance",
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
                            ["fallback"] = "Let's camp by the campfire.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_campfire.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp by the campfire.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_campfire.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp by the campfire.",
                    },
                    ["TL"] = {
                        "Magkampo tayo sa tabi ng apoy.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.companion_orders.label",
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
                                ["fallback"] = "I need you to do something...",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.companion_orders.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I need you to do something...",
                                    },
                                    ["TL"] = {
                                        "May ipapagawa ako sa iyo...",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.companion_orders",
            ["textRoles"] = {
                {
                    ["fallback"] = "I need you to do something...",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_orders.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I need you to do something...",
                        },
                        ["TL"] = {
                            "May ipapagawa ako sa iyo...",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "I need you to do something...",
                                    },
                                    ["TL"] = {
                                        "May ipapagawa ako sa iyo...",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_orders.label",
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
                            ["fallback"] = "I need you to do something...",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.companion_orders.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "I need you to do something...",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_orders.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I need you to do something...",
                    },
                    ["TL"] = {
                        "May ipapagawa ako sa iyo...",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.follow.label",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.follow.label.say.1.neutral",
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
            ["namespace"] = "ui.suggestion.follow",
            ["textRoles"] = {
                {
                    ["fallback"] = "Follow me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.follow.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Follow me.",
                        },
                        ["TL"] = {
                            "Sumunod ka sa akin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Follow me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.follow.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Follow me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.follow.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.follow.utterance",
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
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.follow.utterance.say.1.neutral",
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
            ["namespace"] = "ui.suggestion.follow",
            ["textRoles"] = {
                {
                    ["fallback"] = "Follow me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.follow.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Follow me.",
                        },
                        ["TL"] = {
                            "Sumunod ka sa akin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Follow me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.follow.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Follow me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.follow.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.greeting_report_fine.label",
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
                                ["fallback"] = "Say you're doing fine",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Say you're doing fine",
                                    },
                                    ["TL"] = {
                                        "Sabihing ayos ka lang",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.greeting_report_fine",
            ["textRoles"] = {
                {
                    ["fallback"] = "Say you're doing fine",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_report_fine.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Say you're doing fine",
                        },
                        ["TL"] = {
                            "Sabihing ayos ka lang",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Say you're doing fine",
                                    },
                                    ["TL"] = {
                                        "Sabihing ayos ka lang",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_report_fine.label",
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
                            ["fallback"] = "Say you're doing fine",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_report_fine.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Say you're doing fine",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Say you're doing fine",
                    },
                    ["TL"] = {
                        "Sabihing ayos ka lang",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.greeting_report_fine.utterance",
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
                                ["fallback"] = "I'm fine, thank you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm fine, thank you.",
                                    },
                                    ["TL"] = {
                                        "Ayos lang ako, salamat.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.greeting_report_fine",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm fine, thank you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_report_fine.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm fine, thank you.",
                        },
                        ["TL"] = {
                            "Ayos lang ako, salamat.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "I'm fine, thank you.",
                                    },
                                    ["TL"] = {
                                        "Ayos lang ako, salamat.",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_report_fine.utterance",
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
                            ["fallback"] = "I'm fine, thank you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_report_fine.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "I'm fine, thank you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm fine, thank you.",
                    },
                    ["TL"] = {
                        "Ayos lang ako, salamat.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.greeting_thank.label",
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
                                ["fallback"] = "Thank them",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.greeting_thank.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Thank them",
                                    },
                                    ["TL"] = {
                                        "Pasalamatan siya",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.greeting_thank",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thank them",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_thank.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Thank them",
                        },
                        ["TL"] = {
                            "Pasalamatan siya",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Thank them",
                                    },
                                    ["TL"] = {
                                        "Pasalamatan siya",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_thank.label",
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
                            ["fallback"] = "Thank them",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_thank.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Thank them",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_thank.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Thank them",
                    },
                    ["TL"] = {
                        "Pasalamatan siya",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.greeting_thank.utterance",
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
                                ["fallback"] = "Thanks.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.greeting_thank.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Thanks.",
                                    },
                                    ["TL"] = {
                                        "Salamat.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.greeting_thank",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_thank.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Thanks.",
                        },
                        ["TL"] = {
                            "Salamat.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Thanks.",
                                    },
                                    ["TL"] = {
                                        "Salamat.",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_thank.utterance",
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
                            ["fallback"] = "Thanks.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.greeting_thank.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Thanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_thank.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Thanks.",
                    },
                    ["TL"] = {
                        "Salamat.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.actions.label",
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
                                ["fallback"] = "Conversation actions",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.actions.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Conversation actions",
                                    },
                                    ["TL"] = {
                                        "Mga aksyon sa usapan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.actions",
            ["textRoles"] = {
                {
                    ["fallback"] = "Conversation actions",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.actions.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Conversation actions",
                        },
                        ["TL"] = {
                            "Mga aksyon sa usapan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Conversation actions",
                                    },
                                    ["TL"] = {
                                        "Mga aksyon sa usapan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.actions.label",
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
                            ["fallback"] = "Conversation actions",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.actions.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Conversation actions",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.actions.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Conversation actions",
                    },
                    ["TL"] = {
                        "Mga aksyon sa usapan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.flow.label",
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
                                ["fallback"] = "Current conversation branch",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.flow.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Current conversation branch",
                                    },
                                    ["TL"] = {
                                        "Kasalukuyang sangay ng usapan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.flow",
            ["textRoles"] = {
                {
                    ["fallback"] = "Current conversation branch",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.flow.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Current conversation branch",
                        },
                        ["TL"] = {
                            "Kasalukuyang sangay ng usapan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Current conversation branch",
                                    },
                                    ["TL"] = {
                                        "Kasalukuyang sangay ng usapan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.flow.label",
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
                            ["fallback"] = "Current conversation branch",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.flow.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Current conversation branch",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.flow.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Current conversation branch",
                    },
                    ["TL"] = {
                        "Kasalukuyang sangay ng usapan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.identity.label",
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
                                ["fallback"] = "Identity",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.identity.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Identity",
                                    },
                                    ["TL"] = {
                                        "Pagkakakilanlan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.identity",
            ["textRoles"] = {
                {
                    ["fallback"] = "Identity",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.identity.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Identity",
                        },
                        ["TL"] = {
                            "Pagkakakilanlan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Identity",
                                    },
                                    ["TL"] = {
                                        "Pagkakakilanlan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.identity.label",
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
                            ["fallback"] = "Identity",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.identity.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Identity",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.identity.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Identity",
                    },
                    ["TL"] = {
                        "Pagkakakilanlan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.landing.label",
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
                                ["fallback"] = "Talk",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.landing.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Talk",
                                    },
                                    ["TL"] = {
                                        "Usapan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.landing",
            ["textRoles"] = {
                {
                    ["fallback"] = "Talk",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.landing.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Talk",
                        },
                        ["TL"] = {
                            "Usapan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Talk",
                                    },
                                    ["TL"] = {
                                        "Usapan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.landing.label",
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
                            ["fallback"] = "Talk",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.landing.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Talk",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.landing.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Talk",
                    },
                    ["TL"] = {
                        "Usapan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.medical.label",
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
                                ["fallback"] = "Medical",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.medical.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Medical",
                                    },
                                    ["TL"] = {
                                        "Medikal",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.medical",
            ["textRoles"] = {
                {
                    ["fallback"] = "Medical",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.medical.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Medical",
                        },
                        ["TL"] = {
                            "Medikal",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Medical",
                                    },
                                    ["TL"] = {
                                        "Medikal",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.medical.label",
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
                            ["fallback"] = "Medical",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.medical.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Medical",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.medical.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Medical",
                    },
                    ["TL"] = {
                        "Medikal",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.movement.label",
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
                                ["fallback"] = "Owned companion actions",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.movement.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Owned companion actions",
                                    },
                                    ["TL"] = {
                                        "Mga utos sa kasamang pag-aari",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.movement",
            ["textRoles"] = {
                {
                    ["fallback"] = "Owned companion actions",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.movement.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Owned companion actions",
                        },
                        ["TL"] = {
                            "Mga utos sa kasamang pag-aari",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Owned companion actions",
                                    },
                                    ["TL"] = {
                                        "Mga utos sa kasamang pag-aari",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.movement.label",
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
                            ["fallback"] = "Owned companion actions",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.movement.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Owned companion actions",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.movement.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Owned companion actions",
                    },
                    ["TL"] = {
                        "Mga utos sa kasamang pag-aari",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.needs.label",
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
                                ["fallback"] = "Needs",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.needs.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Needs",
                                    },
                                    ["TL"] = {
                                        "Pangangailangan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.needs",
            ["textRoles"] = {
                {
                    ["fallback"] = "Needs",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.needs.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Needs",
                        },
                        ["TL"] = {
                            "Pangangailangan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Needs",
                                    },
                                    ["TL"] = {
                                        "Pangangailangan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.needs.label",
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
                            ["fallback"] = "Needs",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.needs.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Needs",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.needs.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Needs",
                    },
                    ["TL"] = {
                        "Pangangailangan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.response.label",
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
                                ["fallback"] = "NPC reply",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.response.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "NPC reply",
                                    },
                                    ["TL"] = {
                                        "Sagot ng NPC",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.response",
            ["textRoles"] = {
                {
                    ["fallback"] = "NPC reply",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.response.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "NPC reply",
                        },
                        ["TL"] = {
                            "Sagot ng NPC",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "NPC reply",
                                    },
                                    ["TL"] = {
                                        "Sagot ng NPC",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.response.label",
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
                            ["fallback"] = "NPC reply",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.response.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "NPC reply",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.response.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "NPC reply",
                    },
                    ["TL"] = {
                        "Sagot ng NPC",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.time.label",
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
                                ["fallback"] = "Time and date",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.time.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Time and date",
                                    },
                                    ["TL"] = {
                                        "Oras at petsa",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.time",
            ["textRoles"] = {
                {
                    ["fallback"] = "Time and date",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.time.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Time and date",
                        },
                        ["TL"] = {
                            "Oras at petsa",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Time and date",
                                    },
                                    ["TL"] = {
                                        "Oras at petsa",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.time.label",
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
                            ["fallback"] = "Time and date",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.time.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Time and date",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.time.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Time and date",
                    },
                    ["TL"] = {
                        "Oras at petsa",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.utilities.label",
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
                                ["fallback"] = "Conversation utilities",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.utilities.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Conversation utilities",
                                    },
                                    ["TL"] = {
                                        "Mga gamit sa usapan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.utilities",
            ["textRoles"] = {
                {
                    ["fallback"] = "Conversation utilities",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.utilities.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Conversation utilities",
                        },
                        ["TL"] = {
                            "Mga gamit sa usapan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Conversation utilities",
                                    },
                                    ["TL"] = {
                                        "Mga gamit sa usapan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.utilities.label",
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
                            ["fallback"] = "Conversation utilities",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.utilities.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Conversation utilities",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.utilities.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Conversation utilities",
                    },
                    ["TL"] = {
                        "Mga gamit sa usapan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.weather.label",
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
                                ["fallback"] = "Weather",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.weather.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Weather",
                                    },
                                    ["TL"] = {
                                        "Panahon",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.weather",
            ["textRoles"] = {
                {
                    ["fallback"] = "Weather",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.weather.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Weather",
                        },
                        ["TL"] = {
                            "Panahon",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Weather",
                                    },
                                    ["TL"] = {
                                        "Panahon",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.weather.label",
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
                            ["fallback"] = "Weather",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.weather.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Weather",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.weather.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Weather",
                    },
                    ["TL"] = {
                        "Panahon",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.wellbeing.label",
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
                                ["fallback"] = "Wellbeing",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.wellbeing.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Wellbeing",
                                    },
                                    ["TL"] = {
                                        "Kalagayan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wellbeing",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.wellbeing.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Wellbeing",
                        },
                        ["TL"] = {
                            "Kalagayan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Wellbeing",
                                    },
                                    ["TL"] = {
                                        "Kalagayan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.wellbeing.label",
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
                            ["fallback"] = "Wellbeing",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.wellbeing.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Wellbeing",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.wellbeing.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Wellbeing",
                    },
                    ["TL"] = {
                        "Kalagayan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group.whats_up.label",
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
                                ["fallback"] = "What's up",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.group.whats_up.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What's up",
                                    },
                                    ["TL"] = {
                                        "Ano ang balita",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.group.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "What's up",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.whats_up.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "What's up",
                        },
                        ["TL"] = {
                            "Ano ang balita",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "What's up",
                                    },
                                    ["TL"] = {
                                        "Ano ang balita",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group.whats_up.label",
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
                            ["fallback"] = "What's up",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.group.whats_up.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "What's up",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.whats_up.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "What's up",
                    },
                    ["TL"] = {
                        "Ano ang balita",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.identity.lie.label",
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
                                ["fallback"] = "Lie about your name",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.lie.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Lie about your name",
                                    },
                                    ["TL"] = {
                                        "Magsinungaling tungkol sa pangalan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.identity.lie",
            ["textRoles"] = {
                {
                    ["fallback"] = "Lie about your name",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.lie.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Lie about your name",
                        },
                        ["TL"] = {
                            "Magsinungaling tungkol sa pangalan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Lie about your name",
                                    },
                                    ["TL"] = {
                                        "Magsinungaling tungkol sa pangalan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.lie.label",
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
                            ["fallback"] = "Lie about your name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.lie.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Lie about your name",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.lie.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Lie about your name",
                    },
                    ["TL"] = {
                        "Magsinungaling tungkol sa pangalan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.identity.lie.utterance",
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
                                ["fallback"] = "I'll go by a different name.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.lie.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll go by a different name.",
                                    },
                                    ["TL"] = {
                                        "Ibang pangalan ang gagamitin ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.identity.lie",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll go by a different name.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.lie.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll go by a different name.",
                        },
                        ["TL"] = {
                            "Ibang pangalan ang gagamitin ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "I'll go by a different name.",
                                    },
                                    ["TL"] = {
                                        "Ibang pangalan ang gagamitin ko.",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.lie.utterance",
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
                            ["fallback"] = "I'll go by a different name.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.lie.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "I'll go by a different name.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.lie.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll go by a different name.",
                    },
                    ["TL"] = {
                        "Ibang pangalan ang gagamitin ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.identity.real.label",
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
                                ["fallback"] = "Say your real name",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.real.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Say your real name",
                                    },
                                    ["TL"] = {
                                        "Sabihin ang tunay mong pangalan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.identity.real",
            ["textRoles"] = {
                {
                    ["fallback"] = "Say your real name",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.real.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Say your real name",
                        },
                        ["TL"] = {
                            "Sabihin ang tunay mong pangalan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
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
                                        "Say your real name",
                                    },
                                    ["TL"] = {
                                        "Sabihin ang tunay mong pangalan",
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
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.real.label",
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
                            ["fallback"] = "Say your real name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.real.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Say your real name",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.real.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Say your real name",
                    },
                    ["TL"] = {
                        "Sabihin ang tunay mong pangalan",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
