-- Generated Conversation discovery index; do not edit by hand.
return {
    ["accept"] = {
        ["dependents"] = {
            "quest.clinic_supplies.accept",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "accept",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/accept.json",
    },
    ["compliment"] = {
        ["dependents"] = {
            "tool_reply.compliment",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "compliment",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/compliment.json",
    },
    ["flow.weather.raining"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "flow.weather.raining",
        ["kind"] = "dialogue",
        ["related"] = {
            "pnc.dataset.question.weather.can_we_talk_about_the_weather",
        },
        ["source"] = "dialogue/core_semantic_responses/flow_weather_raining.json",
    },
    ["greeting"] = {
        ["dependents"] = {
            "flow.greeting.exchange",
            "flow.greeting.followup",
            "flow.greeting.opening",
            "flow.greeting.opening.rain",
            "flow.greeting.responses",
            "integration.companion_dogs.greeting",
            "social.greetings.contextual",
            "social.greetings.hostile.parley",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "greeting",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/greeting.json",
    },
    ["offer"] = {
        ["dependents"] = {
            "flow.needs.exchange",
            "needs",
            "quest.clinic_supplies.offer",
            "question.needs.offer",
            "social.recruitment.offer",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "offer",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/offer.json",
    },
    ["question.activity"] = {
        ["dependents"] = {
            "offer.question.activity",
            "question.activity.fishing",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.activity",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_activity.json",
    },
    ["question.backstory.ambiguous"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.ambiguous",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_backstory_ambiguous.json",
    },
    ["question.backstory.follow_up.location"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.follow_up.location",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
    },
    ["question.backstory.follow_up.miss"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.follow_up.miss",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
    },
    ["question.backstory.refusal"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.refusal",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_backstory_refusal.json",
    },
    ["question.backstory.suspected"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.suspected",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_backstory_suspected.json",
    },
    ["question.wellbeing"] = {
        ["dependents"] = {
            "offer.question.wellbeing",
            "question.wellbeing.default",
            "question.wellbeing.fatigue",
            "question.wellbeing.fatigue_alt",
            "question.wellbeing.hunger",
            "question.wellbeing.hunger_alt",
            "question.wellbeing.injured",
            "question.wellbeing.panic",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.wellbeing",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/question_wellbeing.json",
    },
    ["question.wellbeing.unknown"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.wellbeing.unknown",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.wellbeing",
        },
        ["source"] = "dialogue/core_semantic_responses/question_wellbeing_unknown.json",
    },
    ["refuse"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "refuse",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/refuse.json",
    },
    ["response_pool.question.identity"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "response_pool.question.identity",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.identity",
        },
        ["source"] = "dialogue/core_semantic_responses/question_identity.json",
    },
    ["thanks"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "thanks",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_semantic_responses/thanks.json",
    },
}
