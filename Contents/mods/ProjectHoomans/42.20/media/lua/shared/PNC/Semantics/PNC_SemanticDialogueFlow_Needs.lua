return {
    id = "needs",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "QUESTION", subject = "NEEDS" },
    },
    initial = "await_player_quantity",
    nodes = {
        await_player_quantity = {
            responsePool = "semantic.question.needs.offer",
            accepts = {
                {
                    intent = "QUESTION",
                    subject = "QUANTITY",
                },
            },
            requiredSlots = { "quantity" },
            sourceFactRefs = { "npc.needs" },
            onMatch = "quantity_answer",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        quantity_answer = {
            responsePool = "semantic.question.needs.quantity",
            accepts = {
                {
                    intent = "PROMISE",
                    speechAct = "PROMISE",
                    subject = "NEEDS",
                },
            },
            requiredSlots = { "offer" },
            sourceFactRefs = { "npc.needs" },
            pendingKind = "PROPOSAL",
            onMatch = "proposal_pending",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        proposal_pending = {
            responsePool = "semantic.question.needs.proposal",
            accepts = {
                { intent = "ACCEPT" },
                { intent = "AGREE" },
            },
            requiredSlots = { "confirmation" },
            sourceFactRefs = { "npc.needs" },
            pendingKind = "PROPOSAL",
            -- Keep an explicit acceptance in the proposal state until a
            -- future authority-backed confirmation path is implemented.
            onMatch = "proposal_pending",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
    },
}
