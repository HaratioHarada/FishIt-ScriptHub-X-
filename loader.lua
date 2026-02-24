local GameVersion = "1.0.0"
local ScriptEnabled = true


-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local mouse = Players.LocalPlayer:GetMouse()




-- Local Player
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	LocalPlayer = Players:WaitForChild("LocalPlayer")
end


local Character = LocalPlayer.Character or LocalPlayer:WaitForChild("Character")
local Humanoid = Character and Character:FindFirstChild("Humanoid")
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- Логируем процесс инициализации
print("=== FishItMenu загружается ===")
print("LocalPlayer:", game.Players.LocalPlayer)
print("PlayerGui:", game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui"))

-- Переменные для GUI
local mainGui = nil
local isGuiVisible = false
local guiFunctions = {}
local expandedCategories = {}
local webhookUrl = ""
local favoriteRarities = {
	["Uncommon"] = false,
	["Common"] = false,
	["Rare"] = false,
	["Epic"] = false,
	["Legendary"] = false,
	["Mythic"] = false,
	["SECRET"] = false
}

-- Глобальное хранение состояний переключателей и слайдеров
local toggleStates = {}
local sliderValues = {}

-- Авто-покупка погоды
local autoWeatherEnabled = {
	["Wind"] = false,
	["Cloudy"] = false,
	["Snow"] = false,
	["Storm"] = false,
	["Shining"] = false,
	["SharkHunt"] = false
}
local weatherPrices = {
	["Wind"] = 10000,
	["Cloudy"] = 20000,
	["Snow"] = 15000,
	["Storm"] = 35000,
	["Shining"] = 50000,
	["SharkHunt"] = 300000
}
-- Product IDs для погоды (замените на реальные ID из игры)
local weatherProductIds = {
	["Wind"] = 0, -- Замените на реальный Product ID
	["Cloudy"] = 0, -- Замените на реальный Product ID
	["Snow"] = 0, -- Замените на реальный Product ID
	["Storm"] = 0, -- Замените на реальный Product ID
	["Shining"] = 0, -- Замените на реальный Product ID
	["SharkHunt"] = 0 -- Замените на реальный Product ID
}
local weatherConnections = {}

-- Клавиша для открытия меню (по умолчанию G)
local menuKeybind = Enum.KeyCode.G
local menuKeybindName = "G"

-- Autorejoin переменные
local autorejoinEnabled = false
local autorejoinConnection = nil

-- AntiAFK переменные
local antiAFKEnabled = false
local antiAFKConnection = nil

-- Airwalk переменные
local airwalkTargetY = nil
local airwalkJumpConnection = nil

-- Optimization V2 переменные
local optimizationV2Active = false
local optimizationV2Connections = {}



-- Создаем переключатель (toggle) с закругленными углами
local function createToggle(parent, name, yPos, callback)
	local toggle = Instance.new("Frame")
	toggle.Name = name:gsub("[^%w]", "") .. "Toggle"
	toggle.Size = UDim2.new(1, 0, 0, 40)
	toggle.BackgroundTransparency = 1
	toggle.Parent = parent

	-- Название функции
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 300, 1, 0)
	nameLabel.Position = UDim2.new(0, 2, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = toggle

	-- Кнопка переключателя с закругленными углами
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleBtn"
	toggleBtn.Size = UDim2.new(0, 50, 0, 25)
	toggleBtn.Position = UDim2.new(1, -60, 0.5, -12)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "OFF"
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.TextSize = 12
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Parent = toggle

	-- UICorner для кнопки
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = toggleBtn

	-- Получаем сохраненное состояние или создаем новое
	local toggleKey = name:gsub("[^%w]", "")
	local isEnabled = toggleStates[toggleKey] or false

	-- Устанавливаем начальное состояние
	if isEnabled then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		toggleBtn.Text = "ON"
		toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	else
		toggleBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
		toggleBtn.Text = "OFF"
		toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Обработка клика
	toggleBtn.MouseButton1Click:Connect(function()
		isEnabled = not isEnabled
		toggleStates[toggleKey] = isEnabled

		if isEnabled then
			toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			toggleBtn.Text = "ON"
			toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		else
			toggleBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
			toggleBtn.Text = "OFF"
			toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		-- Вызываем callback
		if callback then
			callback(isEnabled)
		end
	end)

	return toggle
end

-- Создаем кнопку с закругленными углами
local function createButton(parent, name, yPos, callback)
	local btn = Instance.new("TextButton")
	btn.Name = name:gsub("[^%w]", "") .. "Button"
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.Font = Enum.Font.Gotham
	btn.Parent = parent

	-- UICorner для кнопки
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	-- Обработка клика
	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return btn
end

-- Создаем слайдер с закругленными углами
local function createSlider(parent, name, yPos, minVal, maxVal, defaultVal, callback)
	local slider = Instance.new("Frame")
	slider.Name = name:gsub("[^%w]", "") .. "Slider"
	slider.Size = UDim2.new(1, 0, 0, 60)
	slider.BackgroundTransparency = 1
	slider.Parent = parent

	-- Получаем сохраненное значение или используем дефолтное
	local sliderKey = name:gsub("[^%w]", "")
	local currentValue = sliderValues[sliderKey] or defaultVal

	-- Название
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 2, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name .. ": " .. tostring(currentValue)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = slider

	-- Ползунок с закругленными углами
	local sliderBar = Instance.new("Frame")
	sliderBar.Name = "SliderBar"
	sliderBar.Size = UDim2.new(1, 0, 0, 10)
	sliderBar.Position = UDim2.new(0, 0, 0, 30)
	sliderBar.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
	sliderBar.BorderSizePixel = 0
	sliderBar.Parent = slider

	-- UICorner для ползунка
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 5)
	barCorner.Parent = sliderBar

	-- Кнопка ползунка с закругленными углами
	local sliderBtn = Instance.new("TextButton")
	sliderBtn.Name = "SliderBtn"
	sliderBtn.Size = UDim2.new(0, 20, 0, 20)
	sliderBtn.Position = UDim2.new(0, (currentValue - minVal) / (maxVal - minVal) * (sliderBar.AbsoluteSize.X - 20), 0, 20)
	sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderBtn.BorderSizePixel = 0
	sliderBtn.Text = ""
	sliderBtn.Parent = slider

	-- UICorner для кнопки
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = sliderBtn

	-- Переменная для отслеживания перетаскивания
	local isDragging = false

	-- Обработка перетаскивания
	sliderBtn.MouseButton1Down:Connect(function()
		isDragging = true
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = input.Position
			local sliderPos = sliderBar.AbsolutePosition
			local sliderSize = sliderBar.AbsoluteSize

			local relativeX = math.clamp(mousePos.X - sliderPos.X, 0, sliderSize.X - 20)
			local percentage = relativeX / (sliderSize.X - 20)
			local value = math.floor(minVal + percentage * (maxVal - minVal))

			sliderBtn.Position = UDim2.new(0, relativeX, 0, 20)
			nameLabel.Text = name .. ": " .. tostring(value)
			sliderValues[sliderKey] = value

			if callback then
				callback(value)
			end
		end
	end)

	return slider
end

