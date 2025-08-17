local Constants = require("KnoxNet_GamesModule/core/Constants")
local TerminalSounds = require("KnoxNet/core/TerminalSounds")

local KnoxNet_Terminal = require("KnoxNet/core/Terminal")

local rand = newrandom()

local DoomGame = {}

local GAME_INFO = {
	id = "doom",
	name = "Doom",
	description = "First-person shooter. Fight demons, find the exit.",
}

local DOOM_CONST = {
	MAP_WIDTH = 16,
	MAP_HEIGHT = 16,

	MOVE_SPEED = 0.05,
	ROTATION_SPEED = 0.03,

	FOV = math.pi / 3,
	NUM_RAYS = 120,

	WEAPONS = {
		PISTOL = { damage = 20, ammo_type = "bullets", rate = 500 },
		SHOTGUN = { damage = 50, ammo_type = "shells", rate = 800 },
	},

	ENEMIES = {
		IMP = { health = 50, damage = 10, speed = 0.03, score = 100 },
		DEMON = { health = 100, damage = 20, speed = 0.02, score = 200 },
	},

	GAME_TICK = 16,
	ENEMY_ATTACK_RANGE = 1.5,

	COLORS = {
		WALL = { r = 0.6, g = 0, b = 0, a = 1 }, -- red
		FLOOR = { r = 0.3, g = 0.3, b = 0.3, a = 1 }, -- dark gray
		CEILING = { r = 0.1, g = 0.1, b = 0.1, a = 1 }, -- darker gray
		ENEMY = { r = 0.8, g = 0.2, b = 0.2, a = 1 }, -- bright red
		WEAPON = { r = 0.7, g = 0.7, b = 0.7, a = 1 }, -- gray
		TEXT = { r = 1, g = 0, b = 0, a = 1 }, -- red
		HUD = { r = 1, g = 1, b = 0, a = 1 }, -- yellow
	},

	-- (1 = wall, 0 = empty space, 2 = enemy spawn)
	MAP = {
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
		{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1 },
		{ 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 1, 0, 0, 1, 0, 2, 1, 0, 0, 1, 0, 0, 1 },
		{ 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1 },
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
	},
}

DoomGame.gameState = {
	player = {
		x = 2.5,
		y = 2.5,
		angle = 0,
		health = 100,
		ammo = {
			bullets = 50,
			shells = 10,
		},
		currentWeapon = "PISTOL",
	},

	enemies = {},
	projectiles = {},

	textures = {},

	isGameOver = false,
	level = 1,
	score = 0,

	stripWidth = 0,
	halfHeight = 0,

	lastUpdateTime = 0,
	lastShootTime = 0,
	animationFrame = 0,
	lastAnimationTime = 0,
	weaponBob = 0,
	weaponBobDir = 1,

	displayWidth = 0,
	displayHeight = 0,
	displayX = 0,
	displayY = 0,
}

function DoomGame:resetState()
	self.gameState = {
		player = {
			x = 2.5,
			y = 2.5,
			angle = 0,
			health = 100,
			ammo = {
				bullets = 50,
				shells = 10,
			},
			currentWeapon = "PISTOL",
		},

		enemies = {},
		projectiles = {},

		textures = {},

		isGameOver = false,
		level = 1,
		score = 0,

		stripWidth = 0,
		halfHeight = 0,

		lastUpdateTime = 0,
		lastShootTime = 0,
		animationFrame = 0,
		lastAnimationTime = 0,
		weaponBob = 0,
		weaponBobDir = 1,

		displayWidth = 0,
		displayHeight = 0,
		displayX = 0,
		displayY = 0,
	}
end

function DoomGame:preview(x, y, width, height, terminal, gamesModule)
	local previewOffsetX = x + 5
	local previewOffsetY = y + 5
	local previewWidth = width - 10
	local previewHeight = height - 10

	terminal:drawRect(previewOffsetX, previewOffsetY, previewWidth, previewHeight, 0.7, 0.1, 0, 0)

	local titleText = "DOOM"
	local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, titleText)
	terminal:drawText(
		titleText,
		previewOffsetX + (previewWidth - textWidth) / 2,
		previewOffsetY + 5,
		1,
		1,
		0,
		0,
		Constants.UI_CONST.FONT.MEDIUM
	)

	local gunY = previewOffsetY + previewHeight - 20
	terminal:drawRect(previewOffsetX + previewWidth / 2 - 10, gunY, 20, 15, 1, 0.7, 0.7, 0.7)
	terminal:drawRect(previewOffsetX + previewWidth / 2 - 5, gunY - 10, 10, 10, 1, 0.7, 0.7, 0.7)

	local faceSize = 15
	local faceX = previewOffsetX + previewWidth / 3
	local faceY = previewOffsetY + previewHeight / 2
	terminal:drawRect(faceX, faceY, faceSize, faceSize, 1, 0.8, 0.2, 0.2)

	terminal:drawRect(previewOffsetX + previewWidth * 2 / 3, faceY + 10, faceSize, faceSize, 1, 0.8, 0.2, 0.2)

	terminal:drawRect(previewOffsetX + previewWidth / 2, previewOffsetY + previewHeight / 2 + 5, 5, 2, 1, 1, 1, 0)
end

function DoomGame:onDeactivate() end

