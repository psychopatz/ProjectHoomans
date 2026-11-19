-- Generated Conversation discovery index; do not edit by hand.
return {
    ["medical.distress"] = {
        ["dependents"] = {
            "medical.distress.call",
            "medical.distress.repeat",
            "medical.distress.teammate",
            "medical.distress.treatment",
            "medical.distress.update",
        },
        ["domain"] = "medical_distress",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/MedicalDistress",
        },
        ["id"] = "medical.distress",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/medical_distress/medical_distress.json",
    },
    ["medical.distress.call"] = {
        ["domain"] = "medical_distress",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/MedicalDistress",
        },
        ["id"] = "medical.distress.call",
        ["kind"] = "dialogue",
        ["related"] = {
            "medical.distress",
        },
        ["source"] = "dialogue/medical_distress/medical_distress_call.json",
    },
    ["medical.distress.repeat"] = {
        ["domain"] = "medical_distress",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/MedicalDistress",
        },
        ["id"] = "medical.distress.repeat",
        ["kind"] = "dialogue",
        ["related"] = {
            "medical.distress",
        },
        ["source"] = "dialogue/medical_distress/medical_distress_repeat.json",
    },
    ["medical.distress.teammate"] = {
        ["domain"] = "medical_distress",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/MedicalDistress",
        },
        ["id"] = "medical.distress.teammate",
        ["kind"] = "dialogue",
        ["related"] = {
            "medical.distress",
        },
        ["source"] = "dialogue/medical_distress/medical_distress_teammate.json",
    },
    ["medical.distress.update"] = {
        ["domain"] = "medical_distress",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/MedicalDistress",
        },
        ["id"] = "medical.distress.update",
        ["kind"] = "dialogue",
        ["related"] = {
            "medical.distress",
        },
        ["source"] = "dialogue/medical_distress/medical_distress_update.json",
    },
}