-- Создаем главное GUI
local function createMainGUI()
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	-- Создаем ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FishItMenu"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Создаем главное окно с закругленными углами
	local window = Instance.new("Frame")
	window.Name = "MainWindow"
	window.Size = UDim2.new(0, 800, 0, 500)
	window.Position = UDim2.new(0.5, -750, 0.5, 0)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	window.BackgroundTransparency = 0.07
	window.BorderSizePixel = 0
	window.Parent = screenGui

	-- Добавляем закругленные углы
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = window

	-- Создаем заголовок окна
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	header.BackgroundTransparency = 0.07
	header.BorderSizePixel = 0
	header.Parent = window

	-- Закругляем только верхние углы заголовка
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	-- Создаем заголовок текста
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎣 Fish It Menu [ScriptHub X]"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = header

	-- Перетаскивание меню за заголовок
	local isDraggingMenu = false
	local dragStartPosMenu = Vector2.new(0, 0)
	local menuStartPos = Vector2.new(0, 0)
	local isClickMenu = true

	local function startDragMenu()
		isDraggingMenu = true
		isClickMenu = true
		dragStartPosMenu = UserInputService:GetMouseLocation()
		-- Получаем текущую позицию меню в пикселях (используем AbsolutePosition)
		menuStartPos = window.AbsolutePosition
	end

	local function updateDragMenu()
		if isDraggingMenu then
			local mousePos = UserInputService:GetMouseLocation()
			local delta = mousePos - dragStartPosMenu

			if delta.Magnitude > 5 then
				isClickMenu = false
			end

			local newPos = menuStartPos + delta
			local viewportSize = camera.ViewportSize
			local windowSize = window.AbsoluteSize

			newPos = Vector2.new(
				math.clamp(newPos.X, 0, viewportSize.X - windowSize.X),
				math.clamp(newPos.Y, 0, viewportSize.Y - windowSize.Y)
			)

			window.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
			window.AnchorPoint = Vector2.new(0, 0)
		end
	end

	local function endDragMenu()
		isDraggingMenu = false
	end

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			startDragMenu()
		end
	end)

	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			endDragMenu()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDragMenu()
		end
	end)

	-- Создаем кнопку сворачивания
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
	minimizeBtn.Position = UDim2.new(1, -90, 0.5, -20)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Text = "−"
	minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeBtn.TextSize = 24
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.Parent = header

	-- UICorner для кнопки сворачивания
	local minimizeBtnCorner = Instance.new("UICorner")
	minimizeBtnCorner.CornerRadius = UDim.new(0, 8)
	minimizeBtnCorner.Parent = minimizeBtn

	-- Обработка клика на кнопку сворачивания
	minimizeBtn.MouseButton1Click:Connect(function()
		if mainGui then
			isGuiVisible = false
			mainGui.Enabled = false
			print("Меню свернуто")
		end
	end)

	-- Создаем кнопку закрытия
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0.5, -20)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✖"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header

	-- UICorner для кнопки закрытия
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	-- Функция для создания диалогового окна подтверждения закрытия
	local function showCloseConfirmation()
		-- Создаем затемняющий фон
		local overlay = Instance.new("Frame")
		overlay.Name = "CloseConfirmationOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.Position = UDim2.new(0, 0, 0, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 100
		overlay.Parent = screenGui

		-- Создаем диалоговое окно
		local dialog = Instance.new("Frame")
		dialog.Name = "CloseConfirmationDialog"
		dialog.Size = UDim2.new(0, 400, 0, 200)
		dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
		dialog.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
		dialog.BorderSizePixel = 0
		dialog.ZIndex = 101
		dialog.Parent = overlay

		-- Закругленные углы
		local dialogCorner = Instance.new("UICorner")
		dialogCorner.CornerRadius = UDim.new(0, 12)
		dialogCorner.Parent = dialog

		-- Заголовок
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, 0, 0, 40)
		titleLabel.Position = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "Close Window"
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 20
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.ZIndex = 102
		titleLabel.Parent = dialog

		-- Линия под заголовком
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(1, -20, 0, 1)
		line.Position = UDim2.new(0, 10, 0, 40)
		line.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
		line.BorderSizePixel = 0
		line.ZIndex = 102
		line.Parent = dialog

		-- Текст вопроса
		local questionLabel = Instance.new("TextLabel")
		questionLabel.Name = "QuestionLabel"
		questionLabel.Size = UDim2.new(1, -20, 0, 30)
		questionLabel.Position = UDim2.new(0, 10, 0, 55)
		questionLabel.BackgroundTransparency = 1
		questionLabel.Text = "Do you want to close this window?"
		questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		questionLabel.TextSize = 16
		questionLabel.Font = Enum.Font.Gotham
		questionLabel.ZIndex = 102
		questionLabel.Parent = dialog

		-- Текст предупреждения
		local warningLabel = Instance.new("TextLabel")
		warningLabel.Name = "WarningLabel"
		warningLabel.Size = UDim2.new(1, -20, 0, 30)
		warningLabel.Position = UDim2.new(0, 10, 0, 85)
		warningLabel.BackgroundTransparency = 1
		warningLabel.Text = "You will not be able to open it again."
		warningLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		warningLabel.TextSize = 14
		warningLabel.Font = Enum.Font.Gotham
		warningLabel.ZIndex = 102
		warningLabel.Parent = dialog

		-- Кнопка Cancel
		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Name = "CancelBtn"
		cancelBtn.Size = UDim2.new(0, 170, 0, 40)
		cancelBtn.Position = UDim2.new(0, 20, 1, -55)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		cancelBtn.BorderSizePixel = 0
		cancelBtn.Text = "Cancel"
		cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		cancelBtn.TextSize = 16
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.ZIndex = 102
		cancelBtn.Parent = dialog

		local cancelCorner = Instance.new("UICorner")
		cancelCorner.CornerRadius = UDim.new(0, 8)
		cancelCorner.Parent = cancelBtn

		-- Кнопка Close Window
		local closeWindowBtn = Instance.new("TextButton")
		closeWindowBtn.Name = "CloseWindowBtn"
		closeWindowBtn.Size = UDim2.new(0, 170, 0, 40)
		closeWindowBtn.Position = UDim2.new(1, -190, 1, -55)
		closeWindowBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		closeWindowBtn.BorderSizePixel = 0
		closeWindowBtn.Text = "Close Window"
		closeWindowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeWindowBtn.TextSize = 16
		closeWindowBtn.Font = Enum.Font.GothamBold
		closeWindowBtn.ZIndex = 102
		closeWindowBtn.Parent = dialog

		local closeWindowCorner = Instance.new("UICorner")
		closeWindowCorner.CornerRadius = UDim.new(0, 8)
		closeWindowCorner.Parent = closeWindowBtn

		-- Функция для закрытия диалога
		local function closeDialog()
			overlay:Destroy()
		end

		-- Обработка клика на Cancel (просто закрывает диалог)
		cancelBtn.MouseButton1Click:Connect(function()
			closeDialog()
		end)

		-- Обработка клика на Close Window (полностью закрывает скрипт)
		closeWindowBtn.MouseButton1Click:Connect(function()
			-- Закрываем диалог
			closeDialog()

			-- Закрываем главное меню
			if mainGui then
				isGuiVisible = false
				mainGui:Destroy()
				mainGui = nil
			end

			-- Удаляем иконку меню
			local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
			if playerGui then
				local iconGui = playerGui:FindFirstChild("FishItMenuIcon")
				if iconGui then
					iconGui:Destroy()
				end
			end

			-- Останавливаем все функции скрипта
			ScriptEnabled = false
			guiFunctions = {}

			-- Останавливаем все соединения
			if autoFishConnection then
				autoFishConnection = nil
			end

			for weatherName, connection in pairs(weatherConnections) do
				if connection then
					connection:Disconnect()
				end
			end
			weatherConnections = {}

			if antiAFKConnection then
				antiAFKConnection = nil
			end

			if autorejoinConnection then
				autorejoinConnection:Disconnect()
				autorejoinConnection = nil
			end

			if airwalkJumpConnection then
				airwalkJumpConnection:Disconnect()
				airwalkJumpConnection = nil
			end

			for _, connection in pairs(optimizationV2Connections) do
				if connection then
					connection:Disconnect()
				end
			end
			optimizationV2Connections = {}

			print("🛑 Скрипт полностью остановлен!")
		end)
	end

	-- Обработка клика на кнопку закрытия
	closeBtn.MouseButton1Click:Connect(function()
		showCloseConfirmation()
	end)

	-- Создаем левую панель для категорий
	local leftPanel = Instance.new("ScrollingFrame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0, 220, 1, -50)
	leftPanel.Position = UDim2.new(0, 10, 0, 50)
	leftPanel.BackgroundTransparency = 1
	leftPanel.BorderSizePixel = 0
	leftPanel.ScrollBarThickness = 6
	leftPanel.ScrollBarImageColor3 = Color3.fromRGB(68, 68, 68)
	leftPanel.CanvasSize = UDim2.new(0, 0, 0, 400)
	leftPanel.Parent = window

	-- Закругляем только нижние углы левой панели
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 16)
	leftCorner.Parent = leftPanel

	-- Создаем правую панель для содержимого
	local rightPanel = Instance.new("ScrollingFrame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(1, -240, 1, -50)
	rightPanel.Position = UDim2.new(0, 240, 0, 50)
	rightPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rightPanel.BackgroundTransparency = 0.8
	rightPanel.BorderSizePixel = 0
	rightPanel.ScrollBarThickness = 6
	rightPanel.ScrollBarImageColor3 = Color3.fromRGB(68, 68, 68)
	rightPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	rightPanel.Parent = window

	-- Создаем UIListLayout для левой панели
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 5)
	leftLayout.Parent = leftPanel

	-- Создаем UIListLayout для правой панели
	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.Parent = rightPanel

	-- Переменная для хранения текущей активной категории
	local currentCategory = nil

	-- Переменная для хранения callback категории Info (для автоматического открытия)
	local infoCategoryCallback = nil

	-- Функция для создания кнопки категории
	local function createCategoryButton(name, icon, callback)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Btn"
		btn.Size = UDim2.new(1, -20, 0, 45)
		btn.Position = UDim2.new(0, 10, 0, 0)
		btn.BackgroundTransparency = 0.9
		btn.BorderSizePixel = 0
		btn.Text = icon .. " " .. name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 14
		btn.Font = Enum.Font.Gotham
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = leftPanel

		-- Сдвигаем указанные категории правее
		if name == "Farm" or name == "Teleport" or name == "AutoFavorite" or name == "Misc" or name == "Webhooks" or name == "Settings" or name == "Info" then
			btn.Position = UDim2.new(0, 20, 0, 0)
		end

		-- UICorner для кнопки
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn

		-- Обработка клика
		btn.MouseButton1Click:Connect(function()
			-- Сбрасываем цвет всех кнопок
			for _, child in pairs(leftPanel:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundTransparency = 0.9
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end

			-- Подсвечиваем активную кнопку
			btn.BackgroundTransparency = 0.7
			btn.TextColor3 = Color3.fromRGB(0, 0, 0)

			-- Очищаем правую панель
			for _, child in pairs(rightPanel:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					child:Destroy()
				end
			end

			-- Вызываем callback для загрузки содержимого
			if callback then
				callback(rightPanel)
			end

			currentCategory = name
		end)

		return btn
	end

	-- Функция для создания заголовка в правой панели
	local function createRightPanelTitle(title, panel)
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -20, 0, 30)
		titleLabel.Position = UDim2.new(0, 25, 0, 10)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 18
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = panel

		-- Линия под заголовком
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(1, -20, 0, 1)
		line.Position = UDim2.new(0, 10, 0, 45)
		line.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
		line.BorderSizePixel = 0
		line.Parent = panel

		return titleLabel
	end

	-- Функция для создания контейнера для элементов
	local function createRightPanelContainer(panel)
		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.new(1, -20, 1, -60)
		container.Position = UDim2.new(0, 25, 0, 60)
		container.BackgroundTransparency = 1
		container.Parent = panel

		-- UIListLayout для контейнера
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 10)
		layout.Parent = container

		return container
	end

	-- Создаем категории в левой панели
	print("Создаем категории...")

	-- Farm категория
	createCategoryButton("Farm", "🎣", function(rightPanel)
		createRightPanelTitle("🎣 Farm", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- AutoFish
		createToggle(container, "🐟 AutoFish", 0, function(enabled)
			guiFunctions.autoFish = enabled
			print("AutoFish:", enabled)
			if enabled then
				startAutoFish()
			else
				stopAutoFish()
			end
		end)

		-- Caught Delay
		createSlider(container, "⏱️ Caught Delay", 0, 0.1, 5, 1, function(value)
			guiFunctions.caughtDelay = value
			print("Caught Delay:", value)
		end)

		-- Recast Delay
		createSlider(container, "⏱️ Recast Delay", 0, 0.1, 5, 1, function(value)
			guiFunctions.recastDelay = value
			print("Recast Delay:", value)
		end)

		-- AutoSell
		createToggle(container, "💰 AutoSell", 0, function(enabled)
			guiFunctions.autoSell = enabled
			print("AutoSell:", enabled)
			if enabled then
				sellFish()
			end
		end)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 250)
	end)

	-- Teleport категория
	createCategoryButton("Teleport", "🚀", function(rightPanel)
		createRightPanelTitle("🚀 Teleport", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Teleport To Island
		createButton(container, "🏝️ Teleport To Island", 0, function()
			-- Очищаем правую панель
			for _, child in pairs(rightPanel:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					child:Destroy()
				end
			end

			-- Создаем заголовок для локаций
			createRightPanelTitle("🏝️ Выберите локацию:", rightPanel)
			local locationContainer = createRightPanelContainer(rightPanel)

			-- Список локаций в правильном порядке (все 17 локаций)
			local locations = {
				{["name"] = "Fisherman Island", ["pos"] = Vector3.new(34.2641716003418, 9.628792762756348, 2803.64599609375)},
				{["name"] = "Traveling Merchant", ["pos"] = Vector3.new(-137.52841186523438, 3.2620537281036377, 2768.219970703125)},
				{["name"] = "Planetary Observatory", ["pos"] = Vector3.new(394.7527770996094, 7.251010417938232, 2157.100341796875)},
				{["name"] = "Crater Island", ["pos"] = Vector3.new(969.0936279296875, 7.362037181854248, 4872.45166015625)},
				{["name"] = "Tropical Grove", ["pos"] = Vector3.new(-2129.407958984375, 53.48722839355469, 3741.8310546875)},
				{["name"] = "Weather Machine", ["pos"] = Vector3.new(-1519.586669921875, 6.499998569488525, 1884.587646484375)},
				{["name"] = "Coral Reefs", ["pos"] = Vector3.new(-3186.4384765625, 10.021647453308105, 2250.93359375)},
				{["name"] = "Crater Island", ["pos"] = Vector3.new(986.1216430664062, 30.208383560180664, 4952.654296875)},
				{["name"] = "Pirate Cove", ["pos"] = Vector3.new(3358.006591796875, 4.192970275878906, 3519.951171875)},
				{["name"] = "Crystal Depths", ["pos"] = Vector3.new(5686.9443359375, -891.0681762695312, 15294.7333984375)},
				{["name"] = "Esoteric Depths", ["pos"] = Vector3.new(3193.7265625, -1302.7301025390625, 1420.59814453125)},
				{["name"] = "Kohana", ["pos"] = Vector3.new(-643.0057373046875, 16.030197143554688, 615.0732421875)},
				{["name"] = "Kohana Volcano", ["pos"] = Vector3.new(-497.61676025390625, 22.394704818725586, 177.54757690429688)},
				{["name"] = "Lava Basin", ["pos"] = Vector3.new(1042.163818359375, 85.89966583251953, -10246.27734375)},
				{["name"] = "Ancient Jungle", ["pos"] = Vector3.new(1453.7100830078125, 7.6254987716674805, -329.9733581542969)},
				{["name"] = "Sacred Temple", ["pos"] = Vector3.new(1475.955078125, -21.849966049194336, -630.0169067382812)},
				{["name"] = "Ancient Ruin", ["pos"] = Vector3.new(6050.234375, -585.9246215820312, 4713.1767578125)},
				{["name"] = "Treasure Room", ["pos"] = Vector3.new(-3599.53759765625, -266.57379150390625, -1572.31298828125)},
				{["name"] = "Sisiphys Statue", ["pos"] = Vector3.new(-3698.338623046875, -135.57444763183594, -1026.4268798828125)},
				{["name"] = "Underground Cellar", ["pos"] = Vector3.new(2135.52490234375, -91.19860076904297, -699.4429931640625)}
			}

			-- Создаем кнопки для каждой локации
			local yPos = 0
			for i, location in ipairs(locations) do
				local locationBtn = Instance.new("TextButton")
				locationBtn.Name = location.name:gsub("[^%w]", "") .. "Btn"
				locationBtn.Size = UDim2.new(1, 0, 0, 30)
				locationBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
				locationBtn.BorderSizePixel = 0
				locationBtn.Text = "📍 " .. location.name
				locationBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				locationBtn.TextSize = 12
				locationBtn.Font = Enum.Font.Gotham
				locationBtn.TextXAlignment = Enum.TextXAlignment.Left
				locationBtn.Parent = locationContainer

				-- UICorner для кнопки
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 4)
				corner.Parent = locationBtn

				-- Обработка клика на локацию
				locationBtn.MouseButton1Click:Connect(function()
					local character = Players.LocalPlayer.Character
					if not character then return end

					local rootPart = character:FindFirstChild("HumanoidRootPart")
					if not rootPart then return end

					rootPart.CFrame = CFrame.new(location.pos)
					print("Телепортировано в:", location.name, location.pos)
				end)

				yPos = yPos + 32
			end

			-- Устанавливаем правильный CanvasSize для всех локаций
			rightPanel.CanvasSize = UDim2.new(0, 0, 0, yPos + 200)
			print("Создано локаций:", #locations, "CanvasSize установлен на:", yPos + 200)
		end)

		-- Teleport to Player
		createButton(container, "👤 Teleport to Player", 0, function()
			-- Очищаем правую панель
			for _, child in pairs(rightPanel:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					child:Destroy()
				end
			end

			-- Создаем заголовок для игроков
			createRightPanelTitle("👤 Выберите игрока:", rightPanel)
			local playerContainer = createRightPanelContainer(rightPanel)

			-- Функция телепортации к игроку
			local function teleportToPlayer(targetPlayer)
				local myCharacter = Players.LocalPlayer.Character
				if not myCharacter then 
					print("❌ У вас нет персонажа!")
					return 
				end

				local myRootPart = myCharacter:FindFirstChild("HumanoidRootPart")
				if not myRootPart then 
					print("❌ У вас нет HumanoidRootPart!")
					return 
				end

				local targetCharacter = targetPlayer.Character
				if not targetCharacter then 
					print("❌ У игрока " .. targetPlayer.Name .. " нет персонажа!")
					return 
				end

				local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
				if not targetRootPart then 
					print("❌ У игрока " .. targetPlayer.Name .. " нет HumanoidRootPart!")
					return 
				end

				-- Телепортируем к игроку
				myRootPart.CFrame = CFrame.new(targetRootPart.Position + Vector3.new(0, 5, 0))
				print("✅ Телепортировано к игроку:", targetPlayer.Name)
			end

			-- Получаем список всех игроков
			local playersList = {}
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= Players.LocalPlayer then
					table.insert(playersList, player)
				end
			end

			-- Создаем кнопки для каждого игрока
			local yPos = 0
			for i, player in ipairs(playersList) do
				local playerBtn = Instance.new("TextButton")
				playerBtn.Name = player.Name .. "Btn"
				playerBtn.Size = UDim2.new(1, 0, 0, 30)
				playerBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
				playerBtn.BorderSizePixel = 0
				playerBtn.Text = "👤 " .. player.Name
				playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				playerBtn.TextSize = 12
				playerBtn.Font = Enum.Font.Gotham
				playerBtn.TextXAlignment = Enum.TextXAlignment.Left
				playerBtn.Parent = playerContainer

				-- UICorner для кнопки
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 4)
				corner.Parent = playerBtn

				-- Обработка клика на игрока
				playerBtn.MouseButton1Click:Connect(function()
					teleportToPlayer(player)
				end)

				yPos = yPos + 32
			end



			-- Устанавливаем правильный CanvasSize (как в Teleport to Island)
			rightPanel.CanvasSize = UDim2.new(0, 0, 0, yPos + 200)
			print("Создано игроков для телепортации:", #playersList, "CanvasSize:", yPos + 200)
		end)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 350)
	end)

	-- Shop категория
	createCategoryButton("Shop", "🛒", function(rightPanel)
		createRightPanelTitle("🛒 Shop", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Open/Close Shop
		createButton(container, "🏪 Open/Close Shop", 0, function()
			local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
			if not playerGui then
				print("PlayerGui не найден!")
				return
			end

			local merchantGui = playerGui:FindFirstChild("Merchant")
			if not merchantGui then
				print("Merchant GUI не найден!")
				return
			end

			local background = merchantGui:FindFirstChild("Main")
			if not background then
				print("Main не найден в Merchant!")
				return
			end

			-- Переключаем видимость магазина
			background.Enabled = not background.Enabled
			print("Магазин", background.Enabled and "открыт" or "закрыт")
		end)

		-- Разделитель
		local separator = Instance.new("Frame")
		separator.Name = "Separator"
		separator.Size = UDim2.new(1, 0, 0, 1)
		separator.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
		separator.BorderSizePixel = 0
		separator.Parent = container

		-- Заголовок для авто-покупки погоды
		local weatherTitle = Instance.new("TextLabel")
		weatherTitle.Name = "WeatherTitle"
		weatherTitle.Size = UDim2.new(1, 0, 0, 25)
		weatherTitle.BackgroundTransparency = 1
		weatherTitle.Text = "🌤️ Auto Buy Weather"
		weatherTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		weatherTitle.TextSize = 16
		weatherTitle.Font = Enum.Font.GothamBold
		weatherTitle.TextXAlignment = Enum.TextXAlignment.Left
		weatherTitle.Parent = container



		-- Функция для создания переключателя погоды
		local function createWeatherToggle(weatherName, price)
			local toggle = Instance.new("Frame")
			toggle.Name = weatherName .. "Toggle"
			toggle.Size = UDim2.new(1, 0, 0, 35)
			toggle.BackgroundTransparency = 1
			toggle.Parent = container

			-- Название и цена
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Size = UDim2.new(0, 200, 1, 0)
			nameLabel.Position = UDim2.new(0, 0, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = weatherName .. " (" .. tostring(price) .. ")"
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 12
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = toggle

			-- Кнопка переключателя
			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Name = "ToggleBtn"
			toggleBtn.Size = UDim2.new(0, 50, 0, 25)
			toggleBtn.Position = UDim2.new(1, -60, 0.5, -12)
			toggleBtn.BorderSizePixel = 0
			toggleBtn.Text = "OFF"
			toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			toggleBtn.TextSize = 12
			toggleBtn.Font = Enum.Font.GothamBold
			toggleBtn.Parent = toggle

			-- UICorner для кнопки
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = toggleBtn

			-- Устанавливаем начальное состояние
			local isEnabled = autoWeatherEnabled[weatherName] or false

			if isEnabled then
				toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
				toggleBtn.Text = "ON"
				toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			else
				toggleBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
				toggleBtn.Text = "OFF"
				toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			end

			-- Обработка клика
			toggleBtn.MouseButton1Click:Connect(function()
				isEnabled = not isEnabled
				autoWeatherEnabled[weatherName] = isEnabled

				if isEnabled then
					toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
					toggleBtn.Text = "ON"
					toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)

					-- Запускаем авто-покупку
					startAutoBuyWeather(weatherName)
				else
					toggleBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
					toggleBtn.Text = "OFF"
					toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

					-- Останавливаем авто-покупку
					stopAutoBuyWeather(weatherName)
				end

				print(weatherName .. " авто-покупка:", isEnabled and "включена" or "выключена")
			end)
		end

		-- Создаем переключатели для каждого типа погоды
		createWeatherToggle("Wind", 10000)
		createWeatherToggle("Cloudy", 20000)
		createWeatherToggle("Snow", 15000)
		createWeatherToggle("Storm", 35000)
		createWeatherToggle("Shining", 50000)
		createWeatherToggle("SharkHunt", 300000)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 350)
	end)

	-- AutoFavorite категория
	createCategoryButton("AutoFavorite", "⭐", function(rightPanel)
		createRightPanelTitle("⭐ AutoFavorite", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Common
		createToggle(container, "Common", 0, function(enabled)
			favoriteRarities["Common"] = enabled
			print("Common favorite:", enabled)
		end)

		-- Uncommon
		createToggle(container, "Uncommon", 0, function(enabled)
			favoriteRarities["Uncommon"] = enabled
			print("Uncommon favorite:", enabled)
		end)

		-- Rare
		createToggle(container, "Rare", 0, function(enabled)
			favoriteRarities["Rare"] = enabled
			print("Rare favorite:", enabled)
		end)

		-- Epic
		createToggle(container, "Epic", 0, function(enabled)
			favoriteRarities["Epic"] = enabled
			print("Epic favorite:", enabled)
		end)

		-- Legendary
		createToggle(container, "Legendary", 0, function(enabled)
			favoriteRarities["Legendary"] = enabled
			print("Legendary favorite:", enabled)
		end)

		-- Mythic
		createToggle(container, "Mythic", 0, function(enabled)
			favoriteRarities["Mythic"] = enabled
			print("Mythic favorite:", enabled)
		end)

		-- SECRET
		createToggle(container, "SECRET", 0, function(enabled)
			favoriteRarities["SECRET"] = enabled
			print("SECRET favorite:", enabled)
		end)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 300)
	end)

	-- Misc категория
	createCategoryButton("Misc", "🔧", function(rightPanel)
		createRightPanelTitle("🔧 Misc", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Noclip
		createToggle(container, "👻 Noclip", 0, function(enabled)
			guiFunctions.noclip = enabled
			print("Noclip:", enabled)
		end)

		-- Speed
		createSlider(container, "💨 Speed", 0, 16, 200, 16, function(value)
			guiFunctions.speed = value
			print("Speed:", value)
		end)

		-- Прыжок
		createSlider(container, "🦘 Прыжок", 0, 50, 200, 50, function(value)
			guiFunctions.jumpPower = value
			guiFunctions.jumpHack = true
			print("Jump Power:", value)
		end)

		-- Airwalk
		createToggle(container, "🚶 Airwalk", 0, function(enabled)
			guiFunctions.airwalk = enabled
			print("Airwalk:", enabled)
			if enabled then
				enableAirwalk()
			else
				disableAirwalk()
			end
		end)



		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 300)
	end)

	-- Optimization категория удалена (функции перенесены в Settings)

	-- Webhook категория
	createCategoryButton("Webhook", "🔔", function(rightPanel)
		createRightPanelTitle("🔔 Webhook", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Webhook URL input
		local webhookInput = Instance.new("TextBox")
		webhookInput.Name = "WebhookInput"
		webhookInput.Size = UDim2.new(1, 0, 0, 30)
		webhookInput.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
		webhookInput.BorderSizePixel = 0
		webhookInput.PlaceholderText = "Discord Webhook URL"
		webhookInput.Text = webhookUrl
		webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
		webhookInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
		webhookInput.TextSize = 12
		webhookInput.Font = Enum.Font.Gotham
		webhookInput.Parent = container

		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 6)
		inputCorner.Parent = webhookInput

		webhookInput.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				webhookUrl = webhookInput.Text
				print("Webhook URL сохранен:", webhookUrl)
			end
		end)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 80)
	end)

	-- Settings категория
	createCategoryButton("Settings", "⚙️", function(rightPanel)
		createRightPanelTitle("⚙️ Settings", rightPanel)
		local container = createRightPanelContainer(rightPanel)

		-- Keybind для открытия меню
		local keybindFrame = Instance.new("Frame")
		keybindFrame.Name = "KeybindFrame"
		keybindFrame.Size = UDim2.new(1, 0, 0, 40)
		keybindFrame.BackgroundTransparency = 1
		keybindFrame.Parent = container

		local keybindLabel = Instance.new("TextLabel")
		keybindLabel.Name = "KeybindLabel"
		keybindLabel.Size = UDim2.new(0, 200, 1, 0)
		keybindLabel.Position = UDim2.new(0, 0, 0, 0)
		keybindLabel.BackgroundTransparency = 1
		keybindLabel.Text = "🔑 Keybind: " .. menuKeybindName
		keybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keybindLabel.TextSize = 14
		keybindLabel.Font = Enum.Font.Gotham
		keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
		keybindLabel.Parent = keybindFrame

		local keybindBtn = Instance.new("TextButton")
		keybindBtn.Name = "KeybindBtn"
		keybindBtn.Size = UDim2.new(0, 100, 0, 30)
		keybindBtn.Position = UDim2.new(1, -110, 0.5, -15)
		keybindBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
		keybindBtn.BorderSizePixel = 0
		keybindBtn.Text = "Изменить"
		keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		keybindBtn.TextSize = 12
		keybindBtn.Font = Enum.Font.Gotham
		keybindBtn.Parent = keybindFrame

		local keybindCorner = Instance.new("UICorner")
		keybindCorner.CornerRadius = UDim.new(0, 6)
		keybindCorner.Parent = keybindBtn

		local isWaitingForKey = false

		keybindBtn.MouseButton1Click:Connect(function()
			if isWaitingForKey then return end
			isWaitingForKey = true
			keybindBtn.Text = "Нажми клавишу..."
			keybindBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)

			local inputConnection
			inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end

				if input.KeyCode ~= nil and input.KeyCode ~= Enum.KeyCode.Unknown then
					menuKeybind = input.KeyCode
					menuKeybindName = input.KeyCode.Name
					keybindLabel.Text = "🔑 Keybind: " .. menuKeybindName
					keybindBtn.Text = "Изменить"
					keybindBtn.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
					isWaitingForKey = false
					inputConnection:Disconnect()
					print("Клавиша изменена на:", menuKeybindName)
				end
			end)
		end)

		-- AntiAFK
		createToggle(container, "🛡️ AntiAFK", 0, function(enabled)
			antiAFKEnabled = enabled
			print("AntiAFK:", enabled)
			if enabled then
				enableAntiAFK()
			else
				disableAntiAFK()
			end
		end)

		-- Autorejoin
		createToggle(container, "🔄 Autorejoin", 0, function(enabled)
			autorejoinEnabled = enabled
			print("Autorejoin:", enabled)
			if enabled then
				enableAutorejoin()
			else
				disableAutorejoin()
			end
		end)

		-- Optimization V2 (новая версия с мыльной графикой)
		createToggle(container, "🚀 Optimization V2", 0, function(enabled)
			optimizationV2Active = enabled
			print("Optimization V2:", enabled)
			if enabled then
				enableOptimizationV2()
			else
				disableOptimizationV2()
			end
		end)

		-- Optimization (оригинальная)
		createToggle(container, "🚀 Optimization", 0, function(enabled)
			guiFunctions.optimization = enabled
			if enabled then
				enableOptimization()
				print("🚀 Optimization enabled!")
			else
				disableOptimization()
				print("❌ Optimization disabled!")
			end
		end)

		-- Ночной режим
		createToggle(container, "🌙 Ночной режим", 0, function(enabled)
			guiFunctions.nightMode = enabled
			if enabled then
				game.Lighting.ClockTime = 0
				print("Ночной режим включен!")
			else
				game.Lighting.ClockTime = 12
				print("Ночной режим выключен!")
			end
		end)

		rightPanel.CanvasSize = UDim2.new(0, 0, 0, 200)
	end)

	-- Info категория
	createCategoryButton("Info", "ℹ️", function(rightPanel)
		-- Сохраняем callback для автоматического открытия (с параметром rightPanel)
		infoCategoryCallback = function(panel)
			createRightPanelTitle("ℹ️ Info", panel)
			local container = createRightPanelContainer(panel)

			-- Информационный текст
			local infoText = Instance.new("TextLabel")
			infoText.Name = "InfoText"
			infoText.Size = UDim2.new(1, 0, 0, 100)
			infoText.BackgroundTransparency = 1
			infoText.Text = "FishIt [ScriptHub X] - это мощный скрипт для Roblox Fish It специально разработан для того, чтобы сделать ваши рыболовные приключения в популярной игре Roblox Fish It невероятно простыми и увлекательными.\n\nНажмите G чтобы открыть/закрыть меню."
			infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
			infoText.TextSize = 12
			infoText.Font = Enum.Font.Gotham
			infoText.TextXAlignment = Enum.TextXAlignment.Left
			infoText.TextYAlignment = Enum.TextYAlignment.Top
			infoText.TextWrapped = true
			infoText.Parent = container

			panel.CanvasSize = UDim2.new(0, 0, 0, 120)
		end

		-- Вызываем callback сразу для загрузки содержимого
		infoCategoryCallback(rightPanel)
	end)

	print("Все категории созданы")

	-- Анимация появления
	local tween = TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 800, 0, 500)
	})
	window.Size = UDim2.new(0, 0, 0, 0)

	-- Убеждаемся, что позиция установлена правильно перед анимацией
	window.Position = UDim2.new(0.5, 0, 0.5, 0)
	window.AnchorPoint = Vector2.new(0.5, 0.5)

	tween:Play()

	return screenGui
