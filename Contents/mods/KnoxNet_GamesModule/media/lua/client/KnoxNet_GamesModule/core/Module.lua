local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local GamesModule = {}

GamesModule.GAMES = table.newarray() --[[@as table]]
GamesModule.registeredGames = {}

function GamesModule:init(terminal)
	self.terminal = terminal
	self.currentGameIndex = 0
	self.inGame = false
	self.selectedTile = 1
	self.tiles = table.newarray() --[[@as table]]
	self.backButton = nil
	self.updateTileLayout = true
	self.scrollOffset = 0
	self.maxScrollOffset = 0
	self.baseTileHeight = 0
	self.currentGame = nil
	self.lastClickTime = nil
	self.lastClickTile = nil
end

function GamesModule:validateSelection()
	if self.selectedTile < 1 then
		self.selectedTile = 1
	elseif self.selectedTile > #GamesModule.GAMES + 1 then
		self.selectedTile = #GamesModule.GAMES + 1
	end
	if #GamesModule.GAMES == 0 then
		self.selectedTile = 1
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
	self.currentGame = nil
	self.terminal:playRandomKeySound()
end

function GamesModule:onDeactivate()
	self.inGame = false
	if self.currentGame and self.currentGame.onDeactivate then
		self.currentGame:onDeactivate()
	end
	self.currentGame = nil
end

function GamesModule:onClose()
	self:onDeactivate()
end

