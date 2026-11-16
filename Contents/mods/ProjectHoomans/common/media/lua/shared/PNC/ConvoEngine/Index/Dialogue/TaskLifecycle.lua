-- Generated Conversation discovery index; do not edit by hand.
return {
    ["gift"] = {
        ["dependents"] = {
            "needs.member.support",
            "needs.neutral.support",
            "needs.special.support",
        },
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/GiftToTaskDrink",
        },
        ["id"] = "gift",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/gift.json",
    },
    ["task.consume"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/GiftToTaskDrink",
        },
        ["id"] = "task.consume",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_consume.json",
    },
    ["task.drink"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/GiftToTaskDrink",
        },
        ["id"] = "task.drink",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_drink.json",
    },
    ["task.eat"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/EatToGive",
        },
        ["id"] = "task.eat",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_eat.json",
    },
    ["task.fetch"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/EatToGive",
        },
        ["id"] = "task.fetch",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_fetch.json",
    },
    ["task.give"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/EatToGive",
        },
        ["id"] = "task.give",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_give.json",
    },
    ["task.refill"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/RefillToWaitAt",
        },
        ["id"] = "task.refill",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_refill.json",
    },
    ["task.wait_at"] = {
        ["domain"] = "task_lifecycle",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/TaskLifecycle/RefillToWaitAt",
        },
        ["id"] = "task.wait_at",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/task_lifecycle/task_wait_at.json",
    },
}
