local DirectiveConstants = require("KnoxNet/modules/directives/base/DirectiveConstants")

---@class BaseDirective
local BaseDirective = {}
BaseDirective.__index = BaseDirective

local rand = newrandom()
local chars = "0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ"

-- Generate a short UUID-like ID (6 characters)
---@param prefix string|nil Optional prefix for the ID
---@return string id The generated ID
function BaseDirective:generateId(prefix)
	prefix = prefix or "dir_"
	local idStr = ""

	for _ = 1, 6 do
		local index = math.floor(rand:random(62)) + 1
		idStr = idStr .. chars:sub(index, index)
	end

	return prefix .. idStr
end

-- Create a new directive instance
---@param data table Initial data for the directive
---@return BaseDirective
function BaseDirective:new(data)
	local directive = {}
	setmetatable(directive, self)

	directive.id = data.id or self:generateId("dir_")
	directive.directiveType = data.directiveType or DirectiveConstants.DIRECTIVE_TYPES.DEFAULT
	directive.title = data.title
		or getText("IGUI_KnoxNet_NewDirective", getText("IGUI_KnoxNet_DirectiveName_" .. directive.directiveType))
	directive.description = data.description or "No description provided."

	directive.useRealDate = data.useRealDate or true
	directive.startDate = data.startDate or self:getCurrentFormattedDate(directive.useRealDate)
	directive.endDate = data.endDate or nil

	directive.isActive = data.isActive or true
	directive.progress = data.progress or 0
	directive.creator = data.creator or "System"
	directive.completed = data.completed or false
	directive.completionDate = data.completionDate or nil

	directive.isCommunityGoal = data.isCommunityGoal or true
	directive.minContributionForReward = data.minContributionForReward or 1

	directive.rewards = data.rewards
		or {
			global = {
				lore = data.rewards and data.rewards.global and data.rewards.global.lore or "",
			},
			individual = {
				items = data.rewards and data.rewards.individual and data.rewards.individual.items or {},
				skills = data.rewards and data.rewards.individual and data.rewards.individual.skills or {},
				custom = data.rewards and data.rewards.individual and data.rewards.individual.custom or {},
			},
		}

	directive.terminalSpecific = data.terminalSpecific or false
	directive.terminalId = data.terminalId or nil

	directive.contributions = data.contributions or {}

	return directive
end

-- Get the current formatted date from the game
---@param useRealDate boolean|nil Whether to use real-world date instead of game date
---@return table date The formatted date table
function BaseDirective:getCurrentFormattedDate(useRealDate)
	if useRealDate then
		local realTime = os.date("*t")
		return {
			min = realTime.min,
			hour = realTime.hour,
			day = realTime.day,
			month = realTime.month,
			year = realTime.year,
		}
	else
		local gameTime = getGameTime()

		if not gameTime then
			return {
				min = 0,
				hour = 0,
				day = 0,
				month = 0,
				year = 0,
			}
		end

		return {
			hour = gameTime:getHour(),
			min = gameTime:getMinutes(),
			day = gameTime:getDay() + 1,
			month = gameTime:getMonth() + 1,
			year = gameTime:getYear(),
		}
	end
end

-- Format date table as string
---@param date table Date table to format
---@return string formattedDate The formatted date string
function BaseDirective:formatDateString(date)
	if not date then
		return "Unknown Date"
	end

	return string.format(
		"%02d:%02d %02d/%02d/%d",
		date.hour or 0,
		date.min or 0,
		date.day or 1,
		date.month or 1,
		date.year or 1993
	)
end

