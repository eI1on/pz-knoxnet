local TerminalConstants = require("KnoxNet/core/TerminalConstants")

---@class ScrollManager
local ScrollManager = {}
ScrollManager.__index = ScrollManager

--- Create a new scroll manager
---@param contentHeight number Total height of the content
---@param visibleHeight number Height of the visible area
---@return ScrollManager
function ScrollManager:new(contentHeight, visibleHeight)
	local obj = setmetatable({}, self) ---@class ScrollManager
	obj.__index = self

	obj.contentHeight = contentHeight or 0
	obj.visibleHeight = visibleHeight or 0
	obj.scrollOffset = 0
	obj.maxScrollOffset = math.max(0, contentHeight - visibleHeight)
	obj.smoothScrollTarget = nil
	obj.smoothScrollSpeed = 8
	obj.lastUpdateTime = getTimeInMillis()
	obj.scrollListeners = {}
	obj.autoScroll = false
	obj.lastScrollDirection = nil

	return obj
end

--- Add a scroll listener function
---@param fn function Function to call on scroll changes
function ScrollManager:addScrollListener(fn)
	if type(fn) == "function" then
		table.insert(self.scrollListeners, fn)
	end
end

--- Notify scroll listeners of changes
---@param oldOffset number Previous scroll offset
function ScrollManager:notifyScrollListeners(oldOffset)
	if self.scrollOffset == oldOffset then
		return
	end

	for i = 1, #self.scrollListeners do
		self.scrollListeners[i](self.scrollOffset, oldOffset)
	end
end

--- Set autoScroll mode
---@param enabled boolean Whether to enable autoScroll
function ScrollManager:setAutoScroll(enabled)
	self.autoScroll = enabled
end

--- Get autoScroll status
---@return boolean autoScroll Current autoScroll status
function ScrollManager:getAutoScroll()
	return self.autoScroll
end

--- Scroll the content up
---@param amount number|nil Amount to scroll (default: 10)
function ScrollManager:scrollUp(amount)
	amount = amount or 10
	local oldOffset = self.scrollOffset
	local newOffset = math.max(0, self.scrollOffset - amount)

	self:scrollTo(newOffset, true)
end

--- Scroll the content down
---@param amount number Amount to scroll (default: 10)
function ScrollManager:scrollDown(amount)
	amount = amount or 10
	local oldOffset = self.scrollOffset
	local maxOffset = math.max(0, self.contentHeight - self.visibleHeight)
	local newOffset = math.min(maxOffset, self.scrollOffset + amount)

	self:scrollTo(newOffset, true)
end

--- Scroll to a specific position
---@param position number Target scroll position
---@param smooth boolean Whether to scroll smoothly (default: false)
function ScrollManager:scrollTo(position, smooth)
	local oldOffset = self.scrollOffset
	local maxOffset = math.max(0, self.contentHeight - self.visibleHeight)

	position = math.max(0, math.min(position, maxOffset))

	if smooth then
		self.smoothScrollTarget = position
	else
		self.scrollOffset = position
		self:notifyScrollListeners(oldOffset)
	end
end

--- Handle mouse wheel scrolling
---@param delta number Scroll delta from mouse wheel
function ScrollManager:onMouseWheel(delta)
	self.maxScrollOffset = math.max(0, self.contentHeight - self.visibleHeight)

	local scrollMultiplier = 4
	local scrollAmount = math.abs(delta) * scrollMultiplier

	if delta > 0 then
		self:scrollUp(scrollAmount)
	else
		self:scrollDown(scrollAmount)
	end
end

--- Check if a position is within the visible area
---@param position number Position to check
---@return boolean isVisible Whether the position is visible
function ScrollManager:isPositionVisible(position)
	return position >= self.scrollOffset and position < self.scrollOffset + self.visibleHeight
end

--- Get the adjusted Y position for rendering
---@param originalY number Original Y position
---@return number yPos Adjusted Y position
function ScrollManager:getAdjustedY(originalY)
	return originalY - self.scrollOffset
end

--- Get the current scroll offset
---@return number scrollOffset Current scroll offset
function ScrollManager:getScrollOffset()
	self.maxScrollOffset = math.max(0, self.contentHeight - self.visibleHeight)

	if self.scrollOffset > self.maxScrollOffset then
		self.scrollOffset = self.maxScrollOffset
	end
	if self.scrollOffset < 0 then
		self.scrollOffset = 0
	end

	return self.scrollOffset
end

