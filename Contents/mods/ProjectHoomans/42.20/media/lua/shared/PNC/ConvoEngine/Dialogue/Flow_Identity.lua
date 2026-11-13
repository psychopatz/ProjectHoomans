return {
    id = "identity",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "QUESTION", subject = "IDENTITY" },
    },
    initial = "await_player_name",
    nodes = {
        await_player_name = {
            responsePool = "semantic.question.identity",
            accepts = {
                {
                    intent = "INFORM",
                    subject = "IDENTITY",
                    identityClaim = true,
                },
            },
            slots = {
                name = {
                    type = "string",
                    owner = "identity",
                    source = "slots.identityClaim.name",
                },
            },
            onMatch = "complete",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        complete = { terminal = true },
    },
}
