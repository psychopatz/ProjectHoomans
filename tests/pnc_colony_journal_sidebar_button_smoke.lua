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
T.falsy(string.find(source, "enabled = hasRadio", 1, true),
    "journal access icon is incorrectly disabled without a radio")
T.contains(source, "ButtonAPI.HasRadio = hasRadio",
    "journal radio gate is not reusable by hub functionality")
T.contains(source, "local hub = PNC.CommandHub",
    "journal icon does not depend on a second sidebar registration")
T.contains(source, "return hub.Toggle()",
    "journal icon does not open the colony command hub")
T.falsy(string.find(source, "ColonyJournalUI.Toggle", 1, true),
    "journal icon still opens the journal directly")
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
    "journal exposes radio possession separately from event-window access")
T.contains(windowSource, "function JournalUI.CanOpen()",
    "journal does not expose an explicit window availability predicate")
T.contains(windowSource, "return true",
    "journal window remains available without a radio")
T.contains(windowSource, "WidgetWindow.Install",
    "journal window does not use the shared detachable widget control")
T.contains(windowSource, 'id = "pnc-colony-journal-widget"',
    "journal widget does not have a stable toolbar id")
T.contains(windowSource, "Options.ApplyOpacity(window, Options.GetOpacity())",
    "journal window does not consume shared command-hub opacity")
T.contains(windowSource, "Options.ApplySurfaceOpacity(self.list, lift)",
    "journal list does not use the shared content opacity lift")
T.contains(windowSource, "self.contentOpacity = Options.GetContentOpacity(lift)",
    "journal header does not use the shared content opacity lift")
T.contains(windowSource, "window.owner = owner or window.owner",
    "journal window is not attached to its colony hub owner")
T.contains(windowSource, "function JournalUI.Close()",
    "journal window has no managed child close path")
T.falsy(string.find(windowSource, "radioFooterRect", 1, true),
    "journal does not use a lower radio strip")
T.falsy(string.find(windowSource, 'UI_PNC_ColonyJournal_Live', 1, true),
    "journal does not render a live status label")
T.falsy(string.find(windowSource, 'UI_PNC_ColonyJournal_Offline', 1, true),
    "journal does not render a radio offline status label")
T.falsy(string.find(windowSource, "Stored: %s x%d by %s", 1, true),
    "journal does not render raw storage wire fields")

T.finish("pnc_colony_journal_sidebar_button_smoke")
