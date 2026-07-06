require("ISUI/ISCollapsableWindow")
require("ISUI/ISButton")
require("ISUI/ISScrollingListBox")
require("ISUI/ISTextEntryBox")
require("ISUI/ISComboBox")
require("ISUI/ISLabel")
require("ISUI/ISUIElement")
require("ISUI/Maps/ISWorldMap")

local Shared = require("KnoxNet/Shared")
local Client = require("KnoxNet/Client")
local Theme = require("ElyonLib/UI/Theme/Theme")
local Layout = require("ElyonLib/UI/Layout/LayoutUtils")
local TextUtils = require("ElyonLib/TextUtils/TextUtils")
local MenuDock = require("ElyonLib/UI/MenuDock/MenuDock")

local T = Theme.colors

local C = {
	LAYOUT = {
		PAD = 10,
		GAP_SM = 6,
		GAP_MD = 10,
		GAP_LG = 16,
		SECTION = 14,
		COMPOSE_LABEL_GAP = 8,
	},
	FIELD = {
		LABEL_H = 16,
		STATUS_H = 18,
		H = 22,
		BUTTON_H = 22,
	},
	LIST = {
		ROW_H = 58,
		MEMBER_ROW_H = 20,
		MSG_H = 84,
	},
	PANEL = {
		MSG_LIST_MIN = 100,
		GROUP_H = 176,
		COMPOSE_H = 68,
	},
	WIN = {
		MIN_W = 860,
		MIN_H = 620,
		DEF_W = 1000,
		DEF_H = 700,
	},
	SIDEBAR = {
		MIN = 220,
		RATIO = 0.34,
	},
}

local KnoxNetScrollingListBox = ISScrollingListBox:derive("KnoxNetScrollingListBox")
local KnoxNetUI = ISCollapsableWindow:derive("KnoxNetUI")

local function drawColor(PANEL, color, x, y, w, h)
	PANEL:drawRect(x, y, w, h, color.a, color.r, color.g, color.b)
end

local function text(PANEL, s, x, y, color, font)
	PANEL:drawText(tostring(s or ""), x, y, color.r, color.g, color.b, color.a or 1, font or UIFont.Small)
end

local function button(x, y, w, h, title, target, cb, variant)
	local b = ISButton:new(x, y, w, h, title, target, cb)
	b:initialise()
	b:instantiate()
	Theme.applyButtonStyle(b, variant)
	return b
end

local function label(title)
	local l = ISLabel:new(0, 0, C.FIELD.LABEL_H, title, T.textMuted.r, T.textMuted.g, T.textMuted.b, 1, UIFont.Small,
		true)
	l:initialise()
	return l
end

local function tooltip(control, textValue)
	if control and control.setTooltip then
		control:setTooltip(textValue)
	end
end

local function setEntryMaxLines(entry, maxLines)
	if not entry then
		return
	end
	maxLines = math.max(1, math.floor(tonumber(maxLines) or 1))
	if entry.setMaxLines then
		entry:setMaxLines(maxLines)
	end
	if entry.javaObject and entry.javaObject.setMaxLines then
		entry.javaObject:setMaxLines(maxLines)
	end
end

local function listContentWidth(LIST)
	if not LIST then
		return 0
	end
	if LIST.getScrollAreaWidth then
		return math.max(1, LIST:getScrollAreaWidth() - 2)
	end
	return math.max(1, LIST:getWidth() - 2)
end

local function resetListState(LIST)
	if not LIST then
		return
	end
	LIST:clear()
	LIST.selected = 0
	LIST:setYScroll(0)
	LIST:setScrollHeight(0)
	LIST.smoothScrollTargetY = nil
	LIST.smoothScrollY = nil
end

local function syncListScrollbar(LIST)
	if not LIST or not LIST.vscroll then
		return
	end
	LIST.vscroll:setX(LIST:getWidth() - 16)
	LIST.vscroll:setY(0)
	LIST.vscroll:setWidth(17)
	LIST.vscroll:setHeight(LIST:getHeight())
	LIST:updateScrollbars()
end

local function getListStencilBounds(list, y, height)
	local border = list.drawBorder and 1 or 0
	local clipX = border
	local clipY = math.max(border, y + list:getYScroll())
	local clipX2 = list:isVScrollBarVisible() and (list.vscroll.x + 3) or (list:getWidth() - border)
	local clipY2 = math.min(list:getHeight() - border, y + height + list:getYScroll())
	if clipX2 <= clipX or clipY2 <= clipY then
		return nil
	end
	return clipX, clipY, clipX2 - clipX, clipY2 - clipY
end

local function drawClippedListRow(list, y, height, drawFn)
	local clipX, clipY, clipW, clipH = getListStencilBounds(list, y, height)
	if not clipX then
		return
	end
	list:setStencilRect(clipX, clipY, clipW, clipH)
	drawFn()
	list:clearStencilRect()
	list:repaintStencilRect(clipX, clipY, clipW, clipH)
end

function KnoxNetScrollingListBox:prerender()
	self.doRepaintStencil = true
	if self.vscroll then
		self.vscroll.doSetStencil = true
		self.vscroll.doRepaintStencil = true
	end
	syncListScrollbar(self)
	ISScrollingListBox.prerender(self)
end

local function firstLocationAttachment(attachments)
	if type(attachments) ~= "table" then
		return nil
	end
	for i = 1, #attachments do
		local attachment = attachments[i]
		if type(attachment) == "table" and attachment.type == "location" then
			return attachment
		end
	end
	return nil
end

