-- Rake Remastered Multihack for Delta X (Mobile + Red/Black Theme)
-- Update: Improved Inf Stamina, Remote Rake Hit (Kill Aura/Reach), Screen Action Button

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    Fly = false, FlySpeed = 2,
    NightVision = false, NoFog = false,
    EspMonster = false, EspPlayers = false, EspLocations = false, EspFlareGun = false,
    GodMode = false, FastSprint = false, UIMinimized = false
}

local LocationKeywords = {
    ["shop"] = "Shop", ["store"] = "Shop", ["tower"] = "Tower",
    ["base"] = "Base", ["camp"] = "Base", ["safehouse"] = "Cabin", ["cabin"] = "Cabin"
}
local ItemList = {"Stun Stick", "Medkit", "Flare Gun", "Tracker", "UV Flashlight", "Scrap", "Vitamins", "Bear Trap"}
local EspCache = {}

local SelectedPlayerIndex = 1
local SelectedItemIndex = 1

-- Создание главного интерфейса
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakeDeltaX"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Кнопка удара на экране (по умолчанию скрыта)
local HitButton = Instance.new("TextButton")
HitButton.Size = UDim2.new(0, 70, 0, 70)
HitButton.Position = UDim2.new(1, -90, 0.6, 0)
HitButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HitButton.Text = "HIT\nRAKE"
HitButton.TextColor3 = Color3.fromRGB(255, 50, 50)
HitButton.Font = Enum.Font.GothamBold
HitButton.TextSize = 14
HitButton.Visible = false
HitButton.Parent = ScreenGui

Instance.new("UICorner", HitButton).CornerRadius = UDim.new(1, 0) -- Круглая кнопка
local HitStroke = Instance.new("UIStroke", HitButton)
HitStroke.Color = Color3.fromRGB(220, 20, 20)
HitStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 420)
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
Container.CanvasSize = UDim2.new(0, 0, 0, 850)
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

local function CreateButton(text, callback, isAction)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Button.Text = text .. (isAction and "" or " [OFF]")
    Button.TextColor3 = isAction and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = Container
    
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Button)
    Stroke.Color = isAction and Color3.fromRGB(180, 20, 20) or Color3.fromRGB(40, 40, 40)
    Stroke.Thickness = 1

    local Enabled = false
    Button.MouseButton1Click:Connect(function()
        task.spawn(AnimateClick, Button)
        if not isAction then
            Enabled = not Enabled
            Button.Text = text .. (Enabled and " [ON]" or " [OFF]")
            Button.TextColor3 = Enabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(150, 150, 150)
            Stroke.Color = Enabled and Color3.fromRGB(220, 20, 20) or Color3.fromRGB(40, 40, 40)
        end
        callback(Enabled, Button)
    end)
    return Button
end

-- Drag & Minimize Logic
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
    MainFrame.Size = Settings.UIMinimized and UDim2.new(0, 260, 0, 35) or UDim2.new(0, 260, 0, 420)
end)

-- Find Rake Logic
local function GetRake()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "Rake" or obj.Name == "The Rake") and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
            if not Players:GetPlayerFromCharacter(obj) then
                return obj
            end
        end
    end
    return nil
end

-- Дистанционный удар по Рейку (Kill Aura / Reach)
HitButton.MouseButton1Click:Connect(function()
    -- Анимация кнопки
    TweenService:Create(HitButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 60, 0, 60)}):Play()
    task.wait(0.1)
    TweenService:Create(HitButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 70, 0, 70)}):Play()

    local rake = GetRake()
    if not rake then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end

    -- Поиск дубинки в инвентаре или в руках
    local stunStick = nil
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if string.find(string.lower(item.Name), "stun") then stunStick = item; break end
    end
    if not stunStick then
        for _, item in ipairs(char:GetChildren()) do
            if string.find(string.lower(item.Name), "stun") then stunStick = item; break end
        end
    end

    if stunStick then
        -- Берем в руки и активируем
        char.Humanoid:EquipTool(stunStick)
        stunStick:Activate()

        local handle = stunStick:FindFirstChild("Handle")
        local targetPart = rake:FindFirstChild("HumanoidRootPart") or rake:FindFirstChild("Torso")

        -- Виртуальное касание (Touch Interest Bypass)
        if handle and targetPart and firetouchinterest then
            firetouchinterest(handle, targetPart, 0) -- Касание
            task.wait(0.05)
            firetouchinterest(handle, targetPart, 1) -- Отпускание
        end
    end
end)

-- Перетаскивание круглой кнопки удара по экрану
local btnDragging, btnDragInput, btnDragStart, btnStartPos
HitButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true; btnDragStart = input.Position; btnStartPos = HitButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then btnDragging = false end
        end)
    end
end)
HitButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then btnDragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == btnDragInput and btnDragging then
        local delta = input.Position - btnDragStart
        HitButton.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)

-- ESP System (сокращено для примера, логика та же)
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
    Label.Size = UDim2.new(1, 0, 1, 0); Label.BackgroundTransparency = 1; Label.Text = text; Label.TextColor3 = color
    Label.TextStrokeTransparency = 0.1; Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.TextSize = 12; Label.Font = Enum.Font.GothamBold; Label.Parent = Billboard
    EspCache[object] = {Highlight, Billboard}
end

local function ClearAllEsp()
    for obj, elements in pairs(EspCache) do for _, v in ipairs(elements) do if v then v:Destroy() end end end
    table.clear(EspCache)
end