end

-- Создаем иконку для быстрого доступа (появляется сразу при запуске)
-- Принимает функцию toggleGUI как параметр
local function createMenuIcon(toggleGUIFunc)
	print("🎣 Создаем иконку меню...")
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then 
		print("❌ PlayerGui не найден!")
		return nil 
	end

	-- Создаем ScreenGui для иконки
	local iconGui = Instance.new("ScreenGui")
	iconGui.Name = "FishItMenuIcon"
	iconGui.ResetOnSpawn = false
	iconGui.Parent = playerGui

	-- Создаем кнопку-иконку для быстрого доступа
	local iconButton = Instance.new("ImageButton")
	iconButton.Name = "MenuIcon"
	iconButton.Size = UDim2.new(0, 50, 0, 50)
	iconButton.Position = UDim2.new(0, 10, 0.5, -25)
	iconButton.AnchorPoint = Vector2.new(0, 0)
	iconButton.BackgroundColor3 = Color3.fromRGB(17, 17, 30)
	iconButton.BackgroundTransparency = 0.2
	iconButton.BorderSizePixel = 0
	iconButton.Parent = iconGui

	-- Сохраняем начальную позицию для корректного перетаскивания
	local initialPosition = iconButton.Position

	-- UICorner для круглой кнопки
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 25)
	iconCorner.Parent = iconButton

	-- Создаем текст с иконкой рыбы и удочки
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "IconLabel"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "🎣"
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.TextSize = 30
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextXAlignment = Enum.TextXAlignment.Center
	iconLabel.TextYAlignment = Enum.TextYAlignment.Center
	iconLabel.Parent = iconButton

	-- Переменные для перетаскивания
	local isDragging = false
	local dragStartPos = Vector2.new(0, 0)
	local iconStartPos = Vector2.new(0, 0)
	local isClick = true -- Для отличия клика от перетаскивания

	-- Функция для начала перетаскивания
	local function startDrag()
		isDragging = true
		isClick = true -- Сначала считаем это кликом
		-- Используем GetMouseLocation для точных координат в пикселях
		dragStartPos = UserInputService:GetMouseLocation()
		-- Получаем текущую позицию иконки в пикселях (используем AbsolutePosition)
		iconStartPos = iconButton.AbsolutePosition
	end

	-- Функция для обновления позиции при перетаскивании
	local function updateDrag()
		if isDragging then
			-- Получаем текущую позицию мыши в пикселях
			local mousePos = UserInputService:GetMouseLocation()
			local delta = mousePos - dragStartPos

			-- Если переместили более чем на 5 пикселей, считаем это перетаскиванием, а не кликом
			if delta.Magnitude > 5 then
				isClick = false
			end

			local newPos = iconStartPos + delta

			-- Ограничиваем позицию в пределах экрана
			local viewportSize = camera.ViewportSize
			local iconSize = iconButton.AbsoluteSize

			newPos = Vector2.new(
				math.clamp(newPos.X, 0, viewportSize.X - iconSize.X),
				math.clamp(newPos.Y, 0, viewportSize.Y - iconSize.Y)
			)

			iconButton.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
		end
	end

	-- Функция для завершения перетаскивания
	local function endDrag()
		isDragging = false
	end

	-- Обработчики событий для перетаскивания
	iconButton.MouseButton1Down:Connect(startDrag)
	iconButton.MouseButton1Up:Connect(endDrag)
	mouse.Button1Up:Connect(endDrag)
	mouse.Move:Connect(updateDrag)

	-- Эффект при наведении
	iconButton.MouseEnter:Connect(function()
		iconButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
		iconButton.BackgroundTransparency = 0
		-- Анимация увеличения
		local tween = TweenService:Create(iconButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 55, 0, 55)
		})
		tween:Play()
	end)

	iconButton.MouseLeave:Connect(function()
		iconButton.BackgroundColor3 = Color3.fromRGB(17, 17, 30)
		iconButton.BackgroundTransparency = 0.2
		-- Анимация уменьшения
		local tween = TweenService:Create(iconButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 50, 0, 50)
		})
		tween:Play()
	end)

	-- Обработка клика на иконку
	iconButton.MouseButton1Click:Connect(function()
		-- Открываем меню только если это был клик, а не перетаскивание
		if isClick then
			print("🖱️ Клик по иконке меню!")
			-- Анимация нажатия
			local clickTween = TweenService:Create(iconButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 45, 0, 45)
			})
			clickTween:Play()

			-- Возвращаем размер после анимации
			task.wait(0.1)
			local restoreTween = TweenService:Create(iconButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 50, 0, 50)
			})
			restoreTween:Play()

			-- Переключаем меню (используем переданную функцию)
			if toggleGUIFunc then
				print("✅ Вызываем toggleGUI()...")
				toggleGUIFunc()
			else
				print("❌ Функция toggleGUI не передана!")
			end
		end
	end)

	print("✅ Иконка меню создана успешно!")
	return iconGui