local function wrapTextLines(font, rawText, maxWidth)
	local textValue = tostring(rawText or "")
	local lines = {}
	local usableWidth = math.max(24, math.floor(tonumber(maxWidth) or 24))

	local function pushWrappedLine(source)
		source = tostring(source or "")
		if source == "" then
			lines[#lines + 1] = ""
			return
		end

		local current = ""
		for word in string.gmatch(source, "%S+") do
			local candidate = current == "" and word or (current .. " " .. word)
			if getTextManager():MeasureStringX(font, candidate) <= usableWidth then
				current = candidate
			else
				if current ~= "" then
					lines[#lines + 1] = current
					current = word
				else
					local piece = ""
					for i = 1, #word do
						local ch = word:sub(i, i)
						local nextPiece = piece .. ch
						if getTextManager():MeasureStringX(font, nextPiece) > usableWidth and piece ~= "" then
							lines[#lines + 1] = piece
							piece = ch
						else
							piece = nextPiece
						end
					end
					current = piece
				end
			end
		end
		if current ~= "" then
			lines[#lines + 1] = current
		end
	end

	local normalized = textValue:gsub("\r\n", "\n"):gsub("\r", "\n")
	local start = 1
	while true do
		local stop = string.find(normalized, "\n", start, true)
		if not stop then
			pushWrappedLine(normalized:sub(start))
			break
		end
		pushWrappedLine(normalized:sub(start, stop - 1))
		start = stop + 1
		if start > #normalized then
			lines[#lines + 1] = ""
			break
		end
	end

	if #lines == 0 then
		lines[1] = ""
	end
	return lines
end

local function drawPanelChrome(PANEL, x, y, w, h, title)
	if w <= 0 or h <= 0 then
		return
	end
	PANEL:drawRect(x, y, w, h, T.panelDark.a * 0.55, T.panelDark.r, T.panelDark.g, T.panelDark.b)
	PANEL:drawRectBorder(x, y, w, h, T.borderDim.a, T.borderDim.r, T.borderDim.g, T.borderDim.b)
	if title and title ~= "" then
		text(PANEL, title, x + 8, y + 5, T.textMuted, UIFont.Small)
	end
end

function KnoxNetUI:new(x, y, w, h)
	local o = ISCollapsableWindow.new(self, x, y, w, h)
	o.title = "KnoxNet"
	o.resizable = true
	o.moveWithMouse = true
	o.minimumWidth = C.WIN.MIN_W
	o.minimumHeight = C.WIN.MIN_H
	o.backgroundColor = Theme.copy(T.background)
	o.borderColor = Theme.copy(T.border)
	o.selectedConversationId = nil
	o.searchText = ""
	o.createMode = Shared.KIND.DM
	o.draftMembers = {}
	o.statusText = ""
	o.pendingOpenTitle = nil
	o.pendingAttachments = {}
	return o
end

function KnoxNetUI:resizeBottomInset()
	if self.resizable and self.resizeWidget and self.resizeWidget:getIsVisible() then
		return self:resizeWidgetHeight() + C.LAYOUT.PAD
	end
	return C.LAYOUT.PAD
end

function KnoxNetUI:initialise()
	ISCollapsableWindow.initialise(self)

	self.search = ISTextEntryBox:new("", C.LAYOUT.PAD, self:titleBarHeight() + C.LAYOUT.PAD, 100, C.FIELD.H)
	self.search:initialise()
	self.search:instantiate()
	Theme.applyFieldStyle(self.search)
	self.search.onTextChange = function(entry)
		self.searchText = entry:getInternalText() or ""
		self:rebuildChatList()
	end
	self:addChild(self.search)
	self.searchLabel = label("Search chats")
	self:addChild(self.searchLabel)
	tooltip(self.search, "Filter direct and group chats by title or last message.")

	self.dmModeBtn = button(0, 0, 64, C.FIELD.BUTTON_H, "DM", self, KnoxNetUI.onModeDm, "primary")
	self.groupModeBtn = button(0, 0, 74, C.FIELD.BUTTON_H, "Group", self, KnoxNetUI.onModeGroup)
	self:addChild(self.dmModeBtn)
	self:addChild(self.groupModeBtn)
	tooltip(self.dmModeBtn, "Create a direct player-to-player conversation.")
	tooltip(self.groupModeBtn, "Create a group conversation with multiple members.")

	self.playerCombo = ISComboBox:new(0, 0, 100, C.FIELD.H, self, nil)
	self.playerCombo:initialise()
	self.playerCombo:instantiate()
	Theme.applyComboStyle(self.playerCombo)
	self:addChild(self.playerCombo)
	self.playerLabel = label("Known / online player")
	self:addChild(self.playerLabel)
	tooltip(self.playerCombo, "Pick an online or previously known KnoxNet user.")

	self.manualUser = ISTextEntryBox:new("", 0, 0, 100, C.FIELD.H)
	self.manualUser:initialise()
	self.manualUser:instantiate()
	Theme.applyFieldStyle(self.manualUser)
	self:addChild(self.manualUser)
	self.manualLabel = label("Manual username")
	self:addChild(self.manualLabel)
	tooltip(self.manualUser, "Type a username manually. This wins over the combo box when filled.")

	self.groupTitle = ISTextEntryBox:new("", 0, 0, 100, C.FIELD.H)
	self.groupTitle:initialise()
	self.groupTitle:instantiate()
	Theme.applyFieldStyle(self.groupTitle)
	self:addChild(self.groupTitle)
	self.groupTitleLabel = label("Group name")
	self:addChild(self.groupTitleLabel)
	tooltip(self.groupTitle, "Name shown in every member's chat LIST.")

	self.refreshPlayersBtn = button(0, 0, 58, C.FIELD.BUTTON_H, "Refresh", self, KnoxNetUI.onRefreshPlayers)
	self.addDraftBtn = button(0, 0, 44, C.FIELD.BUTTON_H, "Add", self, KnoxNetUI.onAddDraftMember, "success")
	self.removeDraftBtn = button(0, 0, 64, C.FIELD.BUTTON_H, "Remove", self, KnoxNetUI.onRemoveDraftMember, "danger")
	self.createBtn = button(0, 0, 92, C.FIELD.BUTTON_H, "Start Chat", self, KnoxNetUI.onCreateConversation, "primary")
	self:addChild(self.refreshPlayersBtn)
	self:addChild(self.addDraftBtn)
	self:addChild(self.removeDraftBtn)
	self:addChild(self.createBtn)
	tooltip(self.refreshPlayersBtn, "Refresh online and known player choices.")
	tooltip(self.addDraftBtn, "Add the selected or manually typed player to the new group.")
	tooltip(self.removeDraftBtn, "Remove the selected player from the draft group member LIST.")
	tooltip(self.createBtn, "Start the direct chat or create the group.")

	self.draftList = KnoxNetScrollingListBox:new(0, 0, 100, 44)
	self.draftList:initialise()
	self.draftList:instantiate()
	self.draftList.itemheight = C.LIST.MEMBER_ROW_H
	self.draftList.font = UIFont.Small
	self.draftList.selected = 0
	self.draftList.drawBorder = true
	self.draftList.emptyMessage = "No members added yet."
	self.draftList.doDrawItem = KnoxNetUI.drawMemberRow
	self.draftList.target = self
	self.draftList.doRepaintStencil = true
	if self.draftList.vscroll then
		self.draftList.vscroll.doSetStencil = true
		self.draftList.vscroll.doRepaintStencil = true
	end
	Theme.applyListStyle(self.draftList)
	self.draftList.drawBorder = true
	self:addChild(self.draftList)
	self.draftLabel = label("Draft group members")
	self:addChild(self.draftLabel)
	tooltip(self.draftList, "Players who will be added when the group is created.")

	self.statusLabel = ISLabel:new(0, 0, 16, "", T.textDim.r, T.textDim.g, T.textDim.b, 1, UIFont.Small, true)
	self.statusLabel:initialise()
	self:addChild(self.statusLabel)

	self.chatList = KnoxNetScrollingListBox:new(C.LAYOUT.PAD, 0, 200, 100)
	self.chatList:initialise()
	self.chatList:instantiate()
	self.chatList.itemheight = C.LIST.ROW_H
	self.chatList.font = UIFont.Small
	self.chatList.selected = 0
	self.chatList.drawBorder = true
	self.chatList.emptyMessage = "No conversations yet."
	self.chatList.doDrawItem = KnoxNetUI.drawChatRow
	self.chatList:setOnMouseDownFunction(self, KnoxNetUI.onChatSelected)
	self.chatList.doRepaintStencil = true
	if self.chatList.vscroll then
		self.chatList.vscroll.doSetStencil = true
		self.chatList.vscroll.doRepaintStencil = true
	end
	Theme.applyListStyle(self.chatList)
	self.chatList.drawBorder = true
	self:addChild(self.chatList)
	self.chatListLabel = label("Chats")
	self:addChild(self.chatListLabel)
	tooltip(self.chatList, "Direct and group conversations. Unread counts appear at the right.")
	self.chatEmptyLabel = ISLabel:new(0, 0, 16, "No conversations yet.", T.textDim.r, T.textDim.g, T.textDim.b, 1,
		UIFont.Small, true)
	self.chatEmptyLabel:initialise()
	self:addChild(self.chatEmptyLabel)

	self.headerLabel = ISLabel:new(0, 0, 18, "Select a chat", T.text.r, T.text.g, T.text.b, 1, UIFont.Medium, true)
	self.headerLabel:initialise()
	self:addChild(self.headerLabel)

	self.leaveBtn = button(0, 0, 60, C.FIELD.BUTTON_H, "Leave", self, KnoxNetUI.onLeave, "danger")
	self:addChild(self.leaveBtn)

	self.memberList = KnoxNetScrollingListBox:new(0, 0, 120, 80)
	self.memberList:initialise()
	self.memberList:instantiate()
	self.memberList.itemheight = C.LIST.MEMBER_ROW_H
	self.memberList.font = UIFont.Small
	self.memberList.selected = 0
	self.memberList.drawBorder = true
	self.memberList.emptyMessage = "No members to show."
	self.memberList.doDrawItem = KnoxNetUI.drawMemberRow
	self.memberList.target = self
	self.memberList.doRepaintStencil = true
	if self.memberList.vscroll then
		self.memberList.vscroll.doSetStencil = true
		self.memberList.vscroll.doRepaintStencil = true
	end
	Theme.applyListStyle(self.memberList)
	self.memberList.drawBorder = true
	self:addChild(self.memberList)
	self.memberListLabel = label("Group members")
	self:addChild(self.memberListLabel)
	tooltip(self.memberList, "Members in the selected group. Owners and admins are marked.")
	self.memberEmptyLabel = ISLabel:new(0, 0, 16, "No members to show.", T.textDim.r, T.textDim.g, T.textDim.b, 1,
		UIFont.Small, true)
	self.memberEmptyLabel:initialise()
	self:addChild(self.memberEmptyLabel)

	self.actionCombo = ISComboBox:new(0, 0, 100, C.FIELD.H, self, nil)
	self.actionCombo:initialise()
	self.actionCombo:instantiate()
	self.actionCombo:addOptionWithData("Add", Shared.GROUP_ACTION.ADD_MEMBER)
	self.actionCombo:addOptionWithData("Remove", Shared.GROUP_ACTION.REMOVE_MEMBER)
	self.actionCombo:addOptionWithData("Promote", Shared.GROUP_ACTION.PROMOTE)
	self.actionCombo:addOptionWithData("Demote", Shared.GROUP_ACTION.DEMOTE)
	self.actionCombo:addOptionWithData("Mute", Shared.GROUP_ACTION.MUTE)
	self.actionCombo:addOptionWithData("Unmute", Shared.GROUP_ACTION.UNMUTE)
	self.actionCombo:addOptionWithData("Rename", Shared.GROUP_ACTION.RENAME)
	self.actionCombo:addOptionWithData("Disband", Shared.GROUP_ACTION.DISBAND)
	self.actionCombo.onChange = KnoxNetUI.onActionChanged
	self.actionCombo.target = self
	Theme.applyComboStyle(self.actionCombo)
	self:addChild(self.actionCombo)
	self.actionLabel = label("Group action")
	self:addChild(self.actionLabel)
	tooltip(self.actionCombo, "Choose what to do to the selected group/member.")

	self.manageUserCombo = ISComboBox:new(0, 0, 100, C.FIELD.H, self, nil)
	self.manageUserCombo:initialise()
	self.manageUserCombo:instantiate()
	Theme.applyComboStyle(self.manageUserCombo)
	self:addChild(self.manageUserCombo)
	self.manageUserLabel = label("Action target")
	self:addChild(self.manageUserLabel)
	tooltip(self.manageUserCombo, "User affected by remove/promote/demote/mute/unmute. Add can also use the value FIELD.")

	self.manageValue = ISTextEntryBox:new("", 0, 0, 100, C.FIELD.H)
	self.manageValue:initialise()
	self.manageValue:instantiate()
	Theme.applyFieldStyle(self.manageValue)
	self:addChild(self.manageValue)
	self.manageValueLabel = label("Value")
	self:addChild(self.manageValueLabel)
	tooltip(self.manageValue, "Rename text, mute minutes, or manual username for Add.")

	self.applyActionBtn = button(0, 0, 54, C.FIELD.BUTTON_H, "Apply", self, KnoxNetUI.onApplyGroupAction, "warning")
	self:addChild(self.applyActionBtn)
	tooltip(self.applyActionBtn, "Send this group action to the server for validation.")

	self.olderBtn = button(0, 0, 84, C.FIELD.BUTTON_H, "Older", self, KnoxNetUI.onOlder)
	self:addChild(self.olderBtn)
	tooltip(self.olderBtn, "Load an older page of messages for this conversation.")

	self.messageList = KnoxNetScrollingListBox:new(0, 0, 100, 100)
	self.messageList:initialise()
	self.messageList:instantiate()
	self.messageList.itemheight = C.LIST.MSG_H
	self.messageList.font = UIFont.Small
	self.messageList.selected = 0
	self.messageList.drawBorder = true
	self.messageList.emptyMessage = "Select a conversation to start messaging."
	self.messageList.doDrawItem = KnoxNetUI.drawMessageRow
	self.messageList:setOnMouseDownFunction(self, KnoxNetUI.onMessageSelected)
	self.messageList.doRepaintStencil = true
	if self.messageList.vscroll then
		self.messageList.vscroll.doSetStencil = true
		self.messageList.vscroll.doRepaintStencil = true
	end
	Theme.applyListStyle(self.messageList)
	self.messageList.drawBorder = true
	self:addChild(self.messageList)
	tooltip(self.messageList, "Message history for the selected conversation.")
	self.messageEmptyLabel = ISLabel:new(0, 0, 16, "Select a conversation to start messaging.", T.textDim.r, T.textDim.g,
		T.textDim.b, 1, UIFont.Small, true)
	self.messageEmptyLabel:initialise()
	self:addChild(self.messageEmptyLabel)

	self.compose = ISTextEntryBox:new("", 0, 0, 100, C.PANEL.COMPOSE_H)
	self.compose:initialise()
	self.compose:instantiate()
	self.compose:setMultipleLine(true)
	setEntryMaxLines(self.compose, 4)
	self.compose.onCommandEntered = function()
		self:onSend()
	end
	self.compose.onOtherKey = function(entry, key)
		if Keyboard and key == Keyboard.KEY_RETURN then
			self:onSend()
		end
	end
	Theme.applyFieldStyle(self.compose)
	self:addChild(self.compose)
	self.composeLabel = label("Message")
	self:addChild(self.composeLabel)
	tooltip(self.compose, "Write your message. The server enforces length, membership, mute, and rate-limit rules.")
	self.attachmentInfoLabel = ISLabel:new(0, 0, 16, "", T.info.r, T.info.g, T.info.b, 1, UIFont.Small, true)
	self.attachmentInfoLabel:initialise()
	self:addChild(self.attachmentInfoLabel)

	self.attachLocationBtn = button(0, 0, 112, C.FIELD.BUTTON_H, "Share Location", self, KnoxNetUI.onShareLocation)
	self:addChild(self.attachLocationBtn)
	tooltip(self.attachLocationBtn, "Attach your current coordinates to the next message.")

	self.sendBtn = button(0, 0, 72, C.FIELD.BUTTON_H, "Send", self, KnoxNetUI.onSend, "primary")
	self:addChild(self.sendBtn)
	tooltip(self.sendBtn, "Send the message to the selected conversation.")

	Client.uiRef = self
	self:refreshPlayerCombo()
	self:rebuildDraftList()
	Client.requestConversations()
	self:rebuildChatList()
	self:updateAttachmentControls()
	self:layoutChildren()
end

function KnoxNetUI:conversationById(id)
	for i = 1, #Client.conversations do
		if Client.conversations[i].id == id then
			return Client.conversations[i]
		end
	end
	return nil
end

function KnoxNetUI:currentConversation()
	return self:conversationById(self.selectedConversationId)
end

function KnoxNetUI:pendingLocationAttachment()
	return firstLocationAttachment(self.pendingAttachments)
end

function KnoxNetUI:updateAttachmentControls()
	if not self.attachLocationBtn then
		return
	end
	local location = self:pendingLocationAttachment()
	if location then
		self.attachLocationBtn:setTitle("Remove Location")
		Theme.applyButtonStyle(self.attachLocationBtn, "warning")
		if self.attachmentInfoLabel then
			self.attachmentInfoLabel.name = string.format(
				"Location attached: %s, %s, %s",
				tostring(location.x),
				tostring(location.y),
				tostring(location.z or 0)
			)
			self.attachmentInfoLabel:setVisible(true)
		end
	else
		self.attachLocationBtn:setTitle("Share Location")
		Theme.applyButtonStyle(self.attachLocationBtn)
		if self.attachmentInfoLabel then
			self.attachmentInfoLabel.name = ""
			self.attachmentInfoLabel:setVisible(false)
		end
	end
end

function KnoxNetUI:setStatus(message)
	self.statusText = tostring(message or "")
	if self.statusLabel then
		self.statusLabel.name = self.statusText
	end
end

function KnoxNetUI:selectedComboText(combo)
	if not combo or not combo.options or #combo.options == 0 then
		return nil
	end
	local option = combo.options[combo.selected or 1]
	return Shared.normalizeUsername(option)
end

function KnoxNetUI:manualUsername()
	return Shared.normalizeUsername(self.manualUser and self.manualUser:getText() or "")
end

function KnoxNetUI:getPickedUsername()
	return self:manualUsername() or self:selectedComboText(self.playerCombo)
end

function KnoxNetUI:refreshPlayerCombo()
	if not self.playerCombo then
		return
	end
	self.playerCombo:clear()
	local players = Client.getPlayerOptions()
	for i = 1, #players do
		self.playerCombo:addOption(players[i])
	end
	if #self.playerCombo.options == 0 then
		self.playerCombo:addOption("No known players")
	end
	self:refreshManageUserCombo()
end

function KnoxNetUI:refreshManageUserCombo()
	if not self.manageUserCombo then
		return
	end
	self.manageUserCombo:clear()
	local seen = {}
	local function add(username)
		username = Shared.normalizeUsername(username)
		if username and not seen[username] then
			seen[username] = true
			self.manageUserCombo:addOption(username)
		end
	end
	local conv = self:currentConversation()
	if conv and conv.kind == Shared.KIND.GROUP then
		for i = 1, #conv.members do
			add(conv.members[i])
		end
	end
	local players = Client.getPlayerOptions()
	for i = 1, #players do
		add(players[i])
	end
end

function KnoxNetUI:updateGroupActionFields()
	if not self.actionCombo or not self.manageValueLabel or not self.manageValue then
		return
	end
	local conv = self:currentConversation()
	local groupVisible = conv and conv.kind == Shared.KIND.GROUP
	local action = self.actionCombo:getOptionData(self.actionCombo.selected)
	local needsTarget = groupVisible
	local needsValue = false
	local valueLabel = "Value"

	if action == Shared.GROUP_ACTION.ADD_MEMBER then
		needsValue = true
		valueLabel = "New member username"
	elseif action == Shared.GROUP_ACTION.MUTE then
		needsValue = true
		valueLabel = "Mute minutes"
	elseif action == Shared.GROUP_ACTION.RENAME then
		needsTarget = false
		needsValue = true
		valueLabel = "New group name"
	elseif action == Shared.GROUP_ACTION.DISBAND then
		needsTarget = false
		needsValue = false
		valueLabel = "No value needed"
	else
		valueLabel = "No value needed"
	end

	groupVisible = groupVisible == true
	needsTarget = needsTarget == true
	needsValue = needsValue == true
	self.manageUserLabel.name = needsTarget and "Action target" or ""
	self.manageValueLabel.name = valueLabel
	self.manageUserLabel:setVisible(groupVisible and needsTarget)
	self.manageUserCombo:setVisible(groupVisible and needsTarget)
	self.manageValueLabel:setVisible(groupVisible and needsValue)
	self.manageValue:setVisible(groupVisible and needsValue)
end

function KnoxNetUI.onActionChanged(target, combo)
	if target and target.updateGroupActionFields then
		target:updateGroupActionFields()
	end
end

function KnoxNetUI:rebuildDraftList()
	if not self.draftList then
		return
	end
	resetListState(self.draftList)
	for i = 1, #self.draftMembers do
		self.draftList:addItem(self.draftMembers[i], { username = self.draftMembers[i] })
	end
end

function KnoxNetUI:rebuildMemberList()
	if not self.memberList then
		return
	end
	resetListState(self.memberList)
	local conv = self:currentConversation()
	if not conv then
		self.memberList.emptyMessage = "Select a group to view members."
		self:refreshManageUserCombo()
		return
	end
	self.memberList.emptyMessage = "No members to show."
	for i = 1, #conv.members do
		local username = conv.members[i]
		self.memberList:addItem(username, {
			username = username,
			isAdmin = Shared.contains(conv.admins, username),
			isOwner = conv.ownerUsername == username,
		})
	end
	self:refreshManageUserCombo()
end

function KnoxNetUI:conversationMatches(conv)
	local q = tostring(self.searchText or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then
		return true
	end
	local hay = tostring(conv.title or ""):lower()
	if conv.lastMessage then
		hay = hay .. " " .. tostring(conv.lastMessage.body or ""):lower()
	end
	return string.find(hay, q, 1, true) ~= nil
end

function KnoxNetUI:rebuildChatListOnly()
	resetListState(self.chatList)
	for i = 1, #Client.conversations do
		local conv = Client.conversations[i]
		if self:conversationMatches(conv) then
			self.chatList:addItem(conv.title or conv.id, conv)
		end
	end
end

function KnoxNetUI:syncChatListSelectionAfterRebuild()
	local conversations = Client.conversations

	if #conversations == 0 then
		self.selectedConversationId = nil
		self.chatList.selected = 0
		self.headerLabel.name = "No conversations"
		self:rebuildMessages(true)
		self:rebuildMemberList()
		self:layoutChildren()
		return
	end

	if #self.chatList.items == 0 then
		self.chatList.selected = 0
		self.selectedConversationId = nil
		self.headerLabel.name = "No matching chats"
		self:rebuildMessages(true)
		self:rebuildMemberList()
		self:layoutChildren()
		return
	end

	local id = self.selectedConversationId
	local idxVisible = nil
	if id then
		for i = 1, #self.chatList.items do
			local it = self.chatList.items[i].item
			if it and it.id == id then
				idxVisible = i
				break
			end
		end
	end

	if idxVisible then
		self.chatList.selected = idxVisible
		return
	end

	local first = self.chatList.items[1].item
	if first then
		self:selectConversation(first)
	end
end

function KnoxNetUI:rebuildChatList()
	self:rebuildChatListOnly()
	self:syncChatListSelectionAfterRebuild()
end

function KnoxNetUI:rebuildMessages(keepTop)
	resetListState(self.messageList)
	local chatId = self.selectedConversationId
	local messages = chatId and Client.messagesByChat[chatId] or {}
	if chatId then
		self.messageList.emptyMessage = "No messages yet. Say hello."
	else
		self.messageList.emptyMessage = "Select a conversation to start messaging."
	end
	for i = 1, #messages do
		self.messageList:addItem(messages[i].id or tostring(i), messages[i])
	end
	if not keepTop and self.messageList.items and #self.messageList.items > 0 then
		self.messageList:ensureVisible(#self.messageList.items)
	end
end

function KnoxNetUI:selectConversation(conv)
	if not conv then
		return
	end
	self.selectedConversationId = conv.id
	self.headerLabel.name = conv.title or "Conversation"
	for i = 1, #self.chatList.items do
		local it = self.chatList.items[i].item
		if it and it.id == conv.id then
			self.chatList.selected = i
			break
		end
	end
	self:rebuildMessages(true)
	Client.fetchMessages(conv.id, nil, Client.settings.historyPageSize)
	Client.markRead(conv.id)
	self:rebuildMemberList()
	self:layoutChildren()
end

function KnoxNetUI.onChatSelected(target, item)
	if target and target.selectConversation and item then
		target:selectConversation(item)
	end
end

function KnoxNetUI:drawChatRow(y, item, alt)
	local conv = item.item
	if not conv then
		return y + item.height
	end
	drawClippedListRow(self, y, item.height, function()
		local selected = self.target and self.target.selectedConversationId == conv.id
		local contentW = listContentWidth(self)
		if selected then
			drawColor(self, T.selected, 0, y, contentW, item.height)
		elseif alt then
			drawColor(self, T.listAlt, 0, y, contentW, item.height)
		end
		local pad = 8
		local titleW = contentW - pad * 2 - 34
		text(self, TextUtils.trimToWidth(UIFont.Small, conv.title or "Conversation", titleW), pad, y + 6, T.text,
			UIFont.Small)
		local preview = ""
		if conv.lastMessage then
			preview = tostring(conv.lastMessage.fromUsername or "") .. ": " .. tostring(conv.lastMessage.body or "")
		end
		text(self, TextUtils.trimToWidth(UIFont.Small, preview, contentW - pad * 2), pad, y + 25, T.textMuted,
			UIFont.Small)
		local ts = conv.lastMessage and Shared.formatUnixLocal(conv.lastMessage.createdAtTs) or ""
		text(self, TextUtils.trimToWidth(UIFont.Small, ts, contentW - pad * 2), pad, y + 41, T.textDim, UIFont.Small)
		local unread = tonumber(conv.unreadCount) or 0
		if unread > 0 then
			local label = unread > 99 and "99+" or tostring(unread)
			self:drawRect(contentW - 32, y + 8, 24, 18, T.danger.a, T.danger.r, T.danger.g, T.danger.b)
			self:drawTextCentre(label, contentW - 20, y + 10, 1, 1, 1, 1, UIFont.Small)
		end
		self:drawRect(0, y + item.height - 1, contentW, 1, T.borderDim.a, T.borderDim.r, T.borderDim.g, T.borderDim.b)
	end)
	return y + item.height
end

function KnoxNetUI:drawMemberRow(y, item, alt)
	local member = item.item or {}
	drawClippedListRow(self, y, item.height, function()
		local contentW = listContentWidth(self)
		if item.index == self.selected then
			drawColor(self, T.selected, 0, y, contentW, item.height)
		elseif alt then
			drawColor(self, T.listAlt, 0, y, contentW, item.height)
		end
		local suffix = ""
		if member.isOwner then
			suffix = "  owner"
		elseif member.isAdmin then
			suffix = "  admin"
		end
		local label = tostring(member.username or item.text or "") .. suffix
		text(self, TextUtils.trimToWidth(UIFont.Small, label, contentW - 12), 6, y + 3, T.textMuted, UIFont.Small)
	end)
	return y + item.height
end

function KnoxNetUI:drawMessageRow(y, item)
	local msg = item.item
	if not msg then
		return y + item.height
	end
	local mine = msg.fromUsername == Client.username
	local pad = 10
	local contentW = listContentWidth(self)
	local maxBubbleW = math.max(120, math.floor(contentW * 0.70))
	local bx = mine and (contentW - maxBubbleW - pad) or pad
	local bubbleColor = mine and T.primaryDark or T.panelAlt
	local name = mine and "You" or tostring(msg.fromDisplayName or msg.fromUsername or "")
	local when = Shared.formatUnixLocal(msg.createdAtTs)
	local location = firstLocationAttachment(msg.attachments)
	local body = tostring(msg.body or "")
	if body == "" and location then
		body = "Shared a location"
	end
	local innerW = maxBubbleW - 16
	local fontH = getTextManager():getFontHeight(UIFont.Small)
	local lineGap = 2
	local bodyLines = wrapTextLines(UIFont.Small, body, innerW)
	local locLines = location and wrapTextLines(
		UIFont.Small,
		string.format("Location: %s (%s, %s, %s)", tostring(location.label or "Shared pin"), tostring(location.x),
			tostring(location.y), tostring(location.z or 0)),
		innerW
	) or nil
	local bodyBlockH = (#bodyLines * fontH) + (math.max(0, #bodyLines - 1) * lineGap)
	local locBlockH = locLines and ((#locLines * fontH) + (math.max(0, #locLines - 1) * lineGap)) or 0
	local bubbleH = 12 + fontH + 8 + bodyBlockH + (locLines and (8 + locBlockH) or 0) + 8 + fontH + 8
	local rowH = bubbleH + 10
	drawClippedListRow(self, y, rowH, function()
		self:drawRect(bx, y + 5, maxBubbleW, bubbleH, bubbleColor.a, bubbleColor.r, bubbleColor.g, bubbleColor.b)
		self:drawRectBorder(bx, y + 5, maxBubbleW, bubbleH, T.borderDim.a, T.borderDim.r, T.borderDim.g, T.borderDim.b)
		text(self, TextUtils.trimToWidth(UIFont.Small, name, innerW), bx + 8, y + 9, T.textMuted, UIFont.Small)
		local cursorY = y + 9 + fontH + 8
		for i = 1, #bodyLines do
			text(self, bodyLines[i], bx + 8, cursorY, T.text, UIFont.Small)
			cursorY = cursorY + fontH + lineGap
		end
		if location then
			cursorY = cursorY + 6
			for i = 1, #locLines do
				text(self, locLines[i], bx + 8, cursorY, T.info or T.textMuted, UIFont.Small)
				cursorY = cursorY + fontH + lineGap
			end
		end
		text(self, TextUtils.trimToWidth(UIFont.Small, when, innerW), bx + 8, y + 5 + bubbleH - fontH - 8, T.textDim,
			UIFont.Small)
	end)
	return y + rowH
end

local function openWorldMapAt(x, y, z)
	local playerObj = getPlayer and getPlayer() or getSpecificPlayer(0)
	local playerNum = playerObj and playerObj:getPlayerNum() or 0
	if ISWorldMap and ISWorldMap.ToggleWorldMap then
		if not ISWorldMap_instance or not ISWorldMap_instance:isVisible() then
			ISWorldMap.ToggleWorldMap(playerNum)
		end
		if ISWorldMap_instance and ISWorldMap_instance.mapAPI then
			ISWorldMap_instance.mapAPI:centerOn(tonumber(x) or 0, tonumber(y) or 0)
			ISWorldMap_instance.mapAPI:setZoom(18.0)
			return true
		end
	end
	return false
end

function KnoxNetUI.onMessageSelected(target, item)
	local location = item and firstLocationAttachment(item.attachments)
	if location then
		if openWorldMapAt(location.x, location.y, location.z) then
			target:setStatus(string.format("Opened map at %s, %s, %s.", tostring(location.x), tostring(location.y),
				tostring(location.z or 0)))
		else
			target:setStatus("Could not open the world map here.")
		end
	end
end

function KnoxNetUI:onConversationsChanged()
	self:rebuildChatListOnly()
	if self.pendingOpenTitle then
		local want = tostring(self.pendingOpenTitle):lower()
		for i = 1, #Client.conversations do
			local conv = Client.conversations[i]
			if tostring(conv.title or ""):lower() == want then
				self.pendingOpenTitle = nil
				self:selectConversation(conv)
				break
			end
		end
	end
	self:syncChatListSelectionAfterRebuild()
	local conv = self:currentConversation()
	if conv then
		self.headerLabel.name = conv.title or "Conversation"
	end
	self:refreshPlayerCombo()
	self:rebuildMemberList()
end

function KnoxNetUI:onMessagesChanged(chatId, olderPage)
	if chatId == self.selectedConversationId then
		self:rebuildMessages(olderPage == true)
	end
	self:rebuildChatList()
end

function KnoxNetUI:onError(message)
	self:setStatus(message or "KnoxNet action failed.")
end

function KnoxNetUI:onSend()
	if not self.selectedConversationId then
		self:setStatus("Select a conversation first.")
		return
	end
	local body = self.compose:getText()
	local attachments = nil
	if self.pendingAttachments and #self.pendingAttachments > 0 then
		attachments = self.pendingAttachments
	end
	Client.sendMessage(self.selectedConversationId, body, attachments)
	self.compose:setText("")
	self.pendingAttachments = {}
	self:updateAttachmentControls()
	self:setStatus("")
end

function KnoxNetUI:onOlder()
	local chatId = self.selectedConversationId
	if not chatId then
		return
	end
	local messages = Client.messagesByChat[chatId] or {}
	local beforeTs = messages[1] and messages[1].createdAtTs or nil
	Client.fetchMessages(chatId, beforeTs, Client.settings.historyPageSize)
end

function KnoxNetUI:onModeDm()
	self.createMode = Shared.KIND.DM
	Theme.applyButtonStyle(self.dmModeBtn, "primary")
	Theme.applyButtonStyle(self.groupModeBtn)
	self.createBtn:setTitle("Start Chat")
	self:setStatus("")
	self:layoutChildren()
end

function KnoxNetUI:onModeGroup()
	self.createMode = Shared.KIND.GROUP
	Theme.applyButtonStyle(self.dmModeBtn)
	Theme.applyButtonStyle(self.groupModeBtn, "primary")
	self.createBtn:setTitle("Create Group")
	self:setStatus("")
	self:layoutChildren()
end

function KnoxNetUI:onRefreshPlayers()
	Client.bootstrap()
	self:refreshPlayerCombo()
	self:setStatus("Player LIST refreshed.")
end

function KnoxNetUI:onShareLocation()
	if self:pendingLocationAttachment() then
		self.pendingAttachments = {}
		self:updateAttachmentControls()
		self:setStatus("Location attachment removed.")
		return
	end
	local playerObj = getPlayer and getPlayer() or getSpecificPlayer(0)
	if not playerObj then
		self:setStatus("Current player position is unavailable.")
		return
	end
	self.pendingAttachments = {
		{
			type = "location",
			x = math.floor(playerObj:getX()),
			y = math.floor(playerObj:getY()),
			z = math.floor(playerObj:getZ()),
			label = "Shared location",
		},
	}
	self:updateAttachmentControls()
	self:setStatus(string.format("Location attached: %d, %d, %d.", math.floor(playerObj:getX()),
		math.floor(playerObj:getY()), math.floor(playerObj:getZ())))
end

function KnoxNetUI:onAddDraftMember()
	local username = self:getPickedUsername()
	if not username or username == "No known players" then
		self:setStatus("Pick or type a player name.")
		return
	end
	if Shared.addUnique(self.draftMembers, username) then
		self:rebuildDraftList()
		self:setStatus("Added " .. username .. ".")
	end
end

function KnoxNetUI:onRemoveDraftMember()
	local item = self.draftList and self.draftList.items and self.draftList.items[self.draftList.selected]
	local username = item and item.item and item.item.username
	if username and Shared.removeValue(self.draftMembers, username) then
		self:rebuildDraftList()
		self:setStatus("Removed " .. username .. ".")
	end
end

function KnoxNetUI:onCreateConversation()
	if self.createMode == Shared.KIND.DM then
		local username = self:getPickedUsername()
		if not username or username == "No known players" then
			self:setStatus("Pick or type a player name.")
			return
		end
		self.pendingOpenTitle = username
		Client.createDm(username)
		self:setStatus("Opening DM with " .. username .. ".")
		return
	end

	if #self.draftMembers == 0 then
		self:onAddDraftMember()
	end
	local title = self.groupTitle:getText()
	if not title or title:gsub("%s+", "") == "" then
		title = "Group Chat"
	end
	Client.createGroup(title, table.concat(self.draftMembers, ","))
	self.pendingOpenTitle = title
	self.draftMembers = {}
	self.groupTitle:setText("")
	self.manualUser:setText("")
	self:rebuildDraftList()
	self:setStatus("Creating group.")
end

function KnoxNetUI:onLeave()
	local conv = self:currentConversation()
	if conv and conv.kind == Shared.KIND.GROUP then
		Client.leaveGroup(conv.id)
		self.selectedConversationId = nil
		self:rebuildMessages()
	end
end

function KnoxNetUI:onApplyGroupAction()
	local conv = self:currentConversation()
	if not conv or conv.kind ~= Shared.KIND.GROUP then
		return
	end
	local action = self.actionCombo:getOptionData(self.actionCombo.selected)
	local selectedUser = self:selectedComboText(self.manageUserCombo)
	local value = tostring(self.manageValue:getText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if action == Shared.GROUP_ACTION.ADD_MEMBER then
		selectedUser = Shared.normalizeUsername(value) or selectedUser
	end
	if action == Shared.GROUP_ACTION.RENAME then
		Client.groupAction(conv.id, action, { title = value })
	elseif action == Shared.GROUP_ACTION.DISBAND then
		Client.groupAction(conv.id, action, {})
	elseif action == Shared.GROUP_ACTION.MUTE then
		Client.groupAction(conv.id, action, { username = selectedUser, minutes = tonumber(value) or 10 })
	else
		Client.groupAction(conv.id, action, { username = selectedUser })
	end
	self:setStatus("Group action sent.")
end

function KnoxNetUI:onResize()
	ISCollapsableWindow.onResize(self)
	self:layoutChildren()
end

function KnoxNetUI:prerender()
	ISCollapsableWindow.prerender(self)
	local r = self.layoutRects or {}
	drawPanelChrome(self, r.sidebarX or C.LAYOUT.PAD, r.createY or 0, r.sidebarW or 1, r.createH or 1)
	drawPanelChrome(self, r.sidebarX or C.LAYOUT.PAD, r.chatY or 0, r.sidebarW or 1, r.chatH or 1)
	drawPanelChrome(self, r.rightX or 0, r.headerY or 0, r.rightW or 1, r.headerH or 1)
	if r.groupVisible then
		drawPanelChrome(self, r.rightX or 0, r.groupY or 0, r.rightW or 1, r.groupH or 1)
	end
	drawPanelChrome(self, r.rightX or 0, r.messagesY or 0, r.rightW or 1, r.messagesH or 1)
	drawPanelChrome(self, r.rightX or 0, r.composeY or 0, r.rightW or 1, r.composeH or 1)
end

function KnoxNetUI:layoutChildren()
	local pad = C.LAYOUT.PAD
	local gapS, gapM, gapL = C.LAYOUT.GAP_SM, C.LAYOUT.GAP_MD, C.LAYOUT.GAP_LG
	local lh = C.FIELD.LABEL_H
	local top = self:titleBarHeight() + pad
	local bottomInset = self:resizeBottomInset()
	local innerBottom = self.height - bottomInset

	local sidebarW = math.max(C.SIDEBAR.MIN, math.floor(self.width * C.SIDEBAR.RATIO))
	sidebarW = math.min(sidebarW, self.width - 440)
	local rightX = sidebarW + gapL + pad
	local rightW = math.max(280, self.width - rightX - pad)

	local createPanelY = top
	local sy = top

	Layout.setBounds(self.searchLabel, pad, sy, sidebarW, lh)
	Layout.setBounds(self.search, pad, sy + lh, sidebarW, C.FIELD.H)
	sy = sy + lh + C.FIELD.H + gapM

	local halfW = math.floor((sidebarW - gapM) / 2)
	Layout.setBounds(self.dmModeBtn, pad, sy, halfW, C.FIELD.BUTTON_H)
	Layout.setBounds(self.groupModeBtn, pad + halfW + gapM, sy, halfW, C.FIELD.BUTTON_H)
	sy = sy + C.FIELD.BUTTON_H + gapM

	local refreshW = 58
	Layout.setBounds(self.playerLabel, pad, sy, sidebarW, lh)
	Layout.setBounds(self.playerCombo, pad, sy + lh, sidebarW - refreshW - gapM, C.FIELD.H)
	Layout.setBounds(self.refreshPlayersBtn, pad + sidebarW - refreshW, sy + lh, refreshW, C.FIELD.BUTTON_H)
	sy = sy + lh + C.FIELD.H + gapM

	Layout.setBounds(self.manualLabel, pad, sy, sidebarW, lh)
	Layout.setBounds(self.manualUser, pad, sy + lh, sidebarW, C.FIELD.H)
	sy = sy + lh + C.FIELD.H + gapM

	local groupMode = self.createMode == Shared.KIND.GROUP
	local OFF = -520

	if groupMode then
		Layout.setBounds(self.groupTitleLabel, pad, sy, sidebarW, lh)
		Layout.setBounds(self.groupTitle, pad, sy + lh, sidebarW, C.FIELD.H)
		sy = sy + lh + C.FIELD.H + gapM
		Layout.setBounds(self.draftLabel, pad, sy, sidebarW, lh)
		local draftBtnW = math.floor((sidebarW - gapM) / 2)
		Layout.setBounds(self.addDraftBtn, pad, sy + lh, draftBtnW, C.FIELD.BUTTON_H)
		Layout.setBounds(self.removeDraftBtn, pad + draftBtnW + gapM, sy + lh, sidebarW - draftBtnW - gapM,
			C.FIELD.BUTTON_H)
		local draftListH = C.FIELD.BUTTON_H * 3 + gapM
		Layout.setBounds(self.draftList, pad, sy + lh + C.FIELD.BUTTON_H + gapS, sidebarW, draftListH)
		syncListScrollbar(self.draftList)
		sy = sy + lh + C.FIELD.BUTTON_H + gapS + draftListH + gapM
		Layout.setBounds(self.createBtn, pad, sy, sidebarW, C.FIELD.BUTTON_H)
		sy = sy + C.FIELD.BUTTON_H + gapM
	else
		Layout.setBounds(self.groupTitleLabel, OFF, OFF, 120, lh)
		Layout.setBounds(self.groupTitle, OFF, OFF, 120, C.FIELD.H)
		Layout.setBounds(self.draftLabel, OFF, OFF, 120, lh)
		Layout.setBounds(self.addDraftBtn, OFF, OFF, 44, C.FIELD.BUTTON_H)
		Layout.setBounds(self.removeDraftBtn, OFF, OFF, 64, C.FIELD.BUTTON_H)
		Layout.setBounds(self.draftList, OFF, OFF, 120, 80)
		syncListScrollbar(self.draftList)
		Layout.setBounds(self.createBtn, pad, sy, sidebarW, C.FIELD.BUTTON_H)
		sy = sy + C.FIELD.BUTTON_H + gapM
	end
	self.groupTitleLabel:setVisible(groupMode)
	self.groupTitle:setVisible(groupMode)
	self.draftLabel:setVisible(groupMode)
	self.addDraftBtn:setVisible(groupMode)
	self.removeDraftBtn:setVisible(groupMode)
	self.draftList:setVisible(groupMode)

	local statusY = sy + gapS
	Layout.setBounds(self.statusLabel, pad, statusY, sidebarW, C.FIELD.STATUS_H)
	sy = statusY + C.FIELD.STATUS_H + C.LAYOUT.SECTION

	local chatsLabelY = sy
	Layout.setBounds(self.chatListLabel, pad, chatsLabelY, sidebarW, lh)
	local listY = chatsLabelY + lh + gapS
	local listH = math.max(C.PANEL.MSG_LIST_MIN, innerBottom - listY)
	Layout.setBounds(self.chatList, pad, listY, sidebarW, listH)
	syncListScrollbar(self.chatList)
	Layout.setBounds(self.chatEmptyLabel, pad + 12, listY + math.floor(listH / 2) - 8, sidebarW - 24, 18)
	self.chatEmptyLabel:setVisible(self.chatList.items and #self.chatList.items == 0)

	local composeY = innerBottom - C.PANEL.COMPOSE_H
	local composeLabelY = composeY - lh - C.LAYOUT.COMPOSE_LABEL_GAP
	local msgAreaBottom = composeLabelY - gapM

	local headerFontH = getTextManager():getFontHeight(UIFont.Medium)
	local headerTop = top + gapS
	local headerLabelH = math.max(headerFontH + 6, C.FIELD.BUTTON_H)
	Layout.setBounds(self.headerLabel, rightX, headerTop, rightW - 72, headerLabelH)
	Layout.setBounds(self.leaveBtn, rightX + rightW - 66, headerTop, 64, C.FIELD.BUTTON_H)
	local headerRowBottom = headerTop + math.max(headerLabelH, C.FIELD.BUTTON_H)
	local rightContentTop = headerRowBottom + gapM

	local conv = self:currentConversation()
	local groupVisible = conv and conv.kind == Shared.KIND.GROUP
	self.leaveBtn:setVisible(groupVisible == true)
	self.memberList:setVisible(groupVisible == true)
	self.actionCombo:setVisible(groupVisible == true)
	self.manageUserCombo:setVisible(groupVisible == true)
	self.manageValue:setVisible(groupVisible == true)
	self.applyActionBtn:setVisible(groupVisible == true)

	local groupPanelY = rightContentTop

	local memberW = math.max(168, math.floor(rightW * 0.36))
	Layout.setBounds(self.memberListLabel, rightX, groupPanelY, memberW, lh)
	Layout.setBounds(self.memberList, rightX, groupPanelY + lh, memberW, C.PANEL.GROUP_H - lh)
	syncListScrollbar(self.memberList)
	Layout.setBounds(self.memberEmptyLabel, rightX + 12, groupPanelY + lh + math.floor((C.PANEL.GROUP_H - lh) / 2) - 8,
		memberW - 24, 18)
	local actionX = rightX + memberW + gapM
	local actionW = rightW - memberW - gapM
	local topHalfW = math.max(100, math.floor((actionW - gapM) / 2))
	Layout.setBounds(self.actionLabel, actionX, groupPanelY, topHalfW, lh)
	Layout.setBounds(self.manageUserLabel, actionX + topHalfW + gapM, groupPanelY, actionW - topHalfW - gapM, lh)
	Layout.setBounds(self.actionCombo, actionX, groupPanelY + lh, topHalfW, C.FIELD.H)
	Layout.setBounds(self.manageUserCombo, actionX + topHalfW + gapM, groupPanelY + lh, actionW - topHalfW - gapM,
		C.FIELD.H)
	local valueY = groupPanelY + lh + C.FIELD.H + gapM
	Layout.setBounds(self.manageValueLabel, actionX, valueY, actionW, lh)
	Layout.setBounds(self.manageValue, actionX, valueY + lh, actionW, C.FIELD.H)
	Layout.setBounds(self.applyActionBtn, actionX, valueY + lh + C.FIELD.H + gapM, actionW, C.FIELD.BUTTON_H)

	self.memberListLabel:setVisible(groupVisible == true)
	self.memberEmptyLabel:setVisible(groupVisible == true and self.memberList.items and #self.memberList.items == 0)
	self.actionLabel:setVisible(groupVisible == true)
	self.manageUserLabel:setVisible(groupVisible == true)
	self.manageValueLabel:setVisible(groupVisible == true)
	self:updateGroupActionFields()

	local olderY = groupVisible and (groupPanelY + C.PANEL.GROUP_H + gapM) or rightContentTop
	Layout.setBounds(self.olderBtn, rightX, olderY, 88, C.FIELD.BUTTON_H)
	local msgY = olderY + C.FIELD.BUTTON_H + gapM
	local msgH = math.max(48, msgAreaBottom - msgY)
	Layout.setBounds(self.messageList, rightX, msgY, rightW, msgH)
	syncListScrollbar(self.messageList)
	Layout.setBounds(self.messageEmptyLabel, rightX + 12, msgY + math.floor(msgH / 2) - 8, rightW - 24, 18)
	self.messageEmptyLabel:setVisible(self.messageList.items and #self.messageList.items == 0)

	Layout.setBounds(self.composeLabel, rightX, composeLabelY, 80, lh)
	Layout.setBounds(self.attachmentInfoLabel, rightX + 86, composeLabelY, math.max(1, rightW - 86), lh)
	local actionBtnW = 112
	local sendW = 76
	local composeW = rightW - actionBtnW - sendW - (gapM * 2)
	Layout.setBounds(self.compose, rightX, composeY, composeW, C.PANEL.COMPOSE_H)
	Layout.setBounds(self.attachLocationBtn, rightX + composeW + gapM, composeY + C.PANEL.COMPOSE_H - C.FIELD.BUTTON_H,
		actionBtnW, C.FIELD.BUTTON_H)
	Layout.setBounds(self.sendBtn, rightX + rightW - sendW, composeY + C.PANEL.COMPOSE_H - C.FIELD.BUTTON_H, sendW,
		C.FIELD.BUTTON_H)

	local composeChromeH = C.PANEL.COMPOSE_H + lh + C.LAYOUT.COMPOSE_LABEL_GAP + gapS
	self.layoutRects = {
		sidebarX = pad - 4,
		sidebarW = sidebarW + 8,
		createY = createPanelY - 4,
		createH = math.max(1, chatsLabelY - gapS - createPanelY),
		chatY = chatsLabelY - 4,
		chatH = self.chatList:getHeight() + lh + gapS + 8,
		rightX = rightX - 4,
		rightW = rightW + 8,
		headerY = top - 4,
		headerH = (headerRowBottom - top) + 8,
		groupY = groupPanelY - 4,
		groupH = groupVisible and (C.PANEL.GROUP_H + 8) or 0,
		groupVisible = groupVisible == true,
		messagesY = msgY - 4,
		messagesH = self.messageList:getHeight() + 8,
		composeY = composeLabelY - gapS - 4,
		composeH = composeChromeH + 8,
	}
end

function KnoxNetUI:close()
	ISCollapsableWindow.close(self)
	Client.uiRef = nil
end

function KnoxNetUI.open()
	if Client.uiRef then
		Client.uiRef:setVisible(true)
		Client.uiRef:bringToTop()
		Client.requestConversations()
		return
	end
	local x, y, w, h = Layout.defaultWindowGeometry(C.WIN.DEF_W, C.WIN.DEF_H, C.WIN.MIN_W, C.WIN.MIN_H, 24)
	local ui = KnoxNetUI:new(x, y, w, h)
	ui:initialise()
	ui:addToUIManager()
end

local MENU_DOCK_BUTTON_ID = "knoxnet"

local function menuDockEntry()
	return {
		id = MENU_DOCK_BUTTON_ID,
		title = "KnoxNet",
		icon = "media/ui/ui_icon_knoxnet.png",
		allowSinglePlayer = true,
		onClick = function()
			KnoxNetUI.open()
		end,
		badge = {
			text = function() return tostring(Client.totalUnread or 0) end,
			maxBeforePlus = 99,
			texture = "media/ui/ui_knoxnet_red_badge.png",
		},
	}
end

function KnoxNetUI.syncMenuDockButton()
	if Shared.getSettings().hideMenuDockButton == true then
		MenuDock.unregisterButton(MENU_DOCK_BUTTON_ID)
		return
	end
	MenuDock.registerButton(menuDockEntry())
end

KnoxNetUI.syncMenuDockButton()
Events.OnGameStart.Add(KnoxNetUI.syncMenuDockButton)


return KnoxNetUI
