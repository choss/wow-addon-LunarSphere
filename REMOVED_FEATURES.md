# Removed and limited features (v1.80: Midnight and WoW: Forever)

LunarSphere 1.80 targets the Midnight retail client (12.1.0, plus 12.1.5) and the
WoW: Forever beta (1.60.1, which runs the same modern client). Almost every feature
of 1.70 still works, including in combat. This file lists the features that had to
be removed or that work differently now, and explains why.

Most of the limits come from Midnight's **secret values**. While you are in combat,
the game hands add-ons health, power, cooldown, aura and tooltip data as "secret"
values. Add-ons can pass a secret value to the game to display it, but they can't do
math with it, compare it, or test it. WoW: Forever uses the same system.

## Removed

| Feature | Why |
| --- | --- |
| **Hide the world map minimap button** | The button (`MiniMapWorldMapButton`) no longer exists on modern clients. The option is greyed out on Midnight and Forever. It still works on Classic. |
| **Key ring button type** | The key ring was removed from the game in patch 4.2. A button set to "Key ring" does nothing on Midnight and Forever. It still works on Classic Era. |
| **Guild bank reagent restocking** | This could never be reached in 1.70: there was no option for it in the settings window, and the event it relied on (`GUILDBANKFRAME_OPENED`) no longer exists. The dead code was removed when restocking was rewritten. Restocking from vendors and from your own bank (bank tabs) still works. |
| **Auction house sale and bid totals** | Already turned off in 1.70, because Blizzard replaced the auction house API in 8.3. It has not been brought back. |
| **Battle pet shortcuts** | Never supported (1.70 printed a "not yet supported" message, and that line also had a bug). Dragging a battle pet onto a button is still ignored. Pet summon spells and companion buttons work. |
| **DrDamage integration** | DrDamage has been discontinued, and the integration was already commented out in 1.70. |

## Limited while in combat (secret values)

These features work normally out of combat. In combat they fall back to what the
game allows.

| Feature | What happens in combat | Why |
| --- | --- | --- |
| **Sphere gauges** (health, mana and other power, target health and power, combo points, extra power) | The gauges still fill correctly. The game computes the fill angle and visibility from the secret value through curves (`C_CurveUtil`), and LunarSphere passes the results to `SetRotation` / `SetAlpha`. | Health and power are secret. Health (`UnitHealth`) is secret even out of combat, so health gauges always use this path. |
| **Smooth gauge animation** | Turned off while the value is secret: the gauge jumps to the new value instead of sliding. Animation comes back once the values are readable. | The animation works out a step between the old and new values, which is math on a secret value. |
| **Sphere text** (health, power and so on) | Still shown. Percent mode uses the game's own 0–100 scaling (`CurveConstants.ScaleTo100`), and plain values are passed to the font string as they are. Custom number formatting doesn't apply. | Formatting a number means doing math on it. |
| **Five-second rule gauge / text** | While mana is secret, spending mana can't start the five-second countdown. The gauge shows full and the text is empty. A countdown that was already running when the value became secret finishes normally. | Detecting the rule means checking whether mana went *down*, which is a comparison between secret values. |
| **Button cooldowns for spells** | Shown with the game's own cooldown swipe through a duration object (`C_Spell.GetSpellCooldownDuration`). If "cooldown text" is on, the game's countdown numbers are shown instead of LunarSphere's text. LunarSphere's own cooldown colours and fade effects pause until combat ends. | Spell cooldowns are secret, so LunarSphere can't run its own timers on them. |
| **Sphere cooldown text** (sphere text set to "cooldown") | Empty while the sphere spell's cooldown is secret. | The sphere has no cooldown swipe that could take a duration object, and the text needs math. |
| **Item cooldowns** | No change. | `C_Item.GetItemCooldown` is not secret. |
| **Spell cast counts** | Still shown, through `C_StringUtil.TruncateWhenZero`. | The count is secret, so it can't be compared with 0 to hide it. |
| **Tooltip filtering** (hide yellow or green lines, recolouring) | Lines the game marks as secret are copied into the tooltip as they are. They can't be filtered, recoloured or measured. Readable lines are still filtered. | Tooltip text can be secret in combat. |
| **Speeches** (random say / party / raid / emote lines) | Speeches that would fire while chat is locked down (`C_ChatInfo.InChatMessagingLockdown()`, which Midnight uses in encounters, Mythic+ and rated PvP) are skipped silently. A target name that is secret becomes empty in the speech text. | Add-ons can't send chat messages during lockdown, and secret names can't be inserted into text that is then sent. |

## Deferred until combat ends

LunarSphere's buttons are secure action buttons, so they work in combat. Like every
add-on, though, LunarSphere can't *reconfigure* them while you are in combat. These
changes now wait for combat to end instead of failing:

* **Logging in or reloading in combat:** set-up is queued and runs as soon as combat
  ends. Until then the sphere isn't configured.
* **"Strongest / weakest" item buttons** (food, water, potions, healthstones,
  bandages, mounts…): if your bags change mid-fight, the buttons are updated after
  combat.
* **Switching templates when your specialization changes:** applied after combat.
* **Hiding or showing Blizzard UI elements** (action bars, micro menu, bags bar,
  experience bars…): changes made in combat are applied after combat.

Opening and closing menus, auto-closing menus on mouse-out, clicking buttons,
keybindings and stance-based button states all still work in combat. They are driven
by secure snippets that run in Blizzard's restricted environment.

## Changed behaviour

* **Two template slots (dual spec):** retail has no talent groups any more, so the
  two template slots now map to specializations 1 and 2.
* **Menu bar button types** (character, spellbook, talents, achievements, quest log
  and so on) are now secure `/click <MicroButton>` macros. This means they work in
  combat and don't taint the UI. If a micro button doesn't exist on a client, that
  button type does nothing.
* **Gossip auto-skip** uses the modern gossip API (option icons). Hold **Shift**
  while talking to an NPC to skip auto-skipping.
* **"Say" and "yell" speeches outside instances** are sent as emotes ("says, …" /
  "yells, …"), as in 1.70. Blizzard only allows add-ons to `/say` and `/yell` inside
  instances.
* **Minimap coordinates** are left empty wherever the game doesn't provide a player
  position (for example inside instances).
* **Tooltip skinning** colours the modern NineSlice tooltip border and background,
  because GameTooltip no longer has backdrop functions.
* **The data exporter** (`LunarSphereExporter`) is shipped again, and importing from
  `LunarSphere\LunarSphereExporter.lua` works again, as described in
  `LunarSphereExporter\How to Import and Export.txt`.

## How this was tested

No WoW client was available, so this port has **not been run in game yet**. It was
checked against the Blizzard UI source and API documentation for Midnight 12.1.0,
the 12.1.5 PTR and WoW: Forever, using:

* A scan of every global function the add-on calls: all removed APIs go through
  `Lib/moduleCompat.lua`.
* A check of every registered event against each client's event list.
* A check of every secure snippet against the restricted environment's function
  list.
* A Lua 5.1 harness. It loads the add-on against each client's real widget and API
  lists, assigns spells, items and macros, simulates combat with secret values and
  chat lockdown, and reports Lua errors, secrets passed to functions that don't
  accept them, and blocked protected actions. It reports zero of each on both
  clients.

Two things can only be confirmed in game: the exact look of the curve-driven gauges,
and whether moving Blizzard frames to the hidden UI parent causes taint in some
edge case. Please report anything that looks wrong.
