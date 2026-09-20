-- Rake Hub-Beta [OPTIMIZED + MULTI-LANG + DOUBLE CONFIRMATION ESP]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local WIDTH = isMobile and 260 or 340
local HEIGHT = isMobile and 340 or 440
local TEXT_SM = isMobile and 11 or 13
local TEXT_MD = isMobile and 12 or 14
local TEXT_LG = isMobile and 14 or 18
local ELEMENT_H = isMobile and 32 or 38

local Settings = {
    NightVision = false, NoFog = false,
    EspMonster = false, EspPlayers = false, EspLocations = false, EspItems = false,
    FastSprint = false
}

local LocationKeywords = {
    ["shop"] = "Shop", ["store"] = "Shop", ["tower"] = "Tower",
    ["base"] = "Base", ["camp"] = "Base", ["safehouse"] = "Cabin", ["cabin"] = "Cabin"
}

local LanguagesList = {
    "Русский (Russian)", "English", "Español (Spanish)", "Deutsch (German)",
    "Français (French)", "Português (Portuguese)", "Türkçe (Turkish)",
    "Українська (Ukrainian)", "Polski (Polish)", "Italiano (Italian)",
    "中文 (Chinese)", "日本語 (Japanese)", "한국어 (Korean)", "العربية (Arabic)"
}

local EspCache = {}
local UIElements = {}
local Connections = {}
local FileName = "RakeHubBeta_SavedName.txt"
local isMenuOpen = false
local scriptRunning = true
local SelectedLanguage = "Русский (Russian)"

local Colors = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(28, 28, 34),
    Stroke = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(210, 55, 65),
    ConfirmWarning = Color3.fromRGB(220, 130, 30),
    TextWhite = Color3.fromRGB(235, 235, 240),
    TextGray = Color3.fromRGB(130, 130, 140)
}

local function GetSavedName()
    if isfile and isfile(FileName) then
        local success, name = pcall(function() return readfile(FileName) end)
        if success and name and string.gsub(name, "%s+", "") ~= "" then return name end
    end
    return nil
end

local function SaveName(name)
    if writefile then pcall(function() writefile(FileName, name) end) end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakeHub_Beta_UI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function DestroyScript()
    scriptRunning = false
    
    for _, conn in ipairs(Connections) do
        if type(conn) == "RBXScriptConnection" then conn:Disconnect()
        elseif type(conn) == "thread" then task.cancel(conn) end
    end
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "RakeHubESP_HL" or v.Name == "RakeHubESP_BB" then v:Destroy() end
    end
    for obj, data in pairs(EspCache) do
        for _, v in ipairs(data.Elements) do pcall(function() v:Destroy() end) end
    end
    EspCache = {}
    
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true
    
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    
    if ScreenGui then ScreenGui:Destroy() end
end

-- Мобильная кнопка
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Size = UDim2.new(0, 46, 0, 46)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -23)
MobileToggleBtn.BackgroundColor3 = Colors.Panel
MobileToggleBtn.Text = "RH"
MobileToggleBtn.TextColor3 = Colors.TextWhite
MobileToggleBtn.Font = Enum.Font.GothamBlack
MobileToggleBtn.TextSize = 18
MobileToggleBtn.Visible = false
MobileToggleBtn.Parent = ScreenGui
Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MobileToggleBtn).Color = Colors.Stroke

local rDragging, rDragInput, rDragStart, rStartPos
MobileToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rDragging = true; rDragStart = input.Position; rStartPos = MobileToggleBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then rDragging = false end end)
        TweenService:Create(MobileToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 42, 0, 42)}):Play()
    end
end)
MobileToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(MobileToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 46, 0, 46)}):Play()
    end
end)
MobileToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then rDragInput = input end
end)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == rDragInput and rDragging then
        local delta = input.Position - rDragStart
        MobileToggleBtn.Position = UDim2.new(rStartPos.X.Scale, rStartPos.X.Offset + delta.X, rStartPos.Y.Scale, rStartPos.Y.Offset + delta.Y)
    end
end))