Workspace.DescendantAdded:Connect(function(obj)
    if Settings.EspFlareGun and (obj:IsA("Model") or obj:IsA("Part")) then
        if string.find(string.lower(obj.Name), "flare") or string.find(string.lower(obj.Name), "signal") then
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
            for _, v in ipairs(elements) do if v then v:Destroy() end end; EspCache[obj] = nil
        end
    end

    if Settings.EspPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then CreateEspElements(p.Character, Color3.fromRGB(200, 200, 200), p.Name) end
        end
    end

    if Settings.EspMonster then
        local rake = GetRake()
        if rake then CreateEspElements(rake, Color3.fromRGB(255, 20, 20), "[ RAKE ]") end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (string.find(string.lower(obj.Name), "trap") or string.find(string.lower(obj.Name), "scrap")) then
                CreateEspElements(obj, Color3.fromRGB(255, 120, 20), "TRAP")
            end
        end
    end

    if Settings.EspLocations then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                for key, label in pairs(LocationKeywords) do
                    if string.find(string.lower(obj.Name), key) then CreateEspElements(obj, Color3.fromRGB(20, 220, 220), label); break end
                end
            end
        end
    end
end)

-- Safe CFrame Fly
local FlyConnection
local function ToggleFly(state)
    Settings.Fly = state
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if state and hrp and hum then
        hrp.Anchored = true
        FlyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Fly or not hrp then return end
            local moveVector = Vector3.new(0, 0, 0)
            if hum.MoveDirection.Magnitude > 0 then
                local camLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
                local camRight = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z).Unit
                local fwd = camLook:Dot(hum.MoveDirection)
                local rgt = camRight:Dot(hum.MoveDirection)
                moveVector = (Camera.CFrame.LookVector * fwd) + (Camera.CFrame.RightVector * rgt)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            if moveVector.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (moveVector.Unit * Settings.FlySpeed) end
        end)
    else
        if FlyConnection then FlyConnection:Disconnect() end
        if hrp then hrp.Anchored = false end
    end
end

-- УЛУЧШЕННЫЙ Fast Sprint & Infinite Stamina
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        
        -- Ускорение
        if Settings.FastSprint and hum.MoveDirection.Magnitude > 0 and not Settings.Fly then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * 0.4)
        end
        
        -- Полная заморозка значений стамины во всех возможных местах игры
        if Settings.FastSprint then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    if string.find(string.lower(v.Name), "stamina") or string.find(string.lower(v.Name), "energy") then
                        v.Value = 100
                    end
                end
            end
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, v in ipairs(playerGui:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        if string.find(string.lower(v.Name), "stamina") then v.Value = 100 end
                    end
                end
            end
        end
    end
end)

-- Toggles
CreateButton("Show 'Hit Rake' Screen Button", function(state) HitButton.Visible = state end)
CreateButton("Safe CFrame Fly", ToggleFly)
CreateButton("Fast Sprint + Inf Stamina", function(state) Settings.FastSprint = state end)
CreateButton("God Mode (Anti-Fall)", function(state) Settings.GodMode = state end)
CreateButton("Night Vision", function(state) Settings.NightVision = state end)
CreateButton("Anti-Fog", function(state) Settings.NoFog = state end)
CreateButton("ESP Rake & Traps", function(state) Settings.EspMonster = state end)
CreateButton("ESP Players", function(state) Settings.EspPlayers = state end)
CreateButton("ESP Locations", function(state) Settings.EspLocations = state end)
CreateButton("ESP Flare Gun (Spawn)", function(state) Settings.EspFlareGun = state end)

-- God Mode
RunService.Heartbeat:Connect(function()
    if Settings.GodMode then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = char.Humanoid.MaxHealth
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("LocalScript") and string.find(string.lower(v.Name), "fall") then v:Destroy() end
            end
        end
    end
end)

-- Rake Tools & Teleport
local PlayerSelectBtn = CreateButton("Select Player: " .. Players:GetPlayers()[1].Name, function(_, btn)
    local list = Players:GetPlayers()
    SelectedPlayerIndex = SelectedPlayerIndex + 1
    if SelectedPlayerIndex > #list then SelectedPlayerIndex = 1 end
    btn.Text = "Select Player: " .. list[SelectedPlayerIndex].Name
end, true)

CreateButton("» TP Rake to Player", function()
    local rake = GetRake()
    local targetPlayer = Players:GetPlayers()[SelectedPlayerIndex]
    if rake and rake:FindFirstChild("HumanoidRootPart") and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        rake:PivotTo(targetPlayer.Character.HumanoidRootPart.CFrame)
    end
end, true)

CreateButton("» Bug Monster (Freeze)", function()
    local rake = GetRake()
    if rake then
        for _, v in ipairs(rake:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true end end
    end
end, true)

-- Item Giver
local ItemSelectBtn = CreateButton("Select Item: " .. ItemList[1], function(_, btn)
    SelectedItemIndex = SelectedItemIndex + 1
    if SelectedItemIndex > #ItemList then SelectedItemIndex = 1 end
    btn.Text = "Select Item: " .. ItemList[SelectedItemIndex]
end, true)

CreateButton("» Give Selected Item", function()
    local itemName = ItemList[SelectedItemIndex]
    local foundItem = ReplicatedStorage:FindFirstChild(itemName, true) or Workspace:FindFirstChild(itemName, true)
    
    if foundItem and foundItem:IsA("Tool") then
        local clone = foundItem:Clone()
        clone.Parent = LocalPlayer.Backpack
    end
end, true)

-- Lighting Overrides
RunService.RenderStepped:Connect(function()
    if Settings.NoFog or Settings.NightVision then
        Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Fog") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then v:Destroy() end
        end
    end
    if Settings.NightVision then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 4; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Settings.Fly then task.wait(1); ToggleFly(true) end
end)
