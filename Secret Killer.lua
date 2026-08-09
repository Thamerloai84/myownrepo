-- Rayfield Gen2 UI Migration
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

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
    Revenge = false, -- New Feature
}

--======================== HELPERS ========================--
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

local function getKiller()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and hasTool(p, "Monster") then
            return p
        end
    end
    return nil
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
        if Flags.Revenge then
            -- Check if we are dead/ghosted
            local success, isGhost = pcall(function()
                local ghost = LocalPlayer.PlayerGui.HUD.GhostText
                return ghost and ghost.Visible and ghost:FindFirstChild("GoLobby") ~= nil
            end)

            if success and isGhost then
                -- We are dead. Wait until we respawn (GhostText becomes invisible/destroyed)
                repeat
                    task.wait(0.2)
                    if not Flags.Revenge then break end
                    success, isGhost = pcall(function()
                        local ghost = LocalPlayer.PlayerGui.HUD.GhostText
                        return ghost and ghost.Visible and ghost:FindFirstChild("GoLobby") ~= nil
                    end)
                until (not success or not isGhost)

                -- We have respawned! Wait a moment for physics to load
                task.wait(0.75)

                -- Now, violently fling the monster
                if Flags.Revenge then
                    local killer = getKiller()
                    if killer and killer.Character then
                        local root = killer.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            -- Flings them 3 times in a row to guarantee they get "tripped"
                            for i = 1, 3 do
                                if not Flags.Revenge or not killer.Character then break end
                                
                                local att = root:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", root)
                                
                                -- Massive upward force
                                local vf = Instance.new("VectorForce")
                                vf.Attachment0 = att
                                vf.Force = Vector3.new(math.random(-90000, 90000), 250000, math.random(-90000, 90000))
                                vf.RelativeTo = Enum.ActuatorRelativeTo.World
                                vf.Parent = root
                                
                                -- Massive spin force to trip them
                                local torque = Instance.new("Torque")
                                torque.Attachment0 = att
                                torque.Torque = Vector3.new(200000, 200000, 200000)
                                torque.Parent = root
                                
                                task.wait(1.2)
                                
                                -- Cleanup forces
                                if vf then vf:Destroy() end
                                if torque then torque:Destroy() end
                                
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1) -- Check every second to save resources
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

PlayerTab:CreateToggle({
    name = "If you kill me, I will kill you",
    description = "Waits for you to respawn as a ghost, then violently flings the monster.",
    flag = "Revenge",
    value = false,
    callback = function(v) Flags.Revenge = v end
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
