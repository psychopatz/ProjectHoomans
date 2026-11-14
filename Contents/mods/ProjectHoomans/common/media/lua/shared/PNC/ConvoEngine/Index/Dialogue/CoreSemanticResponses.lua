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
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/accept.json",
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
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/compliment.json",
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
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/flow_weather_raining.json",
    },
    ["greeting"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "greeting",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/greeting.json",
    },
    ["offer"] = {
        ["dependents"] = {
            "quest.clinic_supplies.offer",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "offer",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/offer.json",
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
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_activity.json",
    },
    ["question.backstory.ambiguous"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.ambiguous",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_ambiguous.json",
    },
    ["question.backstory.follow_up.location"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.follow_up.location",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
    },
    ["question.backstory.follow_up.miss"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.follow_up.miss",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
    },
    ["question.backstory.known"] = {
        ["dependents"] = {
            "question.backstory.known.education",
            "question.backstory.known.family_background",
            "question.backstory.known.fear",
            "question.backstory.known.former_job",
            "question.backstory.known.hobby",
            "question.backstory.known.hometown",
            "question.backstory.known.tragedy",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known.json",
    },
    ["question.backstory.known.education"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.education",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_education.json",
    },
    ["question.backstory.known.family_background"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.family_background",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_family_background.json",
    },
    ["question.backstory.known.fear"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.fear",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_fear.json",
    },
    ["question.backstory.known.former_job"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.former_job",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_former_job.json",
    },
    ["question.backstory.known.hobby"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.hobby",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hobby.json",
    },
    ["question.backstory.known.hometown"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.hometown",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hometown.json",
    },
    ["question.backstory.known.tragedy"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.known.tragedy",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.backstory.known",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_tragedy.json",
    },
    ["question.backstory.refusal"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.refusal",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_refusal.json",
    },
    ["question.backstory.suspected"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.backstory.suspected",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_suspected.json",
    },
    ["question.needs.proposal"] = {
        ["dependents"] = {
            "question.needs.proposal.hunger",
            "question.needs.proposal.thirst",
            "question.needs.proposal.unknown",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.needs.proposal",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.needs",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_proposal.json",
    },
    ["question.needs.quantity"] = {
        ["dependents"] = {
            "question.needs.quantity.hunger",
            "question.needs.quantity.thirst",
            "question.needs.quantity.unknown",
        },
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        },
        ["id"] = "question.needs.quantity",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.needs",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_quantity.json",
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
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing.json",
    },
    ["question.wellbeing.unknown"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        },
        ["id"] = "question.wellbeing.unknown",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.wellbeing",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing_unknown.json",
    },
    ["refuse"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        },
        ["id"] = "refuse",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/refuse.json",
    },
    ["response_pool.question.identity"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        },
        ["id"] = "response_pool.question.identity",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.identity",
        },
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/question_identity.json",
    },
    ["thanks"] = {
        ["domain"] = "core_semantic_responses",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CoreSemanticResponses__5fef31e4",
        },
        ["id"] = "thanks",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/core_semantic_responses/thanks.json",
    },
}
