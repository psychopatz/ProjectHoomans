-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "offer",
        ["id"] = "semantic.offer",
        ["variants"] = {
            {
                ["fallback"] = "That would help a lot. Could I have some?",
                ["id"] = "semantic.offer.dataset.hungry_share",
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_share",
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["fallback"] = "I'd appreciate a bite. Would you share?",
                ["id"] = "semantic.offer.dataset.hungry_appreciate",
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_appreciate",
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
        },
    },
}
