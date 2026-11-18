-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "semantic",
        ["id"] = "identity",
        ["initial"] = "await_player_name",
        ["nodes"] = {
            ["await_player_name"] = {
                ["accepts"] = {
                    {
                        ["identityClaim"] = true,
                        ["intent"] = "INFORM",
                        ["subject"] = "IDENTITY",
                    },
                },
                ["onMatch"] = "complete",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.question.identity",
                ["slots"] = {
                    ["name"] = {
                        ["owner"] = "identity",
                        ["source"] = "slots.identityClaim.name",
                        ["type"] = "string",
                    },
                },
            },
            ["complete"] = {
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "QUESTION",
                ["subject"] = "IDENTITY",
            },
        },
        ["version"] = 1,
    },
}
