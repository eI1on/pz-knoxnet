local DirectiveConstants = require("KnoxNet/modules/directives/base/DirectiveConstants")

---@class DirectiveUIHelper
local DirectiveUIHelper = {}

--- Draw a scrollbar
---@param terminal table Terminal rendering object
---@param x number X position
---@param y number Y position
---@param height number Height of scrollbar area
---@param contentHeight number Total content height
---@param visibleHeight number Visible content height
---@param scrollOffset number Current scroll offset
---@return number handleY Y position of handle
---@return number handleHeight Height of handle
function DirectiveUIHelper.drawScrollbar(terminal, x, y, height, contentHeight, visibleHeight, scrollOffset)
	terminal:drawRect(
		x,
		y,
		DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH,
		height,
		DirectiveConstants.COLORS.SCROLLBAR.BACKGROUND.a,
		DirectiveConstants.COLORS.SCROLLBAR.BACKGROUND.r,
		DirectiveConstants.COLORS.SCROLLBAR.BACKGROUND.g,
		DirectiveConstants.COLORS.SCROLLBAR.BACKGROUND.b
	)

	local handleRatio = math.min(1.0, visibleHeight / contentHeight)
	local handleHeight = math.max(DirectiveConstants.LAYOUT.SCROLLBAR.MIN_HANDLE_HEIGHT, handleRatio * height)

	local maxScrollOffset = math.max(0.1, contentHeight - visibleHeight)
	local scrollRatio = scrollOffset / maxScrollOffset
	if scrollRatio > 1 then
		scrollRatio = 1
	end
	if scrollRatio < 0 then
		scrollRatio = 0
	end

	local availableTrackSpace = height - handleHeight
	local handleY = y
	if availableTrackSpace > 0 then
		handleY = y + (scrollRatio * availableTrackSpace)
	end

	terminal:drawRect(
		x,
		handleY,
		DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH,
		handleHeight,
		DirectiveConstants.COLORS.SCROLLBAR.HANDLE.a,
		DirectiveConstants.COLORS.SCROLLBAR.HANDLE.r,
		DirectiveConstants.COLORS.SCROLLBAR.HANDLE.g,
		DirectiveConstants.COLORS.SCROLLBAR.HANDLE.b
	)

	terminal:drawRectBorder(
		x,
		handleY,
		DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH,
		handleHeight,
		DirectiveConstants.COLORS.SCROLLBAR.BORDER.a,
		DirectiveConstants.COLORS.SCROLLBAR.BORDER.r,
		DirectiveConstants.COLORS.SCROLLBAR.BORDER.g,
		DirectiveConstants.COLORS.SCROLLBAR.BORDER.b
	)

	return handleY, handleHeight
end