-- Экран загрузки
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(0, WIDTH, 0, 100)
LoadFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -50)
LoadFrame.BackgroundColor3 = Colors.Background
LoadFrame.BorderSizePixel = 0
LoadFrame.ClipsDescendants = true
LoadFrame.Parent = ScreenGui
Instance.new("UICorner", LoadFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LoadFrame).Color = Colors.Stroke

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 30)
LoadTitle.Position = UDim2.new(0, 0, 0, 15)
LoadTitle.BackgroundTransparency = 1
LoadTitle.RichText = true
LoadTitle.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
LoadTitle.TextColor3 = Colors.TextWhite
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = TEXT_LG
LoadTitle.Parent = LoadFrame

local PercentText = Instance.new("TextLabel")
PercentText.Size = UDim2.new(1, 0, 0, 20)
PercentText.Position = UDim2.new(0, 0, 0, 42)
PercentText.BackgroundTransparency = 1
PercentText.Text = "Инициализация... 0%"
PercentText.TextColor3 = Colors.TextGray
PercentText.Font = Enum.Font.GothamMedium
PercentText.TextSize = TEXT_SM
PercentText.Parent = LoadFrame

local LoadBarBg = Instance.new("Frame")
LoadBarBg.Size = UDim2.new(0.86, 0, 0, 4)
LoadBarBg.Position = UDim2.new(0.07, 0, 0.75, 0)
LoadBarBg.BackgroundColor3 = Colors.Panel
LoadBarBg.BorderSizePixel = 0
LoadBarBg.Parent = LoadFrame
Instance.new("UICorner", LoadBarBg).CornerRadius = UDim.new(1, 0)

local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0, 0, 1, 0)
LoadBar.BackgroundColor3 = Colors.Accent
LoadBar.BorderSizePixel = 0
LoadBar.Parent = LoadBarBg
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(1, 0)

-- Окно выбора языка
local LangFrame = Instance.new("Frame")
LangFrame.Size = UDim2.new(0, WIDTH, 0, 290)
LangFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -145)
LangFrame.BackgroundColor3 = Colors.Background
LangFrame.BorderSizePixel = 0
LangFrame.Visible = false
LangFrame.ClipsDescendants = true
LangFrame.Parent = ScreenGui
Instance.new("UICorner", LangFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LangFrame).Color = Colors.Stroke

local LangTitle = Instance.new("TextLabel")
LangTitle.Size = UDim2.new(1, 0, 0, 25)
LangTitle.Position = UDim2.new(0, 0, 0, 10)
LangTitle.BackgroundTransparency = 1
LangTitle.Text = "ВЫБЕРИТЕ ЯЗЫК"
LangTitle.TextColor3 = Colors.TextWhite
LangTitle.Font = Enum.Font.GothamBold
LangTitle.TextSize = TEXT_MD
LangTitle.Parent = LangFrame

local LangSearch = Instance.new("TextBox")
LangSearch.Size = UDim2.new(0.86, 0, 0, 30)
LangSearch.Position = UDim2.new(0.07, 0, 0, 40)
LangSearch.BackgroundColor3 = Colors.Panel
LangSearch.BorderSizePixel = 0
LangSearch.PlaceholderText = "Поиск языка..."
LangSearch.PlaceholderColor3 = Colors.TextGray
LangSearch.Text = ""
LangSearch.TextColor3 = Colors.TextWhite
LangSearch.Font = Enum.Font.GothamMedium
LangSearch.TextSize = TEXT_SM
LangSearch.Parent = LangFrame
Instance.new("UICorner", LangSearch).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", LangSearch).Color = Colors.Stroke

local LangContainer = Instance.new("ScrollingFrame")
LangContainer.Size = UDim2.new(0.86, 0, 0, 140)
LangContainer.Position = UDim2.new(0.07, 0, 0, 78)
LangContainer.BackgroundTransparency = 1
LangContainer.ScrollBarThickness = 3
LangContainer.ScrollBarImageColor3 = Colors.Stroke
LangContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
LangContainer.Parent = LangFrame

local LangListLayout = Instance.new("UIListLayout")
LangListLayout.Padding = UDim.new(0, 4)
LangListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
LangListLayout.Parent = LangContainer

