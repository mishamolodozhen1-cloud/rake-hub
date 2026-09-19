-- Rake Remastered Multihack for Delta X (Mobile UI + Red/Black Theme)
-- Update: Flare Gun ESP (Spawn-only), Secure Infinite & Fast Sprint, Noclip Fly, GodMode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    Fly = false, FlySpeed = 1.2,
    NightVision = false, NoFog = false,
    EspMonster = false, EspPlayers = false, EspLocations = false, EspFlareGun = false,
    GodMode = false, FastSprint = false, UIMinimized = false
}

local LocationKeywords = {
    ["shop"] = "Shop", ["store"] = "Shop", ["tower"] = "Tower",
    ["base"] = "Base", ["camp"] = "Base", ["safehouse"] = "Cabin", ["cabin"] = "Cabin"
}
local EspCache = {}
local FlareGunCache = {} -- Кэш для отслеживания сигнального пистолета при спавне

-- Создание интерфейса
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakeDeltaX"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 360)
MainFrame.Position = UDim2.new(0.5, -130, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(220, 20, 20)
Instance.new("UIStroke", MainFrame).Thickness = 2

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DELTA X : RAKE"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 35, 0, 35)
MinButton.Position = UDim2.new(1, -35, 0, 0)
MinButton.BackgroundTransparency = 1
MinButton.Text = "-"
MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinButton.TextSize = 20
MinButton.Font = Enum.Font.GothamBold
MinButton.Parent = TopBar

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -50)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(220, 20, 20)
Container.CanvasSize = UDim2.new(0, 0, 0, 440)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Container

local function AnimateClick(button)
    local tween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(0.9, 0, 0, 36)})
    tween:Play()
    tween.Completed:Wait()
    TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(1, 0, 0, 40)}):Play()
end

local function CreateButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Button.Text = text .. " [OFF]"
    Button.TextColor3 = Color3.fromRGB(150, 150, 150)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = Container
    
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Button)
    Stroke.Color = Color3.fromRGB(40, 40, 40)
    Stroke.Thickness = 1

    local Enabled = false
    Button.MouseButton1Click:Connect(function()
        task.spawn(AnimateClick, Button)
        Enabled = not Enabled
        Button.Text = text .. (Enabled and " [ON]" or " [OFF]")
        Button.TextColor3 = Enabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(150, 150, 150)
        Stroke.Color = Enabled and Color3.fromRGB(220, 20, 20) or Color3.fromRGB(40, 40, 40)
        callback(Enabled)
    end)
    return Button
end

-- Перетаскивание панели
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

MinButton.MouseButton1Click:Connect(function()
    Settings.UIMinimized = not Settings.UIMinimized
    Container.Visible = not Settings.UIMinimized
    MainFrame.Size = Settings.UIMinimized and UDim2.new(0, 260, 0, 35) or UDim2.new(0, 260, 0, 360)
end)

-- Базовая функция ESP
local function CreateEspElements(object, color, text)
    if EspCache[object] then return end
    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = color; Highlight.OutlineColor = color
    Highlight.FillTransparency = 0.7; Highlight.OutlineTransparency = 0.1
    Highlight.Adornee = object; Highlight.Parent = object

    local Billboard = Instance.new("BillboardGui")
    Billboard.AlwaysOnTop = true; Billboard.Size = UDim2.new(0, 150, 0, 30); Billboard.StudsOffset = Vector3.new(0, 4, 0)
    Billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
    Billboard.Parent = object

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0); Label.BackgroundTransparency = 1
    Label.Text = text; Label.TextColor3 = color
    Label.TextStrokeTransparency = 0.1; Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.TextSize = 12; Label.Font = Enum.Font.GothamBold; Label.Parent = Billboard
    EspCache[object] = {Highlight, Billboard}
end

local function ClearAllEsp()
    for obj, elements in pairs(EspCache) do
        for _, v in ipairs(elements) do if v then v:Destroy() end end
    end
    table.clear(EspCache)
end

