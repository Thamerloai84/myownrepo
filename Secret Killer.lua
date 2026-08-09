-- Rayfield Gen2 UI Migration + Revenge Fling
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Player = LocalPlayer -- Alias for SkidFling

--======================== WINDOW ========================--
local Window = Rayfield:CreateWindow({
    name = "Game Hub",
    subtitle = "Orion to Rayfield Gen2",
    configuration = {
        autoSave = false,
        autoLoad = false,
        fileName = "GameHub"
    }
})

--======================== STATE ==========================--
local Flags = {
    AutoCoins = false,
    AutoGun = false,
    ESP_Killer = false,
    ESP_Sheriff = false,
    ESP_Player = false,
    WalkSpeed = 16,
    JumpPower = 50,
    RevengeFling = false
}

--======================== HELPERS ========================--
local Message = function(_Title, _Text, Time)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = _Title, Text = _Text, Duration = Time})
    end)
end

-- Check if a player owns a tool (Backpack OR Equipped in Character)
local function hasTool(player, toolName)
    if not player then return false end
    local success, result = pcall(function()
        local backpack = player:FindFirstChildOfClass("Backpack")
        if backpack and backpack:FindFirstChild(toolName) then
            return true
        end
        local char = player.Character
        if char then
            if char:FindFirstChild(toolName, true) then
                return true
            end
        end
        return false
    end)
    return success and result or false
end

local function getRoot()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    end
end

local function findKiller()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if hasTool(player, "Monster") then
                return player
            end
        end
    end
    return nil
end