function DoomGame:activate(gamesModule)
	self.gamesModule = gamesModule
	self.terminal = gamesModule.terminal

	self:resetState()

	self.gameState.displayWidth = self.terminal.displayWidth
	self.gameState.displayHeight = self.terminal.contentAreaHeight
	self.gameState.displayX = self.terminal.displayX
	self.gameState.displayY = self.terminal.contentAreaY

	self.gameState.stripWidth = math.max(1, math.floor(self.gameState.displayWidth / DOOM_CONST.NUM_RAYS))
	self.gameState.halfHeight = math.floor(self.gameState.displayHeight / 2)

	self.gameState.showMinimap = true
	self.gameState.minimapSize = "medium"

	local startX, startY = 2.5, 2.5

	if self:checkCollision(startX, startY) then
		for y = 1, DOOM_CONST.MAP_HEIGHT do
			for x = 1, DOOM_CONST.MAP_WIDTH do
				if DOOM_CONST.MAP[y][x] == 0 then
					startX = x + 0.5
					startY = y + 0.5
					break
				end
			end
			if not self:checkCollision(startX, startY) then
				break
			end
		end
	end

	self.gameState.player = {
		x = startX,
		y = startY,
		angle = 0,
		health = 100,
		ammo = {
			bullets = 50,
			shells = 10,
		},
		currentWeapon = "PISTOL",
	}

	self.gameState.enemies = {}
	for y = 1, DOOM_CONST.MAP_HEIGHT do
		for x = 1, DOOM_CONST.MAP_WIDTH do
			if DOOM_CONST.MAP[y][x] == 2 then
				local enemyType = "IMP"
				if rand:random(1, 3) == 1 then
					enemyType = "DEMON"
				end

				table.insert(self.gameState.enemies, {
					x = x + 0.5,
					y = y + 0.5,
					type = enemyType,
					health = DOOM_CONST.ENEMIES[enemyType].health,
					lastMoveTime = 0,
					state = "idle",
					wanderAngle = rand:random() * math.pi * 2,
				})
			end
		end
	end

	self.gameState.projectiles = {}
	self.gameState.isGameOver = false
	self.gameState.level = 1
	self.gameState.score = 0
	self.gameState.lastUpdateTime = getTimeInMillis()
	self.gameState.lastShootTime = 0
	self.gameState.animationFrame = 0
	self.gameState.lastAnimationTime = getTimeInMillis()
	self.gameState.weaponBob = 0
	self.gameState.weaponBobDir = 1

	TerminalSounds.playUISound("sfx_knoxnet_key_1")
end

function DoomGame:castRay(angle)
	local rayX = math.cos(angle)
	local rayY = math.sin(angle)

	if math.abs(rayX) < 0.00001 then
		rayX = 0.00001
	end
	if math.abs(rayY) < 0.00001 then
		rayY = 0.00001
	end

	local playerMapX = math.floor(self.gameState.player.x)
	local playerMapY = math.floor(self.gameState.player.y)

	-- dDA (Digital Differential Analysis) algorithm for faster ray casting
	local deltaDistX = math.abs(1 / rayX)
	local deltaDistY = math.abs(1 / rayY)

	local stepX, stepY
	local sideDistX, sideDistY

	if rayX < 0 then
		stepX = -1
		sideDistX = (self.gameState.player.x - playerMapX) * deltaDistX
	else
		stepX = 1
		sideDistX = (playerMapX + 1 - self.gameState.player.x) * deltaDistX
	end

	if rayY < 0 then
		stepY = -1
		sideDistY = (self.gameState.player.y - playerMapY) * deltaDistY
	else
		stepY = 1
		sideDistY = (playerMapY + 1 - self.gameState.player.y) * deltaDistY
	end

	local hit = false
	local side = 0
	local mapX = playerMapX
	local mapY = playerMapY

	local maxIterations = DOOM_CONST.MAP_WIDTH + DOOM_CONST.MAP_HEIGHT
	local iterations = 0

	while not hit and iterations < maxIterations do
		iterations = iterations + 1

		if sideDistX < sideDistY then
			sideDistX = sideDistX + deltaDistX
			mapX = mapX + stepX
			side = 0
		else
			sideDistY = sideDistY + deltaDistY
			mapY = mapY + stepY
			side = 1
		end

		if mapY >= 1 and mapY <= DOOM_CONST.MAP_HEIGHT and mapX >= 1 and mapX <= DOOM_CONST.MAP_WIDTH then
			if DOOM_CONST.MAP[mapY][mapX] == 1 then
				hit = true
			end
		else
			hit = true
			side = -1
		end
	end

	local distance
	if side == 0 then
		distance = (mapX - self.gameState.player.x + (1 - stepX) / 2) / rayX
	elseif side == 1 then
		distance = (mapY - self.gameState.player.y + (1 - stepY) / 2) / rayY
	else
		distance = 20
	end

	distance = math.max(0.1, math.min(distance, 20))

	return distance, hit, side
end

