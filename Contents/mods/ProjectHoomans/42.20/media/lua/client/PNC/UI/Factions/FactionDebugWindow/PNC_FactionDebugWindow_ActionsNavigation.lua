-- Faction debug window navigation actions.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local Model = Internal.Model
local ClientState = Internal.ClientState
local MOBILE_FILTER_CONTROL_MAP = Internal.MobileFilterControlMap
local text = Internal.Text
function Internal.HandleMobileFilterAction(self, internal)
    local mobileFilter = MOBILE_FILTER_CONTROL_MAP[internal]
    if not mobileFilter then return false end
    self.mobileFilter = mobileFilter
    self:refreshSnapshot()
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
    return true
end

function Internal.HandleWindowAction(
    self, button, internal, faction, npc, target
)
    if internal == "refresh" then
        self:requestSnapshot()
        return true
    end
    if internal == "overlay" then
        local visible = PNC.FactionDebugOverlay.Toggle()
        if PNC.MapDisplay and PNC.MapDisplay.SetBasesVisible then
            PNC.MapDisplay.SetBasesVisible(visible)
        end
        if visible then
            PNC.FactionDebugOverlay.SetSelection(
                faction and faction.id,
                target and target.id,
                npc and npc.id
            )
        end
        return true
    end
    if internal == "manage_player_members" then
        PNC.FactionMemberUI.Open()
        return true
    end
    if internal == "create_player_faction"
        or internal == "edit_emblem"
    then
        local snapshot = ClientState.factionDebug or {}
        local selected = faction and faction.faction or nil
        PNC.FactionEmblemEditor.Open({
            archetypeID = selected
                and selected.archetypeID or "settler",
            emblem = internal == "edit_emblem"
                and selected and selected.emblem or nil,
            seed = selected and selected.id
                or snapshot.currentPlayerKey
                or "player_faction",
            context = {
                action = internal,
                groupSize = tonumber(
                    self.groupSizeEntry
                        and self.groupSizeEntry:getText()
                        or self.groupSize
                ) or 4,
                presenceMode = self.presenceMode,
            },
            onSave = function(emblem, context)
                PNC.Client.SendDebug(
                    "faction_debug_action",
                    {
                        factionAction =
                            context.action == "edit_emblem"
                                and "set_emblem"
                                or "create_player_faction",
                        factionID = selected and selected.id,
                        emblem = emblem,
                        groupSize = math.max(
                            1,
                            math.min(
                                24,
                                math.floor(
                                    context.groupSize or 4
                                )
                            )
                        ),
                        presenceMode = context.presenceMode,
                    }
                )
            end,
        })
        return true
    end
    if string.sub(internal, 1, 5) == "view_" then
        local view = string.sub(internal, 6)
        if Model.Views[view] then
            self.viewMode = view
            self:refreshSnapshot()
            self:requestResponsiveLayout(true)
        end
        return true
    end
    return false
end
