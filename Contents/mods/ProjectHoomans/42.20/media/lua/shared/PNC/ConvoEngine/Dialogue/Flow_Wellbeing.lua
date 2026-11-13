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
                -- A contextual follow-up question is still an answer to the
                -- bounded wellbeing exchange. Let the flow retire cleanly so
                -- the normal question resolver can choose its fact-specific
                -- follow-up response instead of restarting this flow.
                {
                    intent = "QUESTION",
                    subject = "WELLBEING",
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
