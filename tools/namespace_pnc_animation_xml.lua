-- Makes every PNC bump selector and attack blend scalar private to PNC.
-- Pass the shipped PNC XML paths as arguments, for example:
--   find Contents/mods/ProjectHoomans/common/media/AnimSets/zombie \
--     -type f -name 'PNC_*.xml' -print0 \
--     | xargs -0 lua tools/namespace_pnc_animation_xml.lua

local updated = 0

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

local function isLegacyCombat(path)
    local fileName = tostring(path):match("([^/]+)$") or ""
    return fileName:match("^PNC_Anim_Attack") ~= nil
        or fileName:match("^PNC_Anim_Knife") ~= nil
        or fileName:match("^PNC_Anim_Shove") ~= nil
        or fileName == "PNC_Anim_FrontKick.xml"
        or fileName == "PNC_Anim_HighKick.xml"
end

local function namespaceBumpType(path, value)
    value = tostring(value or "")
    if value:match("^PNC_") then
        return value
    end
    if isLegacyCombat(path) then
        -- The restored PNC_* combat nodes are the canonical runtime graph.
        -- Keep old PNC_Anim_* previews available without giving them the same
        -- selector (or Bandits' global selector) at load time.
        return "PNC_Legacy_" .. value
    end
    return "PNC_" .. value
end

for _, path in ipairs(arg) do
    local original = readAll(path)
    local content = original
    content = content:gsub(
        "(<m_Name>BumpType</m_Name>%s*"
            .. "<m_Type>STRING</m_Type>%s*"
            .. "<m_StringValue>)([^<]+)(</m_StringValue>)",
        function(prefix, value, suffix)
            return prefix .. namespaceBumpType(path, value) .. suffix
        end
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
    if content ~= original then
        writeAll(path, content)
        updated = updated + 1
    end
end

print("Namespaced " .. tostring(updated) .. " PNC animation XML files.")
