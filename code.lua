-- ============================
-- SCRIPT HUB v2 (Stable & Modern)
-- ============================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================
-- STATE & SETTINGS
-- ============================
if _G.ScriptHubState == nil then _G.ScriptHubState = {} end
_G.ScriptHubState.NotifyEnabled = (_G.ScriptHubState.NotifyEnabled == nil) and true or _G.ScriptHubState.NotifyEnabled
_G.ScriptHubState.ScriptCache = nil

local isExecuting = false -- Debounce for script execution

-- ============================
-- THEME & ASSETS
-- ============================
local THEME = {
    Background = Color3.fromRGB(25, 25, 28),
    Header = Color3.fromRGB(35, 35, 40),
    Element = Color3.fromRGB(45, 45, 50),
    Text = Color3.fromRGB(240, 240, 240),
    Success = Color3.fromRGB(50, 180, 80),
    Warning = Color3.fromRGB(220, 160, 40),
    Danger = Color3.fromRGB(220, 70, 70),
    Hover = Color3.fromRGB(70, 70, 80),
}

local SOUNDS = {
    Click = "rbxassetid://6042053626",
    HubLoaded = "rbxassetid://114326413874741",
    Close = "rbxassetid://6091796264",
}

local soundInstances = {}
local function preloadSounds()
    for name, id in pairs(SOUNDS) do
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = 0.5
        s.Parent = playerGui
        soundInstances[name] = s
    end
    -- Preload them properly without messy loops
    local assets = {}
    for _, s in pairs(soundInstances) do table.insert(assets, s) end
    pcall(function()
        ContentProvider:PreloadAsync(assets)
    end)
end

local function playSound(name)
    if soundInstances[name] then
        soundInstances[name]:Stop()
        soundInstances[name]:Play()
    end
end

-- ============================
-- UTILITIES
-- ============================
local function notify(title, text, duration)
    duration = duration or 5
    if _G.ScriptHubState.NotifyEnabled then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title, Text = text, Duration = duration
            })
        end)
    end
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function addHoverEffect(btn, defaultColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = defaultColor}):Play()
    end)
end

-- ============================
-- NETWORK FUNCTIONS
-- ============================
local function fetchGameScript()
    local csvUrl = "https://raw.githubusercontent.com/Thamerloai84/myhub/refs/heads/main/Scripts.csv"
    local success, result = pcall(function()
        return game:HttpGet(csvUrl)
    end)

    if not success then return nil, "Network error" end

    local currentGameId = tostring(game.PlaceId)
    for line in string.gmatch(result, "[^\r\n]+") do
        if string.match(line, "%S") then
            local parts = {}
            for part in string.gmatch(line, "([^,]+)") do
                table.insert(parts, part:match("^%s*(.-)%s*$")) -- trim whitespace
            end

            if #parts >= 3 and parts[2] == currentGameId then
                return { name = parts[1], gameId = parts[2], scriptUrl = parts[3] }
            end
        end
    end
    return nil, "Not supported"
end

