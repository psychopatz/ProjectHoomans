-- Generated Conversation discovery index; do not edit by hand.
return {
    ["offer.question.activity"] = {
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        },
        ["id"] = "offer.question.activity",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.activity",
        },
        ["source"] = "dialogue/core_check_in/question_activity.json",
    },
    ["offer.question.wellbeing"] = {
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        },
        ["id"] = "offer.question.wellbeing",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.wellbeing",
            "question.wellbeing_detail",
        },
        ["source"] = "dialogue/core_check_in/question_wellbeing.json",
    },
    ["question.date"] = {
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.date",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_check_in/question_date.json",
    },
    ["question.time"] = {
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.time",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_check_in/question_time.json",
    },
    ["question.weather"] = {
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.weather",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_check_in/question_weather.json",
    },
    ["question.wellbeing_detail"] = {
        ["dependents"] = {
            "offer.question.wellbeing",
        },
        ["domain"] = "core_check_in",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreCheckIn",
        },
        ["id"] = "question.wellbeing_detail",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_check_in/question_wellbeing_detail.json",
    },
}
