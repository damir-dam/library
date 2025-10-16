-- Полный обновленный код твоей UI библиотеки для Roblox
-- Изменения: 
-- - createLib теперь возвращается (return createLib), чтобы можно было вызвать как local lib = createLib("Title")
-- - Добавлен параметр description для всех элементов (отображается под именем)
-- - Всё остальное оставлено как в оригинале, но с исправлениями для корректной работы

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function createLib(title)
    local Library = {}
    
    local Colors = {
        Background = Color3.fromRGB(40, 40, 40),
        Secondary = Color3.fromRGB(60, 60, 60),
        Accent = Color3.fromRGB(80, 80, 80),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(200, 200, 200),
        Off = Color3.fromRGB(255, 0, 0),
        On = Color3.fromRGB(0, 255, 0),
        Slider = Color3.fromRGB(100, 100, 100)
    }

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false

    local function AddCorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = parent
        return corner
    end

    AddCorner(MainFrame, 8)

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

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Colors.Secondary
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 35)
    Sidebar.Size = UDim2.new(0, 120, 1, -35)
    
    local SidebarList = Instance.new("UIListLayout")
    SidebarList.Parent = Sidebar
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 5)

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

    local CurrentTab = nil
    local Tabs = {}
    local Sections = {}

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

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Content.Visible = false
                t.Button.BackgroundColor3 = Colors.Accent
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Colors.Background
            CurrentTab = TabContent
        end)

        if #Tabs == 0 then
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Colors.Background
            CurrentTab = TabContent
        end

        Tabs[#Tabs + 1] = {Button = TabButton, Content = TabContent}

        function Tab:NewSection(name)
            local Section = {}
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = name .. "Section"
            SectionFrame.Parent = TabContent
            SectionFrame.BackgroundColor3 = Colors.Secondary
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Size = UDim2.new(1, -10, 0, 40)
            AddCorner(SectionFrame, 6)

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Name = "Title"
            SectionTitle.Parent = SectionFrame
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Position = UDim2.new(0, 10, 0, 0)
            SectionTitle.Size = UDim2.new(1, -20, 0, 20)
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
                SectionFrame.Size = UDim2.new(1, -10, 0, SectionList.AbsoluteContentSize.Y + 25)
            end)

            function Section:NewToggle(name, description, callback)
                local Toggle = {}
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = name .. "Toggle"
                ToggleFrame.Parent = SectionFrame
                ToggleFrame.BackgroundColor3 = Colors.Accent
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Size = UDim2.new(1, -20, 0, 50)
                AddCorner(ToggleFrame, 4)

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "Label"
                ToggleLabel.Parent = ToggleFrame
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.Size = UDim2.new(0.7, 0, 0, 20)
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.Text = name .. ": OFF"
                ToggleLabel.TextColor3 = Colors.Off
                ToggleLabel.TextSize = 12
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

                local ToggleDesc = Instance.new("TextLabel")
                ToggleDesc.Name = "Description"
                ToggleDesc.Parent = ToggleFrame
                ToggleDesc.BackgroundTransparency = 1
                ToggleDesc.Position = UDim2.new(0, 10, 0, 20)
                ToggleDesc.Size = UDim2.new(0.7, 0, 0, 15)
                ToggleDesc.Font = Enum.Font.Gotham
                ToggleDesc.Text = description or ""
                ToggleDesc.TextColor3 = Colors.TextDark
                ToggleDesc.TextSize = 10
                ToggleDesc.TextXAlignment = Enum.TextXAlignment.Left

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Name = "Button"
                ToggleButton.Parent = ToggleFrame
                ToggleButton.BackgroundColor3 = Colors.Off
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Position = UDim2.new(0.75, 0, 0.1, 0)
                ToggleButton.Size = UDim2.new(0.2, 0, 0.8, 0)
                ToggleButton.Font = Enum.Font.GothamBold
                ToggleButton.Text = ""
                ToggleButton.TextColor3 = Colors.Text
                ToggleButton.TextSize = 10
                AddCorner(ToggleButton, 4)

                local state = false
                local function UpdateToggle(s)
                    state = s
                    ToggleLabel.Text = name .. ": " .. (s and "ON" or "OFF")
                    ToggleLabel.TextColor3 = s and Colors.On or Colors.Off
                    ToggleButton.BackgroundColor3 = s and Colors.On or Colors.Off
                    if callback then callback(s) end
                end

                ToggleButton.MouseButton1Click:Connect(function()
                    UpdateToggle(not state)
                end)

                UpdateToggle(false)
                return Toggle
            end

            function Section:NewButton(name, description, callback)
                local ButtonFrame = Instance.new("Frame")
                ButtonFrame.Name = name .. "ButtonFrame"
                ButtonFrame.Parent = SectionFrame
                ButtonFrame.BackgroundColor3 = Colors.Accent
                ButtonFrame.BorderSizePixel = 0
                ButtonFrame.Size = UDim2.new(1, -20, 0, 50)
                AddCorner(ButtonFrame, 4)

                local ButtonLabel = Instance.new("TextLabel")
                ButtonLabel.Name = "Label"
                ButtonLabel.Parent = ButtonFrame
                ButtonLabel.BackgroundTransparency = 1
                ButtonLabel.Position = UDim2.new(0, 10, 0, 0)
                ButtonLabel.Size = UDim2.new(1, -20, 0, 20)
                ButtonLabel.Font = Enum.Font.GothamBold
                ButtonLabel.Text = name
                ButtonLabel.TextColor3 = Colors.Text
                ButtonLabel.TextSize = 12
                ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left

                local ButtonDesc = Instance.new("TextLabel")
                ButtonDesc.Name = "Description"
                ButtonDesc.Parent = ButtonFrame
                ButtonDesc.BackgroundTransparency = 1
                ButtonDesc.Position = UDim2.new(0, 10, 0, 20)
                ButtonDesc.Size = UDim2.new(1, -20, 0, 15)
                ButtonDesc.Font = Enum.Font.Gotham
                ButtonDesc.Text = description or ""
                ButtonDesc.TextColor3 = Colors.TextDark
                ButtonDesc.TextSize = 10
                ButtonDesc.TextXAlignment = Enum.TextXAlignment.Left

                local Button = Instance.new("TextButton")
                Button.Name = "Button"
                Button.Parent = ButtonFrame
                Button.BackgroundTransparency = 1
                Button.Size = UDim2.new(1, 0, 1, 0)
                Button.Font = Enum.Font.SourceSans
                Button.Text = ""
                Button.TextSize = 14

                Button.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)

                return Button
            end

            function Section:NewSlider(name, description, min, max, default, callback)
                local Slider = {}
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = name .. "Slider"
                SliderFrame.Parent = SectionFrame
                SliderFrame.BackgroundColor3 = Colors.Accent
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Size = UDim2.new(1, -20, 0, 70)
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

                local SliderDesc = Instance.new("TextLabel")
                SliderDesc.Name = "Description"
                SliderDesc.Parent = SliderFrame
                SliderDesc.BackgroundTransparency = 1
                SliderDesc.Position = UDim2.new(0, 10, 0, 20)
                SliderDesc.Size = UDim2.new(1, -20, 0, 15)
                SliderDesc.Font = Enum.Font.Gotham
                SliderDesc.Text = description or ""
                SliderDesc.TextColor3 = Colors.TextDark
                SliderDesc.TextSize = 10
                SliderDesc.TextXAlignment = Enum.TextXAlignment.Left

                local SliderBar = Instance.new("Frame")
                SliderBar.Name = "Bar"
                SliderBar.Parent = SliderFrame
                SliderBar.BackgroundColor3 = Colors.Slider
                SliderBar.BorderSizePixel = 0
                SliderBar.Position = UDim2.new(0, 10, 0, 45)
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
                    value = math.clamp(v, min, max)
                    SliderLabel.Text = name .. ": " .. math.floor(value)
                    local percent = (value - min) / (max - min)
                    SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    SliderButton.Position = UDim2.new(percent, -7, 0, 0)
                    if callback then callback(value) end
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

            function Section:NewTextbox(name, description, placeholder, callback)
                local Textbox = {}
                local TextboxFrame = Instance.new("Frame")
                TextboxFrame.Name = name .. "Textbox"
                TextboxFrame.Parent = SectionFrame
                TextboxFrame.BackgroundColor3 = Colors.Accent
                TextboxFrame.BorderSizePixel = 0
                TextboxFrame.Size = UDim2.new(1, -20, 0, 70)
                AddCorner(TextboxFrame, 4)

                local TextboxLabel = Instance.new("TextLabel")
                TextboxLabel.Name = "Label"
                TextboxLabel.Parent = TextboxFrame
                TextboxLabel.BackgroundTransparency = 1
                TextboxLabel.Position = UDim2.new(0, 10, 0, 0)
                TextboxLabel.Size = UDim2.new(1, -20, 0, 20)
                TextboxLabel.Font = Enum.Font.Gotham
                TextboxLabel.Text = name
                TextboxLabel.TextColor3 = Colors.Text
                TextboxLabel.TextSize = 12
                TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left

                local TextboxDesc = Instance.new("TextLabel")
                TextboxDesc.Name = "Description"
                TextboxDesc.Parent = TextboxFrame
                TextboxDesc.BackgroundTransparency = 1
                TextboxDesc.Position = UDim2.new(0, 10, 0, 20)
                TextboxDesc.Size = UDim2.new(1, -20, 0, 15)
                TextboxDesc.Font = Enum.Font.Gotham
                TextboxDesc.Text = description or ""
                TextboxDesc.TextColor3 = Colors.TextDark
                TextboxDesc.TextSize = 10
                TextboxDesc.TextXAlignment = Enum.TextXAlignment.Left

                local TextBox = Instance.new("TextBox")
                TextBox.Name = "TextBox"
                TextBox.Parent = TextboxFrame
                TextBox.BackgroundColor3 = Colors.Slider
                TextBox.BorderSizePixel = 0
                TextBox.Position = UDim2.new(0, 10, 0, 40)
                TextBox.Size = UDim2.new(1, -20, 0, 20)
                TextBox.Font = Enum.Font.Gotham
                TextBox.PlaceholderText = placeholder or "Enter text..."
                TextBox.Text = ""
                TextBox.TextColor3 = Colors.Text
                TextBox.TextSize = 12
                AddCorner(TextBox, 4)

                TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed and callback then
                        callback(TextBox.Text)
                    end
                end)

                return Textbox
            end

            function Section:NewDropdown(name, description, options, callback)
                local Dropdown = {}
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Name = name .. "Dropdown"
                DropdownFrame.Parent = SectionFrame
                DropdownFrame.BackgroundColor3 = Colors.Accent
                DropdownFrame.BorderSizePixel = 0
                DropdownFrame.Size = UDim2.new(1, -20, 0, 70)
                AddCorner(DropdownFrame, 4)

                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Name = "Label"
                DropdownLabel.Parent = DropdownFrame
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                DropdownLabel.Size = UDim2.new(1, -20, 0, 20)
                DropdownLabel.Font = Enum.Font.Gotham
                DropdownLabel.Text = name .. ": " .. (options[1] or "Select")
                DropdownLabel.TextColor3 = Colors.Text
                DropdownLabel.TextSize = 12
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left

                local DropdownDesc = Instance.new("TextLabel")
                DropdownDesc.Name = "Description"
                DropdownDesc.Parent = DropdownFrame
                DropdownDesc.BackgroundTransparency = 1
                DropdownDesc.Position = UDim2.new(0, 10, 0, 20)
                DropdownDesc.Size = UDim2.new(1, -20, 0, 15)
                DropdownDesc.Font = Enum.Font.Gotham
                DropdownDesc.Text = description or ""
                DropdownDesc.TextColor3 = Colors.TextDark
                DropdownDesc.TextSize = 10
                DropdownDesc.TextXAlignment = Enum.TextXAlignment.Left

                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Name = "Button"
                DropdownButton.Parent = DropdownFrame
                DropdownButton.BackgroundColor3 = Colors.Slider
                DropdownButton.BorderSizePixel = 0
                DropdownButton.Position = UDim2.new(0, 10, 0, 40)
                DropdownButton.Size = UDim2.new(1, -20, 0, 20)
                DropdownButton.Font = Enum.Font.Gotham
                DropdownButton.Text = options[1] or "Select"
                DropdownButton.TextColor3 = Colors.Text
                DropdownButton.TextSize = 12
                AddCorner(DropdownButton, 4)

                local DropdownList = Instance.new("Frame")
                DropdownList.Name = "List"
                DropdownList.Parent = DropdownFrame
                DropdownList.BackgroundColor3 = Colors.Secondary
                DropdownList.BorderSizePixel = 0
                DropdownList.Position = UDim2.new(0, 10, 0, 65)
                DropdownList.Size = UDim2.new(1, -20, 0, #options * 20)
                DropdownList.Visible = false
                AddCorner(DropdownList, 4)

                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Parent = DropdownList
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local selected = options[1] or "Select"
                for _, option in ipairs(options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Name = option .. "Option"
                    OptionButton.Parent = DropdownList
                    OptionButton.BackgroundColor3 = Colors.Accent
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Size = UDim2.new(1, 0, 0, 20)
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.Text = option
                    OptionButton.TextColor3 = Colors.Text
                    OptionButton.TextSize = 12
                    AddCorner(OptionButton, 4)

                    OptionButton.MouseButton1Click:Connect(function()
                        selected = option
                        DropdownLabel.Text = name .. ": " .. selected
                        DropdownButton.Text = selected
                        DropdownList.Visible = false
                        if callback then callback(selected) end
                    end)
                end

                DropdownButton.MouseButton1Click:Connect(function()
                    DropdownList.Visible = not DropdownList.Visible
                end)

                return Dropdown
            end

            function Section:NewLabel(name, description)
                local LabelFrame = Instance.new("Frame")
                LabelFrame.Name = name .. "LabelFrame"
                LabelFrame.Parent = SectionFrame
                LabelFrame.BackgroundColor3 = Colors.Accent
                LabelFrame.BorderSizePixel = 0
                LabelFrame.Size = UDim2.new(1, -20, 0, 50)
                AddCorner(LabelFrame, 4)

                local LabelTitle = Instance.new("TextLabel")
                LabelTitle.Name = "Title"
                LabelTitle.Parent = LabelFrame
                LabelTitle.BackgroundTransparency = 1
                LabelTitle.Position = UDim2.new(0, 10, 0, 0)
                LabelTitle.Size = UDim2.new(1, -20, 0, 20)
                LabelTitle.Font = Enum.Font.GothamBold
                LabelTitle.Text = name
                LabelTitle.TextColor3 = Colors.Text
                LabelTitle.TextSize = 12
                LabelTitle.TextXAlignment = Enum.TextXAlignment.Left

                local LabelDesc = Instance.new("TextLabel")
                LabelDesc.Name = "Description"
                LabelDesc.Parent = LabelFrame
                LabelDesc.BackgroundTransparency = 1
                LabelDesc.Position = UDim2.new(0, 10, 0, 20)
                LabelDesc.Size = UDim2.new(1, -20, 0, 15)
                LabelDesc.Font = Enum.Font.Gotham
                LabelDesc.Text = description or ""
                LabelDesc.TextColor3 = Colors.TextDark
                LabelDesc.TextSize = 10
                LabelDesc.TextXAlignment = Enum.TextXAlignment.Left

                return LabelFrame
            end

            return Section
        end

        return Tab
    end

    function Library:Toggle()
        MainFrame.Visible = not MainFrame.Visible
    end

    return Library
end

return createLib
