local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "bandage",
    category = "medical",
    order = 10,
    mode = "THRESHOLD_TARGET",
    selector = "BANDAGE",
    resourceKind = "MEDICAL",
    treatment = "BANDAGE",
    measure = "COUNT",
    priority = 30,
    defaults = { enabled = true, refillBelow = 1, target = 3 },
    ui = {
        labelKey = "UI_PNC_Provision_Bandages",
        descriptionKey = "UI_PNC_Provision_Bandages_Description",
        measureKey = "UI_PNC_Provision_UsableCount",
        fields = {
            { id = "refillBelow", type = "number", min = 0,
                max = 50, step = 1,
                labelKey = "UI_PNC_Provision_RefillBelow" },
            { id = "target", type = "number", min = 0,
                max = 50, step = 1,
                labelKey = "UI_PNC_Provision_TargetCarry" },
        },
    },
})

return Registry
