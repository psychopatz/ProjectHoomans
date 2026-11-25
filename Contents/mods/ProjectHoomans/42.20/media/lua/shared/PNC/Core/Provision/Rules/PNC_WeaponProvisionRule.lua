local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "weapon_upgrade",
    category = "loadout",
    order = 40,
    mode = "UPGRADE_BEST",
    selector = "WEAPON",
    resourceKind = "WEAPON",
    measure = "SCORE",
    priority = 20,
    defaults = { enabled = false, minUpgradeDelta = 1.5 },
    ui = {
        labelKey = "UI_PNC_Provision_WeaponUpgrade",
        descriptionKey = "UI_PNC_Provision_WeaponUpgrade_Description",
        measureKey = "UI_PNC_Provision_UpgradeDelta",
        fields = {
            { id = "minUpgradeDelta", type = "number", min = 0.5,
                max = 50, step = 0.5,
                labelKey = "UI_PNC_Provision_MinUpgradeDelta" },
        },
    },
})

return Registry
