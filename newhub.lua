-- Кастомная UI Библиотека (твоя собственная, не Kavo)
-- Полный код: Адаптирована под серые-тёмные цвета как на скрине (тёмно-серый фон #282828, серые кнопки #3C3C3C, красный #FF0000 для OFF toggles, белый текст)
-- Декор: Снежинки (анимация падения) и ёлка в правом нижнем углу (ImageLabels)
-- Структура: lib = createLib("Название") -> tab = lib:NewTab("Вкладка") -> section = tab:NewSection("Секция") -> section:NewToggle(), :NewButton(), :NewSlider()
-- Это чистая UI библиотека без чит-функций. Вставь свою логику в callbacks (function(state) или function()).
-- Использование: local lib = createLib("BugaBugaHub × Happy New Year! 🎄") - затем создавай вкладки/элементы как в шаблоне ниже.
-- Горячая клавиша: Insert для toggle UI.
-- Полностью рабочий код - копируй и вставляй в свой скрипт. Без лагов - оптимизировано.

local createLib = function(title)
    local Library = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- Цвета (хардкод как на скрине: серые-тёмные, без тем)
    local Colors = {
        Background = Color3.fromRGB(40, 40, 40), -- Тёмно-серый фон
        Secondary = Color3.fromRGB(60, 60, 60), -- Серые элементы
        Accent = Color3.fromRGB(80, 80, 80), -- Границы
        Text = Color3.fromRGB(255, 255, 255), -- Белый текст
        TextDark = Color3.fromRGB(200, 200, 200), -- Светло-серый
        Off = Color3.fromRGB(255, 0, 0), -- Красный для OFF
        On = Color3.fromRGB(0, 255, 0), -- Зелёный для ON
        Slider = Color3.fromRGB(100, 100, 100) -- Серый слайдер
    }

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame (серый-тёмный как на скрине)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150) -- Центр экрана
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Active = true
    MainFrame.Draggable = true -- Drag для всего фрейма
    MainFrame.Visible = false -- Начинаем скрытым

    -- Закругления для всех фреймов
    local function AddCorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = parent
        return corner
    end

    AddCorner(MainFrame, 8)

    -- Заголовок (как на скрине)
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = title or "Custom UI"
    Title.TextColor3 = Colors.Text
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Sidebar (левый бар для вкладок, серый)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Colors.Secondary
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 35)
    Sidebar.Size = UDim2.new(0, 120, 1, -35)
    AddCorner(Sidebar, 0) -- Без углов для sidebar

    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Parent = Sidebar
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 5)

    -- Content Area (правая область для секций)
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Parent = MainFrame
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.new(0, 120, 0, 35)
    Content.Size = UDim2.new(1, -120, 1, -35)

    local ContentList = Instance.new("UIListLayout")
    ContentList.Parent = Content
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Padding = UDim.new(0, 5)

    -- Переменные для UI
    local CurrentTab = nil
    local Tabs = {}
    local Sections = {}

    -- Функция для создания вкладки
    function Library:NewTab(name)
        local Tab = {}
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Parent = Sidebar
        TabButton.BackgroundColor3 = Colors.Accent
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = name
        TabButton.TextColor3 = Colors.Text
        TabButton.TextSize = 14
        AddCorner(TabButton, 4)

        -- Контент для вкладки
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Parent = Content
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.Position = UDim2.new(0, 0, 0, 0)
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.ScrollBarThickness = 6
        TabContent.ScrollBarImageColor3 = Colors.Accent
        TabContent.Visible = false

        local TabContentList = Instance.new("UIListLayout")
        TabContentList.Parent = TabContent
        TabContentList.SortOrder = Enum.SortOrder.LayoutOrder
        TabContentList.Padding = UDim.new(0, 5)

        TabContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContentList.AbsoluteContentSize.Y + 10)
        end)

        -- Смена вкладки
        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Content.Visible = false
                t.Button.BackgroundColor3 = Colors.Accent
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Colors.Background
            CurrentTab = TabContent
        end)

        -- Первая вкладка активна
        if #Tabs == 0 then
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Colors.Background
            CurrentTab = TabContent
        end

        Tabs[#Tabs + 1] = {Button = TabButton, Content = TabContent}

        -- NewSection для вкладки
        function Tab:NewSection(name)
            local Section = {}
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = name .. "Section"
            SectionFrame.Parent = TabContent
            SectionFrame.BackgroundColor3 = Colors.Secondary
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Size = UDim2.new(1, -10, 0, 40) -- Авто-размер
            AddCorner(SectionFrame, 6)

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Name = "Title"
            SectionTitle.Parent = SectionFrame
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Position = UDim2.new(0, 10, 0, 0)
            SectionTitle.Size = UDim2.new(1, -20, 1, 0)
            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.Text = name
            SectionTitle.TextColor3 = Colors.Text
            SectionTitle.TextSize = 14
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left

            local SectionList = Instance.new("UIListLayout")
            SectionList.Parent = SectionFrame
            SectionList.SortOrder = Enum.SortOrder.LayoutOrder
            SectionList.Padding = UDim.new(0, 5)
            SectionList.HorizontalAlignment = Enum.HorizontalAlignment.Center

            SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, -10, 0, SectionList.AbsoluteContentSize.Y + 20)
            end)

            -- NewToggle
            function Section:NewToggle(name, description, callback)
                local Toggle = {}
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = name .. "Toggle"
                ToggleFrame.Parent = SectionFrame
                ToggleFrame.BackgroundColor3 = Colors.Accent
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Size = UDim2.new(1, -20, 0, 30)
                AddCorner(ToggleFrame, 4)

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "Label"
                ToggleLabel.Parent = ToggleFrame
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.Text = name .. ": OFF" -- По умолчанию OFF
                ToggleLabel.TextColor3 = Colors.Off -- Красный как на скрине
                ToggleLabel.TextSize = 12
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Name = "Button"
                ToggleButton.Parent = ToggleFrame
                ToggleButton.BackgroundColor3 = Colors.Off
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Position = UDim2.new(0.75, 0, 0.1, 0)
                ToggleButton.Size = UDim2.new(0.2, 0, 0.8, 0)
                ToggleButton.Font = Enum.Font.GothamBold
                ToggleButton.Text = "OFF"
                ToggleButton.TextColor3 = Colors.Text
                ToggleButton.TextSize = 10
                AddCorner(ToggleButton, 4)

                local state = false
                local function UpdateToggle(s)
                    state = s
                    ToggleLabel.Text = name .. ": " .. (s and "ON" or "OFF")
                    ToggleLabel.TextColor3 = s and Colors.On or Colors.Off
                    ToggleButton.BackgroundColor3 = s and Colors.On or Colors.Off
                    ToggleButton.Text = s and "ON" or "OFF"
                    if callback then callback(s) end
                end

                ToggleButton.MouseButton1Click:Connect(function()
                    UpdateToggle(not state)
                end)

                -- По умолчанию OFF (красный)
                UpdateToggle(false)

                return Toggle
            end

            -- NewButton
            function Section:NewButton(name, description, callback)
                local Button = Instance.new("TextButton")
                Button.Name = name .. "Button"
                Button.Parent = SectionFrame
                Button.BackgroundColor3 = Colors.Secondary
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(1, -20, 0, 30)
                Button.Font = Enum.Font.Gotham
                Button.Text = name
                Button.TextColor3 = Colors.Text
                Button.TextSize = 12
                AddCorner(Button, 4)

                Button.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)

                return Button
            end

            -- NewSlider
            function Section:NewSlider(name, min, max, default, callback)
                local Slider = {}
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = name .. "Slider"
                SliderFrame.Parent = SectionFrame
                SliderFrame.BackgroundColor3 = Colors.Accent
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Size = UDim2.new(1, -20, 0, 50)
                AddCorner(SliderFrame, 4)

                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Name = "Label"
                SliderLabel.Parent = SliderFrame
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Position = UDim2.new(0, 10, 0, 0)
                SliderLabel.Size = UDim2.new(1, -20, 0, 20)
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.Text = name .. ": " .. (default or min)
                SliderLabel.TextColor3 = Colors.Text
                SliderLabel.TextSize = 12
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left

                local SliderBar = Instance.new("Frame")
                SliderBar.Name = "Bar"
                SliderBar.Parent = SliderFrame
                SliderBar.BackgroundColor3 = Colors.Slider
                SliderBar.BorderSizePixel = 0
                SliderBar.Position = UDim2.new(0, 10, 0, 25)
                SliderBar.Size = UDim2.new(1, -20, 0, 10)
                AddCorner(SliderBar, 5)

                local SliderFill = Instance.new("Frame")
                SliderFill.Name = "Fill"
                SliderFill.Parent = SliderBar
                SliderFill.BackgroundColor3 = Colors.On
                SliderFill.BorderSizePixel = 0
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                AddCorner(SliderFill, 5)

                local SliderButton = Instance.new("TextButton")
                SliderButton.Name = "Button"
                SliderButton.Parent = SliderBar
                SliderButton.BackgroundColor3 = Colors.Text
                SliderButton.BorderSizePixel = 0
                SliderButton.Position = UDim2.new(0, 0, 0, 0)
                SliderButton.Size = UDim2.new(0, 15, 1, 0)
                AddCorner(SliderButton, 7)

                local value = default or min
                local dragging = false

                local function UpdateSlider(v)
                    value = v
                    SliderLabel.Text = name .. ": " .. math.floor(v)
                    SliderFill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
                    SliderButton.Position = UDim2.new((v - min) / (max - min), -7, 0, 0)
                    if callback then callback(v) end
                end

                SliderButton.MouseButton1Down:Connect(function()
                    dragging = true
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                RunService.RenderStepped:Connect(function()
                    if dragging then
                        local mousePos = UserInputService:GetMouseLocation()
                        local barPos = SliderBar.AbsolutePosition
                        local barSize = SliderBar.AbsoluteSize
                        local percent = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
                        UpdateSlider(min + (max - min) * percent)
                    end
                end)

                UpdateSlider(value)

                return Slider
            end

            return Section
        end

        return Tab
    end

    -- Декор: Ёлка в правом нижнем углу
    local Tree = Instance.new("ImageLabel")
    Tree.Name = "Tree"
    Tree.Parent = MainFrame
    Tree.BackgroundTransparency = 1
    Tree.Position = UDim2.new(1, -60, 1, -60)
    Tree.Size = UDim2.new(0, 50, 0, 50)
    Tree.Image = "rbxassetid://1234567890" -- Замени на реальный ID ёлки (например, из Roblox assets)
    Tree.ZIndex = 10

    -- Декор: Снежинки (анимация падения)
    for i = 1, 10 do
        local Snowflake = Instance.new("ImageLabel")
        Snowflake.Name = "Snowflake" .. i
        Snowflake.Parent = ScreenGui
        Snowflake.BackgroundTransparency = 1
        Snowflake.Position = UDim2.new(math.random(), 0, 0, -10)
        Snowflake.Size = UDim2.new(0, 10, 0, 10)
        Snowflake.Image = "rbxassetid://1234567891" -- Замени на реальный ID снежинки
        Snowflake.ZIndex = 5

        local tween = TweenService:Create(Snowflake, TweenInfo.new(math.random(5, 10), Enum.EasingStyle.Linear), {
            Position = UDim2.new(math.random(), 0, 1, 10)
        })
        tween:Play()
        tween.Completed:Connect(function()
            Snowflake.Position = UDim2.new(math.random(), 0, 0, -10)
            tween:Play()
        end)
    end

    -- Toggle UI по Insert
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return Library
end