-- Get form fields for editing the directive
---@return table fields Table of form field definitions
function BaseDirective:getFormFields()
	local fields = {
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_Title"),
			type = "text",
			value = self.title,
			key = "title",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_Description"),
			type = "text",
			multiline = true,
			value = self.description,
			key = "description",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_UseRealDate"),
			type = "boolean",
			value = self.useRealDate,
			key = "useRealDate",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_StartDate"),
			type = "date",
			value = self.startDate,
			key = "startDate",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_EndDate"),
			type = "date",
			value = self.endDate,
			key = "endDate",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_IsActive"),
			type = "boolean",
			value = self.isActive,
			key = "isActive",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_IsCommunityGoal"),
			type = "boolean",
			value = self.isCommunityGoal,
			key = "isCommunityGoal",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_MinContrib"),
			type = "number",
			value = self.minContributionForReward,
			key = "minContributionForReward",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_TerminalSpecific"),
			type = "boolean",
			value = self.terminalSpecific,
			key = "terminalSpecific",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_TerminalID"),
			type = "text",
			value = self.terminalId or "",
			key = "terminalId",
			visible = self.terminalSpecific,
		},
		{
			label = "REWARDS",
			type = "section",
			key = "acceptedItemsHeader",
		},
		{
			label = getText("IGUI_KnoxNet_Directive_FormField_GlobalLoreReward"),
			type = "text",
			multiline = true,
			value = self.rewards.global.lore,
			key = "globalLoreReward",
		},
	}

	for i, item in ipairs(self.rewards.individual.items) do
		table.insert(fields, {
			label = getText("IGUI_KnoxNet_Directive_FormField_IndividualItem", i),
			type = "text",
			value = item.item,
			key = "individualItemReward_" .. i .. "_item",
		})
		table.insert(fields, {
			label = getText("IGUI_KnoxNet_Directive_FormField_IndividualItemCount", i),
			type = "number",
			value = item.count,
			key = "individualItemReward_" .. i .. "_count",
		})
	end

	table.insert(fields, {
		label = getText("IGUI_KnoxNet_Directive_FormField_AddIndividualItemReward"),
		type = "button",
		value = "Add",
		key = "addIndividualItemReward",
	})

	for i, skill in ipairs(self.rewards.individual.skills) do
		table.insert(fields, {
			label = getText("IGUI_KnoxNet_Directive_FormField_IndividualSkill", i),
			type = "text",
			value = skill.skill,
			key = "individualSkillReward_" .. i .. "_skill",
		})
		table.insert(fields, {
			label = getText("IGUI_KnoxNet_Directive_FormField_IndividualSkillXP", i),
			type = "number",
			value = skill.xp,
			key = "individualSkillReward_" .. i .. "_xp",
		})
	end

	table.insert(fields, {
		label = getText("IGUI_KnoxNet_Directive_FormField_AddIndividualSkillReward"),
		type = "button",
		value = "Add",
		key = "addIndividualSkillReward",
	})

	return fields
end

-- Apply form field values to directive
---@param fields table Array of form fields with values
function BaseDirective:applyFormFields(fields)
	for _, field in ipairs(fields) do
		if field.key == "title" then
			self.title = field.value
		elseif field.key == "description" then
			self.description = field.value
		elseif field.key == "useRealDate" then
			self.useRealDate = field.value
		elseif field.key == "startDate" then
			self.startDate = field.value ~= "" and field.value or nil
		elseif field.key == "endDate" then
			self.endDate = field.value ~= "" and field.value or nil
		elseif field.key == "isActive" then
			self.isActive = field.value
		elseif field.key == "isCommunityGoal" then
			self.isCommunityGoal = field.value
		elseif field.key == "minContributionForReward" then
			self.minContributionForReward = tonumber(field.value) or 1
		elseif field.key == "terminalSpecific" then
			self.terminalSpecific = field.value
		elseif field.key == "terminalId" then
			self.terminalId = field.value ~= "" and field.value or nil
		elseif field.key == "globalLoreReward" then
			self.rewards.global.lore = field.value
		elseif string.find(field.key, "individualItemReward_") then
			local parts = string.split(field.key, "_")
			local index = tonumber(parts[2]) or 1
			local property = parts[3]

			if property == "item" then
				self.rewards.individual.items[index] = self.rewards.individual.items[index] or {}
				self.rewards.individual.items[index].item = field.value
			elseif property == "count" then
				self.rewards.individual.items[index] = self.rewards.individual.items[index] or {}
				self.rewards.individual.items[index].count = tonumber(field.value) or 1
			end
		elseif string.find(field.key, "individualSkillReward_") then
			local parts = string.split(field.key, "_")
			local index = tonumber(parts[2]) or 1
			local property = parts[3]

			if property == "skill" then
				self.rewards.individual.skills[index] = self.rewards.individual.skills[index] or {}
				self.rewards.individual.skills[index].skill = field.value
			elseif property == "xp" then
				self.rewards.individual.skills[index] = self.rewards.individual.skills[index] or {}
				self.rewards.individual.skills[index].xp = tonumber(field.value) or 1
			end
		elseif field.key == "addIndividualItemReward" and field.clicked then
			table.insert(self.rewards.individual.items, {
				item = "",
				count = 0,
			})
		elseif field.key == "addIndividualSkillReward" and field.clicked then
			table.insert(self.rewards.individual.skills, {
				skill = "",
				xp = 0,
			})
		end
	end
