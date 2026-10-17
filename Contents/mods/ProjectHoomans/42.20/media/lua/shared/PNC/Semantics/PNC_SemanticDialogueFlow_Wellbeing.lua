return {
    id = "wellbeing",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "QUESTION", subject = "WELLBEING" },
    },
    initial = "await_player_status",
    nodes = {
        await_player_status = {
            responsePool = "semantic.question.wellbeing",
            accepts = {
                {
                    intent = "INFORM",
                    subject = "WELLBEING",
                    selfDirected = true,
                    target = "SELF",
                    stateType = "WELLBEING",
                },
            },
            slots = {
                status = {
                    type = "string",
                    owner = "wellbeing",
                    source = "slots.state.value",
                },
            },
            onMatch = "complete",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        complete = { terminal = true },
    },
}
