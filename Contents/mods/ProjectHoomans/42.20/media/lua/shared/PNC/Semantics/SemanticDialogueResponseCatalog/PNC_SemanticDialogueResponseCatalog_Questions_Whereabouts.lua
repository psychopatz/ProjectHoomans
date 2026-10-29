-- Generic community-role whereabouts response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local function register(id, fallback, extra)
    local variant = {
        id = id .. ".default",
        templateID = id,
        fallback = fallback,
        dialogueAct = "FACT_ANSWER",
        topic = "COMMUNITY_ROLE_WHEREABOUTS",
        uncertainty = "known",
        tone = "direct",
    }
    for key, value in pairs(extra or {}) do variant[key] = value end
    Catalog.Register(id, { variants = { variant } })
end

register(
    "semantic.question.community_role_whereabouts.unknown",
    "I don't know where our %15 is.",
    { uncertainty = "unknown", tone = "cautious" }
)
register(
    "semantic.question.community_role_whereabouts.home",
    "Our %15 is here."
)
register(
    "semantic.question.community_role_whereabouts.preparing",
    "Our %15 is preparing to leave."
)
register(
    "semantic.question.community_role_whereabouts.away",
    "Our %15 is away right now."
)
register(
    "semantic.question.community_role_whereabouts.returning",
    "Our %15 is on the way home."
)
register(
    "semantic.question.community_role_whereabouts.visiting",
    "Our %15 is at %16, %17 of here."
)
register(
    "semantic.question.community_role_whereabouts.visiting_eta",
    "Our %15 is at %16, %17 of here. They should be back %18."
)

return true
