-- NewHub v3.1 - Roblox GUI Library (Full Complete Version with Dropdown)
-- Features: Tabs, Sections, Buttons, Toggles, Sliders, Dropdowns, Drag, Close Animation, Scroll, Keybind Toggle

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local Connections = {}  -- To store connections for cleanup

-- Helper function to create instances
local function CreateInstance(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

-- Create ScreenGui
local function CreateScreenGui()
    local screenGui = CreateInstance("ScreenGui", {
        Name = "NewHubGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = player.PlayerGui
    })
    return screenGui
end

-- Create MainFrame with gradient, drag, close button
local function CreateMainFrame(screenGui, hubName)
    local mainFrame = CreateInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 550, 0, 450),
        Position = UDim2.new(0.5, -275, 0.5, -225),
        BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
        BorderSizePixel = 0,
        Parent = screenGui
    })
    
    -- Gradient background (red-white for holiday theme)
    local gradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.5, 0, 0)),  -- Dark red
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))     -- White
        },
        Rotation = 90,
        Parent = mainFrame
    })
    
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = mainFrame
    })
    
    -- Title bar for drag
    local titleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    local titleCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = titleBar
    })
    
    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = hubName,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Close button
    local closeBtn = CreateInstance("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = Color3.new(0.8, 0, 0),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    local closeCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = closeBtn
    })
    
    -- TabBar (horizontal at top)
    local tabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    local tabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5),
        Parent = tabBar
    })
    
    -- Container for tabs
    local container = CreateInstance("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 1, -80),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    local currentTab = nil
    
    -- Drag functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragStart and dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Close button animation
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        wait(0.3)
        mainFrame.Visible = false
    end)
    
    return mainFrame, tabBar, container, currentTab
end

