-- Resolve Bandits' case-mismatched animation x_extends paths on Linux.
--
-- Bandits refers to these files using lowercase names while the installed
-- files use mixed case. PZ resolves x_extends against the absolute Workshop
-- path, which bypasses its normal media-relative active-file lookup. Add an
-- absolute, lowercase lookup alias to the existing canonical file path. This
-- changes only PZ's in-memory file map; it never writes into Bandits' files.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}

local Compat = PNC.Compatibility.Bandits.AnimPathCompat
    or {}
PNC.Compatibility.Bandits.AnimPathCompat = Compat

local aliasPaths = {
    "media/AnimSets/zombie/climbwindow/zsfall.xml",
    "media/AnimSets/zombie/getup/zsonback.xml",
    "media/AnimSets/zombie/lunge-network/defaultlunge.xml",
    "media/AnimSets/zombie/lunge/defaultlunge.xml",
    "media/AnimSets/zombie/pathfind/zslimpall.xml",
    "media/AnimSets/zombie/pathfind/zsrunall.xml",
    "media/AnimSets/zombie/pathfind/zssneakwalkall.xml",
    "media/AnimSets/zombie/pathfind/zswalkall.xml",
    "media/AnimSets/zombie/staggerback/zsdefaultstaggerback.xml",
    "media/AnimSets/zombie/thump/doorbang.xml",
    "media/AnimSets/zombie/turnalerted/zsdefault.xml",
    "media/AnimSets/zombie/walktoward-network/zslimpall.xml",
    "media/AnimSets/zombie/walktoward-network/zsrunall.xml",
    "media/AnimSets/zombie/walktoward-network/zssneakwalkall.xml",
    "media/AnimSets/zombie/walktoward-network/zswalkall.xml",
    "media/AnimSets/zombie/walktoward/zslimpall.xml",
    "media/AnimSets/zombie/walktoward/zsrunall.xml",
    "media/AnimSets/zombie/walktoward/zssneakwalkall.xml",
    "media/AnimSets/zombie/walktoward/zswalkall.xml",
}

local fileSystem = ZomboidFileSystem
    and ZomboidFileSystem.instance or nil
local activeFiles = fileSystem and fileSystem.activeFileMap or nil
local installed = 0
local index
local actualPath
local aliasKey

if fileSystem and fileSystem.getAbsolutePath
    and activeFiles and activeFiles.get and activeFiles.put
then
    for index = 1, #aliasPaths do
        actualPath = fileSystem:getAbsolutePath(aliasPaths[index])
        if actualPath then
            actualPath = tostring(actualPath)
            if string.find(
                string.lower(actualPath),
                "/mods/bandits/",
                1,
                true
            ) then
                aliasKey = string.lower(actualPath)
                if activeFiles:get(aliasKey) == nil then
                    activeFiles:put(aliasKey, actualPath)
                    installed = installed + 1
                end
            end
        end
    end
end

Compat.installedAliases = installed
if installed > 0 and print then
    print("[PNC][BanditsCompat] event=animation_path_aliases installed="
        .. tostring(installed))
end

return Compat
