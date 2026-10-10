-- /***********************************************
--  Lunar API Module
--  *********************
--
--  Author	: Moongaze (Twisting Nether)
--  Description	: Handles various functions that are fairly generic and
--                used by most other modules. Contains chat, frame handling,
--                and some texture methods
--
--  ***********************************************/

-- ~50k memory might be saved with memory management feature

-- /***********************************************
--  * Module Setup
--  *********************

-- Create our Lunar object if it's not made
if (not Lunar) then
	Lunar = {};
end

-- Add our API module to Lunar
if (not Lunar.API) then
	Lunar.API = {};
end

-- Set our current version for the module (used for version checking later on)
Lunar.API.version = 1.80;

-- Set our default chat printing colors
Lunar.API.chatRed	= 0.3;
Lunar.API.chatGreen	= 0.7;
Lunar.API.chatBlue	= 1.0;

-- Set our default settings
Lunar.API.junkSaleText = "Junk vendored:";
Lunar.API.repairCostText = "Repair cost:";
Lunar.API.enableMinimapText = nil;
Lunar.API.updateTimer = 0;
Lunar.API.minimapTimeOffset = 0;
Lunar.API.lastPurchaseTime = nil;
Lunar.API.BlankFunction = function () end;
--Lunar.Items.UpdateBagContents = Lunar.API.BlankFunction;

-- Create our money tracker
Lunar.API.moneyTracker = CreateFrame("GameTooltip", "LunarAPIMoneyTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate, GameTooltipTemplate");

--Lunar.API.moneyTracker:SetScript("OnTooltipAddMoney", function(self, arg1) Lunar.API.sellPrice = arg1 end)
Lunar.API.sellPrice = nil;

-- Create our mail event watcher
Lunar.API.eventWatcher = CreateFrame("Frame", "LunarAPIEventWatcher", UIParent, BackdropTemplateMixin and "BackdropTemplate");

Lunar.API.eventWatcher:SetWidth(1);
Lunar.API.eventWatcher:SetHeight(1);
Lunar.API.eventWatcher:EnableMouse(false);
Lunar.API.eventWatcher:SetAlpha(0);
Lunar.API.eventWatcher.tempTexture = Lunar.API.eventWatcher:CreateTexture("LSEventWatcherTexture");
Lunar.API.eventWatcher:Show();

-- Define global variables for the path of LunarSphere, its art, and the import folder
LUNAR_ADDON_PATH = "Interface\\AddOns\\LunarSphere";
LUNAR_ART_PATH = "Interface\\AddOns\\LunarSphere\\Art\\";
LUNAR_IMPORT_PATH = "Interface\\AddOns\\LunarSphere\\Imports\\";
--LUNAR_IMPORT_PATH = "Interface\\AddOns\\LunarSphereImports\\";

-- Define a static variable for extra icons we have. 2 icons are the player
-- portrait, 13 are the class icons, and 2 are the faction icons
LUNAR_EXTRA_SPHERE_ICON_COUNT = 17;

-- Create our debug tooltip
Lunar.API.debugFrameOver = _G["LSmain"];
Lunar.API.debugTooltipTimer = 0;
Lunar.API.debugTooltip = CreateFrame("GameTooltip", "LunarAPIDebugTooltip", UIParent, BackdropTemplateMixin and "BackdropTemplate, GameTooltipTemplate");
 
Lunar.API.debugTooltipUpdater = CreateFrame("Frame", "LunarAPIDebugTooltipUpdater", UIParent, BackdropTemplateMixin and "BackdropTemplate");

-- Client API compatibility (see moduleCompat.lua)
local Compat = Lunar.Compat;
local GetSpellLink = Compat.GetSpellLink;
local GetSpellInfo = Compat.GetSpellInfo;
local GetSpellSubtext = Compat.GetSpellSubtext;
local GetNumSpellTabs = Compat.GetNumSpellTabs;
local GetSpellTabInfo = Compat.GetSpellTabInfo;
local GetItemInfo = Compat.GetItemInfo;
local GetItemCount = Compat.GetItemCount;
local GetNumAddOns = Compat.GetNumAddOns;
local GetAddOnInfo = Compat.GetAddOnInfo;
local EnableAddOn = Compat.EnableAddOn;
local DisableAddOn = Compat.DisableAddOn;
local IsAddOnLoadOnDemand = Compat.IsAddOnLoadOnDemand;
local GetWatchedFactionInfo = Compat.GetWatchedFactionInfo;
local GetMerchantItemInfo = Compat.GetMerchantItemInfo;
local GetBonusBarOffset = Compat.GetBonusBarOffset;
local BOOKTYPE_SPELL = Compat.BOOKTYPE_SPELL;

-- List of functions that are OK
-- * GetSpellBookItemName, C_SpellBook.GetSpellBookItemName
-- * IsUsableSpell, C_Spell.IsSpellUsable (gotta love the name change)
-- * IsAttackSpell, C_Spell.IsAutoAttackSpell
-- * IsCurrentSpell, C_Spell.IsCurrentSpell
-- * IsAutoRepeatSpell, C_Spell.IsAutoRepeatSpell

do
	local return_type_db = {}
	if C_Spell.GetSpellCooldown then
		return_type_db[C_Spell.GetSpellCooldown] = "SpellCooldownInfo"
	end
	if C_Spell.GetSpellInfo then
		return_type_db[C_Spell.GetSpellInfo] = "SpellInfo"
	end
	if C_SpellBook.GetSpellBookSkillLineInfo then
		return_type_db[C_SpellBook.GetSpellBookSkillLineInfo] = "SpellBookSkillLineInfo"
	end
	if C_Reputation.GetFactionDataByID then
		return_type_db[C_Reputation.GetFactionDataByID] = "FactionData"
	end

	if C_SpellBook.GetSpellBookItemInfo then
		return_type_db[C_SpellBook.GetSpellBookItemInfo] = "SpellBookItemInfo"
	end

	local key_db = {}
	key_db["SpellCooldownInfo"] = {"startTime", "duration", "isEnabled", "modRate"}
	key_db["SpellInfo"] = {"name", "rank", "iconID", "castTime", "minRange", "maxRange", "spellID", "originalIconID"}
	key_db["SpellBookSkillLineInfo"] = {"name", "iconID", "itemIndexOffset", "numSpellBookItems", "isGuild", "offSpecID"}
	key_db["FactionData"] = { 
		"name", "description", "currentStanding", "currentReactionThreshold", "nextReactionThreshold",
		"currentStanding", "atWarWith", "canToggleAtWar", "isHeader", "isCollapsed", "isHeaderWithRep", 
		"isWatched", "isChild", "factionID", "hasBonusRepGain", "canSetInactive", "canSetInactive"}
	key_db["SpellBookItemInfo"] = {"actionID", "itemType"}

	function Lunar.API:Deconfabulate(original_fn)

		local return_type = return_type_db[original_fn]
		local keys = key_db[return_type]

		if (not original_fn) or (not keys) then
			return function () return nil end
		end

		return function (...)
			local tbl = original_fn(...)
			if not tbl then
				return nil
			end
			local tmp = {}
			for idx, key in ipairs(keys) do
				tmp[idx] = tbl[key]
			end
			return unpack(tmp)
		end
	end
end

Lunar.API.debugTooltipUpdater:SetScript("OnUpdate", function(self, arg1)
	if not (LunarSphereSettings.showDebugTooltip == true) then
		return;
	end
	if not (Lunar.API.debugTooltipFunction) then
		local errorMessage, success;
		Lunar.API.debugTooltipFunction, errorMessage = loadstring("local a1, a2, a3, a4, a5, a6, a7, a8, a9, frame; frame = Lunar.API.debugFrameOver; if frame then " .. LunarSphereSettings.debugTooltipCode .. " end; return a1, a2, a3, a4, a5, a6, a7, a8, a9;");
		if (not Lunar.API.debugTooltipFunction) then
			Lunar.API:Print("LunarSphere: Debug Tab Function Error - The Debug function string set in the debug tab is invalid");
			LunarSphereSettings.showDebugTooltip = nil;
			_G["LSSettingsshowDebugTooltip"]:SetChecked(false);
		end
		local success, errorMessage = pcall(Lunar.API.debugTooltipFunction);
		if (not success) then
			Lunar.API:Print("LunarSphere: Debug Tab Function Error - " .. errorMessage);
			LunarSphereSettings.showDebugTooltip = nil;
			_G["LSSettingsshowDebugTooltip"]:SetChecked(false);
		end
	end

	Lunar.API.debugTooltipTimer = Lunar.API.debugTooltipTimer + arg1;

	if (Lunar.API.debugTooltipTimer > 0.3) then
		Lunar.API.debugTooltipTimer = 0;
		Lunar.API.debugFrameOver = Compat.GetMouseFocus();
		Lunar.API.debugTooltip:Hide();
		if (IsControlKeyDown() and IsAltKeyDown() and Lunar.API.debugFrameOver) then
			Lunar.API.debugTooltip:ClearLines();
			local a1, a2, a3, a4, a5, a6, a7, a8, a9 = Lunar.API:debugTooltipFunction()
			Lunar.API.debugTooltip:SetOwner(Lunar.API.debugFrameOver, "ANCHOR_CURSOR");
--			Lunar.API.debugTooltip:SetSpellBookItem(1, "spell");
			Lunar.API.debugTooltip:AddLine("Frame: " .. tostring(Lunar.API.debugFrameOver:GetName()));
			if (Lunar.API.debugFrameOver:GetParent()) then
				Lunar.API.debugTooltip:AddLine("Parent: " .. tostring(Lunar.API.debugFrameOver:GetParent():GetName()));
			end
			Lunar.API.debugTooltip:AddLine("Arg1: " .. tostring(a1));
			Lunar.API.debugTooltip:AddLine("Arg2: " .. tostring(a2));
			Lunar.API.debugTooltip:AddLine("Arg3: " .. tostring(a3));
			Lunar.API.debugTooltip:AddLine("Arg4: " .. tostring(a4));
			Lunar.API.debugTooltip:AddLine("Arg5: " .. tostring(a5));
			Lunar.API.debugTooltip:AddLine("Arg6: " .. tostring(a6));
			Lunar.API.debugTooltip:AddLine("Arg7: " .. tostring(a7));
			Lunar.API.debugTooltip:AddLine("Arg8: " .. tostring(a8));
			Lunar.API.debugTooltip:AddLine("Arg9: " .. tostring(a9));
			Lunar.API.debugTooltip:Show();
--			Lunar.API.debugTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 30);
-- a1 = frame:GetID();
-- a2 = frame.currentStance;
-- a3 = Lunar.Button:GetAssignedStance(frame);
-- a4 = Lunar.Button:GetButtonSetting(a1, a2, LUNAR_GET_SHOW_COOLDOWN);
-- a5 = frame.cooldownID;
-- a6 = Lunar.Button:GetButtonData(a1, a2, a4);
-- a7 = frame.actionNameCooldown;
-- a8 = frame.cooldownText:GetText();
-- a9 = frame.cooldownTextFrame:IsVisible();

-- a1 = frame:GetID(); a2 = frame.currentStance; a3 = Lunar.Button:GetAssignedStance(frame); a4 = Lunar.Button:GetButtonSetting(a1, a2, LUNAR_GET_SHOW_COOLDOWN); a5 = frame.cooldownID; a6 = Lunar.Button:GetButtonData(a1, a2, a4); a7 = frame.actionNameCooldown; if frame.cooldownText then a8 = frame.cooldownText:GetText(); a9 = frame.cooldownTextFrame:IsVisible(); end; 
		end

	end
end);
Lunar.API.debugTooltipUpdater:SetPoint("TOPLEFT");
Lunar.API.debugTooltipUpdater:SetWidth(1);
Lunar.API.debugTooltipUpdater:SetHeight(1);
Lunar.API.debugTooltipUpdater:Show();

-- /***********************************************
--  * Functions
--  *********************

--[[function Lunar.API:RegisterForMemoryWipe(moduleName, functionName)

	if (not Lunar.API.wipeData) then
		Lunar.API.wipeData = {};
	end

	table.insert(Lunar.API.wipeData, {moduleName, functionName});
	
end

function Lunar.API:MemoryWipe()
	
	Lunar.API:RegisterForMemoryWipe("API", "RegisterForMemoryWipe")

	for index = 1, table.getn(Lunar.API.wipeData) do
		Lunar[ Lunar.API.wipeData[index][1] ][ Lunar.API.wipeData[index][2] ] = nil;
	end
	
	Lunar.API.wipeData = nil;
	
end
--]]

-- /***********************************************
--   Debug
--
--   Drops a line into the chat frame while debug mode is on
--
--   accepts:	text to write
--   returns:	none
--  *********************/
function Lunar.Debug(text)

	-- Send the message if debug mode is on
	if (LunarSphereGlobal.debugModeOn == true) and (text) then
		DEFAULT_CHAT_FRAME:AddMessage("LS Debug: |cFFFFFFFF" .. text, 0.3, 0.3, 0.7);
	end
