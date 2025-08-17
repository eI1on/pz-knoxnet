local DirectiveConstants = require("KnoxNet_DirectivesModule/core/DirectiveConstants")
local DirectiveUIHelper = require("KnoxNet_DirectivesModule/ui/DirectiveUIHelper")
local TextWrapper = require("KnoxNet/ui/TextWrapper")

---@class DirectiveRenderer
local DirectiveRenderer = {}

--- Render a single directive item in a list
---@param terminal table Terminal rendering object
---@param directive table Directive to render
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param isSelected boolean Whether item is selected
---@param isEditable boolean Whether item is editable
function DirectiveRenderer.renderDirectiveItem(terminal, directive, x, y, width, height, isSelected, isEditable)
	if not directive then
		return
	end

	local itemPadding = DirectiveConstants.LAYOUT.CONTENT.PADDING_X
	local itemWidth = width
		- 2 * itemPadding
		- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
		- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING

	local bgColor = isSelected and DirectiveConstants.COLORS.ITEM.SELECTED or DirectiveConstants.COLORS.ITEM.BACKGROUND
	terminal:drawRect(x, y, width, height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

	local borderColor = isSelected and { a = 0.9, r = 0.4, g = 0.8, b = 0.4 } or DirectiveConstants.COLORS.BORDER

	terminal:drawRectBorder(x, y, width, height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)

	local contentY = y + itemPadding

	local titleY = contentY
	local statusText = directive.isActive and "[ACTIVE]" or "[COMPLETED]"
	local titleText = directive.title

	local textColor = {
		r = DirectiveConstants.COLORS.TEXT.NORMAL.r,
		g = DirectiveConstants.COLORS.TEXT.NORMAL.g,
		b = DirectiveConstants.COLORS.TEXT.NORMAL.b,
		a = DirectiveConstants.COLORS.TEXT.NORMAL.a,
	}

	if isSelected then
		textColor.r = math.min(1.0, textColor.r * 1.2)
		textColor.g = math.min(1.0, textColor.g * 1.2)
		textColor.b = math.min(1.0, textColor.b * 1.2)
	end

	terminal:drawText(
		titleText,
		x + itemPadding,
		titleY,
		textColor.r,
		textColor.g,
		textColor.b,
		textColor.a,
		DirectiveConstants.LAYOUT.FONT.MEDIUM
	)

	local statusWidth = getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.SMALL, statusText)
	terminal:drawText(
		statusText,
		x + width - statusWidth - itemPadding,
		titleY,
		DirectiveConstants.COLORS.TEXT.DIM.r,
		DirectiveConstants.COLORS.TEXT.DIM.g,
		DirectiveConstants.COLORS.TEXT.DIM.b,
		DirectiveConstants.COLORS.TEXT.DIM.a,
		DirectiveConstants.LAYOUT.FONT.SMALL
	)

	local descY = titleY + 20
	local descText = directive.description
	if #descText > 50 then
		descText = string.sub(descText, 1, 50) .. "..."
	end

	terminal:drawText(
		descText,
		x + itemPadding,
		descY,
		DirectiveConstants.COLORS.TEXT.DIM.r,
		DirectiveConstants.COLORS.TEXT.DIM.g,
		DirectiveConstants.COLORS.TEXT.DIM.b,
		DirectiveConstants.COLORS.TEXT.DIM.a,
		DirectiveConstants.LAYOUT.FONT.SMALL
	)

	local progressBarY = descY + 25
	local progressBarHeight = 10
	local progressBarWidth = itemWidth - 2 * itemPadding

	DirectiveUIHelper.drawProgressBar(
		terminal,
		x + itemPadding,
		progressBarY,
		progressBarWidth,
		progressBarHeight,
		directive.progress,
		true
	)

	local dateY = progressBarY + progressBarHeight + 10
	local dateText = "Started: " .. DirectiveUIHelper.formatDateTable(directive.startDate)

	if directive.completed then
		dateText = dateText .. " | Completed: " .. DirectiveUIHelper.formatDateTable(directive.completionDate)
	elseif directive.endDate then
		dateText = dateText .. " | Ends: " .. DirectiveUIHelper.formatDateTable(directive.endDate)
	end

	terminal:drawText(
		dateText,
		x + itemPadding,
		dateY,
		DirectiveConstants.COLORS.TEXT.DIM.r,
		DirectiveConstants.COLORS.TEXT.DIM.g,
		DirectiveConstants.COLORS.TEXT.DIM.b,
		DirectiveConstants.COLORS.TEXT.DIM.a,
		DirectiveConstants.LAYOUT.FONT.SMALL
	)

	if isEditable then
		local editY = dateY + 15
		local editText = "Press SPACE to edit"

		terminal:drawText(
			editText,
			x + itemPadding,
			editY,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			DirectiveConstants.LAYOUT.FONT.SMALL
		)
	end
