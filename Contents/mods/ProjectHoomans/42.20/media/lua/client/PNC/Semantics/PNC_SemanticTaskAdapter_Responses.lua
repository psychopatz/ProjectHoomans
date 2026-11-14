-- Default response pools for parameterized semantic task capabilities.
-- FETCH and WAIT_AT keep their specialized pools with their metadata; these
-- pools cover the shared item-action capability family.

local TASK_RESPONSE_POOLS = {
    GIVE = {
        admitted = {
            templateID = "task.give.admitted",
        },
        active = {
            templateID = "task.give.active",
        },
        completed = {
            templateID = "task.give.completed",
        },
        rejected = {
            templateID = "task.give.rejected",
        },
        failed = {
            templateID = "task.give.failed",
        },
    },
    EAT = {
        admitted = {
            templateID = "task.eat.admitted",
        },
        active = {
            templateID = "task.eat.active",
        },
        completed = {
            templateID = "task.eat.completed",
        },
        rejected = {
            templateID = "task.eat.rejected",
        },
        failed = {
            templateID = "task.eat.failed",
        },
    },
    DRINK = {
        admitted = {
            templateID = "task.drink.admitted",
        },
        active = {
            templateID = "task.drink.active",
        },
        completed = {
            templateID = "task.drink.completed",
        },
        rejected = {
            templateID = "task.drink.rejected",
        },
        failed = {
            templateID = "task.drink.failed",
        },
    },
    REFILL = {
        admitted = {
            templateID = "task.refill.admitted",
        },
        active = {
            templateID = "task.refill.active",
        },
        completed = {
            templateID = "task.refill.completed",
        },
        rejected = {
            templateID = "task.refill.rejected",
        },
        failed = {
            templateID = "task.refill.failed",
        },
    },
    CONSUME = {
        admitted = {
            templateID = "task.consume.admitted",
        },
        active = {
            templateID = "task.consume.active",
        },
        completed = {
            templateID = "task.consume.completed",
        },
        rejected = {
            templateID = "task.consume.rejected",
        },
        failed = {
            templateID = "task.consume.failed",
        },
    },
}

return TASK_RESPONSE_POOLS