local function fetchUniversalScripts()
    if _G.ScriptHubState.ScriptCache then return _G.ScriptHubState.ScriptCache end

    local url = "https://api.github.com/repos/Thamerloai84/myhub/contents?ref=main"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then return nil, "Network error" end

    local ok, data = pcall(function() return HttpService:JSONDecode(result) end)
    if not ok or type(data) ~= "table" then return nil, "Invalid API response" end

    local luaFiles = {}
    for _, item in ipairs(data) do
        if item.type == "file" and string.lower(string.sub(item.name, -4)) == ".lua" then
            -- Strip .lua extension BEFORE sorting so it sorts cleanly by name
            local cleanName = string.gsub(item.name, "%.lua$", "")
            table.insert(luaFiles, { name = cleanName, download_url = item.download_url })
        end
    end
    
    -- Strict A-Z Alphabetical Sort (Case-insensitive)
    table.sort(luaFiles, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    
    _G.ScriptHubState.ScriptCache = luaFiles
    return luaFiles, nil
end

-- ============================
-- UI BUILDER
-- ============================
local connections = {} -- Track connections to clean up on restart

local function cleanup()
    for _, conn in ipairs(connections) do
        pcall(conn.Disconnect, conn)
    end
    connections = {}
end

local function initializeGUI()
    cleanup()
    local existingGui = playerGui:FindFirstChild("DraggableGUI")
    if existingGui then existingGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DraggableGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 230)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -115)
    mainFrame.BackgroundColor3 = THEME.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = THEME.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
    
    -- Mask header bottom corners
    local headerMask = Instance.new("Frame")
    headerMask.Size = UDim2.new(1, 0, 0, 10)
    headerMask.Position = UDim2.new(0, 0, 1, -10)
    headerMask.BackgroundColor3 = THEME.Header
    headerMask.BorderSizePixel = 0
    headerMask.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Script Hub"
    title.TextColor3 = THEME.Text
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = THEME.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    table.insert(connections, closeBtn.MouseButton1Click:Connect(function()
        playSound("Close")
        screenGui:Destroy()
        cleanup()
    end))

    makeDraggable(mainFrame, header)

    -- Content Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, -50)
    container.Position = UDim2.new(0, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame

    -- Loading Screen
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, 0, 1, 0)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Initializing..."
    loadingLabel.TextColor3 = THEME.Text
    loadingLabel.Font = Enum.Font.Gotham
    loadingLabel.TextSize = 16
    loadingLabel.Parent = container

    -- ============================
    -- Buttons Setup
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(1, -30, 0, 45)
    actionBtn.Position = UDim2.new(0, 15, 0, 15)
    actionBtn.BackgroundColor3 = THEME.Element
    actionBtn.TextColor3 = THEME.Text
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.TextSize = 15
    actionBtn.Visible = false
    actionBtn.Parent = container
    Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(1, -30, 0, 35)
    settingsBtn.Position = UDim2.new(0, 15, 0, 75)
    settingsBtn.BackgroundColor3 = THEME.Element
    settingsBtn.Text = "Settings"
    settingsBtn.TextColor3 = THEME.Text
    settingsBtn.Font = Enum.Font.Gotham
    settingsBtn.TextSize = 14
    settingsBtn.Visible = false
    settingsBtn.Parent = container
    Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 6)
    addHoverEffect(settingsBtn, THEME.Element)

    local universalBtn = Instance.new("TextButton")
    universalBtn.Size = UDim2.new(1, -30, 0, 35)
    universalBtn.Position = UDim2.new(0, 15, 0, 120)
    universalBtn.BackgroundColor3 = THEME.Element
    universalBtn.Text = "Universal Scripts"
    universalBtn.TextColor3 = THEME.Text
    universalBtn.Font = Enum.Font.Gotham
    universalBtn.TextSize = 14
    universalBtn.Visible = false
    universalBtn.Parent = container
    Instance.new("UICorner", universalBtn).CornerRadius = UDim.new(0, 6)
    addHoverEffect(universalBtn, THEME.Element)

    --=========== Tab Logic
    local function showMainTab()
        if container:FindFirstChild("TabFrame") then container.TabFrame:Destroy() end
        actionBtn.Visible = true
        settingsBtn.Visible = true
        universalBtn.Visible = true
    end

    local function openTab()
        actionBtn.Visible = false
        settingsBtn.Visible = false
        universalBtn.Visible = false

        local tabFrame = Instance.new("Frame")
        tabFrame.Name = "TabFrame"
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Parent = container

        local backBtn = Instance.new("TextButton")
        backBtn.Size = UDim2.new(0, 60, 0, 25)
        backBtn.Position = UDim2.new(0, 10, 0, 5)
        backBtn.BackgroundColor3 = THEME.Danger
        backBtn.Text = "Back"
        backBtn.TextColor3 = THEME.Text
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 12
        backBtn.Parent = tabFrame
        Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 4)
        table.insert(connections, backBtn.MouseButton1Click:Connect(function()
            playSound("Click")
            tabFrame:Destroy()
            showMainTab()
        end))

        return tabFrame
    end

    --=========== Universal Tab
    table.insert(connections, universalBtn.MouseButton1Click:Connect(function()
        playSound("Click")
        local tabFrame = openTab()

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -20, 1, -45)
        scroll.Position = UDim2.new(0, 10, 0, 40)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.Parent = tabFrame

        local layout = Instance.new("UIListLayout")
        -- Force layout to respect our sorted array insertion order
        layout.SortOrder = Enum.SortOrder.LayoutOrder 
        layout.Padding = UDim.new(0, 5)
        layout.Parent = scroll

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, 0, 0, 30)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Loading scripts..."
        statusLabel.TextColor3 = THEME.Text
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 14
        statusLabel.Parent = scroll

        task.spawn(function()
            local files, err = fetchUniversalScripts()
            statusLabel:Destroy()

            if err then
                local errLabel = Instance.new("TextLabel")
                errLabel.Size = UDim2.new(1, 0, 0, 30)
                errLabel.BackgroundTransparency = 1
                errLabel.Text = "Error: " .. err
                errLabel.TextColor3 = THEME.Danger
                errLabel.Font = Enum.Font.Gotham
                errLabel.TextSize = 14
                errLabel.Parent = scroll
                return
            end

            -- Files are already sorted A-Z from fetchUniversalScripts()
            for _, file in ipairs(files) do
                local displayName = file.name -- Already cleaned (no .lua)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = THEME.Element
                btn.Text = "  " .. displayName
                btn.TextColor3 = THEME.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 13
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = scroll
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                local defaultColor = THEME.Element
                addHoverEffect(btn, defaultColor)

                table.insert(connections, btn.MouseButton1Click:Connect(function()
                    if isExecuting then return end
                    isExecuting = true
                    playSound("Click")
                    btn.Text = "  ⏳ Executing..."
                    btn.BackgroundColor3 = THEME.Warning

                    task.spawn(function()
                        local success, err = pcall(function()
                            loadstring(game:HttpGet(file.download_url))()
                        end)
                        
                        if success then
                            btn.Text = "  ✓ " .. displayName
                            btn.BackgroundColor3 = THEME.Success
                        else
                            btn.Text = "  ✗ Error"
                            btn.BackgroundColor3 = THEME.Danger
                            notify("Execution Failed", tostring(err):sub(1, 50), 4)
                        end
                        
                        task.wait(2)
                        btn.Text = "  " .. displayName
                        btn.BackgroundColor3 = defaultColor
                        isExecuting = false
                    end)
                end))
            end
        end)
    end))

    --=========== Settings Tab
    table.insert(connections, settingsBtn.MouseButton1Click:Connect(function()
        playSound("Click")
        local tabFrame = openTab()

        local notifyBtn = Instance.new("TextButton")
        notifyBtn.Size = UDim2.new(1, -20, 0, 40)
        notifyBtn.Position = UDim2.new(0, 10, 0, 50)
        notifyBtn.BackgroundColor3 = THEME.Element
        notifyBtn.TextColor3 = THEME.Text
        notifyBtn.Font = Enum.Font.Gotham
        notifyBtn.TextSize = 14
        notifyBtn.Parent = tabFrame
        Instance.new("UICorner", notifyBtn).CornerRadius = UDim.new(0, 6)

        local function updateNotifyBtn()
            notifyBtn.Text = "Notifications: " .. (_G.ScriptHubState.NotifyEnabled and "ON" or "OFF")
            notifyBtn.BackgroundColor3 = _G.ScriptHubState.NotifyEnabled and THEME.Success or THEME.Danger
        end
        updateNotifyBtn()

        table.insert(connections, notifyBtn.MouseButton1Click:Connect(function()
            playSound("Click")
            _G.ScriptHubState.NotifyEnabled = not _G.ScriptHubState.NotifyEnabled
            updateNotifyBtn()
        end))

        local restartBtn = Instance.new("TextButton")
        restartBtn.Size = UDim2.new(1, -20, 0, 40)
        restartBtn.Position = UDim2.new(0, 10, 0, 100)
        restartBtn.BackgroundColor3 = THEME.Warning
        restartBtn.Text = "Restart Hub"
        restartBtn.TextColor3 = THEME.Text
        restartBtn.Font = Enum.Font.GothamBold
        restartBtn.TextSize = 14
        restartBtn.Parent = tabFrame
        Instance.new("UICorner", restartBtn).CornerRadius = UDim.new(0, 6)

        table.insert(connections, restartBtn.MouseButton1Click:Connect(function()
            playSound("Close")
            initializeGUI() -- Rebuilds the whole UI safely
        end))
    end))

    -- ============================
    -- STARTUP SEQUENCE
    -- ============================
    task.spawn(function()
        loadingLabel.Text = "Fetching game data..."
        task.wait(0.2)
        
        local match, err = fetchGameScript()

        if match then
            actionBtn.Text = "Execute: " .. match.name
            actionBtn.BackgroundColor3 = THEME.Success
            addHoverEffect(actionBtn, THEME.Success)
            
            table.insert(connections, actionBtn.MouseButton1Click:Connect(function()
                if isExecuting then return end
                isExecuting = true
                playSound("Click")
                actionBtn.Text = "Executing..."
                actionBtn.BackgroundColor3 = THEME.Warning

                task.spawn(function()
                    local execSuccess, execErr = pcall(function()
                        loadstring(game:HttpGet(match.scriptUrl))()
                    end)
                    
                    if execSuccess then
                        actionBtn.Text = "✓ Loaded Successfully"
                        actionBtn.BackgroundColor3 = THEME.Success
                        notify("Script Loader", match.name .. " loaded!", 3)
                    else
                        actionBtn.Text = "✗ Execution Error"
                        actionBtn.BackgroundColor3 = THEME.Danger
                        notify("Script Loader", "Failed: " .. tostring(execErr):sub(1, 50), 4)
                    end
                    
                    task.wait(2)
                    actionBtn.Text = "Execute: " .. match.name
                    actionBtn.BackgroundColor3 = THEME.Success
                    isExecuting = false
                end)
            end))
            notify("Script Hub", "Supported: " .. match.name, 3)
        else
            actionBtn.Text = "Game Not Supported"
            actionBtn.BackgroundColor3 = THEME.Element
            addHoverEffect(actionBtn, THEME.Element)
            table.insert(connections, actionBtn.MouseButton1Click:Connect(function()
                playSound("Click")
                notify("Script Hub", "This game is not supported.", 3)
            end))
        end

        loadingLabel:Destroy()
        actionBtn.Visible = true
        settingsBtn.Visible = true
        universalBtn.Visible = true
        playSound("HubLoaded")
    end)
end

-- ============================
-- INIT
-- ============================
preloadSounds()
initializeGUI()