local LangConfirmBtn = Instance.new("TextButton")
LangConfirmBtn.Size = UDim2.new(0.86, 0, 0, 34)
LangConfirmBtn.Position = UDim2.new(0.07, 0, 0, 238)
LangConfirmBtn.BackgroundColor3 = Colors.Accent
LangConfirmBtn.BorderSizePixel = 0
LangConfirmBtn.Text = "ПОДТВЕРДИТЬ"
LangConfirmBtn.TextColor3 = Colors.TextWhite
LangConfirmBtn.Font = Enum.Font.GothamBold
LangConfirmBtn.TextSize = TEXT_SM
LangConfirmBtn.Parent = LangFrame
Instance.new("UICorner", LangConfirmBtn).CornerRadius = UDim.new(0, 6)

local LangButtons = {}
local SelectedLangBtn = nil

for _, langName in ipairs(LanguagesList) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 26)
    Btn.BackgroundColor3 = Colors.Panel
    Btn.BorderSizePixel = 0
    Btn.Text = langName
    Btn.TextColor3 = Colors.TextGray
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = TEXT_SM
    Btn.Parent = LangContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", Btn)
    stroke.Color = Colors.Stroke
    stroke.Transparency = 0.5

    Btn.MouseButton1Click:Connect(function()
        SelectedLanguage = langName
        if SelectedLangBtn then
            TweenService:Create(SelectedLangBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Panel, TextColor3 = Colors.TextGray}):Play()
        end
        SelectedLangBtn = Btn
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent, TextColor3 = Colors.TextWhite}):Play()
    end)
    table.insert(LangButtons, Btn)
end
LangContainer.CanvasSize = UDim2.new(0, 0, 0, LangListLayout.AbsoluteContentSize.Y + 10)

LangSearch:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(LangSearch.Text)
    for _, btn in ipairs(LangButtons) do
        if query == "" or string.find(string.lower(btn.Text), query) then
            btn.Visible = true
        else
            btn.Visible = false
        end
    end
    LangContainer.CanvasSize = UDim2.new(0, 0, 0, LangListLayout.AbsoluteContentSize.Y + 10)
end)

-- Окно ввода имени
local NameFrame = Instance.new("Frame")
NameFrame.Size = UDim2.new(0, WIDTH, 0, 200)
NameFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -100)
NameFrame.BackgroundColor3 = Colors.Background
NameFrame.BorderSizePixel = 0
NameFrame.Visible = false
NameFrame.ClipsDescendants = true
NameFrame.Parent = ScreenGui
Instance.new("UICorner", NameFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", NameFrame).Color = Colors.Stroke

local AskLabel = Instance.new("TextLabel")
AskLabel.Size = UDim2.new(1, 0, 0, 20)
AskLabel.Position = UDim2.new(0, 0, 0, 35)
AskLabel.BackgroundTransparency = 1
AskLabel.Text = "Введите ваше имя"
AskLabel.TextColor3 = Colors.TextWhite
AskLabel.Font = Enum.Font.GothamBold
AskLabel.TextSize = TEXT_MD
AskLabel.Parent = NameFrame

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0.86, 0, 0, 36)
NameInput.Position = UDim2.new(0.07, 0, 0, 75)
NameInput.BackgroundColor3 = Colors.Panel
NameInput.BorderSizePixel = 0
NameInput.PlaceholderText = "Имя пользователя..."
NameInput.PlaceholderColor3 = Colors.TextGray
NameInput.Text = ""
NameInput.TextColor3 = Colors.TextWhite
NameInput.Font = Enum.Font.GothamMedium
NameInput.TextSize = TEXT_MD
NameInput.Parent = NameFrame
Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", NameInput).Color = Colors.Stroke

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.86, 0, 0, 34)
SubmitBtn.Position = UDim2.new(0.07, 0, 0, 130)
SubmitBtn.BackgroundColor3 = Colors.Accent
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Text = "ВОЙТИ"
SubmitBtn.TextColor3 = Colors.TextWhite
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = TEXT_MD
SubmitBtn.Parent = NameFrame
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

-- Главное меню
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
MainFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -(HEIGHT/2))
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Colors.Stroke

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Colors.Panel
TopBar.Active = true
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
Title.TextColor3 = Colors.TextWhite
Title.TextSize = TEXT_MD
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Colors.TextGray
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar
CloseButton.MouseButton1Click:Connect(DestroyScript)

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 65, 65), TextSize = 18}):Play()
end)
CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Colors.TextGray, TextSize = 16}):Play()
end)

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -16, 1, -54)
Container.Position = UDim2.new(0, 8, 0, 46)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Colors.Stroke
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Container

