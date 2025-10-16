-- Custom Rayfield-like Library (Full Implementation)
local Rayfield = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function Create(instanceType, properties)
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function Animate(instance, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(duration or 0.2, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    TabBackground = Color3.fromRGB(30, 30, 30),
    SectionBackground = Color3.fromRGB(35, 35, 35),
    ElementBackground = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(100, 100, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Border = Color3.fromRGB(50, 50, 50),
}

local Window = {}
Window.__index = Window

function Window.new(title, keybind)
    local self = setmetatable({}, Window)
    self.Title = title or "Rayfield"
    self.Keybind = keybind or Enum.KeyCode.RightAlt
    self.Tabs = {}
    self.Connections = {}

    self.ScreenGui = Create("ScreenGui", {
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        Name = "RayfieldUI",
        ResetOnSpawn = false,
    })

    self.MainFrame = Create("Frame", {
        Parent = self.ScreenGui,
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    Create("UICorner", {Parent = self.MainFrame, CornerRadius = UDim.new(0, 10)})

    self.TitleBar = Create("Frame", {
        Parent = self.MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Colors.TabBackground,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = self.TitleBar, CornerRadius = UDim.new(0, 10)})
    local TitleLabel = Create("TextLabel", {
        Parent = self.TitleBar,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Colors.Text,
        TextSize = 18,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local CloseButton = Create("TextButton", {
        Parent = self.TitleBar,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = Colors.ElementBackground,
        Text = "X",
        TextColor3 = Colors.Text,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
    })
    Create("UICorner", {Parent = CloseButton, CornerRadius = UDim.new(0, 5)})
    CloseButton.MouseButton1Click:Connect(function()
        self:Toggle(false)
    end)

    self.TabContainer = Create("Frame", {
        Parent = self.MainFrame,
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Colors.TabBackground,
        BorderSizePixel = 0,
    })
    self.TabList = Create("ScrollingFrame", {
        Parent = self.TabContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Colors.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    Create("UIListLayout", {Parent = self.TabList, SortOrder = Enum.SortOrder.LayoutOrder})

    self.ContentFrame = Create("Frame", {
        Parent = self.MainFrame,
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundTransparency = 1,
    })

    local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end)
    table.insert(self.Connections, connection)

    local dragging, dragInput, dragStart, startPos
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    self.MainFrame.Visible = true
    return self
end

function Window:Toggle(visible)
    visible = visible ~= nil and visible or not self.MainFrame.Visible
    Animate(self.MainFrame, {Size = visible and UDim2.new(0, 600, 0, 400) or UDim2.new(0, 0, 0, 0)}, 0.3)
    self.MainFrame.Visible = visible
end

function Window:CreateTab(name)
    local tab = Tab.new(self, name)
    table.insert(self.Tabs, tab)
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, #self.Tabs * 35)
    return tab
end

local Tab = {}
Tab.__index = Tab

function Tab.new(window, name)
    local self = setmetatable({}, Tab)
    self.Window = window
    self.Name = name
    self.Sections = {}

    self.TabButton = Create("TextButton", {
        Parent = window.TabList,
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Colors.ElementBackground,
        Text = name,
        TextColor3 = Colors.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
    })
    Create("UICorner", {Parent = self.TabButton, CornerRadius = UDim.new(0, 5)})
    self.TabButton.MouseButton1Click:Connect(function()
        self:Select()
    end)

    self.Content = Create("ScrollingFrame", {
        Parent = window.ContentFrame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Colors.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
    })
    local listLayout = Create("UIListLayout", {Parent = self.Content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.Content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    if #window.Tabs == 1 then
        self:Select()
    end

    return self
end

function Tab:Select()
    for _, t in pairs(self.Window.Tabs) do
        t.Content.Visible = false
        t.TabButton.BackgroundColor3 = Colors.ElementBackground
    end
    self.Content.Visible = true
    self.TabButton.BackgroundColor3 = Colors.Accent
end

function Tab:CreateSection(name)
    local section = Section.new(self, name)
    table.insert(self.Sections, section)
    return section
end

local Section = {}
Section.__index = Section

function Section.new(tab, name)
    local self = setmetatable({}, Section)
    self.Tab = tab
    self.Name = name

    self.SectionFrame = Create("Frame", {
        Parent = tab.Content,
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Colors.SectionBackground,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = self.SectionFrame, CornerRadius = UDim.new(0, 5)})
    local SectionLabel = Create("TextLabel", {
        Parent = self.SectionFrame,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    self.ElementContainer = Create("Frame", {
        Parent = self.SectionFrame,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
    })
    local elementLayout = Create("UIListLayout", {Parent = self.ElementContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    elementLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.SectionFrame.Size = UDim2.new(1, -10, 0, elementLayout.AbsoluteContentSize.Y + 30)
        self.Tab.Content.CanvasSize = UDim2.new(0, 0, 0, self.Tab.Content.UIListLayout.AbsoluteContentSize.Y + 10)
    end)

    return self
end

local Element = {}
Element.__index = Element

function Element.new(section, type)
    local self = setmetatable({}, Element)
    self.Section = section
    self.Type = type

    self.Frame = Create("Frame", {
        Parent = section.ElementContainer,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Colors.ElementBackground,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = self.Frame, CornerRadius = UDim.new(0, 5)})

    return self
end

function Section:CreateButton(name, callback)
    local button = Element.new(self, "Button")
    button.Label = Create("TextLabel", {
        Parent = button.Frame,
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    button.Button = Create("TextButton", {
        Parent = button.Frame,
        Size = UDim2.new(0, 60, 1, -4),
        Position = UDim2.new(1, -65, 0, 2),
        BackgroundColor3 = Colors.Accent,
        Text = "Click",
        TextColor3 = Colors.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 12,
    })
    Create("UICorner", {Parent = button.Button, CornerRadius = UDim.new(0, 5)})
    button.Button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return button
end

function Section:CreateToggle(name, default, callback)
    local toggle = Element.new(self, "Toggle")
    toggle.Value = default or false
    toggle.Label = Create("TextLabel", {
        Parent = toggle.Frame,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    toggle.ToggleButton = Create("Frame", {
        Parent = toggle.Frame,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0, 5),
        BackgroundColor3 = toggle.Value and Colors.Accent or Colors.ElementBackground,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = toggle.ToggleButton, CornerRadius = UDim.new(1, 0)})
    toggle.Circle = Create("Frame", {
        Parent = toggle.ToggleButton,
        Size = UDim2.new(0, 16, 0, 16),
        Position = toggle.Value and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Colors.Text,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = toggle.Circle, CornerRadius = UDim.new(1, 0)})
    toggle.Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggle.Value = not toggle.Value
            Animate(toggle.ToggleButton, {BackgroundColor3 = toggle.Value and Colors.Accent or Colors.ElementBackground})
            Animate(toggle.Circle, {Position = toggle.Value and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)})
            if callback then callback(toggle.Value) end
        end
    end)
    return toggle
end

function Section:CreateSlider(name, min, max, default, callback)
    local slider = Element.new(self, "Slider")
    slider.Value = default or min
    slider.Min = min
    slider.Max = max
    slider.Name = name
    slider.Label = Create("TextLabel", {
        Parent = slider.Frame,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name .. ": " .. slider.Value,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    slider.SliderBar = Create("Frame", {
        Parent = slider.Frame,
        Size = UDim2.new(1, -10, 0, 4),
        Position = UDim2.new(0, 5, 0, 25),
        BackgroundColor3 = Colors.ElementBackground,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = slider.SliderBar, CornerRadius = UDim.new(1, 0)})
    local percent = (slider.Value - min) / (max - min)
    slider.Fill = Create("Frame", {
        Parent = slider.SliderBar,
        Size = UDim2.new(percent, 0, 1, 0),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = slider.Fill, CornerRadius = UDim.new(1, 0)})
    slider.Handle = Create("Frame", {
        Parent = slider.SliderBar,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(percent, -6, 0, -4),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
    })
    Create("UICorner", {Parent = slider.Handle, CornerRadius = UDim.new(1, 0)})
    local dragging = false
    slider.SliderBar.InputBegan:Connect(function(input)
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
            local relativePos = math.clamp((mousePos.X - slider.SliderBar.AbsolutePosition.X) / slider.SliderBar.AbsoluteSize.X, 0, 1)
            slider.Value = math.floor(min + (max - min) * relativePos)
            slider.Label.Text = name .. ": " .. slider.Value
            slider.Fill.Size = UDim2.new(relativePos, 0, 1, 0)
            slider.Handle.Position = UDim2.new(relativePos, -6, 0, -4)
            if callback then callback(slider.Value) end
        end
    end)
    return slider
end

function Section:CreateDropdown(name, options, default, callback)
    local dropdown = Element.new(self, "Dropdown")
    dropdown.Value = default or options[1]
    dropdown.Options = options
    dropdown.Open = false
    dropdown.Name = name
    dropdown.Label = Create("TextLabel", {
        Parent = dropdown.Frame,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name .. ": " .. dropdown.Value,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    dropdown.Arrow = Create("TextLabel", {
        Parent = dropdown.Frame,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
    })
    dropdown.Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropdown.Open = not dropdown.Open
            dropdown.Arrow.Text = dropdown.Open and "▲" or "▼"
            if dropdown.Open then
                dropdown.ListFrame = Create("Frame", {
                    Parent = dropdown.Frame,
                    Size = UDim2.new(1, 0, 0, #options * 25),
                    Position = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Colors.SectionBackground,
                    BorderSizePixel = 0,
                    ZIndex = 10,
                })
                Create("UICorner", {Parent = dropdown.ListFrame, CornerRadius = UDim.new(0, 5)})
                local listLayout = Create("UIListLayout", {Parent = dropdown.ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})
                for i, option in ipairs(options) do
                    local optionButton = Create("TextButton", {
                        Parent = dropdown.ListFrame,
                        Size = UDim2.new(1, 0, 0, 25),
                        BackgroundTransparency = 1,
                        Text = option,
                        TextColor3 = Colors.Text,
                        Font = Enum.Font.SourceSans,
                        TextSize = 12,
                        ZIndex = 10,
                    })
                    optionButton.MouseButton1Click:Connect(function()
                        dropdown.Value = option
                        dropdown.Label.Text = name .. ": " .. dropdown.Value
                        dropdown.Open = false
                        dropdown.Arrow.Text = "▼"
                        dropdown.ListFrame:Destroy()
                        if callback then callback(dropdown.Value) end
                    end)
                end
            else
                if dropdown.ListFrame then
                    dropdown.ListFrame:Destroy()
                end
            end
        end
    end)
    return dropdown
end

function Section:CreateInput(name, placeholder, callback)
    local input = Element.new(self, "Input")
    input.Label = Create("TextLabel", {
        Parent = input.Frame,
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    input.TextBox = Create("TextBox", {
        Parent = input.Frame,
        Size = UDim2.new(1, -110, 1, -4),
        Position = UDim2.new(0, 105, 0, 2),
        BackgroundColor3 = Colors.SectionBackground,
        Text = "",
        PlaceholderText = placeholder or "",
        TextColor3 = Colors.Text,
        Font = Enum.Font.SourceSans,
        TextSize = 12,
    })
    Create("UICorner", {Parent = input.TextBox, CornerRadius = UDim.new(0, 5)})
    input.TextBox.FocusLost:Connect(function(enterPressed)
        if callback then callback(input.TextBox.Text) end
    end)
    return input
end

function Section:CreateLabel(name)
    local label = Element.new(self, "Label")
    label.Label = Create("TextLabel", {
        Parent = label.Frame,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return label
end

function Section:CreateParagraph(name, content)
    local paragraph = Element.new(self, "Paragraph")
    paragraph.Label = Create("TextLabel", {
        Parent = paragraph.Frame,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    paragraph.Content = Create("TextLabel", {
        Parent = paragraph.Frame,
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 5, 0, 20),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = Colors.TextSecondary,
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    paragraph.Content:GetPropertyChangedSignal("TextBounds"):Connect(function()
        paragraph.Frame.Size = UDim2.new(1, 0, 0, paragraph.Content.TextBounds.Y + 25)
    end)
    return paragraph
end

return Rayfield