end

-- Generic method for tracking a contribution - to be overridden by directive types
---@param playerId string Player identifier
---@param ... any Additional parameters specific to each directive type
---@return boolean success Whether contribution was successful
function BaseDirective:addContribution(playerId, ...)
	if not self.contributions[playerId] then
		self.contributions[playerId] = {
			total = 0,
		}
	end

	self.contributions[playerId].total = self.contributions[playerId].total + 1

	self:updateProgress()
	return true
end

function BaseDirective:updateProgress()
	local totalContributions = 0
	for _, playerContrib in pairs(self.contributions) do
		totalContributions = totalContributions + playerContrib.total
	end

	local totalNeeded = self:calculateTotalGoal()

	self.progress = math.min(1.0, totalContributions / totalNeeded)

	if self.progress >= 1.0 and not self.completed then
		self:markComplete()
	end
end

-- Calculate total goal for this directive - base version returns 1
---@return number total Total goal required
function BaseDirective:calculateTotalGoal()
	return 1
end

function BaseDirective:markComplete()
	self.isActive = false
	self.completed = true
	self.completionDate = self:getCurrentFormattedDate(self.useRealDate)
	self.progress = 1.0
end

-- Check if a player qualifies for a reward
---@param playerId string The player ID to check
---@return boolean qualifies True if player qualifies for reward
function BaseDirective:qualifiesForReward(playerId)
	if not self.completed then
		return false
	end

	if self.isCommunityGoal then
		return true
	end

	local playerContrib = self.contributions[playerId]
	if not playerContrib then
		return false
	end

	return playerContrib.total >= self.minContributionForReward
end

-- Award rewards to a player
---@param playerId string Player to reward
---@param playerObj IsoPlayer|nil Player object (if available)
---@return boolean success Whether rewards were given
function BaseDirective:awardReward(playerId, playerObj)
	if not self:qualifiesForReward(playerId) then
		return false
	end

	if self.contributions[playerId] and self.contributions[playerId].rewardClaimed then
		return false
	end

	if playerObj then
		local inventory = playerObj:getInventory()

		for _, itemReward in ipairs(self.rewards.individual.items) do
			for i = 1, itemReward.count do
				inventory:AddItem(itemReward.item)
			end
		end

		for _, skillReward in ipairs(self.rewards.individual.skills) do
			playerObj:getXp():AddXP(skillReward.skill, skillReward.xp)
		end

		for _, customReward in ipairs(self.rewards.individual.custom) do
			if customReward.callback and type(customReward.callback) == "function" then
				customReward.callback(playerObj, self)
			end
		end
	end

	if not self.contributions[playerId] then
		self.contributions[playerId] = { total = 0, rewardClaimed = true }
	else
		self.contributions[playerId].rewardClaimed = true
	end

	return true
end

-- Serialize the directive to a table for saving
---@return table data Serialized directive data
function BaseDirective:serialize()
	return {
		id = self.id,
		directiveType = self.directiveType,
		title = self.title,
		description = self.description,
		startDate = self.startDate,
		endDate = self.endDate,
		useRealDate = self.useRealDate,
		isActive = self.isActive,
		progress = self.progress,
		creator = self.creator,
		completed = self.completed,
		completionDate = self.completionDate,
		isCommunityGoal = self.isCommunityGoal,
		minContributionForReward = self.minContributionForReward,
		rewards = self.rewards,
		terminalSpecific = self.terminalSpecific,
		terminalId = self.terminalId,
		contributions = self.contributions,
	}
end

-- Deserialize directive data
---@param data table The serialized directive data
function BaseDirective:deserialize(data)
	self.id = data.id
	self.directiveType = data.directiveType or DirectiveConstants.DIRECTIVE_TYPES.DEFAULT
	self.title = data.title
	self.description = data.description
	self.startDate = data.startDate
	self.endDate = data.endDate
	self.useRealDate = data.useRealDate
	self.isActive = data.isActive
	self.progress = data.progress
	self.creator = data.creator
	self.completed = data.completed
	self.completionDate = data.completionDate
	self.isCommunityGoal = data.isCommunityGoal
	self.minContributionForReward = data.minContributionForReward
	self.rewards = data.rewards
	self.terminalSpecific = data.terminalSpecific
	self.terminalId = data.terminalId
	self.contributions = data.contributions or {}

	self:updateProgress()
end

return BaseDirective
