local T = require "tests/support/test"

T.addPackagePaths()

local source = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/PNC_ColonyJournalButton.lua")
local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/PNC_ColonyJournalWindow.lua")

T.contains(source, "PsychopatzCore.UI.Sidebar",
    "journal button uses the core sidebar provider")
T.contains(source, "Sidebar.Register",
    "journal button is registered through the reusable provider")
T.contains(source, 'id = "PNC.ColonyJournal"',
    "journal button has a stable provider id")
T.contains(source, "Item_WalkieTalkieCivilian",
    "journal registration supplies the active walkie-talkie icon")
T.contains(source, "Item_WalkieTalkieCivilian2",
    "journal registration supplies the inactive walkie-talkie icon")
T.contains(source, "enabled = activeRadio",
    "journal registration follows the active radio state")
T.falsy(string.find(source, "ISEquippedItem.initialise", 1, true),
    "journal module does not own the vanilla sidebar hook")
T.falsy(string.find(source, "host:addChild(button)", 1, true),
    "journal module does not create a detached sidebar control")
T.contains(windowSource, "PNC_ColonyStorageActivityPresentation",
    "journal reuses the storage activity formatter")
T.contains(windowSource, "StorageJournal.FIELD",
    "journal maps compact storage fields before presentation")
T.contains(windowSource, "Signal_found/2.png",
    "journal uses the radio idle signal frame")
T.contains(windowSource, "Signal_search/",
    "journal uses the shared radio search animation")
T.falsy(string.find(windowSource, "Stored: %s x%d by %s", 1, true),
    "journal does not render raw storage wire fields")

T.finish("pnc_colony_journal_sidebar_button_smoke")
