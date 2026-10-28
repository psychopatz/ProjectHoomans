-- Generated Conversation discovery index; do not edit by hand.
return {
    ["semantic.accept"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.accept",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
    ["semantic.compliment"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.compliment",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
    ["semantic.flow.weather.raining"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/NeedsWeather",
        },
        ["id"] = "semantic.flow.weather.raining",
        ["kind"] = "responsePool",
        ["related"] = {
            "pnc.dataset.question.weather.can_we_talk_about_the_weather",
        },
        ["source"] = "flows/common/needs_weather.json",
    },
    ["semantic.greeting"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.greeting",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
    ["semantic.offer"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.offer",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
    ["semantic.question.activity"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Questions",
        },
        ["id"] = "semantic.question.activity",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/questions.json",
    },
    ["semantic.question.identity"] = {
        ["dependents"] = {
            "phrase.semantic.question.identity",
        },
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Questions",
        },
        ["id"] = "semantic.question.identity",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/questions.json",
    },
    ["semantic.question.needs.proposal"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/NeedsWeather",
        },
        ["id"] = "semantic.question.needs.proposal",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/needs_weather.json",
    },
    ["semantic.question.needs.quantity"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/NeedsWeather",
        },
        ["id"] = "semantic.question.needs.quantity",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/needs_weather.json",
    },
    ["semantic.question.wellbeing"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Questions",
        },
        ["id"] = "semantic.question.wellbeing",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/questions.json",
    },
    ["semantic.question.wellbeing.unknown"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Questions",
        },
        ["id"] = "semantic.question.wellbeing.unknown",
        ["kind"] = "responsePool",
        ["related"] = {
            "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
        },
        ["source"] = "flows/common/questions.json",
    },
    ["semantic.refuse"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.refuse",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
    ["semantic.thanks"] = {
        ["domain"] = "common",
        ["generated"] = {
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        },
        ["id"] = "semantic.thanks",
        ["kind"] = "responsePool",
        ["source"] = "flows/common/social.json",
    },
}