end

-- /***********************************************
--   CreateFrame
--
--   Creates a frame based on parameters passed
--
--   accepts:	frame type, frame name, frame's parent, width and height of the frame, the texture file to
--		use, if it will use mouse input, and an ID for the frame
--   returns:	a frame
--  *********************/
function Lunar.API:CreateFrame(frameType, frameName, frameParent, width, height, textureFile, enableMouse, ID)

	-- create a temp frame
	local tempFrame;

	-- Parse the texture file for the "$addon" string and replace it with the addon's path
	if (textureFile) then
		textureFile = string.gsub(textureFile, "$addon", LUNAR_ADDON_PATH);
	end

	-- Create a frame with the details provided
	tempFrame = CreateFrame(frameType, frameName, frameParent, BackdropTemplateMixin and "BackdropTemplate");

	tempFrame:SetWidth(width);
	tempFrame:SetHeight(height);
	tempFrame:EnableMouse(enableMouse);
	tempFrame:SetID(ID);

	-- If the frame was a button, load the texture.
	if frameType == "Button" then
		tempFrame:SetNormalTexture(textureFile);
	end

	-- Return our new frame
	return tempFrame;

end

function Lunar.API:CopyTable(sourceTable)

	local key, value;
	local newTable = {};

	for key, value in pairs(sourceTable) do
		if (type(value) == "table") then
			newTable[key] = Lunar.API:CopyTable(value);
		else
			newTable[key] = value;
		end
	end

	return newTable;

end

function Lunar.API:ConvertClick(clickName)
	local clickType;

	if (clickName == "RightButton") then
		clickType = 2;
	elseif (clickName == "MiddleButton") then
		clickType = 3;
	-- The following work (clickName is indeed Button4 and Button5) but aren't yet supported in the addon
--	elseif ( clickName == "Button4" ) then
--		clickType = 4;
--	elseif ( clickName == "Button5" ) then
--		clickType = 5;
	else
		clickType = 1;
	end

	return clickType;
	
end

function Lunar.API:FixFaerie(actionName)

	if (actionName) then
--		if string.find(actionName, "(", nil, true)  then
		if (string.find(actionName, "%(")) then
			if not string.find(actionName, "%((.*)%(")  then
				return actionName .. "()";
			end
		end
--		else
--			return actionName;
--		end
	end

	return actionName;
	
end

-- /***********************************************
--   RotateTexture
--
--   Rotates the texture to the specified angle
--
--   accepts:	texture to rotate, degrees to set it to, the x origin, the y origin
--   returns:	none
--  *********************/
function Lunar.API:RotateTexture(tex, degrees, xOrigin, yOrigin)

	-- Convert the degrees into radians. We want to make 0 degrees pointing straight up as well.
	-- To do this, we offset the degrees by 135 and inverse the radians
	local radians = -math.rad(degrees - 135 );

	-- Locate the rotated point's sine and cosine, factored to the size we have
	local sin = math.sin(radians) * 0.71;
	local cos = math.cos(radians) * 0.71;

	-- Set the new coordinates, with the rotation coming from the origin (0.5, 0.5 ... the center of the image)
	tex:SetTexCoord(xOrigin - sin, yOrigin + cos, xOrigin + cos, yOrigin + sin, xOrigin - cos, yOrigin - sin, xOrigin + sin, yOrigin - cos);

end

-- /***********************************************
--   Print
--
--   Drops a line into the chat frame in a specified color
--
--   accepts:	text to write, red, green, and blue values (0.0 - 1.0)
--   returns:	none
--  *********************/
function Lunar.API:Print(text, red, green, blue)

	-- If no color values were passed, we used the defaults defined at the start of the
	-- module
	if (not red) then
		red = Lunar.API.chatRed;
		green = Lunar.API.chatGreen;
		blue = Lunar.API.chatBlue;
	end

	-- Send the message
	DEFAULT_CHAT_FRAME:AddMessage(text, red, green, blue);

end

function Lunar.API:GetItemBagInfo(itemName)
	local bagID, slotID, slotTotal, locked, searchName, count, stackSize, itemLink;
	local returnBag, returnSlot, returnCount, returnSize;
--	largestCount = 0;

	for bagID = 0, 4  do 
		slotTotal = Lunar.Items:GetContainerNumSlots(bagID);
		for slotID = 1, slotTotal do 
			itemLink = Lunar.Items:GetContainerItemLink(bagID, slotID);
			if (itemLink) then
				searchName, _, _, _, _, _, _, stackSize = GetItemInfo(itemLink);
				if (itemName == searchName)  then
					_, count, locked = Lunar.Items:GetContainerItemInfo(bagID, slotID);
					if not locked then
						if ((returnCount or (0)) < count) then
							returnBag = bagID;
							returnSlot = slotID;
							returnCount = count;
							returnSize = stackSize;
						end
--						return bagID, slotID, count, stackSize;
					end
				end
			end
		end
	end
	return returnBag, returnSlot, returnCount, returnSize;

end

function Lunar.API:GetItemID(itemLink)

	-- If the link doesn't exit, end now
	if not (itemLink) then
		return nil;
	end

	-- Set our locals and grab part of the link that we'll look at
	local itemID = nil;
	local locIndex = string.find(itemLink, "item:");

	-- If we have something to work with, continue
	if (locIndex) then

		-- Find the location of the itemID. If it exists, grab it
		itemLink = string.sub(itemLink, locIndex + 5);
		locIndex = string.find(itemLink, ":");
		if (locIndex) then
			itemID = tonumber(string.sub(itemLink, 1, locIndex-1));
		else
			itemID = tonumber(itemLink);
		end
	else
		-- It might already be the itemID that was passed, so we check
		-- if the string is all numbers. If so, return the number as a number
		if (string.find(itemLink, "%a") == nil) then
			itemID = tonumber(itemLink);
		end
	end

	-- Return our results
	return itemID;
end

-- /***********************************************
--   FilterCooldown
--
--   Takes a start time and the duration of the cooldown and returns a value
--   in an easy-to-read format (hours, minutes, or seconds)
--
--   accepts:	startTime and duration of cooldown
--   returns:	formatted text of the cooldown (##, ##m, ##h)
--  *********************/
function Lunar.API:FilterCooldown(startTime, duration)

	-- Create our local
	local tempCooldown = nil;

	-- If there is a start time and duration (i.e., not null), continue
	if (startTime) and (duration) then

		-- Calculate how many seconds we have left
		if not (duration == 0) then
			tempCooldown = duration - (GetTime() - startTime);
		end

	-- If only one item was passed, assume it was the originally
	-- calculated cooldown in seconds and continue
	elseif (startTime) and (not duration)  then
	
		tempCooldown = startTime;

	end

	-- If we still have a tempCooldown to work with, continue
	if (tempCooldown) then

		-- If there is at least 1 second, format the string to show the number
		-- of hours, minutes, or seconds left (whichever is larger)
		if (tempCooldown > 0) then
			if (tempCooldown > 3600) then
				tempCooldown = tostring(math.ceil(tempCooldown / 3600)) .. "h";
			elseif (tempCooldown > 60) then
				tempCooldown = tostring(math.ceil(tempCooldown / 60)) .. "m";
			else
				tempCooldown = tostring(math.ceil(tempCooldown));
			end
		else
			tempCooldown = "0";
		end

	end
	
	-- Return our results
	return tempCooldown;
end

-- /***********************************************
--   GetSpellID
--
--   Something I wish Blizzard had in their API. Takes a spell name and spits out
--   the spellbook ID of that spell
--
--   accepts:	name of spell
--   returns:	spellbook ID of spell, rank of spell
--  *********************/
function Lunar.API:GetSpellID(spellName)
	-- Create our locals
	local index, spellsInTab, spellID;
	local spellRankNumber, spellRank, filterName;
	local totalSpells, rankFound = 0, 0;

	local scanName, scanRank;

	-- Separate part of the spell name from the rank;
	spellName = string.lower(spellName or (""));
	filterName = string.match(spellName, "(.*)%(");
	filterName = filterName or spellName;

	-- If the spell name exists, grab the rank if it also exists and convert it to a number
	if (filterName) and (filterName) ~= "" then
		spellRankNumber = string.match(spellName, "(%d)");
		if (spellRankNumber) then
			spellRankNumber = tonumber(spellRankNumber);
		end
		spellRank = string.match(spellName, "%((.*)%)");
--		if (spellRank) then
--			spellRank = spellRank;
--		end
	end

	-- Obtain the total number of spells the player knows
	totalSpells = Lunar.API:CountTotalSpells()

-- Fix for people who don't put the ";" at the end of the macro ... if I want to include it
--
--	if (string.sub(spellName, string.len(spellName)) == "\n") then
--		spellName = string.sub(spellName, 1, string.len(spellName) - 1);		
--	end

	-- Search every spell in player's spellbook. If the name matches our
	-- spell that we're searching for, save the ID...
	for index = 1, totalSpells do
		scanName, scanRank = Lunar.API:GetSpellBookItemName(index, BOOKTYPE_SPELL);
		scanName = scanName or "";
		scanRank = scanRank or "";
		if (string.lower(scanName) == filterName) then

			spellID = index;

			-- Track the current rank of the spell. If we hit the rank
			-- we're looking for, if it exists, exit now
			rankFound = rankFound + 1;
			if (spellRank) and (string.lower(scanRank) == spellRank) then
				break;
			end
		else
			-- If our spell was found and we're still searching, we stop searching
			-- when we find the first spell after the one we found
			if (spellID) then
				break;
			end
		end
	end

	-- Return our results
	return spellID, spellRank;
	
end

function Lunar.API:IsInAQ()
	-- End now if we're not in an instance
	if (not IsInInstance()) then
		return false;
	end
	
	if C_Map.GetBestMapForUnit("player") == 320 then -- 320 is map ID for Temple of Ahn'Qiraj
		return true
	else
		return false
	end
end

-- /***********************************************
--   MemoryUsage
--
--   Another way to query how much memory this addon is taking up
--
--   accepts:	none
--   returns:	bytes taken up in memory
--  *********************/
function Lunar.API:MemoryUsage()

	-- Update the internal database of memory values
	UpdateAddOnMemoryUsage();

	-- Return our memory usage
	return math.floor(GetAddOnMemoryUsage("LunarSphere") * 10)/10;
	
end