local function CreateElement(text, callback, isAction, customColor)
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    Wrapper.BackgroundTransparency = 1
    Wrapper.Parent = Container

    local Element = Instance.new("TextButton")
    Element.Size = UDim2.new(1, 0, 1, 0)
    Element.Position = UDim2.new(0, -30, 0, 0)
    Element.BackgroundColor3 = Colors.Panel
    Element.BackgroundTransparency = 1
    Element.Text = ""
    Element.AutoButtonColor = false
    Element.Parent = Wrapper
    
    Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Element)
    Stroke.Color = Colors.Stroke
    Stroke.Transparency = 1

    local Label = Instance.new("TextLabel")
    Label.Size = isAction and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -46, 1, 0)
    Label.Position = isAction and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = isAction and (customColor or Colors.TextWhite) or Colors.TextGray
    Label.TextSize = TEXT_SM
    Label.Font = Enum.Font.GothamMedium
    Label.TextTransparency = 1
    Label.TextXAlignment = isAction and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    Label.Parent = Element
    
    local Knob, SwitchBg, SwitchStroke
    if not isAction then
        SwitchBg = Instance.new("Frame")
        SwitchBg.Size = UDim2.new(0, 34, 0, 18)
        SwitchBg.Position = UDim2.new(1, -42, 0.5, -9)
        SwitchBg.BackgroundColor3 = Colors.Background
        SwitchBg.BackgroundTransparency = 1
        SwitchBg.Parent = Element
        Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
        SwitchStroke = Instance.new("UIStroke", SwitchBg)
        SwitchStroke.Color = Colors.Stroke
        SwitchStroke.Transparency = 1

        Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.Position = UDim2.new(0, 3, 0.5, -6)
        Knob.BackgroundColor3 = Colors.TextGray
        Knob.BackgroundTransparency = 1
        Knob.Parent = SwitchBg
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local Enabled = false
        Element.MouseButton1Click:Connect(function()
            Enabled = not Enabled
            local activeColor = customColor or Colors.Accent
            TweenService:Create(Knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = Enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Enabled and Colors.TextWhite or Colors.TextGray
            }):Play()
            TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = Enabled and activeColor or Colors.Background}):Play()
            TweenService:Create(SwitchStroke, TweenInfo.new(0.3), {Color = Enabled and activeColor or Colors.Stroke}):Play()
            TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Enabled and Colors.TextWhite or Colors.TextGray}):Play()
            callback(Enabled)
        end)
    else
        Element.MouseButton1Click:Connect(function()
            TweenService:Create(Element, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(0.95, 0, 0, ELEMENT_H - 4)}):Play()
            task.wait(0.1)
            TweenService:Create(Element, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            callback()
        end)
    end

    table.insert(UIElements, {Element = Element, Stroke = Stroke, Label = Label, SwitchBg = SwitchBg, SwitchStroke = SwitchStroke, Knob = Knob})
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
    return Element
end

local function ResetCascadeElements()
    for _, item in ipairs(UIElements) do
        item.Element.Position = UDim2.new(0, -35, 0, 0)
        item.Element.BackgroundTransparency = 1
        item.Stroke.Transparency = 1
        item.Label.TextTransparency = 1
        if item.SwitchBg then
            item.SwitchBg.BackgroundTransparency = 1
            item.Knob.BackgroundTransparency = 1
            item.SwitchStroke.Transparency = 1
        end
    end
end

local function PlayCascadeAnimation()
    for _, item in ipairs(UIElements) do
        TweenService:Create(item.Element, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(item.Stroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
        TweenService:Create(item.Label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        if item.SwitchBg then
            TweenService:Create(item.SwitchBg, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(item.Knob, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(item.SwitchStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
        end
        task.wait(0.04)
    end
end

local function ToggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        MainFrame.Visible = true
        ResetCascadeElements()
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, HEIGHT)}):Play()
        task.delay(0.15, PlayCascadeAnimation)
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
        task.delay(0.35, function() if not isMenuOpen then MainFrame.Visible = false end end)
    end
end

local function ShowMain(name)
    MobileToggleBtn.Visible = true 
    isMenuOpen = true
    MainFrame.Size = UDim2.new(0, WIDTH, 0, 0)
    MainFrame.Visible = true
    ResetCascadeElements()
    TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, HEIGHT)}):Play()
    task.delay(0.15, PlayCascadeAnimation)
