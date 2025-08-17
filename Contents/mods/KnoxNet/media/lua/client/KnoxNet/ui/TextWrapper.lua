---@class TextWrapper
local TextWrapper = {}

--- Wraps text to fit within a specified width
---@param text string The text to wrap
---@param maxWidth number The maximum width for text
---@param font UIFont The font to use for measuring
---@return table lines Wrapped lines of text
function TextWrapper.wrap(text, maxWidth, font)
	if not text or text == "" then
		return {}
	end

	local lines = {}
	local words = {}

	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end

	local currentLine = ""
	local currentLineWidth = 0

	for i = 1, #words do
		local word = words[i]
		local wordWidth = getTextManager():MeasureStringX(font, word)
		local spaceWidth = getTextManager():MeasureStringX(font, " ")

		local potentialLineWidth = currentLineWidth
		if currentLine ~= "" then
			potentialLineWidth = potentialLineWidth + spaceWidth + wordWidth
		else
			potentialLineWidth = wordWidth
		end

		if potentialLineWidth <= maxWidth then
			if currentLine ~= "" then
				currentLine = currentLine .. " " .. word
				currentLineWidth = potentialLineWidth
			else
				currentLine = word
				currentLineWidth = wordWidth
			end
		else
			table.insert(lines, currentLine)
			currentLine = word
			currentLineWidth = wordWidth
		end
	end

	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	return lines
end

--- Truncate text to fit within a specified width
---@param text string The text to truncate
---@param maxWidth number The maximum width for text
---@param font UIFont The font to use for measuring
---@param ellipsis string Optional ellipsis character (default "...")
---@return string text Truncated text
function TextWrapper.truncate(text, maxWidth, font, ellipsis)
	ellipsis = ellipsis or "..."

	if not text or text == "" then
		return ""
	end

	local fullTextWidth = getTextManager():MeasureStringX(font, text)
	if fullTextWidth <= maxWidth then
		return text
	end

	local left, right = 1, #text
	local truncated = ""

	-- binary search for the longest substring that fits
	while left <= right do
		local mid = math.floor((left + right) / 2)
		local candidate = text:sub(1, mid) .. ellipsis
		local width = getTextManager():MeasureStringX(font, candidate)

		if width <= maxWidth then
			truncated = candidate
			left = mid + 1
		else
			right = mid - 1
		end
	end

	if truncated == "" then
		return ellipsis
	end

	return truncated
end

--- Format a multi-paragraph text for display
---@param text string The text to format
---@param maxWidth number The maximum width for each line
---@param font UIFont The font to use for measuring
---@return table lines Array of formatted lines
function TextWrapper.formatParagraphs(text, maxWidth, font)
	if not text or text == "" then
		return {}
	end

	local paragraphs = {}
	local allLines = {}

	for paragraph in text:gmatch("([^\n\n]+)") do
		table.insert(paragraphs, paragraph:gsub("^%s*(.-)%s*$", "%1"))
	end

	for i = 1, #paragraphs do
		local paragraph = paragraphs[i]
		local wrappedLines = TextWrapper.wrap(paragraph, maxWidth, font)

		for j = 1, #wrappedLines do
			table.insert(allLines, wrappedLines[j])
		end

		table.insert(allLines, "")
	end

	if #allLines > 0 and allLines[#allLines] == "" then
		table.remove(allLines)
	end

	return allLines
end

return TextWrapper
