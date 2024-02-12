---@class BetterBags: AceAddon
local addonBetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")
---@class Categories: AceModule
local categories = addonBetterBags:GetModule('Categories')
---@class Localization: AceModule
local L = addonBetterBags:GetModule('Localization')

local debug = false
local frame = CreateFrame("Frame", nil)
local categoryName = "Sets"
-------------------------------------------------------
local function printChat(message)
	if debug == true then
		print("[BetterBags ItemRack] "..message)
	end
end

local function split(s, sep)
	local fields = {}
	
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	
	return fields
end

local function updateCategory()
	-- Wipe category since we can't retrieve deleted set from itemRack (Except maybe store duplicate of sets and check last version of it)
	categories:WipeCategory(L:G(categoryName))

	-- Loop all sets
	for setName, _ in pairs(ItemRackUser.Sets) do
		-- Only update user sets (internals start with '~')
		if not string.match(setName, "^~") then
			printChat("Updating set: " .. setName)
			-- Loop all items of set
			for _, item in pairs(ItemRackUser.Sets[setName].equip) do
				local id = tonumber(split(item, ":")[1])
				--printChat(id)
				--printChat(GetItemInfo(ItemRack.IRStringToItemString(item)))
				categories:AddItemToCategory(id, L:G(categoryName))
				printChat("Added item '" .. id .. "' to '" .. categoryName .. "' category")
			end	
		else
			printChat("Skipping internal set: " .. setName)
		end
	end
end

local function itemRackUpdated(event, _)
	printChat(event)
	updateCategory()
end
-------------------------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon, ...)
	if event == "ADDON_LOADED" and addon == "ItemRack" then
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_SAVED", itemRackUpdated)
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_DELETED", itemRackUpdated)

		printChat("ItemRack Loaded.. Initializing Category")
		updateCategory()
	end
end)