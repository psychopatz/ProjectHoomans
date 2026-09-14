-- Semantic labels for command feedback.  Provider text never controls these
-- labels; command identity is mapped through this bounded catalog.
PNC = PNC or {}
PNC.NameplateToolFeedbackCatalog = PNC.NameplateToolFeedbackCatalog or {
    follow = {
        key = "UI_PNC_ToolFeedback_FollowMode",
        fallback = "Follow mode",
    },
    stay = {
        key = "UI_PNC_ToolFeedback_GuardMode",
        fallback = "Guard mode",
    },
    camp = {
        key = "UI_PNC_ToolFeedback_CampMode",
        fallback = "Camp mode",
    },
    return_home = {
        key = "UI_PNC_ToolFeedback_ReturnHome",
        fallback = "Returning home",
    },
    attack_auto = {
        key = "UI_PNC_ToolFeedback_AttackMode",
        fallback = "Attack mode",
    },
    attack_melee = {
        key = "UI_PNC_ToolFeedback_AttackMelee",
        fallback = "Melee attack mode",
    },
    attack_ranged = {
        key = "UI_PNC_ToolFeedback_AttackRanged",
        fallback = "Ranged attack mode",
    },
    attack_none = {
        key = "UI_PNC_ToolFeedback_AttackDisabled",
        fallback = "Attack disabled",
    },
}

return PNC.NameplateToolFeedbackCatalog
