-- Generated; do not edit by hand.
return {
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
            ["metadata"] = {
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
                ["translations"] = {
                    ["EN"] = {
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
                    },
                },
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
            ["namespace"] = "ui.suggestion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Wait here.",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.ui.suggestion.stay.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait here.",
                        },
                        ["TL"] = {
                            "Dito ka maghintay.",
                        },
                    },
                },
                {
                    ["fallback"] = "Wait here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.ui.suggestion.stay.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Wait here.",
                        },
                        ["TL"] = {
                            "Dito ka maghintay.",
                        },
                    },
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
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
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
                        ["key"] = "suggestion.stay.label",
                        ["text"] = {
                            ["EN"] = "Wait here.",
                            ["TL"] = "Dito ka maghintay.",
                        },
                    },
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
                                ["id"] = "default",
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
                ["translations"] = {
                    ["EN"] = {
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
                    },
                },
            },
            {
                ["fallback"] = "Wait here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.ui.suggestion.stay.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Wait here.",
                    },
                    ["TL"] = {
                        "Dito ka maghintay.",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_again_about.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_talk_again_about_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.talk_something_else.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_talk_something_else_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "trade",
            ["sourceId"] = "ui.suggestion.trade",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_trade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "tooltip",
            ["sourceId"] = "ui.suggestion.unavailable.tooltip",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_unavailable_tooltip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
        ["domainPath"] = "static_suggestion_text",
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wait_at",
            ["sourceId"] = "ui.suggestion.wait_at",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_wait_at.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
            ["domains"] = {
                {
                    ["domain"] = "ui",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
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
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "label",
            ["sourceId"] = "ui.suggestion.whats_up.label",
            ["sourcePath"] = "dialogue/static_suggestion_text/ui_suggestion_whats_up_label.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/StaticSuggestionText/IdentityRealToWhatsUpLabel",
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