end

-- Переключение видимости GUI (глобальная функция для доступа из createMenuIcon)
toggleGUI = function()
	print("🎯 toggleGUI вызван, mainGui:", mainGui ~= nil)

	if not mainGui then
		-- Создаем GUI если его нет
		print("📝 Создаем GUI...")
		mainGui = createMainGUI()
		if mainGui then
			isGuiVisible = true
			mainGui.Enabled = true
			print("✅ GUI создан и включен")

			-- Центрируем меню при создании
			local window = mainGui:FindFirstChild("MainWindow")
			if window then
				window.Position = UDim2.new(0.5, 0, 0.5, 0)
				window.AnchorPoint = Vector2.new(0.5, 0.5)
			end

			-- GUI создан со всеми категориями
			print("✅ GUI создан со всеми категориями")
		else
			print("❌ Ошибка: GUI не создан")
		end
	else
		-- Переключаем видимость
		isGuiVisible = not isGuiVisible
		mainGui.Enabled = isGuiVisible
		print("🔄 GUI переключен, видимость:", isGuiVisible)

		-- При открытии центрируем меню
		if isGuiVisible then
			local window = mainGui:FindFirstChild("MainWindow")
			if window then
				window.Position = UDim2.new(0.5, 0, 0.5, 0)
				window.AnchorPoint = Vector2.new(0.5, 0.5)
			end
		end
	end
