local DirectiveModuleManager = {}

local DirectiveManager = require("KnoxNet_DirectivesModule/core/DirectiveManager")
local DirectiveConstants = require("KnoxNet_DirectivesModule/core/DirectiveConstants")
local DirectiveUIHelper = require("KnoxNet_DirectivesModule/ui/DirectiveUIHelper")
local DirectiveRenderer = require("KnoxNet_DirectivesModule/ui/DirectiveRenderer")
local ScrollManager = require("KnoxNet/ui/ScrollManager")
local TextWrapper = require("KnoxNet/ui/TextWrapper")

DirectiveModuleManager.scrollManagers = {}
DirectiveModuleManager.tabs = {}
DirectiveModuleManager.selectedTab = 1
DirectiveModuleManager.currentView = "active"
DirectiveModuleManager.lastUpdateTime = 0
DirectiveModuleManager.lastClickTime = 0

DirectiveModuleManager.viewStates = {
	selectedDirective = 1,
	viewingDirective = nil,
	viewingContribution = nil,
	detailScrollOffset = 0,
	selectedDetailButton = 1,
	detailActionButtons = {},
	directivesList = {},
	initialHeightSet = false,
	cachedContentHeight = nil,
	previousView = nil,
	buttonAreaY = nil,
	buttonWidth = nil,
	buttonSpacing = nil,
	buttonStartX = nil,
}

function DirectiveModuleManager.init(terminal)
	DirectiveModuleManager.terminal = terminal
	DirectiveModuleManager.isAdmin = DirectiveModuleManager.checkAdminAccess()

	DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.ACTIVE

	DirectiveModuleManager.createTabs()
	DirectiveModuleManager.initScrollManagers()
	DirectiveModuleManager.loadData()
	DirectiveModuleManager.updateDirectivesList()

	return true
end

function DirectiveModuleManager.checkAdminAccess()
	if not isServer() and not isClient() then
		return true
	elseif isClient() then
		return isAdmin()
	end

	if getDebug() then
		return true
	end

	return false
end

function DirectiveModuleManager.createTabs()
	local tabs = {
		{
			id = DirectiveConstants.VIEWS.ACTIVE,
			text = "Active Directives",
			action = function()
				DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.ACTIVE
				DirectiveModuleManager.updateDirectivesList()
			end,
		},
		{
			id = DirectiveConstants.VIEWS.HISTORY,
			text = "Directives History",
			action = function()
				DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.HISTORY
				DirectiveModuleManager.updateDirectivesList()
			end,
		},
		{
			id = DirectiveConstants.VIEWS.CONTRIBUTIONS,
			text = "My Contributions",
			action = function()
				DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.CONTRIBUTIONS
				DirectiveModuleManager.updateDirectivesList()
			end,
		},
	}

	DirectiveModuleManager.tabs = tabs
end

function DirectiveModuleManager.initScrollManagers()
	local contentHeight = DirectiveModuleManager.terminal.contentAreaHeight - DirectiveConstants.LAYOUT.TAB.HEIGHT

	DirectiveModuleManager.scrollManagers = {
		[DirectiveConstants.VIEWS.ACTIVE] = ScrollManager:new(0, contentHeight),
		[DirectiveConstants.VIEWS.HISTORY] = ScrollManager:new(0, contentHeight),
		[DirectiveConstants.VIEWS.DETAILS] = ScrollManager:new(0, contentHeight),
		[DirectiveConstants.VIEWS.CONTRIBUTIONS] = ScrollManager:new(0, contentHeight),
	}

	DirectiveModuleManager.updateScrollManagers()
end

function DirectiveModuleManager.updateScrollManagers()
	local activeContent = DirectiveModuleManager.calculateDirectivesContentHeight()
	DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.ACTIVE]:updateContentHeight(activeContent)
	DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.HISTORY]:updateContentHeight(activeContent)
	DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.CONTRIBUTIONS]:updateContentHeight(activeContent)
end

function DirectiveModuleManager.calculateDirectivesContentHeight()
	local itemHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.HEIGHT
	local itemPadding = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.PADDING
	local count = #DirectiveModuleManager.viewStates.directivesList

	return math.max(itemHeight, count * (itemHeight + itemPadding))
end

function DirectiveModuleManager.loadData()
	DirectiveManager.loadDirectives()
end

function DirectiveModuleManager.updateDirectivesList()
	DirectiveModuleManager.viewStates.directivesList = {}
	DirectiveModuleManager.viewStates.selectedDirective = 1
	local scrollManager = DirectiveModuleManager.getCurrentScrollManager()
	if scrollManager then
		scrollManager:scrollTo(0, false)
	end

	local playerObj = getSpecificPlayer(0)
	local playerId = playerObj and (playerObj:getUsername() or tostring(playerObj:getPlayerNum())) or "unknown"

	if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.ACTIVE then
		for i, directive in ipairs(DirectiveManager.activeDirectives) do
			table.insert(DirectiveModuleManager.viewStates.directivesList, {
				directive = directive,
				index = i,
			})
		end
	elseif DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.HISTORY then
		for i, directive in ipairs(DirectiveManager.completedDirectives) do
			table.insert(DirectiveModuleManager.viewStates.directivesList, {
				directive = directive,
				index = i,
			})
		end
	elseif DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.CONTRIBUTIONS then
		for i, directive in ipairs(DirectiveManager.activeDirectives) do
			if directive.contributions and directive.contributions[playerId] then
				table.insert(DirectiveModuleManager.viewStates.directivesList, {
					directive = directive,
					index = i,
					contribution = directive.contributions[playerId],
				})
			end
		end

		for i, directive in ipairs(DirectiveManager.completedDirectives) do
			if directive.contributions and directive.contributions[playerId] then
				table.insert(DirectiveModuleManager.viewStates.directivesList, {
					directive = directive,
					index = i,
					contribution = directive.contributions[playerId],
				})
			end
		end
	end

	DirectiveModuleManager.updateScrollManagers()