-- /***********************************************
--   PrintMemoryStats
--
--   Dumps a list of all addons loaded in memory, along with how
--   much memory they are using, into the chat frame
--
--   accepts:	none
--   returns:	none
--  *********************/
function Lunar.API:PrintMemoryStats()

	-- Set our sorted table and index counter up
	local sortTable = {};
	local i; 
	local totalKB = 0;

	-- If we got addons, we're good to go!
	if GetNumAddOns() > 0 then

		-- Clean the garbage first
		collectgarbage();

		-- Update the current memory usage
		UpdateAddOnMemoryUsage();

		-- Set our locals for the addons
		local addonCount, name, enabled, loadable, usedKB
		
		addonCount = 1;

		-- Populate our sorted addon list with addons that are enabled
		for i = 1, GetNumAddOns() do

			-- Pull addon info
			name, _, _, enabled, loadable, _, _ = GetAddOnInfo(i);

			-- If it's enabled ...
			if (enabled) then

				-- Grab how much memory the addon uses. If it uses more than 0kb
				-- of memory, we dump it into the list and update our counter.
				-- We do this because 0kb means it's loaded, but "by demand"
				usedKB = GetAddOnMemoryUsage(name);
				if (usedKB > 0) then
					sortTable[addonCount] = string.lower(name) .. ": " .. tostring(math.floor(usedKB * 10)/10) .. "kb";
					addonCount = addonCount + 1;
					totalKB = totalKB + usedKB;
				end
			end

		end

		-- Sort our addons
		table.sort(sortTable);

	end

	-- If we have some data, print it out!
	if (sortTable) then
		for i = 1, table.getn(sortTable) do 
			Lunar.API:Print(sortTable[i]);
		end
		Lunar.API:Print("===================================");
		Lunar.API:Print("All addons: " .. tostring(math.floor(totalKB * 10)/10) .. "kb");
	end

	
	-- Set our table to nothing and collect the garbage we just made from
	-- the deleted table (keeping the memory usage down), and then dump the garbage again...
	sortTable = nil;

	collectgarbage();
end

-- /***********************************************
--   GetMemoryTable
--
--   Populates a table with a list of all addons loaded and how
--   much memory it is taking up
--
--   accepts:	none
--   returns:	table, sorted, of all addons loaded
--  *********************/
function Lunar.API:GetMemoryTable()

	-- Set our sorted table up
	local sortTable = {};

	-- If we got addons, we're good to go!
	if GetNumAddOns() > 0 then

		-- Update the current memory usage
		UpdateAddOnMemoryUsage();

		-- Set our locals for the addons
		local addonCount, name, enabled, loadable, usedKB;
		
		addonCount = 1;

		-- Populate our sorted addon list with addons that are enabled
		for i = 1, GetNumAddOns() do

			-- Pull addon info
			name, _, _, enabled, loadable, _, _ = GetAddOnInfo(i);

			-- If it's enabled ...
			if (enabled) then

				-- Grab how much memory the addon uses. If it uses more than 0kb
				-- of memory, we dump it into the list and update our counter.
				-- We do this because 0kb means it's loaded, but "by demand"
				usedKB = GetAddOnMemoryUsage(name);
				if (usedKB > 0) then
					sortTable[addonCount] = string.lower(name) .. ": " .. tostring(math.floor(usedKB * 10)/10) .. "kb";
					addonCount = addonCount + 1;
				end
			end

		end

		-- Sort our addons
		table.sort(sortTable);

	end

	return sortTable;
end

--function Lunar.API:MemoryLoader()

-- /***********************************************
--   ToggleActiveAddons
--
--   Scans all addons and will either turn off all active addons and populate
--   a table of data with the addon names, or turn on all addons in the table
--   of addon names. This is to make peoples' lives easier while testing
--   LunarSphere.
--
--   accepts:	toggle (true = turn saved list of addons on, false = turn them off)
--   returns:	none
--  *********************/
function Lunar.API:ToggleActiveAddons(toggle)

	-- If we have no addons to turn on, leave now

	if (toggle == true) and not (LunarSphereSettings.debugAddonList) then
		return;
	end

	-- Ensure we have a table to add to if we are to turn stuff off.

	if (toggle ~= true) then
		LunarSphereSettings.debugAddonList = {};
	end

	-- If we got addons, we're good to go!

	if GetNumAddOns() > 0 then

		-- Set our locals for the addons

		local name, enabled, index;
		local loadable;

		-- Search through each addon for the user

		for i = 1, GetNumAddOns() do

			-- Pull addon info

			name, _, _, enabled, loadable = GetAddOnInfo(i);

			-- If the addon is turned on and we're toggling all addons off, add the
			-- addon to the saved addon list and turn it off. We will skip all
			-- LunarSphere addons though, since those need to stay on.

			if (enabled) and (toggle ~= true) and not string.find(name, "LunarSphere") and not (IsAddOnLoadOnDemand(i)) then
				
				table.insert(LunarSphereSettings.debugAddonList, name);
				DisableAddOn(name);

			-- If the addon is not enabled, and we're toggling all addons on that
			-- were toggled off from a previous call to this function, search our
			-- saved addon list and see if this addon exists. If so, remove it from
			-- the list and turn it on.

			elseif (not enabled) and (toggle == true) then

				for index = 1, table.getn(LunarSphereSettings.debugAddonList) do
					if (name == LunarSphereSettings.debugAddonList[index]) then
						EnableAddOn(name);
						table.remove(LunarSphereSettings.debugAddonList, index);
						break;
					end
				end

			end

		end

		-- If we're turning our saved addons on, wipe our table since we're done with it

		if (toggle == true) then
			LunarSphereSettings.debugAddonList = nil;
		end

		ReloadUI();

	end
end

function Lunar.API:MultiAddToTooltip(actionType, actionName, index, firstLineAppend)

	-- Set our locals up
	local textLine, textContainer, textContainerRight, r1, g1, b1, r2, g2, b2, longText;
	local itemString, spellID, spellRank, tipText, tipTextRight, isYellow, isGreen, showLine;
	local macroCommand, canAutoCast;

	-- Set our tooltip up
	Lunar.Items.tooltip:ClearLines();
	Lunar.Items.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
	
	if (not firstLineAppend) then
		firstLineAppend = "";
	end

	if (actionType ~= "pet") then
		Lunar.Items.tooltip:AddLine(actionName);
	end

	if (actionType == "spell") then
--		spellID, spellRank = Lunar.API:GetSpellID(actionName);

		spellID = GetSpellLink(actionName);
		--_, spellRank = GetSpellBookItemName(actionName);
		if (not Lunar.API:IsVersionClassicEra() and spellID and (spellID:len() > 0)) then
			Lunar.Items.tooltip:SetHyperlink(spellID);
		end

--		Lunar.Items.tooltip:SetHyperlink(GetSpellLink(actionName));		
--		if (spellID) then
--			Lunar.Items.tooltip:SetSpellBookItem(spellID, BOOKTYPE_SPELL);
--		end
	
	elseif (actionType == "item") then
		
		if actionName and not ((actionName == "") or (actionName == " ")) then
			_, itemString = GetItemInfo(actionName);
			if (itemString) then
				Lunar.Items.tooltip:SetHyperlink(itemString);
			end
		end

	elseif (actionType == "pet") then
		local petID = tonumber(actionName);
		local name, subText, texture, isToken, _, canAuto = GetPetActionInfo(petID);
		canAutoCast = canAuto;		

		if ( not isToken ) then
--			if (canAutoCast) then
--				Lunar.Items.tooltip:AddLine(name .. "  |cFF00EE00" .. "[" .. Lunar.Locale["_SHIFT_TOGGLE"] .. "]|r");
--			else
--				Lunar.Items.tooltip:AddLine(name);
--			end
			Lunar.Items.tooltip:SetPetAction(petID);
		else
			Lunar.Items.tooltip:SetText(_G[name], 1.0, 1.0, 1.0);
			if (subText) then
				Lunar.Items.tooltip:AddLine(subText, "", 0.5, 0.5, 0.5);
			end
			macroCommand = true;
		end
	else
		local macroBody, objectName;
		_,_, macroBody = GetMacroInfo(actionName);
		objectName = GetActionFromMacroText(macroBody);

		if (objectName) then
			_, itemString = GetItemInfo(objectName);
			if (itemString) then
				Lunar.Items.tooltip:SetHyperlink(itemString);
			else
				spellID, spellRank = Lunar.API:GetSpellID(objectName);

				if (spellID) then
					Lunar.Items.tooltip:SetSpellBookItem(spellID, BOOKTYPE_SPELL);
				end
			end
		else
			macroCommand = true;	
		end
	end

	for textLine = 1, Lunar.Items.tooltip:NumLines() do
								
		textContainer = _G[Lunar.Items.tooltip:GetName() .. "TextLeft" .. textLine];
		textContainerRight = _G[Lunar.Items.tooltip:GetName() .. "TextRight" .. textLine];
		tipText = textContainer:GetText();
		tipTextRight = textContainerRight:GetText();

		-- Tooltip lines can contain secret values while in combat on Midnight. We can't
		-- inspect them, so add a placeholder line and hand the secret text to its
		-- font string (FontString:SetText accepts secret values).
		if Compat.AnySecret(tipText, tipTextRight) then
			if (tipText) then
				GameTooltip:AddLine(" ", 1, 1, 1, true);
				local line = _G["GameTooltipTextLeft" .. GameTooltip:NumLines()];
				if (line) then
					line:SetText(tipText);
				end
			end
			tipText = nil;
		elseif (textLine == 1) then
			tipText = tipText .. firstLineAppend;
			if (spellID) then
--				_, tipTextRight = GetSpellBookItemName(spellID, BOOKTYPE_SPELL);
				tipTextRight = spellRank;
				textContainerRight:SetTextColor(0.5,0.5,0.5);
			end
		end
		if (tipText) then
			r1,g1,b1 = textContainer:GetTextColor();
			if Compat.AnySecret(r1, g1, b1) then
				r1, g1, b1 = 1, 1, 1;
			end
			isYellow = (r1 > 0.8) and (g1 > 0.8) and (b1 < 0.2);
			isGreen =  (g1 > 0.8) and (r1 < 0.2) and (b1 < 0.2);
			showLine = true;
			if (textLine > 1) then
				longText = (string.len(tipText) > 80);
				if (isYellow) and ( (LunarSphereSettings.tooltipType == 3) or 
					((LunarSphereSettings.hideYellowTooltips == true) and ((LunarSphereSettings.yellowTooltipType == 0) or ((LunarSphereSettings.yellowTooltipType == 1) and (longText == true))))) then
					showLine = false;
				elseif (isGreen) and ( (LunarSphereSettings.tooltipType == 3) or 
					((LunarSphereSettings.hideGreenTooltips == true) and ((LunarSphereSettings.greenTooltipType == 0) or ((LunarSphereSettings.greenTooltipType == 1) and (longText == true))))) then
					showLine = false;
				end
			end
			if (showLine) then
				if (tipTextRight) then
					r2,g2,b2 = textContainerRight:GetTextColor();
					if Compat.AnySecret(r2, g2, b2) then
						r2, g2, b2 = 1, 1, 1;
					end
					GameTooltip:AddDoubleLine(tipText, tipTextRight, r1, g1, b1, r2, g2, b2);
				else
					GameTooltip:AddLine(tipText, r1, g1, b1, true);
				end
			end
			if (textLine == 1) then
				GameTooltip:AddTexture("Interface\\Addons\\LunarSphere\\art\\tooltipMouse" .. index);
				if (canAutoCast) then
					canAutoCast = nil;
					GameTooltip:AddLine("|cFF00EE00" .. "[" .. Lunar.Locale["_SHIFT_TOGGLE"] .. "]|r", r1, r2, r3, true);
				end
			end
		end
	end

	return macroCommand;
end

function Lunar.API:ShortKeybindText(text)

	if not text then
		return text;
	end

	-- Modifiers
	text = string.gsub(text, "ALT--", "|cFFCC0000A|cFFFFFFFF")
	text = string.gsub(text, "CTRL--", "|cFFBBBB00C|cFFFFFFFF")
	text = string.gsub(text, "SHIFT--", "|cFF2266CCS|cFFFFFFFF")

	-- Normal buttons
	text = string.gsub(text, "BACKSPACE", "Bs")
	text = string.gsub(text, "DELETE", "Del")
	text = string.gsub(text, "END", "End")
	text = string.gsub(text, "HOME", "Home")
	text = string.gsub(text, "INSERT", "Ins")
	text = string.gsub(text, "NUMPAD", "NP")
	text = string.gsub(text, "PAGEUP", "PgUp")
	text = string.gsub(text, "PAGEDOWN", "PgDn")
	text = string.gsub(text, "SPACE", "Sp")

	-- Arrow keys
	text = string.gsub(text, "DOWN", "Down")
	text = string.gsub(text, "UP", "Up")
	text = string.gsub(text, "LEFT", "Left")
	text = string.gsub(text, "RIGHT", "Right")	

	-- Mouse related
	text = string.gsub(text, "BUTTON", "M")

	-- Other locales ... 
	text = string.gsub(text, "STRG--", "|cFFBBBB00S|r")

	return text;
