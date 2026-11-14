-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.identity.real.utterance",
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
                                ["fallback"] = "My real name.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.real.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "My real name.",
                                    },
                                    ["TL"] = {
                                        "Tunay kong pangalan.",
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
                    ["fallback"] = "My real name.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.real.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "My real name.",
                        },
                        ["TL"] = {
                            "Tunay kong pangalan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.real.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.identity.real.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_real_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "My real name.",
                                    },
                                    ["TL"] = {
                                        "Tunay kong pangalan.",
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
            ["responsePlanID"] = "ui.suggestion.identity.real.utterance",
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
                            ["fallback"] = "My real name.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.real.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "My real name.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.real.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "My real name.",
                    },
                    ["TL"] = {
                        "Tunay kong pangalan.",
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
            ["familyID"] = "ui.suggestion.identity.rude.label",
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
                                ["fallback"] = "Don't tell your name",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.rude.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Don't tell your name",
                                    },
                                    ["TL"] = {
                                        "Huwag sabihin ang pangalan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.identity.rude",
            ["textRoles"] = {
                {
                    ["fallback"] = "Don't tell your name",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.rude.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Don't tell your name",
                        },
                        ["TL"] = {
                            "Huwag sabihin ang pangalan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.rude.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.identity.rude.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Don't tell your name",
                                    },
                                    ["TL"] = {
                                        "Huwag sabihin ang pangalan",
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
            ["responsePlanID"] = "ui.suggestion.identity.rude.label",
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
                            ["fallback"] = "Don't tell your name",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.rude.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Don't tell your name",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.rude.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Don't tell your name",
                    },
                    ["TL"] = {
                        "Huwag sabihin ang pangalan",
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
            ["familyID"] = "ui.suggestion.identity.rude.utterance",
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
                                ["fallback"] = "That's none of your business.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.rude.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's none of your business.",
                                    },
                                    ["TL"] = {
                                        "Wala ka nang pakialam.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.identity.rude",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's none of your business.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.rude.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's none of your business.",
                        },
                        ["TL"] = {
                            "Wala ka nang pakialam.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.rude.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.identity.rude.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_identity_rude_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "That's none of your business.",
                                    },
                                    ["TL"] = {
                                        "Wala ka nang pakialam.",
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
            ["responsePlanID"] = "ui.suggestion.identity.rude.utterance",
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
                            ["fallback"] = "That's none of your business.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.identity.rude.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "That's none of your business.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.rude.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's none of your business.",
                    },
                    ["TL"] = {
                        "Wala ka nang pakialam.",
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
            ["familyID"] = "ui.suggestion.needs_destination.tooltip",
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
                                ["fallback"] = "Choose a destination first.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.needs_destination.tooltip.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Choose a destination first.",
                                    },
                                    ["TL"] = {
                                        "Pumili muna ng pupuntahan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.needs_destination",
            ["textRoles"] = {
                {
                    ["fallback"] = "Choose a destination first.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.needs_destination.tooltip.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Choose a destination first.",
                        },
                        ["TL"] = {
                            "Pumili muna ng pupuntahan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.needs_destination.tooltip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.needs_destination.tooltip",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_needs_destination_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Choose a destination first.",
                                    },
                                    ["TL"] = {
                                        "Pumili muna ng pupuntahan.",
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
            ["responsePlanID"] = "ui.suggestion.needs_destination.tooltip",
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
                            ["fallback"] = "Choose a destination first.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.needs_destination.tooltip.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Choose a destination first.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.needs_destination.tooltip.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Choose a destination first.",
                    },
                    ["TL"] = {
                        "Pumili muna ng pupuntahan.",
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
            ["familyID"] = "ui.suggestion.personal_check_in.label",
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
                                ["fallback"] = "Ask what's on their mind",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.personal_check_in.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Ask what's on their mind",
                                    },
                                    ["TL"] = {
                                        "Alamin kung may bumabagabag sa kanya",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.personal_check_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask what's on their mind",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.personal_check_in.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask what's on their mind",
                        },
                        ["TL"] = {
                            "Alamin kung may bumabagabag sa kanya",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.personal_check_in.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.personal_check_in.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Ask what's on their mind",
                                    },
                                    ["TL"] = {
                                        "Alamin kung may bumabagabag sa kanya",
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
            ["responsePlanID"] = "ui.suggestion.personal_check_in.label",
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
                            ["fallback"] = "Ask what's on their mind",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.personal_check_in.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Ask what's on their mind",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.personal_check_in.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what's on their mind",
                    },
                    ["TL"] = {
                        "Alamin kung may bumabagabag sa kanya",
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
            ["familyID"] = "ui.suggestion.personal_check_in.utterance",
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
                                ["fallback"] = "Anything bothering you?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.personal_check_in.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Anything bothering you?",
                                    },
                                    ["TL"] = {
                                        "May bumabagabag ba sa'yo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.personal_check_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "Anything bothering you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.personal_check_in.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Anything bothering you?",
                        },
                        ["TL"] = {
                            "May bumabagabag ba sa'yo?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.personal_check_in.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.personal_check_in.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_personal_check_in_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Anything bothering you?",
                                    },
                                    ["TL"] = {
                                        "May bumabagabag ba sa'yo?",
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
            ["responsePlanID"] = "ui.suggestion.personal_check_in.utterance",
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
                            ["fallback"] = "Anything bothering you?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.personal_check_in.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Anything bothering you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.personal_check_in.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Anything bothering you?",
                    },
                    ["TL"] = {
                        "May bumabagabag ba sa'yo?",
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
            ["familyID"] = "ui.suggestion.stay.label",
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
                                ["fallback"] = "Wait here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.stay.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Wait here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka maghintay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.stay",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.stay.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait here.",
                        },
                        ["TL"] = {
                            "Dito ka maghintay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.stay.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.stay.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Wait here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka maghintay.",
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
            ["responsePlanID"] = "ui.suggestion.stay.label",
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
                            ["fallback"] = "Wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.stay.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.stay.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
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
            ["familyID"] = "ui.suggestion.stay.utterance",
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
                                ["fallback"] = "Wait here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.stay.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Wait here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka maghintay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.stay",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.stay.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait here.",
                        },
                        ["TL"] = {
                            "Dito ka maghintay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.stay.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.stay.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_stay_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Wait here.",
                                    },
                                    ["TL"] = {
                                        "Dito ka maghintay.",
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
            ["responsePlanID"] = "ui.suggestion.stay.utterance",
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
                            ["fallback"] = "Wait here.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.stay.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.stay.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
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
            ["familyID"] = "ui.suggestion.talk_again_about.label",
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
                                ["fallback"] = "Talk again about",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.talk_again_about.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Talk again about",
                                    },
                                    ["TL"] = {
                                        "Pag-usapan muli ang",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.talk_again_about",
            ["textRoles"] = {
                {
                    ["fallback"] = "Talk again about",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.talk_again_about.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Talk again about",
                        },
                        ["TL"] = {
                            "Pag-usapan muli ang",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.talk_again_about.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_again_about.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Talk again about",
                                    },
                                    ["TL"] = {
                                        "Pag-usapan muli ang",
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
            ["responsePlanID"] = "ui.suggestion.talk_again_about.label",
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
                            ["fallback"] = "Talk again about",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.talk_again_about.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Talk again about",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.talk_again_about.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Talk again about",
                    },
                    ["TL"] = {
                        "Pag-usapan muli ang",
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
            ["familyID"] = "ui.suggestion.talk_something_else.label",
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
                                ["fallback"] = "Let's talk something else",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.talk_something_else.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's talk something else",
                                    },
                                    ["TL"] = {
                                        "Iba naman ang pag-usapan natin",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.talk_something_else",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's talk something else",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.talk_something_else.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's talk something else",
                        },
                        ["TL"] = {
                            "Iba naman ang pag-usapan natin",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.talk_something_else.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_something_else.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Let's talk something else",
                                    },
                                    ["TL"] = {
                                        "Iba naman ang pag-usapan natin",
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
            ["responsePlanID"] = "ui.suggestion.talk_something_else.label",
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
                            ["fallback"] = "Let's talk something else",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.talk_something_else.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's talk something else",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.talk_something_else.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's talk something else",
                    },
                    ["TL"] = {
                        "Iba naman ang pag-usapan natin",
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
            ["familyID"] = "ui.suggestion.trade.label",
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
                                ["fallback"] = "Open trading",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.trade.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Open trading",
                                    },
                                    ["TL"] = {
                                        "Buksan ang kalakalan",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.trade",
            ["textRoles"] = {
                {
                    ["fallback"] = "Open trading",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.trade.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Open trading",
                        },
                        ["TL"] = {
                            "Buksan ang kalakalan",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.trade.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.trade.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Open trading",
                                    },
                                    ["TL"] = {
                                        "Buksan ang kalakalan",
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
            ["responsePlanID"] = "ui.suggestion.trade.label",
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
                            ["fallback"] = "Open trading",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.trade.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Open trading",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.trade.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Open trading",
                    },
                    ["TL"] = {
                        "Buksan ang kalakalan",
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
            ["familyID"] = "ui.suggestion.trade.utterance",
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
                                ["fallback"] = "Let's trade.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.trade.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's trade.",
                                    },
                                    ["TL"] = {
                                        "Magpalitan tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.trade",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's trade.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.trade.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's trade.",
                        },
                        ["TL"] = {
                            "Magpalitan tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.trade.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.trade.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Let's trade.",
                                    },
                                    ["TL"] = {
                                        "Magpalitan tayo.",
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
            ["responsePlanID"] = "ui.suggestion.trade.utterance",
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
                            ["fallback"] = "Let's trade.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.trade.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Let's trade.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.trade.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's trade.",
                    },
                    ["TL"] = {
                        "Magpalitan tayo.",
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
            ["familyID"] = "ui.suggestion.unavailable.tooltip",
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
                                ["fallback"] = "Unavailable in the current situation.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.unavailable.tooltip.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Unavailable in the current situation.",
                                    },
                                    ["TL"] = {
                                        "Hindi magagamit sa kasalukuyang sitwasyon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.unavailable",
            ["textRoles"] = {
                {
                    ["fallback"] = "Unavailable in the current situation.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.unavailable.tooltip.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Unavailable in the current situation.",
                        },
                        ["TL"] = {
                            "Hindi magagamit sa kasalukuyang sitwasyon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.unavailable.tooltip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.unavailable.tooltip",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Unavailable in the current situation.",
                                    },
                                    ["TL"] = {
                                        "Hindi magagamit sa kasalukuyang sitwasyon.",
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
            ["responsePlanID"] = "ui.suggestion.unavailable.tooltip",
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
                            ["fallback"] = "Unavailable in the current situation.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.unavailable.tooltip.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Unavailable in the current situation.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.unavailable.tooltip.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Unavailable in the current situation.",
                    },
                    ["TL"] = {
                        "Hindi magagamit sa kasalukuyang sitwasyon.",
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
            ["familyID"] = "ui.suggestion.wait_at.label",
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
                                ["fallback"] = "Ask them to wait there",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.wait_at.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Ask them to wait there",
                                    },
                                    ["TL"] = {
                                        "Sabihing maghintay siya roon",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.wait_at",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask them to wait there",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.wait_at.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask them to wait there",
                        },
                        ["TL"] = {
                            "Sabihing maghintay siya roon",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.wait_at.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.wait_at.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Ask them to wait there",
                                    },
                                    ["TL"] = {
                                        "Sabihing maghintay siya roon",
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
            ["responsePlanID"] = "ui.suggestion.wait_at.label",
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
                            ["fallback"] = "Ask them to wait there",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.wait_at.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Ask them to wait there",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.wait_at.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Ask them to wait there",
                    },
                    ["TL"] = {
                        "Sabihing maghintay siya roon",
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
            ["familyID"] = "ui.suggestion.wait_at.utterance",
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
                                ["fallback"] = "Wait there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.wait_at.utterance.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Wait there.",
                                    },
                                    ["TL"] = {
                                        "Maghintay ka roon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.wait_at",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wait there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.wait_at.utterance.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait there.",
                        },
                        ["TL"] = {
                            "Maghintay ka roon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.wait_at.utterance",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "utterance",
            ["sourceId"] = "ui.suggestion.wait_at.utterance",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at_utterance.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "Wait there.",
                                    },
                                    ["TL"] = {
                                        "Maghintay ka roon.",
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
            ["responsePlanID"] = "ui.suggestion.wait_at.utterance",
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
                            ["fallback"] = "Wait there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.wait_at.utterance.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "Wait there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.wait_at.utterance.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Wait there.",
                    },
                    ["TL"] = {
                        "Maghintay ka roon.",
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
            ["familyID"] = "ui.suggestion.whats_up.label",
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
                                ["fallback"] = "What's up?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.whats_up.label.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What's up?",
                                    },
                                    ["TL"] = {
                                        "Ano ang balita?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.whats_up",
            ["textRoles"] = {
                {
                    ["fallback"] = "What's up?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.whats_up.label.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "What's up?",
                        },
                        ["TL"] = {
                            "Ano ang balita?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.whats_up.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.whats_up.label",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__285ca74c",
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
                                        "What's up?",
                                    },
                                    ["TL"] = {
                                        "Ano ang balita?",
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
            ["responsePlanID"] = "ui.suggestion.whats_up.label",
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
                            ["fallback"] = "What's up?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.ui.suggestion.whats_up.label.say_1",
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
        ["textRoles"] = {
            {
                ["fallback"] = "What's up?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.whats_up.label.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "What's up?",
                    },
                    ["TL"] = {
                        "Ano ang balita?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
