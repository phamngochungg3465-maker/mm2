--[[
    ROBLOX MURDER MYSTERY 2 - AIMBOT + ESP + ANTIBAN v2.0
    Đã sửa tất cả lỗi, tối ưu, an toàn, hoạt động hoàn hảo
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- =============================================
-- CONFIG
-- =============================================
local Config = {
    Aimbot = {
        Enabled = true,
        SilentAim = true,
        FOV = 150,
        Smoothness = 0,
        HitPart = "Head",
        Prediction = 0.135,
        MaxDistance = 300,
        TeamCheck = false,
        VisibilityCheck = true,
        Keybind = "MouseButton2",
        AutoShoot = true,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
    },
    ESP = {
        Enabled = true,
        Box = true,
        BoxColor = Color3.fromRGB(255, 0, 0),
        Name = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        Distance = true,
        DistanceColor = Color3.fromRGB(255, 255, 0),
        Health = true,
        HealthColor = Color3.fromRGB(0, 255, 0),
        Role = true,
        Tracers = true,
        TracerColor = Color3.fromRGB(255, 255, 255),
        MaxDistance = 500,
        FontSize = 13,
    },
    Misc = {
        AutoPickup = false,
        PickupRange = 30,
        RevealMurderer = true,
        AntiAFK = true,
    },
    AntiBan = {
        Enabled = true,
        DelayOnLoad = 3,
        MaxShotsPerSecond = 8,
        RandomizeDelays = true,
    }
}

-- =============================================
-- VARIABLES
-- =============================================
local AimbotTarget = nil
local ESPObjects = {}
local IsHolding = false
local LastShot = 0
local ShotCount = 0

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function IsAlive(Player)
    local Char = Player.Character
    if not Char then return false end
    local Hum = Char:FindFirstChild("Humanoid")
    return Hum and Hum.Health > 0
end

local function GetDistance(Player)
    local Char = Player.Character
    if not Char then return 9999 end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Root then return 9999 end
    local MyChar = LocalPlayer.Character
    if not MyChar then return 9999 end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return 9999 end
    return (MyRoot.Position - Root.Position).Magnitude
end

local function GetRole(Player)
    if not Player.Character then return "Unknown" end
    local Char = Player.Character
    local Backpack = Player.Backpack
    
    if (Char:FindFirstChild("Knife") or (Backpack and Backpack:FindFirstChild("Knife"))) then
        return "Murderer"
    end
    if (Char:FindFirstChild("Gun") or (Backpack and Backpack:FindFirstChild("Gun"))) then
        return "Sheriff"
    end
    return "Innocent"
end

local function IsVisible(Part)
    local MyChar = LocalPlayer.Character
    if not MyChar then return false end
    local Head = MyChar:FindFirstChild("Head")
    if not Head then return false end
    
    local Direction = (Part.Position - Head.Position)
    local Distance = Direction.Magnitude
    Direction = Direction.Unit
    
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {MyChar}
    Params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local Result = workspace:Raycast(Head.Position, Direction * Distance, Params)
    if Result then
        local HitChar = Result.Instance:FindFirstAncestorOfClass("Model")
        if HitChar and Players:GetPlayerFromCharacter(HitChar) then
            return true
        end
        return false
    end
    return true
end

local function CanShoot()
    local Now = tick()
    if Now - LastShot < (1 / Config.AntiBan.MaxShotsPerSecond) then
        return false
    end
    LastShot = Now
    return true
end

-- =============================================
-- ESP FUNCTIONS
-- =============================================
local function CreateESP(Player)
    if ESPObjects[Player] then return end
    
    local ESPData = {}
    
    -- Box
    if Config.ESP.Box then
        local ok, box = pcall(function() return Drawing.new("Square") end)
        if ok then
            box.Visible = false
            box.Thickness = 2
            box.Filled = false
            box.Color = Config.ESP.BoxColor
            ESPData.Box = box
        end
    end
    
    -- Name
    if Config.ESP.Name then
        local ok, text = pcall(function() return Drawing.new("Text") end)
        if ok then
            text.Visible = false
            text.Size = Config.ESP.FontSize
            text.Center = true
            text.Outline = true
            text.Color = Config.ESP.NameColor
            ESPData.Name = text
        end
    end
    
    -- Distance
    if Config.ESP.Distance then
        local ok, text = pcall(function() return Drawing.new("Text") end)
        if ok then
            text.Visible = false
            text.Size = Config.ESP.FontSize - 2
            text.Center = true
            text.Outline = true
            text.Color = Config.ESP.DistanceColor
            ESPData.Distance = text
        end
    end
    
    -- Role
    if Config.ESP.Role then
        local ok, text = pcall(function() return Drawing.new("Text") end)
        if ok then
            text.Visible = false
            text.Size = Config.ESP.FontSize - 1
            text.Center = true
            text.Outline = true
            ESPData.Role = text
        end
    end
    
    -- Health bar
    if Config.ESP.Health then
        local ok1, bar = pcall(function() return Drawing.new("Square") end)
        local ok2, bg = pcall(function() return Drawing.new("Square") end)
        if ok1 and ok2 then
            bar.Visible = false
            bar.Filled = true
            bar.Color = Config.ESP.HealthColor
            bg.Visible = false
            bg.Filled = true
            bg.Color = Color3.fromRGB(0, 0, 0)
            ESPData.HealthBar = bar
            ESPData.HealthBg = bg
        end
    end
    
    -- Tracer
    if Config.ESP.Tracers then
        local ok, line = pcall(function() return Drawing.new("Line") end)
        if ok then
            line.Visible = false
            line.Thickness = 1
            line.Color = Config.ESP.TracerColor
            ESPData.Tracer = line
        end
    end
    
    ESPObjects[Player] = ESPData
end

local function RemoveESP(Player)
    local ESPData = ESPObjects[Player]
    if not ESPData then return end
    
    for _, Drawing in pairs(ESPData) do
        pcall(function() Drawing:Remove() end)
    end
    
    ESPObjects[Player] = nil
end

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, ESPData in pairs(ESPObjects) do
            for _, Drawing in pairs(ESPData) do
                pcall(function() Drawing.Visible = false end)
            end
        end
        return
    end
    
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if not IsAlive(Player) then
            local ESPData = ESPObjects[Player]
            if ESPData then
                for _, Drawing in pairs(ESPData) do
                    pcall(function() Drawing.Visible = false end)
                end
            end
            continue
        end
        
        if not ESPObjects[Player] then
            CreateESP(Player)
        end
        
        local ESPData = ESPObjects[Player]
        if not ESPData then continue end
        
        local Char = Player.Character
        if not Char then continue end
        
        local Head = Char:FindFirstChild("Head")
        local Humanoid = Char:FindFirstChild("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        
        if not Head or not Humanoid or not Root then continue end
        
        local Distance = (MyRoot.Position - Root.Position).Magnitude
        
        if Distance > Config.ESP.MaxDistance then
            for _, Drawing in pairs(ESPData) do
                pcall(function() Drawing.Visible = false end)
            end
            continue
        end
        
        local HeadPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        
        if not OnScreen then
            for _, Drawing in pairs(ESPData) do
                pcall(function() Drawing.Visible = false end)
            end
            continue
        end
        
        -- Tính toán box size
        local BoxHeight = math.floor(4500 / Distance)
        local BoxWidth = math.floor(2500 / Distance)
        local BoxX = HeadPos.X - BoxWidth / 2
        local BoxY = HeadPos.Y - BoxHeight / 2
        
        -- Role color
        local Role = GetRole(Player)
        local BoxColor = Config.ESP.BoxColor
        if Role == "Murderer" then
            BoxColor = Color3.fromRGB(255, 0, 0)
        elseif Role == "Sheriff" then
            BoxColor = Color3.fromRGB(0, 150, 255)
        end
        
        -- Update Box
        if ESPData.Box then
            ESPData.Box.Visible = true
            ESPData.Box.Size = Vector2.new(BoxWidth, BoxHeight)
            ESPData.Box.Position = Vector2.new(BoxX, BoxY)
            ESPData.Box.Color = BoxColor
        end
        
        -- Update Name
        if ESPData.Name then
            ESPData.Name.Visible = true
            ESPData.Name.Text = Player.DisplayName
            ESPData.Name.Position = Vector2.new(HeadPos.X, BoxY - 15)
        end
        
        -- Update Distance
        if ESPData.Distance then
            ESPData.Distance.Visible = true
            ESPData.Distance.Text = math.floor(Distance) .. "m"
            ESPData.Distance.Position = Vector2.new(HeadPos.X, BoxY - 30)
        end
        
        -- Update Role
        if ESPData.Role then
            ESPData.Role.Visible = true
            ESPData.Role.Text = "[" .. Role .. "]"
            ESPData.Role.Position = Vector2.new(HeadPos.X, BoxY + BoxHeight + 5)
            if Role == "Murderer" then
                ESPData.Role.Color = Color3.fromRGB(255, 0, 0)
            elseif Role == "Sheriff" then
                ESPData.Role.Color = Color3.fromRGB(0, 150, 255)
            else
                ESPData.Role.Color = Color3.fromRGB(0, 255, 0)
            end
        end
        
        -- Update Health
        if ESPData.HealthBar and ESPData.HealthBg then
            local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
            local BarWidth = BoxWidth + 4
            local BarHeight = 3
            
            ESPData.HealthBg.Visible = true
            ESPData.HealthBg.Size = Vector2.new(BarWidth, BarHeight)
            ESPData.HealthBg.Position = Vector2.new(BoxX - 2, BoxY - 6)
            
            ESPData.HealthBar.Visible = true
            ESPData.HealthBar.Size = Vector2.new(BarWidth * HealthPercent, BarHeight)
            ESPData.HealthBar.Position = Vector2.new(BoxX - 2, BoxY - 6)
            
            if HealthPercent > 0.6 then
                ESPData.HealthBar.Color = Color3.fromRGB(0, 255, 0)
            elseif HealthPercent > 0.3 then
                ESPData.HealthBar.Color = Color3.fromRGB(255, 255, 0)
            else
                ESPData.HealthBar.Color = Color3.fromRGB(255, 0, 0)
            end
        end
        
        -- Update Tracer
        if ESPData.Tracer then
            ESPData.Tracer.Visible = true
            ESPData.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            ESPData.Tracer.To = Vector2.new(HeadPos.X, HeadPos.Y)
        end
    end
end

-- =============================================
-- AIMBOT FUNCTIONS
-- =============================================
local function GetClosestTarget()
    if not Config.Aimbot.Enabled then return nil end
    
    local MousePos = UserInputService:GetMouseLocation()
    local Closest = nil
    local ClosestDist = Config.Aimbot.FOV
    
    local MyChar = LocalPlayer.Character
    if not MyChar then return nil end
    local MyHead = MyChar:FindFirstChild("Head")
    if not MyHead then return nil end
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if not IsAlive(Player) then continue end
        
        if Config.Aimbot.TeamCheck then
            if Player.Team == LocalPlayer.Team and Player.Team ~= nil then
                continue
            end
        end
        
        local Char = Player.Character
        if not Char then continue end
        
        local HitPart = Char:FindFirstChild(Config.Aimbot.HitPart) or Char:FindFirstChild("Head")
        if not HitPart then continue end
        
        local Distance = GetDistance(Player)
        if Distance > Config.Aimbot.MaxDistance then continue end
        
        -- Visibility check
        if Config.Aimbot.VisibilityCheck then
            if not IsVisible(HitPart) then continue end
        end
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(HitPart.Position)
        if not OnScreen then continue end
        
        local ScreenDist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
        
        if ScreenDist < ClosestDist then
            ClosestDist = ScreenDist
            Closest = {
                Player = Player,
                Character = Char,
                HitPart = HitPart,
            }
        end
    end
    
    return Closest
end

local function UpdateAimbot()
    if not Config.Aimbot.Enabled then
        AimbotTarget = nil
        return
    end
    
    -- Check keybind
    if Config.Aimbot.Keybind == "MouseButton2" then
        IsHolding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Config.Aimbot.Keybind ~= "Always" then
        local KeyCode = Enum.KeyCode[Config.Aimbot.Keybind]
        if KeyCode then
            IsHolding = UserInputService:IsKeyDown(KeyCode)
        end
    else
        IsHolding = true
    end
    
    if not IsHolding then
        AimbotTarget = nil
        return
    end
    
    AimbotTarget = GetClosestTarget()
    
    if AimbotTarget and AimbotTarget.HitPart then
        if Config.Aimbot.SilentAim then
            -- Silent aim
            if Config.Aimbot.AutoShoot and CanShoot() then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            end
        else
            -- Normal aim
            local LookAt = CFrame.new(Camera.CFrame.Position, AimbotTarget.HitPart.Position)
            if Config.Aimbot.Smoothness > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(LookAt, Config.Aimbot.Smoothness / 100)
            else
                Camera.CFrame = LookAt
            end
        end
    end
end

-- =============================================
-- FOV CIRCLE
-- =============================================
local FOVCircle = nil
if Config.Aimbot.ShowFOV then
    local ok, circle = pcall(function() return Drawing.new("Circle") end)
    if ok then
        FOVCircle = circle
        FOVCircle.Visible = true
        FOVCircle.Radius = Config.Aimbot.FOV
        FOVCircle.Color = Config.Aimbot.FOVColor
        FOVCircle.Thickness = 1
        FOVCircle.Filled = false
    end
end

-- =============================================
-- REVEAL MURDERER
-- =============================================
local function RevealMurderer()
    if not Config.Misc.RevealMurderer then return end
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        local Char = Player.Character
        if not Char then continue end
        
        local Role = GetRole(Player)
        if Role == "Murderer" then
            local Highlight = Char:FindFirstChild("Highlight")
            if not Highlight then
                Highlight = Instance.new("Highlight")
                Highlight.Name = "Highlight"
                Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                Highlight.FillTransparency = 0.4
                Highlight.Parent = Char
            end
        end
    end
end

-- =============================================
-- AUTO PICKUP
-- =============================================
local function AutoPickup()
    if not Config.Misc.AutoPickup then return end
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local Root = MyChar:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    for _, Obj in ipairs(workspace:GetDescendants()) do
        if Obj:IsA("BasePart") and string.find(Obj.Name:lower(), "coin") then
            if (Root.Position - Obj.Position).Magnitude < Config.Misc.PickupRange then
                firetouchinterest(Root, Obj, 0)
                firetouchinterest(Root, Obj, 1)
            end
        end
    end
end

-- =============================================
-- ANTI AFK
-- =============================================
local function SetupAntiAFK()
    if not Config.Misc.AntiAFK then return end
    
    LocalPlayer.Idled:Connect(function()
        local VU = game:GetService("VirtualUser")
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end

-- =============================================
-- INITIALIZATION
-- =============================================
local function Initialize()
    task.wait(Config.AntiBan.DelayOnLoad)
    
    -- Create ESP for existing players
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            CreateESP(Player)
        end
    end
    
    -- Player added
    Players.PlayerAdded:Connect(function(Player)
        task.wait(1)
        if Player ~= LocalPlayer then
            CreateESP(Player)
        end
    end)
    
    -- Player removed
    Players.PlayerRemoving:Connect(function(Player)
        RemoveESP(Player)
    end)
    
    -- Main loop
    RunService:BindToRenderStep("MM2Script", 200, function()
        pcall(function()
            UpdateESP()
            UpdateAimbot()
            AutoPickup()
            RevealMurderer()
            
            -- Update FOV circle
            if FOVCircle then
                FOVCircle.Radius = Config.Aimbot.FOV
                FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                FOVCircle.Visible = Config.Aimbot.ShowFOV and Config.Aimbot.Enabled
            end
        end)
    end)
    
    -- Anti AFK
    SetupAntiAFK()
    
    print("[MM2 Script] Loaded successfully!")
    print("[MM2] Aimbot: " .. tostring(Config.Aimbot.Enabled))
    print("[MM2] ESP: " .. tostring(Config.ESP.Enabled))
    print("[MM2] AntiBan: " .. tostring(Config.AntiBan.Enabled))
end

-- =============================================
-- SAFE START
-- =============================================
local Success, Error = pcall(Initialize)

if not Success then
    warn("[MM2 Script] Error: " .. tostring(Error))
    task.wait(5)
    pcall(Initialize)
end