end

function Lunar.API:Load()
	if not (LunarSphereSettings.memoryDisableReagents) then
		function Lunar.API:RestockReagents(printBill) -- (reagentName, amount, buyAmount)

			-- If the LunarSphereSettings table doesn't exist, exit now
			if (not LunarSphereSettings) then
				return;
			end

			-- If the reagentList table doesn't exist in the LunarSphereSettings table, exit now
			if (not LunarSphereSettings.reagentList) then
				return;
			end

			-- We have two options now. If the last purchase time was within the past 8 seconds,
			-- and the last used vendor name is the same, we will end now to prevent auto-buying
			-- the same reagents if they haven't entered the player's inventory yet)
			local vendorName = Compat.Readable(UnitName("target"), nil);
			if (Lunar.API.lastPurchaseTime) and (not UnitPlayerControlled("target")) and (vendorName ~= nil) and (vendorName == Lunar.API.lastVendorName) then
				if (Lunar.API.lastPurchaseTime > (time() - 8)) then
					return;
				end
			end
			Lunar.API.lastPurchaseTime = time();
			Lunar.API.lastVendorName = vendorName;

			-- Reset the bill
			local formattedReceipt = 0;
			local reagentIndex, reagent, currentAmount, restockCounter;

			-- Bank restocking. The bank is made up of containers (bank tabs on modern clients,
			-- the bank slots + bank bags on older ones). Grab what we need from them.
			if (Lunar.API.isBanker == true) then

				local bankContainers = Compat.GetBankContainers();
				local bagID, slotID, slotCount, info, itemName, moveAmount, freeBag, freeBagID;

				for reagentIndex = 1, table.getn(LunarSphereSettings.reagentList) do
					reagent = LunarSphereSettings.reagentList[reagentIndex];
					if (reagent.maxAmount) and (reagent.name) then

						currentAmount = GetItemCount(reagent.name) or 0;
						restockCounter = reagent.maxAmount - currentAmount;

						for _, bagID in ipairs(bankContainers) do
							if (restockCounter <= 0) then
								break;
							end
							slotCount = C_Container.GetContainerNumSlots(bagID) or 0;
							for slotID = 1, slotCount do
								if (restockCounter <= 0) then
									break;
								end
								info = C_Container.GetContainerItemInfo(bagID, slotID);
								if (info) and (info.hyperlink) and (not info.isLocked) then
									itemName = GetItemInfo(info.hyperlink);
									if (itemName == reagent.name) then

										moveAmount = math.min(info.stackCount or 1, restockCounter);

										-- If we need the whole stack, just move it into our bags
										if (moveAmount >= (info.stackCount or 1)) then
											C_Container.UseContainerItem(bagID, slotID);
										else
											-- Otherwise split off what we need and drop it into a free bag slot
											freeBag = nil;
											for freeBagID = 0, (NUM_BAG_SLOTS or 4) do
												if ((C_Container.GetContainerNumFreeSlots(freeBagID) or 0) > 0) then
													freeBag = freeBagID;
													break;
												end
											end
											if (freeBag == nil) then
												moveAmount = 0;
											else
												C_Container.SplitContainerItem(bagID, slotID, moveAmount);
												if (freeBag == 0) then
													PutItemInBackpack();
												else
													PutItemInBag(Compat.GetBagInventoryID(freeBag));
												end
											end
										end

										restockCounter = restockCounter - moveAmount;
										formattedReceipt = formattedReceipt + moveAmount;
									end
								end
							end
						end
					end
				end

			-- Merchant restocking
			else
				local totalMerchItems = GetMerchantNumItems() or 0;
				local itemIndex, itemName, price, quantity, numAvailable, maxBuyAmount;

				for reagentIndex = 1, table.getn(LunarSphereSettings.reagentList) do
					reagent = LunarSphereSettings.reagentList[reagentIndex];

					-- Although it shouldn't happen if the reagent list is built properly, but
					-- check and make sure that the table is proper, so we don't get errors.
					if (reagent.maxAmount) and (reagent.name) then

						-- Grab how many of the restock item that we have
						currentAmount = GetItemCount(reagent.name) or 0;

						-- Cycle through each item in the vendor window
						for itemIndex = 1, totalMerchItems do

							itemName, _, price, quantity, numAvailable = GetMerchantItemInfo(itemIndex);

							-- If the names match, it's time to see if we buy it
							if (itemName ~= nil) and (itemName ~= "") and (itemName == reagent.name) then

								price = price or 0;
								quantity = math.max(quantity or 1, 1);
								restockCounter = reagent.maxAmount - currentAmount;

								if (numAvailable) and (numAvailable > -1) and (restockCounter > numAvailable) then
									restockCounter = numAvailable;
								end

								-- Grab how many of the item we can buy at once
								maxBuyAmount = math.max(GetMerchantItemMaxStack(itemIndex) or 1, 1);

								-- Now, loop and buy the items.
								while (restockCounter > 0) do
									local buyAmount = math.min(restockCounter, maxBuyAmount);
									BuyMerchantItem(itemIndex, buyAmount);
									restockCounter = restockCounter - buyAmount;
									currentAmount = currentAmount + buyAmount;
									formattedReceipt = formattedReceipt + ((price / quantity) * buyAmount);
								end
							end
						end
					end
				end
			end

			-- If there is a bill to print out, and we're supposed to print it out, do so now
			if (printBill) and (formattedReceipt > 0) then
				if (Lunar.API.isBanker) then
					Lunar.API:Print(LUNARSPHERE_CHAT .. Lunar.Locale["_REAGENT_BANKRESTOCK_TEXT"]);
				else
					Lunar.API:Print(LUNARSPHERE_CHAT .. Lunar.Locale["REAGENT_TOTALCOST_TEXT"] .. Lunar.API:FormatMoney(formattedReceipt));
				end
			end
		end
	end

	-- /***********************************************
	--   FormatMoney
	--
	--   Formats an amount of copper into gold, silver and copper text
	--  *********************/
	function Lunar.API:FormatMoney(copper)
		copper = math.floor(copper or 0);
		return string.format("|c00D5B108 %2dg", math.floor(copper / 10000)) ..
		       string.format("|c00C8C5C8 %2ds", math.floor(copper / 100) % 100) ..
		       string.format("|c00A3613D %2dc", copper % 100);
	end
	if not (LunarSphereSettings.memoryDisableJunk) then

		-- /***********************************************
		--   SellJunkItems
		--
		--   Sells all quality 0 (gray, junk) items at a vender and prints a report
		--   of how much money was made if requested
		--
		--   accepts:	keep non-equipment, keep armor, keep weapons, print a report (all true or false)
		--   returns:	none
		--  *********************/
		function Lunar.API:SellJunkItems(keepNonEquip, keepAllArmor, keepAllWeapons, printReceipt)

			-- If we call this function and all types of items to sell are not marked for sale,
			-- just leave. No one loves you.
			if ((keepNonEquip) and (keepAllArmor) and (keepAllWeapons)) then
				return;
			end

			local timeDelay = time() - (Lunar.API.lastSellTime or (0));

			-- If it's been a second since the last attempt, continue
			if (timeDelay > 1) then

				Lunar.API.lastSellTime = time();

				-- Create our locals. We use the (locale independent) item class IDs to tell
				-- weapons and armor apart from everything else.
				local bagIndex, slotIndex, itemLink, itemRarity, sellPrice, classID, info, sellIt;
				local WEAPON = (Enum.ItemClass and Enum.ItemClass.Weapon) or 2;
				local ARMOR = (Enum.ItemClass and Enum.ItemClass.Armor) or 4;
				local sellReceipt = 0;

				-- Cycle through all our bags
				for bagIndex = 0, (NUM_BAG_SLOTS or 4) do

					-- Cycle through all our slots in the bag
					for slotIndex = 1, Lunar.Items:GetContainerNumSlots(bagIndex) do

						-- Get the item link of the item in the current slot, if it exists
						itemLink = Lunar.Items:GetContainerItemLink(bagIndex, slotIndex);

						-- If the item exists ...
						if (itemLink) then

							-- Grab the rarity, vendor price and class of the item
							_, _, itemRarity, _, _, _, _, _, _, _, sellPrice, classID = GetItemInfo(itemLink);

							-- If the item rarity is 0 (gray, junk) and can be sold, continue...
							if (itemRarity == 0) and (sellPrice) and (sellPrice > 0) then

								if (classID == ARMOR) then
									sellIt = not keepAllArmor;
								elseif (classID == WEAPON) then
									sellIt = not keepAllWeapons;
								else
									sellIt = not keepNonEquip;
								end

								if (sellIt) then
									info = C_Container.GetContainerItemInfo(bagIndex, slotIndex);
									if (info) and (not info.isLocked) then
										C_Container.UseContainerItem(bagIndex, slotIndex);
										sellReceipt = sellReceipt + sellPrice * (info.stackCount or 1);
									end
								end
							end
						end
					end
				end

				-- If we successfully sold something, we'll need to print the profit if the feature is turned on.
				if (printReceipt) and (sellReceipt > 0)  then
					Lunar.API:Print(LUNARSPHERE_CHAT .. Lunar.Locale["JUNK_SALE_TEXT"] .. Lunar.API:FormatMoney(sellReceipt));
				end
			end
		end
	end
	if not (LunarSphereSettings.memoryDisableRepairs) then

		-- /***********************************************
		--   RepairInventory
		--
		--   Repairs all items in inventory if the user is at a merchant that can repair. Can print
		--   a repair cost receipt if requested.
		--
		--   accepts:	whether or not to print a receipt (true or false)
		--   returns:	formatted receipt string, for log purposes
		--  *********************/
		function Lunar.API:RepairInventory(printReceipt)

			local guildFunds, formattedReceipt

			-- Determine the last time we tried to repair (this is to fix some lag issues with repairing
			-- more than once in a second).

			local timeDelay = time() - (Lunar.API.lastRepairTime or (0));

			-- If we can repair, continue
			if (CanMerchantRepair()) and (timeDelay > 1) then

				Lunar.API.lastRepairTime = time();

				-- Figure our our repair cost and see if we can repair
				local repairAllCost, canRepair = GetRepairAllCost()

				if (canRepair) and (repairAllCost > 0)  then

					-- If we have saved player money waiting for comparison from selling junk items,
					-- update it to reflect how much money the player now has
					Lunar.API.moneyCache = GetMoney() - repairAllCost;

					-- Do the repair and format the cost of the repair into a formatted string (##g, ##s, ##c)
					-- This function is defined in MerchantFrame.lua

					-- Guild Banks were added in patch 2.3.0. Hopefully Blizzard
					-- will keep the API versioning consistent for BCC
					if (CanGuildBankRepair) and (IsInGuild()) and CanGuildBankRepair() and (LunarSphereSettings.useGuildFunds == true) then
						-- Get our bank funds and withdraw max. 

						local withdrawMax = GetGuildBankWithdrawMoney();
						local bankFunds = GetGuildBankMoney();

						-- If the repair cost is less than what we can pull out (withdrawl < 0 means no limit),
						-- and the bank itself has enough to cover this transaction, repair with the guild bank.
						-- Otherwise, use our funds.

						if ((repairAllCost <= withdrawMax) or (withdrawMax < 0)) and (bankFunds >= repairAllCost) then
							RepairAllItems(1);
							guildFunds = true;
						else
							RepairAllItems();
						end

					else
						RepairAllItems();
					end

					formattedReceipt = Lunar.API:FormatMoney(repairAllCost);
					if (guildFunds == true) then
						formattedReceipt = formattedReceipt .. " " .. Lunar.Locale["_GUILD_FUNDS_TAG"];
					end

					-- If we need to print a receipt, do it
					if (printReceipt) then
						Lunar.API:Print(LUNARSPHERE_CHAT .. Lunar.Locale["REPAIR_COST_TEXT"] .. formattedReceipt);
					end

				end
			end

			-- Return our string
			return formattedReceipt;
			
		end
	end

	if not (LunarSphereSettings.memoryDisableAHTotals) then
--
--		function Lunar.API:ShowAuctionTotals(toggle)
--
--			-- If our frame doesn't exist yet, make it
--			if (not Lunar.API.AuctionTotals) then
--				Lunar.API:CreateAuctionTotals();
--			end
--
--			Lunar.API.AuctionTotals.showMe = toggle;
--
--			if (toggle == true) then
--				Lunar.API.AuctionTotals:RegisterEvent("AUCTION_OWNED_LIST_UPDATE");
--				if (Lunar.API.AuctionTotals:GetParent() == _G["AuctionsCancelAuctionButton"]) then
--					Lunar.API.AuctionTotals:Show();
--				end
--			else
----				Lunar.API.AuctionTotals:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE");
--				Lunar.API.AuctionTotals:Hide();
--			end
--
----			Lunar.API:ShowBidTotals(toggle);
--		end
--
--		function Lunar.API:CreateAuctionTotals()
--			
--			-- Create our new frame and hide it
--			Lunar.API.AuctionTotals = CreateFrame("Frame", "LSAuctionTotals", UIParent, "SmallMoneyFrameTemplate");
--			Lunar.API.AuctionTotals:SetPoint("Center");
--			Lunar.API.AuctionTotals.small = 1;
--			Lunar.API.AuctionTotals:Hide();
--
--			-- Reset the money frame scripts and build our own
--			Lunar.API.AuctionTotals:SetScript("OnShow", nil);
--			Lunar.API.AuctionTotals:SetScript("OnHide", nil);
--			Lunar.API.AuctionTotals:SetScript("OnUpdate", nil);
--			Lunar.API.AuctionTotals:SetScript("OnEvent", 
--			function (self, event)
--					
--				-- First, check if the frame has been attached to the auction house window yet. If not, do so
--				-- and make sure it's visible
--				if (AuctionFrameAuctions) then
--					if (self:GetParent() ~= _G["AuctionsCancelAuctionButton"]) then
--						self:ClearAllPoints()
--						self:SetParent("AuctionsCancelAuctionButton");
--						self:SetPoint("TOPRIGHT", _G["AuctionsCancelAuctionButton"], "TOPLEFT", -2, -4);
--						self:SetFrameStrata("HIGH");
--						self:Hide();
--						if (self.showMe) then
--							self:Show();
--						end
--					end
--				end
--
--				-- Create our locals
--				local index, buyoutPrice, bidAmount, minBid;
--				local numBatchAuctions = C_AuctionHouse.GetNumReplicateItems("owner");
--				local totalListed = 0;
--
--				-- If there's auctions to check, get shaking!
--				if (numBatchAuctions > 0) then
--					for index = 1, numBatchAuctions do
--
--						-- Grab the starting bid, buyout price, and current bid
--						_,_,_,_,_,_,minBid,_,buyoutPrice,bidAmount = GetAuctionItemInfo("owner", index);
--
--						-- If there is no buyout price, grab the current bid
--		--				if (not buyoutPrice) then
--		--					buyoutPrice = bidAmount;
--		--				end
--						-- Now, if there wasn't a current bid or buyout price, we grab the
--						-- starting bid
--		--				if (not buyoutPrice) then
--		--					buyoutPrice = minBid
--		--				end
--
--						totalListed = totalListed + (buyoutPrice or bidAmount or minBid);
--
--						-- Add it up!
--		--				totalListed = totalListed + buyoutPrice;
--					end
--				end
--
--				-- Update the money frame
--				MoneyFrame_Update(self:GetName(), totalListed);
--			end);
--
--			-- Set its default denomination
--			MoneyFrame_Update("LSAuctionTotals", 0)
--		end
--
--		function Lunar.API:ShowBidTotals(toggle)
--
--			-- If our frame doesn't exist yet, make it
--			if (not Lunar.API.BidTotals) then
--				Lunar.API:CreateBidTotals();
--			end
--
--			Lunar.API.BidTotals.showMe = toggle;
--
----			if (toggle == true) then
--				Lunar.API.BidTotals:RegisterEvent("AUCTION_BIDDER_LIST_UPDATE");
--				if (Lunar.API.BidTotals:GetParent() == _G["BidBidButton"]) then
--					Lunar.API.BidTotals:Show();
--				end
--			else
--				Lunar.API.BidTotals:UnregisterEvent("AUCTION_BIDDER_LIST_UPDATE");
--				Lunar.API.BidTotals:Hide();
--			end
--		end
--
--		function Lunar.API:CreateBidTotals()
--
--			-- Create our new frame and hide it
--			Lunar.API.BidTotals = CreateFrame("Frame", "LSBidTotals", UIParent, "SmallMoneyFrameTemplate");
--			Lunar.API.BidTotals:SetPoint("Center");
--			Lunar.API.BidTotals.small = 1;
--			Lunar.API.BidTotals:Hide();
--
--			-- Reset the money frame scripts and build our own
--			Lunar.API.BidTotals:SetScript("OnShow", nil);
--			Lunar.API.BidTotals:SetScript("OnHide", nil);
--			Lunar.API.BidTotals:SetScript("OnUpdate", nil);
--			Lunar.API.BidTotals:SetScript("OnEvent", 
--			function (self, event)
--					
--				-- First, check if the frame has been attached to the auction house window yet. If not, do so
--				-- and make sure it's visible
--				if (AuctionFrameBid) then
--					if (self:GetParent() ~= _G["BidBidButton"]) then
--						self:ClearAllPoints()
--						self:SetParent(_G["BidBidButton"]);
--						self:SetPoint("TOPRIGHT", _G["BidBidButton"], "TOPLEFT", -2, -4);
--						self:SetFrameStrata("HIGH");
--						self:Hide();
--						if (self.showMe) then
--							self:Show();
--						end
--					end
--				end
--
--				-- Create our locals
--				local index;
--				local numBatchAuctions = C_AuctionHouse.GetNumReplicateItems("bidder");
--				local totalBid = 0;
--
--				-- If there's auctions to check, get shaking!
--				if (numBatchAuctions > 0) then
--					for index = 1, numBatchAuctions do
--
--						-- Grab the current bid and add it up!
--						totalBid = totalBid + (select(10, GetAuctionItemInfo("bidder", index)) or 0);
--
--						-- Add it up!
--		--				totalBid = totalBid + bidAmount;
--					end
--	--				Lunar.API:Print(" Total Bid = " .. totalBid)
--				end
--
--				-- Update the money frame
--				MoneyFrame_Update(self:GetName(), totalBid);
--			end);
--
--			MoneyFrame_Update("LSBidTotals", 0)
--		end
	end

	if not (LunarSphereSettings.memoryDisableAHMail) then

		-- /***********************************************
		--   OnEvent
		--
		--   Event handler for the API object
		--
		--   accepts:	triggered event
		--   returns:	none
		--  *********************/
		function Lunar.API.OnEvent(self, event, arg1)

			-- If we have a mailbox update, notate that we can move to the next mail message
			-- and clear this event
			if (event == "MAIL_INBOX_UPDATE") then
				if (Lunar.API.awaitingMail == 1) then
					Lunar.API.awaitingMail = 2;
					Lunar.API:GetMail();
					return;
				else
					Lunar.API.eventWatcher:UnregisterEvent("MAIL_INBOX_UPDATE");
					Lunar.API.nextMail = 1;
				end
			end

			-- If the mail box shows and we got a mail task, do it!
			if (event == "MAIL_SHOW") then
				Lunar.API.awaitingMail = 1;
				Lunar.API.eventWatcher:RegisterEvent("MAIL_INBOX_UPDATE");
				CheckInbox();
			end

			-- If the mail box closes, we need to stop what we're doing
			if (event == "MAIL_CLOSED") then
				Lunar.API.eventWatcher:SetScript("OnUpdate", nil);
				Lunar.API.eventWatcher:UnregisterEvent("MAIL_INBOX_UPDATE");
				Lunar.API.awaitingMail = nil;
				Lunar.API.totalMail = nil
				Lunar.API.nextMail = nil;
			end

		end

		Lunar.API.eventWatcher:SetScript("OnEvent", Lunar.API.OnEvent);

		function Lunar.API:GetMailSetup(getMoney, getItem)

			Lunar.API.getMoneyMail = getMoney;
			Lunar.API.getItemMail = getItem;

			Lunar.API.str1, Lunar.API.str2 = strsplit("%s", AUCTION_OUTBID_MAIL_SUBJECT);	-- money
			Lunar.API.str3, Lunar.API.str4 = strsplit("%s", AUCTION_SOLD_MAIL_SUBJECT);	-- money
			Lunar.API.str5, Lunar.API.str6 = strsplit("%s", AUCTION_EXPIRED_MAIL_SUBJECT);	-- item
			Lunar.API.str7, Lunar.API.str8 = strsplit("%s", AUCTION_WON_MAIL_SUBJECT);	-- item
			Lunar.API.str9, Lunar.API.str10 = strsplit("%s", AUCTION_REMOVED_MAIL_SUBJECT);	-- money
			Lunar.API.pendingStr1, Lunar.API.pendingStr2 = strsplit("%s", AUCTION_INVOICE_MAIL_SUBJECT); -- ignore :)

			if (getMoney) or (getItem)  then
				Lunar.API.eventWatcher:RegisterEvent("MAIL_SHOW");
				Lunar.API.eventWatcher:RegisterEvent("MAIL_CLOSED");
			else
				Lunar.API.eventWatcher:UnregisterEvent("MAIL_SHOW");
				Lunar.API.eventWatcher:UnregisterEvent("MAIL_CLOSED");
			end
		end

		function Lunar.API:GetMail()
			
			CheckInbox();

			Lunar.API.totalMail = GetInboxNumItems();
			Lunar.API.mailGrabbed = 0;
			Lunar.API.mailToGrab = Lunar.API.totalMail;

			Lunar.API.nextMail = 1;
			Lunar.API.delay = 0;

			Lunar.API.eventWatcher:SetScript("OnUpdate",
			function (self, arg1)
				if (Lunar.API.delay == 0) then
					Lunar.API.delay = 1;
					if (Lunar.API.nextMail == 1) and (Lunar.API.totalMail > 0) then

						local loopRunning = true;
				
						while (loopRunning == true) do 

							local _, _, _, subject, money, CODAmount, _, hasItem = GetInboxHeaderInfo(Lunar.API.totalMail);
							subject = subject or "";
							local index, takeIt;
							takeIt = nil;

							if Lunar.API.pendingStr1 then
								if Lunar.API.pendingStr2 then
									if (string.find(subject, Lunar.API.pendingStr1) and string.find(subject, Lunar.API.pendingStr2)) then
										takeIt = false;
									end
								else
									if (string.find(subject, Lunar.API.pendingStr1)) then
										takeIt = false;
									end
								end
							end

							if (takeIt ~= false) then
								for index = 1, 9, 2 do 
									
									if (Lunar.API["str" .. index]) then
										if (Lunar.API["str" .. index+1]) then
											if ((string.find(subject, Lunar.API["str" .. index])) and (string.find(subject, Lunar.API["str" .. index+1])))  then
												takeIt = true;
											end
										else
											if (string.find(subject, Lunar.API["str" .. index])) then
												takeIt = true
											end
										end
									end

									if (takeIt == true) then
										if (index < 5) and (Lunar.API.getMoneyMail)  then
											Lunar.API.nextMail = nil;
											Lunar.API.eventWatcher:RegisterEvent("MAIL_INBOX_UPDATE");
											TakeInboxMoney(Lunar.API.totalMail);
											loopRunning = false;
											Lunar.API.mailGrabbed = Lunar.API.mailGrabbed + 1;
											break;
										elseif (index >= 5) and (index < 9) and (Lunar.API.getItemMail)  then
											Lunar.API.nextMail = nil;
											Lunar.API.eventWatcher:RegisterEvent("MAIL_INBOX_UPDATE");
											AutoLootMailItem(Lunar.API.totalMail);
											loopRunning = false;
											Lunar.API.mailGrabbed = Lunar.API.mailGrabbed + 1;
											break;
										elseif (index >= 9) then
											if (Lunar.API.getItemMail) and (hasItem) then
												Lunar.API.nextMail = nil;
												Lunar.API.eventWatcher:RegisterEvent("MAIL_INBOX_UPDATE");
												AutoLootMailItem(Lunar.API.totalMail);
												loopRunning = false;
												Lunar.API.mailGrabbed = Lunar.API.mailGrabbed + 1;
												break;
											end
											if (Lunar.API.getMoneyMail) and (money > 0) then
												Lunar.API.nextMail = nil;
												Lunar.API.eventWatcher:RegisterEvent("MAIL_INBOX_UPDATE");
												TakeInboxMoney(Lunar.API.totalMail);
												loopRunning = false;
												Lunar.API.mailGrabbed = Lunar.API.mailGrabbed + 1;
												break;
											end
										end
									end
								end
							end

							Lunar.API.totalMail = Lunar.API.totalMail - 1;

							if (Lunar.API.totalMail == 0) then
								loopRunning = false;
								Lunar.API.eventWatcher:SetScript("OnUpdate", nil);
								Lunar.API.nextMail = nil;
								Lunar.API.eventWatcher:UnregisterEvent("MAIL_INBOX_UPDATE");
							end

						end

						if (Lunar.API.mailGrabbed == Lunar.API.mailToGrab) then
							-- Hide the mail minimap icon if there's no more mail (only exists on
							-- older clients, modern clients update the mail indicator themselves)
							if (MiniMapMailFrame) then
								MiniMapMailFrame:Hide();
							end
						end

					end
				else
					Lunar.API.delay = 0;
				end
			end);
		end
	end

	if not (LunarSphereSettings.memoryDisableDefaultUI) then

		-- Hidden holder frame. Blizzard frames we hide are re-parented to it instead of
		-- replacing their Show() methods, which would taint them.
		Lunar.API.uiHider = Lunar.API.uiHider or CreateFrame("Frame", "LunarSphereUIHider", UIParent);
		Lunar.API.uiHider:Hide();
		Lunar.API.hiddenFrames = Lunar.API.hiddenFrames or setmetatable({}, {__mode = "k"});

		-- Runs a function once we're out of combat (or right now if we already are)
		function Lunar.API:RunOutOfCombat(func, ...)
			if not InCombatLockdown() then
				func(...);
				return;
			end
			if (not Lunar.API.combatQueueFrame) then
				Lunar.API.combatQueueFrame = CreateFrame("Frame");
				Lunar.API.combatQueueFrame.queue = {};
				Lunar.API.combatQueueFrame:SetScript("OnEvent", function(self)
					self:UnregisterEvent("PLAYER_REGEN_ENABLED");
					local queue = self.queue;
					self.queue = {};
					for _, entry in ipairs(queue) do
						entry.func(unpack(entry.args, 1, entry.argCount));
					end
				end);
			end
			table.insert(Lunar.API.combatQueueFrame.queue, {func = func, args = {...}, argCount = select("#", ...)});
			Lunar.API.combatQueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		end

		local function SetFrameHidden(frame, hide)
			if (not frame) then
				return;
			end
			local objectType = frame.GetObjectType and frame:GetObjectType();
			if (objectType == "Texture") or (objectType == "FontString") or (objectType == "MaskTexture") then
				frame:SetAlpha(hide and 0 or 1);
				return;
			end
			if (frame.IsProtected) and (frame:IsProtected()) and InCombatLockdown() then
				Lunar.API:RunOutOfCombat(SetFrameHidden, frame, hide);
				return;
			end
			if (hide) then
				if (Lunar.API.hiddenFrames[frame] == nil) then
					Lunar.API.hiddenFrames[frame] = frame:GetParent() or false;
					frame:SetParent(Lunar.API.uiHider);
				end
			else
				local parent = Lunar.API.hiddenFrames[frame];
				if (parent ~= nil) then
					Lunar.API.hiddenFrames[frame] = nil;
					frame:SetParent(parent or UIParent);
				end
			end
		end

		-- /***********************************************
		--   HideFrame
		--
		--   Hides (or restores) a Blizzard UI frame. On load we only ever hide, so that
		--   frames the user never touched are left completely alone.
		--  *********************/
		function Lunar.API:HideFrame(frame, toggle, loading)
			if (not frame) then
				return;
			end
			if (toggle) then
				SetFrameHidden(frame, true);
			elseif (not loading) then
				SetFrameHidden(frame, false);
			end
		end

		-- Shortcut for hiding a list of frames that might not exist on this client
		local function HideFrames(toggle, loading, ...)
			for i = 1, select("#", ...) do
				Lunar.API:HideFrame((select(i, ...)), toggle, loading);
			end
		end

		function Lunar.API:HidePlayerFrame(toggle, loading)
			HideFrames(toggle, loading, PlayerFrame);
		end

		function Lunar.API:HideCalendar(toggle, loading)
			HideFrames(toggle, loading, GameTimeFrame);
		end

		function Lunar.API:HideMinimapZoom(toggle, loading)
			if (Minimap) and (Minimap.ZoomIn) then
				HideFrames(toggle, loading, Minimap.ZoomIn, Minimap.ZoomOut, Minimap.ZoomHitArea);
			else
				HideFrames(toggle, loading, MinimapZoomIn, MinimapZoomOut);
			end
		end

		-- The world map minimap button no longer exists on modern clients (Midnight / Forever)
		function Lunar.API:HideWorldmap(toggle, loading)
			HideFrames(toggle, loading, MiniMapWorldMapButton);
		end

		function Lunar.API:HideMinimap(toggle, loading)
			HideFrames(toggle, loading, MinimapCluster);
		end

		function Lunar.API:HideTracking(toggle, loading)
			if (MinimapCluster) and (MinimapCluster.Tracking) then
				HideFrames(toggle, loading, MinimapCluster.Tracking);
			else
				HideFrames(toggle, loading, MiniMapTracking);
			end
		end

		function Lunar.API:HideMinimapTime(toggle, loading)
			HideFrames(toggle, loading, TimeManagerClockButton);
		end

		function Lunar.API:HideExpBars(toggle, loading)
			if (StatusTrackingBarManager) then
				HideFrames(toggle, loading, StatusTrackingBarManager, MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer);
			else
				HideFrames(toggle, loading, MainMenuExpBar, ReputationWatchBar, MainMenuBarMaxLevelBar, ExhaustionTick);
			end
		end

		local function GetMainActionBar()
			return MainActionBar or MainMenuBar;
		end

		function Lunar.API:HideGryphons(toggle, loading)
			local bar = GetMainActionBar();
			if (bar) and (bar.EndCaps) then
				HideFrames(toggle, loading, bar.EndCaps);
			else
				HideFrames(toggle, loading, MainMenuBarLeftEndCap, MainMenuBarRightEndCap);
			end
		end

		function Lunar.API:HideMenus(toggle, loading)
			if (MicroMenuContainer) then
				HideFrames(toggle, loading, MicroMenuContainer);
			elseif (MicroMenu) then
				HideFrames(toggle, loading, MicroMenu);
			else
				HideFrames(toggle, loading, CharacterMicroButton, SpellbookMicroButton, TalentMicroButton, AchievementMicroButton,
					QuestLogMicroButton, GuildMicroButton, LFDMicroButton, EJMicroButton, MainMenuMicroButton, StoreMicroButton,
					CollectionsMicroButton, HelpMicroButton);
			end
		end

		function Lunar.API:HideBags(toggle, loading)
			if (BagsBar) then
				HideFrames(toggle, loading, BagsBar);
			else
				HideFrames(toggle, loading, MainMenuBarBackpackButton, CharacterBag0Slot, CharacterBag1Slot, CharacterBag2Slot, CharacterBag3Slot);
			end
		end

		function Lunar.API:HideBottomBar(toggle, loading)
			local bar = GetMainActionBar();
			if (bar) and (bar.BorderArt) then
				HideFrames(toggle, loading, bar.BorderArt, bar.Background, bar.ActionBarPageNumber);
			else
				HideFrames(toggle, loading, MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3,
					SlidingActionBarTexture0, SlidingActionBarTexture1, MainMenuBarPageNumber);
			end
		end

		function Lunar.API:HideStanceBar(toggle, loading)
			HideFrames(toggle, loading, StanceBar or StanceBarFrame);
		end

		function Lunar.API:HideTotemBar(toggle, loading)
			HideFrames(toggle, loading, MultiCastActionBarFrame);
		end

		function Lunar.API:HidePetBar(toggle, loading)
			HideFrames(toggle, loading, PetActionBar or PetActionBarFrame);
		end

		function Lunar.API:HideActionButtons(toggle, loading)
			local bar = GetMainActionBar();
			if (MainActionBar) or (bar and bar.EditModeInitialize) then
				-- Modern clients: the main action bar is a single Edit Mode frame
				HideFrames(toggle, loading, bar);
			else
				local index;
				for index = 1, 12 do
					HideFrames(toggle, loading, _G["ActionButton" .. index]);
				end
				HideFrames(toggle, loading, ActionBarUpButton, ActionBarDownButton);
			end
		end
	end
	if not (LunarSphereSettings.memoryDisableMinimap) then

		function Lunar.API:SetMinimapScroll(toggle)
			LunarSphereSettings.minimapScroll = toggle;

			-- Modern clients already zoom the minimap with the mouse wheel. We only add our own
			-- handler if the minimap doesn't have one, and only touch the minimap when the
			-- option is actually turned on (or when undoing our own change).
			if (toggle == true) then
				if (not Minimap:GetScript("OnMouseWheel")) then
					Lunar.API.minimapWheelHooked = true;
					Minimap:SetScript("OnMouseWheel", function (self, delta)
						if (delta > 0) then
							Minimap_ZoomIn();
						else
							Minimap_ZoomOut();
						end
					end);
				end
				if (Minimap.IsMouseWheelEnabled) and (not Minimap:IsMouseWheelEnabled()) then
					Lunar.API.minimapWheelEnabled = true;
					Minimap:EnableMouseWheel(true);
				end
			else
				if (Lunar.API.minimapWheelHooked) then
					Lunar.API.minimapWheelHooked = nil;
					Minimap:SetScript("OnMouseWheel", nil);
				end
				if (Lunar.API.minimapWheelEnabled) then
					Lunar.API.minimapWheelEnabled = nil;
					Minimap:EnableMouseWheel(false);
				end
			end
		end

		function Lunar.API:ShowMinimapCoords(toggle)

			-- If we're showing the coords, make sure the elements are visible and the original
			-- minimap zone text is hidden
			if (toggle) then
				Lunar.API.minimapShowCoords = true;
				Lunar.API.enableMinimapText = true;
				Lunar.API.MinimapTextRight:Show();
				MinimapZoneText:Hide();

			-- Otherwise, hide our coords. If the coords and the time are hidden, disable our
			-- updater as well and show the original minimap zone text
			else
				Lunar.API.minimapShowCoords = nil;
				if ((not Lunar.API.minimapShowTime) and (not Lunar.API.minimapShowCoords)) then
					Lunar.API.enableMinimapText = false;
					MinimapZoneText:Show();
				end	
				Lunar.API.MinimapTextRight:Hide();
			end

			-- Repositon text locations
			Lunar.API:PositionMinimapText()

		end

		function Lunar.API:ShowMinimapTime(toggle, useMilitary, offset)

			-- Set our settings
	--		Lunar.API.minimapTimeMilitary = useMilitary;
	--		if (offset) then
	--			Lunar.API.minimapTimeOffset = offset * 3600;
	--		end

			-- If we show the time, we need to show its elements and hide the minimap zone text
			if (toggle) then
				Lunar.API.minimapShowTime = true;
				Lunar.API.enableMinimapText = true;
				Lunar.API.MinimapText:Show();
				MinimapZoneText:Hide();

				Lunar.API.MinimapText:ClearAllPoints();
				if (Lunar.API.minimapShowCoords) then
					Lunar.API.MinimapText:SetPoint("Left", 2, 1);
				else
					Lunar.API.MinimapText:SetPoint("Center");
				end

			-- Otherwise, turn off the time and if the time and coords are turned off, we also
			-- need to turn off the updater. When we're done, show the original minimap zone text
			else
				Lunar.API.minimapShowTime = nil;
				if ((not Lunar.API.minimapShowTime) and (not Lunar.API.minimapShowCoords)) then
					Lunar.API.enableMinimapText = false;
					MinimapZoneText:Show();
				end	
				Lunar.API.MinimapText:Hide();
			end

			-- Repositon text locations
			Lunar.API:PositionMinimapText()
		end

		function Lunar.API:PositionMinimapText()
			Lunar.API.MinimapText:ClearAllPoints();
			Lunar.API.MinimapTextRight:ClearAllPoints();

			if (Lunar.API.minimapShowCoords) and (Lunar.API.minimapShowTime) then
				Lunar.API.MinimapText:SetPoint("Left", 2, 1);
				Lunar.API.MinimapTextRight:SetPoint("Right", -22, 1);
			else
				Lunar.API.MinimapText:SetPoint("Center", 0, 1);
				Lunar.API.MinimapTextRight:SetPoint("Center", 0, 1);
			end
		end

		function Lunar.API:CreateMinimapText()

			-- Create our new frame, set its anchors, and make sure it doesn't have mouse input
			Lunar.API.MinimapTextUpdater = CreateFrame("Frame", "LSMinimapTextUpdater", UIParent, BackdropTemplateMixin and "BackdropTemplate");

			Lunar.API.MinimapTextUpdater:Show();
			local zoneTextButton = MinimapZoneTextButton or (MinimapCluster and MinimapCluster.ZoneTextButton) or Minimap;
			Lunar.API.MinimapTextUpdater:SetPoint("TopLeft", zoneTextButton, "TopLeft");
			Lunar.API.MinimapTextUpdater:SetPoint("BottomRight", zoneTextButton, "BottomRight");
			Lunar.API.MinimapTextUpdater:EnableMouse(false);

			-- Create the updating function (frame updates every 1/3 of a second)
			Lunar.API.MinimapTextUpdater:SetScript("OnUpdate",
			function (self, arg1)

				-- If we're not currently supposed to work, leave now
				if (not Lunar.API.enableMinimapText) then
					return;
				end

				-- Update the timer. If it's not time to update yet, leave now
				Lunar.API.updateTimer = Lunar.API.updateTimer + arg1;
				if (Lunar.API.updateTimer < 0.3) then
					return;
				end

				-- Reset the timer
				Lunar.API.updateTimer = 0;

				-- If we need to update the time, do so
				if (LunarSphereSettings.showTime) then -- Lunar.API.minimapShowTime) then
					local hours, minutes = GetGameTime();
					hours = hours + LunarSphereSettings.timeOffset; --Lunar.API.minimapTimeOffset
					if (hours > 23) then
						hours = hours - 24;
					elseif (hours < 0) then
						hours = hours + 24;
					end
					if (LunarSphereSettings.militaryTime) then -- Lunar.API.minimapTimeMilitary) then
						Lunar.API.MinimapText:SetFormattedText(TIME_TWENTYFOURHOURS, hours, minutes);
	--					Lunar.API.MinimapText:SetText(hours .. ":" .. minutes);date("%H:%M", time() + Lunar.API.minimapTimeOffset));
					else
						-- Handle the PM	
						if(hours >= 12) then
							if (hours > 12) then
								hours = hours - 12;
							end
							Lunar.API.MinimapText:SetFormattedText(TIME_TWELVEHOURPM, hours, minutes);

						-- Handle the AM
						else
							if(hours == 0) then
								hours = 12;
							end
							Lunar.API.MinimapText:SetFormattedText(TIME_TWELVEHOURAM, hours, minutes);
						end
							
	--					Lunar.API.MinimapText:SetText(date("%I:%M", time() + Lunar.API.minimapTimeOffset));
					end
				end

				-- If we need to update the coordinates, do so
				if (Lunar.API.minimapShowCoords) then
					local x, y = Compat.GetPlayerMapPosition();
					if Compat.AnySecret(x, y) then
						Lunar.API.MinimapTextRight:SetText("");
					else
						Lunar.API.MinimapTextRight:SetText(tostring(math.floor(x * 1000) / 10) .. ",  " .. tostring(math.floor(y * 1000) / 10));
					end
				end

			 end);

			-- Create our left hand text (for time)
			Lunar.API.MinimapText = Lunar.API.MinimapTextUpdater:CreateFontString("LSMinimapText", "OVERLAY")
			Lunar.API.MinimapText:SetFont(STANDARD_TEXT_FONT, 10)
			Lunar.API.MinimapText:SetTextColor(1, 1, 1)
			Lunar.API.MinimapText:SetPoint("Left", 2, 1);
			Lunar.API.MinimapText:SetText("");
			Lunar.API.MinimapText:Hide()

			-- Create our right hand text (for coordinates)
			Lunar.API.MinimapTextRight = Lunar.API.MinimapTextUpdater:CreateFontString("LSMinimapTextRight", "OVERLAY")
			Lunar.API.MinimapTextRight:SetFont(STANDARD_TEXT_FONT, 10)
			Lunar.API.MinimapTextRight:SetTextColor(1, 1, 1)
			Lunar.API.MinimapTextRight:SetPoint("Right", -2, 1);
			Lunar.API.MinimapTextRight:SetText("");
			Lunar.API.MinimapTextRight:Hide()

		end
	end

	function Lunar.API:CheckArtDatabase()

		-- Continue if we have an art database
		
		if (LunarSphereGlobal.artDatabase) then

			-- Create our locals, set our start index

			local count, index, filename;
			index = 1;

			-- Run through each file saved in the art database and verify that
			-- it exists. If the file no longer exists, remove it from the database.
			-- If the file exists, update the search index.

			for count = 1, table.getn(LunarSphereGlobal.artDatabase) do
				filename = select(4, Lunar.API:GetArt(index));
				if not Lunar.API:ArtExists(LUNAR_IMPORT_PATH .. filename) then
					table.remove(LunarSphereGlobal.artDatabase, index);
				else
					index = index + 1;
				end
			end
		end
		
	end

	function Lunar.API:AddArt(artType, width, height, filename)

		local fileAdded = false;

		-- If we have valid values, continue
		
		if artType and width and height and filename then

			-- We have support for multiple filenames. Each filename is separated by a comma ","
			-- and we will check each file in the string.

			local currentName, finished, startPos;

			while not finished do 

				-- Check if the comma exists.

				startPos = string.find(filename, ",")
				currentName = nil;

				-- If the comma exists, we will grab the file that is before the
				-- comma and trim any extra spaces from the string. If it is not the last
				-- file in the list, we remove the file from our filename list for the
				-- next search. Otherwise, if it was the last filename in the list, we
				-- destroy the list

				if (startPos) then

					if (startPos > 1) then
						currentName = strtrim(string.sub(filename, 1, startPos - 1)); 
					end

					if (string.len(filename) > startPos + 1) then
						filename = string.sub(filename, startPos + 1);
					else
						filename = "";
					end

				-- If the comma didn't exist, assume that we're finished and whatever
				-- is left in the filename list is the last filename

				else

					finished = true;
					currentName = strtrim(filename);

				end

				-- If we have a valid filename, we will check if it already exists in the
				-- specified art catagory. Next, we verify that the art file exists and
				-- if it does, we add the file to the database.

				if (currentName) then
					if not Lunar.API:FindArt(currentName, artType) then
						if (Lunar.API:ArtExists(LUNAR_IMPORT_PATH .. currentName)) then
							table.insert(LunarSphereGlobal.artDatabase, artType .. ":::" .. width .. ":::" .. height .. ":::" .. currentName);
							fileAdded = true;
						end
					end
				end
			end
		end

		return fileAdded;

	end

	function Lunar.API:ArtExists(filename)

		-- Grab the test texture frame and load up our new texture file.
		-- If the file loaded okay (because it exists), return true.
		-- Otherwise, we're going to return false with the fail.

		local frame = Lunar.API.eventWatcher.tempTexture;
		frame:SetTexture("")
		frame:SetTexture(filename)
		if (frame:GetTexture()) then
			return true;
		end
		return false;

	end

	function Lunar.API:RemoveArt(filename, index)

		-- Ensure we have an index to remove. Once we have one, remove
		-- it from the art database table

		if (not index) then
			index = Lunar.API:FindArt(filename);
		end
		if index then
			table.remove(LunarSphereGlobal.artDatabase, index);
		end

	end

	function Lunar.API:FindArt(filename, findArtType)

		-- Search our art database. If the current art database entry's name is
		-- the same name we're looking for, check the artType of that file
		-- as well. If the artType is the same, or there is no specified artType
		-- to look for, return the art database index the file was found in
		-- along with the art file's data

		local index, artType, width, height, artFilename;
		for index = 1, table.getn(LunarSphereGlobal.artDatabase) do
			artType, width, height, artFilename = Lunar.API:GetArt(index);
			if string.lower(artFilename) == string.lower(filename) then
				if findArtType and (findArtType == artType) then
					return index, artType, width, height, artFilename;
				elseif not findArtType then
					return index, artType, width, height, artFilename;
				end
			end
		end
		return;

	end

	function Lunar.API:GetArt(artID)

		-- Grab the data string from the specified artID. If the data string
		-- exists, return the art file information from within the string.

	--	local bufferString, artType, width, height, artFilename
		local bufferString
		bufferString = LunarSphereGlobal.artDatabase[artID]
		if bufferString then
	--		artType, width, height, artFilename = string.match(bufferString, "(.*):::(.*):::(.*):::(.*)");
			return string.match(bufferString, "(.*):::(.*):::(.*):::(.*)");
		end
	--	return artType, width, height, artFilename;
		return;
	end

	function Lunar.API:GetArtCount(catagory)

		-- Search our art database and increase our totalCount counter every time we
		-- find an art file in the specified catagory. Return our results when finished.

		local index, totalCount = 0, 0;
		for index = 1, table.getn(LunarSphereGlobal.artDatabase) do 
			if (Lunar.API:GetArt(index) == catagory) then
				totalCount = totalCount + 1;
			end
		end
		return totalCount;

	end

	function Lunar.API:GetNextArt(catagory, startIndex)

		-- Exit now if we have bad data

		if not catagory then
			return;
		end

		-- Search our art database and return the next art filename that
		-- is in our search catagory.

		local index, artType, width, height, artFilename
		for index = (startIndex or 1), table.getn(LunarSphereGlobal.artDatabase) do 
			artType, width, height, artFilename = Lunar.API:GetArt(index);
			if (artType == catagory) then
				return index, artType, width, height, artFilename;
			end
		end
		return;

	end

	function Lunar.API:GetArtByCatagoryIndex(catagory, grabIndex)

		-- Exit if we have invalid data

		if (not catagory) or (not grabIndex) then
			return;
		end

		-- Search our art database. Grab the data of each entry and compare the
		-- artType against our search catagory. If it is the same catagory we're
		-- looking for, notate how many of this type we have found. Once we have
		-- found the grabIndex amount of art files, return the data for that entry.

		local index, artType, width, height, artFilename
		local currentIndex = 0;
		for index = 1, table.getn(LunarSphereGlobal.artDatabase) do
			artType, width, height, artFilename = Lunar.API:GetArt(index);
			if (artType == catagory) then
				currentIndex = currentIndex + 1;
				if (currentIndex == grabIndex) then
					return index, artType, width, height, artFilename;
				end
			end
		end
		return;
	end

	function Lunar.API:SupportForDrDamage()
	--[[
		if not DrDamage then
			return;
		end

		if not (LunarSphereSettings.enableDrDamage == true) and not (Lunar.Button.updateDrDamage) then
			return;
		end

		if (LunarSphereSettings.enableDrDamage == true) then
			if not Lunar.API.hookedDrDamage then
	--			Lunar.API.hookedDrDamage = 2;
				hooksecurefunc(DrDamage, "UpdateAB", Lunar.API.SupportForDrDamage);

				-- Support for old and new DrDamage code
				Lunar.Button.drDamageParamStart = 0;
				if (GetAddOnMetadata("DrDamage", "Version") < "1.2.3") then
					Lunar.Button.drDamageParamStart = 1;
				end
				Lunar.Button.drDamageParam = {};
	--			return;
	--		elseif (Lunar.API.hookedDrDamage == 2) then
				Lunar.API.hookedDrDamage = true;
				Lunar.Button.updateDrDamage = true;
				return;
			end	
	--		Lunar.Button.updateDrDamage = true;
		else
			Lunar.Button.updateDrDamage = nil;
		end

	--	if not Lunar.Button.updateDrDamage then
	--		return;
	--	end

		local buttonName, spellRank, spellName;


		local param = Lunar.Button.drDamageParam;
		local paramOffset = Lunar.Button.drDamageParamStart;
		for index = 1, 10 do
			buttonName = "LunarMenu" .. index .. "Button"
			button = _G[buttonName];
			if button.actionType == "spell" and button.buttonType == 1 and button.spellReagent == nil then
				if LunarSphereSettings.enableDrDamage == true then
					_G[buttonName .. "Count"]:Show()
					_, param[paramOffset + 1] = GetSpellBookItemName(button.actionName);
	--				_, spellRank = GetSpellBookItemName(button.actionName);
					if (string.find(button.actionName, "%(")) then
						spellName = string.match(button.actionName, "(.*)%(");
					else
						spellName = button.actionName;
					end
					param[paramOffset] = spellName;
	--				_G[buttonName .. "Count"]:SetText(DrDamage:CheckAction(_G[buttonName], nil, nil, param[0], param[1], param[2]));
					_G[buttonName .. "Count"]:SetText(DrDamage:CheckAction(nil, nil, nil, spellName, spellRank));
				else
					_G[buttonName .. "Count"]:Hide()
				end
			end
			if LunarSphereSettings.buttonData[index].isMenu then
				for subIndex = 1, 12 do
					buttonName = "LunarSub" .. ((index * 12) - 2 + subIndex) .. "Button";
					button = _G[buttonName];
					if button.actionType == "spell" and button.buttonType == 1 and button.spellReagent == nil then
						if LunarSphereSettings.enableDrDamage == true then
							_G[buttonName .. "Count"]:Show()
							_, param[paramOffset + 1] = GetSpellBookItemName(button.actionName);
	--						_, spellRank = GetSpellBookItemName(button.actionName);
							if (string.find(button.actionName, "%(")) then
								spellName = string.match(button.actionName, "(.*)%(");
							else
								spellName = button.actionName;
							end
							param[paramOffset] = spellName;
	--						_G[buttonName .. "Count"]:SetText(DrDamage:CheckAction(_G[buttonName], nil, nil, param[0], param[1], param[2]));
							_G[buttonName .. "Count"]:SetText(DrDamage:CheckAction(nil, nil, nil, spellName, spellRank));
						else
							_G[buttonName .. "Count"]:Hide()
						end
					end
				end
			end
		end
	--]]
	end

