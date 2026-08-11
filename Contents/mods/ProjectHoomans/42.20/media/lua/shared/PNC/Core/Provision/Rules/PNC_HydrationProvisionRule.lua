local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "hydration",
    category = "survival",
    order = 20,
    mode = "THRESHOLD_TARGET",
    selector = "HYDRATION",
    measure = "THIRST_UTILITY",
    priority = 40,
    defaults = { enabled = true, refillBelow = 0.25, target = 0.70 },
    ui = {
        labelKey = "UI_PNC_Provision_Hydration",
        descriptionKey = "UI_PNC_Provision_Hydration_Description",
        measureKey = "UI_PNC_Provision_ThirstUtility",
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
