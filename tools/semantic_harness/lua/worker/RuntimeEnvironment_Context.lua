-- Scenario-backed state and semantic engine reset for the runtime seam.

local Context = {}

local function projectSocialProfiles(context, playerData, npcData)
    local playerTraits = playerData.traits or playerData.socialTraits or {}
    local npcTraits = npcData.traits or {}
    local playerProfile
    local playerConflicts
    local playerFingerprint
    local npcProfile
    local personalityMode
    local personalitySource
    local identitySeed = npcData.identitySeed
        or npcData.identity and npcData.identity.seed
        or npcData.npcID
    local archetypeID = npcData.archetype or npcData.archetypeID or "General"

    local sourceKind = context.Runtime.sourceMetadata
        and context.Runtime.sourceMetadata.sourceKind or "FIXTURE"
    if sourceKind == "SAVE"
        and type(playerData.socialProfile) == "table"
        and PNC and PNC.SocialProfileTypes
        and type(PNC.SocialProfileTypes.NormalizePlayerSocialProfile)
            == "function"
    then
        playerProfile = PNC.SocialProfileTypes.NormalizePlayerSocialProfile(
            playerData.socialProfile
        )
        playerConflicts = {}
        playerFingerprint = playerProfile.sourceFingerprint or "saved"
    elseif PNC and PNC.SocialTraits
        and type(PNC.SocialTraits.ResolveTraits) == "function"
    then
        playerProfile, playerConflicts, playerFingerprint =
            PNC.SocialTraits.ResolveTraits(playerTraits)
    else
        playerProfile = {}
        playerConflicts = {}
        playerFingerprint = ""
    end

    personalityMode = tostring(npcData.personalityMode or "")
    personalitySource = npcData.personalityOverride == true
        or personalityMode == "override"
    -- Scenarios written before the generated-personality mode existed remain
    -- readable as explicit legacy fixtures. New scenarios omit personality
    -- values and therefore use the generated production path by default.
    if not personalitySource and personalityMode == ""
        and type(npcData.personality) == "table"
    then
        personalitySource = true
        personalityMode = "legacy_override"
    end

    if personalitySource and PNC and PNC.SocialProfileTypes
        and type(PNC.SocialProfileTypes.NormalizeNPCPersonality) == "function"
    then
        -- An explicit/manual profile is authoritative. Normalize it through
        -- the production schema so numeric dimensions are not replaced by a
        -- freshly generated profile merely because traits are present.
        npcProfile = PNC.SocialProfileTypes.NormalizeNPCPersonality(
            npcData.personality,
            identitySeed,
            archetypeID,
            npcData.personality,
            { npcTraits = npcTraits }
        )
    elseif PNC and PNC.SocialProfileGenerator
        and type(PNC.SocialProfileGenerator.Generate) == "function"
    then
        npcProfile = PNC.SocialProfileGenerator.Generate(
            identitySeed,
            archetypeID,
            nil,
            { npcTraits = npcTraits }
        )
    else
        npcProfile = npcData.personality or {}
    end

    context.playerSocialProfile = playerProfile
    context.playerTraitConflicts = playerConflicts
    context.playerTraitFingerprint = playerFingerprint
    context.npcGeneratedPersonality = npcProfile
    context.npcPersonality = npcProfile
    context.npcPersonalityMode = personalitySource
        and (personalityMode ~= "" and personalityMode or "override")
        or "generated"
end

function Context.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local playerData = scenario.player or {}
    local npcData = scenario.npc or {}
    local world = scenario.world or {}
    local runtime = scenario.runtime or {}
    context.scenario = scenario
    context.playerData = playerData
    context.npcData = npcData
    context.world = world
    context.runtime = runtime
    context.semanticFactValues = {}
    projectSocialProfiles(context, playerData, npcData)
    ModData = {
        get = function(key)
            return Runtime.modData[tostring(key or "")]
        end,
        getOrCreate = function(key)
            key = tostring(key or "")
            Runtime.modData[key] = Runtime.modData[key] or {}
            return Runtime.modData[key]
        end,
    }
    if world.zombieKills ~= nil then
        context.semanticFactValues["player.stats.zombie_kills"] = {
            status = "known",
            value = Values.number(world.zombieKills, 0),
            type = "number",
            unit = "count",
            authority = "harness",
        }
    end
    if world.weatherTransition ~= nil then
        context.semanticFactValues["world.weather.transition"] = {
            status = "known",
            value = tostring(world.weatherTransition),
            type = "string",
            unit = "transition",
            authority = "harness",
        }
    end
    if PNC.Semantics and PNC.Semantics.WorldContext
        and type(PNC.Semantics.WorldContext.Clear) == "function"
    then
        PNC.Semantics.WorldContext.Clear()
    end
    if PNC.Semantics and PNC.Semantics.EngineEvents
        and type(PNC.Semantics.EngineEvents.Reset) == "function"
    then
        PNC.Semantics.EngineEvents.Reset()
    end
end

return Context