end

function Lunar.API:GetItemCooldown(itemData)

	-- We can take item links, item names, and item IDs. We will need to
	-- convert this data into an item id. Best way to do this for now
	-- if to use GetItemInfo to grab the item link, and from there, we
	-- grab the item ID and return the cooldown from it. Pain in the
	-- ass, but the way we need to do it currently.

	if (itemData == nil) or (itemData == "") then
		return 0, 0, 0;
	end

	local _, itemLink = GetItemInfo(itemData);

	local itemID = Lunar.API:GetItemID(itemLink)

	if (itemID) then
		return Compat.GetItemCooldown(itemID);
	end

	return 0, 0, 0;
end

--end

-- /script LunarSphereSettings.enableDrDamage = false; Lunar.API:SupportForDrDamage();
--
-- Lunar.API:UserGetProfession()
--
-- Argument:
--     None
--
-- Returns :
--     A Value relating to Binary Bits if the Argument is false.
--
-- I came up with this, because GetProfessionInfo( ... ) returns localised profession names
-- and not English (Unless you are running the English Client).  So using it for anything other
-- than labels is impossible.  Using the Icon makes the search easier, as it is should be unique
-- to the Profession.
--
-- I was going to return the Secondary Professions, but you can get that from GetProfessions() anyway.
--
--
-- Crafting Profession returns     Gathering Profesion returns
--    Bin   English                    Bin   English
--      1   Alchemy                    256   Herbalism
--      2   Blacksmith                 512   Mining
--      4   Enchanting                1024   Skinning
--      8   Engineering
--     16   Inscription
--     32   Jewelcrafting
--     64   Leatherworking
--    128   Tailor
--
function Lunar.API:UserGetProfession()

    -- Database Configuration.  Icons and Values.
    --
    ProfDB = {
        [1] = {Icon = "trade_alchemy",                Value = 1},
        [2] = {Icon = "trade_blacksmithing",          Value = 2},
        [3] = {Icon = "trade_engraving",              Value = 4},
        [4] = {Icon = "trade_engineering",            Value = 8},
        [5] = {Icon = "inv_inscription_tradeskill01", Value = 16},
        [6] = {Icon = "inv_misc_gem_01",              Value = 32},
        [7] = {Icon = "trade_leatherworking",         Value = 64},
        [8] = {Icon = "trade_tailoring",              Value = 128},
        [9] = {Icon = "trade_herbalism",              Value = 256},
       [10] = {Icon = "inv_pick_02",                  Value = 512},
       [11] = {Icon = "inv_misc_pelt_wolf_01",        Value = 1024}
    };


    if ( Lunar.API:IsVersionRetail() == false ) then
        return
    end

    -- Set local strings to Nil values.
    --
    local bin_Prof = 0;

    local val_Prof = {};
    val_Prof[1], val_Prof[2] = GetProfessions(); -- Get main Professions. do not bother collecting the rest.  Not needed here.

    -- Get Profession Icon locations.  The only thing that is unique over all Languages.
    --
    local profIndex = 0;
    repeat
        profIndex = profIndex + 1;

        if (val_Prof[profIndex]) then  -- Do I have a profession

            local _, Icon = GetProfessionInfo(val_Prof[profIndex]);  -- Get the Icon for the Profession
            Icon = string.lower(string.sub(Icon, 17));  -- Strip out the 'Interface\\Icons\\' part and make lowercase

            -- Loop run for the Icon to Profession comparison.
            --
            local loopIndex = 1;
            repeat
                if (Icon == ProfDB[loopIndex].Icon) then
                    bin_Prof = bin_Prof + ProfDB[loopIndex].Value;  -- Add the Binary Value.  See ProfDB
                    loopIndex = table.getn(ProfDB); -- Profession has been found,  so why carry on looping.
                end

                loopIndex = loopIndex + 1;
            until (not ProfDB[loopIndex]);  -- Should only be 11,  but room for more.

        end
    until (profIndex == 2); -- Only have 2 main professions

    return bin_Prof;  -- Return Values for binary comparison.