-- Логика отслеживания появления сигнального пистолета (Flare Gun)
Workspace.DescendantAdded:Connect(function(obj)
    if Settings.EspFlareGun and (obj:IsA("Model") or obj:IsA("Part")) then
        local nameLower = string.lower(obj.Name)
        if string.find(nameLower, "flare") or string.find(nameLower, "signal") or string.find(nameLower, "gun") then
            CreateEspElements(obj, Color3.fromRGB(255, 255, 0), "★ FLARE GUN ★")
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not (Settings.EspMonster or Settings.EspPlayers or Settings.EspLocations or Settings.EspFlareGun) then
        if next(EspCache) ~= nil then ClearAllEsp() end; return
    end
    for obj, elements in pairs(EspCache) do
        if not obj or not obj.Parent then
            for _, v in ipairs(elements) do if v then v:Destroy() end end
            EspCache[obj] = nil
        end
    end

    if Settings.EspPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateEspElements(player.Character, Color3.fromRGB(200, 200, 200), player.Name)
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local nameLower = string.lower(obj.Name)
            if Settings.EspMonster then
                if (string.find(nameLower, "rake") or string.find(nameLower, "monster")) and not Players:GetPlayerFromCharacter(obj) and obj:IsA("Model") then
                    CreateEspElements(obj, Color3.fromRGB(255, 20, 20), "[ RAKE ]")
                end
                if string.find(nameLower, "trap") or string.find(nameLower, "scrap") then
                    CreateEspElements(obj, Color3.fromRGB(255, 120, 20), "TRAP")
                end
            end
            if Settings.EspLocations then
                for key, label in pairs(LocationKeywords) do
                    if string.find(nameLower, key) then CreateEspElements(obj, Color3.fromRGB(20, 220, 220), label); break end
                end
            end
            if Settings.EspFlareGun then
                if string.find(nameLower, "flare") or string.find(nameLower, "signal") then
                    CreateEspElements(obj, Color3.fromRGB(255, 255, 0), "★ FLARE GUN ★")
                end
            end
        end
    end
end)

-- Бесконечный и быстрый бег (Защита от сброса игрой)
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if Settings.FastSprint then
            hum.WalkSpeed = 24 -- Ускоренная скорость бега
        end
        -- Сброс усталости / бесконечная выносливость в телах персонажей
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():match("stamina") or v.Name:lower():match("energy") or v.Name:lower():match("fatigue")) then
                v.Value = 999
            end
        end
    end
end)

-- Fly (Noclip Fly)
local FlyConnection, FlyBodyVel, FlyBodyGyro
local function ToggleFly(state)
    Settings.Fly = state
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")

    if state and hrp and hum then
        hum.PlatformStand = true
        
        FlyBodyVel = Instance.new("BodyVelocity")
        FlyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyVel.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVel.Parent = hrp

        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyGyro.P = 15000
        FlyBodyGyro.CFrame = Camera.CFrame
        FlyBodyGyro.Parent = hrp

        FlyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Fly or not hrp or not hum then return end
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            local moveVector = hum.MoveDirection * (Settings.FlySpeed * 40)
            local yVel = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then yVel = Settings.FlySpeed * 40 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then yVel = -Settings.FlySpeed * 40 end

            FlyBodyVel.Velocity = Vector3.new(moveVector.X, yVel, moveVector.Z)
            FlyBodyGyro.CFrame = Camera.CFrame
        end)
    else
        if FlyConnection then FlyConnection:Disconnect() end
        if FlyBodyVel then FlyBodyVel:Destroy() end
        if FlyBodyGyro then FlyBodyGyro:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end

CreateButton("3D Noclip Fly", ToggleFly)
CreateButton("Fast & Inf Sprint", function(state) Settings.FastSprint = state end)
CreateButton("ESP Flare Gun (Spawn)", function(state) Settings.EspFlareGun = state end)
CreateButton("Night Vision", function(state) Settings.NightVision = state end)
CreateButton("Anti-Fog", function(state) Settings.NoFog = state end)
CreateButton("ESP Monster + Traps", function(state) Settings.EspMonster = state end)
CreateButton("ESP Players", function(state) Settings.EspPlayers = state end)
CreateButton("ESP Locations", function(state) Settings.EspLocations = state end)

-- God Mode
local GodModeConnection
CreateButton("God Mode", function(state)
    Settings.GodMode = state
    if state then
        GodModeConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                if hrp.Velocity.Y < -40 then
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z)
                end
                if hum.Health < hum.MaxHealth and hum.Health > 0 then
                    hum.Health = hum.MaxHealth
                end
            end
        end)
    else
        if GodModeConnection then GodModeConnection:Disconnect() end
    end
end)

-- Освещение и туман
RunService.RenderStepped:Connect(function()
    if Settings.NoFog or Settings.NightVision then
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Fog") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then
                v:Destroy()
            end
        end
    end
    if Settings.NightVision then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 4
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Settings.Fly then task.wait(1); ToggleFly(true) end
end)
