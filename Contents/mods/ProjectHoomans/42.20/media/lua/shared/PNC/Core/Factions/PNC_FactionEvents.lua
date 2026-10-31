-- Public, data-only faction facts. Listeners never admit or veto mutations.
-- Emitted only after successful commit/reconciliation, never for rejected/unchanged requests.
-- The relation is a detached snapshot; observer errors cannot veto the result.
-- TREATY_CHANGED(firstID, secondID, incidentType, relationSnapshot, worldAgeHours)
return {
    TREATY_CHANGED = "projecthoomans.faction.treatyChanged",
}