function DoomGame:calculateDistance(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

function DoomGame:update()
	local currentTime = getTimeInMillis()
	local deltaTime = (currentTime - self.gameState.lastUpdateTime) / 1000

	deltaTime = math.min(deltaTime, 0.1)

	self.gameState.weaponBob = self.gameState.weaponBob + deltaTime * 2 * self.gameState.weaponBobDir
	if self.gameState.weaponBob > 1 then
		self.gameState.weaponBob = 1
		self.gameState.weaponBobDir = -1
	elseif self.gameState.weaponBob < 0 then
		self.gameState.weaponBob = 0
		self.gameState.weaponBobDir = 1
	end

	if currentTime - self.gameState.lastAnimationTime > 200 then
		self.gameState.animationFrame = (self.gameState.animationFrame + 1) % 2
		self.gameState.lastAnimationTime = currentTime
	end

	if self.gameState.isGameOver then
		return
	end

	self:updateEnemies(deltaTime, currentTime)

	self:updateProjectiles(deltaTime)

	if #self.gameState.enemies == 0 then
		self.gameState.level = self.gameState.level + 1
		self.gameState.isGameOver = true
		TerminalSounds.playUISound("sfx_knoxnet_key_1")
	end

	self.gameState.lastUpdateTime = currentTime
end

function DoomGame:updateProjectiles(deltaTime)
	local i = 1
	while i <= #self.gameState.projectiles do
		local projectile = self.gameState.projectiles[i]

		local moveSpeed = 5 * deltaTime
		projectile.x = projectile.x + projectile.dirX * moveSpeed
		projectile.y = projectile.y + projectile.dirY * moveSpeed
		projectile.distance = projectile.distance + moveSpeed

		local removeProjectile = false

		if projectile.distance > 20 then
			removeProjectile = true
		else
			local mapX = math.floor(projectile.x)
			local mapY = math.floor(projectile.y)

			if mapX >= 1 and mapX <= DOOM_CONST.MAP_WIDTH and mapY >= 1 and mapY <= DOOM_CONST.MAP_HEIGHT then
				if DOOM_CONST.MAP[mapY][mapX] == 1 then
					removeProjectile = true
				end
			else
				removeProjectile = true
			end

			if not removeProjectile then
				local j = 1
				while j <= #self.gameState.enemies do
					local enemy = self.gameState.enemies[j]
					local dist = self:calculateDistance(enemy.x, enemy.y, projectile.x, projectile.y)

					if dist < 0.5 then
						enemy.health = enemy.health - projectile.damage
						enemy.state = "hurt"
						enemy.lastMoveTime = getTimeInMillis()

						if enemy.health <= 0 then
							self.gameState.score = self.gameState.score + DOOM_CONST.ENEMIES[enemy.type].score
							table.remove(self.gameState.enemies, j)

							TerminalSounds.playUISound("sfx_knoxnet_key_2")
						else
							j = j + 1
						end

						removeProjectile = true
						break
					else
						j = j + 1
					end
				end
			end
		end

		if removeProjectile then
			table.remove(self.gameState.projectiles, i)
		else
			i = i + 1
		end
	end
end

function DoomGame:updateEnemies(deltaTime, currentTime)
	local i = 1
	while i <= #self.gameState.enemies do
		local enemy = self.gameState.enemies[i]

		local dx = self.gameState.player.x - enemy.x
		local dy = self.gameState.player.y - enemy.y
		local dist = self:calculateDistance(enemy.x, enemy.y, self.gameState.player.x, self.gameState.player.y)

		if dist < DOOM_CONST.ENEMY_ATTACK_RANGE then
			if currentTime - enemy.lastMoveTime > 1000 then
				enemy.state = "attacking"
				self.gameState.player.health = self.gameState.player.health - DOOM_CONST.ENEMIES[enemy.type].damage

				TerminalSounds.playUISound("sfx_knoxnet_key_4")

				enemy.lastMoveTime = currentTime

				if self.gameState.player.health <= 0 then
					self.gameState.isGameOver = true
					self.gameState.player.health = 0
					TerminalSounds.playUISound("sfx_knoxnet_key_3")
				end
			end
			i = i + 1
		else
			if dist < 8 then
				local canSeePlayer =
					self:checkLineOfSight(enemy.x, enemy.y, self.gameState.player.x, self.gameState.player.y)

				if canSeePlayer then
					local moveSpeed = DOOM_CONST.ENEMIES[enemy.type].speed * deltaTime
					local moveX = dx / dist * moveSpeed
					local moveY = dy / dist * moveSpeed

					if not self:checkCollision(enemy.x + moveX, enemy.y) then
						enemy.x = enemy.x + moveX
					end

					if not self:checkCollision(enemy.x, enemy.y + moveY) then
						enemy.y = enemy.y + moveY
					end

					enemy.state = "idle"
				else
					if currentTime - enemy.lastMoveTime > 2000 then
						enemy.wanderAngle = rand:random() * math.pi * 2
						enemy.lastMoveTime = currentTime
					end

					if enemy.wanderAngle then
						local moveSpeed = DOOM_CONST.ENEMIES[enemy.type].speed * deltaTime * 0.5
						local moveX = math.cos(enemy.wanderAngle) * moveSpeed
						local moveY = math.sin(enemy.wanderAngle) * moveSpeed

						if not self:checkCollision(enemy.x + moveX, enemy.y) then
							enemy.x = enemy.x + moveX
						else
							enemy.wanderAngle = math.pi - enemy.wanderAngle
						end

						if not self:checkCollision(enemy.x, enemy.y + moveY) then
							enemy.y = enemy.y + moveY
						else
							enemy.wanderAngle = -enemy.wanderAngle
						end
					end
				end
			end

			i = i + 1
		end
	end
end

function DoomGame:checkCollision(x, y)
	local mapX = math.floor(x)
	local mapY = math.floor(y)

	if mapY >= 1 and mapY <= DOOM_CONST.MAP_HEIGHT and mapX >= 1 and mapX <= DOOM_CONST.MAP_WIDTH then
		return DOOM_CONST.MAP[mapY][mapX] == 1
	end

	return true
end

function DoomGame:checkLineOfSight(startX, startY, endX, endY)
	local dx = endX - startX
	local dy = endY - startY
	local distance = math.sqrt(dx * dx + dy * dy)

	dx = dx / distance
	dy = dy / distance

	local step = 0.1
	local current = 0

	while current < distance do
		local checkX = startX + dx * current
		local checkY = startY + dy * current

		local mapX = math.floor(checkX)
		local mapY = math.floor(checkY)

		if mapY >= 1 and mapY <= DOOM_CONST.MAP_HEIGHT and mapX >= 1 and mapX <= DOOM_CONST.MAP_WIDTH then
			if DOOM_CONST.MAP[mapY][mapX] == 1 then
				return false
			end
		end

		current = current + step
	end

	return true
end

function DoomGame:onKeyPress(key)
	if self.gameState.isGameOver then
		if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_BACK then
			self:onActivate()
			return true
		end
		return false
	end

	local moveSpeed = DOOM_CONST.MOVE_SPEED
	local rotateSpeed = DOOM_CONST.ROTATION_SPEED

	if key == Keyboard.KEY_UP then
		local newX = self.gameState.player.x + math.cos(self.gameState.player.angle) * moveSpeed
		local newY = self.gameState.player.y + math.sin(self.gameState.player.angle) * moveSpeed

		if not self:checkCollision(newX, newY) then
			self.gameState.player.x = newX
			self.gameState.player.y = newY
		end
		return true
	elseif key == Keyboard.KEY_DOWN then
		local newX = self.gameState.player.x - math.cos(self.gameState.player.angle) * moveSpeed
		local newY = self.gameState.player.y - math.sin(self.gameState.player.angle) * moveSpeed

		if not self:checkCollision(newX, newY) then
			self.gameState.player.x = newX
			self.gameState.player.y = newY
		end
		return true
	elseif key == Keyboard.KEY_LEFT then
		self.gameState.player.angle = self.gameState.player.angle - rotateSpeed
		return true
	elseif key == Keyboard.KEY_RIGHT then
		self.gameState.player.angle = self.gameState.player.angle + rotateSpeed
		return true
	elseif key == Keyboard.KEY_SPACE then
		local currentTime = getTimeInMillis()
		local weapon = DOOM_CONST.WEAPONS[self.gameState.player.currentWeapon]

		if currentTime - self.gameState.lastShootTime > weapon.rate then
			if self.gameState.player.ammo[weapon.ammo_type] > 0 then
				self.gameState.player.ammo[weapon.ammo_type] = self.gameState.player.ammo[weapon.ammo_type] - 1

				if self.gameState.player.currentWeapon == "SHOTGUN" then
					for i = 1, 5 do
						local spread = (rand:random() - 0.5) * 0.2
						local dirX = math.cos(self.gameState.player.angle + spread)
						local dirY = math.sin(self.gameState.player.angle + spread)

						table.insert(self.gameState.projectiles, {
							x = self.gameState.player.x,
							y = self.gameState.player.y,
							dirX = dirX,
							dirY = dirY,
							damage = weapon.damage / 5,
							distance = 0,
						})
					end
				else
					table.insert(self.gameState.projectiles, {
						x = self.gameState.player.x,
						y = self.gameState.player.y,
						dirX = math.cos(self.gameState.player.angle),
						dirY = math.sin(self.gameState.player.angle),
						damage = weapon.damage,
						distance = 0,
					})
				end

				self.gameState.lastShootTime = currentTime
				TerminalSounds.playUISound("sfx_knoxnet_key_1")
			else
				TerminalSounds.playUISound("sfx_knoxnet_key_4")
			end
		end
		return true
	elseif key == Keyboard.KEY_BACK then
		self:onActivate()
		return true
	elseif key == Keyboard.KEY_1 then
		self.gameState.player.currentWeapon = "PISTOL"
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_2 then
		self.gameState.player.currentWeapon = "SHOTGUN"
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	elseif key == Keyboard.KEY_M then
		self.gameState.showMinimap = not self.gameState.showMinimap
		TerminalSounds.playUISound("sfx_knoxnet_key_3")
		return true
	elseif key == Keyboard.KEY_N then
		if not self.gameState.minimapSize then
			self.gameState.minimapSize = "medium"
		elseif self.gameState.minimapSize == "small" then
			self.gameState.minimapSize = "medium"
		elseif self.gameState.minimapSize == "medium" then
			self.gameState.minimapSize = "large"
		else
			self.gameState.minimapSize = "small"
		end
		TerminalSounds.playUISound("sfx_knoxnet_key_2")
		return true
	end

	return false
end

function DoomGame:render()
	self.terminal:renderTitle("DOOM - HEALTH: " .. self.gameState.player.health .. " | SCORE: " .. self.gameState.score)

	self.terminal:drawRect(
		self.gameState.displayX,
		self.gameState.displayY,
		self.gameState.displayWidth,
		self.gameState.halfHeight,
		DOOM_CONST.COLORS.CEILING.a,
		DOOM_CONST.COLORS.CEILING.r,
		DOOM_CONST.COLORS.CEILING.g,
		DOOM_CONST.COLORS.CEILING.b
	)

	self.terminal:drawRect(
		self.gameState.displayX,
		self.gameState.displayY + self.gameState.halfHeight,
		self.gameState.displayWidth,
		self.gameState.halfHeight,
		DOOM_CONST.COLORS.FLOOR.a,
		DOOM_CONST.COLORS.FLOOR.r,
		DOOM_CONST.COLORS.FLOOR.g,
		DOOM_CONST.COLORS.FLOOR.b
	)

	local depthBuffer = {}
	for i = 0, DOOM_CONST.NUM_RAYS - 1 do
		depthBuffer[i] = 20.0
	end

	local numRays = math.ceil(self.gameState.displayWidth / self.gameState.stripWidth)

	for i = 0, numRays do
		local rayRatio = i / numRays
		local rayAngle = self.gameState.player.angle - (DOOM_CONST.FOV / 2) + (DOOM_CONST.FOV * rayRatio)

		local distance, hitWall, side = self:castRay(rayAngle)

		if i < DOOM_CONST.NUM_RAYS then
			depthBuffer[i] = distance
		end

		local correctedDistance = distance * math.cos(rayAngle - self.gameState.player.angle)

		local wallHeight =
			math.min(self.gameState.displayHeight, math.floor(self.gameState.displayHeight / correctedDistance))

		local wallTop = self.gameState.displayY + (self.gameState.displayHeight - wallHeight) / 2

		local brightness = math.max(0.2, 1.0 - correctedDistance / 10)

		local wallColor = DOOM_CONST.COLORS.WALL

		if side == 1 then
			wallColor = {
				r = DOOM_CONST.COLORS.WALL.r * 0.8,
				g = DOOM_CONST.COLORS.WALL.g * 0.8,
				b = DOOM_CONST.COLORS.WALL.b * 0.8,
				a = DOOM_CONST.COLORS.WALL.a,
			}
		end

		local stripX = self.gameState.displayX + i * self.gameState.stripWidth

		if stripX < self.gameState.displayX + self.gameState.displayWidth then
			local actualStripWidth = self.gameState.stripWidth
			if stripX + actualStripWidth > self.gameState.displayX + self.gameState.displayWidth then
				actualStripWidth = (self.gameState.displayX + self.gameState.displayWidth) - stripX
			end

			if actualStripWidth > 0 then
				self.terminal:drawRect(
					stripX,
					wallTop,
					actualStripWidth,
					wallHeight,
					1,
					wallColor.r * brightness,
					wallColor.g * brightness,
					wallColor.b * brightness
				)
			end
		end
	end

	self:renderMinimap()

	local visibleEnemies = {}
	for _, enemy in ipairs(self.gameState.enemies) do
		local dx = enemy.x - self.gameState.player.x
		local dy = enemy.y - self.gameState.player.y
		local dist = math.sqrt(dx * dx + dy * dy)

		local enemyAngle = math.atan2(dy, dx)

		while enemyAngle < self.gameState.player.angle - math.pi do
			enemyAngle = enemyAngle + 2 * math.pi
		end
		while enemyAngle > self.gameState.player.angle + math.pi do
			enemyAngle = enemyAngle - 2 * math.pi
		end

		local inFOV = math.abs(enemyAngle - self.gameState.player.angle) < DOOM_CONST.FOV / 1.5

		if inFOV and dist > 0.5 and dist < 15 then
			local screenX = self.gameState.displayX
				+ self.gameState.displayWidth / 2
				+ (enemyAngle - self.gameState.player.angle) / DOOM_CONST.FOV * self.gameState.displayWidth

			if
				screenX >= self.gameState.displayX
				and screenX <= self.gameState.displayX + self.gameState.displayWidth
			then
				local columnIndex = math.floor((screenX - self.gameState.displayX) / self.gameState.stripWidth)
				columnIndex = math.max(0, math.min(DOOM_CONST.NUM_RAYS - 1, columnIndex))

				if dist < depthBuffer[columnIndex] then
					table.insert(visibleEnemies, {
						enemy = enemy,
						screenX = screenX,
						distance = dist,
						angle = enemyAngle,
					})
				end
			end
		end
	end

	table.sort(visibleEnemies, function(a, b)
		return a.distance > b.distance
	end)

	for _, visData in ipairs(visibleEnemies) do
		local enemy = visData.enemy
		local screenX = visData.screenX
		local dist = visData.distance

		local size = math.min(100, math.floor(300 / dist))

		if
			screenX + size / 2 >= self.gameState.displayX
			and screenX - size / 2 <= self.gameState.displayX + self.gameState.displayWidth
		then
			local screenY = self.gameState.displayY + self.gameState.displayHeight / 2 + size / 8

			local brightness = math.max(0.3, 1.0 - dist / 15)
			local r, g, b =
				DOOM_CONST.COLORS.ENEMY.r * brightness,
				DOOM_CONST.COLORS.ENEMY.g * brightness,
				DOOM_CONST.COLORS.ENEMY.b * brightness

			if enemy.state == "hurt" then
				if self.gameState.animationFrame == 0 then
					r, g, b = 1, 1, 1
				end
			elseif enemy.state == "attacking" then
				r, g, b = 1, 0, 0
			end

			self:renderEnemy(enemy, screenX, screenY, size, r, g, b, dist)
		end
	end

	self:renderWeapon()

	local hudY = self.gameState.displayY + self.gameState.displayHeight - 25

	local healthText = "HEALTH: " .. self.gameState.player.health
	self.terminal:drawText(
		healthText,
		self.gameState.displayX + 10,
		hudY,
		DOOM_CONST.COLORS.TEXT.a,
		DOOM_CONST.COLORS.TEXT.r,
		DOOM_CONST.COLORS.TEXT.g,
		DOOM_CONST.COLORS.TEXT.b,
		Constants.UI_CONST.FONT.CODE
	)

	local ammoText = "AMMO: "
		.. self.gameState.player.ammo[DOOM_CONST.WEAPONS[self.gameState.player.currentWeapon].ammo_type]
	local ammoWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.CODE, ammoText)
	self.terminal:drawText(
		ammoText,
		self.gameState.displayX + self.gameState.displayWidth - ammoWidth - 10,
		hudY,
		DOOM_CONST.COLORS.HUD.a,
		DOOM_CONST.COLORS.HUD.r,
		DOOM_CONST.COLORS.HUD.g,
		DOOM_CONST.COLORS.HUD.b,
		Constants.UI_CONST.FONT.CODE
	)

	if self.gameState.isGameOver then
		local gameOverText
		local textColor

		if self.gameState.player.health <= 0 then
			gameOverText = "GAME OVER"
			textColor = DOOM_CONST.COLORS.TEXT
		else
			gameOverText = "LEVEL COMPLETE!"
			textColor = DOOM_CONST.COLORS.HUD
		end

		local textWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.LARGE, gameOverText)
		local textX = self.gameState.displayX + (self.gameState.displayWidth - textWidth) / 2
		local textY = self.gameState.displayY + self.gameState.displayHeight / 3

		self.terminal:drawRect(textX - 20, textY - 20, textWidth + 40, 60, 0.8, 0, 0, 0)

		self.terminal:drawText(
			gameOverText,
			textX,
			textY,
			textColor.a,
			textColor.r,
			textColor.g,
			textColor.b,
			Constants.UI_CONST.FONT.LARGE
		)

		local scoreText = "FINAL SCORE: " .. self.gameState.score
		local scoreWidth = getTextManager():MeasureStringX(Constants.UI_CONST.FONT.MEDIUM, scoreText)
		local scoreX = self.gameState.displayX + (self.gameState.displayWidth - scoreWidth) / 2

		self.terminal:drawText(
			scoreText,
			scoreX,
			textY + 40,
			textColor.a,
			textColor.r,
			textColor.g,
			textColor.b,
			Constants.UI_CONST.FONT.MEDIUM
		)

		self.terminal:renderFooter(gameOverText .. "! | PRESS SPACE OR BACKSPACE TO CONTINUE")
	else
		self.terminal:renderFooter("ARROWS - MOVE | SPACE - SHOOT | 1,2 - WEAPONS | M - TOGGLE MAP | BACKSPACE - QUIT")
	end
