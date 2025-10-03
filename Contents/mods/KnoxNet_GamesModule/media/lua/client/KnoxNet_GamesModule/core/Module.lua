local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")
local GameMainMenu = require("KnoxNet_GamesModule/core/GameMainMenu")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local GamesModule = {}

GamesModule.GAMES = table.newarray() --[[@as table]]
GamesModule.registeredGames = {}

function GamesModule:init(terminal)
	self.terminal = terminal
	self.currentGameIndex = 0
	self.inGame = false
	self.inGameMenu = false
	self.selectedTile = 1
	self.tiles = table.newarray() --[[@as table]]
	self.backButton = nil
	self.updateTileLayout = true
	self.scrollOffset = 0
	self.maxScrollOffset = 0
	self.baseTileHeight = 0
	self.currentGame = nil
	self.currentGameMenu = nil
	self.lastClickTime = nil
	self.lastClickTile = nil
end

function GamesModule:validateSelection()
	if self.selectedTile < 1 then
		self.selectedTile = 1
	elseif self.selectedTile > #GamesModule.GAMES + 1 then
		self.selectedTile = #GamesModule.GAMES + 1
	end

	-- Ensure scroll offset stays within bounds
	if self.scrollOffset < 0 then
		self.scrollOffset = 0
	elseif self.scrollOffset > self.maxScrollOffset then
		self.scrollOffset = self.maxScrollOffset
	end
end

function GamesModule:onActivate()
	self:init(self.terminal)
	self.terminal:setTitle("GAMES ARCADE")
	self:calculateTileLayout()

	if #GamesModule.GAMES > 0 then
		self.selectedTile = 1
	else
		self.selectedTile = #GamesModule.GAMES + 1
	end

	self:validateSelection()
	self.scrollOffset = 0
	self.inGame = false
	self.inGameMenu = false
	self.currentGame = nil
	self.currentGameMenu = nil
	self.terminal:playRandomKeySound()
end

function GamesModule:onDeactivate()
	self.inGame = false
	self.inGameMenu = false
	if self.currentGame and self.currentGame.onDeactivate then
		self.currentGame:onDeactivate()
	end
	self.currentGame = nil
	self.currentGameMenu = nil
end

function GamesModule:onClose()
	self:onDeactivate()
end

