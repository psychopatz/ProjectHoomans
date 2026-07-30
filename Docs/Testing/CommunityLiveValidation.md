# Community Live Validation

## Phase 5B.1 overlay gate

No Project Zomboid live session was available during Phase 5C implementation.
Automated Lua UI/model tests are not live validation. The required Phase 5B.1
overlay checks therefore remain:

| Check | Live status |
|---|---|
| Overlay opening and closing | NOT TESTED |
| No duplicated event handlers | NOT TESTED |
| 1280×720 layout | NOT TESTED |
| Normal development resolution | NOT TESTED |
| UI scaling above 100% | NOT TESTED |
| Source/target refresh | NOT TESTED |
| Telemetry enable and disable | NOT TESTED |
| Attack episode visualization | NOT TESTED |
| Treaty reconciliation visualization | NOT TESTED |

No critical lifecycle defect was observed by static inspection or automated
smoke coverage, but that is not a substitute for this matrix.

## Community validation matrix

Open **PsychopatzCore Debug Hub → PNC Community Inspector** with admin/debug
authority. The optional **PNC Community NPC World Overlay** renders sanitized
server diagnostics above visible NPCs. Record the game version, mod commit,
resolution, UI scale, server type, and save name for every run.

| # | Scenario | Expected evidence | Result |
|---|---|---|---|
| 1 | Create settlement for settler faction | Active settled record, faction index, creation defaults | NOT RUN |
| 2 | Create camp for refugee faction | Active camped record and refugee creation defaults | NOT RUN |
| 3 | Assign matching-faction NPC | Affiliation V2 and member index agree | NOT RUN |
| 4 | Assign wrong-faction NPC | `faction_mismatch`; no revisions change | NOT RUN |
| 5 | Verify population | Living assigned NPC count; dead NPC excluded | NOT RUN |
| 6 | Set leader | Living member becomes leader | NOT RUN |
| 7 | Set home to selected NPC | Primitive coordinates update | NOT RUN |
| 8 | Walk inside/outside radius | Overlay containment and distance change | NOT RUN |
| 9 | Adjust security and morale | Values/revisions persist; combat unchanged | NOT RUN |
| 10 | Add/remove supplies | Integer summaries change atomically | NOT RUN |
| 11 | Save/reload | Registry, membership, leader, summaries persist | NOT RUN |
| 12 | Same-faction community transfer | One current membership, no faction history | NOT RUN |
| 13 | Cross-faction community transfer | Rejects without changes | NOT RUN |
| 14 | Remove NPC from faction | Community reference and index clear | NOT RUN |
| 15 | Kill community leader | Membership and leadership clear | NOT RUN |
| 16 | Archive community | Historical record remains; members/leader clear | NOT RUN |
| 17 | Destroy community | Destroyed historical record remains | NOT RUN |
| 18 | Archive owning faction | Owned active communities archive | NOT RUN |
| 19 | Destroy owning faction | Owned communities become destroyed | NOT RUN |
| 20 | Compare unrelated state | Diplomacy, hostility, relationships, conduct unchanged | NOT RUN |
| 21 | Compare revisions | `presenceRevision` and social revisions unchanged | NOT RUN |
| 22 | 1280×720 | Inspector remains usable | NOT RUN |
| 23 | Normal development resolution | Inspector and overlay remain usable | NOT RUN |
| 24 | UI scale above 100% | Controls/lists remain reachable | NOT RUN |
| 25 | Hosted authority | Admin succeeds; ordinary client rejects | NOT RUN |
| 26 | Dedicated authority | Persistence and guarded commands behave identically | NOT RUN |

## Result record

| Field | Result |
|---|---|
| Commit/mod version | |
| Save name | |
| Game mode | |
| Server type | single-player / hosted / dedicated |
| Resolution and UI scale | |
| Community IDs | |
| NPC IDs | |
| Revisions before/after | |
| Save/reload result | |
| Pass/fail | NOT RUN |
| Notes | |
