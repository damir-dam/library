-- newhub.lua: Обновлённая UI Библиотека для Roblox
-- Автор: AI Assistant (на основе твоих требований)
-- Версия: 2.0 (с Keybind настройкой, исправленными табами и овальным тоглом)
-- Использование: local lib = loadstring(game:HttpGet("..."))("My Hub")

local createLib = function(name)
    local lib = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    
    -- Переменные
    lib.Name = name
    lib.Visible = false
    lib.Tabs = {}
    lib.CurrentTab = nil
    lib.Keybind = Enum.KeyCode.K  -- По умолчанию K для toggle (как в верхнем табе)
    lib.Connections = {}
    
    -- Создание ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = lib.Name .. "Gui"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- MainFrame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Visible = false
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.Thickness = 1
    Stroke.Parent = MainFrame
    
    -- Заголовок
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.Size = UDim2.new(1, -100, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = lib.Name
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Мини-кнопка для Keybind (сверху справа, текст "Open")
    local KeybindButton = Instance.new("TextButton")
    KeybindButton.Name = "KeybindButton"
    KeybindButton.Parent = MainFrame
    KeybindButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    KeybindButton.BorderSizePixel = 0
    KeybindButton.Position = UDim2.new(1, -40, 0, 5)
    KeybindButton.Size = UDim2.new(0, 30, 0, 30)
    KeybindButton.Font = Enum.Font.Gotham
    KeybindButton.Text = "Open"  -- Изменено на "Open" (как "открыть")
    KeybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindButton.TextSize = 10  -- Уменьшен для "Open"
    
    local KeybindCorner = Instance.new("UICorner")
    KeybindCorner.CornerRadius = UDim.new(0, 4)
    KeybindCorner.Parent = KeybindButton
    
    local KeybindStroke = Instance.new("UIStroke")
    KeybindStroke.Color = Color3.fromRGB(100, 100, 100)
    KeybindStroke.Thickness = 1
    KeybindStroke.Parent = KeybindButton
    
    -- Keybind Окно (модальное, скрыто по умолчанию)
    local KeybindWindow = Instance.new("Frame")
    KeybindWindow.Name = "KeybindWindow"
    KeybindWindow.Parent = MainFrame
    KeybindWindow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KeybindWindow.BorderSizePixel = 0
    KeybindWindow.Position = UDim2.new(0.5, -100, 0.5, -50)
    KeybindWindow.Size = UDim2.new(0, 200, 0, 100)
    KeybindWindow.Visible = false
    KeybindWindow.Active = true
    KeybindWindow.Draggable = true
    
    local KWCorner = Instance.new("UICorner")
    KWCorner.CornerRadius = UDim.new(0, 6)
    KWCorner.Parent = KeybindWindow
    
    local KWStroke = Instance.new("UIStroke")
    KWStroke.Color = Color3.fromRGB(255, 255, 255)
    KWStroke.Thickness = 1
    KWStroke.Parent = KeybindWindow
    
    local KWTitle = Instance.new("TextLabel")
    KWTitle.Parent = KeybindWindow
    KWTitle.BackgroundTransparency = 1
    KWTitle.Position = UDim2.new(0, 10, 0, 5)
    KWTitle.Size = UDim2.new(1, -20, 0, 20)
    KWTitle.Font = Enum.Font.Gotham
    KWTitle.Text = "Set Keybind (for Open/Close UI)"  -- Изменено на "Open/Close"
    KWTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    KWTitle.TextSize = 12
    KWTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local KWTextBox = Instance.new("TextBox")
    KWTextBox.Parent = KeybindWindow
    KWTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    KWTextBox.BorderSizePixel = 0
    KWTextBox.Position = UDim2.new(0, 10, 0, 30)
    KWTextBox.Size = UDim2.new(1, -20, 0, 25)
    KWTextBox.Font = Enum.Font.Gotham
    KWTextBox.PlaceholderText = "Enter key (e.g., Insert, Delete)"
    KWTextBox.Text = tostring(lib.Keybind)
    KWTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KWTextBox.TextSize = 12
    
    local KWCornerTB = Instance.new("UICorner")
    KWCornerTB.CornerRadius = UDim.new(0, 4)
    KWCornerTB.Parent = KWTextBox
    
    local KWSetButton = Instance.new("TextButton")
    KWSetButton.Parent = KeybindWindow
    KWSetButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    KWSetButton.BorderSizePixel = 0
    KWSetButton.Position = UDim2.new(0, 10, 0, 60)
    KWSetButton.Size = UDim2.new(0.45, -5, 0, 25)
    KWSetButton.Font = Enum.Font.Gotham
    KWSetButton.Text = "Open"  -- Изменено на "Open"
    KWSetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    KWSetButton.TextSize = 12
    
    local KWSetCorner = Instance.new("UICorner")
    KWSetCorner.CornerRadius = UDim.new(0, 4)
    KWSetCorner.Parent = KWSetButton
    
    local KWCloseButton = Instance.new("TextButton")
    KWCloseButton.Parent = KeybindWindow
    KWCloseButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    KWCloseButton.BorderSizePixel = 0
    KWCloseButton.Position = UDim2.new(0.55, 0, 0, 60)
    KWCloseButton.Size = UDim2.new(0.45, -15, 0, 25)
    KWCloseButton.Font = Enum.Font.Gotham
    KWCloseButton.Text = "Close"  -- Уже "Close"
    KWCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    KWCloseButton.TextSize = 12
    
    local KWCloseCorner = Instance.new("UICorner")
    KWCloseCorner.CornerRadius = UDim.new(0, 4)
    KWCloseCorner.Parent = KWCloseButton
    
    -- Таббар (горизонтальный сверху)
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = MainFrame
    TabBar.BackgroundTransparency = 1
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.Size = UDim2.new(1, 0, 0, 30)
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabBar
    
    -- Контейнер для секций (ScrollingFrame)
    local Container = Instance.new("ScrollingFrame")
    Container.Name = "Container"
    Container.Parent = MainFrame
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Position = UDim2.new(0, 0, 0, 70)
    Container.Size = UDim2.new(1, 0, 1, -70)
    Container.ScrollBarThickness = 6
    Container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    
    local ContainerLayout = Instance.new("UIListLayout")
    ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContainerLayout.Padding = UDim.new(0, 5)
    ContainerLayout.Parent = Container
    
    -- Функция для обновления размера контейнера
    local function updateContainerSize()
        Container.CanvasSize = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 10)
    end
    ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContainerSize)
    
    -- Функция создания таба
    function lib:NewTab(name)
        local tab = {Name = name, Sections = {}, TabButton = nil, Content = nil}
        
        -- Кнопка таба
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Parent = TabBar
        TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Чёрный неактивный
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(0, 80, 1, 0)
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextSize = 12
        TabButton.LayoutOrder = #lib.Tabs + 1
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton
        
        -- Контент таба (Frame для секций)
        local Content = Instance.new("Frame")
        Content.Name = name .. "Content"
        Content.Parent = Container
        Content.BackgroundTransparency = 1
        Content.Size = UDim2.new(1, 0, 0, 0)
        Content.Visible = false
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 5)
        ContentLayout.Parent = Content
        
        tab.TabButton = TabButton
        tab.Content = Content
        table.insert(lib.Tabs, tab)
        
        -- Функция переключения таба
        local function switchToTab()
            if lib.CurrentTab then
                lib.CurrentTab.TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Чёрный
                lib.CurrentTab.TabButton.UIStroke:Destroy()  -- Убрать обводку
                lib.CurrentTab.Content.Visible = false
            end
            lib.CurrentTab = tab
            tab.TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Серый активный
            local newStroke = Instance.new("UIStroke")
            newStroke.Color = Color3.fromRGB(255, 255, 255)
            newStroke.Thickness = 1
            newStroke.Parent = tab.TabButton
            tab.Content.Visible = true
            updateContainerSize()
        end
        
        TabButton.MouseButton1Click:Connect(switchToTab)
        
        -- Функция создания секции
        function tab:NewSection(name)
            local section = {Name = name, Elements = {}, SectionFrame = nil}
            
            -- Фрейм секции
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = name .. "Section"
            SectionFrame.Parent = Content
            SectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Size = UDim2.new(1, -10, 0, 0)
            
            local SectionCorner = Instance.new("UICorner")
            SectionCorner.CornerRadius = UDim.new(0, 6)
            SectionCorner.Parent = SectionFrame
            
            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 5)
            SectionLayout.Parent = SectionFrame
            
            -- Заголовок секции
            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Parent = SectionFrame
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Size = UDim2.new(1, 0, 0, 20)
            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.Text = name
            SectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            SectionTitle.TextSize = 14
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            
            section.SectionFrame = SectionFrame
            table.insert(tab.Sections, section)
            
            -- Функции для элементов
            function section:NewButton(text, callback)
                local button = Instance.new("TextButton")
                button.Parent = SectionFrame
                button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                button.BorderSizePixel = 0
                button.Size = UDim2.new(1, -10, 0, 30)
                button.Font = Enum.Font.Gotham
                button.Text = text
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                button.TextSize = 12
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Parent = button
                
                button.MouseButton1Click:Connect(callback or function() end)
                
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(1, -10, 0, SectionLayout.AbsoluteContentSize.Y + 10)
                    updateContainerSize()
                end)
            end
            
            function section:NewToggle(text, default, callback)
                local toggle = {Value = default or false}
                
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Parent = SectionFrame
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.Size = UDim2.new(1, -10, 0, 30)
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Parent = ToggleFrame
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
                ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.Text = text
                ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                ToggleLabel.TextSize = 12
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local ToggleButton = Instance.new("Frame")
                ToggleButton.Parent = ToggleFrame
                ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Position = UDim2.new(1, -40, 0.5, -10)
                ToggleButton.Size = UDim2.new(0, 40, 0, 20)
                
                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(0, 10)  -- Овальный
                ToggleCorner.Parent = ToggleButton
                
                local ToggleKnob = Instance.new("Frame")
                ToggleKnob.Parent = ToggleButton
                ToggleKnob.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                ToggleKnob.BorderSizePixel = 0
                ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
                ToggleKnob.Position = toggle.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                
                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(0, 8)
                KnobCorner.Parent = ToggleKnob
                
                local function updateToggle()
                    TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {Position = toggle.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                    TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {BackgroundColor3 = toggle.Value and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)}):Play()
                    if callback then callback(toggle.Value) end
                end
                updateToggle()
                
                ToggleFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggle.Value = not toggle.Value
                        updateToggle()
                    end
                end)
                
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(1, -10, 0, SectionLayout.AbsoluteContentSize.Y + 10)
                    updateContainerSize()
                end)
            end
            
            function section:NewSlider(text, min, max, default, callback)
                local slider = {Value = default or min}
                
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Parent = SectionFrame
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Size = UDim2.new(1, -10, 0, 40)
                
                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Parent = SliderFrame
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Position = UDim2.new(0, 0, 0, 0)
                SliderLabel.Size = UDim2.new(1, 0, 0, 20)
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.Text = text .. ": " .. slider.Value
                SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                SliderLabel.TextSize = 12
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local SliderBar = Instance.new("Frame")
                SliderBar.Parent = SliderFrame
                SliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                SliderBar.BorderSizePixel = 0
                SliderBar.Position = UDim2.new(0, 0, 0, 25)
                SliderBar.Size = UDim2.new(1, 0, 0, 10)
                
                local SliderCorner = Instance.new("UICorner")
                SliderCorner.CornerRadius = UDim.new(0, 5)
                SliderCorner.Parent = SliderBar
                
                local SliderFill = Instance.new("Frame")
                SliderFill.Parent = SliderBar
                SliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                SliderFill.BorderSizePixel = 0
                SliderFill.Size = UDim2.new((slider.Value - min) / (max - min), 0, 1, 0)
                
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 5)
                FillCorner.Parent = SliderFill
                
                local SliderKnob = Instance.new("Frame")
                SliderKnob.Parent = SliderBar
                SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderKnob.BorderSizePixel = 0
                SliderKnob.Size = UDim2.new(0, 15, 0, 15)
                SliderKnob.Position = UDim2.new((slider.Value - min) / (max - min), -7.5, 0.5, -7.5)
                
                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(0, 7.5)
                KnobCorner.Parent = SliderKnob
                
                local dragging = false
                SliderFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = UserInputService:GetMouseLocation()
                        local barPos = SliderBar.AbsolutePosition
                        local barSize = SliderBar.AbsoluteSize
                        local percent = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
                        slider.Value = math.floor(min + (max - min) * percent)
                        SliderLabel.Text = text .. ": " .. slider.Value
                        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                        SliderKnob.Position = UDim2.new(percent, -7.5, 0.5, -7.5)
                        if callback then callback(slider.Value) end
                    end
                end)
                
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(1, -10, 0, SectionLayout.AbsoluteContentSize.Y + 10)
                    updateContainerSize()
                end)
            end
            
            function section:NewDropdown(text, options, default, callback)
                local dropdown = {Value = default or options[1], Open = false}
                
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Parent = SectionFrame
                DropdownFrame.BackgroundTransparency = 1
                DropdownFrame.Size = UDim2.new(1, -10, 0, 30)
                
                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Parent = DropdownFrame
                DropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                DropdownButton.BorderSizePixel = 0
                DropdownButton.Size = UDim2.new(1, 0, 1, 0)
                DropdownButton.Font = Enum.Font.Gotham
                DropdownButton.Text = text .. ": " .. dropdown.Value
                DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                DropdownButton.TextSize = 12
                
                local DropdownCorner = Instance.new("UICorner")
                DropdownCorner.CornerRadius = UDim.new(0, 4)
                DropdownCorner.Parent = DropdownButton
                
                local DropdownList = Instance.new("Frame")
                DropdownList.Parent = DropdownFrame
                DropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                DropdownList.BorderSizePixel = 0
                DropdownList.Position = UDim2.new(0, 0, 1, 0)
                DropdownList.Size = UDim2.new(1, 0, 0, 0)
                DropdownList.Visible = false
                
                local ListCorner = Instance.new("UICorner")
                ListCorner.CornerRadius = UDim.new(0, 4)
                ListCorner.Parent = DropdownList
                
                local ListLayout = Instance.new("UIListLayout")
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Parent = DropdownList
                
                for _, option in ipairs(options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Parent = DropdownList
                    OptionButton.BackgroundTransparency = 1
                    OptionButton.Size = UDim2.new(1, 0, 0, 25)
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.Text = option
                    OptionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    OptionButton.TextSize = 12
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        dropdown.Value = option
                        DropdownButton.Text = text .. ": " .. dropdown.Value
                        DropdownList.Visible = false
                        dropdown.Open = false
                        DropdownFrame.Size = UDim2.new(1, -10, 0, 30)
                        if callback then callback(dropdown.Value) end
                        updateContainerSize()
                    end)
                end
                
                DropdownButton.MouseButton1Click:Connect(function()
                    dropdown.Open = not dropdown.Open
                    DropdownList.Visible = dropdown.Open
                    DropdownFrame.Size = dropdown.Open and UDim2.new(1, -10, 0, 30 + ListLayout.AbsoluteContentSize.Y) or UDim2.new(1, -10, 0, 30)
                    updateContainerSize()
                end)
                
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(1, -10, 0, SectionLayout.AbsoluteContentSize.Y + 10)
                    updateContainerSize()
                end)
            end
            
            return section
        end
        
        return tab
    end
    
    -- Функции для toggle UI
    function lib:Toggle()
        lib.Visible = not lib.Visible
        MainFrame.Visible = lib.Visible
    end
    
    -- Обработчики событий
    KeybindButton.MouseButton1Click:Connect(function()
        KeybindWindow.Visible = not KeybindWindow.Visible
    end)
    
    KWSetButton.MouseButton1Click:Connect(function()
        local key = KWTextBox.Text
        if Enum.KeyCode[key] then
            lib.Keybind = Enum.KeyCode[key]
            KWTextBox.Text = tostring(lib.Keybind)
            KeybindWindow.Visible = false
        else
            KWTextBox.Text = "Invalid Key"
            wait(1)
            KWTextBox.Text = tostring(lib.Keybind)
        end
    end)
    
    KWCloseButton.MouseButton1Click:Connect(function()
        KeybindWindow.Visible = false
    end)
    
    table.insert(lib.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == lib.Keybind then
            lib:Toggle()
        end
    end))
    
    -- Очистка при уничтожении
    function lib:Destroy()
        for _, conn in ipairs(lib.Connections) do
            conn:Disconnect()
        end
        ScreenGui:Destroy()
    end
    
    return lib
end

return createLib
