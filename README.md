# LunarSphere: Claude Edition

A port of LunarSphere to **World of Warcraft: Midnight** (12.1.x) and the
**WoW: Forever** beta (1.60.1), made with Claude (Anthropic's AI assistant).

Originally by: Moongaze
Taken over by: N3od3ath, Toludin-Stormrage
Fan update by: Fullmoon/Thundermoo/Bloodyaxe-Sulfuras & voyseys
Claude Edition: ported by Claude for [choss](https://github.com/choss/wow-addon-LunarSphere)

## About the Claude Edition

This edition is based on the LunarSphere fan update (1.70). Midnight changed a
lot of the game's add-on API and added in-combat "secret values" that add-ons
can display but can't do math with. This edition updates LunarSphere for both:

* Every removed game API is replaced with its modern equivalent (through
  `Lib/moduleCompat.lua`).
* The sphere keeps working in combat: gauges, sphere text and spell cooldowns
  update from secret values without doing math on them.
* Secure button set-up that isn't allowed in combat (logging in, template
  switching, "best item" updates, hiding Blizzard frames) waits until combat
  ends instead of failing.
* Fixes for buttons that wouldn't cast or use anything on the modern client
  (template order, empty macro and unit attributes, stale button refreshes).
* The data exporter (`LunarSphereExporter`) is included again, and importing
  works again.
* WoW: Forever gets its own `_Camelot.toc` files.

Some features had to be removed or work differently on Midnight. They're
listed, with the reasons, in [REMOVED_FEATURES.md](REMOVED_FEATURES.md).

### Status

This edition is new and still being tested in game. It has been checked
against Blizzard's UI source and API documentation for Midnight, the 12.1.5
PTR and WoW: Forever, and with a test harness that loads the add-on, simulates
combat and secret values, and runs the add-on's secure button code to verify
what each click does. Menus and some special button types still need more
in-game testing. Please report anything that doesn't work (see below).

**Tip:** "Edit buttons" is turned on by default. While it's on, button actions
are disabled out of combat (clicking a button edits it), and the sphere has a
yellow glow. Untick it in the settings to use your buttons.

## About LunarSphere

LunarSphere is an all-class version of the popular "sphere" addons that exist
for various classes within World of Warcraft.

It's a quality of life addon that helps players manage their buttons in a
smart and non-intrusive way. Besides adding extra buttons to the interface, it
has a class of "smart" buttons that support, among other actions:

* Using the strongest/weakest food in the player's inventory.
* Using the strongest/weakest healthstone/mana gem in the player's inventory.
* Using a random mount
* Changing the button action depending on the current stance.
* Applying a poison to the weapon in the player's main hand.
* Many others, like auto-selling junk or restocking reagents or food.

A smart button configured to use strongest food will change the item used if
the player buys a stronger food, for example.

### Details of LunarSphere

When it comes to "sphere" addons, examples that come to mind are the following
addons:

* Cryolysis (Mage)
* HolyHope (Paladin)
* Necrosis (Warlock)
* Sabella (Rogue)
* Serenity (Priest)
* Totemus (Shaman)
* Venantes (Hunter)

What separates this addon from the other sphere addons listed above is that
every button is customizable. When you load up LunarSphere for the first
time, you can load up a template for your specific class which will contain
every spell that your character knows and attach it to the sphere (if you
level up and learn new spells, you'll need to manually add them to the
sphere, or, if you never changed your sphere layout, you can just reload the
template again).

## Installation

### With WowUp

Every push to this repository builds a zip and publishes it as a GitHub
release, with the `release.json` file WowUp uses to pick the right files.

1. In WowUp, choose **Get Addons → Install from URL**.
2. Enter `https://github.com/choss/wow-addon-LunarSphere`.

WowUp then picks up new builds from the repository's releases.

### Manually

Download the latest zip from the
[releases page](https://github.com/choss/wow-addon-LunarSphere/releases) and
extract it in the `Interface\AddOns` folder for the game version you're
playing:

* Retail (Midnight): `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns`
* WoW: Forever (beta): the `Interface\AddOns` folder of your WoW: Forever installation
* Classic: `C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns` (or `_classic_era_`)

The zip contains both the `LunarSphere` and `LunarSphereExporter` folders;
copy both. There are no client-specific releases: the same zip works on every
client.

Classic still has its TOC, but this edition was only tested against Midnight
and WoW: Forever.

## Features

### Sphere

LunarSphere gives you a large sphere on the screen. Around said sphere, you
will find 10 buttons that circle around it. These buttons, known as "main
buttons," can take left, middle, and right click assignments to store spells,
items, or macros. These buttons can also be turned into menu buttons,
allowing an additional 12 buttons per menu button to exist, giving a total of
130 total buttons that you could possibly use, if you desire. The sphere can
also function like a button, making the total up to 131 buttons.

### Sphere Gauges/Display

The sphere provides up to two gauges (They look like rings or circular bars)
that can display certain information such as health, mana, experience, rep,
combo points, and more. You can also set text to be displayed on the middle
section of the sphere, to also display your health, mana, rep, and more.

On Midnight, gauges and sphere text keep updating in combat. Smooth gauge
animation pauses while values are secret, and a few displays are limited (see
[REMOVED_FEATURES.md](REMOVED_FEATURES.md)).

### Buttons

The buttons can take actions that you assign them, but there are also special
button types that you can assign to the button, such as "Use strongest
water," "Use random epic flying mount," "Apply best Instant Poison to
Main-hand" and more. Some can be seen as specific for certain classes, other
button types can be used by all. Lots of "auto bar" type action assignments
will happen within LunarSphere, if you assign such actions.

### Reagent Restocking

LunarSphere can restock reagents from a custom list you define. Helpful for
tailors who constantly need to restock on thread, or rogues who need poisons,
hunters with ammo, priests with candles, and more.

### Random Speeches

The random speeches that were trademark of most sphere addons? Yeah,
LunarSphere can do that too. The addon comes pre-loaded with a few speeches
for your mounts and for resurrecting people, but the sky is the limit since
you can create your own speeches and assign them to items and spells that are
used. Great for roleplayers, great for people who want to annoy their raid,
or make them laugh.

On Midnight, speeches are skipped while the game locks chat (encounters,
Mythic+ and rated PvP).

### Skinning

LunarSphere lets you skin the buttons with over 38 circular button skins and
any color tinting you want to apply to them. LunarSphere was built to be
customizable to fit most, if not all interfaces, no matter the color or
design.

### And more!

Tooltip handling and coloring, junk item selling, bank restocking, user
interface object hiding (such as the action bar artwork, the main menu
buttons, the mini-map zoom buttons, and more), and more can be handled by
LunarSphere. If you want to use it as a full action bar replacement, you can
hide all the action bars, assign the menu buttons and bag opening features to
LunarSphere buttons, and clean up your screen.

### Memory management

A lot of the extra bells and whistles of LunarSphere can be disabled so that
it doesn't tie up lots of memory. In fact, with all features running,
LunarSphere runs on about 850kb of memory and can replace between 3 and 10
addons, depending on the features used.

### Longevity

Lastly, LunarSphere was made to last. When new drinks, food, potions, mounts,
bandages and more are added to World of Warcraft, LunarSphere will usually
pick up those new items without a version update. When new spells come out,
you can just add them to your sphere just like dragging a spell from your
spellbook to an action bar.

## User Manual and various help that might be needed

LunarSphere doesn't have a user manual, but [Dreambound's blog post](http://dreambound-druid.blogspot.com/2009/03/lunarsphere.html)
is pretty close to one.

LunarSphere can be overwhelming at first. Lots of beta testers who helped with
the project have said that after getting used to it, LunarSphere became
really easy to setup and use, and they loved the power it provides.

## Bug Reporting

Please report problems with the Claude Edition on this repository's issue
tracker:

https://github.com/choss/wow-addon-LunarSphere/issues

When posting a report, please include:

1. Which client you were using:
    1. Retail (Midnight)
    2. WoW: Forever
    3. Classic
2. Which class you were playing
3. How to trigger the bug, and any Lua error text (BugSack is a big help)
4. For buttons that don't react: `/fstack` output over the button, and whether
   "Edit buttons" is ticked

The original fan update lives at https://github.com/leonardopsantos/LunarSphere
and its community on the LunarSphere Discord server
(https://discord.gg/qdwhkfXwCU).

## Current Version: 1.80 (Claude Edition)

* Update to WoW 12.1.0 / Midnight (and the 12.1.5 patch)
* Support for the WoW: Forever beta (1.60.1)
* Works in combat with Midnight's secret values: gauges, sphere text and spell
  cooldowns keep updating in combat
* Fixed buttons not casting or using anything on the modern client
* Data exporter included again
* See [REMOVED_FEATURES.md](REMOVED_FEATURES.md) for what was removed or changed,
  and `LunarSphere/changelog.txt` for the full list of changes

## Special Thanks

The first thanks must go to Moongaze, who coded this amazing addon. Many
thanks to the other torch bearers over the years who kept LS alive:
N3od3ath, Toludin-Stormrage, voyseys and Fullmoon/Thundermoo/Bloodyaxe, as
well as Zenyari1 for updating LS to Dragonflight, nicodemusmercy for helping
test it, and Crystyl and Murph for updating it to The War Within.
