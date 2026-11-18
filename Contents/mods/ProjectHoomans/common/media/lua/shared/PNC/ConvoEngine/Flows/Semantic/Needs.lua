-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "semantic",
        ["id"] = "needs",
        ["initial"] = "await_player_quantity",
        ["nodes"] = {
            ["await_player_quantity"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "QUANTITY",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["subject"] = "NEEDS",
                    },
                },
                ["onClarify"] = "clarification",
                ["onMatch"] = "quantity_answer",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["requiredSlots"] = {
                    "quantity",
                },
                ["responsePool"] = "semantic.question.needs.offer",
                ["sourceFactRefs"] = {
                    "npc.needs",
                },
            },
            ["clarification"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "QUANTITY",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["speechAct"] = "CLARIFY",
                        ["subject"] = "NEEDS",
                    },
                },
                ["onClarify"] = "clarification",
                ["onMatch"] = "quantity_answer",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["requiredSlots"] = {
                    "quantity",
                },
                ["responsePool"] = "semantic.question.needs.quantity",
                ["sourceFactRefs"] = {
                    "npc.needs",
                },
            },
            ["complete"] = {
                ["responsePool"] = "semantic.question.needs.proposal",
                ["terminal"] = true,
            },
            ["proposal_pending"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "ACCEPT",
                    },
                    {
                        ["intent"] = "AGREE",
                    },
                },
                ["onMatch"] = "complete",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["pendingKind"] = "PROPOSAL",
                ["requiredSlots"] = {
                    "confirmation",
                },
                ["responsePool"] = "semantic.question.needs.proposal",
                ["sourceFactRefs"] = {
                    "npc.needs",
                },
            },
            ["quantity_answer"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "PROMISE",
                        ["speechAct"] = "PROMISE",
                        ["subject"] = "NEEDS",
                    },
                },
                ["onMatch"] = "proposal_pending",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["pendingKind"] = "PROPOSAL",
                ["requiredSlots"] = {
                    "offer",
                },
                ["responsePool"] = "semantic.question.needs.quantity",
                ["sourceFactRefs"] = {
                    "npc.needs",
                },
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "QUESTION",
                ["subject"] = "NEEDS",
            },
        },
        ["version"] = 1,
    },
}
