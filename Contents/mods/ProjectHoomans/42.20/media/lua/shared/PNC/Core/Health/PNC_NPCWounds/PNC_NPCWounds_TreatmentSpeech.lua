-- Material concepts authorized by the selected wound and the speaker's knowledge.
local Speech = {}
local dressing = {
    ["Base.Bandage"] = "BANDAGE",
    ["Base.BandageDirty"] = "BANDAGE",
    ["Base.AlcoholBandage"] = "STERILE_BANDAGE",
    ["Base.Bandaid"] = "ADHESIVE_BANDAGE",
    ["Base.RippedSheets"] = "RAG",
    ["Base.RippedSheetsDirty"] = "RAG",
    ["Base.AlcoholRippedSheets"] = "STERILE_RAG",
    ["Base.DenimStrips"] = "DENIM_STRIP",
    ["Base.DenimStripsDirty"] = "DENIM_STRIP",
    ["Base.LeatherStrips"] = "LEATHER_STRIP",
    ["Base.LeatherStripsDirty"] = "LEATHER_STRIP",
}
local splint = {
    ["Base.Splint"] = "CRAFTED_SPLINT",
    ["Base.Plank"] = "PLANK_SPLINT",
    ["Base.TreeBranch2"] = "BRANCH_SPLINT",
    ["Base.TreeBranch"] = "BRANCH_SPLINT",
    ["Base.WoodenStick2"] = "STICK_SPLINT",
    ["Base.WoodenStick"] = "STICK_SPLINT",
}
local prefix = "COMBAT_TREATMENT_"

local function dressingConcept(wound, observed)
    if wound.bandaged ~= true or wound.virtualDressing then return nil end
    local item = (wound.bandageDirty and wound.spentBandageType) or wound.bandageType
    local material = dressing[item]
    if observed or wound.bandageDirty or wound.sterileDressing ~= true then
        if material == "STERILE_BANDAGE" then material = "BANDAGE" end
        if material == "STERILE_RAG" then material = "RAG" end
    end
    return material and prefix .. material
end

local function splintConcept(wound)
    if wound.splinted ~= true then return nil end
    local material = splint[wound.splintType or wound.splintItem]
    return material and prefix .. material
end

function Speech.Describe(wound, observed)
    if type(wound) ~= "table" then return nil end
    local dressingMaterial = dressingConcept(wound, observed)
    if dressingMaterial and wound.bandageDirty then return dressingMaterial, "bandaged", true end
    local splintMaterial = splintConcept(wound)
    if splintMaterial then return splintMaterial, "splinted" end
    if dressingMaterial then return dressingMaterial, "bandaged" end
end

function Speech.IsMaterialClaim(claim)
    return type(claim) == "string" and string.sub(claim, 1, #prefix) == prefix
end

function Speech.Matches(wound, claim, observed)
    return claim == dressingConcept(wound, observed) or claim == splintConcept(wound)
end

return Speech