end


--
-- Lunar.API:UserHasProfession(val_Value, bin_Value)
--
-- Argument:
--    val_Value - Crafting or Gathering value returned from UserGetProfession()
--    bin_Value - The Binary value of the Profession you want.
--
-- Returns :
--    not 0 - Yes I have the requested Profession
--        0 - Nope, don't have it.
--
--
-- Crafting Professions            Gathering Profesions
--    Bin                              Bin
--      1   Alchemy                    256   Herbalism
--      2   Blacksmith                 512   Mining
--      4   Enchanting                1024   Skinning
--      8   Engineering
--     16   Inscription
--     32   Jewelcrafting
--     64   Leatherworking
--    128   Tailor
--
--
function Lunar.API:UserHasProfession(val_Value, bit_Value)
    return bit.band(val_Value, bit_Value);
end

--
-- Lunar.API:IsVersionRetail()
--
-- Returns `true` on clients that use the modern (Mainline) API. That includes
-- Midnight and WoW: Forever (which reports a 1.6x interface number, but runs the
-- modern client).
--
function Lunar.API:IsVersionRetail()
	return Lunar.Compat.isModern;
end

-- Lunar.API:IsVersionClassicEra()
--
-- Returns `true` on the Classic Era (Vanilla) clients.
--
function Lunar.API:IsVersionClassicEra()
	return Lunar.Compat.isClassicEra;
