-- Hand-maintained ProjectHoomans ConvoEngine module.
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
                        ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                        ["key"] = "semantic_suggestions.title",
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
                                ["fallback"] = "CONTEXTUAL SUGGESTIONS",
                                ["id"] = "neutral",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                        ["fallback"] = "Already following you.",
                        ["key"] = "suggestion.already_following.tooltip",
                    },
                    {
                        ["fallback"] = "Already holding position.",
                        ["key"] = "suggestion.already_staying.tooltip",
                    },
                    {
                        ["fallback"] = "This camp location is too far away right now.",
                        ["key"] = "suggestion.camp_site_out_of_range.tooltip",
                    },
                    {
                        ["fallback"] = "This camp location is no longer available; choose a fresh location.",
                        ["key"] = "suggestion.camp_site_stale.tooltip",
                    },
                    {
                        ["fallback"] = "Unavailable while the companion is busy or in combat.",
                        ["key"] = "suggestion.companion_busy.tooltip",
                    },
                    {
                        ["fallback"] = "Unavailable because the companion is dead.",
                        ["key"] = "suggestion.companion_dead.tooltip",
                    },
                    {
                        ["fallback"] = "Unavailable because the companion is incapacitated.",
                        ["key"] = "suggestion.companion_incapacitated.tooltip",
                    },
                    {
                        ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                        ["key"] = "suggestion.companion_unavailable.tooltip",
                    },
                    {
                        ["fallback"] = "Go Home is unavailable because no base has been established.",
                        ["key"] = "suggestion.go_home.no_base.tooltip",
                    },
                    {
                        ["fallback"] = "No valid camp location is currently available.",
                        ["key"] = "suggestion.no_camp_site.tooltip",
                    },
                    {
                        ["fallback"] = "Stay is available while the companion is following you.",
                        ["key"] = "suggestion.not_following.tooltip",
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
                                ["fallback"] = "Unavailable because this companion cannot receive orders right now.",
                                ["id"] = "neutral",
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
                        ["fallback"] = "Back",
                        ["key"] = "suggestion.back.label",
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
                                ["fallback"] = "Back",
                                ["id"] = "neutral",
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
                },
                {
                    ["fallback"] = "How are we doing?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.check_in.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Check in with them",
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
                        ["fallback"] = "Check in with them",
                        ["key"] = "suggestion.check_in.label",
                    },
                    {
                        ["fallback"] = "How are we doing?",
                        ["key"] = "suggestion.check_in.utterance",
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
                                ["fallback"] = "How are we doing?",
                                ["id"] = "default",
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
            },
            {
                ["fallback"] = "How are we doing?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.check_in.say.1.default",
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
                },
                {
                    ["fallback"] = "Let's camp here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.1.variant_1",
                    ["variantID"] = "variant_1",
                },
                {
                    ["fallback"] = "Let's camp in the %1.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.2.variant_1",
                    ["variantID"] = "variant_1",
                },
                {
                    ["fallback"] = "Let's camp by the campfire.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.companion_camp.say.3.variant_1",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Let's camp...",
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
                        ["fallback"] = "Let's camp...",
                        ["key"] = "suggestion.companion_camp.label",
                    },
                    {
                        ["fallback"] = "Let's camp here.",
                        ["key"] = "suggestion.companion_camp_here.utterance",
                    },
                    {
                        ["fallback"] = "Let's camp in the %1.",
                        ["key"] = "suggestion.companion_camp_room.utterance",
                    },
                    {
                        ["fallback"] = "Let's camp by the campfire.",
                        ["key"] = "suggestion.companion_campfire.utterance",
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
                                ["fallback"] = "Let's camp here.",
                                ["id"] = "variant_1",
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
            },
            {
                ["fallback"] = "Let's camp here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.1.variant_1",
                ["variantID"] = "variant_1",
            },
            {
                ["fallback"] = "Let's camp in the %1.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.2.variant_1",
                ["variantID"] = "variant_1",
            },
            {
                ["fallback"] = "Let's camp by the campfire.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.companion_camp.say.3.variant_1",
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
                        ["fallback"] = "I need you to do something...",
                        ["key"] = "suggestion.companion_orders.label",
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
                                ["fallback"] = "I need you to do something...",
                                ["id"] = "neutral",
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
                },
                {
                    ["fallback"] = "Follow me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.follow.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Follow me.",
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
                        ["fallback"] = "Follow me.",
                        ["key"] = "suggestion.follow.label",
                    },
                    {
                        ["fallback"] = "Follow me.",
                        ["key"] = "suggestion.follow.utterance",
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
                                ["fallback"] = "Follow me.",
                                ["id"] = "default",
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
            },
            {
                ["fallback"] = "Follow me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.follow.say.1.default",
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
                },
                {
                    ["fallback"] = "I'm fine, thank you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Say you're doing fine",
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
                        ["fallback"] = "Say you're doing fine",
                        ["key"] = "suggestion.greeting_report_fine.label",
                    },
                    {
                        ["fallback"] = "I'm fine, thank you.",
                        ["key"] = "suggestion.greeting_report_fine.utterance",
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
                                ["fallback"] = "I'm fine, thank you.",
                                ["id"] = "default",
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
            },
            {
                ["fallback"] = "I'm fine, thank you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_report_fine.say.1.default",
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
                },
                {
                    ["fallback"] = "Thanks.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.greeting_thank.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Thank them",
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
                        ["fallback"] = "Thank them",
                        ["key"] = "suggestion.greeting_thank.label",
                    },
                    {
                        ["fallback"] = "Thanks.",
                        ["key"] = "suggestion.greeting_thank.utterance",
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
                                ["fallback"] = "Thanks.",
                                ["id"] = "default",
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
            },
            {
                ["fallback"] = "Thanks.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.greeting_thank.say.1.default",
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
                            },
                            {
                                ["fallback"] = "Current conversation branch",
                                ["id"] = "flow.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Identity",
                                ["id"] = "identity.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Talk",
                                ["id"] = "landing.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Medical",
                                ["id"] = "medical.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Owned companion actions",
                                ["id"] = "movement.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Needs",
                                ["id"] = "needs.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "NPC reply",
                                ["id"] = "response.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Time and date",
                                ["id"] = "time.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Conversation utilities",
                                ["id"] = "utilities.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Weather",
                                ["id"] = "weather.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "Wellbeing",
                                ["id"] = "wellbeing.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
                                ["textRole"] = "spoken_action",
                            },
                            {
                                ["fallback"] = "What's up",
                                ["id"] = "whats_up.label",
                                ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
                                ["textRole"] = "spoken_action",
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
                    ["variantID"] = "actions.label",
                },
                {
                    ["fallback"] = "Current conversation branch",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
                    ["variantID"] = "flow.label",
                },
                {
                    ["fallback"] = "Identity",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
                    ["variantID"] = "identity.label",
                },
                {
                    ["fallback"] = "Talk",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
                    ["variantID"] = "landing.label",
                },
                {
                    ["fallback"] = "Medical",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
                    ["variantID"] = "medical.label",
                },
                {
                    ["fallback"] = "Owned companion actions",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
                    ["variantID"] = "movement.label",
                },
                {
                    ["fallback"] = "Needs",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
                    ["variantID"] = "needs.label",
                },
                {
                    ["fallback"] = "NPC reply",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
                    ["variantID"] = "response.label",
                },
                {
                    ["fallback"] = "Time and date",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
                    ["variantID"] = "time.label",
                },
                {
                    ["fallback"] = "Conversation utilities",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
                    ["variantID"] = "utilities.label",
                },
                {
                    ["fallback"] = "Weather",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
                    ["variantID"] = "weather.label",
                },
                {
                    ["fallback"] = "Wellbeing",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
                    ["variantID"] = "wellbeing.label",
                },
                {
                    ["fallback"] = "What's up",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                        ["fallback"] = "Conversation actions",
                        ["key"] = "suggestion.group.actions.label",
                    },
                    {
                        ["fallback"] = "Current conversation branch",
                        ["key"] = "suggestion.group.flow.label",
                    },
                    {
                        ["fallback"] = "Identity",
                        ["key"] = "suggestion.group.identity.label",
                    },
                    {
                        ["fallback"] = "Talk",
                        ["key"] = "suggestion.group.landing.label",
                    },
                    {
                        ["fallback"] = "Medical",
                        ["key"] = "suggestion.group.medical.label",
                    },
                    {
                        ["fallback"] = "Owned companion actions",
                        ["key"] = "suggestion.group.movement.label",
                    },
                    {
                        ["fallback"] = "Needs",
                        ["key"] = "suggestion.group.needs.label",
                    },
                    {
                        ["fallback"] = "NPC reply",
                        ["key"] = "suggestion.group.response.label",
                    },
                    {
                        ["fallback"] = "Time and date",
                        ["key"] = "suggestion.group.time.label",
                    },
                    {
                        ["fallback"] = "Conversation utilities",
                        ["key"] = "suggestion.group.utilities.label",
                    },
                    {
                        ["fallback"] = "Weather",
                        ["key"] = "suggestion.group.weather.label",
                    },
                    {
                        ["fallback"] = "Wellbeing",
                        ["key"] = "suggestion.group.wellbeing.label",
                    },
                    {
                        ["fallback"] = "What's up",
                        ["key"] = "suggestion.group.whats_up.label",
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
                                ["fallback"] = "Conversation actions",
                                ["id"] = "actions.label",
                            },
                            {
                                ["fallback"] = "Current conversation branch",
                                ["id"] = "flow.label",
                            },
                            {
                                ["fallback"] = "Identity",
                                ["id"] = "identity.label",
                            },
                            {
                                ["fallback"] = "Talk",
                                ["id"] = "landing.label",
                            },
                            {
                                ["fallback"] = "Medical",
                                ["id"] = "medical.label",
                            },
                            {
                                ["fallback"] = "Owned companion actions",
                                ["id"] = "movement.label",
                            },
                            {
                                ["fallback"] = "Needs",
                                ["id"] = "needs.label",
                            },
                            {
                                ["fallback"] = "NPC reply",
                                ["id"] = "response.label",
                            },
                            {
                                ["fallback"] = "Time and date",
                                ["id"] = "time.label",
                            },
                            {
                                ["fallback"] = "Conversation utilities",
                                ["id"] = "utilities.label",
                            },
                            {
                                ["fallback"] = "Weather",
                                ["id"] = "weather.label",
                            },
                            {
                                ["fallback"] = "Wellbeing",
                                ["id"] = "wellbeing.label",
                            },
                            {
                                ["fallback"] = "What's up",
                                ["id"] = "whats_up.label",
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
                ["variantID"] = "actions.label",
            },
            {
                ["fallback"] = "Current conversation branch",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.flow.label",
                ["variantID"] = "flow.label",
            },
            {
                ["fallback"] = "Identity",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.identity.label",
                ["variantID"] = "identity.label",
            },
            {
                ["fallback"] = "Talk",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.landing.label",
                ["variantID"] = "landing.label",
            },
            {
                ["fallback"] = "Medical",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.medical.label",
                ["variantID"] = "medical.label",
            },
            {
                ["fallback"] = "Owned companion actions",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.movement.label",
                ["variantID"] = "movement.label",
            },
            {
                ["fallback"] = "Needs",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.needs.label",
                ["variantID"] = "needs.label",
            },
            {
                ["fallback"] = "NPC reply",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.response.label",
                ["variantID"] = "response.label",
            },
            {
                ["fallback"] = "Time and date",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.time.label",
                ["variantID"] = "time.label",
            },
            {
                ["fallback"] = "Conversation utilities",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.utilities.label",
                ["variantID"] = "utilities.label",
            },
            {
                ["fallback"] = "Weather",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.weather.label",
                ["variantID"] = "weather.label",
            },
            {
                ["fallback"] = "Wellbeing",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.wellbeing.label",
                ["variantID"] = "wellbeing.label",
            },
            {
                ["fallback"] = "What's up",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.group.say.1.whats_up.label",
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
                                ["variantCount"] = 12,
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
                },
                {
                    ["fallback"] = "I'm {slot.identity_claim.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.lie.say.1.neutral",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Lie about your name",
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
                        ["fallback"] = "Lie about your name",
                        ["key"] = "suggestion.identity.lie.label",
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
                                ["fallback"] = "I'm {slot.identity_claim.name}.",
                                ["id"] = "neutral",
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
            },
            {
                ["fallback"] = "I'm {slot.identity_claim.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.lie.say.1.neutral",
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
                                ["variantCount"] = 12,
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
                },
                {
                    ["fallback"] = "I'm {slot.identity_claim.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.real.say.1.neutral",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Say your real name",
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
                        ["fallback"] = "Say your real name",
                        ["key"] = "suggestion.identity.real.label",
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
                                ["fallback"] = "I'm {slot.identity_claim.name}.",
                                ["id"] = "neutral",
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
            },
            {
                ["fallback"] = "I'm {slot.identity_claim.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.real.say.1.neutral",
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
                                ["variantCount"] = 8,
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
                },
                {
                    ["fallback"] = "That's none of your business.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.identity.rude.say.1.neutral",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Don't tell your name",
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
                        ["fallback"] = "Don't tell your name",
                        ["key"] = "suggestion.identity.rude.label",
                    },
                    {
                        ["fallback"] = "That's none of your business.",
                        ["key"] = "suggestion.identity.rude.utterance",
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
                                ["fallback"] = "That's none of your business.",
                                ["id"] = "neutral",
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
            },
            {
                ["fallback"] = "That's none of your business.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.identity.rude.say.1.neutral",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                        ["fallback"] = "Choose a destination first.",
                        ["key"] = "suggestion.needs_destination.tooltip",
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
                                ["fallback"] = "Choose a destination first.",
                                ["id"] = "neutral",
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
                },
                {
                    ["fallback"] = "Anything bothering you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.personal_check_in.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Ask what's on their mind",
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
                        ["fallback"] = "Ask what's on their mind",
                        ["key"] = "suggestion.personal_check_in.label",
                    },
                    {
                        ["fallback"] = "Anything bothering you?",
                        ["key"] = "suggestion.personal_check_in.utterance",
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
                                ["fallback"] = "Anything bothering you?",
                                ["id"] = "default",
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
            },
            {
                ["fallback"] = "Anything bothering you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.personal_check_in.say.1.default",
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
                ["labelFallback"] = "Wait here.",
                ["labelKey"] = "convo.ui.suggestion.stay.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "ui.suggestion.stay",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.stay.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wait here.",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.stay.affordance.label",
                },
                {
                    ["fallback"] = "Wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.stay.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stay",
            ["sourceId"] = "ui.suggestion.stay",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_stay.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Wait here.",
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
                        ["fallback"] = "Wait here.",
                        ["key"] = "suggestion.stay.label",
                    },
                    {
                        ["fallback"] = "Wait here.",
                        ["key"] = "suggestion.stay.utterance",
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
                                ["fallback"] = "Wait here.",
                                ["id"] = "default",
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
            ["responsePlanID"] = "ui.suggestion.stay",
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
                            ["templateID"] = "convo.ui.suggestion.stay.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_stay.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Wait here.",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.stay.affordance.label",
            },
            {
                ["fallback"] = "Wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.stay.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.talk_again_about.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_again_about.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textKey"] = "suggestion.talk_again_about.label",
                ["textRows"] = {
                    {
                        ["fallback"] = "Talk again about",
                        ["key"] = "suggestion.talk_again_about.label",
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
                                ["fallback"] = "Talk again about",
                                ["id"] = "neutral",
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
                            ["templateID"] = "convo.ui.suggestion.talk_again_about.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.talk_something_else.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_something_else.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textKey"] = "suggestion.talk_something_else.label",
                ["textRows"] = {
                    {
                        ["fallback"] = "Let's talk something else",
                        ["key"] = "suggestion.talk_something_else.label",
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
                                ["fallback"] = "Let's talk something else",
                                ["id"] = "neutral",
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
                            ["templateID"] = "convo.ui.suggestion.talk_something_else.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
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
                ["labelFallback"] = "Open trading",
                ["labelKey"] = "convo.ui.suggestion.trade.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "ui.suggestion.trade",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.trade.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion",
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Open trading",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.trade.affordance.label",
                },
                {
                    ["fallback"] = "Let's trade.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.trade.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.trade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "trade",
            ["sourceId"] = "ui.suggestion.trade",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_trade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Open trading",
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
                        ["fallback"] = "Open trading",
                        ["key"] = "suggestion.trade.label",
                    },
                    {
                        ["fallback"] = "Let's trade.",
                        ["key"] = "suggestion.trade.utterance",
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
                                ["fallback"] = "Let's trade.",
                                ["id"] = "default",
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
            ["responsePlanID"] = "ui.suggestion.trade",
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
                            ["templateID"] = "convo.ui.suggestion.trade.say_1",
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_trade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Open trading",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.trade.affordance.label",
            },
            {
                ["fallback"] = "Let's trade.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.trade.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.unavailable.tooltip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.unavailable.tooltip",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textKey"] = "suggestion.unavailable.tooltip",
                ["textRows"] = {
                    {
                        ["fallback"] = "Unavailable in the current situation.",
                        ["key"] = "suggestion.unavailable.tooltip",
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
                                ["fallback"] = "Unavailable in the current situation.",
                                ["id"] = "neutral",
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
                            ["templateID"] = "convo.ui.suggestion.unavailable.tooltip.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
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
                ["labelFallback"] = "Ask them to wait there",
                ["labelKey"] = "convo.ui.suggestion.wait_at.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "ui.suggestion.wait_at",
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
                                ["id"] = "default",
                                ["templateID"] = "convo.ui.suggestion.wait_at.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask them to wait there",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.wait_at.affordance.label",
                },
                {
                    ["fallback"] = "Wait there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.wait_at.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.wait_at",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wait_at",
            ["sourceId"] = "ui.suggestion.wait_at",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_wait_at.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
                ["labelFallback"] = "Ask them to wait there",
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
                        ["fallback"] = "Ask them to wait there",
                        ["key"] = "suggestion.wait_at.label",
                    },
                    {
                        ["fallback"] = "Wait there.",
                        ["key"] = "suggestion.wait_at.utterance",
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
                                ["fallback"] = "Wait there.",
                                ["id"] = "default",
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
            ["responsePlanID"] = "ui.suggestion.wait_at",
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
                            ["templateID"] = "convo.ui.suggestion.wait_at.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_wait_at.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask them to wait there",
                ["role"] = "button_label",
                ["templateID"] = "convo.ui.suggestion.wait_at.affordance.label",
            },
            {
                ["fallback"] = "Wait there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.wait_at.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "static_suggestion_text",
        ["domainPath"] = "static_suggestion_text",
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "ui.suggestion.whats_up.label",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.whats_up.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textKey"] = "suggestion.whats_up.label",
                ["textRows"] = {
                    {
                        ["fallback"] = "What's up?",
                        ["key"] = "suggestion.whats_up.label",
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
                                ["fallback"] = "What's up?",
                                ["id"] = "neutral",
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
                            ["templateID"] = "convo.ui.suggestion.whats_up.label.say_1",
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
        ["sourceShard"] = "dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
