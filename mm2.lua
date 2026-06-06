--[[
    MURDER MYSTERY 2 - AIMBOT + ESP + ANTIBAN v3.0
    Tương thích: Delta X, VNG, Roblox Mobile & PC
    Có UI đơn giản, dễ bấm, hoạt động mượt mà
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- =============================================
-- TẠO THƯ VIỆN UI ĐƠN GIẢN
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2Tool"
ScreenGui.Parent = CoreGui

-- Anti detect
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
elseif gethui then
    ScreenGui.Parent = gethui()
end

-- =============================================
-- CONFIG
-- =============================================
local Config = {
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0,
    SilentAim = true,
    AutoShoot = true,
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPRole = true,
    ESPTracer = false,
    RevealMurderer = false,
    AntiAFK = true,
}

-- =============================================
-- BIẾN
-- =============================================
local ESPObjects = {}
local AimbotTarget = nil
local LastShot = 0
local IsHolding = false

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function IsAlive(plr)
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

local function GetRole(plr)
    if not plr.Character then return "?" end
    local c = plr.Character
    local b = plr.Backpack
    if c:FindFirstChild("Knife") or (b and b:FindFirstChild("Knife")) then return "Murderer" end
    if c:FindFirstChild("Gun") or (b and b:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function IsVisible(part)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local head = myChar:FindFirstChild("Head")
    if not head then return false end
    
    local dir = (part.Position - head.Position)
    local dist = dir.Magnitude
    dir = dir.Unit
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {myChar}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(head.Position, dir * dist, params)
    if result then
        local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
        if hitChar and Players:GetPlayerFromCharacter(hitChar) then
            return true
        end
        return false
    end
    return true
end

-- =============================================
-- ESP
-- =============================================
local function createESP(plr)
    if ESPObjects[plr] then return end
    
    local data = {}
    
    pcall(function()
        if Config.ESPBox then
            local box = Drawing.new("Square")
            box.Visible = false; box.Thickness = 2; box.Filled = false
            box.Color = Color3.fromRGB(255,0,0)
            data.Box = box
        end
    end)
    
    pcall(function()
        if Config.ESPName then
            local txt = Drawing.new("Text")
            txt.Visible = false; txt.Size = 13; txt.Center = true; txt.Outline = true
            txt.Color = Color3.fromRGB(255,255,255)
            data.Name = txt
        end
    end)
    
    pcall(function()
        if Config.ESPDistance then
            local txt = Drawing.new("Text")
            txt.Visible = false; txt.Size = 11; txt.Center = true; txt.Outline = true
            txt.Color = Color3.fromRGB(255,255,0)
            data.Distance = txt
        end
    end)
    
    pcall(function()
        if Config.ESPRole then
            local txt = Drawing.new("Text")
            txt.Visible = false; txt.Size = 12; txt.Center = true; txt.Outline = true
            data.Role = txt
        end
    end)
    
    pcall(function()
        if Config.ESPHealth then
            local bar = Drawing.new("Square")
            bar.Visible = false; bar.Filled = true
            bar.Color = Color3.fromRGB(0,255,0)
            local bg = Drawing.new("Square")
            bg.Visible = false; bg.Filled = true
            bg.Color = Color3.fromRGB(0,0,0)
            data.HealthBar = bar; data.HealthBg = bg
        end
    end)
    
    pcall(function()
        if Config.ESPTracer then
            local line = Drawing.new("Line")
            line.Visible = false; line.Thickness = 1
            line.Color = Color3.fromRGB(255,255,255)
            data.Tracer = line
        end
    end)
    
    ESPObjects[plr] = data
end

local function updateESP()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        if not IsAlive(plr) then
            if ESPObjects[plr] then
                for _, d in pairs(ESPObjects[plr]) do
                    pcall(function() d.Visible = false end)
                end
            end
            continue
        end
        
        if not ESPObjects[plr] then
            createESP(plr)
        end
        
        local data = ESPObjects[plr]
        if not data then continue end
        
        local char = plr.Character
        if not char then continue end
        
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not hum or not root then continue end
        
        local dist = (myRoot.Position - root.Position).Magnitude
        
        if dist > 500 then
            for _, d in pairs(data) do
                pcall(function() d.Visible = false end)
            end
            continue
        end
        
        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        
        if not onScreen then
            for _, d in pairs(data) do
                pcall(function() d.Visible = false end)
            end
            continue
        end
        
        local boxH = math.floor(4500 / dist)
        local boxW = math.floor(2500 / dist)
        local boxX = headPos.X - boxW/2
        local boxY = headPos.Y - boxH/2
        
        -- Role color
        local role = GetRole(plr)
        local boxColor = Color3.fromRGB(255,0,0)
        if role == "Murderer" then boxColor = Color3.fromRGB(255,0,0)
        elseif role == "Sheriff" then boxColor = Color3.fromRGB(0,150,255)
        else boxColor = Color3.fromRGB(255,255,255) end
        
        -- Update drawings
        if data.Box then
            data.Box.Visible = Config.ESPEnabled and Config.ESPBox
            data.Box.Size = Vector2.new(boxW, boxH)
            data.Box.Position = Vector2.new(boxX, boxY)
            data.Box.Color = boxColor
        end
        
        if data.Name then
            data.Name.Visible = Config.ESPEnabled and Config.ESPName
            data.Name.Text = plr.DisplayName
            data.Name.Position = Vector2.new(headPos.X, boxY - 15)
        end
        
        if data.Distance then
            data.Distance.Visible = Config.ESPEnabled and Config.ESPDistance
            data.Distance.Text = math.floor(dist).."m"
            data.Distance.Position = Vector2.new(headPos.X, boxY - 30)
        end
        
        if data.Role then
            data.Role.Visible = Config.ESPEnabled and Config.ESPRole
            data.Role.Text = "["..role.."]"
            data.Role.Position = Vector2.new(headPos.X, boxY + boxH + 5)
            if role == "Murderer" then data.Role.Color = Color3.fromRGB(255,0,0)
            elseif role == "Sheriff" then data.Role.Color = Color3.fromRGB(0,150,255)
            else data.Role.Color = Color3.fromRGB(0,255,0) end
        end
        
        if data.HealthBar and data.HealthBg then
            local hp = hum.Health / hum.MaxHealth
            local bw = boxW + 4
            local bh = 3
            
            data.HealthBg.Visible = Config.ESPEnabled and Config.ESPHealth
            data.HealthBg.Size = Vector2.new(bw, bh)
            data.HealthBg.Position = Vector2.new(boxX - 2, boxY - 6)
            
            data.HealthBar.Visible = Config.ESPEnabled and Config.ESPHealth
            data.HealthBar.Size = Vector2.new(bw * hp, bh)
            data.HealthBar.Position = Vector2.new(boxX - 2, boxY - 6)
            
            if hp > 0.6 then data.HealthBar.Color = Color3.fromRGB(0,255,0)
            elseif hp > 0.3 then data.HealthBar.Color = Color3.fromRGB(255,255,0)
            else data.HealthBar.Color = Color3.fromRGB(255,0,0) end
        end
        
        if data.Tracer then
            data.Tracer.Visible = Config.ESPEnabled and Config.ESPTracer
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            data.Tracer.To = Vector2.new(headPos.X, headPos.Y)
        end
    end
end

-- =============================================
-- AIMBOT
-- =============================================
local function getClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local closestDist = Config.AimbotFOV
    
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return nil end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not IsAlive(plr) then continue end
        
        local char = plr.Character
        if not char then continue end
        
        local hitPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not hitPart then continue end
        
        local dist = (myChar:FindFirstChild("HumanoidRootPart") and (myChar.HumanoidRootPart.Position - hitPart.Position).Magnitude) or 9999
        if dist > 300 then continue end
        
        if not IsVisible(hitPart) then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
        if not onScreen then continue end
        
        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if screenDist < closestDist then
            closestDist = screenDist
            closest = {HitPart = hitPart, Position = hitPart.Position}
        end
    end
    
    return closest
end

local function updateAimbot()
    if not Config.AimbotEnabled then
        AimbotTarget = nil
        return
    end
    
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        IsHolding = true
    else
        IsHolding = false
        AimbotTarget = nil
        return
    end
    
    AimbotTarget = getClosestTarget()
    
    if AimbotTarget and AimbotTarget.HitPart then
        if Config.SilentAim and Config.AutoShoot then
            local now = tick()
            if now - LastShot > 0.12 then
                LastShot = now
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            end
        elseif not Config.SilentAim then
            local lookAt = CFrame.new(Camera.CFrame.Position, AimbotTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, (Config.AimbotSmooth == 0 and 1 or Config.AimbotSmooth/100))
        end
    end
end

-- =============================================
-- REVEAL MURDERER
-- =============================================
local function revealMurderer()
    if not Config.RevealMurderer then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not plr.Character then continue end
        if GetRole(plr) == "Murderer" then
            if not plr.Character:FindFirstChild("Highlight") then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.FillTransparency = 0.4
                hl.Parent = plr.Character
            end
        end
    end
end

-- =============================================
-- TẠO UI ĐƠN GIẢN
-- =============================================
local function createUI()
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 280, 0, 420)
    Main.Position = UDim2.new(0, 10, 0, 100)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Main.BackgroundTransparency = 0.1
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    Title.BackgroundTransparency = 0.2
    Title.Text = "MM2 TOOL v3.0"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = Main
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title
    
    -- Close button
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -35, 0, 3)
    Close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    Close.BackgroundTransparency = 0.3
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 255, 255)
    Close.Font = Enum.Font.GothamBold
    Close.TextSize = 16
    Close.Parent = Main
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 15)
    CloseCorner.Parent = Close
    
    Close.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)
    
    -- Scrolling Frame
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -40)
    Scroll.Position = UDim2.new(0, 0, 0, 40)
    Scroll.BackgroundColor3 = Color3.fromRGB(1, 1, 1)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 650)
    Scroll.Parent = Main
    
    -- UI Elements
    local yPos = 5
    local function addSection(title)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, -20, 0, 25)
        section.Position = UDim2.new(0, 10, 0, yPos)
        section.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        section.BackgroundTransparency = 0.5
        section.Text = title
        section.TextColor3 = Color3.fromRGB(255, 255, 255)
        section.Font = Enum.Font.GothamBold
        section.TextSize = 14
        section.Parent = Scroll
        
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 4)
        sCorner.Parent = section
        
        yPos = yPos + 30
        return section
    end
    
    local function addToggle(text, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 35)
        frame.Position = UDim2.new(0, 10, 0, yPos)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        frame.BackgroundTransparency = 0.3
        frame.Parent = Scroll
        
        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, 4)
        fCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 45, 0, 22)
        button.Position = UDim2.new(1, -55, 0.5, -11)
        button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        button.Text = "OFF"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 11
        button.Parent = frame
        
        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 11)
        bCorner.Parent = button
        
        local enabled = false
        button.MouseButton1Click:Connect(function()
            enabled = not enabled
            if enabled then
                button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                button.Text = "ON"
            else
                button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                button.Text = "OFF"
            end
            callback(enabled)
        end)
        
        yPos = yPos + 40
        return button
    end
    
    -- AIMBOT SECTION
    addSection("🎯 AIMBOT")
    
    addToggle("Enable Aimbot", function(v) Config.AimbotEnabled = v end)
    addToggle("Silent Aim", function(v) Config.SilentAim = v end)
    addToggle("Auto Shoot", function(v) Config.AutoShoot = v end)
    
    -- ESP SECTION
    addSection("👁️ ESP")
    
    addToggle("Enable ESP", function(v) Config.ESPEnabled = v end)
    addToggle("Show Box", function(v) Config.ESPBox = v end)
    addToggle("Show Name", function(v) Config.ESPName = v end)
    addToggle("Show Distance", function(v) Config.ESPDistance = v end)
    addToggle("Show Health", function(v) Config.ESPHealth = v end)
    addToggle("Show Role", function(v) Config.ESPRole = v end)
    addToggle("Show Tracer", function(v) Config.ESPTracer = v end)
    
    -- MISC SECTION
    addSection("⚡ MISC")
    
    addToggle("Reveal Murderer", function(v) Config.RevealMurderer = v end)
    addToggle("Anti AFK", function(v) Config.AntiAFK = v end)
    
    yPos = yPos + 10
    
    -- Toggle UI button (nút ẩn/hiện nhỏ)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
    ToggleBtn.Position = UDim2.new(0, 10, 0, 50)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    ToggleBtn.BackgroundTransparency = 0.3
    ToggleBtn.Text = "🔫"
    ToggleBtn.TextSize = 20
    ToggleBtn.Parent = ScreenGui
    
    local TBtnCorner = Instance.new("UICorner")
    TBtnCorner.CornerRadius = UDim.new(0, 20)
    TBtnCorner.Parent = ToggleBtn
    
    ToggleBtn.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
    end)
end

-- =============================================
-- INIT
-- =============================================
local function init()
    createUI()
    
    -- Create ESP for existing players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            createESP(plr)
        end
    end
    
    -- Player events
    Players.PlayerAdded:Connect(function(plr)
        task.wait(1)
        if plr ~= LocalPlayer then createESP(plr) end
    end)
    
    Players.PlayerRemoving:Connect(function(plr)
        if ESPObjects[plr] then
            for _, d in pairs(ESPObjects[plr]) do
                pcall(function() d:Remove() end)
            end
            ESPObjects[plr] = nil
        end
    end)
    
    -- Main loop
    RunService:BindToRenderStep("MM2Main", 1, function()
        pcall(function()
            updateESP()
            updateAimbot()
            revealMurderer()
        end)
    end)
    
    -- Anti AFK
    if Config.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
    
    print("[MM2 Tool] Loaded! Hold Right Mouse Button for Aimbot")
    print("[MM2 Tool] Made for Delta X / VNG")
end

-- =============================================
-- SAFE START
-- =============================================
local ok, err = pcall(init)
if not ok then
    warn("[MM2 Tool] Error: " .. tostring(err))
    task.wait(3)
    pcall(init)
end 
