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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.actions.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_actions_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.actions.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_actions_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.flow.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_flow_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.flow.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_flow_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.identity.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_identity_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.identity.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_identity_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.landing.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_landing_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.landing.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_landing_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.medical.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_medical_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.medical.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_medical_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.movement.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_movement_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.movement.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_movement_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.needs.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_needs_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.needs.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_needs_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.response.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_response_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.response.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_response_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.time.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_time_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.time.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_time_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.utilities.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_utilities_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.utilities.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_utilities_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.weather.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_weather_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.weather.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_weather_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.wellbeing.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_wellbeing_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.wellbeing.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_wellbeing_label.json",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.group.whats_up.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_group_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
                            ["templateID"] = "convo.ui.suggestion.group.whats_up.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_group_whats_up_label.json",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/SemanticSuggestionsTitleToSuggestionIdentityLie",
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
}
