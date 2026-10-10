# LunarSphere

Originaly By: Moongsaze
Taken over by: N3od3ath, Toludin-Stormrage
Current fix by: Fullmon/Thundermoo/Bloodyaxe-Sulfuras & voyseys

## About LunarSphere

LunarSphere is an all-class version of the popular "sphere" addons that exist
for various classes within World of Warcraft.

It's a quality of life addon that helps players manage their buttons in a
smart and non-intrusive way. Besides adding extra button to the interface, it
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
time, you can load up a template for your specific class (Warriors, Druids,
and now Death Knights have some sphere addon love) which will contain every
spell that your character knows and attach it to the sphere (if you level up
and learn new spells, you'll need to manually add them to the sphere, or, if
you never changed your sphere layout, you can just reload the template
again).

If you've never seen any of these addons, or need to know more about
LunarSphere, here you go:

## Installation

Just extract a release file in the `Interface\AddOns` folder for the game
version you're playing:

* Retail (Midnight) : `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns`
* WoW: Forever (beta) : the `Interface\AddOns` folder of your WoW: Forever installation
* Classic : `C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns` (or `_classic_era_`)

Copy both the `LunarSphere` and `LunarSphereExporter` folders. LunarSphere supports
all clients out-of-the-box, there are no client-specific releases.

See [REMOVED_FEATURES.md](REMOVED_FEATURES.md) for the features that were removed
or work differently on Midnight and WoW: Forever (mostly because of Midnight's
in-combat secret values).

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

### Buttons

The buttons can take actions that to assign them, but there are also special
button types that you can assign the the button, such as "Use strongest
water," "Use random epic flying mount," "Apply best Instant Poison to
Main-hand" and more. Some can be seen as specific for certain classes, other
button types can be used by all. Lots of "auto bar" type action assignments
will happen within LunarSphere, if you assign such actions.

### Reagent Restocking

LunarSphere can restock reagents from a custom list you define. Helpful for
tailors who constantly need to restock on thread, or rogues you need poisons,
hunters with ammo, priests with candles, and more.

### Random Speeches

The random speeches that were trademark of most sphere addons? Yeah,
LunarSphere can do that too. The addon comes pre-loaded with a few speeches
for your mounts and for resurrecting people, but the sky is the limit since
you can create your own speeches and assign them to items and spells that are
used. Great for roleplayers, great for people who want to annoy their raid,
or make them laugh.

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
spellbook to an action bar. That's some of the power and flexibility that
LunarSphere provides, so that the only time you need to update LunarSphere
will be for bells and whistle feature updates or bug fixes, but never so that
you can finally use your new spell.

### Discord Server

The watering hole for Lunarspherians is the LunarSphere Discord server at

https://discord.gg/qdwhkfXwCU

Feel free to drop in, ask questions, make suggestions, or just hang out.

I go by Fullmoon_druid there. Please feel free to ask for any questions or
features that you'd like to be added. 

### User Manual and various help that might be needed

LunarSphere doesn't have a user manual, but [Dreambound's blog post](http://dreambound-druid.blogspot.com/2009/03/lunarsphere.html) 
is pretty close to one.

LunarSphere can be overwhelming at first. Lots of beta testers who helped with
the project have said that after getting used to it, LunarSphere became
really easy to setup and use, and they loved the power it provides.

### Bug Reporting, Feature Requests, Comments and More

The ideal place to fill bug reports is LunarSphere git repo at 

https://github.com/leonardopsantos/LunarSphere

It's OK to post bug report on Curse or on Discord. When posting a report,
please make sure that you inform:

1. Which client were you using:
    1. Retail (Midnight)
    2. WoW: Forever
    3. Classic
2. Which class were you playing
3. How to trigger the bug/crash

The more specific the report is, the easier for me to find the problem and fix
it.

## Current Version: 1.80

* Update to WoW 12.1.0 / Midnight (and the 12.1.5 patch)
* Support for the WoW: Forever beta (1.60.1)
* Works in combat with Midnight's secret values: gauges, sphere text and spell
  cooldowns keep updating in combat, and secure menus open and close in combat
* See [REMOVED_FEATURES.md](REMOVED_FEATURES.md) for what was removed or changed

Updates for LunarSphere are distributed via WowUp and Curseforge. Be sure to
get the latest version here:

* https://wowup.io/addons/1414683
* https://www.curseforge.com/wow/addons/lunarsphere-fan-update


## Special Thanks

My first thanks must go to Moongsaze that coded this amazing addon. I
originally found it when playing WotLK and I think it's one of the most
useful addons I have. Many thanks for the other torch bearers over the years
who kept LS alive: N3od3ath, Toludin-Stormrage, and voyseys.

Many tanks to Zenyari1 for updating LS to Dragonflight and nicodemusmercy for 
helping test it.

Fullmon/Thundermoo/Bloodyaxe-Faerlina