function GamesModule:calculateTileLayout()
	self.tiles = table.newarray() --[[@as table]]

	local displayWidth = self.terminal.displayWidth
	local contentHeight = self.terminal.contentAreaHeight

	local tilePadding = Constants.UI_CONST.TILE_PADDING
	local tileSpacing = Constants.UI_CONST.TILE_SPACING
	local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW

	local availableWidth = displayWidth - Constants.UI_CONST.SCROLLBAR_WIDTH - (tilesPerRow + 1) * tileSpacing
	local tileWidth = math.floor(availableWidth / tilesPerRow)

	local tileHeight = Constants.UI_CONST.TITLE_HEIGHT
		+ Constants.UI_CONST.DESCRIPTION_HEIGHT
		+ Constants.UI_CONST.PREVIEW_HEIGHT
		+ tilePadding * 2
	self.baseTileHeight = tileHeight + tileSpacing

	local rowsTotal = math.ceil(#GamesModule.GAMES / tilesPerRow)
	local visibleRows = Constants.UI_CONST.VISIBLE_ROWS

	self.maxScrollOffset = math.max(0, rowsTotal - visibleRows)

	local backButtonHeight = 30
	local backButtonWidth = 160

	local backButtonX = self.terminal.displayX + (self.terminal.displayWidth - backButtonWidth) / 2
	local backButtonY = self.terminal.contentAreaY + contentHeight - backButtonHeight - tileSpacing

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

	for i = 1, #GamesModule.GAMES do
		local game = GamesModule.GAMES[i]
		local row = math.floor((i - 1) / tilesPerRow)
		local col = (i - 1) % tilesPerRow

		local x = self.terminal.displayX + tileSpacing + col * (tileWidth + tileSpacing)
		local baseY = self.terminal.contentAreaY + tileSpacing

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
	if not self.inGame then
		local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW
		local firstVisibleRow = self.scrollOffset
		local lastVisibleRow = firstVisibleRow + Constants.UI_CONST.VISIBLE_ROWS - 1

		for i = 1, #self.tiles do
			local tile = self.tiles[i]
			if tile.row >= firstVisibleRow and tile.row <= lastVisibleRow then
				local yOffset = (tile.row - firstVisibleRow) * self.baseTileHeight
				local visibleY = tile.baseY + yOffset

				if x >= tile.x and x <= tile.x + tile.width and y >= visibleY and y <= visibleY + tile.height then
					if self.lastClickTime and getTimeInMillis() - self.lastClickTime < 500 and self.lastClickTile == i then
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
			self.inGame = true

			if self.currentGame.activate then
				self.currentGame:activate(self)
			end
			return true
		end
	end
	return false
end

function GamesModule:update()
	if self.updateTileLayout then
		self:calculateTileLayout()
	end

	if not self.inGame then
		return
	end

	if self.currentGame and self.currentGame.update then
		self.currentGame:update(self)
	end
end

function GamesModule:onKeyPress(key)
	if not self.inGame then
		local tilesPerRow = Constants.UI_CONST.TILES_PER_ROW
		local visibleRows = Constants.UI_CONST.VISIBLE_ROWS

		if key == Keyboard.KEY_UP then
			if self.selectedTile > #GamesModule.GAMES then
				local currentRow = self.scrollOffset
				local gamesInCurrentRow = math.min(tilesPerRow, #GamesModule.GAMES - currentRow * tilesPerRow)
				if gamesInCurrentRow > 0 then
					self.selectedTile = currentRow * tilesPerRow + gamesInCurrentRow
				else
					self.selectedTile = #GamesModule.GAMES
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
						local prevRowEnd = math.min(prevRowStart + tilesPerRow - 1, #GamesModule.GAMES)
						
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
					local nextRowStart = targetRow * tilesPerRow + 1
					local nextRowEnd = math.min(nextRowStart + tilesPerRow - 1, #GamesModule.GAMES)
					
					if nextRowStart <= #GamesModule.GAMES then
						local closestTile = nextRowStart
						local minDistance = math.abs(currentCol - 0)
						
						for i = nextRowStart + 1, nextRowEnd do
							local col = (i - 1) % tilesPerRow
							local distance = math.abs(currentCol - col)
							if distance < minDistance then
								minDistance = distance
								closestTile = i
							end
						end
						
						self.selectedTile = closestTile
						local selectedRow = math.floor((self.selectedTile - 1) / tilesPerRow)
						local bottomRow = self.scrollOffset + visibleRows - 1

						if selectedRow > bottomRow then
							self.scrollOffset = selectedRow - visibleRows + 1
						end
					else
						self.selectedTile = #GamesModule.GAMES + 1
					end
				end
			end

			self:validateSelection()
			self.terminal:playRandomKeySound()
			return true
		elseif key == Keyboard.KEY_LEFT then
			if self.selectedTile > #GamesModule.GAMES then
				local currentRow = self.scrollOffset
				local gamesInCurrentRow = math.min(tilesPerRow, #GamesModule.GAMES - currentRow * tilesPerRow)
				if gamesInCurrentRow > 0 then
					self.selectedTile = currentRow * tilesPerRow + gamesInCurrentRow
				else
					self.selectedTile = #GamesModule.GAMES
				end
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

function GamesModule:render()
	if not self.inGame then
		self:renderGameSelection()
	else
		if self.currentGame and self.currentGame.render then
			self.currentGame:render(self)
		end
	end
end

function GamesModule:onMouseWheel(del)
	if not self.inGame then
		local scrollAmount = del < 0 and 1 or -1
		local newOffset = self.scrollOffset + scrollAmount
		self.scrollOffset = math.max(0, math.min(self.maxScrollOffset, newOffset))
		self:update()
		return true
	elseif self.currentGame and self.currentGame.onMouseWheel then
		return self.currentGame:onMouseWheel(del, self)
	end
	return false
end

function GamesModule:renderGameSelection()
	self.terminal:renderTitle("GAMES ARCADE")
	local termColors = Constants.UI_CONST.COLORS
	self.terminal:drawRect(
		self.terminal.displayX,
		self.terminal.contentAreaY,
		self.terminal.displayWidth,
		self.terminal.contentAreaHeight,
		termColors.BACKGROUND.a,
		termColors.BACKGROUND.r,
		termColors.BACKGROUND.g,
		termColors.BACKGROUND.b
	)
	self.terminal:clearStencilRect()
	self.terminal:setStencilRect(
		self.terminal.displayX,
		self.terminal.contentAreaY,
		self.terminal.displayWidth,
		self.terminal.contentAreaHeight - self.backButton.height - 20
	)
	local firstVisibleRow = self.scrollOffset
	local lastVisibleRow = firstVisibleRow + Constants.UI_CONST.VISIBLE_ROWS - 1
	for i = 1, #self.tiles do
		local tile = self.tiles[i]
		if tile.row >= firstVisibleRow and tile.row <= lastVisibleRow then
			local isSelected = (i == self.selectedTile)
			local rowsFromTop = tile.row - firstVisibleRow
			local visibleY = tile.baseY + (rowsFromTop * (tile.height + Constants.UI_CONST.TILE_SPACING))
			local bgColor = isSelected and termColors.BUTTON_HOVER or termColors.BUTTON_COLOR
			local borderColor = isSelected and termColors.BUTTON_BORDER or termColors.BORDER
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
			local textColor = termColors.TEXT

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

	if self.maxScrollOffset > 0 then
		local scrollbarX = self.terminal.displayX + self.terminal.displayWidth - Constants.UI_CONST.SCROLLBAR_WIDTH - 5
		local scrollbarY = self.terminal.contentAreaY
		local scrollbarHeight = self.terminal.contentAreaHeight - self.backButton.height - 20

		self.terminal:drawRect(
			scrollbarX,
			scrollbarY,
			Constants.UI_CONST.SCROLLBAR_WIDTH,
			scrollbarHeight,
			termColors.SCROLLBAR_BG.a,
			termColors.SCROLLBAR_BG.r,
			termColors.SCROLLBAR_BG.g,
			termColors.SCROLLBAR_BG.b
		)

		local totalRows = math.ceil(#GamesModule.GAMES / Constants.UI_CONST.TILES_PER_ROW)
		local handleHeight = math.max(
			Constants.UI_CONST.SCROLLBAR_MIN_HANDLE,
			(Constants.UI_CONST.VISIBLE_ROWS / totalRows) * scrollbarHeight
		)

		if totalRows > Constants.UI_CONST.VISIBLE_ROWS then
			local scrollRatio = self.scrollOffset / self.maxScrollOffset
			local handleY = scrollbarY + scrollRatio * (scrollbarHeight - handleHeight)

			self.terminal:drawRect(
				scrollbarX,
				handleY,
				Constants.UI_CONST.SCROLLBAR_WIDTH,
				handleHeight,
				termColors.SCROLLBAR.a,
				termColors.SCROLLBAR.r,
				termColors.SCROLLBAR.g,
				termColors.SCROLLBAR.b
			)
		end
	end

	self.terminal:clearStencilRect()

	local isBackSelected = (self.selectedTile > #GamesModule.GAMES)
	local backBgColor = isBackSelected and termColors.BUTTON_HOVER or termColors.BUTTON_COLOR
	local backBorderColor = isBackSelected and termColors.BUTTON_BORDER or termColors.BORDER

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

	local textColor = termColors.TEXT
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

	self.terminal:renderFooter("SPACE - SELECT | ARROWS - NAVIGATE | DOUBLE-CLICK - PLAY GAME | BACKSPACE - BACK")
end

function GamesModule:onMouseDown(x, y)
	if not self.inGame then
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
				self.scrollOffset = math.max(0, math.min(self.maxScrollOffset, newScrollOffset))
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