function GamesModule:calculateTileLayout()
	self.tiles = table.newarray() --[[@as table]]

	local displayWidth = self.terminal.displayWidth
	local contentHeight = self.terminal.contentAreaHeight

	-- Get responsive padding based on terminal size
	local padding = Constants.UI_CONST.getResponsivePadding(self.terminal.width, self.terminal.height)

	local tilePadding = Constants.UI_CONST.TILE_PADDING
	local tileSpacing = padding.tileSpacing -- Use responsive spacing
	local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW

	-- Calculate available width with proper padding
	local availableWidth = displayWidth
		- Constants.UI_CONST.SCROLLBAR_WIDTH
		- (tilesPerRow + 1) * tileSpacing
		- (padding.contentEdge * 2)
	local tileWidth = math.floor(availableWidth / tilesPerRow)

	local tileHeight = Constants.UI_CONST.TITLE_HEIGHT
		+ Constants.UI_CONST.DESCRIPTION_HEIGHT
		+ Constants.UI_CONST.PREVIEW_HEIGHT
		+ tilePadding * 2
	self.baseTileHeight = tileHeight + tileSpacing

	local rowsTotal = math.ceil(#GamesModule.GAMES / tilesPerRow)
	local visibleRows = Constants.UI_CONST.VISIBLE_ROWS

	-- Fix scroll offset calculation
	self.maxScrollOffset = math.max(0, rowsTotal - visibleRows)

	local backButtonHeight = 30
	local backButtonWidth = 160

	-- Position back button with proper padding
	local backButtonX = self.terminal.displayX + (self.terminal.displayWidth - backButtonWidth) / 2
	local backButtonY = self.terminal.contentAreaY + contentHeight - backButtonHeight - padding.contentEdge

	self.backButton = {
		x = backButtonX,
		y = backButtonY,
		width = backButtonWidth,
		height = backButtonHeight,
		text = "Back to Main Menu",
		action = function()
			self.terminal:changeState("mainMenu")
		end,
	}

	-- Calculate tile positions with proper padding
	local contentX = self.terminal.displayX + padding.contentEdge
	local contentY = self.terminal.contentAreaY + padding.contentEdge

	for i = 1, #GamesModule.GAMES do
		local game = GamesModule.GAMES[i]
		local row = math.floor((i - 1) / tilesPerRow)
		local col = (i - 1) % tilesPerRow

		local x = contentX + tileSpacing + col * (tileWidth + tileSpacing)
		local baseY = contentY + tileSpacing

		table.insert(self.tiles, {
			x = x,
			baseY = baseY,
			row = row,
			col = col,
			width = tileWidth,
			height = tileHeight,
			game = game,
			index = i,
		})
	end

	self.updateTileLayout = false
end

function GamesModule:onMouseUp(x, y)
	if self.inGameMenu and self.currentGameMenu then
		return self.currentGameMenu:onMouseUp(x, y)
	elseif not self.inGame then
		local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW
		local firstVisibleRow = self.scrollOffset
		local lastVisibleRow = firstVisibleRow + Constants.UI_CONST.VISIBLE_ROWS - 1

		for i = 1, #self.tiles do
			local tile = self.tiles[i]
			if tile.row >= firstVisibleRow and tile.row <= lastVisibleRow then
				local yOffset = (tile.row - firstVisibleRow) * self.baseTileHeight
				local visibleY = tile.baseY + yOffset

				if x >= tile.x and x <= tile.x + tile.width and y >= visibleY and y <= visibleY + tile.height then
					if
						self.lastClickTime
						and getTimeInMillis() - self.lastClickTime < 500
						and self.lastClickTile == i
					then
						self:activateGame(i)
						self.lastClickTime = nil
						self.lastClickTile = nil
						return true
					else
						self.selectedTile = i
						self:validateSelection()
						self.lastClickTime = getTimeInMillis()
						self.lastClickTile = i
						if self.terminal.playRandomKeySound then
							self.terminal:playRandomKeySound()
						end
						return true
					end
				end
			end
		end

		if
			x >= self.backButton.x
			and x <= self.backButton.x + self.backButton.width
			and y >= self.backButton.y
			and y <= self.backButton.y + self.backButton.height
		then
			self.terminal:changeState("mainMenu")
			if self.terminal.playRandomKeySound then
				self.terminal:playRandomKeySound()
			end
			return true
		end
	end
	return false
end

function GamesModule:activateGame(gameIndex)
	if gameIndex > 0 and gameIndex <= #GamesModule.GAMES then
		local gameId = GamesModule.GAMES[gameIndex].id
		local gameInstance = GamesModule.registeredGames[gameId]

		if gameInstance then
			self.currentGameIndex = gameIndex
			self.currentGame = gameInstance
			self.inGameMenu = true

			if gameInstance.getMainMenu then
				self.currentGameMenu = gameInstance:getMainMenu()
			else
				self.currentGameMenu = GameMainMenu:new(gameInstance, GamesModule.GAMES[gameIndex])
			end
			self.currentGameMenu:activate(self)

			return true
		end
	end
	return false
end

function GamesModule:startGame(gameInstance)
	if gameInstance then
		self.inGame = true
		self.inGameMenu = false

		if gameInstance.activate then
			gameInstance:activate(self)
		end
		return true
	end
	return false
end

function GamesModule:update()
	if self.updateTileLayout then
		self:calculateTileLayout()
	end

	if self.inGameMenu and self.currentGameMenu then
		if self.currentGameMenu.update then
			self.currentGameMenu:update()
		end
		return
	elseif self.inGame and self.currentGame then
		if self.currentGame.update then
			self.currentGame:update(self)
		end
	end
end

function GamesModule:onKeyPress(key)
	if self.inGameMenu and self.currentGameMenu then
		return self.currentGameMenu:onKeyPress(key)
	elseif not self.inGame then
		local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW
		local visibleRows = Constants.UI_CONST.VISIBLE_ROWS

		if key == Keyboard.KEY_UP then
			if self.selectedTile > #GamesModule.GAMES then
				-- If on back button, go to the last tile in the last visible row
				local lastVisibleRow = self.scrollOffset + visibleRows - 1
				local lastTileInRow = math.min(#GamesModule.GAMES, lastVisibleRow * tilesPerRow + tilesPerRow)
				self.selectedTile = lastTileInRow

				-- Ensure the row is visible
				if lastVisibleRow > self.scrollOffset + visibleRows - 1 then
					self.scrollOffset = lastVisibleRow - visibleRows + 1
				end
			else
				local currentRow = math.floor((self.selectedTile - 1) / tilesPerRow)
				local currentCol = (self.selectedTile - 1) % tilesPerRow
				local targetRow = currentRow - 1

				if targetRow >= 0 then
					local targetTile = targetRow * tilesPerRow + currentCol + 1

					if targetTile <= #GamesModule.GAMES then
						self.selectedTile = targetTile
						local selectedRow = math.floor((self.selectedTile - 1) / tilesPerRow)
						if selectedRow < self.scrollOffset then
							self.scrollOffset = selectedRow
						end
					else
						local prevRowStart = targetRow * tilesPerRow + 1
						local prevRowEnd = ((prevRowStart + tilesPerRow - 1) < #GamesModule.GAMES)
								and (prevRowStart + tilesPerRow - 1)
							or #GamesModule.GAMES

						if prevRowStart <= #GamesModule.GAMES then
							local closestTile = prevRowStart
							local minDistance = math.abs(currentCol - 0)

							for i = prevRowStart + 1, prevRowEnd do
								local col = (i - 1) % tilesPerRow
								local distance = math.abs(currentCol - col)
								if distance < minDistance then
									minDistance = distance
									closestTile = i
								end
							end

							self.selectedTile = closestTile
							local selectedRow = math.floor((self.selectedTile - 1) / tilesPerRow)
							if selectedRow < self.scrollOffset then
								self.scrollOffset = selectedRow
							end
						end
					end
				end
			end

			self:validateSelection()
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_DOWN then
			if self.selectedTile > #GamesModule.GAMES then
				return true
			else
				local currentRow = math.floor((self.selectedTile - 1) / tilesPerRow)
				local currentCol = (self.selectedTile - 1) % tilesPerRow
				local targetRow = currentRow + 1
				local targetTile = targetRow * tilesPerRow + currentCol + 1

				if targetTile <= #GamesModule.GAMES then
					self.selectedTile = targetTile
					local selectedRow = math.floor((self.selectedTile - 1) / tilesPerRow)
					local bottomRow = self.scrollOffset + visibleRows - 1

					if selectedRow > bottomRow then
						self.scrollOffset = selectedRow - visibleRows + 1
					end
				else
					-- If we can't go down to another tile, go to the back button
					self.selectedTile = #GamesModule.GAMES + 1
				end
			end

			self:validateSelection()
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_LEFT then
			if self.selectedTile > #GamesModule.GAMES then
				-- If on back button, go to the last tile in the current visible row
				local currentRow = self.scrollOffset + visibleRows - 1
				local lastTileInRow = math.min(#GamesModule.GAMES, currentRow * tilesPerRow + tilesPerRow)
				self.selectedTile = lastTileInRow
			elseif self.selectedTile % tilesPerRow ~= 1 then
				self.selectedTile = self.selectedTile - 1
			end

			self:validateSelection()
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_RIGHT then
			if self.selectedTile > #GamesModule.GAMES then
				return true
			elseif self.selectedTile % tilesPerRow ~= 0 and self.selectedTile < #GamesModule.GAMES then
				self.selectedTile = self.selectedTile + 1
			end

			self:validateSelection()
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_SPACE then
			if self.selectedTile <= #GamesModule.GAMES then
				self:activateGame(self.selectedTile)
			else
				self.terminal:changeState("mainMenu")
			end
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_BACK then
			self.terminal:changeState("mainMenu")
			self.terminal:playRandomKeySound()
			return true
		end
	else
		if self.currentGame and self.currentGame.onKeyPress then
			return self.currentGame:onKeyPress(key, self)
		end

		if key == Keyboard.KEY_BACK then
			self:onActivate()
			return true
		end
	end

	return false
end

function GamesModule:onKeyStartPressed(key)
	if self.inGameMenu and self.currentGameMenu then
		return false
	elseif not self.inGame then
		return false
	end

	if self.currentGame and self.currentGame.onKeyStartPressed then
		return self.currentGame:onKeyStartPressed(key, self)
	end

	return false
end

function GamesModule:onKeyKeepPressed(key)
	if self.inGameMenu and self.currentGameMenu then
		return false
	elseif not self.inGame then
		return false
	end

	if self.currentGame and self.currentGame.onKeyKeepPressed then
		return self.currentGame:onKeyKeepPressed(key, self)
	end

	return false
end

function GamesModule:render()
	if self.inGameMenu and self.currentGameMenu then
		self.currentGameMenu:render()
	elseif not self.inGame then
		self:renderGameSelection()
	else
		if self.currentGame and self.currentGame.render then
			self.currentGame:render(self)
		end
	end
end

function GamesModule:onMouseWheel(del)
	if self.inGameMenu and self.currentGameMenu then
		return self.currentGameMenu:onMouseWheel(del)
	elseif not self.inGame then
		local scrollAmount = del < 0 and 3 or -3 -- 3x sensitivity
		local newOffset = self.scrollOffset + scrollAmount
		self.scrollOffset = (newOffset < 0) and 0
			or ((newOffset > self.maxScrollOffset) and self.maxScrollOffset or newOffset)
		self:update()
		return true
	elseif self.currentGame and self.currentGame.onMouseWheel then
		return self.currentGame:onMouseWheel(del, self)
	end
	return false
end

function GamesModule:renderGameSelection()
	self.terminal:renderTitle("GAMES ARCADE")

	-- Get responsive padding based on terminal size
	local padding = Constants.UI_CONST.getResponsivePadding(self.terminal.width, self.terminal.height)

	-- Calculate content area with proper padding
	local contentX = self.terminal.displayX + padding.contentEdge
	local contentY = self.terminal.contentAreaY + padding.contentEdge
	local contentWidth = self.terminal.displayWidth - (padding.contentEdge * 2)
	local contentHeight = self.terminal.contentAreaHeight - (padding.contentEdge * 2)

	local termColors = Constants.UI_CONST.COLORS

	-- Render background for content area only (not overlapping title/footer)
	self.terminal:drawRect(
		contentX,
		contentY,
		contentWidth,
		contentHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)

	self.terminal:clearStencilRect()
	self.terminal:setStencilRect(
		contentX,
		contentY,
		contentWidth,
		contentHeight - self.backButton.height - padding.contentEdge
	)

	local firstVisibleRow = self.scrollOffset
	local lastVisibleRow = firstVisibleRow + Constants.UI_CONST.VISIBLE_ROWS - 1

	for i = 1, #self.tiles do
		local tile = self.tiles[i]
		if tile.row >= firstVisibleRow and tile.row <= lastVisibleRow then
			local isSelected = (i == self.selectedTile)
			local rowsFromTop = tile.row - firstVisibleRow
			local visibleY = tile.baseY + (rowsFromTop * (tile.height + padding.tileSpacing))

			-- SMART CLIPPING: Allow partial visibility for smooth scrolling, but prevent title/footer overlap
			-- Check if tile intersects with content area (allows partial visibility)
			if visibleY + tile.height > contentY and visibleY < contentY + contentHeight then
				local bgColor = isSelected and termColors.BUTTON.HOVER or termColors.BUTTON.COLOR
				local borderColor = isSelected and termColors.BUTTON.BORDER or termColors.BORDER

				self.terminal:drawRect(
					tile.x,
					visibleY,
					tile.width,
					tile.height,
					bgColor.a,
					bgColor.r,
					bgColor.g,
					bgColor.b
				)

				self.terminal:drawRectBorder(
					tile.x,
					visibleY,
					tile.width,
					tile.height,
					borderColor.a,
					borderColor.r,
					borderColor.g,
					borderColor.b
				)

				local titleY = visibleY + Constants.UI_CONST.TILE_PADDING
				local textColor = termColors.TEXT.NORMAL

				local titleText = tile.game.name
				local titleWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.CODE, titleText)
				local titleX = tile.x + (tile.width - titleWidth) / 2

				self.terminal:drawText(
					titleText,
					titleX,
					titleY,
					textColor.r,
					textColor.g,
					textColor.b,
					textColor.a,
					Constants.UI_CONST.FONT.CODE
				)

				local descY = titleY + Constants.UI_CONST.TITLE_HEIGHT
				local descText = tile.game.description
				local descWidth = tile.width - 2 * Constants.UI_CONST.TILE_PADDING
				local descLines = self:wrapText(descText, descWidth, Constants.UI_CONST.FONT.SMALL)

				for j = 1, #descLines do
					local line = descLines[j]
					local lineWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.SMALL, line)
					local lineX = tile.x + (tile.width - lineWidth) / 2
					local lineY = descY + (j - 1) * 15

					self.terminal:drawText(
						line,
						lineX,
						lineY,
						textColor.r * 0.8,
						textColor.g * 0.8,
						textColor.b * 0.8,
						textColor.a * 0.9,
						Constants.UI_CONST.FONT.SMALL
					)
				end

				local previewY = descY + Constants.UI_CONST.DESCRIPTION_HEIGHT
				local previewX = tile.x + Constants.UI_CONST.TILE_PADDING
				local previewWidth = tile.width - 2 * Constants.UI_CONST.TILE_PADDING

				local gameInstance = GamesModule.registeredGames[tile.game.id]
				if gameInstance and gameInstance.preview then
					gameInstance:preview(
						previewX,
						previewY,
						previewWidth,
						Constants.UI_CONST.PREVIEW_HEIGHT,
						self.terminal,
						self
					)
				end
			end
		end
	end

	-- Render scrollbar if needed
	if self.maxScrollOffset > 0 then
		local scrollbarX = contentX + contentWidth - Constants.UI_CONST.SCROLLBAR_WIDTH - padding.contentEdge
		local scrollbarY = contentY
		local scrollbarHeight = contentHeight - self.backButton.height - padding.contentEdge

		-- Only render scrollbar if it fits within content bounds
		if scrollbarHeight > 0 then
			self.terminal:drawRect(
				scrollbarX,
				scrollbarY,
				Constants.UI_CONST.SCROLLBAR_WIDTH,
				scrollbarHeight,
				termColors.SCROLLBAR.BACKGROUND.a,
				termColors.SCROLLBAR.BACKGROUND.r,
				termColors.SCROLLBAR.BACKGROUND.g,
				termColors.SCROLLBAR.BACKGROUND.b
			)

			local totalRows = math.ceil(#GamesModule.GAMES / Constants.UI_CONST.TILES_PER_ROW)
			local handleHeight = (
				(
					totalRows > 0
					and math.max(
						Constants.UI_CONST.SCROLLBAR_MIN_HANDLE,
						(Constants.UI_CONST.VISIBLE_ROWS / totalRows) * scrollbarHeight
					)
				) or Constants.UI_CONST.SCROLLBAR_MIN_HANDLE
			)

			if totalRows > Constants.UI_CONST.VISIBLE_ROWS then
				local scrollRatio = self.scrollOffset / self.maxScrollOffset
				local handleY = scrollbarY + scrollRatio * (scrollbarHeight - handleHeight)

				self.terminal:drawRect(
					scrollbarX,
					handleY,
					Constants.UI_CONST.SCROLLBAR_WIDTH,
					handleHeight,
					termColors.SCROLLBAR.HANDLE.a,
					termColors.SCROLLBAR.HANDLE.r,
					termColors.SCROLLBAR.HANDLE.g,
					termColors.SCROLLBAR.HANDLE.b
				)
			end
		end
	end

	self.terminal:clearStencilRect()

	local isBackSelected = (self.selectedTile > #GamesModule.GAMES)
	local backBgColor = isBackSelected and termColors.BUTTON.HOVER or termColors.BUTTON.COLOR
	local backBorderColor = isBackSelected and termColors.BUTTON.BORDER or termColors.BORDER

	-- Only render back button if it's within the content area bounds
	if self.backButton.y >= contentY and self.backButton.y + self.backButton.height <= contentY + contentHeight then
		self.terminal:drawRect(
			self.backButton.x,
			self.backButton.y,
			self.backButton.width,
			self.backButton.height,
			backBgColor.a,
			backBgColor.r,
			backBgColor.g,
			backBgColor.b
		)

		self.terminal:drawRectBorder(
			self.backButton.x,
			self.backButton.y,
			self.backButton.width,
			self.backButton.height,
			backBorderColor.a,
			backBorderColor.r,
			backBorderColor.g,
			backBorderColor.b
		)

		local textColor = termColors.TEXT.NORMAL
		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.CODE, self.backButton.text)
		local textHeight = getTextManager():MeasureStringY(Constants.UI_CONST.FONT.CODE, self.backButton.text)
		local textX = self.backButton.x + (self.backButton.width - textWidth) / 2
		local textY = self.backButton.y + (self.backButton.height - textHeight) / 2

		self.terminal:drawText(
			self.backButton.text,
			textX,
			textY,
			textColor.r,
			textColor.g,
			textColor.b,
			textColor.a,
			Constants.UI_CONST.FONT.CODE
		)
	end

	self.terminal:renderFooter("SPACE - SELECT | ARROWS - NAVIGATE | DOUBLE-CLICK - PLAY GAME | BACKSPACE - BACK")
end

function GamesModule:onMouseDown(x, y)
	if self.inGameMenu and self.currentGameMenu then
		return false
	elseif not self.inGame then
		if self.maxScrollOffset > 0 then
			local scrollbarX = self.terminal.displayX
				+ self.terminal.displayWidth
				- Constants.UI_CONST.SCROLLBAR_WIDTH
				- 5
			local scrollbarY = self.terminal.contentAreaY
			local scrollbarHeight = self.terminal.contentAreaHeight - self.backButton.height - 20

			if
				x >= scrollbarX
				and x <= scrollbarX + Constants.UI_CONST.SCROLLBAR_WIDTH
				and y >= scrollbarY
				and y <= scrollbarY + scrollbarHeight
			then
				local totalRows = math.ceil(#GamesModule.GAMES / Constants.UI_CONST.TILES_PER_ROW)
				local clickPosition = (y - scrollbarY) / scrollbarHeight

				local newScrollOffset = math.floor(clickPosition * self.maxScrollOffset + 0.5)

				if self.scrollOffset ~= newScrollOffset then
					local targetOffset = (newScrollOffset < 0) and 0
						or ((newScrollOffset > self.maxScrollOffset) and self.maxScrollOffset or newScrollOffset)
					self.scrollOffset = targetOffset
				end
				return true
			end
		end

		local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW
		local firstVisibleRow = self.scrollOffset
		local lastVisibleRow = firstVisibleRow + Constants.UI_CONST.VISIBLE_ROWS - 1

		for i = 1, #self.tiles do
			local tile = self.tiles[i]
			if tile.row >= firstVisibleRow and tile.row <= lastVisibleRow then
				local yOffset = (tile.row - firstVisibleRow) * self.baseTileHeight
				local visibleY = tile.baseY + yOffset

				if x >= tile.x and x <= tile.x + tile.width and y >= visibleY and y <= visibleY + tile.height then
					self.selectedTile = i
					self:validateSelection()
					return true
				end
			end
		end

		if
			x >= self.backButton.x
			and x <= self.backButton.x + self.backButton.width
			and y >= self.backButton.y
			and y <= self.backButton.y + self.backButton.height
		then
			self.selectedTile = #GamesModule.GAMES + 1
			self:validateSelection()
			return true
		end
	elseif self.currentGame and self.currentGame.onMouseDown then
		return self.currentGame:onMouseDown(x, y, self)
	end

	return false
end

function GamesModule:wrapText(text, maxWidth, font)
	local lines = table.newarray() --[[@as table]]
	local words = table.newarray() --[[@as table]]

	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end

	local currentLine = ""
	local currentWidth = 0

	for i = 1, #words do
		local word = words[i]
		local wordWidth = getTextManager():MeasureStringX(font, word)
		local spaceWidth = getTextManager():MeasureStringX(font, " ")

		if currentWidth + wordWidth <= maxWidth then
			if currentLine ~= "" then
				currentLine = currentLine .. " " .. word
				currentWidth = currentWidth + spaceWidth + wordWidth
			else
				currentLine = word
				currentWidth = wordWidth
			end
		else
			table.insert(lines, currentLine)
			currentLine = word
			currentWidth = wordWidth
		end
	end

	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	return lines
end

function GamesModule.registerGame(gameInfo, gameImpl)
	if not gameInfo or not gameInfo.id or not gameInfo.name or not gameInfo.description then
		return false
	end

	local gameEntry = {
		id = gameInfo.id,
		name = gameInfo.name,
		description = gameInfo.description,
	}

	GamesModule.registeredGames[gameInfo.id] = gameImpl

	table.insert(GamesModule.GAMES, gameEntry)

	return true
end

KnoxNet_Terminal.registerModule("Games", GamesModule)

return GamesModule
