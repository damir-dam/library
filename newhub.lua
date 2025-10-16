-- newhub.lua (Версия 3.0 - Полностью переписанная с улучшениями)
-- Улучшения: 
-- - Keybind: Клик на кнопку -> жди нажатие клавиши -> сохрани и toggle GUI на неё (плавно).
-- - Slider: Независимое перетаскивание ползунка (не двигает GUI). GUI draggable только по заголовку.
-- - Dropdown: Улучшенный (плавная анимация, ScrollingFrame для списка, "матание" вверх/вниз = прокрутка).
-- - Scrolling для секций: Если >5 элементов, добавляется ScrollingFrame в секцию (листать вверх/вниз).
-- - Название хаба: lib("Твоё Название") — использует как заголовок.
-- - Размер GUI: Увеличен (500x400).
-- - Новогоднее: Красный фон (градиент красный-белый), падающие снежинки (анимация TweenService, респавн).
-- - Тема: Тёмная с новогодними акцентами (красный/зелёный/белый).
-- - Анимации: Плавные для всего (открытие/закрытие, hover, drag).
-- - Key для toggle: По умолчанию K, но переопределяется keybind.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Library = {}
local Connections = {}

-- Создаём ScreenGui
local function CreateScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NewHub"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Новогодний фон: Красный градиент (красный сверху, белый снизу)
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(1, 0.2, 0.2)  -- Красный
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),  -- Красный сверху
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))   -- Белый снизу
    }
    gradient.Rotation = 90
    gradient.Parent = background
    
    -- Падающие снежинки (новогоднее)
    local snowflakes = {}
    for i = 1, 20 do  -- 20 снежинок
        local snow = Instance.new("ImageLabel")
        snow.Name = "Snowflake" .. i
        snow.Size = UDim2.new(0, 10 + math.random(0, 10), 0, 10 + math.random(0, 10))
        snow.Position = UDim2.new(math.random(0, 100)/100, 0, -0.1, 0)
        snow.BackgroundTransparency = 1
        snow.Image = "rbxasset://textures/particles/sparkles_main.dds"  -- Снежинка (или загрузи кастомную)
        snow.ImageColor3 = Color3.new(1, 1, 1)
        snow.ImageTransparency = 0.3
        snow.Parent = screenGui
        
        -- Анимация падения
        local fallTween = TweenService:Create(snow, TweenInfo.new(5 + math.random(0, 5), Enum.EasingStyle.Linear), {
            Position = UDim2.new(math.random(0, 100)/100, 0, 1.1, 0),
            Rotation = math.random(-180, 180)
        })
        fallTween:Play()
        fallTween.Completed:Connect(function()
            snow.Position = UDim2.new(math.random(0, 100)/100, 0, -0.1, 0)
            fallTween:Play()  -- Респавн
        end)
        
        table.insert(snowflakes, snow)
    end
    
    return screenGui
end

-- MainFrame с draggable только по заголовку
local function CreateMainFrame(screenGui, hubName)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)  -- Увеличенный размер
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)  -- Тёмный
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Заголовок (draggable)
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.new(0.8, 0, 0)  -- Красный акцент
    title.BorderSizePixel = 0
    title.Text = hubName or "Hub"  -- Название из lib("Name")
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Draggable только title
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    title.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- TabBar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 40)
    tabBar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = mainFrame
    
    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.Padding = UDim.new(0, 5)
    tabList.Parent = tabBar
    
    -- Container для табов (ScrollingFrame для контента)
    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, -80)
    container.Position = UDim2.new(0, 0, 0, 80)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 8
    container.ScrollBarImageColor3 = Color3.new(0.8, 0, 0)  -- Красный скролл
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.Parent = mainFrame
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.FillDirection = Enum.FillDirection.Vertical
    containerLayout.Padding = UDim.new(0, 5)
    containerLayout.Parent = container
    
    containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Кнопка закрытия (в углу)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.new(1, 0, 0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = title
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
    end)
    
    return mainFrame, tabBar, container
end

