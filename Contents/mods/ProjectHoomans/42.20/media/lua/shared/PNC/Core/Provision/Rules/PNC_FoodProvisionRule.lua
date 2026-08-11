local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "food",
    category = "survival",
    order = 10,
    mode = "THRESHOLD_TARGET",
    selector = "FOOD",
    measure = "HUNGER_UTILITY",
    priority = 35,
    defaults = { enabled = true, refillBelow = 0.30, target = 0.80 },
    ui = {
        labelKey = "UI_PNC_Provision_Food",
        descriptionKey = "UI_PNC_Provision_Food_Description",
        measureKey = "UI_PNC_Provision_HungerUtility",
        fields = {
            { id = "refillBelow", type = "number", min = 0,
                max = 5, step = 0.05,
                labelKey = "UI_PNC_Provision_RefillBelow" },
            { id = "target", type = "number", min = 0,
                max = 5, step = 0.05,
                labelKey = "UI_PNC_Provision_TargetCarry" },
        },
    },
})

return Registry