end

function DirectiveModuleManager.setupDirectiveDetailView(directive, contribution)
	if not directive then
		return
	end

	local previousView = DirectiveModuleManager.currentView
	DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.DETAILS

	DirectiveModuleManager.viewStates.previousView = previousView
	DirectiveModuleManager.viewStates.viewingDirective = directive
	DirectiveModuleManager.viewStates.viewingContribution = contribution

	DirectiveModuleManager.viewStates.detailScrollOffset = 0
	DirectiveModuleManager.viewStates.selectedDetailButton = 0
	DirectiveModuleManager.viewStates.detailActionButtons = {}
	DirectiveModuleManager.viewStates.initialHeightSet = false
	DirectiveModuleManager.viewStates.cachedContentHeight = nil

	if directive.isActive then
		table.insert(DirectiveModuleManager.viewStates.detailActionButtons, {
			text = "CONTRIBUTE ITEMS",
			action = function()
				DirectiveModuleManager.openContributionInterface()
			end,
		})
	end

	local playerObj = getSpecificPlayer(0)
	local playerId = playerObj and (playerObj:getUsername() or tostring(playerObj:getPlayerNum())) or "unknown"

	if directive.completed and directive:qualifiesForReward(playerId) then
		local hasClaimedReward = directive.contributions[playerId] and directive.contributions[playerId].rewardClaimed

		if not hasClaimedReward then
			table.insert(DirectiveModuleManager.viewStates.detailActionButtons, {
				text = "CLAIM REWARD",
				action = function()
					DirectiveModuleManager.claimDirectiveReward()
				end,
			})
		end
	end

	table.insert(DirectiveModuleManager.viewStates.detailActionButtons, {
		text = "BACK",
		action = function()
			DirectiveModuleManager.currentView = DirectiveModuleManager.viewStates.previousView
				or DirectiveConstants.VIEWS.ACTIVE
			DirectiveModuleManager.viewStates.viewingDirective = nil
			DirectiveModuleManager.viewStates.viewingContribution = nil
			DirectiveModuleManager.updateDirectivesList()
		end,
	})

	local detailContentHeight = DirectiveModuleManager.calculateDetailContentHeight(directive, contribution)

	local scrollManager = DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.DETAILS]
	scrollManager:updateContentHeight(detailContentHeight)
	scrollManager:scrollTo(0, false)
end