end

--
-- Lunar.API:IsVersionClassic()
--
-- Returns `true` on the progression Classic clients (TBC, Wrath, Cata, Mists...).
--
function Lunar.API:IsVersionClassic()
	return Lunar.Compat.isClassic;
end

-- Lunar.API:GetBuildInfo()
-- 
-- Returns the API build number the client is running.
--
-- Returns :
--   The API build number the client is running.
--
function Lunar.API:GetBuildInfo()
	local _, _, _, t = GetBuildInfo();
    return t;
end
if ( Lunar.API:IsVersionClassicEra() ) then

------------------------------------------------------------------------------
------------------------------------------------------------------------------
---                                                                        ---
---                            SoM Functions                               ---
---                                                                        ---
------------------------------------------------------------------------------
------------------------------------------------------------------------------

--
-- Lunar.API:IsFlyableArea()
-- 
-- Checks whether the player's current location is classified as being a 
-- flyable area. Wrapper around `IsFlyableArea()` because the Classic 
-- client doesn't support it.
--
-- Returns :
-- canFly 
--    1 if the area is classified as flyable, nil otherwise.
--
-- Zone ID from
-- https://wowpedia.fandom.com/wiki/UiMapID
--
    function Lunar.API:IsFlyableArea()
        return nil
    end

	function Lunar.API:CountTotalSpells()
		local totalSpells = 0
		for i = 1, GetNumSpellTabs() do
			local numSlots = select(4, GetSpellTabInfo(i))
			totalSpells = totalSpells + numSlots
		end
		return totalSpells
	end

	function Lunar.API:GetSpellName(spellIdentifier)
		local name = select(1, GetSpellInfo(spellIdentifier))
		local subText = GetSpellSubtext(spellIdentifier)
		return name, subText
	end