--======================== SKID FLING (R-77) ==============--
local SkidFling = function(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid, TRootPart, THead, Accessory, Handle

    if TCharacter and TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter and TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter and TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart and TCharacter then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THumanoid and THumanoid.Sit then
            return Message("Error Occurred", "Targeting is sitting", 5)
        end

        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else break end
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or (THumanoid and THumanoid.Sit) or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end

        local FPDH = workspace.FallenPartsDestroyHeight -- FIXED: Original script used getgenv().FPDH which was nil
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
        elseif TRootPart and not THead then SFBasePart(TRootPart)
        elseif not TRootPart and THead then SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then SFBasePart(Handle)
        else return Message("Error Occurred", "Target is missing everything", 5) end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid

        repeat
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, x in ipairs(Character:GetChildren()) do -- FIXED: Replaced deprecated table.foreach
                if x:IsA("BasePart") then
                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = FPDH
    else
        return Message("Error Occurred", "Random error", 5)
    end
end

--======================== ESP SYSTEM =====================--
local ESPObjects = {} 
local ROLE_COLORS = {
    Killer  = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Player  = Color3.fromRGB(0, 255, 0),
}

local function clearESP(player)
    local data = ESPObjects[player]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    ESPObjects[player] = nil
    
    local char = player.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v.Name == "ESPHighlight" or v.Name == "ESPBillboard" then
                v:Destroy()
            end
        end
    end
end

local function createESP(player, role)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char.Parent then return end 
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not root then return end

    local existing = ESPObjects[player]
    
    if existing and existing.Role == role and existing.Highlight and existing.Highlight.Parent == char then
        return 
    end
    
    clearESP(player)
    
    local hl = Instance.new("Highlight")
    hl.Name = "ESPHighlight"
    hl.Adornee = char
    hl.FillColor = ROLE_COLORS[role]
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESPBillboard"
    bb.Adornee = char:FindFirstChild("Head") or root
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = char

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextColor3 = ROLE_COLORS[role]
    lbl.TextStrokeTransparency = 0
    lbl.Text = player.Name .. "\n[" .. role .. "]"
    lbl.Parent = bb

    ESPObjects[player] = { Highlight = hl, Billboard = bb, Role = role }
end

RunService.Heartbeat:Connect(function()
    if not (Flags.ESP_Killer or Flags.ESP_Sheriff or Flags.ESP_Player) then
        for p in pairs(ESPObjects) do clearESP(p) end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isKiller  = hasTool(player, "Monster")
            local isSheriff = hasTool(player, "Gun")

            local shouldShow = false
            local role = nil

            if isKiller and Flags.ESP_Killer then
                role = "Killer"
                shouldShow = true
            elseif isSheriff and Flags.ESP_Sheriff then
                role = "Sheriff"
                shouldShow = true
            elseif (not isKiller and not isSheriff) and Flags.ESP_Player then
                role = "Player"
                shouldShow = true
            end

            if shouldShow then
                createESP(player, role)
            else
                clearESP(player)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(clearESP)

--======================== AUTO COLLECT COINS =============--
task.spawn(function()
    while true do
        if Flags.AutoCoins then
            local holder = Workspace:FindFirstChild("CoinHolder")
            local root = getRoot()
            if holder and root then
                for _, obj in ipairs(holder:GetChildren()) do
                    if obj:IsA("MeshPart") and Flags.AutoCoins then
                        root.CFrame = obj.CFrame
                        task.wait(0.1)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

--======================== AUTO TELEPORT TO GUN ===========--
task.spawn(function()
    while true do
        if Flags.AutoGun then
            local pickupHolder = Workspace:FindFirstChild("GunPickupHolder")
            if pickupHolder then
                local pickup = pickupHolder:FindFirstChild("GunPickup")
                if pickup then
                    local part = pickup:FindFirstChild("Part") or pickup:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local root = getRoot()
                        if root then
                            local originalCFrame = part.CFrame
                            while Flags.AutoGun and part.Parent and root.Parent do
                                part.CFrame = root.CFrame
                                task.wait(0.05)
                                if not part.Parent then break end 
                                part.CFrame = originalCFrame
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

--======================== WALKSPEED / JUMPPOWER ==========--
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.WalkSpeed = Flags.WalkSpeed end)
                pcall(function() hum.JumpPower = Flags.JumpPower end)
            end
        end
        task.wait(0.25)
    end
end)

--======================== REVENGE FLING ==================--
task.spawn(function()
    while true do
        if Flags.RevengeFling then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local hud = playerGui and playerGui:FindFirstChild("HUD")
            local ghostText = hud and hud:FindFirstChild("GhostText")
            local goLobby = ghostText and ghostText:FindFirstChild("GoLobby")
            
            -- Wait for GhostText and GoLobby to be visible
            if ghostText and goLobby and ghostText.Visible and goLobby.Visible then
                -- Activate GoLobby in every way
                pcall(function() goLobby.MouseButton1Click:Fire() end)
                pcall(function() goLobby:FireServer() end) 
                pcall(function() fireclickdetector(goLobby) end) 
                
                -- Wait to be respawned
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(2) -- Wait a bit to ensure full spawn
                end
                
                -- Try to fling the monster
                local killer = findKiller()
                if killer then
                    pcall(SkidFling, killer)
                end
                
                task.wait(2) -- Cooldown to prevent spam
            end
        end
        task.wait(0.5)
    end
end)

--======================== TAB: PLAYER ====================--
local PlayerTab = Window:CreateTab({
    name = "Player",
    icon = 4483362458
})

PlayerTab:CreateToggle({
    name = "Auto Collect Coins",
    flag = "AutoCoins",
    value = false,
    callback = function(v) Flags.AutoCoins = v end
})

PlayerTab:CreateToggle({
    name = "Auto Teleport To Gun",
    flag = "AutoGun",
    value = false,
    callback = function(v) Flags.AutoGun = v end
})

PlayerTab:CreateToggle({
    name = "If you kill me, I will kill you",
    flag = "RevengeFling",
    description = "Auto rejoins and flings the monster if you die.",
    value = false,
    callback = function(v) Flags.RevengeFling = v end
})

PlayerTab:CreateSlider({
    name = "Walk Speed",
    range = {16, 250},
    increment = 1,
    value = 16,
    flag = "WalkSpeed",
    callback = function(v) Flags.WalkSpeed = v end
})

PlayerTab:CreateSlider({
    name = "Jump Power",
    range = {50, 350},
    increment = 1,
    value = 50,
    flag = "JumpPower",
    callback = function(v) Flags.JumpPower = v end
})

--======================== TAB: ESP =======================--
local ESPTab = Window:CreateTab({
    name = "ESP",
    icon = 4483362458
})

ESPTab:CreateToggle({
    name = "Show Killers",
    flag = "ESP_Killer",
    value = false,
    callback = function(v)
        Flags.ESP_Killer = v
        if not v then
            for p, d in pairs(ESPObjects) do
                if d.Role == "Killer" then clearESP(p) end
            end
        end
    end
})

ESPTab:CreateToggle({
    name = "Show Sheriff",
    flag = "ESP_Sheriff",
    value = false,
    callback = function(v)
        Flags.ESP_Sheriff = v
        if not v then
            for p, d in pairs(ESPObjects) do
                if d.Role == "Sheriff" then clearESP(p) end
            end
        end
    end
})

ESPTab:CreateToggle({
    name = "Show Players",
    flag = "ESP_Player",
    value = false,
    callback = function(v)
        Flags.ESP_Player = v
        if not v then
            for p, d in pairs(ESPObjects) do
                if d.Role == "Player" then clearESP(p) end
            end
        end
    end
})