--- Draw a button
---@param terminal table Terminal rendering object
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param text string Button text
---@param isSelected boolean Whether button is selected
---@param isDisabled boolean Whether button is disabled
function DirectiveUIHelper.drawButton(terminal, x, y, width, height, text, isSelected, isDisabled)
	local bgColor

	if isDisabled then
		bgColor = DirectiveConstants.COLORS.BUTTON.DISABLED
	elseif isSelected then
		bgColor = DirectiveConstants.COLORS.BUTTON.SELECTED
	else
		bgColor = DirectiveConstants.COLORS.BUTTON.NORMAL
	end

	terminal:drawRect(x, y, width, height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

	terminal:drawRectBorder(
		x,
		y,
		width,
		height,
		DirectiveConstants.COLORS.BUTTON.BORDER.a,
		DirectiveConstants.COLORS.BUTTON.BORDER.r,
		DirectiveConstants.COLORS.BUTTON.BORDER.g,
		DirectiveConstants.COLORS.BUTTON.BORDER.b
	)

	local font = DirectiveConstants.LAYOUT.FONT.CODE
	local textWidth = getTextManager():MeasureStringX(font, text)
	local textHeight = getTextManager():MeasureStringY(font, text)

	local textX = x + (width - textWidth) / 2
	local textY = y + (height - textHeight) / 2

	local textColor = DirectiveConstants.COLORS.TEXT.NORMAL
	if isDisabled then
		textColor = DirectiveConstants.COLORS.TEXT.DIM
	end

	terminal:drawText(text, textX, textY, textColor.r, textColor.g, textColor.b, textColor.a, font)
end

--- Draw a progress bar
---@param terminal table Terminal rendering object
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param progress number Progress value (0-1)
---@param showText boolean Whether to show percentage text
function DirectiveUIHelper.drawProgressBar(terminal, x, y, width, height, progress, showText)
	progress = math.max(0, math.min(1, progress))

	-- Draw background
	terminal:drawRect(
		x,
		y,
		width,
		height,
		DirectiveConstants.COLORS.PROGRESS.BACKGROUND.a,
		DirectiveConstants.COLORS.PROGRESS.BACKGROUND.r,
		DirectiveConstants.COLORS.PROGRESS.BACKGROUND.g,
		DirectiveConstants.COLORS.PROGRESS.BACKGROUND.b
	)

	-- Get appropriate color based on progress
	local fillColor = DirectiveConstants.getProgressBarColor(progress)

	-- Draw fill
	terminal:drawRect(x, y, width * progress, height, fillColor.a, fillColor.r, fillColor.g, fillColor.b)

	-- Draw border
	terminal:drawRectBorder(
		x,
		y,
		width,
		height,
		DirectiveConstants.COLORS.PROGRESS.BORDER.a,
		DirectiveConstants.COLORS.PROGRESS.BORDER.r,
		DirectiveConstants.COLORS.PROGRESS.BORDER.g,
		DirectiveConstants.COLORS.PROGRESS.BORDER.b
	)

	-- Draw text if requested
	if showText then
		local progressText = string.format("%d%%", math.floor(progress * 100))
		local font = DirectiveConstants.LAYOUT.FONT.SMALL
		local textWidth = getTextManager():MeasureStringX(font, progressText)
		local textHeight = getTextManager():MeasureStringY(font, progressText)

		local textX = x + (width - textWidth) / 2
		local textY = y + (height - textHeight) / 2

		terminal:drawText(
			progressText,
			textX,
			textY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			font
		)
	end
end

--- Draw a tab bar
---@param terminal table Terminal rendering object
---@param x number X position
---@param y number Y position
---@param width number Width
---@param height number Height
---@param tabs table Array of tab definitions
---@param selectedTabIndex number Index of selected tab
---@param calculateOnly boolean Whether to only calculate positions without drawing
---@return number totalHeight Total height of tab bar
---@return table tabPositions Table of tab position data
function DirectiveUIHelper.drawTabBar(terminal, x, y, width, height, tabs, selectedTabIndex, calculateOnly)
	if not calculateOnly then
		terminal:drawRect(
			x,
			y,
			width,
			height,
			DirectiveConstants.COLORS.TAB.BAR_BACKGROUND.a,
			DirectiveConstants.COLORS.TAB.BAR_BACKGROUND.r,
			DirectiveConstants.COLORS.TAB.BAR_BACKGROUND.g,
			DirectiveConstants.COLORS.TAB.BAR_BACKGROUND.b
		)

		terminal:drawRect(
			x,
			y + height - 1,
			width,
			1,
			DirectiveConstants.COLORS.TAB.BORDER.a,
			DirectiveConstants.COLORS.TAB.BORDER.r,
			DirectiveConstants.COLORS.TAB.BORDER.g,
			DirectiveConstants.COLORS.TAB.BORDER.b
		)
	end

	if not tabs or #tabs == 0 then
		return height, {}
	end

	local tabFont = DirectiveConstants.LAYOUT.FONT.CODE
	local tabPadding = DirectiveConstants.LAYOUT.TAB.DEFAULT_PADDING
	local tabRowHeight = DirectiveConstants.LAYOUT.TAB.HEIGHT

	local totalTabsWidth = 0
	local tabWidths = {}

	for i, tab in ipairs(tabs) do
		local textWidth = getTextManager():MeasureStringX(tabFont, tab.text)
		local tabWidth = textWidth + (tabPadding * 2)
		totalTabsWidth = totalTabsWidth + tabWidth
		tabWidths[i] = tabWidth
	end

	local maxTabWidth = 0
	for _, w in ipairs(tabWidths) do
		maxTabWidth = math.max(maxTabWidth, w)
	end

	local tabsPerRow
	local numRows
	local tabPositions = {}

	if totalTabsWidth <= width then
		tabsPerRow = #tabs
		numRows = 1
		local tabWidth = width / #tabs

		for i = 1, #tabs do
			tabPositions[i] = {
				row = 0,
				col = i - 1,
				width = tabWidth,
				x = x + (i - 1) * tabWidth,
				y = y,
			}
		end
	else
		tabsPerRow = math.floor(width / maxTabWidth)
		if tabsPerRow == 0 then
			tabsPerRow = 1
		end

		numRows = math.ceil(#tabs / tabsPerRow)
		local tabWidth = width / math.min(tabsPerRow, #tabs)

		for i = 1, #tabs do
			local row = math.floor((i - 1) / tabsPerRow)
			local col = (i - 1) % tabsPerRow

			tabPositions[i] = {
				row = row,
				col = col,
				width = tabWidth,
				x = x + col * tabWidth,
				y = y + row * tabRowHeight,
			}
		end
	end

	if calculateOnly then
		return numRows * tabRowHeight, tabPositions
	end

	for i, tab in ipairs(tabs) do
		local pos = tabPositions[i]
		local isSelected = (i == selectedTabIndex)

		local bgColor = isSelected and DirectiveConstants.COLORS.TAB.SELECTED or DirectiveConstants.COLORS.TAB.NORMAL

		terminal:drawRect(pos.x, pos.y, pos.width, tabRowHeight, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

		terminal:drawRectBorder(
			pos.x,
			pos.y,
			pos.width,
			tabRowHeight,
			DirectiveConstants.COLORS.TAB.BORDER.a,
			DirectiveConstants.COLORS.TAB.BORDER.r,
			DirectiveConstants.COLORS.TAB.BORDER.g,
			DirectiveConstants.COLORS.TAB.BORDER.b
		)

		if isSelected then
			terminal:drawRect(
				pos.x + 1,
				pos.y + tabRowHeight - 1,
				pos.width - 2,
				1,
				bgColor.a,
				bgColor.r,
				bgColor.g,
				bgColor.b
			)
		end

		local textWidth = getTextManager():MeasureStringX(tabFont, tab.text)
		local textHeight = getTextManager():MeasureStringY(tabFont, tab.text)
		local textX = pos.x + (pos.width - textWidth) / 2
		local textY = pos.y + (tabRowHeight - textHeight) / 2

		terminal:drawText(
			tab.text,
			textX,
			textY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			tabFont
		)
	end

	return numRows * tabRowHeight, tabPositions
end

--- Draw a form field
---@param terminal table Terminal rendering object
---@param x number X position
---@param y number Y position
---@param labelWidth number Width of label area
---@param fieldWidth number Width of field area
---@param field table Field definition
---@param isSelected boolean Whether field is selected
function DirectiveUIHelper.drawFormField(terminal, x, y, labelWidth, fieldWidth, field, isSelected)
	local labelFont = DirectiveConstants.LAYOUT.FONT.CODE
	local fieldHeight = DirectiveConstants.LAYOUT.FORM.FIELD_HEIGHT

	terminal:drawText(
		field.label,
		x,
		y + (fieldHeight - getTextManager():MeasureStringY(labelFont, field.label)) / 2,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		labelFont
	)

	local valueX = x + labelWidth + DirectiveConstants.LAYOUT.CONTENT.PADDING_X
	local bgColor = isSelected and DirectiveConstants.COLORS.FIELD.SELECTED
		or DirectiveConstants.COLORS.FIELD.BACKGROUND

	terminal:drawRect(valueX, y, fieldWidth, fieldHeight, bgColor.a, bgColor.r, bgColor.g, bgColor.b)

	terminal:drawRectBorder(
		valueX,
		y,
		fieldWidth,
		fieldHeight,
		DirectiveConstants.COLORS.FIELD.BORDER.a,
		DirectiveConstants.COLORS.FIELD.BORDER.r,
		DirectiveConstants.COLORS.FIELD.BORDER.g,
		DirectiveConstants.COLORS.FIELD.BORDER.b
	)

	local valueText = ""

	if field.type == "text" or field.type == "number" then
		valueText = tostring(field.value or "")
	elseif field.type == "boolean" then
		valueText = field.value and "Yes" or "No"
	elseif field.type == "date" then
		if type(field.value) == "table" then
			valueText =
				string.format("%02d/%02d/%d", field.value.month or 1, field.value.day or 1, field.value.year or 1993)
		else
			valueText = tostring(field.value or "")
		end
	elseif field.type == "list" then
		valueText = tostring(field.value or "")
	elseif field.type == "button" then
		valueText = field.value or field.label
	end

	terminal:drawText(
		valueText,
		valueX + DirectiveConstants.LAYOUT.CONTENT.PADDING_X,
		y + (fieldHeight - getTextManager():MeasureStringY(labelFont, valueText)) / 2,
		DirectiveConstants.COLORS.TEXT.NORMAL.r,
		DirectiveConstants.COLORS.TEXT.NORMAL.g,
		DirectiveConstants.COLORS.TEXT.NORMAL.b,
		DirectiveConstants.COLORS.TEXT.NORMAL.a,
		labelFont
	)
end

--- Calculate the scroll position needed to make an item visible
---@param currentOffset number Current scroll offset
---@param itemPosition number Item Y position
---@param itemHeight number Item height
---@param visibleHeight number Visible area height
---@return number newOffset New scroll offset
function DirectiveUIHelper.calculateScrollToItem(currentOffset, itemPosition, itemHeight, visibleHeight)
	if itemPosition < currentOffset then
		-- Item is above visible area, scroll up to it
		return itemPosition
	elseif itemPosition + itemHeight > currentOffset + visibleHeight then
		-- Item is below visible area, scroll down to it
		return itemPosition - visibleHeight + itemHeight
	else
		-- Item is already visible, don't change scroll
		return currentOffset
	end
end

--- Find a tab index by its ID
---@param tabs table Array of tab definitions
---@param tabId string Tab ID to find
---@return number|nil index Found index or nil
function DirectiveUIHelper.getTabIndexById(tabs, tabId)
	for i, tab in ipairs(tabs) do
		if tab.id == tabId then
			return i
		end
	end
	return nil
end

--- Format a date table into a string
---@param date table Date table {day, month, year, hour, min}
---@return string formatted Formatted date string
function DirectiveUIHelper.formatDateTable(date)
	if not date then
		return "Unknown Date"
	end

	-- Default format: MM/DD/YYYY HH:MM
	return string.format(
		"%02d/%02d/%d %02d:%02d",
		date.month or 1,
		date.day or 1,
		date.year or 1993,
		date.hour or 0,
		date.min or 0
	)
end

--- Create a formatted date string
---@param useShortFormat boolean Whether to use short format
---@return string date The formatted date string
function DirectiveUIHelper.getCurrentFormattedDate(useShortFormat)
	local gameTime = getGameTime()
	if not gameTime then
		return "Unknown Date"
	end

	local year = gameTime:getYear()
	local month = gameTime:getMonth() + 1
	local day = gameTime:getDay() + 1
	local hour = gameTime:getHour()
	local minute = gameTime:getMinutes()

	if useShortFormat then
		return string.format("%02d/%02d/%d", month, day, year)
	else
		return string.format("%02d/%02d/%d %02d:%02d", month, day, year, hour, minute)
	end
end

--- Draw text centered on x coordinate
---@param terminal table Terminal rendering object
---@param text string Text to draw
---@param x number Center X position
---@param y number Y position
---@param font UIFont Font to use
---@param color table Color table (r,g,b,a)
function DirectiveUIHelper.drawTextCentered(terminal, text, x, y, font, color)
	local textWidth = getTextManager():MeasureStringX(font, text)
	local textX = x - textWidth / 2

	terminal:drawText(text, textX, y, color.r, color.g, color.b, color.a, font)
end

return DirectiveUIHelper
