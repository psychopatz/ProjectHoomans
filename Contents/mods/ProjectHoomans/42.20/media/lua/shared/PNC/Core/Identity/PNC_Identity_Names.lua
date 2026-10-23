PNC = PNC or {}
PNC.IdentityNames = PNC.IdentityNames or {}

local Names = PNC.IdentityNames
local Identity = PNC.Identity
local DeterministicContent = PNC.DeterministicContent
    or PsychopatzCore and PsychopatzCore.DeterministicContent
if type(DeterministicContent) ~= "table" then
    local ok, loaded = pcall(require,
        "PsychopatzCore/Content/PsychopatzDeterministicContent"
    )
    if ok and type(loaded) == "table" then
        DeterministicContent = loaded
    end
end
PNC.DeterministicContent = DeterministicContent

local MaleFirst = {
    "Adam", "Aaron", "Ben", "Caleb", "Derek", "Eli", "Felix", "Grant", "Harvey", "Isaac",
    "Jonah", "Liam", "Marcus", "Noah", "Owen", "Peter", "Quinn", "Rory", "Samuel", "Victor",
}

local FemaleFirst = {
    "Alice", "Beth", "Cara", "Diana", "Elise", "Faith", "Grace", "Hannah", "Ivy", "Julia",
    "Kara", "Lena", "Maya", "Nina", "Olive", "Paige", "Ruby", "Sara", "Tessa", "Wren",
}

local Surnames = {
    "Bennett", "Carter", "Dalton", "Ellis", "Foster", "Griffin", "Hayes", "Irwin", "Keller", "Lang",
    "Morris", "Nolan", "Owens", "Parker", "Quincy", "Reed", "Sawyer", "Turner", "Vance", "Walker",
}

function Names.CatalogInfo()
    local catalog = DeterministicContent
        and type(DeterministicContent.NativeNameCatalog) == "function"
        and DeterministicContent.NativeNameCatalog() or nil
    if not catalog then
        catalog = {
            femaleFirst = FemaleFirst,
            maleFirst = MaleFirst,
            surnames = Surnames,
            source = "project_hoomans_fallback",
        }
    end
    if DeterministicContent
        and type(DeterministicContent.NameCatalogInfo) == "function"
    then
        return DeterministicContent.NameCatalogInfo(catalog)
    end
    return {
        source = catalog.source,
        femaleFirstCount = #catalog.femaleFirst,
        maleFirstCount = #catalog.maleFirst,
        surnameCount = #catalog.surnames,
    }
end

function Names.Generate(seed, isFemale, archetypeID, options)
    options = type(options) == "table" and options or {}
    local catalog = DeterministicContent
        and type(DeterministicContent.NativeNameCatalog) == "function"
        and DeterministicContent.NativeNameCatalog() or {
            femaleFirst = FemaleFirst,
            maleFirst = MaleFirst,
            surnames = Surnames,
            source = "project_hoomans_fallback",
        }
    if DeterministicContent
        and type(DeterministicContent.GenerateName) == "function"
    then
        local saveSeed = options.saveSeed
            or DeterministicContent.ResolveSaveSeed(options)
        return DeterministicContent.GenerateName({
            saveSeed = saveSeed,
            identitySeed = seed,
            namespace = options.namespace or "projecthoomans.identity.name",
            version = options.version,
            isFemale = isFemale == true,
            archetypeID = archetypeID or "General",
            firstName = options.firstName or options.forename,
            surname = options.surname or options.lastName,
        }, catalog)
    end
    local firstPool = isFemale and FemaleFirst or MaleFirst
    local first = options.firstName or options.forename
        or firstPool[Identity.Index(
            seed,
            "name:first:" .. tostring(archetypeID or "General"),
            #firstPool
        )]
    local last = options.surname or options.lastName
        or Surnames[Identity.Index(seed, "name:last", #Surnames)]
    return tostring(first or "Alex") .. " " .. tostring(last or "Walker")
end

return Names
