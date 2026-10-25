-- Health, personal-history, and conversational context concepts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
if type(registerConcept) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end

function Internal.RegisterContextConcepts()
    registerConcept("BITTEN", { "bitten", "got bitten", "was bitten" })
    registerConcept("BITE", { "bite", "bites", "biting" })
    registerConcept("RESIDENCE", {
        "house", "residence", "settlement", "where i live",
    })
    registerConcept("HEALTH_STATUS", {
        "health", "hurt", "injured", "wounded", "wounds",
    })
    registerConcept("KNOW", { "know", "knows", "aware" })
    registerConcept("FORMER_JOB", {
        "job", "work", "occupation", "profession", "career",
    }, 4)
    registerConcept("HOMETOWN", {
        "hometown", "home town", "where i grew up", "where i'm from",
    }, 4)
    registerConcept("EDUCATION", {
        "education", "school", "college", "studies", "studied",
    }, 4)
    registerConcept("HOBBY", {
        "hobby", "hobbies", "pastime", "pastimes", "free time",
    }, 4)
    registerConcept("FAMILY", {
        "family", "relatives", "parents", "siblings",
    }, 4)
    registerConcept("PERSONAL_VALUE", {
        "values", "value", "beliefs", "belief", "principles",
    }, 4)
    registerConcept("SURVIVAL_ORIGIN", {
        "survival", "surviving", "how i survived",
    }, 4)
    registerConcept("PERSONAL_FEAR", {
        "afraid", "fear", "fears", "scared", "frightened",
    }, 4)
    registerConcept("PERSONAL_TRAGEDY", {
        "tragedy", "loss", "what happened", "what i went through",
        "what did you go through",
    }, 4)
    registerConcept("BIRTHDAY", {
        "birthday", "birth date", "date of birth",
    }, 4)
end

return Internal
