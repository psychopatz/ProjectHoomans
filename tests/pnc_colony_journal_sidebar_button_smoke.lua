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
T.contains(source, "RadioImageAnimation",
    "journal registration uses the core radio animation")
T.contains(source, "imageRefreshInterval = 200",
    "sidebar refreshes animated radio frames at the configured cadence")
T.contains(source, "Signal_found/2.png",
    "sidebar uses the shared inactive radio frame")
T.contains(source, "Signal_search/",
    "sidebar uses the shared active radio animation")
T.contains(source, "HasPlayerDevice",
    "sidebar stays available while the radio is present but inactive")
T.falsy(string.find(source, "Item_WalkieTalkieCivilian", 1, true),
    "sidebar does not use the static walkie-talkie icon")
T.contains(source, "enabled = hasRadio",
    "journal registration stays clickable with an inactive radio")
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
T.contains(windowSource, "imageX = header.x + header.width - imageSize",
    "journal positions the radio animation at the header right edge")
T.contains(windowSource, "RadioDeviceState.HasPlayerDevice",
    "journal can open without an active powered radio")
T.falsy(string.find(windowSource, "radioFooterRect", 1, true),
    "journal does not use a lower radio strip")
T.falsy(string.find(windowSource, 'UI_PNC_ColonyJournal_Live', 1, true),
    "journal does not render a live status label")
T.falsy(string.find(windowSource, 'UI_PNC_ColonyJournal_Offline', 1, true),
    "journal does not render a radio offline status label")
T.falsy(string.find(windowSource, "Stored: %s x%d by %s", 1, true),
    "journal does not render raw storage wire fields")

T.finish("pnc_colony_journal_sidebar_button_smoke")