end

local function ShowNameFrame()
    NameFrame.Visible = true
    NameFrame.Size = UDim2.new(0, WIDTH, 0, 0)
    TweenService:Create(NameFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, 200)}):Play()
end

-- Переход выбора языка с ДВОЙНЫМ ПОДТВЕРЖДЕНИЕМ
local langConfirmStep = 0
LangConfirmBtn.MouseButton1Click:Connect(function()
    if langConfirmStep == 0 then
        langConfirmStep = 1
        LangConfirmBtn.Text = "ТОЧНО? НАЖМИТЕ ЕЩЁ РАЗ"
        TweenService:Create(LangConfirmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.ConfirmWarning}):Play()
    elseif langConfirmStep == 1 then
        TweenService:Create(LangConfirmBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.82, 0, 0, 30)}):Play()
        task.wait(0.1)
        TweenService:Create(LangFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
        task.wait(0.3)
        LangFrame:Destroy()
        ShowNameFrame()
    end
end)

local function OnNameSubmitted()
    local enteredName = NameInput.Text
    if enteredName == "" or string.gsub(enteredName, "%s+", "") == "" then enteredName = LocalPlayer.DisplayName end
    SaveName(enteredName)
    TweenService:Create(SubmitBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.82, 0, 0, 30)}):Play()
    task.wait(0.1)
    TweenService:Create(NameFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
    task.wait(0.3)
    NameFrame:Destroy()
    ShowMain(enteredName)
end
SubmitBtn.MouseButton1Click:Connect(OnNameSubmitted)
NameInput.FocusLost:Connect(function(enterPressed) if enterPressed then OnNameSubmitted() end end)

task.spawn(function()
    TweenService:Create(LoadBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    for i = 1, 100, 7 do 
        PercentText.Text = "Загрузка скриптов... " .. i .. "%"
        task.wait(0.04) 
    end
    PercentText.Text = "Успешно! Запуск интерфейса."
    task.wait(0.3)
    TweenService:Create(LoadFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
    task.wait(0.3)
    LoadFrame:Destroy()

    local savedName = GetSavedName()
    if savedName then 
        ShowMain(savedName)
    else
        LangFrame.Visible = true
        LangFrame.Size = UDim2.new(0, WIDTH, 0, 0)
        TweenService:Create(LangFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, 290)}):Play()
    end
end)

MobileToggleBtn.MouseButton1Click:Connect(function() if not rDragging then ToggleMenu() end end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

-- ОПТИМИЗИРОВАННЫЙ И БЫСТРЫЙ ESP
local function CreateEspElements(object, color, text, useHighlight, espType)
    if EspCache[object] then return end
    local elements = {}
    
    if useHighlight then
        local Highlight = Instance.new("Highlight")
        Highlight.Name = "RakeHubESP_HL"
        Highlight.FillColor = color; Highlight.OutlineColor = color
        Highlight.FillTransparency = 0.65
        Highlight.OutlineTransparency = 0.1
        Highlight.Adornee = object; Highlight.Parent = object
        table.insert(elements, Highlight)
    end
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "RakeHubESP_BB"
    Billboard.AlwaysOnTop = true
    Billboard.MaxDistance = 600 -- Ограничение дистанции для исключения лагов
    Billboard.Size = UDim2.new(0, 130, 0, 22)
    Billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    Billboard.Adornee = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
    Billboard.Parent = object
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color
    Label.TextStrokeTransparency = 0.2
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.TextSize = isMobile and 10 or 12
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Billboard
    table.insert(elements, Billboard)
    
    EspCache[object] = {Elements = elements, Type = espType, LabelText = text}
end

-- КЭШИРОВАННЫЙ И ОПТИМИЗИРОВАННЫЙ ПОИСК
local CachedRake = nil
local function GetRake()
    if CachedRake and CachedRake.Parent then
        local hum = CachedRake:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return CachedRake end
    end
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local n = string.lower(obj.Name)
            if string.find(n, "rake") or string.find(n, "monster") or obj.Name == "Rake" then
                if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("HumanoidRootPart") then
                    CachedRake = obj; return obj
                end
            end
        end
    end
    return nil
end

local function IsValidScrap(obj)
    local n = string.lower(obj.Name)
    if string.find(n, "scrap") then
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if part and part.Size.Magnitude < 15 then 
            return part
        end
    end
    return nil
end

-- В Heartbeat оставлен только минимальный цикл проверки состояния (без скана GetDescendants)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not scriptRunning then return end
    
    for obj, data in pairs(EspCache) do
        if not obj or not obj.Parent or not Settings[data.Type] then
            for _, v in ipairs(data.Elements) do if v then pcall(function() v:Destroy() end) end end
            EspCache[obj] = nil
        end
    end
    
    if Settings.EspPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                CreateEspElements(p.Character, Color3.fromRGB(220, 220, 230), p.Name, true, "EspPlayers")
            end
        end
    end
end))

