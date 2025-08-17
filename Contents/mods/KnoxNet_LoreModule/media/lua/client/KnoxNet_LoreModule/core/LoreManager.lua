local TerminalConstants = require("KnoxNet/core/TerminalConstants")

---@class LoreManager
local LoreManager = {}

LoreManager.categories = {}
LoreManager.entries = {}

LoreManager.ENTRY_TYPES = {
	TEXT = "text",
	AUDIO = "audio",
	BOTH = "both",
}

function LoreManager.init()
	LoreManager.loadLoreData()
end

-- Add a new lore category
---@param name string Category name
---@param description string Category description
---@return string categoryId The ID of the new category
function LoreManager.addCategory(name, description)
	local categoryId = "cat_" .. LoreManager.generateId()

	table.insert(LoreManager.categories, {
		id = categoryId,
		name = name,
		description = description,
		entries = {},
	})

	LoreManager.saveLoreData()
	return categoryId
end

-- Update an existing category
---@param categoryId string Category ID
---@param name string New category name
---@param description string New category description
---@return boolean success Whether the update was successful
function LoreManager.updateCategory(categoryId, name, description)
	for i, category in ipairs(LoreManager.categories) do
		if category.id == categoryId then
			category.name = name
			category.description = description
			LoreManager.saveLoreData()
			return true
		end
	end

	return false
end

-- Delete a category and all its entries
---@param categoryId string Category ID
---@return boolean success Whether the deletion was successful
function LoreManager.deleteCategory(categoryId)
	for i = 1, #LoreManager.categories do
		local category = LoreManager.categories[i]
		if category.id == categoryId then
			if category.entries then
				for j = 1, #category.entries do
					for k = 1, #LoreManager.entries do
						local entry = LoreManager.entries[k]
						if entry.id == category.entries[j] then
							table.remove(LoreManager.entries, k)
							break
						end
					end
				end
			end

			table.remove(LoreManager.categories, i)
			LoreManager.saveLoreData()
			return true
		end
	end

	return false
end

-- Add a new lore entry
---@param categoryId string Category ID
---@param title string Entry title
---@param content string Entry text content
---@param audioFile string|nil Path to audio file (optional)
---@param requiresCassette boolean Whether this entry requires a cassette
---@param cassetteName string|nil Custom cassette name (optional)
---@param date string|nil Date of the entry (optional)
---@return string|nil entryId The ID of the new entry, or nil if category not found
function LoreManager.addEntry(categoryId, title, content, audioFile, requiresCassette, cassetteName, date)
	local categoryIndex = LoreManager.findCategoryIndex(categoryId)
	if not categoryIndex then
		return nil
	end

	local entryId = "entry_" .. LoreManager.generateId()
	local entryType = LoreManager.ENTRY_TYPES.TEXT

	if audioFile and audioFile ~= "" then
		entryType = content and content ~= "" and LoreManager.ENTRY_TYPES.BOTH or LoreManager.ENTRY_TYPES.AUDIO
	end

	if not cassetteName or cassetteName == "" then
		cassetteName = "Lore Cassette: " .. title
	end

	local newEntry = {
		id = entryId,
		title = title,
		content = content,
		audioFile = audioFile,
		requiresCassette = requiresCassette,
		cassetteName = cassetteName,
		date = date,
		entryType = entryType,
		categoryId = categoryId,
	}

	table.insert(LoreManager.entries, newEntry)

	local category = LoreManager.categories[categoryIndex]
	if not category.entries then
		category.entries = {}
	end
	table.insert(category.entries, entryId)

	LoreManager.saveLoreData()
	return entryId
end

-- Update an existing lore entry
---@param entryId string Entry ID
---@param title string New title
---@param content string New content
---@param audioFile string|nil New audio file
---@param requiresCassette boolean Whether this entry requires a cassette
---@param cassetteName string|nil New cassette name
---@param date string|nil New date
---@param categoryId string|nil New category ID (to move entry)
---@return boolean success Whether the update was successful
function LoreManager.updateEntry(entryId, title, content, audioFile, requiresCassette, cassetteName, date, categoryId)
	local entryIndex = LoreManager.findEntryIndex(entryId)
	if not entryIndex then
		return false
	end

	local entry = LoreManager.entries[entryIndex]
	local oldCategoryId = entry.categoryId

	local entryType = LoreManager.ENTRY_TYPES.TEXT
	if audioFile and audioFile ~= "" then
		entryType = content and content ~= "" and LoreManager.ENTRY_TYPES.BOTH or LoreManager.ENTRY_TYPES.AUDIO
	end

	entry.title = title
	entry.content = content
	entry.audioFile = audioFile
	entry.requiresCassette = requiresCassette
	entry.cassetteName = cassetteName or ("Lore Cassette: " .. title)
	entry.date = date
	entry.entryType = entryType

	if categoryId and categoryId ~= oldCategoryId then
		local oldCategoryIndex = LoreManager.findCategoryIndex(oldCategoryId)
		local newCategoryIndex = LoreManager.findCategoryIndex(categoryId)

		if oldCategoryIndex and newCategoryIndex then
			local oldCategory = LoreManager.categories[oldCategoryIndex]
			local newCategory = LoreManager.categories[newCategoryIndex]

			for i, id in ipairs(oldCategory.entries) do
				if id == entryId then
					table.remove(oldCategory.entries, i)
					break
				end
			end

			if not newCategory.entries then
				newCategory.entries = {}
			end
			table.insert(newCategory.entries, entryId)

			entry.categoryId = categoryId
		end
	end

	LoreManager.saveLoreData()
	return true
