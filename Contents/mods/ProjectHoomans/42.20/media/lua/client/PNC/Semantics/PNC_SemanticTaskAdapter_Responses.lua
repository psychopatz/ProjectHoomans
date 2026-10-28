-- Default response pools for parameterized semantic task capabilities.
-- FETCH and WAIT_AT keep their specialized pools with their metadata; these
-- pools cover the shared item-action capability family.

local TASK_RESPONSE_POOLS = {
    GIVE = {
        admitted = {
            templateID = "semantic.task.give.admitted",
        },
        active = {
            templateID = "semantic.task.give.active",
        },
        completed = {
            templateID = "semantic.task.give.completed",
        },
        rejected = {
            templateID = "semantic.task.give.rejected",
        },
        failed = {
            templateID = "semantic.task.give.failed",
        },
    },
    EAT = {
        admitted = {
            templateID = "semantic.task.eat.admitted",
        },
        active = {
            templateID = "semantic.task.eat.active",
        },
        completed = {
            templateID = "semantic.task.eat.completed",
        },
        rejected = {
            templateID = "semantic.task.eat.rejected",
        },
        failed = {
            templateID = "semantic.task.eat.failed",
        },
    },
    DRINK = {
        admitted = {
            templateID = "semantic.task.drink.admitted",
        },
        active = {
            templateID = "semantic.task.drink.active",
        },
        completed = {
            templateID = "semantic.task.drink.completed",
        },
        rejected = {
            templateID = "semantic.task.drink.rejected",
        },
        failed = {
            templateID = "semantic.task.drink.failed",
        },
    },
    REFILL = {
        admitted = {
            templateID = "semantic.task.refill.admitted",
        },
        active = {
            templateID = "semantic.task.refill.active",
        },
        completed = {
            templateID = "semantic.task.refill.completed",
        },
        rejected = {
            templateID = "semantic.task.refill.rejected",
        },
        failed = {
            templateID = "semantic.task.refill.failed",
        },
    },
    CONSUME = {
        admitted = {
            templateID = "semantic.task.consume.admitted",
        },
        active = {
            templateID = "semantic.task.consume.active",
        },
        completed = {
            templateID = "semantic.task.consume.completed",
        },
        rejected = {
            templateID = "semantic.task.consume.rejected",
        },
        failed = {
            templateID = "semantic.task.consume.failed",
        },
    },
}

return TASK_RESPONSE_POOLS