function DirectiveModuleManager.calculateDetailContentHeight(directive, contribution)
	if not directive then
		return 300
	end

	local height = 0

	height = height + 50

	local descLines = TextWrapper.wrap(
		directive.description,
		DirectiveModuleManager.terminal.displayWidth - 80,
		DirectiveConstants.LAYOUT.FONT.CODE
	)
	height = height + 30 + (#descLines * 20) + 20

	height = height + 60 + 40

	if directive.directiveType == DirectiveConstants.DIRECTIVE_TYPES.SCAVENGE then
		height = height + 20 -- Header

		if directive.minContributionForReward and directive.minContributionForReward > 1 then
			height = height + 20
		end

		if directive.acceptedItems then
			height = height + (#directive.acceptedItems * 20)
		end
	end

	height = height + 20 + 20 -- Headers

	if directive.rewards then
		if directive.rewards.global and directive.rewards.global.lore and directive.rewards.global.lore ~= "" then
			local loreLines = TextWrapper.wrap(
				"Lore: " .. directive.rewards.global.lore,
				DirectiveModuleManager.terminal.displayWidth - 120,
				DirectiveConstants.LAYOUT.FONT.SMALL
			)
			height = height + (#loreLines * 15)
		end

		height = height + 20 -- Individual rewards header

		if directive.rewards.individual then
			if directive.rewards.individual.items then
				height = height + (#directive.rewards.individual.items * 15)
			end

			if directive.rewards.individual.skills then
				height = height + 5 + (#directive.rewards.individual.skills * 15)
			end
		end
	end

	if DirectiveModuleManager.isAdmin then
		height = height + 40
	end

	height = height + 10 + DirectiveConstants.LAYOUT.BUTTON.HEIGHT + 20

	return height
end

function DirectiveModuleManager.openContributionInterface()
	if
		not DirectiveModuleManager.viewStates.viewingDirective
		or not DirectiveModuleManager.viewStates.viewingDirective.isActive
	then
		return
	end

	local ContributionInterface = require("KnoxNet_DirectivesModule/ui/ContributionInterface")
	if ContributionInterface.openPanel then
		ContributionInterface.openPanel(DirectiveModuleManager.viewStates.viewingDirective, getSpecificPlayer(0))
	end
end

function DirectiveModuleManager.claimDirectiveReward()
	local directive = DirectiveModuleManager.viewStates.viewingDirective
	if not directive or not directive.completed then
		return
	end
	local playerObj = getSpecificPlayer(0)
	local playerId = playerObj and (playerObj:getUsername() or tostring(playerObj:getPlayerNum())) or "unknown"

	if not directive:qualifiesForReward(playerId) then
		return
	end

	local success = DirectiveManager.awardRewards(directive.id, playerId, playerObj)

	if success then
		local modal = ISModalDialog:new(
			getCore():getScreenWidth() / 2 - 175,
			getCore():getScreenHeight() / 2 - 75,
			350,
			150,
			"Rewards Claimed",
			true,
			nil,
			nil
		)
		modal.text = "You have successfully claimed your rewards!"
		modal:initialise()
		modal:addToUIManager()

		DirectiveModuleManager.setupDirectiveDetailView(directive)
	end
end

function DirectiveModuleManager.getCurrentScrollManager()
	local view = DirectiveModuleManager.currentView

	if view == DirectiveConstants.VIEWS.DETAILS then
		return DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.DETAILS]
	else
		return DirectiveModuleManager.scrollManagers[view]
			or DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.ACTIVE]
	end
end

function DirectiveModuleManager.onActivate()
	DirectiveModuleManager.init(DirectiveModuleManager.terminal)
	DirectiveModuleManager.terminal:setTitle("DIRECTIVES TERMINAL")
	DirectiveModuleManager.currentView = DirectiveConstants.VIEWS.ACTIVE
	DirectiveModuleManager.updateDirectivesList()
	DirectiveModuleManager.terminal:playRandomKeySound()
end

function DirectiveModuleManager.onDeactivate()
	DirectiveManager.saveDirectives()
end

function DirectiveModuleManager.onClose()
	DirectiveModuleManager.onDeactivate()
end

function DirectiveModuleManager.update()
	local currentTime = getTimeInMillis()
	local timeDelta = currentTime - (DirectiveModuleManager.lastUpdateTime or currentTime)
	DirectiveModuleManager.lastUpdateTime = currentTime

	local scrollManager = DirectiveModuleManager.getCurrentScrollManager()
	if scrollManager and scrollManager.update then
		scrollManager:update(timeDelta)

		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
			DirectiveModuleManager.viewStates.detailScrollOffset = scrollManager:getScrollOffset()

			if scrollManager.contentHeight > scrollManager.visibleHeight then
				local maxScroll = scrollManager.contentHeight - scrollManager.visibleHeight
				local currentScroll = scrollManager:getScrollOffset()

				local bottomThreshold = 5 -- pixels from bottom
				if
					math.abs(currentScroll - maxScroll) <= bottomThreshold
					and #DirectiveModuleManager.viewStates.detailActionButtons > 0
					and DirectiveModuleManager.viewStates.selectedDetailButton == 0
				then
					DirectiveModuleManager.viewStates.selectedDetailButton = 1
				end
			end
		end
	end
end

function DirectiveModuleManager.onKeyPress(key)
	DirectiveModuleManager.terminal:playRandomKeySound()

	if key == Keyboard.KEY_LEFT then
		local currentTabIndex = DirectiveModuleManager.getTabIndexForView(DirectiveModuleManager.currentView)
		if currentTabIndex and currentTabIndex > 1 then
			DirectiveModuleManager.selectedTab = currentTabIndex - 1
			DirectiveModuleManager.tabs[DirectiveModuleManager.selectedTab].action()
		end
		return true
	elseif key == Keyboard.KEY_RIGHT then
		local currentTabIndex = DirectiveModuleManager.getTabIndexForView(DirectiveModuleManager.currentView)
		if currentTabIndex and currentTabIndex < #DirectiveModuleManager.tabs then
			DirectiveModuleManager.selectedTab = currentTabIndex + 1
			DirectiveModuleManager.tabs[DirectiveModuleManager.selectedTab].action()
		end
		return true
	elseif key == Keyboard.KEY_BACK then
		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
			DirectiveModuleManager.currentView = DirectiveModuleManager.viewStates.previousView
				or DirectiveConstants.VIEWS.ACTIVE
			DirectiveModuleManager.viewStates.viewingDirective = nil
			DirectiveModuleManager.viewStates.viewingContribution = nil
			DirectiveModuleManager.updateDirectivesList()
			return true
		end
	elseif key == Keyboard.KEY_UP then
		local handled = false

		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
			local scrollManager = DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.DETAILS]

			if DirectiveModuleManager.viewStates.selectedDetailButton > 0 then
				if DirectiveModuleManager.viewStates.selectedDetailButton > 1 then
					DirectiveModuleManager.viewStates.selectedDetailButton = DirectiveModuleManager.viewStates.selectedDetailButton
						- 1
					handled = true
				else
					DirectiveModuleManager.viewStates.selectedDetailButton = 0

					local maxOffset = scrollManager.maxScrollOffset
					if maxOffset > 0 then
						scrollManager:scrollTo(maxOffset - 20, true)
					end

					handled = true
				end
			else
				local currentOffset = scrollManager:getScrollOffset()
				if currentOffset > 0 then
					scrollManager:scrollUp(20)
					DirectiveModuleManager.viewStates.detailScrollOffset = scrollManager:getScrollOffset()
					handled = true
				end
			end
		elseif DirectiveModuleManager.isListView() then
			if DirectiveModuleManager.viewStates.selectedDirective > 1 then
				DirectiveModuleManager.viewStates.selectedDirective = DirectiveModuleManager.viewStates.selectedDirective
					- 1

				local itemHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.HEIGHT
				local itemPadding = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.PADDING
				local itemPosition = (DirectiveModuleManager.viewStates.selectedDirective - 1)
					* (itemHeight + itemPadding)

				local scrollManager = DirectiveModuleManager.getCurrentScrollManager()
				if scrollManager and itemPosition < scrollManager:getScrollOffset() then
					scrollManager:scrollTo(itemPosition, true)
				end

				handled = true
			end
		end

		return handled
	elseif key == Keyboard.KEY_DOWN then
		local handled = false

		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
			local scrollManager = DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.DETAILS]
			local currentOffset = scrollManager:getScrollOffset()
			local maxOffset = scrollManager.maxScrollOffset

			local isNearBottom = (maxOffset - currentOffset) < 50

			if DirectiveModuleManager.viewStates.selectedDetailButton == 0 then
				if currentOffset < maxOffset then
					scrollManager:scrollDown(20)
					DirectiveModuleManager.viewStates.detailScrollOffset = scrollManager:getScrollOffset()

					if isNearBottom or (maxOffset - scrollManager:getScrollOffset()) < 30 then
						if #DirectiveModuleManager.viewStates.detailActionButtons > 0 then
							DirectiveModuleManager.viewStates.selectedDetailButton = 1
						end
					end

					handled = true
				else
					if #DirectiveModuleManager.viewStates.detailActionButtons > 0 then
						DirectiveModuleManager.viewStates.selectedDetailButton = 1
						handled = true
					end
				end
			elseif
				DirectiveModuleManager.viewStates.selectedDetailButton
				< #DirectiveModuleManager.viewStates.detailActionButtons
			then
				DirectiveModuleManager.viewStates.selectedDetailButton = DirectiveModuleManager.viewStates.selectedDetailButton
					+ 1
				handled = true
			end
		elseif DirectiveModuleManager.isListView() then
			if
				DirectiveModuleManager.viewStates.selectedDirective < #DirectiveModuleManager.viewStates.directivesList
			then
				DirectiveModuleManager.viewStates.selectedDirective = DirectiveModuleManager.viewStates.selectedDirective
					+ 1

				local itemHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.HEIGHT
				local itemPadding = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.PADDING
				local visibleHeight = DirectiveModuleManager.terminal.contentAreaHeight
					- DirectiveConstants.LAYOUT.TAB.HEIGHT
				local itemPosition = (DirectiveModuleManager.viewStates.selectedDirective - 1)
					* (itemHeight + itemPadding)
				local itemBottom = itemPosition + itemHeight

				local scrollManager = DirectiveModuleManager.getCurrentScrollManager()
				if scrollManager and itemBottom > scrollManager:getScrollOffset() + visibleHeight then
					scrollManager:scrollTo(itemPosition - visibleHeight + itemHeight + itemPadding, true)
				end

				handled = true
			end
		end

		return handled
	elseif key == Keyboard.KEY_SPACE then
		local handled = false

		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
			if
				DirectiveModuleManager.viewStates.selectedDetailButton > 0
				and DirectiveModuleManager.viewStates.selectedDetailButton
					<= #DirectiveModuleManager.viewStates.detailActionButtons
			then
				local button =
					DirectiveModuleManager.viewStates.detailActionButtons[DirectiveModuleManager.viewStates.selectedDetailButton]
				if button and button.action then
					button.action()
					handled = true
				end
			else
				if #DirectiveModuleManager.viewStates.detailActionButtons > 0 then
					DirectiveModuleManager.viewStates.selectedDetailButton = 1
					handled = true
				end
			end
		elseif DirectiveModuleManager.isListView() then
			if
				DirectiveModuleManager.viewStates.selectedDirective > 0
				and DirectiveModuleManager.viewStates.selectedDirective
					<= #DirectiveModuleManager.viewStates.directivesList
			then
				local directiveInfo =
					DirectiveModuleManager.viewStates.directivesList[DirectiveModuleManager.viewStates.selectedDirective]

				if directiveInfo.directive then
					DirectiveModuleManager.setupDirectiveDetailView(directiveInfo.directive, directiveInfo.contribution)
					handled = true
				end
			end
		end

		return handled
	end

	return false
end

function DirectiveModuleManager.onMouseWheel(delta)
	local scrollAmount = 20
	local scrollManager = DirectiveModuleManager.getCurrentScrollManager()

	if scrollManager then
		local previousOffset = scrollManager:getScrollOffset()

		if delta > 0 then
			scrollManager:scrollUp(scrollAmount)
		else
			scrollManager:scrollDown(scrollAmount)
		end

		if
			DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS
			and previousOffset ~= scrollManager:getScrollOffset()
		then
			DirectiveModuleManager.viewStates.selectedDetailButton = 0
		end

		return true
	end

	return false
end

function DirectiveModuleManager.onMouseDown(x, y)
	local tabY = DirectiveModuleManager.terminal.titleAreaY + DirectiveModuleManager.terminal.titleAreaHeight
	local tabHeight = DirectiveConstants.LAYOUT.TAB.HEIGHT

	local tabBarHeight = DirectiveUIHelper.drawTabBar(
		DirectiveModuleManager.terminal,
		DirectiveModuleManager.terminal.displayX,
		tabY,
		DirectiveModuleManager.terminal.displayWidth,
		tabHeight,
		DirectiveModuleManager.tabs,
		DirectiveModuleManager.getTabIndexForView(DirectiveModuleManager.currentView),
		true
	)

	if y >= tabY and y < tabY + tabBarHeight then
		local tabFont = DirectiveConstants.LAYOUT.FONT.CODE
		local tabPadding = DirectiveConstants.LAYOUT.TAB.DEFAULT_PADDING

		local totalTabsWidth = 0
		local tabWidths = {}

		for i, tab in ipairs(DirectiveModuleManager.tabs) do
			local textWidth = getTextManager():MeasureStringX(tabFont, tab.text)
			local tabWidth = textWidth + (tabPadding * 2)
			totalTabsWidth = totalTabsWidth + tabWidth
			tabWidths[i] = tabWidth
		end

		local maxTabWidth = 0
		for i = 1, #tabWidths do
			maxTabWidth = math.max(maxTabWidth, tabWidths[i])
		end

		local tabsPerRow
		local tabPositions = {}
		local displayWidth = DirectiveModuleManager.terminal.displayWidth

		if totalTabsWidth <= displayWidth then
			tabsPerRow = #DirectiveModuleManager.tabs
			local tabWidth = displayWidth / #DirectiveModuleManager.tabs

			for i = 1, #DirectiveModuleManager.tabs do
				tabPositions[i] = {
					row = 0,
					col = i - 1,
					width = tabWidth,
					x = DirectiveModuleManager.terminal.displayX + (i - 1) * tabWidth,
					y = tabY,
				}
			end
		else
			tabsPerRow = math.floor(displayWidth / maxTabWidth)
			if tabsPerRow == 0 then
				tabsPerRow = 1
			end

			local tabWidth = displayWidth / math.min(tabsPerRow, #DirectiveModuleManager.tabs)

			for i = 1, #DirectiveModuleManager.tabs do
				local row = math.floor((i - 1) / tabsPerRow)
				local col = (i - 1) % tabsPerRow

				tabPositions[i] = {
					row = row,
					col = col,
					width = tabWidth,
					x = DirectiveModuleManager.terminal.displayX + col * tabWidth,
					y = tabY + row * tabHeight,
				}
			end
		end

		for i, pos in ipairs(tabPositions) do
			if x >= pos.x and x < pos.x + pos.width and y >= pos.y and y < pos.y + tabHeight then
				DirectiveModuleManager.selectedTab = i
				DirectiveModuleManager.tabs[i].action()
				return true
			end
		end
	end

	local contentAreaY = tabY + tabHeight

	if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
		local scrollManager = DirectiveModuleManager.getCurrentScrollManager()
		if scrollManager then
			local scrollbarX = DirectiveModuleManager.terminal.displayX
				+ DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING

			local scrollbarY = contentAreaY
			local scrollbarHeight = DirectiveModuleManager.terminal.contentAreaHeight

			if
				x >= scrollbarX
				and x < scrollbarX + DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				and y >= scrollbarY
				and y < scrollbarY + scrollbarHeight
			then
				local clickRatio = (y - scrollbarY) / scrollbarHeight
				local targetScrollPosition = clickRatio * scrollManager.contentHeight

				if targetScrollPosition > scrollManager.contentHeight - scrollManager.visibleHeight then
					targetScrollPosition = scrollManager.contentHeight - scrollManager.visibleHeight
				end

				scrollManager:scrollTo(targetScrollPosition, true)
				DirectiveModuleManager.viewStates.detailScrollOffset = scrollManager:getScrollOffset()
				DirectiveModuleManager.viewStates.selectedDetailButton = 0
				return true
			end
		end

		if
			DirectiveModuleManager.viewStates.buttonAreaY
			and DirectiveModuleManager.viewStates.detailActionButtons
			and #DirectiveModuleManager.viewStates.detailActionButtons > 0
		then
			local buttonY = DirectiveModuleManager.viewStates.buttonAreaY
			local buttonHeight = DirectiveModuleManager.viewStates.buttonAreaHeight
				or DirectiveConstants.LAYOUT.BUTTON.HEIGHT
			local buttonWidth = DirectiveModuleManager.viewStates.buttonWidth or 150
			local buttonSpacing = DirectiveModuleManager.viewStates.buttonSpacing or 20
			local startX = DirectiveModuleManager.viewStates.buttonStartX

			if startX and y >= buttonY and y < buttonY + buttonHeight then
				for i, button in ipairs(DirectiveModuleManager.viewStates.detailActionButtons) do
					local buttonX = startX + (i - 1) * (buttonWidth + buttonSpacing)

					if x >= buttonX and x < buttonX + buttonWidth then
						DirectiveModuleManager.viewStates.selectedDetailButton = i

						if button.action then
							button.action()
						end

						return true
					end
				end
			end
		end

		local buttonAreaHeight = DirectiveConstants.LAYOUT.BUTTON.HEIGHT + 20
		local contentMax = contentAreaY + DirectiveModuleManager.terminal.contentAreaHeight - buttonAreaHeight

		if
			y >= contentAreaY
			and y < contentMax
			and x
				< DirectiveModuleManager.terminal.displayX + DirectiveModuleManager.terminal.displayWidth - DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH - DirectiveConstants.LAYOUT.SCROLLBAR.PADDING
		then
			DirectiveModuleManager.viewStates.selectedDetailButton = 0
			return true
		end

		return true
	end

	if DirectiveModuleManager.isListView() then
		local itemHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.HEIGHT
		local itemPadding = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.PADDING

		if
			#DirectiveModuleManager.viewStates.directivesList > DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.VISIBLE_COUNT
		then
			local scrollbarX = DirectiveModuleManager.terminal.displayX
				+ DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING

			local scrollbarY = contentAreaY
			local scrollbarHeight = DirectiveModuleManager.terminal.contentAreaHeight - 20

			if
				x >= scrollbarX
				and x < scrollbarX + DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				and y >= scrollbarY
				and y < scrollbarY + scrollbarHeight
			then
				local currentScrollManager = DirectiveModuleManager.getCurrentScrollManager()

				if currentScrollManager then
					local contentHeight = #DirectiveModuleManager.viewStates.directivesList * (itemHeight + itemPadding)
					local visibleHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.VISIBLE_COUNT
						* (itemHeight + itemPadding)
					local maxScroll = math.max(0, contentHeight - visibleHeight)
					local clickPosition = (y - scrollbarY) / scrollbarHeight

					clickPosition = math.max(0, math.min(1, clickPosition))
					currentScrollManager:scrollTo(math.floor(clickPosition * maxScroll), true)
					return true
				end
			end
		end

		local startY = contentAreaY + itemPadding
		local currentScrollManager = DirectiveModuleManager.getCurrentScrollManager()
		local scrollOffset = currentScrollManager and currentScrollManager:getScrollOffset() or 0
		local itemsToSkip = math.floor(scrollOffset / (itemHeight + itemPadding))

		for i = 1, math.min(
			DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.VISIBLE_COUNT,
			#DirectiveModuleManager.viewStates.directivesList - itemsToSkip
		) do
			local index = itemsToSkip + i

			if index <= #DirectiveModuleManager.viewStates.directivesList then
				local itemY = startY + (i - 1) * (itemHeight + itemPadding)
				local itemWidth = DirectiveModuleManager.terminal.displayWidth
					- 2 * itemPadding
					- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH

				local itemX = DirectiveModuleManager.terminal.displayX + itemPadding

				if x >= itemX and x < itemX + itemWidth and y >= itemY and y < itemY + itemHeight then
					DirectiveModuleManager.viewStates.selectedDirective = index

					if
						DirectiveModuleManager.lastClickTime
						and getTimeInMillis() - DirectiveModuleManager.lastClickTime < 300
					then
						local directiveInfo =
							DirectiveModuleManager.viewStates.directivesList[DirectiveModuleManager.viewStates.selectedDirective]

						if directiveInfo and directiveInfo.directive then
							DirectiveModuleManager.setupDirectiveDetailView(
								directiveInfo.directive,
								directiveInfo.contribution
							)
						end
					end

					DirectiveModuleManager.lastClickTime = getTimeInMillis()
					return true
				end
			end
		end
	end

	return true
end

function DirectiveModuleManager.render()
	local title = "DIRECTIVES TERMINAL"
	if DirectiveModuleManager.isAdmin then
		title = title .. " [ADMIN MODE]"
	end

	DirectiveModuleManager.terminal:renderTitle(title)

	local tabHeight = DirectiveUIHelper.drawTabBar(
		DirectiveModuleManager.terminal,
		DirectiveModuleManager.terminal.displayX,
		DirectiveModuleManager.terminal.titleAreaY + DirectiveModuleManager.terminal.titleAreaHeight,
		DirectiveModuleManager.terminal.displayWidth,
		DirectiveConstants.LAYOUT.TAB.HEIGHT,
		DirectiveModuleManager.tabs,
		DirectiveModuleManager.getTabIndexForView(DirectiveModuleManager.currentView),
		false
	)

	local contentStartY = DirectiveModuleManager.terminal.titleAreaY
		+ DirectiveModuleManager.terminal.titleAreaHeight
		+ tabHeight

	local contentHeight = DirectiveModuleManager.terminal.contentAreaHeight - tabHeight

	DirectiveModuleManager.terminal:clearStencilRect()
	DirectiveModuleManager.terminal:setStencilRect(
		DirectiveModuleManager.terminal.displayX,
		contentStartY,
		DirectiveModuleManager.terminal.displayWidth,
		contentHeight
	)

	if DirectiveModuleManager.isListView() then
		DirectiveModuleManager.renderDirectivesList(contentStartY, contentHeight)
	elseif DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
		DirectiveModuleManager.renderDirectiveDetails(contentStartY, contentHeight)
	end

	local currentScrollManager = DirectiveModuleManager.getCurrentScrollManager()
	if currentScrollManager and currentScrollManager.contentHeight > currentScrollManager.visibleHeight then
		if DirectiveModuleManager.currentView ~= DirectiveConstants.VIEWS.DETAILS then
			local scrollbarX = DirectiveModuleManager.terminal.displayX
				+ DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING

			DirectiveModuleManager.terminal:clearStencilRect()
			currentScrollManager:renderScrollbar(
				DirectiveModuleManager.terminal,
				scrollbarX,
				contentStartY,
				contentHeight
			)
		end
	end

	DirectiveModuleManager.terminal:clearStencilRect()

	local footerText = ""

	if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.DETAILS then
		footerText = "UP/DOWN - Scroll/Select | SPACE - Activate | BACKSPACE - Return"
	else
		footerText = "LEFT/RIGHT - Change Tab | SPACE - Select | BACKSPACE - Back"
	end

	DirectiveModuleManager.terminal:renderFooter(footerText)
end

function DirectiveModuleManager.renderDirectivesList(startY, contentHeight)
	DirectiveModuleManager.terminal:drawRect(
		DirectiveModuleManager.terminal.displayX,
		startY,
		DirectiveModuleManager.terminal.displayWidth,
		contentHeight,
		DirectiveConstants.COLORS.BACKGROUND.a,
		DirectiveConstants.COLORS.BACKGROUND.r,
		DirectiveConstants.COLORS.BACKGROUND.g,
		DirectiveConstants.COLORS.BACKGROUND.b
	)

	if #DirectiveModuleManager.viewStates.directivesList == 0 then
		local message = "No directives found."
		if DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.CONTRIBUTIONS then
			message = "You haven't contributed to any directives yet."
		end

		local textWidth = getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.CODE, message)
		local textX = DirectiveModuleManager.terminal.displayX
			+ (DirectiveModuleManager.terminal.displayWidth - textWidth) / 2
		local textY = startY + 50

		DirectiveModuleManager.terminal:drawText(
			message,
			textX,
			textY,
			DirectiveConstants.COLORS.TEXT.NORMAL.r,
			DirectiveConstants.COLORS.TEXT.NORMAL.g,
			DirectiveConstants.COLORS.TEXT.NORMAL.b,
			DirectiveConstants.COLORS.TEXT.NORMAL.a,
			DirectiveConstants.LAYOUT.FONT.CODE
		)
		return
	end

	local currentScrollManager = DirectiveModuleManager.getCurrentScrollManager()
	local scrollOffset = currentScrollManager and currentScrollManager:getScrollOffset() or 0

	local itemHeight = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.HEIGHT
	local itemPadding = DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.PADDING
	local listStartY = startY + itemPadding

	local itemsToSkip = math.floor(scrollOffset / (itemHeight + itemPadding))
	local visibleItems = math.min(
		DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.VISIBLE_COUNT,
		#DirectiveModuleManager.viewStates.directivesList - itemsToSkip
	)

	for i = 1, visibleItems do
		local index = itemsToSkip + i
		if index <= #DirectiveModuleManager.viewStates.directivesList then
			local directiveInfo = DirectiveModuleManager.viewStates.directivesList[index]
			local isSelected = (index == DirectiveModuleManager.viewStates.selectedDirective)

			local itemY = listStartY + (i - 1) * (itemHeight + itemPadding)
			local itemWidth = DirectiveModuleManager.terminal.displayWidth
				- 2 * itemPadding
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
			local itemX = DirectiveModuleManager.terminal.displayX + itemPadding

			DirectiveRenderer.renderDirectiveItem(
				DirectiveModuleManager.terminal,
				directiveInfo.directive,
				itemX,
				itemY,
				itemWidth,
				itemHeight,
				isSelected,
				DirectiveModuleManager.isAdmin
			)

			if
				DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.CONTRIBUTIONS
				and directiveInfo.contribution
			then
				local contributionText = "Your Contribution: " .. directiveInfo.contribution.total .. " items"
				local textWidth =
					getTextManager():MeasureStringX(DirectiveConstants.LAYOUT.FONT.SMALL, contributionText)

				DirectiveModuleManager.terminal:drawText(
					contributionText,
					itemX + itemWidth - textWidth - 10,
					itemY + itemHeight - 25,
					DirectiveConstants.COLORS.TEXT.HIGHLIGHT.r,
					DirectiveConstants.COLORS.TEXT.HIGHLIGHT.g,
					DirectiveConstants.COLORS.TEXT.HIGHLIGHT.b,
					DirectiveConstants.COLORS.TEXT.HIGHLIGHT.a,
					DirectiveConstants.LAYOUT.FONT.SMALL
				)

				if directiveInfo.directive.completed then
					local rewardText = directiveInfo.contribution.rewardClaimed and "Reward Claimed"
						or "Reward Available"

					local rewardColor = directiveInfo.contribution.rewardClaimed and DirectiveConstants.COLORS.TEXT.DIM
						or DirectiveConstants.COLORS.TEXT.WARNING

					DirectiveModuleManager.terminal:drawText(
						rewardText,
						itemX + 10,
						itemY + itemHeight - 25,
						rewardColor.r,
						rewardColor.g,
						rewardColor.b,
						rewardColor.a,
						DirectiveConstants.LAYOUT.FONT.SMALL
					)
				end
			end
		end
	end

	if #DirectiveModuleManager.viewStates.directivesList > DirectiveConstants.LAYOUT.DIRECTIVE_ITEM.VISIBLE_COUNT then
		local totalContentHeight = DirectiveModuleManager.calculateDirectivesContentHeight()

		DirectiveUIHelper.drawScrollbar(
			DirectiveModuleManager.terminal,
			DirectiveModuleManager.terminal.displayX
				+ DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING,
			startY,
			contentHeight,
			totalContentHeight,
			contentHeight,
			scrollOffset
		)
	end
end

function DirectiveModuleManager.renderDirectiveDetails(startY, contentHeight)
	if not DirectiveModuleManager.viewStates.viewingDirective then
		return
	end

	local directive = DirectiveModuleManager.viewStates.viewingDirective
	local contribution = DirectiveModuleManager.viewStates.viewingContribution

	local scrollManager = DirectiveModuleManager.scrollManagers[DirectiveConstants.VIEWS.DETAILS]
	local scrollOffset = scrollManager:getScrollOffset()

	DirectiveModuleManager.terminal:drawRect(
		DirectiveModuleManager.terminal.displayX,
		startY,
		DirectiveModuleManager.terminal.displayWidth,
		contentHeight,
		DirectiveConstants.COLORS.BACKGROUND.a,
		DirectiveConstants.COLORS.BACKGROUND.r,
		DirectiveConstants.COLORS.BACKGROUND.g,
		DirectiveConstants.COLORS.BACKGROUND.b
	)

	DirectiveModuleManager.terminal:clearStencilRect()
	DirectiveModuleManager.terminal:setStencilRect(
		DirectiveModuleManager.terminal.displayX,
		startY,
		DirectiveModuleManager.terminal.displayWidth
			- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
			- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING,
		contentHeight
	)

	local totalContentHeight

	if not DirectiveModuleManager.viewStates.initialHeightSet then
		totalContentHeight = DirectiveRenderer.renderDirectiveDetails(
			DirectiveModuleManager.terminal,
			directive,
			DirectiveModuleManager.terminal.displayX,
			startY,
			DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING,
			contentHeight,
			scrollOffset,
			DirectiveModuleManager.isAdmin
		)

		scrollManager.contentHeight = totalContentHeight
		scrollManager.maxScrollOffset = math.max(0, totalContentHeight - contentHeight)
		DirectiveModuleManager.viewStates.cachedContentHeight = totalContentHeight
		DirectiveModuleManager.viewStates.initialHeightSet = true
	else
		totalContentHeight = DirectiveModuleManager.viewStates.cachedContentHeight

		DirectiveRenderer.renderDirectiveDetails(
			DirectiveModuleManager.terminal,
			directive,
			DirectiveModuleManager.terminal.displayX,
			startY,
			DirectiveModuleManager.terminal.displayWidth
				- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
				- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING,
			contentHeight,
			scrollOffset,
			DirectiveModuleManager.isAdmin
		)
	end

	local buttons = DirectiveModuleManager.viewStates.detailActionButtons
	if buttons and #buttons > 0 then
		local buttonHeight = DirectiveConstants.LAYOUT.BUTTON.HEIGHT
		local buttonWidth = 150
		local buttonSpacing = 20

		local totalButtonWidth = (#buttons * buttonWidth) + ((#buttons - 1) * buttonSpacing)
		local startX = DirectiveModuleManager.terminal.displayX
			+ (
					DirectiveModuleManager.terminal.displayWidth
					- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
					- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING
					- totalButtonWidth
				)
				/ 2

		local buttonY = DirectiveModuleManager.terminal.buttonAreaY

		if buttonY then
			for i, button in ipairs(buttons) do
				local buttonX = startX + (i - 1) * (buttonWidth + buttonSpacing)
				local isSelected = (i == DirectiveModuleManager.viewStates.selectedDetailButton)

				DirectiveUIHelper.drawButton(
					DirectiveModuleManager.terminal,
					buttonX,
					buttonY,
					buttonWidth,
					buttonHeight,
					button.text,
					isSelected,
					false
				)
			end

			DirectiveModuleManager.viewStates.buttonAreaY = buttonY
			DirectiveModuleManager.viewStates.buttonAreaHeight = buttonHeight
			DirectiveModuleManager.viewStates.buttonWidth = buttonWidth
			DirectiveModuleManager.viewStates.buttonSpacing = buttonSpacing
			DirectiveModuleManager.viewStates.buttonStartX = startX
		end
	end

	DirectiveModuleManager.terminal:clearStencilRect()

	if totalContentHeight > contentHeight then
		local scrollbarX = DirectiveModuleManager.terminal.displayX
			+ DirectiveModuleManager.terminal.displayWidth
			- DirectiveConstants.LAYOUT.SCROLLBAR.WIDTH
			- DirectiveConstants.LAYOUT.SCROLLBAR.PADDING

		local fixedContentHeight = DirectiveModuleManager.viewStates.cachedContentHeight or totalContentHeight

		DirectiveUIHelper.drawScrollbar(
			DirectiveModuleManager.terminal,
			scrollbarX,
			startY,
			contentHeight,
			fixedContentHeight,
			contentHeight,
			scrollOffset
		)
	end
end

function DirectiveModuleManager.isListView()
	return DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.ACTIVE
		or DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.HISTORY
		or DirectiveModuleManager.currentView == DirectiveConstants.VIEWS.CONTRIBUTIONS
end

function DirectiveModuleManager.getTabIndexForView(view)
	for i, tab in ipairs(DirectiveModuleManager.tabs) do
		if tab.id == view then
			return i
		end
	end
	return 1
end

function DirectiveModuleManager.findDirectiveById(directiveId)
	return DirectiveManager.findDirectiveById(directiveId)
end

return DirectiveModuleManager