-- Создание таба
local function CreateTab(hub, name)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(0, 100, 1, 0)
    tabButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    tabButton.Text = name
    tabButton.TextColor3 = Color3.new(1, 1, 1)
    tabButton.TextScaled = true
    tabButton.Font = Enum.Font.Gotham
    tabButton.BorderSizePixel = 0
    tabButton.Parent = hub.TabBar
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 4)
    tabCorner.Parent = tabButton
    
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = name .. "Frame"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = hub.Container
    
    -- Hover анимация
    tabButton.MouseEnter:Connect(function()
        TweenService:Create(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.8, 0, 0)}):Play()
    end)
    tabButton.MouseLeave:Connect(function()
        TweenService:Create(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)}):Play()
    end)
    
    -- Смена таба
    local currentTab = nil
    tabButton.MouseButton1Click:Connect(function()
        if currentTab then
            currentTab.Visible = false
            TweenService:Create(currentTab, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            wait(0.3)
            currentTab.Size = UDim2.new(1, 0, 1, 0)
        end
        currentTab = tabFrame
        tabFrame.Visible = true
        TweenService:Create(tabFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    end)
    
    -- Первый таб открывается
    if #hub.Container:GetChildren() == 1 then  -- Только containerLayout
        tabButton.MouseButton1Click:Fire()
    end
    
    return {
        NewSection = function(self, name)
            local section = Instance.new("ScrollingFrame")  -- Scrolling для элементов (если много)
            section.Name = name .. "Section"
            section.Size = UDim2.new(1, -20, 0, 200)  -- Авто-высота, но с прокруткой
            section.Position = UDim2.new(0, 10, 0, 10)
            section.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
            section.BorderSizePixel = 0
            section.ScrollBarThickness = 6
            section.ScrollBarImageColor3 = Color3.new(0, 1, 0)  -- Зелёный скролл
            section.CanvasSize = UDim2.new(0, 0, 0, 0)
            section.Parent = tabFrame
            
            local secCorner = Instance.new("UICorner")
            secCorner.CornerRadius = UDim.new(0, 4)
            secCorner.Parent = section
            
            local secHeader = Instance.new("TextLabel")
            secHeader.Name = "Header"
            secHeader.Size = UDim2.new(1, 0, 0, 30)
            secHeader.Position = UDim2.new(0, 0, 0, 0)
            secHeader.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
            secHeader.Text = name
            secHeader.TextColor3 = Color3.new(1, 1, 1)
            secHeader.TextScaled = true
            secHeader.Font = Enum.Font.GothamBold
            secHeader.BorderSizePixel = 0
            secHeader.Parent = section
            
            local headerCorner = Instance.new("UICorner")
            headerCorner.CornerRadius = UDim.new(0, 4)
            headerCorner.Parent = secHeader
            
            local elementList = Instance.new("UIListLayout")
            elementList.FillDirection = Enum.FillDirection.Vertical
            elementList.Padding = UDim.new(0, 5)
            elementList.Parent = section
            elementList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.CanvasSize = UDim2.new(0, 0, 0, elementList.AbsoluteContentSize.Y + 10)
                if elementList.AbsoluteContentSize.Y > 150 then  -- Если много, показываем скролл
                    section.ScrollBarImageTransparency = 0
                end
            end)
            
            -- Элементы
            return {
                NewButton = function(self, text, callback)
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.BackgroundColor3 = Color3.new(0, 0.8, 0)  -- Зелёный
                    btn.Text = text
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.TextScaled = true
                    btn.Font = Enum.Font.Gotham
                    btn.BorderSizePixel = 0
                    btn.Parent = section
                    
                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 4)
                    btnCorner.Parent = btn
                    
                    btn.MouseButton1Click:Connect(callback)
                    
                    -- Hover
                    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0, 1, 0)}):Play() end)
                    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0, 0.8, 0)}):Play() end)
                    
                    return btn
                end,
                
                NewToggle = function(self, text, default, callback)
                    local toggleFrame = Instance.new("Frame")
                    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
                    toggleFrame.BackgroundTransparency = 1
                    toggleFrame.Parent = section
                    
                    local toggleLabel = Instance.new("TextLabel")
                    toggleLabel.Size = UDim2.new(1, -50, 1, 0)
                    toggleLabel.BackgroundTransparency = 1
                    toggleLabel.Text = text
                    toggleLabel.TextColor3 = Color3.new(1, 1, 1)
                    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    toggleLabel.TextScaled = true
                    toggleLabel.Font = Enum.Font.Gotham
                    toggleLabel.Parent = toggleFrame
                    
                    local toggleBtn = Instance.new("TextButton")
                    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
                    toggleBtn.Position = UDim2.new(1, -45, 0.5, -10)
                    toggleBtn.BackgroundColor3 = default and Color3.new(0, 0.8, 0) or Color3.new(0.8, 0, 0)
                    toggleBtn.Text = ""
                    toggleBtn.BorderSizePixel = 0
                    toggleBtn.Parent = toggleFrame
                    
                    local toggleCorner = Instance.new("UICorner")
                    toggleCorner.CornerRadius = UDim.new(0, 10)
                    toggleCorner.Parent = toggleBtn
                    
                    local state = default
                    toggleBtn.MouseButton1Click:Connect(function()
                        state = not state
                        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.new(0, 0.8, 0) or Color3.new(0.8, 0, 0)}):Play()
                        callback(state)
                    end)
                    
                    return toggleFrame
                end,
                
                NewSlider = function(self, text, min, max, default, callback)
                    local sliderFrame = Instance.new("Frame")
                    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
                    sliderFrame.BackgroundTransparency = 1
                    sliderFrame.Parent = section
                    
                    local sliderLabel = Instance.new("TextLabel")
                    sliderLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    sliderLabel.BackgroundTransparency = 1
                    sliderLabel.Text = text .. ": " .. default
                    sliderLabel.TextColor3 = Color3.new(1, 1, 1)
                    sliderLabel.TextScaled = true
                    sliderLabel.Font = Enum.Font.Gotham
                    sliderLabel.Parent = sliderFrame
                    
                    local sliderBar = Instance.new("Frame")
                    sliderBar.Size = UDim2.new(1, 0, 0, 10)
                    sliderBar.Position = UDim2.new(0, 0, 0.5, 0)
                    sliderBar.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
                    sliderBar.BorderSizePixel = 0
                    sliderBar.Parent = sliderFrame
                    
                    local sliderCorner = Instance.new("UICorner")
                    sliderCorner.CornerRadius = UDim.new(0, 5)
                    sliderCorner.Parent = sliderBar
                    
                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                    fill.BackgroundColor3 = Color3.new(0, 0.8, 0)
                    fill.BorderSizePixel = 0
                    fill.Parent = sliderBar
                    
                    local fillCorner = Instance.new("UICorner")
                    fillCorner.CornerRadius = UDim.new(0, 5)
                    fillCorner.Parent = fill
                    
                    local knob = Instance.new("TextButton")
                    knob.Size = UDim2.new(0, 20, 0, 20)
                    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
                    knob.BackgroundColor3 = Color3.new(1, 1, 1)
                    knob.Text = ""
                    knob.BorderSizePixel = 0
                    knob.Parent = sliderBar
                    
                    local knobCorner = Instance.new("UICorner")
                    knobCorner.CornerRadius = UDim.new(0.5, 0)
                    knobCorner.Parent = knob
                    
                    local draggingSlider = false
                    local value = default
                    
                    knob.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            draggingSlider = true
                        end
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            draggingSlider = false
                        end
                    end)
                    
                    RunService.Heartbeat:Connect(function()
                        if draggingSlider then
                            local mouse = UserInputService:GetMouseLocation()
                            local barAbsPos = sliderBar.AbsolutePosition
                            local barAbsSize = sliderBar.AbsoluteSize.X
                            local relPos = math.clamp((mouse.X - barAbsPos.X) / barAbsSize, 0, 1)
                            value = math.floor(min + (max - min) * relPos)
                            
                            fill.Size = UDim2.new(relPos, 0, 1, 0)
                            knob.Position = UDim2.new(relPos, -10, 0.5, -10)
                            sliderLabel.Text = text .. ": " .. value
                            callback(value)
                        end
                    end)
                    
                    return sliderFrame
                end,
                
                NewDropdown = function(self, text, options, default, callback)
                    local dropFrame = Instance.new("Frame")
                    dropFrame.Size = UDim2.new(1, 0, 0, 40)
                    dropFrame.BackgroundTransparency = 1
                    dropFrame.Parent = section
                    
                    local dropLabel = Instance.new("TextLabel")
                    dropLabel.Size = UDim2.new(1, -100, 0.5, 0)
                    dropLabel.BackgroundTransparency = 1
                    dropLabel.Text = text
                    dropLabel.TextColor3 = Color3.new(1, 1, 1)
                    dropLabel.TextXAlignment = Enum.TextXAlignment.Left
                    dropLabel.TextScaled = true
                    dropLabel.Font = Enum.Font.Gotham
                    dropLabel.Parent = dropFrame
                    
                    local dropButton = Instance.new("TextButton")
                    dropButton.Size = UDim2.new(0, 100, 0.5, 0)
                    dropButton.Position = UDim2.new(1, -105, 0, 0)
                    dropButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
                    dropButton.Text = default or options[1] or "None"
                    dropButton.TextColor3 = Color3.new(1, 1, 1)
                    dropButton.TextScaled = true
                    dropButton.Font = Enum.Font.Gotham
                    dropButton.BorderSizePixel = 0
                    dropButton.Parent = dropFrame
                    
                    local dropCorner = Instance.new("UICorner")
                    dropCorner.CornerRadius = UDim.new(0, 4)
                    dropCorner.Parent = dropButton
                    
                    local listFrame = Instance.new("ScrollingFrame")  -- Улучшенный с прокруткой (матание вверх/вниз)
                    listFrame.Name = "DropdownList"
                    listFrame.Size = UDim2.new(0, 100, 0, 0)
                    listFrame.Position = UDim2.new(1, -105, 0.5, 0)
                    listFrame.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
                    listFrame.BorderSizePixel = 0
                    listFrame.ScrollBarThickness = 4
                    listFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
                    listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
                    listFrame.Visible = false
                    listFrame.Parent = dropFrame
                    
                    local listCorner = Instance.new("UICorner")
                    listCorner.CornerRadius = UDim.new(0, 4)
                    listCorner.Parent = listFrame
                    
                    local listLayout = Instance.new("UIListLayout")
                    listLayout.FillDirection = Enum.FillDirection.Vertical
                    listLayout.Padding = UDim.new(0, 0)
                    listLayout.Parent = listFrame
                    
                    local isOpen = false
                    local selected = default or options[1]
                    
                    -- Создаём опции
                    for i, opt in ipairs(options) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 30)
                        optBtn.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
                        optBtn.Text = opt
                        optBtn.TextColor3 = Color3.new(1, 1, 1)
                        optBtn.TextScaled = true
                        optBtn.Font = Enum.Font.Gotham
                        optBtn.BorderSizePixel = 0
                        optBtn.Parent = listFrame
                        
                        local optCorner = Instance.new("UICorner")
                        optCorner.CornerRadius = UDim.new(0, 2)
                        optCorner.Parent = optBtn
                        
                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            dropButton.Text = opt
                            callback(opt)
                            isOpen = false
                            TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 100, 0, 0)}):Play()
                            listFrame.Visible = false
                        end)
                    end
                    
                    dropButton.MouseButton1Click:Connect(function()
                        isOpen = not isOpen
                        if isOpen then
                            listFrame.Visible = true
                            TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 100, 0, math.min(#options * 30, 150))}):Play()  -- Макс 150 высоты
                        else
                            TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 100, 0, 0)}):Play()
                            wait(0.2)
                            listFrame.Visible = false
                        end
                    end)
                    
                    return dropFrame
                end,
                
                NewKeybind = function(self, text, defaultKey, callback)
                    local keyFrame = Instance.new("Frame")
                    keyFrame.Size = UDim2.new(1, 0, 0, 30)
                    keyFrame.BackgroundTransparency = 1
                    keyFrame.Parent = section
                    
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(1, -100, 1, 0)
                    keyLabel.BackgroundTransparency = 1
                    keyLabel.Text = text
                    keyLabel.TextColor3 = Color3.new(1, 1, 1)
                    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    keyLabel.TextScaled = true
                    keyLabel.Font = Enum.Font.Gotham
                    keyLabel.Parent = keyFrame
                    
                    local keyButton = Instance.new("TextButton")
                    keyButton.Size = UDim2.new(0, 80, 0, 25)
                    keyButton.Position = UDim2.new(1, -85, 0, 2.5)
                    keyButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
                    keyButton.Text = defaultKey and defaultKey.Name or "None"
                    keyButton.TextColor3 = Color3.new(1, 1, 1)
                    keyButton.TextScaled = true
                    keyButton.Font = Enum.Font.Gotham
                    keyButton.BorderSizePixel = 0
                    keyButton.Parent = keyFrame
                    
                    local keyCorner = Instance.new("UICorner")
                    keyCorner.CornerRadius = UDim.new(0, 4)
                    keyCorner.Parent = keyButton
                    
                    local binding = false
                    local currentKey = defaultKey or Enum.KeyCode.K  -- По умолчанию K
                    
                    -- Система keybind
                    keyButton.MouseButton1Click:Connect(function()
                        binding = true
                        keyButton.Text = "Press a key..."
                        keyButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0)  -- Жёлтый для ожидания
                    end)
                    
                    local bindConnection
                    bindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if binding and not gameProcessed and input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentKey = input.KeyCode
                            keyButton.Text = currentKey.Name
                            keyButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
                            binding = false
                            bindConnection:Disconnect()
                            
                            -- Удаляем старый connection, если есть
                            if Connections[currentKey] then
                                Connections[currentKey]:Disconnect()
                            end
                            
                            -- Новый toggle на клавишу (плавно открывает/закрывает)
                            Connections[currentKey] = UserInputService.InputBegan:Connect(function(inp)
                                if inp.KeyCode == currentKey then
                                    local visible = hub.MainFrame.Visible
                                    if visible then
                                        -- Закрытие
                                        local closeTween = TweenService:Create(hub.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)})
                                        closeTween:Play()
                                        closeTween.Completed:Connect(function()
                                            hub.MainFrame.Visible = false
                                        end)
                                    else
                                        -- Открытие
                                        hub.MainFrame.Visible = true
                                        hub.MainFrame.Size = UDim2.new(0, 0, 0, 0)
                                        local openTween = TweenService:Create(hub.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 500, 0, 400)})
                                        openTween:Play()
                                    end
                                    callback(currentKey)  -- Callback с клавишей
                                end
                            end)
                        end
                    end)
                    
                    -- Инициализация default key
                    if defaultKey then
                        Connections[defaultKey] = UserInputService.InputBegan:Connect(function(inp)
                            if inp.KeyCode == defaultKey then
                                -- Toggle логика как выше
                                local visible = hub.MainFrame.Visible
                                if visible then
                                    local closeTween = TweenService:Create(hub.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)})
                                    closeTween:Play()
                                    closeTween.Completed:Connect(function()
                                        hub.MainFrame.Visible = false
                                    end)
                                else
                                    hub.MainFrame.Visible = true
                                    hub.MainFrame.Size = UDim2.new(0, 0, 0, 0)
                                    local openTween = TweenService:Create(hub.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 500, 0, 400)})
                                    openTween:Play()
                                end
                            end
                        end)
                    end
                    
                    return keyFrame
                end
            }
        end
    }
end

-- Основная функция библиотеки
local function CreateHub(hubName)
    local screenGui = CreateScreenGui()
    local mainFrame, tabBar, container = CreateMainFrame(screenGui, hubName)
    
    local hub = {
        MainFrame = mainFrame,
        TabBar = tabBar,
        Container = container,
        ScreenGui = screenGui,
        Toggle = function(self, open)
            if open then
                self.MainFrame.Visible = true
                self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
                TweenService:Create(self.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 500, 0, 400)}):Play()
            else
                TweenService:Create(self.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                wait(0.3)
                self.MainFrame.Visible = false
            end
        end,
        Open = function(self)
            self:Toggle(true)
        end,
        Close = function(self)
            self:Toggle(false)
        end,
        NewTab = function(self, name)
            return CreateTab(self, name)
        end
    }
    
    -- По умолчанию закрыт
    mainFrame.Visible = false
    
    -- Глобальный keybind на K (если не переопределён)
    local defaultBind = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.K then
            hub:Toggle(not mainFrame.Visible)
        end
    end)
    
    table.insert(Connections, defaultBind)
    
    return hub
end

-- Возвращаем функцию для lib("Name")
return function(name)
    return function()
        return CreateHub(name)
    end
end