end





-- Обработка ввода для открытия/закрытия GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == menuKeybind then
		print("Нажата клавиша:", menuKeybindName)
		toggleGUI()
	end
end)

print("=== FishItMenu загружен, нажмите G для открытия ===")

-- Создаем иконку меню сразу при запуске скрипта (передаем toggleGUI как параметр)
local menuIcon = createMenuIcon(toggleGUI)
if menuIcon then
	print("✅ Иконка меню создана и видна на экране")
else
	print("⚠️ Не удалось создать иконку меню")
end

-- Автоматически открываем меню и выбираем категорию Info при запуске
task.wait(0.5) -- Ждем небольшую задержку для полной инициализации
print("🚀 Автоматически открываем меню...")
toggleGUI()

-- Ждем создания GUI и затем выбираем категорию Info
task.wait(0.3)
if mainGui then
	local window = mainGui:FindFirstChild("MainWindow")
	if window then
		local leftPanel = window:FindFirstChild("LeftPanel")
		if leftPanel then
			-- Ищем кнопку категории Info
			for _, child in pairs(leftPanel:GetChildren()) do
				if child:IsA("TextButton") and child.Name == "InfoBtn" then
					print("✅ Найдена кнопка Info, симулируем клик...")
					-- Сбрасываем цвет всех кнопок
					for _, btn in pairs(leftPanel:GetChildren()) do
						if btn:IsA("TextButton") then
							btn.BackgroundTransparency = 0.9
							btn.TextColor3 = Color3.fromRGB(255, 255, 255)
						end
					end
					-- Подсвечиваем кнопку Info
					child.BackgroundTransparency = 0.7
					child.TextColor3 = Color3.fromRGB(0, 0, 0)
					-- Вызываем callback для загрузки содержимого категории Info
					if infoCategoryCallback then
						print("✅ Вызываем callback категории Info...")
						local rightPanel = window:FindFirstChild("RightPanel")
						if rightPanel then
							-- Очищаем правую панель
							for _, panelChild in pairs(rightPanel:GetChildren()) do
								if panelChild:IsA("Frame") or panelChild:IsA("TextLabel") or panelChild:IsA("TextButton") or panelChild:IsA("TextBox") then
									panelChild:Destroy()
								end
							end
							-- Загружаем содержимое Info (передаем rightPanel как параметр)
							infoCategoryCallback(rightPanel)
						end
					end
					break
				end
			end
		end
	end
