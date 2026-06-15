# Weekly Sign-In Design

## Goal

Add a seven-day weekly sign-in feature in two stages. First, run the official
SignInEvent template unchanged with its official UI and TestButton. After the
complete sign-in and reward flow is verified, replace the official main panel
with the existing `UI04` art panel and add a separate persistent entry button.

## Scope

### Stage 1: Official template verification

- Keep all files under `ExtendResource/SignInEvent/OfficialPackage` unchanged.
- Configure one weekly sign-in event with seven reward days.
- Use the same temporary item ID and quantity for all seven days.
- Use the official `TestButton` to open the panel, clear test data, add or
  remove items, and query the temporary item count.
- Use the official `SignInEvent_Main_UIBP` as the sign-in panel.
- Persist player sign-in state through `UGCPlayerStateSystem`.
- Grant rewards through `VirtualItemManager`.

### Stage 2: Project UI integration

- Create a new persistent sign-in entry widget.
- Open `UI04` from the entry widget.
- Adapt `UI04` to the verified SignInEvent APIs and data.
- Replace generic widget names such as `Button_620` with role-based names
  before binding behavior.
- Remove or hide the official TestButton in production.

Stage 2 starts only after Stage 1 passes all acceptance checks.

## Architecture

The official `SignInEventComponent` is attached to each player's controller.
It reads the event configuration and reward table, owns the local sign-in UI,
validates requests on the server, and saves each player's progress.

```text
Official TestButton
        |
        v
SignInEventManager
        |
        v
SignInEventComponent on PlayerController
   |          |                 |
   v          v                 v
Config     Player archive   VirtualItemManager
tables     sign-in data     temporary reward
   |
   v
Official SignInEvent UI
```

The client requests a sign-in through `SignInEventManager`. The component
checks event time, current day, duplicate claims, and client/server data
consistency. Only the server updates archive data and grants the reward.

## Required Configuration

### Virtual item system

The project must provide a `VirtualItemManager` game-part actor discoverable by
this exact name. The temporary reward item must exist in the project's item
table and mapping table before the sign-in test.

### Sign-in component

The official `SignInEventComponent` must be added to the active player
controller and configured with:

- `ConfigTablePath`: the sign-in event configuration table.
- `MainUIPath`: official `SignInEvent_Main_UIBP`.
- `TestButtonPath`: official `TestButton`.
- `ShowTestButton`: enabled for Stage 1.

The component registers its class with `SignInEventManager`, loads the tables,
and creates the official UI and test controls for the local player.

### Weekly event table

Create or duplicate a project-owned configuration table rather than editing an
official package asset. Configure one row with:

- A unique `EventID` used consistently by the UI tab and config row.
- Type set to `Weekly`.
- A valid start and end time covering the test period.
- An award table path pointing to the seven-day test table.
- Supplement fields disabled or configured with harmless test values for the
  first pass.
- A short test event name and description.

### Seven-day award table

Create a project-owned award table containing seven rows. Every row uses the
same temporary item ID and a small quantity. Row ordering must be verified in
the editor because the template converts table rows into the displayed day
sequence.

## Error Handling

- Missing `VirtualItemManager`: the UI may open, but reward delivery cannot be
  considered successful.
- Missing or invalid table paths: the component logs a path or config loading
  error and must not be worked around by editing official Lua.
- Duplicate daily claim: the server rejects it without granting another item.
- Client/server progress mismatch: the server rejects the request.
- Invalid event dates: the event is hidden or the claim is rejected.
- Failed archive write or virtual item grant: record the log and fix the
  underlying project configuration before UI04 integration.

## Verification

Stage 1 is complete only when all of the following pass in a multiplayer test
session where server behavior is active:

1. The official TestButton appears.
2. The Open action displays the official weekly sign-in UI.
3. The weekly event displays exactly seven rewards in the expected order.
4. The first claim grants the configured temporary item quantity.
5. Querying the item through TestButton reports the increased count.
6. A second claim on the same day grants nothing.
7. Clearing test data resets sign-in progress for another test run.
8. Re-entering the game preserves progress when data has not been cleared.
9. No missing asset, invalid soft path, component, archive, or virtual item
   errors appear in the relevant logs.

## UI04 Integration Boundary

`UI04` is currently an art-complete but behavior-free widget with fourteen
buttons and generic control names. Stage 2 will treat it as a view over the
already verified SignInEvent system. It will call manager APIs for opening,
claiming, and reading state; it will not duplicate archive or reward logic.

The separate persistent entry widget will own only entry visibility and the
open action. Sign-in state, duplicate-claim protection, persistence, and reward
delivery remain owned by the official component and server flow.

## Non-Goals

- Editing files inside the official SignInEvent package.
- Implementing monthly, one-off, or supplementary sign-in in Stage 1.
- Final reward balancing or production item selection.
- Rebuilding the official persistence and server validation logic.
- Binding UI04 before the official template passes verification.
