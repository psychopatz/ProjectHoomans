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
            terminal = true,
        },
    },
}
