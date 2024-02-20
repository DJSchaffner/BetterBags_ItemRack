---@class BetterBags: AceAddon
local addonBetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")
---@class Categories: AceModule
local categories = addonBetterBags:GetModule('Categories')
---@class Localization: AceModule
local L = addonBetterBags:GetModule('Localization')

local debug = false
local frame = CreateFrame("Frame", nil)
local labels = {}
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

local function updateCategories()
	-- Wipe custom categories since we can't retrieve deleted set from itemRack (Except maybe store duplicate of sets and check last version of it)
	for label, _ in pairs(labels) do
		-- @TODO completely remove label as custom category from BetterBags
		categories:WipeCategory(L:G(label))
	end

	-- Keep track of all used items and their associated sets
	local usedItems = {}

	-- Loop all sets and collect items
	for setName, _ in pairs(ItemRackUser.Sets) do
		-- Only update user sets (internals start with '~')
		if not string.match(setName, "^~") then
			printChat("Updating set: " .. setName)
			-- Loop all items of set
			for _, item in pairs(ItemRackUser.Sets[setName].equip) do
				local id = tonumber(split(item, ":")[1])

				-- Adding items that don't exist causes errors
				if id ~= 0 then
					local itemSets = usedItems[id]

					if itemSets == nil then
						usedItems[id] = { setName }
						-- Extend existing labels
					else
						table.insert(usedItems[id], setName)
					end
				end
			end
		else
			printChat("Skipping internal set: " .. setName)
		end
	end
	
	-- Loop collected items and add them to their respective categories
	for item, sets in pairs(usedItems) do
		local label = nil

		if #sets == 1 then
			label = "Set: " .. sets[1]
		else
			label = "Sets: ".. table.concat(sets, ", ")
		end

		table.insert(labels, L:G(label))
		categories:AddItemToCategory(item, L:G(label))
		-- printChat("Added item '" .. id .. "' to '" .. categoryName .. "' category")
	end
end


local function itemRackUpdated(event, eventData)
	printChat(event)
	updateCategories()
end
-------------------------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon, ...)
	if event == "ADDON_LOADED" and addon == "ItemRack" then
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_SAVED", itemRackUpdated)
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_DELETED", itemRackUpdated)
		

		printChat("ItemRack Loaded..")
		printChat("Initializing Category..")
		updateCategories()
	end
end)