end

print("✅ Меню автоматически открыто в категории Info!")

-- Основной цикл для применения настроек
RunService.RenderStepped:Connect(function()
	local character = Players.LocalPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Применяем Speed Hack
	if guiFunctions.speedHack then
		humanoid.WalkSpeed = guiFunctions.walkSpeed or 32
	else
		humanoid.WalkSpeed = 16
	end

	-- Применяем Jump Hack
	if guiFunctions.jumpHack and guiFunctions.jumpPower then
		humanoid.JumpPower = guiFunctions.jumpPower
	else
		humanoid.JumpPower = 50
	end

	-- Применяем Speed из Misc
	if guiFunctions.speed then
		humanoid.WalkSpeed = guiFunctions.speed
	end

	-- Применяем Noclip
	if guiFunctions.noclip then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end

	-- Применяем Airwalk
	if guiFunctions.airwalk then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Если есть зафиксированная высота, удерживаем на ней
			if airwalkTargetY then
				local currentY = hrp.Position.Y
				local yDifference = airwalkTargetY - currentY

				-- Применяем вертикальную скорость для удержания высоты
				if math.abs(yDifference) > 0.1 then
					hrp.AssemblyLinearVelocity = Vector3.new(
						hrp.AssemblyLinearVelocity.X,
						yDifference * 10, -- Скорость подъема/опускания
						hrp.AssemblyLinearVelocity.Z
					)
				else
					hrp.AssemblyLinearVelocity = Vector3.new(
						hrp.AssemblyLinearVelocity.X,
						0,
						hrp.AssemblyLinearVelocity.Z
					)
				end
			else
				-- Если высота не зафиксирована, просто предотвращаем падение
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {character}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude

				local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), raycastParams)
				if not rayResult then
					hrp.AssemblyLinearVelocity = Vector3.new(
						hrp.AssemblyLinearVelocity.X,
						0,
						hrp.AssemblyLinearVelocity.Z
					)
				end
			end
		end
	end
end)

-- Airwalk функции
local function enableAirwalk()
	local character = Players.LocalPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Сбрасываем целевую высоту
	airwalkTargetY = nil

	-- Отслеживаем прыжки для фиксации высоты
	if airwalkJumpConnection then
		airwalkJumpConnection:Disconnect()
	end

	airwalkJumpConnection = humanoid.Jumping:Connect(function()
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Запоминаем высоту прыжка
			airwalkTargetY = hrp.Position.Y
			print("Airwalk: Зафиксирована высота", airwalkTargetY)
		end
	end)
end

local function disableAirwalk()
	if airwalkJumpConnection then
		airwalkJumpConnection:Disconnect()
		airwalkJumpConnection = nil
	end
	airwalkTargetY = nil
end

-- AntiAFK функции
local function enableAntiAFK()
	if antiAFKConnection then
		antiAFKConnection:Disconnect()
	end

	local VirtualInputService = game:GetService("VirtualInputService")
	local RunService = game:GetService("RunService")

	-- Имитация активности каждые 2 минуты (120000 мс)
	-- Roblox кикает за AFK через 20 минут, но лучше делать чаще
	antiAFKConnection = task.spawn(function()
		while antiAFKEnabled do
			task.wait(120) -- Ждем 2 минуты

			if not antiAFKEnabled then break end

			-- Имитируем нажатие клавиши (например, W)
			pcall(function()
				VirtualInputService:SendKeyEvent(true, Enum.KeyCode.W, false, game)
				task.wait(0.1)
				VirtualInputService:SendKeyEvent(false, Enum.KeyCode.W, false, game)
			end)

			-- Также можно имитировать движение мыши
			pcall(function()
				VirtualInputService:SendMouseMoveEvent(1, 1, game)
				task.wait(0.1)
				VirtualInputService:SendMouseMoveEvent(-1, -1, game)
			end)

			print("🛡️ AntiAFK: Активность симулирована")
		end
	end)

	print("✅ AntiAFK включен!")
end

local function disableAntiAFK()
	antiAFKEnabled = false
	if antiAFKConnection then
		antiAFKConnection = nil
	end
	print("❌ AntiAFK выключен!")
end

-- Autorejoin функции
local function enableAutorejoin()
	if autorejoinConnection then
		autorejoinConnection:Disconnect()
	end

	autorejoinConnection = game:BindToClose(function()
		if autorejoinEnabled then
			local TeleportService = game:GetService("TeleportService")
			local Players = game:GetService("Players")

			-- Получаем ID текущего места
			local placeId = game.PlaceId

			-- Получаем ID текущего сервера (JobId)
			local jobId = game.JobId

			print("Autorejoin: Попытка переподключения к серверу", jobId)

			-- Пытаемся переподключиться к тому же серверу
			local success, errorMessage = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, Players.LocalPlayer)
			end)

			if not success then
				print("Autorejoin: Не удалось подключиться к тому же серверу, подключаемся к новому...")
				-- Если не удалось, подключаемся к новому серверу
				pcall(function()
					TeleportService:Teleport(placeId, Players.LocalPlayer)
				end)
			end
		end
	end)

	print("✅ Autorejoin включен!")
end

local function disableAutorejoin()
	if autorejoinConnection then
		autorejoinConnection:Disconnect()
		autorejoinConnection = nil
	end
	print("❌ Autorejoin выключен!")
end

-- AutoFish функция
local autoFishConnection = nil
local function startAutoFish()
	if autoFishConnection then return end

	autoFishConnection = task.spawn(function()
		while guiFunctions.autoFish do
			-- Здесь должна быть логика автоматической рыбалки
			-- Это зависит от структуры игры Fish It
			print("AutoFish активен...")
			task.wait(guiFunctions.caughtDelay or 1)
		end
		autoFishConnection = nil
	end)
end

local function stopAutoFish()
	guiFunctions.autoFish = false
	autoFishConnection = nil
end

-- AutoSell функция
local function sellFish()
	-- Здесь должна быть логика продажи рыбы
	-- Исключая рыбу из favoriteRarities
	print("AutoSell: Продаем рыбу...")
	for rarity, isFavorite in pairs(favoriteRarities) do
		if isFavorite then
			print("Пропускаем", rarity, "(в избранном)")
		else
			print("Продаем", rarity)
		end
	end
end



-- Webhook функция
local function sendWebhook(fishName, rarity)
	if webhookUrl == "" then return end

	local data = {
		["embeds"] = {
			{
				["title"] = "🎣 Новая рыба поймана!",
				["description"] = string.format("**Рыба:** %s\n**Редкость:** %s", fishName, rarity),
				["color"] = 3447003,
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}
		}
	}

	pcall(function()
		local response = HttpService:RequestAsync({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(data)
		})
		print("Webhook отправлен:", response.StatusCode)
	end)
end

