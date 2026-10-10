-- /***********************************************
--  Lunar Compat Module
--  *********************
--
--  Description	: Version detection, API compatibility wrappers and secret value
--                helpers. Loaded before every other LunarSphere module so the
--                rest of the addon can keep using the legacy call shapes while
--                running on Midnight (12.x), WoW: Forever and the Classic clients.
--
--  ***********************************************/

if (not Lunar) then
	Lunar = {};
end

Lunar.Compat = Lunar.Compat or {};
local Compat = Lunar.Compat;

-- /***********************************************
--  * Client detection
--  *********************

local _, _, _, tocVersion = GetBuildInfo();
Compat.tocVersion = tocVersion or 0;

-- WoW: Forever ("Camelot") reports a 1.6x interface number but runs the modern
-- (Mainline) client and API. Early beta builds reported WOW_PROJECT_ID as the
-- Mainline value, newer builds define WOW_PROJECT_CAMELOT.
Compat.isForever = ((WOW_PROJECT_CAMELOT ~= nil) and (WOW_PROJECT_ID == WOW_PROJECT_CAMELOT))
	or ((Compat.tocVersion >= 16000) and (Compat.tocVersion < 20000));
Compat.isMainline = (not Compat.isForever) and (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE);
Compat.isModern = Compat.isMainline or Compat.isForever;
Compat.isClassicEra = (not Compat.isModern) and (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC);
Compat.isClassic = (not Compat.isModern) and (not Compat.isClassicEra);

-- /***********************************************
--  * Secret value helpers (Midnight)
--  *********************

local issecretvalue = issecretvalue or function() return false; end
Compat.hasSecrets = (_G.issecretvalue ~= nil);

function Compat.IsSecret(value)
	return issecretvalue(value) and true or false;
end

-- Returns true if any of the passed values is a secret
function Compat.AnySecret(...)
	for i = 1, select("#", ...) do
		if issecretvalue((select(i, ...))) then
			return true;
		end
	end
	return false;
end

-- Returns the value if it can be inspected, or the fallback if it's a secret
function Compat.Readable(value, fallback)
	if issecretvalue(value) then
		return fallback;
	end
	return value;
end

-- Text helpers that are safe with secret numbers
function Compat.FloorText(value)
	if C_StringUtil and C_StringUtil.FloorToNearestString then
		return C_StringUtil.FloorToNearestString(value);
	end
	return tostring(math.floor(value));
end

function Compat.CountText(value)
	if issecretvalue(value) and C_StringUtil and C_StringUtil.TruncateWhenZero then
		return C_StringUtil.TruncateWhenZero(value);
	end
	if (not value) or (value == 0) then
		return "";
	end
	return value;
end

-- /***********************************************
--  * Spell API
--  *********************

if C_Spell and C_Spell.GetSpellInfo then
	function Compat.GetSpellInfo(spell)
		if (spell == nil) or (spell == "") then
			return nil;
		end
		local info = C_Spell.GetSpellInfo(spell);
		if (not info) then
			return nil;
		end
		return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID;
	end
else
	Compat.GetSpellInfo = GetSpellInfo;
end

if C_Spell and C_Spell.GetSpellCooldown then
	-- Returns start, duration, enabled, modRate. Values can be secrets in combat.
	function Compat.GetSpellCooldown(spell)
		if (spell == nil) or (spell == "") then
			return nil;
		end
		local info = C_Spell.GetSpellCooldown(spell);
		if (not info) then
			return nil;
		end
		-- Legacy code expects 1/0 for the enabled flag
		local enabled = info.isEnabled;
		if not issecretvalue(enabled) then
			enabled = (enabled and 1) or 0;
		end
		return info.startTime, info.duration, enabled, info.modRate;
	end
else
	Compat.GetSpellCooldown = GetSpellCooldown;
end

-- Returns a duration object usable with Cooldown:SetCooldownFromDurationObject, if
-- the client supports them (Midnight / Forever).
function Compat.GetSpellCooldownDuration(spell, ignoreGCD)
	if C_Spell and C_Spell.GetSpellCooldownDuration and spell and (spell ~= "") then
		return C_Spell.GetSpellCooldownDuration(spell, ignoreGCD);
	end
end

-- The C_Spell functions raise errors on empty spell identifiers, where the old globals
-- quietly returned nil. Wrap them so the legacy behaviour is kept.
local function SafeSpellFunction(func)
	if (not func) then
		return function() return nil; end
	end
	return function(spell, ...)
		if (spell == nil) or (spell == "") or (spell == " ") then
			return nil;
		end
		return func(spell, ...);
	end
end

Compat.GetSpellTexture = SafeSpellFunction((C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture);
Compat.GetSpellLink = SafeSpellFunction((C_Spell and C_Spell.GetSpellLink) or GetSpellLink);
Compat.IsUsableSpell = SafeSpellFunction((C_Spell and C_Spell.IsSpellUsable) or IsUsableSpell);
Compat.IsSpellInRange = SafeSpellFunction((C_Spell and C_Spell.IsSpellInRange) or IsSpellInRange);
Compat.IsCurrentSpell = SafeSpellFunction((C_Spell and C_Spell.IsCurrentSpell) or IsCurrentSpell);
Compat.IsAutoRepeatSpell = SafeSpellFunction((C_Spell and C_Spell.IsAutoRepeatSpell) or IsAutoRepeatSpell);
Compat.IsAttackSpell = SafeSpellFunction((C_Spell and C_Spell.IsAutoAttackSpell) or IsAttackSpell);

function Compat.GetSpellSubtext(spell)
	if C_Spell and C_Spell.GetSpellSubtext then
		return C_Spell.GetSpellSubtext(spell);
	elseif GetSpellSubtext then
		return GetSpellSubtext(spell);
	end
end

function Compat.GetSpellCastCount(spell)
	if C_Spell and C_Spell.GetSpellCastCount then
		return C_Spell.GetSpellCastCount(spell);
	elseif GetSpellCount then
		return GetSpellCount(spell);
	end
	return 0;
end

function Compat.GetSpellIDForSpellIdentifier(spell)
	if (spell == nil) or (spell == "") then
		return nil;
	end
	if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
		return C_Spell.GetSpellIDForSpellIdentifier(spell);
	end
	return select(7, Compat.GetSpellInfo(spell));
end

function Compat.IsSpellKnown(spellID, isPet)
	if C_SpellBook and C_SpellBook.IsSpellKnown then
		local bank = Enum.SpellBookSpellBank and (isPet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player);
		return C_SpellBook.IsSpellKnown(spellID, bank);
	elseif IsSpellKnown then
		return IsSpellKnown(spellID, isPet);
	end
end

-- /***********************************************
--  * Spell book API
--  *********************

Compat.BOOKTYPE_SPELL = (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or BOOKTYPE_SPELL or "spell";
Compat.BOOKTYPE_PET = (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or BOOKTYPE_PET or "pet";

local function ConvertSpellBank(bank)
	if (bank == nil) or (bank == "spell") then
		return Compat.BOOKTYPE_SPELL;
	elseif (bank == "pet") then
		return Compat.BOOKTYPE_PET;
	end
	return bank;
end

function Compat.GetNumSpellTabs()
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
		return C_SpellBook.GetNumSpellBookSkillLines() or 0;
	elseif GetNumSpellTabs then
		return GetNumSpellTabs() or 0;
	end
	return 0;
end

-- Returns name, texture, offset, numSlots, isGuild, offSpecID (legacy shape)
function Compat.GetSpellTabInfo(index)
	if C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
		local info = C_SpellBook.GetSpellBookSkillLineInfo(index);
		if (not info) then
			return nil;
		end
		return info.name, info.iconID, info.itemIndexOffset, info.numSpellBookItems, info.isGuild, info.offSpecID;
	elseif GetSpellTabInfo then
		return GetSpellTabInfo(index);
	end
end

function Compat.GetSpellBookItemName(index, bank)
	if (index == nil) then
		return nil;
	end
	if C_SpellBook and C_SpellBook.GetSpellBookItemName then
		if (type(index) ~= "number") then
			-- Legacy calls passed spell names here. Resolve them into name + subtext.
			local name = Compat.GetSpellInfo(index);
			return name, name and Compat.GetSpellSubtext(index);
		end
		return C_SpellBook.GetSpellBookItemName(index, ConvertSpellBank(bank));
	elseif GetSpellBookItemName then
		return GetSpellBookItemName(index, bank);
	end
end

-- Returns spellType ("SPELL", "FUTURESPELL", "PETACTION", "FLYOUT"), actionID (legacy shape)
local spellBookItemTypeNames;
function Compat.GetSpellBookItemInfo(index, bank)
	if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
		local info = C_SpellBook.GetSpellBookItemInfo(index, ConvertSpellBank(bank));
		if (not info) then
			return nil;
		end
		if (not spellBookItemTypeNames) then
			spellBookItemTypeNames = {};
			if Enum.SpellBookItemType then
				spellBookItemTypeNames[Enum.SpellBookItemType.Spell] = "SPELL";
				spellBookItemTypeNames[Enum.SpellBookItemType.FutureSpell] = "FUTURESPELL";
				spellBookItemTypeNames[Enum.SpellBookItemType.PetAction] = "PETACTION";
				spellBookItemTypeNames[Enum.SpellBookItemType.Flyout] = "FLYOUT";
			end
		end
		return spellBookItemTypeNames[info.itemType], info.actionID or info.spellID, info.spellID;
	elseif GetSpellBookItemInfo then
		return GetSpellBookItemInfo(index, bank);
	end
end

function Compat.GetSpellBookItemTexture(index, bank)
	if (index == nil) then
		return nil;
	end
	if C_SpellBook and C_SpellBook.GetSpellBookItemTexture then
		return C_SpellBook.GetSpellBookItemTexture(index, ConvertSpellBank(bank));
	elseif GetSpellBookItemTexture then
		return GetSpellBookItemTexture(index, bank);
	end
	return GetSpellTexture(index, bank);
end

function Compat.HasPetSpells()
	if C_SpellBook and C_SpellBook.HasPetSpells then
		return C_SpellBook.HasPetSpells();
	elseif HasPetSpells then
		return HasPetSpells();
	end
end

-- /***********************************************
--  * Item API
--  *********************

-- Like the spell functions, the C_Item functions raise errors for empty item names
local function SafeItemFunction(func)
	if (not func) then
		return function() return nil; end
	end
	return function(item, ...)
		if (item == nil) or (item == "") or (item == " ") or (item == "item: ") then
			return nil;
		end
		return func(item, ...);
	end
end

Compat.GetItemInfo = SafeItemFunction((C_Item and C_Item.GetItemInfo) or GetItemInfo);
Compat.IsUsableItem = SafeItemFunction((C_Item and C_Item.IsUsableItem) or IsUsableItem);
Compat.ItemHasRange = SafeItemFunction((C_Item and C_Item.ItemHasRange) or ItemHasRange);
Compat.IsItemInRange = SafeItemFunction((C_Item and C_Item.IsItemInRange) or IsItemInRange);

function Compat.GetItemCount(item, includeBank, includeCharges)
	if (item == nil) or (item == "") then
		return 0;
	end
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(item, includeBank, includeCharges) or 0;
	end
	return GetItemCount(item, includeBank, includeCharges) or 0;
end

function Compat.GetItemSpell(item)
	if (item == nil) or (item == "") then
		return nil;
	end
	if C_Item and C_Item.GetItemSpell then
		return C_Item.GetItemSpell(item);
	end
	return GetItemSpell(item);
end

function Compat.GetItemIcon(item)
	if (item == nil) or (item == "") then
		return nil;
	end
	if C_Item and C_Item.GetItemIconByID then
		return C_Item.GetItemIconByID(item);
	end
	return GetItemIcon(item);
end

function Compat.IsConsumableItem(item)
	if (item == nil) or (item == "") then
		return false;
	end
	if C_Item and C_Item.IsConsumableItem then
		return C_Item.IsConsumableItem(item);
	end
	return IsConsumableItem(item);
end

function Compat.IsEquippedItem(item)
	if (item == nil) or (item == "") then
		return false;
	end
	if C_Item and C_Item.IsEquippedItem then
		return C_Item.IsEquippedItem(item);
	end
	return IsEquippedItem(item);
end

function Compat.GetItemCooldown(item)
	if (item == nil) or (item == "") then
		return 0, 0, 0;
	end
	if C_Item and C_Item.GetItemCooldown then
		local startTime, duration, enable = C_Item.GetItemCooldown(item);
		if (enable == true) then
			enable = 1;
		elseif (enable == false) then
			enable = 0;
		end
		return startTime, duration, enable;
	end
	return C_Container.GetItemCooldown(item);
end

-- /***********************************************
--  * Add-on API
--  *********************

function Compat.GetNumAddOns()
	if C_AddOns and C_AddOns.GetNumAddOns then
		return C_AddOns.GetNumAddOns();
	end
	return GetNumAddOns();
end

-- Returns name, title, notes, isEnabled (bool), loadable
function Compat.GetAddOnInfo(index)
	local name, title, notes, loadable;
	if C_AddOns and C_AddOns.GetAddOnInfo then
		name, title, notes, loadable = C_AddOns.GetAddOnInfo(index);
	else
		name, title, notes, loadable = GetAddOnInfo(index);
	end
	return name, title, notes, Compat.IsAddOnEnabled(name or index), loadable;
end

function Compat.IsAddOnEnabled(addon)
	if C_AddOns and C_AddOns.GetAddOnEnableState then
		return (C_AddOns.GetAddOnEnableState(addon, UnitName("player")) or 0) > 0;
	elseif GetAddOnEnableState then
		return (GetAddOnEnableState(UnitName("player"), addon) or 0) > 0;
	end
	return true;
end

Compat.IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded;
Compat.LoadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn;
Compat.EnableAddOn = (C_AddOns and C_AddOns.EnableAddOn) or EnableAddOn;
Compat.DisableAddOn = (C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn;
Compat.IsAddOnLoadOnDemand = (C_AddOns and C_AddOns.IsAddOnLoadOnDemand) or IsAddOnLoadOnDemand;
Compat.GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata;

-- /***********************************************
--  * Misc API
--  *********************

function Compat.GetMouseFocus()
	if GetMouseFoci then
		return GetMouseFoci()[1];
	end
	return GetMouseFocus();
end

-- Returns x, y (0-1) of the player on the current map, or 0, 0
function Compat.GetPlayerMapPosition()
	if C_Map and C_Map.GetBestMapForUnit then
		local mapID = C_Map.GetBestMapForUnit("player");
		if (mapID) then
			local position = C_Map.GetPlayerMapPosition(mapID, "player");
			if (position) then
				local x, y = position:GetXY();
				return x or 0, y or 0;
			end
		end
		return 0, 0;
	end
	return GetPlayerMapPosition("player");
end

-- Returns name, reaction, minimum, maximum, value, factionID (legacy shape)
function Compat.GetWatchedFactionInfo()
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		local data = C_Reputation.GetWatchedFactionData();
		if (not data) or (not data.name) or (data.name == "") then
			return nil;
		end
		return data.name, data.reaction, data.currentReactionThreshold or 0, data.nextReactionThreshold or 1, data.currentStanding or 0, data.factionID;
	elseif GetWatchedFactionInfo then
		return GetWatchedFactionInfo();
	end
end

-- Returns name, texture, price, quantity, numAvailable (legacy shape)
function Compat.GetMerchantItemInfo(index)
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		local info = C_MerchantFrame.GetItemInfo(index);
		if (not info) then
			return nil;
		end
		return info.name, info.texture, info.price, info.stackCount, info.numAvailable;
	end
	return GetMerchantItemInfo(index);
end

function Compat.GetActiveSpecGroup()
	if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
		return C_SpecializationInfo.GetActiveSpecGroup();
	elseif GetActiveSpecGroup then
		return GetActiveSpecGroup();
	elseif GetActiveTalentGroup then
		return GetActiveTalentGroup();
	end
	return 1;
end

Compat.GetBonusBarOffset = (C_ActionBar and C_ActionBar.GetBonusBarOffset) or GetBonusBarOffset;
Compat.GetActionText = (C_ActionBar and C_ActionBar.GetActionText) or GetActionText;
Compat.GetActionTexture = (C_ActionBar and C_ActionBar.GetActionTexture) or GetActionTexture;

function Compat.GetInventorySlotInfo(slotName)
	if C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo then
		return C_PaperDollInfo.GetInventorySlotInfo(slotName);
	end
	return GetInventorySlotInfo(slotName);
end

-- Returns the auction item class names (weapon, armor, consumable) without the
-- removed GetAuctionItemClasses / GetItemClassInfo globals.
function Compat.GetItemClassName(classID)
	if C_Item and C_Item.GetItemClassInfo then
		return C_Item.GetItemClassInfo(classID);
	elseif GetItemClassInfo then
		return GetItemClassInfo(classID);
	end
end

function Compat.GetItemSubClassName(classID, subClassID)
	if C_Item and C_Item.GetItemSubClassInfo then
		return C_Item.GetItemSubClassInfo(classID, subClassID);
	elseif GetItemSubClassInfo then
		return GetItemSubClassInfo(classID, subClassID);
	end
end

-- Returns the number of available and active quests at the current gossip NPC
function Compat.GetGossipQuestCounts()
	if C_GossipInfo then
		local available = C_GossipInfo.GetNumAvailableQuests and C_GossipInfo.GetNumAvailableQuests() or #(C_GossipInfo.GetAvailableQuests() or {});
		local active = C_GossipInfo.GetNumActiveQuests and C_GossipInfo.GetNumActiveQuests() or #(C_GossipInfo.GetActiveQuests() or {});
		return available, active;
	end
	return select("#", GetGossipAvailableQuests()), select("#", GetGossipActiveQuests());
end

-- Gossip icons that identify "service" gossip options which can be skipped safely
local serviceGossipIcons = {
	[132050] = "banker",
	[132054] = "battlemaster",
	[132057] = "taxi",
	[132058] = "trainer",
	[132060] = "vendor",
};

-- Returns the gossip option to auto-select, if the NPC only offers a single service option
function Compat.GetSkippableGossipOption()
	if not (C_GossipInfo and C_GossipInfo.GetOptions) then
		return nil;
	end
	local options = C_GossipInfo.GetOptions();
	if (not options) or (#options ~= 1) then
		return nil;
	end
	local option = options[1];
	if (option.icon and serviceGossipIcons[option.icon]) or (option.overrideIconID and serviceGossipIcons[option.overrideIconID]) then
		return option.gossipOptionID;
	end
end

-- Character bank containers (bank tabs on Midnight and Forever, legacy bank + bags otherwise)
function Compat.GetBankContainers()
	local containers = {};
	if Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 then
		local first = Enum.BagIndex.CharacterBankTab_1;
		local last = Enum.BagIndex.CharacterBankTab_9 or Enum.BagIndex.CharacterBankTab_6 or first;
		for bagID = first, last do
			if (C_Container.GetContainerNumSlots(bagID) or 0) > 0 then
				table.insert(containers, bagID);
			end
		end
	else
		table.insert(containers, BANK_CONTAINER or -1);
		local bagID;
		for bagID = (NUM_BAG_SLOTS or 4) + 1, (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7) do
			table.insert(containers, bagID);
		end
	end
	return containers;
end

-- Returns the inventory bag ID used by PutItemInBag for one of the player's bags (1-4)
function Compat.GetBagInventoryID(bagID)
	if C_Container and C_Container.ContainerIDToInventoryID then
		return C_Container.ContainerIDToInventoryID(bagID);
	end
	if CharacterBag0Slot then
		return CharacterBag0Slot:GetID() + bagID - 1;
	end
	return 19 + bagID;
end

-- Send a chat message if the client allows add-ons to do so right now
function Compat.SendChatMessage(message, chatType, languageID, target)
	if (message == nil) or (message == "") or issecretvalue(message) or issecretvalue(target) then
		return false;
	end
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		return false;
	end
	if C_ChatInfo and C_ChatInfo.SendChatMessage then
		C_ChatInfo.SendChatMessage(message, chatType, languageID, target);
	else
		SendChatMessage(message, chatType, languageID, target);
	end
	return true;
end

-- /***********************************************
--  * Texture helpers
--  *********************

local PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask";

-- Replacement for the removed SetPortraitToTexture: sets the texture and applies a
-- circular mask so the icon is drawn as a circle.
function Compat.SetPortraitToTexture(texture, file)
	if (not texture) then
		return;
	end
	if (file ~= nil) and (file ~= texture:GetTexture()) then
		texture:SetTexture(file);
	end
	if (texture.AddMaskTexture) and (not texture.lunarCircleMask) then
		local parent = texture:GetParent();
		if (parent) and (parent.CreateMaskTexture) then
			-- Remove the square action button mask from the template, if it's attached
			if (parent.IconMask) and (texture.RemoveMaskTexture) and (parent.icon == texture) then
				texture:RemoveMaskTexture(parent.IconMask);
			end
			local mask = parent:CreateMaskTexture();
			mask:SetTexture(PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
			mask:SetAllPoints(texture);
			texture:AddMaskTexture(mask);
			texture.lunarCircleMask = mask;
		end
	end
end

-- Returns a comparable key for a texture. Modern clients report textures as file IDs,
-- while LunarSphere's templates store texture paths, so paths are converted to their
-- file ID (when the client knows the file).
local scratchFrame, scratchTexture;
function Compat.NormalizeTexture(texture)
	if (texture == nil) or (texture == "") or (texture == " ") then
		return "";
	end
	if (type(texture) == "number") then
		return tostring(texture);
	end
	if (tonumber(texture)) then
		return texture;
	end
	if (not scratchTexture) then
		scratchFrame = CreateFrame("Frame");
		scratchFrame:Hide();
		scratchTexture = scratchFrame:CreateTexture();
	end
	scratchTexture:SetTexture(nil);
	scratchTexture:SetTexture(texture);
	local fileID = scratchTexture:GetTexture();
	if (type(fileID) == "number") then
		return tostring(fileID);
	end
	return string.lower(texture);
end

-- /***********************************************
--  * Micro menu buttons (menu bar button types)
--  *********************

local menuBarButtons = {
	[100] = {"CharacterMicroButton"},
	[101] = {"SpellbookMicroButton", "PlayerSpellsMicroButton"},
	[102] = {"TalentMicroButton", "PlayerSpellsMicroButton"},
	[103] = {"QuestLogMicroButton"},
	[104] = {"GuildMicroButton", "SocialsMicroButton"},
	[105] = {"LFDMicroButton", "LFGMicroButton"},
	[106] = {"MainMenuMicroButton"},
	[107] = {"HelpMicroButton"},
	[108] = {"AchievementMicroButton"},
};

-- Returns a secure "/click" macro for the given menu bar button type, if the matching
-- Blizzard micro menu button exists on this client.
function Compat.GetMenuBarMacro(buttonType)
	if (not Compat.isModern) then
		return nil;
	end
	local candidates = menuBarButtons[buttonType];
	if (candidates) then
		local _, name;
		for _, name in ipairs(candidates) do
			if (_G[name]) then
				return "/click " .. name;
			end
		end
	end
end
