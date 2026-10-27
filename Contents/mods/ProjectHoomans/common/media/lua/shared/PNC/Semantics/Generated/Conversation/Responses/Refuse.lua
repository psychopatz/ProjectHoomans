-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "refuse",
        ["id"] = "semantic.refuse",
        ["variants"] = {
            {
                ["fallback"] = "I can't take that on right now.",
                ["id"] = "semantic.refuse.dataset.pending_unavailable",
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_unavailable",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["fallback"] = "Not this time. I have enough to manage.",
                ["id"] = "semantic.refuse.dataset.pending_enough",
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_enough",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
}