-- Оптимизация графики V2 (новая версия с мыльной графикой)
local function enableOptimizationV2()
	if optimizationV2Active then return end
	optimizationV2Active = true

	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	-- Оптимизация освещения
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e9
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(140,140,140)
		Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140)
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
	end)

	-- Удаляем пост-эффекты, атмосферу и небо
	for _,v in ipairs(Lighting:GetChildren()) do
		if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
			v:Destroy()
		end
	end

	-- Создаем простое небо
	local sky = Instance.new("Sky")
	local SKY_ID = "rbxassetid://79747281250125"
	sky.SkyboxBk = SKY_ID
	sky.SkyboxDn = SKY_ID
	sky.SkyboxFt = SKY_ID
	sky.SkyboxLf = SKY_ID
	sky.SkyboxRt = SKY_ID
	sky.SkyboxUp = SKY_ID
	sky.SunAngularSize = 0
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.Parent = Lighting

	-- Функция для удаления эффектов
	local function removeEffect(obj)
		if obj:IsA("ParticleEmitter")
			or obj:IsA("Trail")
			or obj:IsA("Beam")
			or obj:IsA("Explosion")
			or obj:IsA("Smoke")
			or obj:IsA("Fire") then
			obj:Destroy()
		end
	end

	-- Функция для очистки частей
	local function cleanPart(part)
		part.CastShadow = false
		part.Reflectance = 0
		part.Material = Enum.Material.Plastic
		part.Color = Color3.fromRGB(150,150,150)
	end

	-- Очищаем все существующие объекты
	for _,obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			cleanPart(obj)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj:Destroy()
		else
			removeEffect(obj)
		end
	end

	-- Подключаемся к новым объектам
	local descendantConnection = Workspace.DescendantAdded:Connect(function(obj)
		if not optimizationV2Active then return end

		if obj:IsA("BasePart") then
			task.wait()
			cleanPart(obj)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj:Destroy()
		else
			removeEffect(obj)
		end
	end)
	table.insert(optimizationV2Connections, descendantConnection)

	-- Функция для очистки персонажей
	local function cleanCharacter(char)
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("Shirt")
				or v:IsA("Pants")
				or v:IsA("ShirtGraphic") then
				v:Destroy()
			elseif v:IsA("Decal") and v.Name == "face" then
				v:Destroy()
			elseif v:IsA("BasePart") then
				cleanPart(v)
			elseif v:IsA("Accessory") then
				local handle = v:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					cleanPart(handle)
				end
			end
		end
	end

	-- Очищаем всех игроков
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			cleanCharacter(plr.Character)
		end
		local charConnection = plr.CharacterAdded:Connect(function(char)
			if optimizationV2Active then
				cleanCharacter(char)
			end
		end)
		table.insert(optimizationV2Connections, charConnection)
	end

	-- Очищаем все модели с гуманоидами
	for _,model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildWhichIsA("Humanoid") then
			cleanCharacter(model)
		end
	end

	-- Устанавливаем минимальное качество
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

	print("✅ Optimization V2 enabled!")
end

local function disableOptimizationV2()
	optimizationV2Active = false

	-- Отключаем все соединения
	for _, connection in pairs(optimizationV2Connections) do
		if connection then
			connection:Disconnect()
		end
	end
	optimizationV2Connections = {}

	print("❌ Optimization V2 disabled!")
end

-- Оптимизация графики
local originalSettings = {}
local optimizationActive = false

