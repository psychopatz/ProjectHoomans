-- Restore the PNC combat bump graph from Bandits without sharing Bandits'
-- unnamespaced BumpType values. Run from the ProjectHoomans repository root:
--   lua tools/restore_pnc_bandits_combat_xml.lua [bandits_bumped_dir]

local sourceDir = arg[1]
    or "/home/psychopatz/.steam/debian-installation/steamapps/common/ProjectZomboid/projectzomboid/steamapps/workshop/content/108600/3268487204/mods/Bandits/common/media/AnimSets/zombie/bumped"
local targetDir =
    "Contents/mods/ProjectHoomans/common/media/AnimSets/zombie/bumped"

local sourceFiles = {
    "ZSAttack1H1.xml",
    "ZSAttack1H1Bwd.xml",
    "ZSAttack1H2.xml",
    "ZSAttack1H2Bwd.xml",
    "ZSAttack1H3.xml",
    "ZSAttack1H3Bwd.xml",
    "ZSAttack1H4.xml",
    "ZSAttack1H5.xml",
    "ZSAttack2H1.xml",
    "ZSAttack2H1Bwd.xml",
    "ZSAttack2H2.xml",
    "ZSAttack2H2Bwd.xml",
    "ZSAttack2H3.xml",
    "ZSAttack2H3Bwd.xml",
    "ZSAttack2H4.xml",
    "ZSAttack2HFloor.xml",
    "ZSAttack2HHeavy1.xml",
    "ZSAttack2HHeavy2.xml",
    "ZSAttack2HStamp.xml",
    "ZSAttackBareHands1.xml",
    "ZSAttackBareHands2.xml",
    "ZSAttackBareHands2Bwd.xml",
    "ZSAttackBareHands3.xml",
    "ZSAttackBareHands4.xml",
    "ZSAttackBareHands4Bwd.xml",
    "ZSAttackBareHands5.xml",
    "ZSAttackBareHands6.xml",
    "ZSAttackChainsaw1.xml",
    "ZSAttackChainsaw2.xml",
    "ZSAttackPistol.xml",
    "ZSAttackRifle.xml",
    "ZSAttackS1.xml",
    "ZSAttackS1Bwd.xml",
    "ZSAttackS2.xml",
    "ZSAttackS2Bwd.xml",
    "ZSFrontKick.xml",
    "ZSHighKick.xml",
    "ZSKnife.xml",
    "ZSKnifeBwd.xml",
    "ZSKnifeMiss.xml",
    "ZSShove.xml",
    "ZSShove2handed.xml",
    "ZSShoveHandgun.xml",
    "ZSShoveRifle.xml",
}

local function readAll(path)
    local handle = assert(io.open(path, "rb"))
    local content = assert(handle:read("*a"))
    handle:close()
    return content
end

local function writeAll(path, content)
    local handle = assert(io.open(path, "wb"))
    assert(handle:write(content))
    handle:close()
end

local actorCondition = table.concat({
    "\t<m_Conditions>",
    "\t\t<m_Name>PNCActor</m_Name>",
    "\t\t<m_Type>BOOL</m_Type>",
    "\t\t<m_BoolValue>true</m_BoolValue>",
    "\t</m_Conditions>",
    "",
}, "\n")

local restored = 0
for _, fileName in ipairs(sourceFiles) do
    local content = readAll(sourceDir .. "/" .. fileName)
    content = content:gsub("^\239\187\191", "")
    content = content:gsub("\r\n", "\n")

    local bumpType = content:match(
        "<m_Name>BumpType</m_Name>%s*"
            .. "<m_Type>STRING</m_Type>%s*"
            .. "<m_StringValue>([^<]+)</m_StringValue>"
    )
    assert(bumpType, "missing BumpType in " .. fileName)

    local pncBumpType = "PNC_" .. bumpType
    local sourceNode = content:match("<m_Name>([^<]+)</m_Name>")
    local pncNode = pncBumpType
    -- Bandits has four distinct shove nodes selected by the same "Shove"
    -- BumpType plus weapon conditions. Preserve those node identities while
    -- namespacing their shared selector.
    if bumpType == "Shove" then
        pncNode = tostring(sourceNode or "ZSShove")
            :gsub("^ZS", "PNC_")
    end
    content = content:gsub(
        "(<m_Name>)[^<]+(</m_Name>)",
        "%1" .. pncNode .. "%2",
        1
    )
    content = content:gsub(
        "(<m_StringValue>)" .. bumpType .. "(</m_StringValue>)",
        "%1" .. pncBumpType .. "%2",
        1
    )
    content = content:gsub(
        "<m_Name>BanditPrimaryType</m_Name>",
        "<m_Name>PNCPrimaryType</m_Name>"
    )
    content = content:gsub(
        "<m_Scalar>AttackVariationX</m_Scalar>",
        "<m_Scalar>PNCAttackVariationX</m_Scalar>"
    )
    content = content:gsub(
        "<m_Scalar2>AttackVariationY</m_Scalar2>",
        "<m_Scalar2>PNCAttackVariationY</m_Scalar2>"
    )
    content = content:gsub(
        "(\t<m_Conditions>%s*\n\t\t<m_Name>BumpType</m_Name>)",
        actorCondition .. "%1",
        1
    )
    assert(
        content:find("<m_Name>PNCActor</m_Name>", 1, true),
        "failed to add PNCActor condition to " .. fileName
    )

    writeAll(targetDir .. "/" .. pncNode .. ".xml", content)
    restored = restored + 1
end

print("Restored " .. tostring(restored) .. " PNC combat XML nodes from Bandits.")
