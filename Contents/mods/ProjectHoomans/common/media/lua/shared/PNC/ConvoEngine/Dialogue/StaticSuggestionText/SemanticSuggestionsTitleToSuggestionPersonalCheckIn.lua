-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "title",
            ["sourceId"] = "ui.semantic_suggestions.title",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_semantic_suggestions_title.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.semantic_suggestions.title.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_semantic_suggestions_title.json",
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
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.availability.tooltips",
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
                                ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.availability.tooltips.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Unavailable because this companion cannot receive orders right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi magagamit dahil hindi makatanggap ng utos ang kasama ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion.availability",
            ["textRoles"] = {
                {
                    ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.availability.tooltips.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Unavailable because this companion cannot receive orders right now.",
                        },
                        ["TL"] = {
                            "Hindi magagamit dahil hindi makatanggap ng utos ang kasama ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.availability.tooltips",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "tooltips",
            ["sourceId"] = "ui.suggestion.availability.tooltips",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_availability_tooltips.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion.availability",
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
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.already_following.tooltip",
                        ["text"] = {
                            ["EN"] = "Already following you.",
                            ["TL"] = "Sinusundan ka na.",
                        },
                    },
                    {
                        ["key"] = "suggestion.already_staying.tooltip",
                        ["text"] = {
                            ["EN"] = "Already holding position.",
                            ["TL"] = "Nananatili na sa puwesto.",
                        },
                    },
                    {
                        ["key"] = "suggestion.camp_site_out_of_range.tooltip",
                        ["text"] = {
                            ["EN"] = "This camp location is too far away right now.",
                            ["TL"] = "Masyadong malayo ang lugar ng kampo sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "suggestion.camp_site_stale.tooltip",
                        ["text"] = {
                            ["EN"] = "This camp location is no longer available; choose a fresh location.",
                            ["TL"] = "Hindi na available ang lugar; pumili ng bagong lokasyon.",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_busy.tooltip",
                        ["text"] = {
                            ["EN"] = "Unavailable while the companion is busy or in combat.",
                            ["TL"] = "Hindi magagamit habang abala o nakikipaglaban ang kasama.",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_dead.tooltip",
                        ["text"] = {
                            ["EN"] = "Unavailable because the companion is dead.",
                            ["TL"] = "Hindi magagamit dahil patay na ang kasama.",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_incapacitated.tooltip",
                        ["text"] = {
                            ["EN"] = "Unavailable because the companion is incapacitated.",
                            ["TL"] = "Hindi magagamit dahil walang malay o hindi makagalaw ang kasama.",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_unavailable.tooltip",
                        ["text"] = {
                            ["EN"] = "Unavailable because this companion cannot receive orders right now.",
                            ["TL"] = "Hindi magagamit dahil hindi makatanggap ng utos ang kasama ngayon.",
                        },
                    },
                    {
                        ["key"] = "suggestion.go_home.no_base.tooltip",
                        ["text"] = {
                            ["EN"] = "Go Home is unavailable because no base has been established.",
                            ["TL"] = "Hindi magagamit ang pag-uwi dahil wala pang naitayong base.",
                        },
                    },
                    {
                        ["key"] = "suggestion.no_camp_site.tooltip",
                        ["text"] = {
                            ["EN"] = "No valid camp location is currently available.",
                            ["TL"] = "Walang valid na lugar para magkampo sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "suggestion.not_following.tooltip",
                        ["text"] = {
                            ["EN"] = "Stay is available while the companion is following you.",
                            ["TL"] = "Magagamit ang paghihintay habang sinusundan ka ng kasama.",
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
                                        "Unavailable because this companion cannot receive orders right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi magagamit dahil hindi makatanggap ng utos ang kasama ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.availability.tooltips",
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
                            ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.availability.tooltips.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_availability_tooltips.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.availability.tooltips.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Unavailable because this companion cannot receive orders right now.",
                    },
                    ["TL"] = {
                        "Hindi magagamit dahil hindi makatanggap ng utos ang kasama ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.back.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_back_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Back",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.back.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_back_label.json",
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
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Check in with them",
                ["labelKey"] = "convo.ui.suggestion.check_in.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Check in with them",
                    },
                    ["TL"] = {
                        "Kumusta tayo",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.check_in",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.check_in.say.1.default",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Check in with them",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.check_in.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Check in with them",
                        },
                        ["TL"] = {
                            "Kumusta tayo",
                        },
                    },
                },
                {
                    ["fallback"] = "How are we doing?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.check_in.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "How are we doing?",
                        },
                        ["TL"] = {
                            "Kumusta tayo?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.check_in",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "check_in",
            ["sourceId"] = "ui.suggestion.check_in",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_check_in.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Check in with them",
                    },
                    ["TL"] = {
                        "Kumusta tayo",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.check_in.label",
                        ["text"] = {
                            ["EN"] = "Check in with them",
                            ["TL"] = "Kumusta tayo",
                        },
                    },
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
                                ["id"] = "default",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.check_in",
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
                            ["templateID"] = "convo.ui.suggestion.check_in.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Check in with them",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.check_in.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Check in with them",
                    },
                    ["TL"] = {
                        "Kumusta tayo",
                    },
                },
            },
            {
                ["fallback"] = "How are we doing?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.check_in.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "How are we doing?",
                    },
                    ["TL"] = {
                        "Kumusta tayo?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Let's camp...",
                ["labelKey"] = "convo.ui.suggestion.companion_camp.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp...",
                    },
                    ["TL"] = {
                        "Magkampo tayo...",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.companion_camp",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Let's camp here.",
                                ["id"] = "variant_1",
                                ["templateID"] = "convo.ui.suggestion.companion_camp.say.1.variant_1",
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
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Let's camp in the %1.",
                                ["id"] = "variant_1",
                                ["templateID"] = "convo.ui.suggestion.companion_camp.say.2.variant_1",
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
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Let's camp by the campfire.",
                                ["id"] = "variant_1",
                                ["templateID"] = "convo.ui.suggestion.companion_camp.say.3.variant_1",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Let's camp...",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp...",
                        },
                        ["TL"] = {
                            "Magkampo tayo...",
                        },
                    },
                },
                {
                    ["fallback"] = "Let's camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.1.variant_1",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp here.",
                        },
                        ["TL"] = {
                            "Magkampo tayo rito.",
                        },
                    },
                    ["variantID"] = "variant_1",
                },
                {
                    ["fallback"] = "Let's camp in the %1.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.2.variant_1",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp in the %1.",
                        },
                        ["TL"] = {
                            "Magkampo tayo sa %1.",
                        },
                    },
                    ["variantID"] = "variant_1",
                },
                {
                    ["fallback"] = "Let's camp by the campfire.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.3.variant_1",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's camp by the campfire.",
                        },
                        ["TL"] = {
                            "Magkampo tayo sa tabi ng apoy.",
                        },
                    },
                    ["variantID"] = "variant_1",
                },
            },
        },
        ["id"] = "ui.suggestion.companion_camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "companion_camp",
            ["sourceId"] = "ui.suggestion.companion_camp",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_companion_camp.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Let's camp...",
                    },
                    ["TL"] = {
                        "Magkampo tayo...",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.companion_camp.label",
                        ["text"] = {
                            ["EN"] = "Let's camp...",
                            ["TL"] = "Magkampo tayo...",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_camp_here.utterance",
                        ["text"] = {
                            ["EN"] = "Let's camp here.",
                            ["TL"] = "Magkampo tayo rito.",
                        },
                    },
                    {
                        ["key"] = "suggestion.companion_camp_room.utterance",
                        ["text"] = {
                            ["EN"] = "Let's camp in the %1.",
                            ["TL"] = "Magkampo tayo sa %1.",
                        },
                    },
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
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "variant_1",
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
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "variant_1",
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
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "variant_1",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.companion_camp",
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
                            ["templateID"] = "convo.ui.suggestion.companion_camp.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_companion_camp.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Let's camp...",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.companion_camp.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp...",
                    },
                    ["TL"] = {
                        "Magkampo tayo...",
                    },
                },
            },
            {
                ["fallback"] = "Let's camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.1.variant_1",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp here.",
                    },
                    ["TL"] = {
                        "Magkampo tayo rito.",
                    },
                },
                ["variantID"] = "variant_1",
            },
            {
                ["fallback"] = "Let's camp in the %1.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.2.variant_1",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp in the %1.",
                    },
                    ["TL"] = {
                        "Magkampo tayo sa %1.",
                    },
                },
                ["variantID"] = "variant_1",
            },
            {
                ["fallback"] = "Let's camp by the campfire.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.3.variant_1",
                ["translations"] = {
                    ["EN"] = {
                        "Let's camp by the campfire.",
                    },
                    ["TL"] = {
                        "Magkampo tayo sa tabi ng apoy.",
                    },
                },
                ["variantID"] = "variant_1",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.companion_orders.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_companion_orders_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I need you to do something...",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.companion_orders.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_companion_orders_label.json",
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
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Follow me.",
                ["labelKey"] = "convo.ui.suggestion.follow.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.follow",
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
                                ["templateID"] = "convo.ui.suggestion.follow.say.1.default",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Follow me.",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.follow.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Follow me.",
                        },
                        ["TL"] = {
                            "Sumunod ka sa akin.",
                        },
                    },
                },
                {
                    ["fallback"] = "Follow me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.follow.say.1.default",
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
        ["id"] = "ui.suggestion.follow",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "follow",
            ["sourceId"] = "ui.suggestion.follow",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_follow.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.follow.label",
                        ["text"] = {
                            ["EN"] = "Follow me.",
                            ["TL"] = "Sumunod ka sa akin.",
                        },
                    },
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.follow",
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
                            ["templateID"] = "convo.ui.suggestion.follow.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_follow.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Follow me.",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.follow.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Follow me.",
                    },
                    ["TL"] = {
                        "Sumunod ka sa akin.",
                    },
                },
            },
            {
                ["fallback"] = "Follow me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.follow.say.1.default",
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
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Say you're doing fine",
                ["labelKey"] = "convo.ui.suggestion.greeting_report_fine.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Say you're doing fine",
                    },
                    ["TL"] = {
                        "Sabihing ayos ka lang",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.greeting_report_fine",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say.1.default",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Say you're doing fine",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.greeting_report_fine.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Say you're doing fine",
                        },
                        ["TL"] = {
                            "Sabihing ayos ka lang",
                        },
                    },
                },
                {
                    ["fallback"] = "I'm fine, thank you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm fine, thank you.",
                        },
                        ["TL"] = {
                            "Ayos lang ako, salamat.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.greeting_report_fine",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "greeting_report_fine",
            ["sourceId"] = "ui.suggestion.greeting_report_fine",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Say you're doing fine",
                    },
                    ["TL"] = {
                        "Sabihing ayos ka lang",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_report_fine.label",
                        ["text"] = {
                            ["EN"] = "Say you're doing fine",
                            ["TL"] = "Sabihing ayos ka lang",
                        },
                    },
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
                                ["id"] = "default",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_report_fine",
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
                            ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_greeting_report_fine.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Say you're doing fine",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Say you're doing fine",
                    },
                    ["TL"] = {
                        "Sabihing ayos ka lang",
                    },
                },
            },
            {
                ["fallback"] = "I'm fine, thank you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "I'm fine, thank you.",
                    },
                    ["TL"] = {
                        "Ayos lang ako, salamat.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Thank them",
                ["labelKey"] = "convo.ui.suggestion.greeting_thank.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Thank them",
                    },
                    ["TL"] = {
                        "Pasalamatan siya",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.greeting_thank",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.greeting_thank.say.1.default",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thank them",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.greeting_thank.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Thank them",
                        },
                        ["TL"] = {
                            "Pasalamatan siya",
                        },
                    },
                },
                {
                    ["fallback"] = "Thanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_thank.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Thanks.",
                        },
                        ["TL"] = {
                            "Salamat.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.greeting_thank",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "greeting_thank",
            ["sourceId"] = "ui.suggestion.greeting_thank",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_greeting_thank.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Thank them",
                    },
                    ["TL"] = {
                        "Pasalamatan siya",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.greeting_thank.label",
                        ["text"] = {
                            ["EN"] = "Thank them",
                            ["TL"] = "Pasalamatan siya",
                        },
                    },
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
                                ["id"] = "default",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.greeting_thank",
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
                            ["templateID"] = "convo.ui.suggestion.greeting_thank.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_greeting_thank.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thank them",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.greeting_thank.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Thank them",
                    },
                    ["TL"] = {
                        "Pasalamatan siya",
                    },
                },
            },
            {
                ["fallback"] = "Thanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_thank.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Thanks.",
                    },
                    ["TL"] = {
                        "Salamat.",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["familyID"] = "ui.suggestion.group",
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
                                ["id"] = "actions.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.actions.label",
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
                            {
                                ["fallback"] = "Current conversation branch",
                                ["id"] = "flow.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
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
                            {
                                ["fallback"] = "Identity",
                                ["id"] = "identity.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
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
                            {
                                ["fallback"] = "Talk",
                                ["id"] = "landing.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
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
                            {
                                ["fallback"] = "Medical",
                                ["id"] = "medical.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
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
                            {
                                ["fallback"] = "Owned companion actions",
                                ["id"] = "movement.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
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
                            {
                                ["fallback"] = "Needs",
                                ["id"] = "needs.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
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
                            {
                                ["fallback"] = "NPC reply",
                                ["id"] = "response.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
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
                            {
                                ["fallback"] = "Time and date",
                                ["id"] = "time.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
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
                            {
                                ["fallback"] = "Conversation utilities",
                                ["id"] = "utilities.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
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
                            {
                                ["fallback"] = "Weather",
                                ["id"] = "weather.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
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
                            {
                                ["fallback"] = "Wellbeing",
                                ["id"] = "wellbeing.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
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
                            {
                                ["fallback"] = "What's up",
                                ["id"] = "whats_up.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Conversation actions",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.actions.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Conversation actions",
                        },
                        ["TL"] = {
                            "Mga aksyon sa usapan",
                        },
                    },
                    ["variantID"] = "actions.label",
                },
                {
                    ["fallback"] = "Current conversation branch",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Current conversation branch",
                        },
                        ["TL"] = {
                            "Kasalukuyang sangay ng usapan",
                        },
                    },
                    ["variantID"] = "flow.label",
                },
                {
                    ["fallback"] = "Identity",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Identity",
                        },
                        ["TL"] = {
                            "Pagkakakilanlan",
                        },
                    },
                    ["variantID"] = "identity.label",
                },
                {
                    ["fallback"] = "Talk",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Talk",
                        },
                        ["TL"] = {
                            "Usapan",
                        },
                    },
                    ["variantID"] = "landing.label",
                },
                {
                    ["fallback"] = "Medical",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Medical",
                        },
                        ["TL"] = {
                            "Medikal",
                        },
                    },
                    ["variantID"] = "medical.label",
                },
                {
                    ["fallback"] = "Owned companion actions",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Owned companion actions",
                        },
                        ["TL"] = {
                            "Mga utos sa kasamang pag-aari",
                        },
                    },
                    ["variantID"] = "movement.label",
                },
                {
                    ["fallback"] = "Needs",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Needs",
                        },
                        ["TL"] = {
                            "Pangangailangan",
                        },
                    },
                    ["variantID"] = "needs.label",
                },
                {
                    ["fallback"] = "NPC reply",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
                    ["translations"] = {
                        ["EN"] = {
                            "NPC reply",
                        },
                        ["TL"] = {
                            "Sagot ng NPC",
                        },
                    },
                    ["variantID"] = "response.label",
                },
                {
                    ["fallback"] = "Time and date",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Time and date",
                        },
                        ["TL"] = {
                            "Oras at petsa",
                        },
                    },
                    ["variantID"] = "time.label",
                },
                {
                    ["fallback"] = "Conversation utilities",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Conversation utilities",
                        },
                        ["TL"] = {
                            "Mga gamit sa usapan",
                        },
                    },
                    ["variantID"] = "utilities.label",
                },
                {
                    ["fallback"] = "Weather",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Weather",
                        },
                        ["TL"] = {
                            "Panahon",
                        },
                    },
                    ["variantID"] = "weather.label",
                },
                {
                    ["fallback"] = "Wellbeing",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Wellbeing",
                        },
                        ["TL"] = {
                            "Kalagayan",
                        },
                    },
                    ["variantID"] = "wellbeing.label",
                },
                {
                    ["fallback"] = "What's up",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
                    ["translations"] = {
                        ["EN"] = {
                            "What's up",
                        },
                        ["TL"] = {
                            "Ano ang balita",
                        },
                    },
                    ["variantID"] = "whats_up.label",
                },
            },
        },
        ["id"] = "ui.suggestion.group",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "group",
            ["sourceId"] = "ui.suggestion.group",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.group.actions.label",
                        ["text"] = {
                            ["EN"] = "Conversation actions",
                            ["TL"] = "Mga aksyon sa usapan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.flow.label",
                        ["text"] = {
                            ["EN"] = "Current conversation branch",
                            ["TL"] = "Kasalukuyang sangay ng usapan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.identity.label",
                        ["text"] = {
                            ["EN"] = "Identity",
                            ["TL"] = "Pagkakakilanlan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.landing.label",
                        ["text"] = {
                            ["EN"] = "Talk",
                            ["TL"] = "Usapan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.medical.label",
                        ["text"] = {
                            ["EN"] = "Medical",
                            ["TL"] = "Medikal",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.movement.label",
                        ["text"] = {
                            ["EN"] = "Owned companion actions",
                            ["TL"] = "Mga utos sa kasamang pag-aari",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.needs.label",
                        ["text"] = {
                            ["EN"] = "Needs",
                            ["TL"] = "Pangangailangan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.response.label",
                        ["text"] = {
                            ["EN"] = "NPC reply",
                            ["TL"] = "Sagot ng NPC",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.time.label",
                        ["text"] = {
                            ["EN"] = "Time and date",
                            ["TL"] = "Oras at petsa",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.utilities.label",
                        ["text"] = {
                            ["EN"] = "Conversation utilities",
                            ["TL"] = "Mga gamit sa usapan",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.weather.label",
                        ["text"] = {
                            ["EN"] = "Weather",
                            ["TL"] = "Panahon",
                        },
                    },
                    {
                        ["key"] = "suggestion.group.wellbeing.label",
                        ["text"] = {
                            ["EN"] = "Wellbeing",
                            ["TL"] = "Kalagayan",
                        },
                    },
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
                                ["id"] = "actions.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Conversation actions",
                                    },
                                    ["TL"] = {
                                        "Mga aksyon sa usapan",
                                    },
                                },
                            },
                            {
                                ["id"] = "flow.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Current conversation branch",
                                    },
                                    ["TL"] = {
                                        "Kasalukuyang sangay ng usapan",
                                    },
                                },
                            },
                            {
                                ["id"] = "identity.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Identity",
                                    },
                                    ["TL"] = {
                                        "Pagkakakilanlan",
                                    },
                                },
                            },
                            {
                                ["id"] = "landing.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Talk",
                                    },
                                    ["TL"] = {
                                        "Usapan",
                                    },
                                },
                            },
                            {
                                ["id"] = "medical.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Medical",
                                    },
                                    ["TL"] = {
                                        "Medikal",
                                    },
                                },
                            },
                            {
                                ["id"] = "movement.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Owned companion actions",
                                    },
                                    ["TL"] = {
                                        "Mga utos sa kasamang pag-aari",
                                    },
                                },
                            },
                            {
                                ["id"] = "needs.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Needs",
                                    },
                                    ["TL"] = {
                                        "Pangangailangan",
                                    },
                                },
                            },
                            {
                                ["id"] = "response.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "NPC reply",
                                    },
                                    ["TL"] = {
                                        "Sagot ng NPC",
                                    },
                                },
                            },
                            {
                                ["id"] = "time.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Time and date",
                                    },
                                    ["TL"] = {
                                        "Oras at petsa",
                                    },
                                },
                            },
                            {
                                ["id"] = "utilities.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Conversation utilities",
                                    },
                                    ["TL"] = {
                                        "Mga gamit sa usapan",
                                    },
                                },
                            },
                            {
                                ["id"] = "weather.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Weather",
                                    },
                                    ["TL"] = {
                                        "Panahon",
                                    },
                                },
                            },
                            {
                                ["id"] = "wellbeing.label",
                                ["text"] = {
                                    ["EN"] = {
                                        "Wellbeing",
                                    },
                                    ["TL"] = {
                                        "Kalagayan",
                                    },
                                },
                            },
                            {
                                ["id"] = "whats_up.label",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.group",
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
                            ["templateID"] = "convo.ui.suggestion.group.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group.json",
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
                ["templateID"] = "convo.ui.suggestion.group.say.1.actions.label",
                ["translations"] = {
                    ["EN"] = {
                        "Conversation actions",
                    },
                    ["TL"] = {
                        "Mga aksyon sa usapan",
                    },
                },
                ["variantID"] = "actions.label",
            },
            {
                ["fallback"] = "Current conversation branch",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
                ["translations"] = {
                    ["EN"] = {
                        "Current conversation branch",
                    },
                    ["TL"] = {
                        "Kasalukuyang sangay ng usapan",
                    },
                },
                ["variantID"] = "flow.label",
            },
            {
                ["fallback"] = "Identity",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
                ["translations"] = {
                    ["EN"] = {
                        "Identity",
                    },
                    ["TL"] = {
                        "Pagkakakilanlan",
                    },
                },
                ["variantID"] = "identity.label",
            },
            {
                ["fallback"] = "Talk",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
                ["translations"] = {
                    ["EN"] = {
                        "Talk",
                    },
                    ["TL"] = {
                        "Usapan",
                    },
                },
                ["variantID"] = "landing.label",
            },
            {
                ["fallback"] = "Medical",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
                ["translations"] = {
                    ["EN"] = {
                        "Medical",
                    },
                    ["TL"] = {
                        "Medikal",
                    },
                },
                ["variantID"] = "medical.label",
            },
            {
                ["fallback"] = "Owned companion actions",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
                ["translations"] = {
                    ["EN"] = {
                        "Owned companion actions",
                    },
                    ["TL"] = {
                        "Mga utos sa kasamang pag-aari",
                    },
                },
                ["variantID"] = "movement.label",
            },
            {
                ["fallback"] = "Needs",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
                ["translations"] = {
                    ["EN"] = {
                        "Needs",
                    },
                    ["TL"] = {
                        "Pangangailangan",
                    },
                },
                ["variantID"] = "needs.label",
            },
            {
                ["fallback"] = "NPC reply",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
                ["translations"] = {
                    ["EN"] = {
                        "NPC reply",
                    },
                    ["TL"] = {
                        "Sagot ng NPC",
                    },
                },
                ["variantID"] = "response.label",
            },
            {
                ["fallback"] = "Time and date",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
                ["translations"] = {
                    ["EN"] = {
                        "Time and date",
                    },
                    ["TL"] = {
                        "Oras at petsa",
                    },
                },
                ["variantID"] = "time.label",
            },
            {
                ["fallback"] = "Conversation utilities",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
                ["translations"] = {
                    ["EN"] = {
                        "Conversation utilities",
                    },
                    ["TL"] = {
                        "Mga gamit sa usapan",
                    },
                },
                ["variantID"] = "utilities.label",
            },
            {
                ["fallback"] = "Weather",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
                ["translations"] = {
                    ["EN"] = {
                        "Weather",
                    },
                    ["TL"] = {
                        "Panahon",
                    },
                },
                ["variantID"] = "weather.label",
            },
            {
                ["fallback"] = "Wellbeing",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
                ["translations"] = {
                    ["EN"] = {
                        "Wellbeing",
                    },
                    ["TL"] = {
                        "Kalagayan",
                    },
                },
                ["variantID"] = "wellbeing.label",
            },
            {
                ["fallback"] = "What's up",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
                ["translations"] = {
                    ["EN"] = {
                        "What's up",
                    },
                    ["TL"] = {
                        "Ano ang balita",
                    },
                },
                ["variantID"] = "whats_up.label",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Lie about your name",
                ["labelKey"] = "convo.ui.suggestion.identity.lie.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Lie about your name",
                    },
                    ["TL"] = {
                        "Magsinungaling tungkol sa pangalan",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.identity.lie",
            ["initiatingSay"] = {
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
                                ["fallback"] = "I'm {slot.identity_claim.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.lie.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm {slot.identity_claim.name}.",
                                        "Name's {slot.identity_claim.name}.",
                                        "You can call me {slot.identity_claim.name}.",
                                        "My name's {slot.identity_claim.name}.",
                                        "It's {slot.identity_claim.name}.",
                                        "Call me {slot.identity_claim.name}.",
                                        "I go by {slot.identity_claim.name}.",
                                        "They call me {slot.identity_claim.name}.",
                                        "The name's {slot.identity_claim.name}.",
                                        "Just call me {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}. That's what I go by.",
                                        "I'll go by {slot.identity_claim.name}.",
                                    },
                                    ["TL"] = {
                                        "Ako si {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang pangalan ko.",
                                        "Tawagin mo akong {slot.identity_claim.name}.",
                                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                                        "Si {slot.identity_claim.name} ito.",
                                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang gamit kong pangalan.",
                                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                                        "Ako nga pala si {slot.identity_claim.name}.",
                                        "Sabihin na nating {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}. Iyan ang tawag sa akin.",
                                        "Magpapakilala akong si {slot.identity_claim.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "INFORM",
                ["speechAct"] = "DECEIVE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["namespace"] = "ui.suggestion.identity",
            ["slots"] = {
                ["identity_claim"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "fact",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Lie about your name",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.identity.lie.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Lie about your name",
                        },
                        ["TL"] = {
                            "Magsinungaling tungkol sa pangalan",
                        },
                    },
                },
                {
                    ["fallback"] = "I'm {slot.identity_claim.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.lie.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm {slot.identity_claim.name}.",
                            "Name's {slot.identity_claim.name}.",
                            "You can call me {slot.identity_claim.name}.",
                            "My name's {slot.identity_claim.name}.",
                            "It's {slot.identity_claim.name}.",
                            "Call me {slot.identity_claim.name}.",
                            "I go by {slot.identity_claim.name}.",
                            "They call me {slot.identity_claim.name}.",
                            "The name's {slot.identity_claim.name}.",
                            "Just call me {slot.identity_claim.name}.",
                            "{slot.identity_claim.name}. That's what I go by.",
                            "I'll go by {slot.identity_claim.name}.",
                        },
                        ["TL"] = {
                            "Ako si {slot.identity_claim.name}.",
                            "{slot.identity_claim.name} ang pangalan ko.",
                            "Tawagin mo akong {slot.identity_claim.name}.",
                            "Ang pangalan ko ay {slot.identity_claim.name}.",
                            "Si {slot.identity_claim.name} ito.",
                            "Tawagin mo na lang akong {slot.identity_claim.name}.",
                            "{slot.identity_claim.name} ang gamit kong pangalan.",
                            "{slot.identity_claim.name} ang tawag nila sa akin.",
                            "Ako nga pala si {slot.identity_claim.name}.",
                            "Sabihin na nating {slot.identity_claim.name}.",
                            "{slot.identity_claim.name}. Iyan ang tawag sa akin.",
                            "Magpapakilala akong si {slot.identity_claim.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.lie",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "lie",
            ["sourceId"] = "ui.suggestion.identity.lie",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_identity_lie.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion.identity",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Lie about your name",
                    },
                    ["TL"] = {
                        "Magsinungaling tungkol sa pangalan",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["invoke"] = {
                ["intent"] = "INFORM",
                ["speechAct"] = "DECEIVE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["metadata"] = {
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
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm {slot.identity_claim.name}.",
                                        "Name's {slot.identity_claim.name}.",
                                        "You can call me {slot.identity_claim.name}.",
                                        "My name's {slot.identity_claim.name}.",
                                        "It's {slot.identity_claim.name}.",
                                        "Call me {slot.identity_claim.name}.",
                                        "I go by {slot.identity_claim.name}.",
                                        "They call me {slot.identity_claim.name}.",
                                        "The name's {slot.identity_claim.name}.",
                                        "Just call me {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}. That's what I go by.",
                                        "I'll go by {slot.identity_claim.name}.",
                                    },
                                    ["TL"] = {
                                        "Ako si {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang pangalan ko.",
                                        "Tawagin mo akong {slot.identity_claim.name}.",
                                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                                        "Si {slot.identity_claim.name} ito.",
                                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang gamit kong pangalan.",
                                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                                        "Ako nga pala si {slot.identity_claim.name}.",
                                        "Sabihin na nating {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}. Iyan ang tawag sa akin.",
                                        "Magpapakilala akong si {slot.identity_claim.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.lie",
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
                            ["fallback"] = "I'm {slot.identity_claim.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.identity.lie.say_1",
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
            ["identity_claim"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "fact",
            },
        },
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_identity_lie.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Lie about your name",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.identity.lie.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Lie about your name",
                    },
                    ["TL"] = {
                        "Magsinungaling tungkol sa pangalan",
                    },
                },
            },
            {
                ["fallback"] = "I'm {slot.identity_claim.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.lie.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm {slot.identity_claim.name}.",
                        "Name's {slot.identity_claim.name}.",
                        "You can call me {slot.identity_claim.name}.",
                        "My name's {slot.identity_claim.name}.",
                        "It's {slot.identity_claim.name}.",
                        "Call me {slot.identity_claim.name}.",
                        "I go by {slot.identity_claim.name}.",
                        "They call me {slot.identity_claim.name}.",
                        "The name's {slot.identity_claim.name}.",
                        "Just call me {slot.identity_claim.name}.",
                        "{slot.identity_claim.name}. That's what I go by.",
                        "I'll go by {slot.identity_claim.name}.",
                    },
                    ["TL"] = {
                        "Ako si {slot.identity_claim.name}.",
                        "{slot.identity_claim.name} ang pangalan ko.",
                        "Tawagin mo akong {slot.identity_claim.name}.",
                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                        "Si {slot.identity_claim.name} ito.",
                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                        "{slot.identity_claim.name} ang gamit kong pangalan.",
                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                        "Ako nga pala si {slot.identity_claim.name}.",
                        "Sabihin na nating {slot.identity_claim.name}.",
                        "{slot.identity_claim.name}. Iyan ang tawag sa akin.",
                        "Magpapakilala akong si {slot.identity_claim.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Say your real name",
                ["labelKey"] = "convo.ui.suggestion.identity.real.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Say your real name",
                    },
                    ["TL"] = {
                        "Sabihin ang tunay mong pangalan",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.identity.real",
            ["initiatingSay"] = {
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
                                ["fallback"] = "I'm {slot.identity_claim.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.real.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}.",
                                        "My name's {slot.identity_claim.name}.",
                                        "My name is {slot.identity_claim.name}.",
                                        "It's {slot.identity_claim.name}.",
                                        "Name's {slot.identity_claim.name}.",
                                        "You can call me {slot.identity_claim.name}.",
                                        "They call me {slot.identity_claim.name}.",
                                        "I go by {slot.identity_claim.name}.",
                                        "The name's {slot.identity_claim.name}.",
                                        "Call me {slot.identity_claim.name}.",
                                        "Folks call me {slot.identity_claim.name}.",
                                    },
                                    ["TL"] = {
                                        "Ako si {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}.",
                                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                                        "Pangalan ko'y {slot.identity_claim.name}.",
                                        "Si {slot.identity_claim.name} ito.",
                                        "{slot.identity_claim.name} ang pangalan ko.",
                                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                                        "Kilala ako bilang {slot.identity_claim.name}.",
                                        "Ako nga pala si {slot.identity_claim.name}.",
                                        "Pwede mo akong tawaging {slot.identity_claim.name}.",
                                        "Lagi akong tinatawag na {slot.identity_claim.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "INFORM",
                ["speechAct"] = "DISCLOSE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["namespace"] = "ui.suggestion.identity",
            ["slots"] = {
                ["identity_claim"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "fact",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Say your real name",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.identity.real.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Say your real name",
                        },
                        ["TL"] = {
                            "Sabihin ang tunay mong pangalan",
                        },
                    },
                },
                {
                    ["fallback"] = "I'm {slot.identity_claim.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.real.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm {slot.identity_claim.name}.",
                            "{slot.identity_claim.name}.",
                            "My name's {slot.identity_claim.name}.",
                            "My name is {slot.identity_claim.name}.",
                            "It's {slot.identity_claim.name}.",
                            "Name's {slot.identity_claim.name}.",
                            "You can call me {slot.identity_claim.name}.",
                            "They call me {slot.identity_claim.name}.",
                            "I go by {slot.identity_claim.name}.",
                            "The name's {slot.identity_claim.name}.",
                            "Call me {slot.identity_claim.name}.",
                            "Folks call me {slot.identity_claim.name}.",
                        },
                        ["TL"] = {
                            "Ako si {slot.identity_claim.name}.",
                            "{slot.identity_claim.name}.",
                            "Ang pangalan ko ay {slot.identity_claim.name}.",
                            "Pangalan ko'y {slot.identity_claim.name}.",
                            "Si {slot.identity_claim.name} ito.",
                            "{slot.identity_claim.name} ang pangalan ko.",
                            "Tawagin mo na lang akong {slot.identity_claim.name}.",
                            "{slot.identity_claim.name} ang tawag nila sa akin.",
                            "Kilala ako bilang {slot.identity_claim.name}.",
                            "Ako nga pala si {slot.identity_claim.name}.",
                            "Pwede mo akong tawaging {slot.identity_claim.name}.",
                            "Lagi akong tinatawag na {slot.identity_claim.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.real",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "real",
            ["sourceId"] = "ui.suggestion.identity.real",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_identity_real.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion.identity",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Say your real name",
                    },
                    ["TL"] = {
                        "Sabihin ang tunay mong pangalan",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["invoke"] = {
                ["intent"] = "INFORM",
                ["speechAct"] = "DISCLOSE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["metadata"] = {
                ["modernizationRetention"] = {
                    ["evidenceCode"] = "DISTINCT_SEMANTIC_ACT_OR_INTENT",
                    ["reason"] = "real (DISCLOSE_IDENTITY / INFORM), lie (DECEIVE_IDENTITY / INFORM), and rude (REFUSE_IDENTITY / REFUSE) own distinct canonical speechAct, intent, and identity-claim semantics.",
                },
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
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}.",
                                        "My name's {slot.identity_claim.name}.",
                                        "My name is {slot.identity_claim.name}.",
                                        "It's {slot.identity_claim.name}.",
                                        "Name's {slot.identity_claim.name}.",
                                        "You can call me {slot.identity_claim.name}.",
                                        "They call me {slot.identity_claim.name}.",
                                        "I go by {slot.identity_claim.name}.",
                                        "The name's {slot.identity_claim.name}.",
                                        "Call me {slot.identity_claim.name}.",
                                        "Folks call me {slot.identity_claim.name}.",
                                    },
                                    ["TL"] = {
                                        "Ako si {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name}.",
                                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                                        "Pangalan ko'y {slot.identity_claim.name}.",
                                        "Si {slot.identity_claim.name} ito.",
                                        "{slot.identity_claim.name} ang pangalan ko.",
                                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                                        "Kilala ako bilang {slot.identity_claim.name}.",
                                        "Ako nga pala si {slot.identity_claim.name}.",
                                        "Pwede mo akong tawaging {slot.identity_claim.name}.",
                                        "Lagi akong tinatawag na {slot.identity_claim.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.real",
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
                            ["fallback"] = "I'm {slot.identity_claim.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.identity.real.say_1",
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
            ["identity_claim"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "fact",
            },
        },
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_identity_real.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Say your real name",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.identity.real.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Say your real name",
                    },
                    ["TL"] = {
                        "Sabihin ang tunay mong pangalan",
                    },
                },
            },
            {
                ["fallback"] = "I'm {slot.identity_claim.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.real.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm {slot.identity_claim.name}.",
                        "{slot.identity_claim.name}.",
                        "My name's {slot.identity_claim.name}.",
                        "My name is {slot.identity_claim.name}.",
                        "It's {slot.identity_claim.name}.",
                        "Name's {slot.identity_claim.name}.",
                        "You can call me {slot.identity_claim.name}.",
                        "They call me {slot.identity_claim.name}.",
                        "I go by {slot.identity_claim.name}.",
                        "The name's {slot.identity_claim.name}.",
                        "Call me {slot.identity_claim.name}.",
                        "Folks call me {slot.identity_claim.name}.",
                    },
                    ["TL"] = {
                        "Ako si {slot.identity_claim.name}.",
                        "{slot.identity_claim.name}.",
                        "Ang pangalan ko ay {slot.identity_claim.name}.",
                        "Pangalan ko'y {slot.identity_claim.name}.",
                        "Si {slot.identity_claim.name} ito.",
                        "{slot.identity_claim.name} ang pangalan ko.",
                        "Tawagin mo na lang akong {slot.identity_claim.name}.",
                        "{slot.identity_claim.name} ang tawag nila sa akin.",
                        "Kilala ako bilang {slot.identity_claim.name}.",
                        "Ako nga pala si {slot.identity_claim.name}.",
                        "Pwede mo akong tawaging {slot.identity_claim.name}.",
                        "Lagi akong tinatawag na {slot.identity_claim.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Don't tell your name",
                ["labelKey"] = "convo.ui.suggestion.identity.rude.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Don't tell your name",
                    },
                    ["TL"] = {
                        "Huwag sabihin ang pangalan",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.identity.rude",
            ["initiatingSay"] = {
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
                                ["fallback"] = "That's none of your business.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.ui.suggestion.identity.rude.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's none of your business.",
                                        "You don't need my name.",
                                        "I'm not giving you my name.",
                                        "Keep walking. You're not getting my name.",
                                        "None of your concern.",
                                        "Forget it. You don't need to know who I am.",
                                        "My name isn't for you to know.",
                                        "I don't owe you my name.",
                                    },
                                    ["TL"] = {
                                        "Wala ka nang pakialam.",
                                        "Hindi mo kailangan ang pangalan ko.",
                                        "Hindi ko ibibigay ang pangalan ko sa'yo.",
                                        "Huwag mo nang alamin ang pangalan ko.",
                                        "Wala kang kinalaman doon.",
                                        "Kalimutan mo na. Hindi mo kailangang malaman.",
                                        "Hindi para sa'yo ang pangalan ko.",
                                        "Hindi ako obligadong magpakilala sa'yo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "REFUSE",
                ["speechAct"] = "REFUSE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["namespace"] = "ui.suggestion.identity",
            ["textRoles"] = {
                {
                    ["fallback"] = "Don't tell your name",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.identity.rude.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Don't tell your name",
                        },
                        ["TL"] = {
                            "Huwag sabihin ang pangalan",
                        },
                    },
                },
                {
                    ["fallback"] = "That's none of your business.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.rude.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's none of your business.",
                            "You don't need my name.",
                            "I'm not giving you my name.",
                            "Keep walking. You're not getting my name.",
                            "None of your concern.",
                            "Forget it. You don't need to know who I am.",
                            "My name isn't for you to know.",
                            "I don't owe you my name.",
                        },
                        ["TL"] = {
                            "Wala ka nang pakialam.",
                            "Hindi mo kailangan ang pangalan ko.",
                            "Hindi ko ibibigay ang pangalan ko sa'yo.",
                            "Huwag mo nang alamin ang pangalan ko.",
                            "Wala kang kinalaman doon.",
                            "Kalimutan mo na. Hindi mo kailangang malaman.",
                            "Hindi para sa'yo ang pangalan ko.",
                            "Hindi ako obligadong magpakilala sa'yo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.identity.rude",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rude",
            ["sourceId"] = "ui.suggestion.identity.rude",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_identity_rude.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion.identity",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Don't tell your name",
                    },
                    ["TL"] = {
                        "Huwag sabihin ang pangalan",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["invoke"] = {
                ["intent"] = "REFUSE",
                ["speechAct"] = "REFUSE_IDENTITY",
                ["subject"] = "IDENTITY",
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.identity.rude.label",
                        ["text"] = {
                            ["EN"] = "Don't tell your name",
                            ["TL"] = "Huwag sabihin ang pangalan",
                        },
                    },
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
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That's none of your business.",
                                        "You don't need my name.",
                                        "I'm not giving you my name.",
                                        "Keep walking. You're not getting my name.",
                                        "None of your concern.",
                                        "Forget it. You don't need to know who I am.",
                                        "My name isn't for you to know.",
                                        "I don't owe you my name.",
                                    },
                                    ["TL"] = {
                                        "Wala ka nang pakialam.",
                                        "Hindi mo kailangan ang pangalan ko.",
                                        "Hindi ko ibibigay ang pangalan ko sa'yo.",
                                        "Huwag mo nang alamin ang pangalan ko.",
                                        "Wala kang kinalaman doon.",
                                        "Kalimutan mo na. Hindi mo kailangang malaman.",
                                        "Hindi para sa'yo ang pangalan ko.",
                                        "Hindi ako obligadong magpakilala sa'yo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.identity.rude",
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
                            ["templateID"] = "convo.ui.suggestion.identity.rude.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_identity_rude.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Don't tell your name",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.identity.rude.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Don't tell your name",
                    },
                    ["TL"] = {
                        "Huwag sabihin ang pangalan",
                    },
                },
            },
            {
                ["fallback"] = "That's none of your business.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.rude.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's none of your business.",
                        "You don't need my name.",
                        "I'm not giving you my name.",
                        "Keep walking. You're not getting my name.",
                        "None of your concern.",
                        "Forget it. You don't need to know who I am.",
                        "My name isn't for you to know.",
                        "I don't owe you my name.",
                    },
                    ["TL"] = {
                        "Wala ka nang pakialam.",
                        "Hindi mo kailangan ang pangalan ko.",
                        "Hindi ko ibibigay ang pangalan ko sa'yo.",
                        "Huwag mo nang alamin ang pangalan ko.",
                        "Wala kang kinalaman doon.",
                        "Kalimutan mo na. Hindi mo kailangang malaman.",
                        "Hindi para sa'yo ang pangalan ko.",
                        "Hindi ako obligadong magpakilala sa'yo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.needs_destination.tooltip",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_needs_destination_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
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
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Choose a destination first.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.ui.suggestion.needs_destination.tooltip.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_needs_destination_tooltip.json",
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
        ["domainPath"] = "static_suggestion_text",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Ask what's on their mind",
                ["labelKey"] = "convo.ui.suggestion.personal_check_in.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what's on their mind",
                    },
                    ["TL"] = {
                        "Alamin kung may bumabagabag sa kanya",
                    },
                },
            },
            ["familyID"] = "ui.suggestion.personal_check_in",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.personal_check_in.say.1.default",
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask what's on their mind",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.personal_check_in.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask what's on their mind",
                        },
                        ["TL"] = {
                            "Alamin kung may bumabagabag sa kanya",
                        },
                    },
                },
                {
                    ["fallback"] = "Anything bothering you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.personal_check_in.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Anything bothering you?",
                        },
                        ["TL"] = {
                            "May bumabagabag ba sa'yo?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.personal_check_in",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "personal_check_in",
            ["sourceId"] = "ui.suggestion.personal_check_in",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_personal_check_in.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionPersonalCheckIn",
        ["namespace"] = "ui.suggestion",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask what's on their mind",
                    },
                    ["TL"] = {
                        "Alamin kung may bumabagabag sa kanya",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.personal_check_in.label",
                        ["text"] = {
                            ["EN"] = "Ask what's on their mind",
                            ["TL"] = "Alamin kung may bumabagabag sa kanya",
                        },
                    },
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
                                ["id"] = "default",
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
            ["topics"] = {
                {
                    ["domain"] = "ui",
                    ["id"] = "ui_suggestion",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "ui.suggestion.personal_check_in",
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
                            ["templateID"] = "convo.ui.suggestion.personal_check_in.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_personal_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask what's on their mind",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.personal_check_in.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what's on their mind",
                    },
                    ["TL"] = {
                        "Alamin kung may bumabagabag sa kanya",
                    },
                },
            },
            {
                ["fallback"] = "Anything bothering you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.personal_check_in.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Anything bothering you?",
                    },
                    ["TL"] = {
                        "May bumabagabag ba sa'yo?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