local function enableOptimization()
	if optimizationActive then return end
	optimizationActive = true

	-- Сохраняем оригинальные настройки
	originalSettings = {
		QualityLevel = game:GetService("UserGameSettings").QualityLevel,
		SavesQuality = game:GetService("UserGameSettings").SavesQuality,
		ComputerQuality = game:GetService("UserGameSettings").ComputerQuality,
		GraphicsMode = game:GetService("UserGameSettings").GraphicsMode,
		FullScreen = game:GetService("UserGameSettings").FullScreen,
		VSync = game:GetService("UserGameSettings").VSync,
		Rendering = game:GetService("UserGameSettings").Rendering,
		EmissiveQuality = game:GetService("UserGameSettings").EmissiveQuality,
		QualityLevel = game:GetService("UserGameSettings").QualityLevel,
		SimulationQuality = game:GetService("UserGameSettings").SimulationQuality,
		MeshPartDetailLevel = game:GetService("UserGameSettings").MeshPartDetailLevel
	}

	-- Устанавливаем минимальные настройки графики
	local UserGameSettings = game:GetService("UserGameSettings")
	UserGameSettings.SavedQualityLevel = Enum.QualityLevel.Level01
	UserGameSettings.QualityLevel = Enum.QualityLevel.Level01
	UserGameSettings.SavesQuality = false
	UserGameSettings.ComputerQuality = Enum.ComputerQuality.Low
	UserGameSettings.GraphicsMode = Enum.GraphicsMode.Direct3D11
	UserGameSettings.FullScreen = false
	UserGameSettings.VSync = false
	UserGameSettings.Rendering = Enum.RenderingLevel.Level01
	UserGameSettings.EmissiveQuality = Enum.EmissiveQuality.Level01
	UserGameSettings.SimulationQuality = Enum.SimulationQuality.Level01
	UserGameSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Low

	-- МАКСИМАЛЬНАЯ оптимизация освещения (МЫЛЬНАЯ ГРАФИКА)
	local Lighting = game:GetService("Lighting")

	-- Отключаем ВСЕ тени (самое тяжелое для FPS)
	Lighting.GlobalShadows = false
	Lighting.ShadowSoftness = 0
	Lighting.ShadowBias = 0

	-- Убираем туман для производительности
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0

	-- Делаем освещение максимально простым (плоским)
	Lighting.Brightness = 1
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 0
	Lighting.Ambient = Color3.new(1, 1, 1) -- Максимально яркий ambient для плоского освещения
	Lighting.OutdoorAmbient = Color3.new(1, 1, 1)

	-- Отключаем все цветовые сдвиги
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	Lighting.ColorShift_Top = Color3.new(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.ExposureCompensation = 0

	-- Используем самую простую технологию рендеринга
	Lighting.Technology = Enum.Technology.Compatibility

	-- Отключаем атмосферные эффекты
	Lighting.Atmosphere.Density = 0
	Lighting.Atmosphere.Offset = 0
	Lighting.Atmosphere.Color = Color3.new(1, 1, 1)
	Lighting.Atmosphere.Decay = Color3.new(1, 1, 1)
	Lighting.Atmosphere.Glare = 0
	Lighting.Atmosphere.Haze = 0

	-- Удаляем ВСЕ пост-эффекты (Bloom, ColorCorrection, и т.д.)
	for _, child in pairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	-- Удаляем Skybox для производительности
	local Sky = Lighting:FindFirstChild("Sky")
	if Sky then
		Sky:Destroy()
	end

	-- Создаем простой черный Skybox
	local simpleSky = Instance.new("Sky")
	simpleSky.SkyboxBk = ""
	simpleSky.SkyboxDn = ""
	simpleSky.SkyboxFt = ""
	simpleSky.SkyboxLf = ""
	simpleSky.SkyboxRt = ""
	simpleSky.SkyboxUp = ""
	simpleSky.SunAngularSize = 0
	simpleSky.MoonAngularSize = 0
	simpleSky.StarCount = 0
	simpleSky.Parent = Lighting

	-- Оптимизация Workspace
	local Workspace = game:GetService("Workspace")

	-- Включаем стриминг для загрузки только близких объектов
	Workspace.StreamingEnabled = true
	Workspace.StreamingTargetRadius = 64 -- Загружаем только то, что рядом
	Workspace.StreamingMinRadius = 32
	Workspace.StreamingPauseMode = Enum.StreamingPauseMode.Default

	-- Отключаем физику для удаленных объектов
	Workspace.PhysicsEnvironmentalThrottle = Enum.PhysicsEnvironmentalThrottle.Aggressive
	Workspace.PhysicsSteppingMethod = Enum.PhysicsSteppingMethod.Fixed

	-- Отключаем детекторы столкновений для производительности
	Workspace.FallbackHumanoidRootPart = true

	-- Удаляем ненужные объекты из Workspace
	for _, obj in pairs(Workspace:GetChildren()) do
		if obj:IsA("Camera") or obj:IsA("Terrain") then
			continue
		end

		-- Удаляем декоративные объекты и пропсы
		if obj:IsA("Model") or obj:IsA("Folder") then
			-- Проверяем, не является ли это персонажем игрока
			local isPlayerCharacter = false
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character == obj then
					isPlayerCharacter = true
					break
				end
			end

			if not isPlayerCharacter then
				-- Удаляем декоративные объекты для повышения FPS
				local nameLower = obj.Name:lower()
				if nameLower:find("decor") or nameLower:find("prop") or nameLower:find("detail") or nameLower:find("furniture") or nameLower:find("plant") or nameLower:find("tree") or nameLower:find("bush") or nameLower:find("rock") or nameLower:find("grass") then
					obj:Destroy()
				end
			end
		end
	end

	-- МАКСИМАЛЬНАЯ оптимизация деталей (МЫЛЬНАЯ ГРАФИКА)
	for _, descendant in pairs(Workspace:GetDescendants()) do
		-- Заменяем ВСЕ материалы на Plastic (мыльный вид)
		if descendant:IsA("BasePart") then
			-- Заменяем материал на Plastic (самый простой)
			descendant.Material = Enum.Material.Plastic

			-- Убираем ВСЕ отражения и блеск
			descendant.Reflectance = 0
			descendant.Specular = 0

			-- Удаляем MaterialVariant если есть
			descendant.MaterialVariant = ""

			-- Делаем прозрачные объекты невидимыми для производительности
			if descendant.Transparency > 0.3 then
				descendant.Transparency = 1
			end

			-- Удаляем ВСЕ декали, текстуры и SurfaceAppearance
			for _, child in pairs(descendant:GetChildren()) do
				if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
		end

		-- Оптимизация MeshParts (делаем их мыльными)
		if descendant:IsA("MeshPart") then
			descendant.Material = Enum.Material.Plastic
			descendant.Reflectance = 0
			descendant.Specular = 0
			descendant.MaterialVariant = ""

			-- Удаляем текстурные карты
			descendant.TextureID = ""

			-- Удаляем декали и SurfaceAppearance
			for _, child in pairs(descendant:GetChildren()) do
				if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
		end

		-- Удаляем SpecialMesh для упрощения геометрии
		if descendant:IsA("SpecialMesh") then
			descendant:Destroy()
		end

		-- Удаляем частицы и эффекты
		if descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") or descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant:Destroy()
		end

		-- Удаляем весь свет (освещение делает графику тяжелой)
		if descendant:IsA("Light") then
			descendant:Destroy()
		end

		-- Отключаем звуки для производительности
		if descendant:IsA("Sound") then
			descendant.Volume = 0
			descendant.PlaybackSpeed = 0
		end

		-- Удаляем ненужные анимации
		if descendant:IsA("Animation") then
			descendant:Destroy()
		end

		-- Удаляем Constraint для оптимизации физики
		if descendant:IsA("Constraint") then
			descendant.Enabled = false
		end
	end

	-- Дополнительная оптимизация Terrain (земли)
	local Terrain = Workspace:FindFirstChild("Terrain")
	if Terrain then
		-- Делаем terrain максимально простым
		Terrain.MaterialColors = {
			[Enum.Material.Grass] = Color3.new(0.2, 0.5, 0.2),
			[Enum.Material.Sand] = Color3.new(0.8, 0.7, 0.5),
			[Enum.Material.Water] = Color3.new(0.2, 0.4, 0.8),
			[Enum.Material.Rock] = Color3.new(0.5, 0.5, 0.5),
			[Enum.Material.Mud] = Color3.new(0.4, 0.3, 0.2),
			[Enum.Material.Ground] = Color3.new(0.3, 0.3, 0.3)
		}

		-- Отключаем декорации на terrain
		Terrain.Decoration = false
	end

	-- Устанавливаем максимальный FPS
	game:GetService("RunService"):Set3dRenderingEnabled(true)

	-- Отключаем ненужные сервисы для производительности
	game:GetService("RunService").RenderStepped:Connect(function()
		-- Ничего не делаем, просто держим активным
	end)

	-- Оптимизация сетевого трафика
	game:GetService("NetworkClient"):SetOutgoingKBPSLimit(100)

	-- Отключаем анимации персонажей для производительности
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = false
			end
		end
	end

	print("✅ Оптимизация графики применена!")
end

local function disableOptimization()
	if not optimizationActive then return end
	optimizationActive = false

	-- Восстанавливаем оригинальные настройки
	local UserGameSettings = game:GetService("UserGameSettings")
	if originalSettings.QualityLevel then
		UserGameSettings.QualityLevel = originalSettings.QualityLevel
	end
	if originalSettings.SavesQuality ~= nil then
		UserGameSettings.SavesQuality = originalSettings.SavesQuality
	end
	if originalSettings.ComputerQuality then
		UserGameSettings.ComputerQuality = originalSettings.ComputerQuality
	end
	if originalSettings.GraphicsMode then
		UserGameSettings.GraphicsMode = originalSettings.GraphicsMode
	end
	if originalSettings.FullScreen ~= nil then
		UserGameSettings.FullScreen = originalSettings.FullScreen
	end
	if originalSettings.VSync ~= nil then
		UserGameSettings.VSync = originalSettings.VSync
	end
	if originalSettings.Rendering then
		UserGameSettings.Rendering = originalSettings.Rendering
	end
	if originalSettings.EmissiveQuality then
		UserGameSettings.EmissiveQuality = originalSettings.EmissiveQuality
	end
	if originalSettings.SimulationQuality then
		UserGameSettings.SimulationQuality = originalSettings.SimulationQuality
	end
	if originalSettings.MeshPartDetailLevel then
		UserGameSettings.MeshPartDetailLevel = originalSettings.MeshPartDetailLevel
	end

	-- Восстанавливаем освещение
	local Lighting = game:GetService("Lighting")
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 1000
	Lighting.FogStart = 0
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 41.33
	Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
	Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ShadowSoftness = 1
	Lighting.ShadowBias = 0.15

	-- Восстанавливаем Workspace
	local Workspace = game:GetService("Workspace")
	Workspace.StreamingEnabled = true
	Workspace.StreamingTargetRadius = 1024
	Workspace.StreamingMinRadius = 64
	Workspace.StreamingPauseMode = Enum.StreamingPauseMode.Default

	print("✅ Настройки графики восстановлены!")
end

-- Мониторинг для AutoSell
RunService.Heartbeat:Connect(function()
	if guiFunctions.autoSell then
		-- Проверяем инвентарь и продаем рыбу
		-- Это зависит от структуры игры Fish It
	end
end)

-- Авто-покупка погоды
local function buyWeather(weatherName)
	local MarketplaceService = game:GetService("MarketplaceService")
	local productId = weatherProductIds[weatherName]

	if productId == 0 then
		print("⚠️ Product ID для " .. weatherName .. " не установлен!")
		print("Пожалуйста, установите правильный Product ID в weatherProductIds")
		print("Или откройте магазин и нажмите на погоду, чтобы автоматически определить ID")
		return false
	end

	local success, result = pcall(function()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
	end)

	if success then
		print("✅ Покупка " .. weatherName .. " инициирована (Product ID: " .. productId .. ")")
		return true
	else
		print("❌ Ошибка при покупке " .. weatherName .. ":", result)
		return false
	end
end

-- Автоматическое определение Product IDs из GUI магазина
local function detectWeatherProductIds()
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local merchantGui = playerGui:FindFirstChild("Merchant")
	if not merchantGui then return end

	local main = merchantGui:FindFirstChild("Main")
	if not main then return end

	-- Ищем кнопки погоды в GUI
	local weatherButtons = {
		["Wind"] = nil,
		["Cloudy"] = nil,
		["Snow"] = nil,
		["Storm"] = nil,
		["Shining"] = nil,
		["SharkHunt"] = nil
	}

	-- Проходим по всем потомкам и ищем кнопки с названиями погоды
	for _, descendant in pairs(main:GetDescendants()) do
		if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
			local text = descendant.Text or ""
			local name = descendant.Name or ""

			-- Проверяем по названию или тексту кнопки
			for weatherName, _ in pairs(weatherButtons) do
				if string.find(text:lower(), weatherName:lower()) or string.find(name:lower(), weatherName:lower()) then
					weatherButtons[weatherName] = descendant
					print("🔍 Найдена кнопка для " .. weatherName .. ":", descendant:GetFullName())

					-- Пытаемся найти Product ID в атрибутах или свойствах
					local productId = descendant:GetAttribute("ProductId") or 
						descendant:GetAttribute("ProductID") or
						descendant:GetAttribute("ProductIdValue")

					if productId then
						weatherProductIds[weatherName] = tonumber(productId)
						print("✅ Product ID для " .. weatherName .. ":", productId)
					end
				end
			end
		end
	end

	-- Если не нашли Product IDs, пробуем другой метод
	local foundAny = false
	for weatherName, productId in pairs(weatherProductIds) do
		if productId ~= 0 then
			foundAny = true
			break
		end
	end

	if not foundAny then
		print("⚠️ Не удалось автоматически определить Product IDs")
		print("💡 Попробуйте открыть магазин и нажать на кнопку погоды вручную")
	end
end

-- Подключаемся к открытию магазина для автоматического определения Product IDs
Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	detectWeatherProductIds()
end)

-- Запускаем определение при загрузке
task.wait(2)
detectWeatherProductIds()

local function startAutoBuyWeather(weatherName)
	-- Останавливаем предыдущее соединение если есть
	if weatherConnections[weatherName] then
		weatherConnections[weatherName]:Disconnect()
		weatherConnections[weatherName] = nil
	end

	-- Запускаем новый цикл авто-покупки
	weatherConnections[weatherName] = task.spawn(function()
		while autoWeatherEnabled[weatherName] do
			-- Покупаем погоду
			buyWeather(weatherName)

			-- Ждем перед следующей покупкой (5 секунд)
			task.wait(5)
		end

		print("🛑 Авто-покупка " .. weatherName .. " остановлена")
	end)

	print("🚀 Авто-покупка " .. weatherName .. " запущена")
end

local function stopAutoBuyWeather(weatherName)
	-- Останавливаем соединение
	if weatherConnections[weatherName] then
		weatherConnections[weatherName]:Disconnect()
		weatherConnections[weatherName] = nil
	end

	print("🛑 Авто-покупка " .. weatherName .. " остановлена")
end

print("🎣 Fish It Menu [ScriptHub X] загружен! Нажмите G чтобы открыть меню.")