end

function DoomGame:renderEnemy(enemy, screenX, screenY, size, r, g, b, dist)
	-- basic body
	self.terminal:drawRect(screenX - size / 2, screenY - size, size, size, 1, r, g, b)

	if enemy.type == "IMP" then
		-- head (slightly smaller than body)
		local headSize = size * 0.6
		self.terminal:drawRect(
			screenX - headSize / 2,
			screenY - size - headSize * 0.7,
			headSize,
			headSize,
			1,
			r * 0.9,
			g * 0.9,
			b * 0.9
		)

		-- eyes
		local eyeSize = size / 10
		local eyeSpacing = size / 5
		self.terminal:drawRect(screenX - eyeSpacing, screenY - size - headSize * 0.4, eyeSize, eyeSize, 1, 1, 1, 0)
		self.terminal:drawRect(
			screenX + eyeSpacing - eyeSize,
			screenY - size - headSize * 0.4,
			eyeSize,
			eyeSize,
			1,
			1,
			1,
			0
		)

		-- arms
		local armWidth = size / 10
		local armLength = size / 2

		-- left arm
		self.terminal:drawRect(
			screenX - size / 2 - armWidth,
			screenY - size + size / 3,
			armWidth,
			armLength,
			1,
			r,
			g,
			b
		)

		-- right arm
		self.terminal:drawRect(screenX + size / 2, screenY - size + size / 3, armWidth, armLength, 1, r, g, b)

		-- mouth
		self.terminal:drawRect(screenX - size / 6, screenY - size - headSize * 0.2, size / 3, size / 15, 1, 0, 0, 0)
	elseif enemy.type == "DEMON" then
		-- head with horns
		local headSize = size * 0.7
		self.terminal:drawRect(screenX - headSize / 2, screenY - size - headSize * 0.7, headSize, headSize, 1, r, g, b)

		-- horns
		local hornHeight = size / 3
		local hornWidth = size / 8

		-- left horn
		self.terminal:drawRect(
			screenX - headSize / 2 - hornWidth,
			screenY - size - headSize * 0.7 - hornHeight,
			hornWidth,
			hornHeight,
			1,
			r,
			g,
			b
		)

		-- right horn
		self.terminal:drawRect(
			screenX + headSize / 2,
			screenY - size - headSize * 0.7 - hornHeight,
			hornWidth,
			hornHeight,
			1,
			r,
			g,
			b
		)

		-- eyes (glowing)
		local eyeSize = size / 8
		local eyeSpacing = size / 4
		self.terminal:drawRect(screenX - eyeSpacing, screenY - size - headSize * 0.4, eyeSize, eyeSize, 1, 1, 0, 0)
		self.terminal:drawRect(
			screenX + eyeSpacing - eyeSize,
			screenY - size - headSize * 0.4,
			eyeSize,
			eyeSize,
			1,
			1,
			0,
			0
		)

		-- large mouth with teeth
		self.terminal:drawRect(screenX - size / 4, screenY - size - headSize * 0.2, size / 2, size / 8, 1, 0, 0, 0)

		-- teeth
		local toothWidth = size / 20
		local toothHeight = size / 15
		for i = 0, 4 do
			self.terminal:drawRect(
				screenX - size / 4 + i * (size / 10),
				screenY - size - headSize * 0.2,
				toothWidth,
				toothHeight,
				1,
				1,
				1,
				1
			)
		end

		-- arms with claws
		local armWidth = size / 8
		local armLength = size / 1.8

		-- left arm
		self.terminal:drawRect(
			screenX - size / 2 - armWidth,
			screenY - size + size / 4,
			armWidth,
			armLength,
			1,
			r,
			g,
			b
		)

		-- left claw
		self.terminal:drawRect(
			screenX - size / 2 - armWidth - size / 15,
			screenY - size + size / 4 + armLength - size / 10,
			size / 15,
			size / 10,
			1,
			r,
			g,
			b
		)

		-- right arm
		self.terminal:drawRect(screenX + size / 2, screenY - size + size / 4, armWidth, armLength, 1, r, g, b)

		-- right claw
		self.terminal:drawRect(
			screenX + size / 2 + armWidth,
			screenY - size + size / 4 + armLength - size / 10,
			size / 15,
			size / 10,
			1,
			r,
			g,
			b
		)
	end

	-- animation for movement
	if enemy.state == "idle" and dist < 8 then
		local bobAmount = math.sin(getTimeInMillis() * 0.005) * (size / 20)
		if self.gameState.animationFrame == 0 then
			-- left leg forward
			self.terminal:drawRect(screenX - size / 3, screenY - size / 3, size / 6, size / 3 + bobAmount, 1, r, g, b)
			-- right leg back
			self.terminal:drawRect(screenX + size / 6, screenY - size / 3, size / 6, size / 3 - bobAmount, 1, r, g, b)
		else
			-- left leg back
			self.terminal:drawRect(screenX - size / 3, screenY - size / 3, size / 6, size / 3 - bobAmount, 1, r, g, b)
			-- right leg forward
			self.terminal:drawRect(screenX + size / 6, screenY - size / 3, size / 6, size / 3 + bobAmount, 1, r, g, b)
		end
	else
		-- static legs when not moving
		self.terminal:drawRect(screenX - size / 3, screenY - size / 3, size / 6, size / 3, 1, r, g, b)
		self.terminal:drawRect(screenX + size / 6, screenY - size / 3, size / 6, size / 3, 1, r, g, b)
	end
