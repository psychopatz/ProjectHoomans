local Paths = {}

local function exists(path)
    local file = io.open(path, "rb")
    if file then file:close(); return true end
    return false
end

function Paths.modRoot(modId)
    modId = tostring(modId or "ProjectHoomans")
    local root = "Contents/mods/" .. modId .. "/"
    local handle = io.popen("find '" .. root
        .. "' -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null")
    local versions = {}
    if handle then
        for name in handle:lines() do
            if name ~= "common" and exists(root .. name .. "/mod.info") then
                versions[#versions + 1] = name
            end
        end
        handle:close()
    end
    table.sort(versions, function(left, right) return left > right end)
    assert(versions[1], "No active version root found for " .. modId)
    return root .. versions[1] .. "/"
end

return Paths
