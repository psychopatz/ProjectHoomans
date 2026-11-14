-- Generated; do not edit by hand.
return {
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Open trading",
                ["labelKey"] = "convo.ui.suggestion.trade.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Open trading",
                    },
                    ["TL"] = {
                        "Buksan ang kalakalan",
                    },
                },
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Open trading",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.trade.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Open trading",
                        },
                        ["TL"] = {
                            "Buksan ang kalakalan",
                        },
                    },
                },
                {
                    ["fallback"] = "Let's trade.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.trade.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's trade.",
                        },
                        ["TL"] = {
                            "Magpalitan tayo.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.trade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "trade",
            ["sourceId"] = "ui.suggestion.trade",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
                        "Open trading",
                    },
                    ["TL"] = {
                        "Buksan ang kalakalan",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["metadata"] = {
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.trade.label",
                        ["text"] = {
                            ["EN"] = "Open trading",
                            ["TL"] = "Buksan ang kalakalan",
                        },
                    },
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
                                ["id"] = "default",
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
                            ["templateID"] = "psdl.ui.suggestion.trade.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_trade.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Open trading",
                    },
                    ["TL"] = {
                        "Buksan ang kalakalan",
                    },
                },
            },
            {
                ["fallback"] = "Let's trade.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.trade.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Let's trade.",
                    },
                    ["TL"] = {
                        "Magpalitan tayo.",
                    },
                },
                ["variantID"] = "default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["labelFallback"] = "Ask them to wait there",
                ["labelKey"] = "convo.ui.suggestion.wait_at.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask them to wait there",
                    },
                    ["TL"] = {
                        "Sabihing maghintay siya roon",
                    },
                },
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask them to wait there",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.wait_at.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask them to wait there",
                        },
                        ["TL"] = {
                            "Sabihing maghintay siya roon",
                        },
                    },
                },
                {
                    ["fallback"] = "Wait there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.wait_at.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait there.",
                        },
                        ["TL"] = {
                            "Maghintay ka roon.",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "ui.suggestion.wait_at",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "wait_at",
            ["sourceId"] = "ui.suggestion.wait_at",
            ["sourcePath"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
                        "Ask them to wait there",
                    },
                    ["TL"] = {
                        "Sabihing maghintay siya roon",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["metadata"] = {
                ["sourceProfile"] = "conversation.source.project.hoomans.conversation.authoring.51ad5f4261",
                ["textRows"] = {
                    {
                        ["key"] = "suggestion.wait_at.label",
                        ["text"] = {
                            ["EN"] = "Ask them to wait there",
                            ["TL"] = "Sabihing maghintay siya roon",
                        },
                    },
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
                                ["id"] = "default",
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
                            ["templateID"] = "psdl.ui.suggestion.wait_at.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/static_suggestion_text/ui_suggestion_wait_at.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "Ask them to wait there",
                    },
                    ["TL"] = {
                        "Sabihing maghintay siya roon",
                    },
                },
            },
            {
                ["fallback"] = "Wait there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.wait_at.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Wait there.",
                    },
                    ["TL"] = {
                        "Maghintay ka roon.",
                    },
                },
                ["variantID"] = "default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText__725d3d75",
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
