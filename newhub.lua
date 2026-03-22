local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local RunService = game:GetService("RunService")

local Window = Rayfield:CreateWindow({
    Name = "CFrame Fixed Bot",
    LoadingTitle = "Final Correction",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = { Enabled = false }
})

local _G = {
    Enabled = false,
    Targets = {},
    Radius = 1000,
    Speed = 16,
    HeightOffset = 7 -- Чуть выше, чтобы точно не застрять
}

local currentTarget = nil

-- Глубокий, но редкий поиск (не лагает)
task.spawn(function()
    while true do
        if _G.Enabled and #_G.Targets > 0 then
            local player = game.Players.LocalPlayer
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                local closest = nil
                local minDist = _G.Radius
                
                -- Перебор всех объектов в Workspace (раз в секунду - это не лагает)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if table.find(_G.Targets, obj.Name) and (obj:IsA("Model") or obj:IsA("BasePart")) then
                        local p = obj:GetPivot().Position
                        local d = (root.Position - p).Magnitude
                        if d < minDist then
                            minDist = d
                            closest = obj
                        end
                    end
                end
                
                if closest then
                    currentTarget = closest
                else
                    currentTarget = nil
                end
            end
        end
        task.wait(1) -- Ищем раз в секунду, чтобы убрать лаги на 100%
    end
end)

-- Движение через CFrame
RunService.Heartbeat:Connect(function(deltaTime)
    if _G.Enabled and currentTarget and currentTarget.Parent then
        local char = game.Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if root then
            -- Полный стоп физики (анти-гравити)
            root.Velocity = Vector3.new(0, 0, 0)
            
            local targetPos = currentTarget:GetPivot().Position
            local destination = targetPos + Vector3.new(0, _G.HeightOffset, 0)
            
            local direction = (destination - root.Position)
            local distance = direction.Magnitude

            if distance > 1 then
                -- Движение со скоростью 16
                local moveDir = direction.Unit
                root.CFrame = root.CFrame + (moveDir * _G.Speed * deltaTime)
            else
                -- Фиксация позиции над целью, смотрим вниз на цель
                root.CFrame = CFrame.new(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
            end
        end
    end
end)

local MainTab = Window:CreateTab("Main Settings")

MainTab:CreateToggle({
    Name = "Включить CFrame движение",
    CurrentValue = false,
    Callback = function(v) 
        _G.Enabled = v 
        if not v then currentTarget = nil end
    end,
})

MainTab:CreateDropdown({
    Name = "Цели (выбери несколько)",
    Options = {"Gold Pot", "Mega Gold Pot", "Golden Gold Pot", "Mega Golden Gold Pot"},
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(v) _G.Targets = v end,
})

MainTab:CreateSlider({
    Name = "Радиус поиска",
    Range = {0, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(v) _G.Radius = v end,
})

MainTab:CreateSlider({
    Name = "Скорость полета",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) _G.Speed = v end,
})