end

-- Delete a lore entry
---@param entryId string Entry ID
---@return boolean success Whether the deletion was successful
function LoreManager.deleteEntry(entryId)
	local entryIndex = LoreManager.findEntryIndex(entryId)
	if not entryIndex then
		return false
	end

	local entry = LoreManager.entries[entryIndex]
	local categoryIndex = LoreManager.findCategoryIndex(entry.categoryId)

	if categoryIndex then
		local category = LoreManager.categories[categoryIndex]
		for i, id in ipairs(category.entries) do
			if id == entryId then
				table.remove(category.entries, i)
				break
			end
		end
	end

	table.remove(LoreManager.entries, entryIndex)

	LoreManager.saveLoreData()
	return true
end

-- Get all categories with their entries
---@return table categories Array of category objects
function LoreManager.getCategories()
	local result = {}

	for _, category in ipairs(LoreManager.categories) do
		local categoryData = {
			id = category.id,
			name = category.name,
			description = category.description,
			entries = {},
		}

		if category.entries then
			for _, entryId in ipairs(category.entries) do
				local entry = LoreManager.getEntryById(entryId)
				if entry then
					table.insert(categoryData.entries, entry)
				end
			end
		end

		table.insert(result, categoryData)
	end

	return result
end

-- Get all entries
---@return table entries Array of entry objects
function LoreManager.getEntries()
	return LoreManager.entries
end

-- Get a single entry by ID
---@param entryId string Entry ID
---@return table|nil entry The entry object or nil if not found
function LoreManager.getEntryById(entryId)
	for _, entry in ipairs(LoreManager.entries) do
		if entry.id == entryId then
			return entry
		end
	end

	return nil
end

-- Find the index of a category by ID
---@param categoryId string Category ID
---@return number|nil index Index of the category or nil if not found
function LoreManager.findCategoryIndex(categoryId)
	for i, category in ipairs(LoreManager.categories) do
		if category.id == categoryId then
			return i
		end
	end

	return nil
end

-- Find the index of an entry by ID
---@param entryId string Entry ID
---@return number|nil index Index of the entry or nil if not found
function LoreManager.findEntryIndex(entryId)
	for i, entry in ipairs(LoreManager.entries) do
		if entry.id == entryId then
			return i
		end
	end

	return nil
end

-- Generate a random ID
---@return string id Random ID
function LoreManager.generateId()
	local chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local id = ""

	for i = 1, 8 do
		local randomIndex = ZombRand(1, #chars + 1)
		id = id .. string.sub(chars, randomIndex, randomIndex)
	end

	return id
end

function LoreManager.saveLoreData()
	ModData.add("KnoxNet_LoreCategories", LoreManager.categories)
	ModData.add("KnoxNet_LoreEntries", LoreManager.entries)
	ModData.transmit("KnoxNet_LoreCategories")
	ModData.transmit("KnoxNet_LoreEntries")
end

function LoreManager.loadLoreData()
	local categories = ModData.get("KnoxNet_LoreCategories")
	local entries = ModData.get("KnoxNet_LoreEntries")

	if categories then
		LoreManager.categories = categories
	end

	if entries then
		LoreManager.entries = entries
	end

	if #LoreManager.categories == 0 then
		LoreManager.addCategory("General Information", "General information about Knox County and the outbreak.")
	end

	if #LoreManager.entries == 0 and getDebug() then
		LoreManager.addEntry(
			LoreManager.categories[1].id,
			"Welcome to Knox County",
			"Welcome to the Knox County Emergency Network (KnoxNet). This system has been established to provide critical information during the ongoing crisis.\n\nThe Knox County authorities are working diligently to contain the situation. Please follow all emergency protocols and stay tuned for further instructions.",
			nil,
			false,
			nil,
			"1993-07-04"
		)

		LoreManager.addEntry(
			LoreManager.categories[1].id,
			"Evacuation Protocol",
			"Knox County evacuation protocol is now in effect. All citizens should proceed to designated evacuation centers.\n\nBring only essential items. Do not attempt to drive personal vehicles outside the county. Military transport will be provided.",
			"media/sound/knoxnet_evac_alert.ogg",
			true,
			"Evacuation Protocol Tape",
			"1993-07-08"
		)
	end
end

LoreManager.init()

return LoreManager
