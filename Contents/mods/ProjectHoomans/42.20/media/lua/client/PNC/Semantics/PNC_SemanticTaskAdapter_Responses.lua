-- Default response pools for parameterized semantic task capabilities.
-- FETCH and WAIT_AT keep their specialized pools with their metadata; these
-- pools cover the shared item-action capability family.

local TASK_RESPONSE_POOLS = {
    GIVE = {
        admitted = {
        },
        active = {
        },
        completed = {
        },
        rejected = {
        },
        failed = {
        },
    },
    EAT = {
        admitted = {
        },
        active = {
        },
        completed = {
        },
        rejected = {
        },
        failed = {
        },
    },
    DRINK = {
        admitted = {
        },
        active = {
        },
        completed = {
        },
        rejected = {
        },
        failed = {
        },
    },
    REFILL = {
        admitted = {
        },
        active = {
        },
        completed = {
        },
        rejected = {
        },
        failed = {
        },
    },
    CONSUME = {
        admitted = {
        },
        active = {
        },
        completed = {
        },
        rejected = {
        },
        failed = {
        },
    },
}

return TASK_RESPONSE_POOLS