end

--- Render a detailed view of a directive
---@param terminal table Terminal rendering object
---@param directive table Directive to render
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param scrollOffset number Vertical scroll offset
---@param isAdmin boolean Whether user has admin privileges
---@return number contentHeight Total content height
function DirectiveRenderer.renderDirectiveDetails(terminal, directive, x, y, width, height, scrollOffset, isAdmin)
	local initialY = y
	local currentY = y - scrollOffset
	local startX = x + DirectiveConstants.LAYOUT.CONTENT.PADDING_X
	local contentWidth = width - (2 * DirectiveConstants.LAYOUT.CONTENT.PADDING_X)

	local statusText = directive.isActive and "STATUS: ACTIVE" or "STATUS: COMPLETED"
	local dateText = "Started: " .. DirectiveUIHelper.formatDateTable(directive.startDate)

	if directive.completed then
		dateText = dateText .. " | Completed: " .. DirectiveUIHelper.formatDateTable(directive.completionDate)
	elseif directive.endDate then
		dateText = dateText .. " | Ends: " .. DirectiveUIHelper.formatDateTable(directive.endDate)
	end

	local typeText = "Type: " .. (directive.directiveType or "Unknown")
	local dateTypeText = directive.useRealDate and "(Real-world date)" or "(Game date)"

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			statusText,
			startX,
			currentY,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)

		local typeWidth = getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.CODE, typeText)
		terminal:drawText(
			typeText,
			startX + contentWidth - typeWidth,
			currentY,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
	end

	currentY = currentY + 20

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			dateText,
			startX,
			currentY,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)

		local dateTypeWidth = getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.CODE, dateTypeText)
		terminal:drawText(
			dateTypeText,
			startX + contentWidth - dateTypeWidth,
			currentY,
			DirectiveConstants.COLORS.TEXT.DIM.r,
			DirectiveConstants.COLORS.TEXT.DIM.g,
			DirectiveConstants.COLORS.TEXT.DIM.b,
			DirectiveConstants.COLORS.TEXT.DIM.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
	end

	currentY = currentY + 30
	local descriptionLines = TextWrapper.wrap(directive.description, contentWidth, DirectiveConstants.LAYOUT.FONT.CODE)

	if descriptionLines then
		for i = 1, #descriptionLines do
			local line = descriptionLines[i]
			local lineY = currentY + (i - 1) * 20
			if lineY >= y and lineY < y + height then
				terminal:drawText(
					line,
					startX,
					lineY,
					DirectiveConstants.COLORS.TEXT.NORMAL.r,
					DirectiveConstants.COLORS.TEXT.NORMAL.g,
					DirectiveConstants.COLORS.TEXT.NORMAL.b,
					DirectiveConstants.COLORS.TEXT.NORMAL.a,
					DirectiveConstants.LAYOUT.FONT.CODE
				)
			end
		end
	end

	currentY = currentY + (#descriptionLines * 20) + 20

	local progressText = "PROGRESS: " .. string.format("%d%%", math.floor(directive.progress * 100))

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			progressText,
			startX,
			currentY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
	end

	currentY = currentY + 25

	local barY = currentY
	local barWidth = contentWidth
	local barHeight = 15

	if barY >= y and barY + barHeight <= y + height then
		DirectiveUIHelper.drawProgressBar(terminal, startX, barY, barWidth, barHeight, directive.progress, true)
	end

	currentY = barY + barHeight + 30

	if directive.directiveType == DirectiveConstants.DIRECTIVE_TYPES.SCAVENGE then
		currentY = DirectiveRenderer.renderScavengeDirectiveDetails(
			terminal,
			directive,
			startX,
			currentY,
			contentWidth,
			y,
			height
		)
	end

	currentY = currentY + 30

	local rewardsText = "REWARDS:"

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			rewardsText,
			startX,
			currentY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
	end

	currentY = currentY + 20

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			"Community Rewards:",
			startX + 20,
			currentY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.SMALL
		)
	end

	currentY = currentY + 20

	if
		directive.rewards
		and directive.rewards.global
		and directive.rewards.global.lore
		and directive.rewards.global.lore ~= ""
	then
		local loreText = "Lore: " .. directive.rewards.global.lore
		local loreLines = TextWrapper.wrap(loreText, contentWidth - 40, DirectiveConstants.LAYOUT.FONT.SMALL)

		for i, line in ipairs(loreLines) do
			local lineY = currentY + (i - 1) * 15
			if lineY >= y and lineY < y + height then
				terminal:drawText(
					line,
					startX + 40,
					lineY,
					DirectiveConstants.COLORS.TEXT.NORMAL.r,
					DirectiveConstants.COLORS.TEXT.NORMAL.g,
					DirectiveConstants.COLORS.TEXT.NORMAL.b,
					DirectiveConstants.COLORS.TEXT.NORMAL.a,
					DirectiveConstants.LAYOUT.FONT.SMALL
				)
			end
		end

		currentY = currentY + (#loreLines * 15)
	end

	currentY = currentY + 20

	if currentY >= y and currentY < y + height then
		terminal:drawText(
			"Individual Rewards:",
			startX + 20,
			currentY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.SMALL
		)
	end

	currentY = currentY + 20

	if directive.rewards and directive.rewards.individual then
		if directive.rewards.individual.items and #directive.rewards.individual.items > 0 then
			for i, itemReward in ipairs(directive.rewards.individual.items) do
				local itemText = "• " .. itemReward.item
				if itemReward.count and itemReward.count > 1 then
					itemText = itemText .. " x" .. itemReward.count
				end

				if currentY >= y and currentY < y + height then
					terminal:drawText(
						itemText,
						startX + 40,
						currentY,
						DirectiveConstants.COLORS.TEXT.NORMAL.r,
						DirectiveConstants.COLORS.TEXT.NORMAL.g,
						DirectiveConstants.COLORS.TEXT.NORMAL.b,
						DirectiveConstants.COLORS.TEXT.NORMAL.a,
						DirectiveConstants.LAYOUT.FONT.SMALL
					)
				end

				currentY = currentY + 15
			end
		end

		if directive.rewards.individual.skills and #directive.rewards.individual.skills > 0 then
			currentY = currentY + 5

			for i, skillReward in ipairs(directive.rewards.individual.skills) do
				local skillText = "• " .. skillReward.skill
				if skillReward.xp then
					skillText = skillText .. " +" .. skillReward.xp .. " XP"
				end

				if currentY >= y and currentY < y + height then
					terminal:drawText(
						skillText,
						startX + 40,
						currentY,
						DirectiveConstants.COLORS.TEXT.NORMAL.r,
						DirectiveConstants.COLORS.TEXT.NORMAL.g,
						DirectiveConstants.COLORS.TEXT.NORMAL.b,
						DirectiveConstants.COLORS.TEXT.NORMAL.a,
						DirectiveConstants.LAYOUT.FONT.SMALL
					)
				end

				currentY = currentY + 15
			end
		end
	end

	if isAdmin then
		currentY = currentY + 20

		if currentY >= y and currentY < y + height then
			local creatorText = "Created by: " .. directive.creator

			terminal:drawText(
				creatorText,
				startX,
				currentY,
				DirectiveConstants.COLORS.TEXT.DIM.r,
				DirectiveConstants.COLORS.TEXT.DIM.g,
				DirectiveConstants.COLORS.TEXT.DIM.b,
				DirectiveConstants.COLORS.TEXT.DIM.a,
				DirectiveConstants.LAYOUT.FONT.SMALL
			)

			local idText = "ID: " .. directive.id
			local idWidth = getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.SMALL, idText)

			terminal:drawText(
				idText,
				x + width - DirectiveConstants.LAYOUT.CONTENT.PADDING_X - idWidth,
				currentY,
				DirectiveConstants.COLORS.TEXT.DIM.r,
				DirectiveConstants.COLORS.TEXT.DIM.g,
				DirectiveConstants.COLORS.TEXT.DIM.b,
				DirectiveConstants.COLORS.TEXT.DIM.a,
				DirectiveConstants.LAYOUT.FONT.SMALL
			)
		end

		currentY = currentY + 20
	end

	currentY = currentY + 5

	terminal.buttonAreaY = currentY - scrollOffset

	local totalContentHeight = currentY + DirectiveConstants.LAYOUT.BUTTON.HEIGHT - initialY
	return totalContentHeight
end

--- Render Scavenge directive-specific details
---@param terminal table Terminal rendering object
---@param directive table Directive to render
---@param startX number X position
---@param currentY number Current Y position
---@param contentWidth number Available content width
---@param minY number Minimum visible Y
---@param maxY number Maximum visible Y
---@return number nextY Next Y position after rendering
function DirectiveRenderer.renderScavengeDirectiveDetails(
	terminal,
	directive,
	startX,
	currentY,
	contentWidth,
	minY,
	maxY
)
	local itemsText = "ITEMS REQUIRED:"

	if currentY >= minY and currentY < maxY then
		terminal:drawText(
			itemsText,
			startX,
			currentY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
	end

	currentY = currentY + 20

	if directive.minContributionForReward and directive.minContributionForReward > 1 then
		local minContribText = "Minimum Contribution for Rewards: " .. directive.minContributionForReward .. " items"

		if currentY >= minY and currentY < maxY then
			terminal:drawText(
				minContribText,
				startX,
				currentY,
				DirectiveConstants.COLORS.TEXT.DIM.r,
				DirectiveConstants.COLORS.TEXT.DIM.g,
				DirectiveConstants.COLORS.TEXT.DIM.b,
				DirectiveConstants.COLORS.TEXT.DIM.a,
				DirectiveConstants.LAYOUT.FONT.SMALL
			)
		end

		currentY = currentY + 20
	end

	if directive.acceptedItems and #directive.acceptedItems > 0 then
		for i, item in ipairs(directive.acceptedItems) do
			local itemText = "• " .. item.item .. ": " .. item.collected .. "/" .. item.count

			if item.minCondition and item.minCondition > 0 then
				itemText = itemText .. string.format(" (Condition ≥ %.0f%%)", item.minCondition * 100)
			end

			if item.minUses and item.minUses > 0 then
				itemText = itemText .. string.format(" (Uses ≥ %d)", item.minUses)
			end

			if currentY >= minY and currentY < maxY then
				local textColor
				if item.collected >= item.count then
					textColor = DirectiveConstants.COLORS.TEXT.HIGHLIGHT
				else
					textColor = DirectiveConstants.COLORS.TEXT.NORMAL
				end

				terminal:drawText(
					itemText,
					startX + 20,
					currentY,
					textColor.r,
					textColor.g,
					textColor.b,
					textColor.a,
					DirectiveConstants.LAYOUT.FONT.SMALL
				)
			end

			currentY = currentY + 20
		end
	else
		if currentY >= minY and currentY < maxY then
			terminal:drawText(
				"No specific items defined",
				startX + 20,
				currentY,
				DirectiveConstants.COLORS.TEXT.DIM.r,
				DirectiveConstants.COLORS.TEXT.DIM.g,
				DirectiveConstants.COLORS.TEXT.DIM.b,
				DirectiveConstants.COLORS.TEXT.DIM.a,
				DirectiveConstants.LAYOUT.FONT.SMALL
			)
		end

		currentY = currentY + 20
	end

	return currentY
end

return DirectiveRenderer