--- Update content height
---@param newHeight number New content height
function ScrollManager:updateContentHeight(newHeight)
	local previousMaxOffset = self.maxScrollOffset
	local wasAtBottom = self.scrollOffset >= previousMaxOffset - 10
	local oldOffset = self.scrollOffset

	self.contentHeight = newHeight
	self.maxScrollOffset = math.max(0, self.contentHeight - self.visibleHeight)

	if wasAtBottom and previousMaxOffset > 0 then
		self.scrollOffset = self.maxScrollOffset
	else
		self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)
		self.scrollOffset = math.max(0, self.scrollOffset)
	end

	if self.smoothScrollTarget ~= nil then
		self.smoothScrollTarget = math.min(self.smoothScrollTarget, self.maxScrollOffset)
	end

	if oldOffset ~= self.scrollOffset then
		self:notifyScrollListeners(oldOffset)
	end
end

--- Update visible height
---@param newHeight number New visible height
function ScrollManager:updateVisibleHeight(newHeight)
	local oldOffset = self.scrollOffset
	self.visibleHeight = newHeight
	self.maxScrollOffset = math.max(0, self.contentHeight - self.visibleHeight)

	self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)

	if oldOffset ~= self.scrollOffset then
		self:notifyScrollListeners(oldOffset)
	end
end

--- Update scroll animation
---@param deltaTime number Time since last update in milliseconds
function ScrollManager:update(deltaTime)
	if self.smoothScrollTarget ~= nil then
		local oldOffset = self.scrollOffset
		local diff = self.smoothScrollTarget - self.scrollOffset
		local absDiff = math.abs(diff)

		if absDiff < 0.5 then
			self.scrollOffset = self.smoothScrollTarget
			self.smoothScrollTarget = nil
			self:notifyScrollListeners(oldOffset)
		else
			local moveAmount = math.min(absDiff, self.smoothScrollSpeed * (deltaTime / 16.67))
			if diff > 0 then
				self.scrollOffset = self.scrollOffset + moveAmount
			else
				self.scrollOffset = self.scrollOffset - moveAmount
			end

			if math.abs(oldOffset - self.scrollOffset) > 0.1 then
				self:notifyScrollListeners(oldOffset)
			end
		end
	end
end

--- Render a scrollbar
---@param uiElement ISUIElement UI object for rendering
---@param x number X position of scrollbar
---@param y number Y position of scrollbar
---@param height number Height of scrollbar
---@return number handleY Y position of scroll handle
---@return number handleHeight Height of scroll handle
function ScrollManager:renderScrollbar(uiElement, x, y, height)
	if self.contentHeight <= self.visibleHeight then
		return y, height
	end

	uiElement:drawRect(
		x,
		y,
		TerminalConstants.LAYOUT.SCROLLBAR.WIDTH,
		height,
		TerminalConstants.COLORS.SCROLLBAR.BACKGROUND.a,
		TerminalConstants.COLORS.SCROLLBAR.BACKGROUND.r,
		TerminalConstants.COLORS.SCROLLBAR.BACKGROUND.g,
		TerminalConstants.COLORS.SCROLLBAR.BACKGROUND.b
	)

	local handleRatio = math.min(1.0, self.visibleHeight / self.contentHeight)
	local handleHeight = math.max(TerminalConstants.LAYOUT.SCROLLBAR.MIN_HANDLE_HEIGHT, handleRatio * height)

	local maxOffset = math.max(0.1, self.contentHeight - self.visibleHeight)
	local scrollRatio = self.scrollOffset / maxOffset
	scrollRatio = math.max(0, math.min(1, scrollRatio))

	local availableTrackSpace = height - handleHeight
	local handleY = y
	if availableTrackSpace > 0 then
		handleY = y + (scrollRatio * availableTrackSpace)
	end

	uiElement:drawRect(
		x,
		handleY,
		TerminalConstants.LAYOUT.SCROLLBAR.WIDTH,
		handleHeight,
		TerminalConstants.COLORS.SCROLLBAR.HANDLE.a,
		TerminalConstants.COLORS.SCROLLBAR.HANDLE.r,
		TerminalConstants.COLORS.SCROLLBAR.HANDLE.g,
		TerminalConstants.COLORS.SCROLLBAR.HANDLE.b
	)

	uiElement:drawRectBorder(
		x,
		handleY,
		TerminalConstants.LAYOUT.SCROLLBAR.WIDTH,
		handleHeight,
		TerminalConstants.COLORS.SCROLLBAR.BORDER.a,
		TerminalConstants.COLORS.SCROLLBAR.BORDER.r,
		TerminalConstants.COLORS.SCROLLBAR.BORDER.g,
		TerminalConstants.COLORS.SCROLLBAR.BORDER.b
	)

	return handleY, handleHeight
end

return ScrollManager