-- Оптимизированный фоновый сканнер (Выполняется раз в 1.5 сек, убирает фризы)
local espThread = task.spawn(function()
    while scriptRunning do
        if Settings.EspMonster then
            local rake = GetRake()
            if rake then CreateEspElements(rake, Color3.fromRGB(255, 30, 30), "RAKE", true, "EspMonster") end
            
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not scriptRunning then break end
                local n = string.lower(obj.Name)
                if (string.find(n, "trap") or string.find(n, "bear")) and not string.find(n, "scrap") then
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        CreateEspElements(obj, Color3.fromRGB(255, 130, 0), "TRAP", true, "EspMonster")
                    end
                end
            end
        end
        
        if Settings.EspLocations then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not scriptRunning then break end
                if obj:IsA("Model") or obj:IsA("Part") then
                    local n = string.lower(obj.Name)
                    for key, label in pairs(LocationKeywords) do
                        if string.find(n, key) then CreateEspElements(obj, Color3.fromRGB(65, 160, 120), label, false, "EspLocations"); break end
                    end
                end
            end
        end
        
        if Settings.EspItems then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not scriptRunning then break end
                if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("Tool") then
                    local n = string.lower(obj.Name)
                    if (string.find(n, "flare gun") or string.find(n, "flaregun")) and not string.find(n, "note") then 
                        CreateEspElements(obj, Color3.fromRGB(200, 110, 50), "FLARE GUN", true, "EspItems") 
                    end
                    local scrapPart = IsValidScrap(obj)
                    if scrapPart then 
                        CreateEspElements(obj, Color3.fromRGB(150, 150, 155), "SCRAP", true, "EspItems") 
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)
table.insert(Connections, espThread)

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not scriptRunning then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Settings.FastSprint then hum.WalkSpeed = 28 else
                if hum.WalkSpeed > 16 and hum.WalkSpeed == 28 then hum.WalkSpeed = 16 end
            end
        end
    end
    if Settings.NoFog or Settings.NightVision then Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9 end
    if Settings.NightVision then
        Lighting.Ambient = Color3.fromRGB(230, 230, 230); Lighting.OutdoorAmbient = Color3.fromRGB(230, 230, 230)
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end
end))

CreateElement("Быстрый бег", function(state) Settings.FastSprint = state end, false, Color3.fromRGB(140, 140, 150))
CreateElement("Ночное зрение", function(state) Settings.NightVision = state end, false, Color3.fromRGB(140, 140, 150))
CreateElement("ESP Монстр и Капканы", function(state) Settings.EspMonster = state end, false, Color3.fromRGB(255, 30, 30))
CreateElement("ESP Игроки", function(state) Settings.EspPlayers = state end, false, Color3.fromRGB(140, 140, 150))
CreateElement("ESP Локации", function(state) Settings.EspLocations = state end, false, Color3.fromRGB(140, 140, 150))
CreateElement("ESP Лом и Предметы", function(state) Settings.EspItems = state end, false, Color3.fromRGB(140, 140, 150))
CreateElement("Удалить Скрипт", DestroyScript, true, Color3.fromRGB(255, 65, 65))
