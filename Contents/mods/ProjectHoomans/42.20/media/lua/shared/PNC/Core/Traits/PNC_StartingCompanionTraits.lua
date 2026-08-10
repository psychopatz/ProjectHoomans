if not PsychopatzCore or not PsychopatzCore.Traits then
    require "PsychopatzCore/Traits/PsychopatzTraitRegistry"
end

PNC = PNC or {}
PNC.StartingCompanionTraits = PNC.StartingCompanionTraits or {}

local StartingTraits = PNC.StartingCompanionTraits

StartingTraits.OWNER = "ProjectHoomans.StartingCompanions"
StartingTraits.IDS = {
    BROTHER = "PNC_HasBrother",
    SISTER = "PNC_HasSister",
    LOVER = "PNC_HasLover",
    MOM = "PNC_HasMom",
    DAD = "PNC_HasDad",
    FRIEND = "PNC_HasFriend",
}

local T = StartingTraits.IDS
StartingTraits.DEFINITIONS = {
    { id = T.BROTHER, resource = "pnc:pnc_hasbrother", cost = 2,
        relationshipKind = "brother", sex = "male", sharesSurname = true,
        uiName = "UI_PNC_Trait_HasBrother",
        uiDescription = "UI_PNC_Trait_HasBrother_Description" },
    { id = T.SISTER, resource = "pnc:pnc_hassister", cost = 2,
        relationshipKind = "sister", sex = "female", sharesSurname = true,
        uiName = "UI_PNC_Trait_HasSister",
        uiDescription = "UI_PNC_Trait_HasSister_Description" },
    { id = T.LOVER, resource = "pnc:pnc_haslover", cost = 2,
        relationshipKind = "lover", sex = "orientation", sharesSurname = true,
        uiName = "UI_PNC_Trait_HasLover",
        uiDescription = "UI_PNC_Trait_HasLover_Description" },
    { id = T.MOM, resource = "pnc:pnc_hasmom", cost = 2,
        relationshipKind = "mother", sex = "female", sharesSurname = true,
        uiName = "UI_PNC_Trait_HasMom",
        uiDescription = "UI_PNC_Trait_HasMom_Description" },
    { id = T.DAD, resource = "pnc:pnc_hasdad", cost = 2,
        relationshipKind = "father", sex = "male", sharesSurname = true,
        uiName = "UI_PNC_Trait_HasDad",
        uiDescription = "UI_PNC_Trait_HasDad_Description" },
    { id = T.FRIEND, resource = "pnc:pnc_hasfriend", cost = 2,
        relationshipKind = "friend", sex = "random", sharesSurname = false,
        uiName = "UI_PNC_Trait_HasFriend",
        uiDescription = "UI_PNC_Trait_HasFriend_Description" },
}

StartingTraits.EXCLUSIONS = {}

local byID = {}
local index
for index = 1, #StartingTraits.DEFINITIONS do
    byID[StartingTraits.DEFINITIONS[index].id] =
        StartingTraits.DEFINITIONS[index]
end

function StartingTraits.GetDefinition(id)
    return byID[id]
end

function StartingTraits.ResolveSelections(player)
    local selected, reason = PsychopatzCore.Traits.ReadPlayer(
        player, StartingTraits.OWNER
    )
    if not selected then return nil, reason end
    local output = {}
    for index = 1, #StartingTraits.DEFINITIONS do
        local spec = StartingTraits.DEFINITIONS[index]
        if selected[spec.id] then output[#output + 1] = spec end
    end
    return output, #output > 0 and "selected" or "none"
end

-- Compatibility helper for integrations that only need the first selection.
function StartingTraits.ResolveSelected(player)
    local selections, reason = StartingTraits.ResolveSelections(player)
    if not selections then return nil, reason end
    return selections[1] or false, reason
end

function StartingTraits.ResolveCompanionFemale(
    spec, playerFemale, orientation, randomFemale
)
    if not spec then return nil end
    if spec.sex == "female" then return true end
    if spec.sex == "male" then return false end
    if spec.sex == "random" then return randomFemale == true end
    orientation = orientation or "straight"
    if orientation == "gay" then return playerFemale == true end
    if orientation == "bisexual" then return randomFemale == true end
    return playerFemale ~= true
end

PsychopatzCore.Traits.RegisterCatalog(
    StartingTraits.OWNER,
    StartingTraits.DEFINITIONS,
    StartingTraits.EXCLUSIONS
)

return StartingTraits
