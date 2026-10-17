-- A small modular social exchange. The flow owns the bounded follow-up;
-- central intent policy remains responsible for ordinary standalone replies.
return {
    id = "greeting",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "GREET", speechAct = "GREET" },
    },
    initial = "await_thanks",
    nodes = {
        await_thanks = {
            responsePool = "semantic.flow.greeting.opening",
            accepts = {
                { intent = "THANK", speechAct = "THANK" },
            },
            onMatch = "complete",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        complete = {
            terminal = true,
            responsePool = "semantic.flow.greeting.followup",
        },
    },
}
