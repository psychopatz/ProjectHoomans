-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "accept",
        ["id"] = "semantic.accept",
        ["variants"] = {
            {
                ["fallback"] = "Okay, I'll get started.",
                ["id"] = "semantic.accept.dataset.pending_started",
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_started",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["fallback"] = "All right. I can take care of that.",
                ["id"] = "semantic.accept.dataset.pending_care",
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_care",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
}
