---@class BetterBags: AceAddon
local addonBetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")
---@class Categories: AceModule
local categories = addonBetterBags:GetModule('Categories')
---@class Localization: AceModule
local L = addonBetterBags:GetModule('Localization')
---@class Context: AceModule
local context = addonBetterBags:GetModule('Context')

local debug = false
local frame = CreateFrame("Frame", nil)

local customCategories = {}

-------------------------------------------------------

local function printChat(message)
	if debug == true then
		print("[BetterBags ItemRack] " .. tostring(message))
	end
end

local function split(s, sep)
	local fields = {}

	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)

	---@diagnostic disable-next-line: discard-returns
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
end

local function getContextName(name)
	return "BetterBags_ItemRack_" .. name
end

local function updateCategories()
	-- Wipe custom categories since we can't retrieve deleted set from ItemRack (Except maybe store duplicate of sets and check last version of it)
	for category, _ in pairs(customCategories) do
		local ctx = context:New(getContextName("Deletion"))
		categories:DeleteCategory(ctx, L:G(category))
		printChat("Deleted category '" .. L:G(category) .. "'")
	end

	-- Reset list of in-use categories
	customCategories = {}

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
					-- Extend existing labels and filter duplicate items per set
					elseif usedItems[id][setName] ~= nil then
						table.insert(usedItems[id], setName)
					end
				end
			end
		else
			printChat("Skipping internal set: " .. setName)
		end
	end

	-- Loop collected items and add them to their respective categories
	for itemId, itemSets in pairs(usedItems) do
		local label = nil

		if #itemSets == 1 then
			label = "Set: " .. itemSets[1]
		else
			label = "Sets: ".. table.concat(itemSets, ", ")
		end

		local categoryItemList = customCategories[L:G(label)]

		if categoryItemList then
			customCategories[L:G(label)][itemId] = true
		else
			customCategories[L:G(label)] = {[itemId] = true}
		end
		-- printChat("Added item '" .. item .. "' to '" .. label .. "' category")
	end

	for category, items in pairs(customCategories) do
		local ctx = context:New(getContextName("Creation"))
		categories:CreateCategory(ctx, {
			name = L:G(category),
			itemList = items,
			note = "Created by BetterBags_ItemRack plugin",
			save = false
		})

		printChat("Created category '" .. category .. "' with item list: [" .. table.concat(items, ",") .. "]")
	end

	-- Force a refresh in BetterBags
	local ctx = context:New(getContextName("Refresh"))
	categories:ReprocessAllItems(ctx)
end

local function initCategories()
	printChat("Initializing Categories..")
	updateCategories()
end

local function itemRackUpdated(event, eventData)
	printChat(event)
	updateCategories()
end

-------------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon, ...)
	-- Technically since we don't use saved variables anymore waiting here isn't necessary, but doesn't hurt
	if event == "ADDON_LOADED" and addon == "BetterBags_ItemRack" then
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_SAVED", itemRackUpdated)
		ItemRack:RegisterExternalEventListener("ITEMRACK_SET_DELETED", itemRackUpdated)

		initCategories()
	end
end)