elseif Lunar.API:IsVersionClassic() then

------------------------------------------------------------------------------
------------------------------------------------------------------------------
---                                                                        ---
---                            WotLK Functions                             ---
---                                                                        ---
------------------------------------------------------------------------------
------------------------------------------------------------------------------

    function Lunar.API:IsFlyableArea()
        local zone_id = C_Map.GetBestMapForUnit("player")
        -- Dalaran. Check if we're in Krasus' Landing
        if( zone_id == 125 ) then
            local x, y = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY()
            x = x*100
            y = y*100

            -- Krasus' Landing center coordinates
            -- x: 0.726104
            -- y: 0.455933
            local d = (x-72.6104)*(x-72.6104)+(y-45.5933)*(y-45.5933)

            --print("2939 Lunar.API:IsFlyableArea() : x, y, d: ",x, y, d)

            -- Cartesian distance to the doorway
            return (d <= 63.24)
        else
            return IsFlyableArea()
        end
    end

	function Lunar.API:CountTotalSpells()
		local totalSpells = 0
		for i = 1, GetNumSpellTabs() do
			local numSlots = select(4, GetSpellTabInfo(i))
			totalSpells = totalSpells + numSlots
		end
		return totalSpells
	end

	function Lunar.API:GetSpellName(spellIdentifier)
		local name = select(1, GetSpellInfo(spellIdentifier))
		local subText = GetSpellSubtext(spellIdentifier)
		return name, subText
	end
else

------------------------------------------------------------------------------
------------------------------------------------------------------------------
---                                                                        ---
---                           Retail Functions                             ---
---                                                                        ---
------------------------------------------------------------------------------
------------------------------------------------------------------------------

    function Lunar.API:IsFlyableArea()
        return IsFlyableArea()
    end

	function Lunar.API:CountTotalSpells()
		local totalSpells = 0
		for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local numSlots = C_SpellBook.GetSpellBookSkillLineInfo(i).numSpellBookItems
			totalSpells = totalSpells + numSlots
		end
		return totalSpells
	end

	function Lunar.API:GetSpellName(spellIdentifier)
		if (spellIdentifier == nil) or (spellIdentifier == "") then
			return nil;
		end
		return C_Spell.GetSpellName(spellIdentifier), nil
	end
end

-- Accepts a spell book slot index (and spell bank), or a spell name / ID.
function Lunar.API:GetSpellBookItemName(spellBookItemSlotIndex, spellBookItemSpellBank)
	return Lunar.Compat.GetSpellBookItemName(spellBookItemSlotIndex, spellBookItemSpellBank);
end