end

function DoomGame:renderWeapon()
	local weaponX = self.gameState.displayX + self.gameState.displayWidth / 2
	local weaponY = self.gameState.displayY + self.gameState.displayHeight

	local bobOffset = self.gameState.weaponBob * 5
	local weaponScale = self.gameState.displayWidth / 800

	if self.gameState.player.currentWeapon == "PISTOL" then
		-- barrel
		local barrelWidth = 40 * weaponScale
		local barrelHeight = 10 * weaponScale
		self.terminal:drawRect(
			weaponX - barrelWidth / 2,
			weaponY - 80 * weaponScale + bobOffset,
			barrelWidth,
			barrelHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r,
			DOOM_CONST.COLORS.WEAPON.g,
			DOOM_CONST.COLORS.WEAPON.b
		)

		-- slide
		local slideWidth = 45 * weaponScale
		local slideHeight = 15 * weaponScale
		self.terminal:drawRect(
			weaponX - slideWidth / 2,
			weaponY - (80 + barrelHeight) * weaponScale + bobOffset,
			slideWidth,
			slideHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.9,
			DOOM_CONST.COLORS.WEAPON.g * 0.9,
			DOOM_CONST.COLORS.WEAPON.b * 0.9
		)

		-- frame
		local frameWidth = 30 * weaponScale
		local frameHeight = 35 * weaponScale
		self.terminal:drawRect(
			weaponX - frameWidth / 2,
			weaponY - (80 + barrelHeight + slideHeight - 5) * weaponScale + bobOffset,
			frameWidth,
			frameHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r,
			DOOM_CONST.COLORS.WEAPON.g,
			DOOM_CONST.COLORS.WEAPON.b
		)

		-- grip
		local gripWidth = 20 * weaponScale
		local gripHeight = 40 * weaponScale
		self.terminal:drawRect(
			weaponX - gripWidth / 2,
			weaponY - (80 + barrelHeight + slideHeight - 5 - frameHeight + 10) * weaponScale + bobOffset,
			gripWidth,
			gripHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.8,
			DOOM_CONST.COLORS.WEAPON.g * 0.8,
			DOOM_CONST.COLORS.WEAPON.b * 0.8
		)

		-- trigger
		local triggerWidth = 15 * weaponScale
		local triggerHeight = 10 * weaponScale
		self.terminal:drawRect(
			weaponX - triggerWidth / 2,
			weaponY - (80 + barrelHeight + slideHeight - 5 - frameHeight + 25) * weaponScale + bobOffset,
			triggerWidth,
			triggerHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.7,
			DOOM_CONST.COLORS.WEAPON.g * 0.7,
			DOOM_CONST.COLORS.WEAPON.b * 0.7
		)

		-- muzzle flash
		if getTimeInMillis() - self.gameState.lastShootTime < 100 then
			local flashCenterX = weaponX
			local flashCenterY = weaponY - (80 + barrelHeight / 2) * weaponScale + bobOffset

			-- outer glow
			local flashSize = 25 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				0.7,
				1,
				0.8,
				0
			)

			-- inner glow
			flashSize = 15 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				0.9,
				1,
				1,
				0.5
			)

			-- center
			flashSize = 8 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				1,
				1,
				1,
				1
			)
		end
	elseif self.gameState.player.currentWeapon == "SHOTGUN" then
		-- barrel
		local barrelWidth = 60 * weaponScale
		local barrelHeight = 12 * weaponScale
		self.terminal:drawRect(
			weaponX - barrelWidth / 2,
			weaponY - 80 * weaponScale + bobOffset,
			barrelWidth,
			barrelHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r,
			DOOM_CONST.COLORS.WEAPON.g,
			DOOM_CONST.COLORS.WEAPON.b
		)

		-- pump
		local pumpWidth = 35 * weaponScale
		local pumpHeight = 18 * weaponScale
		self.terminal:drawRect(
			weaponX - pumpWidth / 2,
			weaponY - (80 + barrelHeight + 2) * weaponScale + bobOffset,
			pumpWidth,
			pumpHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.8,
			DOOM_CONST.COLORS.WEAPON.g * 0.8,
			DOOM_CONST.COLORS.WEAPON.b * 0.8
		)

		-- receiver
		local receiverWidth = 40 * weaponScale
		local receiverHeight = 25 * weaponScale
		self.terminal:drawRect(
			weaponX - receiverWidth / 2,
			weaponY - (80 + barrelHeight + pumpHeight) * weaponScale + bobOffset,
			receiverWidth,
			receiverHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r,
			DOOM_CONST.COLORS.WEAPON.g,
			DOOM_CONST.COLORS.WEAPON.b
		)

		-- stock
		local stockWidth = 25 * weaponScale
		local stockHeight = 50 * weaponScale
		self.terminal:drawRect(
			weaponX - stockWidth / 2,
			weaponY - (80 + barrelHeight + pumpHeight + receiverHeight - 15) * weaponScale + bobOffset,
			stockWidth,
			stockHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.7,
			DOOM_CONST.COLORS.WEAPON.g * 0.7,
			DOOM_CONST.COLORS.WEAPON.b * 0.7
		)

		-- trigger
		local triggerWidth = 15 * weaponScale
		local triggerHeight = 10 * weaponScale
		self.terminal:drawRect(
			weaponX - triggerWidth / 2,
			weaponY - (80 + barrelHeight + pumpHeight + 15) * weaponScale + bobOffset,
			triggerWidth,
			triggerHeight,
			1,
			DOOM_CONST.COLORS.WEAPON.r * 0.6,
			DOOM_CONST.COLORS.WEAPON.g * 0.6,
			DOOM_CONST.COLORS.WEAPON.b * 0.6
		)

		-- muzzle flash
		if getTimeInMillis() - self.gameState.lastShootTime < 100 then
			local flashCenterX = weaponX
			local flashCenterY = weaponY - (80 + barrelHeight / 2) * weaponScale + bobOffset

			-- outer glow
			local flashSize = 35 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				0.7,
				1,
				0.6,
				0
			)

			-- inner glow
			flashSize = 25 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				0.9,
				1,
				0.9,
				0.3
			)

			-- center
			flashSize = 15 * weaponScale
			self.terminal:drawRect(
				flashCenterX - flashSize / 2,
				flashCenterY - flashSize / 2,
				flashSize,
				flashSize,
				1,
				1,
				1,
				0.8
			)

			-- multiple pellet effect
			for i = 1, 5 do
				local pelletSize = 5 * weaponScale
				local angle = rand:random() * math.pi * 2
				local distance = rand:random() * 15 * weaponScale
				self.terminal:drawRect(
					flashCenterX - pelletSize / 2 + math.cos(angle) * distance,
					flashCenterY - pelletSize / 2 + math.sin(angle) * distance,
					pelletSize,
					pelletSize,
					0.8,
					1,
					1,
					0.5
				)
			end
		end
	end