-- Create Tab (Fixed: Auto-open logic without Fire())
local function CreateTab(hub, name, currentTab)
    local tabBtn = CreateInstance("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = Color3.new(0.25, 0.25, 0.25),
        Text = name,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        Parent = hub.TabBar
    })
    
    local tabCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = tabBtn
    })
    
    local tabFrame = CreateInstance("ScrollingFrame", {
        Name = name .. "Frame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 8,
        ScrollBarImageColor3 = Color3.new(0.8, 0, 0),
        Visible = false,
        Parent = hub.Container
    })
    
    local tabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 5),
        Parent = tabFrame
    })
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Function to open tab (extracted for auto-open)
    local function openTab()
        if hub.CurrentTab then
            hub.CurrentTab.Visible = false
        end
        tabFrame.Visible = true
        hub.CurrentTab = tabFrame
        -- Highlight active tab
        for _, btn in ipairs(hub.TabBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
            end
        end
        tabBtn.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
    end
    
    tabBtn.MouseButton1Click:Connect(openTab)
    
    -- Auto-open first tab (now calls the function directly, no Fire())
    if not hub.CurrentTab then
        openTab()
    end
    
    local tab = {
        Frame = tabFrame,
        NewSection = function(self, sectionName)
            local section = CreateInstance("Frame", {
                Name = sectionName,
                Size = UDim2.new(1, -20, 0, 30),
                BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
                BorderSizePixel = 0,
                Parent = self.Frame
            })
            
            local sectionCorner = CreateInstance("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = section
            })
            
            local sectionLabel = CreateInstance("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section
            })
            
            local sectionLayout = CreateInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 5),
                Parent = section
            })
            
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.Size = UDim2.new(1, -20, 0, sectionLayout.AbsoluteContentSize.Y + 10)
            end)
            
            return {
                NewButton = function(self, text, callback)
                    local button = CreateInstance("TextButton", {
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = Color3.new(0, 0.5, 0),  -- Green accent
                        Text = text,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        BorderSizePixel = 0,
                        Parent = section
                    })
                    
                    local btnCorner = CreateInstance("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = button
                    })
                    
                    button.MouseEnter:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0, 0.7, 0)}):Play()
                    end)
                    
                    button.MouseLeave:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0, 0.5, 0)}):Play()
                    end)
                    
                    button.MouseButton1Click:Connect(callback)
                    return button
                end,
                
                NewToggle = function(self, text, default, callback)
                    local toggleFrame = CreateInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundTransparency = 1,
                        Parent = section
                    })
                    
                    local toggleLabel = CreateInstance("TextLabel", {
                        Size = UDim2.new(1, -50, 1, 0),
                        BackgroundTransparency = 1,
                        Text = text,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        Parent = toggleFrame
                    })
                    
                    local toggleBtn = CreateInstance("TextButton", {
                        Size = UDim2.new(0, 40, 1, 0),
                        Position = UDim2.new(1, -45, 0, 0),
                        BackgroundColor3 = default and Color3.new(0, 0.5, 0) or Color3.new(0.3, 0.3, 0.3),
                        Text = "",
                        BorderSizePixel = 0,
                        Parent = toggleFrame
                    })
                    
                    local toggleCorner = CreateInstance("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = toggleBtn
                    })
                    
                    local state = default
                    toggleBtn.MouseButton1Click:Connect(function()
                        state = not state
                        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.new(0, 0.5, 0) or Color3.new(0.3, 0.3, 0.3)}):Play()
                        callback(state)
                    end)
                    
                    return toggleFrame
                end,
                
                NewSlider = function(self, text, min, max, default, callback)
                    local sliderFrame = CreateInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 50),
                        BackgroundTransparency = 1,
                        Parent = section
                    })
                    
                    local sliderLabel = CreateInstance("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundTransparency = 1,
                        Text = text .. ": " .. default,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = sliderFrame
                    })
                    
                    local sliderBar = CreateInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 10),
                        Position = UDim2.new(0, 0, 0, 25),
                        BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
                        BorderSizePixel = 0,
                        Parent = sliderFrame
                    })
                    
                    local sliderFill = CreateInstance("Frame", {
                        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                        BackgroundColor3 = Color3.new(0, 0.5, 0),
                        BorderSizePixel = 0,
                        Parent = sliderBar
                    })
                    
                    local sliderKnob = CreateInstance("TextButton", {
                        Size = UDim2.new(0, 20, 1, 0),
                        Position = UDim2.new((default - min) / (max - min), -10, 0, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Text = "",
                        BorderSizePixel = 0,
                        Parent = sliderBar
                    })
                    
                    local knobCorner = CreateInstance("UICorner", {
                        CornerRadius = UDim.new(0, 10),
                        Parent = sliderKnob
                    })
                    
                    local dragging = false
                    local value = default
                    
                    local function updateValue()
                        local percent = math.clamp((UserInputService:GetMouseLocation().X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                        value = min + (max - min) * percent
                        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                        sliderKnob.Position = UDim2.new(percent, -10, 0, 0)
                        sliderLabel.Text = text .. ": " .. math.floor(value)
                        callback(value)
                    end
                    
                    sliderKnob.MouseButton1Down:Connect(function()
                        dragging = true
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    
                    RunService.RenderStepped:Connect(function()
                        if dragging then
                            updateValue()
                        end
                    end)
                    
                    return sliderFrame
                end,
                
                NewDropdown = function(self, text, options, default, callback)
                    local dropdownFrame = CreateInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundTransparency = 1,
                        Parent = section
                    })
                    
                    local dropdownLabel = CreateInstance("TextLabel", {
                        Size = UDim2.new(1, -50, 1, 0),
                        BackgroundTransparency = 1,
                        Text = text .. ": " .. (default or options[1]),
                        TextColor3 = Color3.new(1, 1, 1),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        Parent = dropdownFrame
                    })
                    
                    local dropdownBtn = CreateInstance("TextButton", {
                        Size = UDim2.new(0, 40, 1, 0),
                        Position = UDim2.new(1, -45, 0, 0),
                        BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
                        Text = "▼",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        Font = Enum.Font.Gotham,
                        BorderSizePixel = 0,
                        Parent = dropdownFrame
                    })
                    
                    local dropdownCorner = CreateInstance("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = dropdownBtn
                    })
                    
                    local dropdownList = CreateInstance("Frame", {
                        Size = UDim2.new(1, 0, 0, #options * 30),
                        Position = UDim2.new(0, 0, 1, 5),
                        BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
                        Visible = false,
                        BorderSizePixel = 0,
                        Parent = dropdownFrame
                    })
                    
                    local listLayout = CreateInstance("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical,
                        Parent = dropdownList
                    })
                    
                    local selected = default or options[1]
                    for _, option in ipairs(options) do
                        local optionBtn = CreateInstance("TextButton", {
                            Size = UDim2.new(1, 0, 0, 30),
                            BackgroundColor3 = Color3.new(0.25, 0.25, 0.25),
                            Text = option,
                            TextColor3 = Color3.new(1, 1, 1),
                            TextScaled = true,
                            Font = Enum.Font.Gotham,
                            BorderSizePixel = 0,
                            Parent = dropdownList
                        })
                        
                        optionBtn.MouseButton1Click:Connect(function()
                            selected = option
                            dropdownLabel.Text = text .. ": " .. selected
                            dropdownList.Visible = false
                            callback(selected)
                        end)
                    end
                    
                    dropdownBtn.MouseButton1Click:Connect(function()
                        dropdownList.Visible = not dropdownList.Visible
                    end)
                    
                    return dropdownFrame
                end
            }
        end
    }
    
    return tab
end

-- Main Library Function
function Library:NewHub(hubName, keybind)
    keybind = keybind or Enum.KeyCode.K
    local screenGui = CreateScreenGui()
    local mainFrame, tabBar, container, currentTab = CreateMainFrame(screenGui, hubName)
    
    local hub = {
        TabBar = tabBar,
        Container = container,
        CurrentTab = currentTab,
        CreateTab = function(self, name)
            return CreateTab(self, name, self.CurrentTab)
        end
    }
    
    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == keybind then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    
    return hub
end

return Library