end

function DoomGame:renderMinimap()
	if self.gameState.showMinimap == false then
		return
	end

	local sizeMultiplier = 0.25
	if self.gameState.minimapSize == "small" then
		sizeMultiplier = 0.2
	elseif self.gameState.minimapSize == "large" then
		sizeMultiplier = 0.33
	end

	local miniMapSize = math.min(self.gameState.displayWidth, self.gameState.displayHeight) * sizeMultiplier
	local cellSize = miniMapSize / DOOM_CONST.MAP_WIDTH

	local mapX = self.gameState.displayX + self.gameState.displayWidth - miniMapSize - 10
	local mapY = self.gameState.displayY + 10

	self.terminal:drawRect(mapX, mapY, miniMapSize, miniMapSize, 0.7, 0, 0, 0)

	self.terminal:drawRectBorder(mapX, mapY, miniMapSize, miniMapSize, 1, 1, 1, 1)

	for y = 1, DOOM_CONST.MAP_HEIGHT do
		for x = 1, DOOM_CONST.MAP_WIDTH do
			local cellX = mapX + (x - 1) * cellSize
			local cellY = mapY + (y - 1) * cellSize

			if DOOM_CONST.MAP[y][x] == 1 then
				self.terminal:drawRect(cellX, cellY, cellSize, cellSize, 1, 0.6, 0, 0)
			elseif DOOM_CONST.MAP[y][x] == 2 then
				self.terminal:drawRect(cellX, cellY, cellSize, cellSize, 0.3, 0.2, 0.2, 0.2)
			end
		end
	end

	for _, enemy in ipairs(self.gameState.enemies) do
		local enemyX = mapX + (enemy.x - 1) * cellSize
		local enemyY = mapY + (enemy.y - 1) * cellSize

		local r, g, b = 1, 0, 0
		if enemy.type == "DEMON" then
			r, g, b = 1, 0.3, 0
		end

		self.terminal:drawRect(enemyX - cellSize / 6, enemyY - cellSize / 6, cellSize / 3, cellSize / 3, 1, r, g, b)
	end

	local playerX = mapX + (self.gameState.player.x - 1) * cellSize
	local playerY = mapY + (self.gameState.player.y - 1) * cellSize

	self.terminal:drawRect(playerX - cellSize / 4, playerY - cellSize / 4, cellSize / 2, cellSize / 2, 1, 0, 1, 0)

	local dirX = math.cos(self.gameState.player.angle) * cellSize * 0.75
	local dirY = math.sin(self.gameState.player.angle) * cellSize * 0.75

	local length = math.sqrt(dirX * dirX + dirY * dirY)
	local thickness = cellSize / 6

	local angle = math.atan2(dirY, dirX)

	for i = 0, length, thickness / 2 do
		local pointX = playerX + math.cos(angle) * i
		local pointY = playerY + math.sin(angle) * i

		self.terminal:drawRect(pointX - thickness / 2, pointY - thickness / 2, thickness, thickness, 1, 0.5, 1, 0)
	end

	local fovLeftAngle = self.gameState.player.angle - DOOM_CONST.FOV / 2
	local fovRightAngle = self.gameState.player.angle + DOOM_CONST.FOV / 2

	local fovLeftX = math.cos(fovLeftAngle) * miniMapSize * 0.5
	local fovLeftY = math.sin(fovLeftAngle) * miniMapSize * 0.5
	local fovRightX = math.cos(fovRightAngle) * miniMapSize * 0.5
	local fovRightY = math.sin(fovRightAngle) * miniMapSize * 0.5

	for i = 0, miniMapSize * 0.5, thickness / 2 do
		local factor = i / (miniMapSize * 0.5)

		-- left FOV line
		local leftX = playerX + fovLeftX * factor
		local leftY = playerY + fovLeftY * factor

		-- right FOV line
		local rightX = playerX + fovRightX * factor
		local rightY = playerY + fovRightY * factor

		-- draw dots along the FOV lines
		self.terminal:drawRect(leftX - thickness / 2, leftY - thickness / 2, thickness, thickness, 0.4, 1, 1, 0)

		self.terminal:drawRect(rightX - thickness / 2, rightY - thickness / 2, thickness, thickness, 0.4, 1, 1, 0)
	end

	self.terminal:drawText("MINIMAP", mapX + miniMapSize / 2 - 25, mapY - 15, 1, 1, 1, 0, Constants.UI_CONST.FONT.SMALL)
end

local GamesModule = require("KnoxNet_GamesModule/core/Module")
GamesModule.registerGame(GAME_INFO, DoomGame)

return DoomGame
