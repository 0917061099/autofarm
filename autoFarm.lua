local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local platformCount = 9
local farmCount = 0
local totalCoinsEarned = 0
local goldPerRound = 132 -- ปรับตามจริง
local startTime = os.clock()

-- 🧠 GUI แสดงข้อมูล
local function createFarmCounterGUI()
    if player:FindFirstChild("PlayerGui"):FindFirstChild("FarmCounterGUI") then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmCounterGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- พื้นหลังดำเต็มจอ
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.ZIndex = 0
    bg.Parent = screenGui

    -- รอบ
    local label1 = Instance.new("TextLabel")
    label1.Name = "FarmCounterLabel"
    label1.Size = UDim2.new(0, 250, 0, 40)
    label1.Position = UDim2.new(0, 10, 0, 10)
    label1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label1.TextColor3 = Color3.fromRGB(255, 255, 0)
    label1.Font = Enum.Font.GothamBold
    label1.TextScaled = true
    label1.Text = "รอบที่: 0"
    label1.ZIndex = 1
    label1.Parent = screenGui

    -- รวมเงิน
    local label2 = Instance.new("TextLabel")
    label2.Name = "CoinCounterLabel"
    label2.Size = UDim2.new(0, 250, 0, 40)
    label2.Position = UDim2.new(0, 10, 0, 55)
    label2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label2.TextColor3 = Color3.fromRGB(0, 255, 0)
    label2.Font = Enum.Font.GothamBold
    label2.TextScaled = true
    label2.Text = "ได้เงินรวม: 0"
    label2.ZIndex = 1
    label2.Parent = screenGui

    -- เงินต่อนาที
    local label3 = Instance.new("TextLabel")
    label3.Name = "RatePerMinuteLabel"
    label3.Size = UDim2.new(0, 250, 0, 40)
    label3.Position = UDim2.new(0, 10, 0, 100)
    label3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label3.TextColor3 = Color3.fromRGB(0, 200, 255)
    label3.Font = Enum.Font.GothamBold
    label3.TextScaled = true
    label3.Text = "เงินต่อนาที: 0"
    label3.ZIndex = 1
    label3.Parent = screenGui
end

-- อัปเดต GUI
local function updateFarmCounter()
    local gui = player:FindFirstChild("PlayerGui"):FindFirstChild("FarmCounterGUI")
    if gui then
        local roundLabel = gui:FindFirstChild("FarmCounterLabel")
        local coinLabel = gui:FindFirstChild("CoinCounterLabel")
        local rateLabel = gui:FindFirstChild("RatePerMinuteLabel")

        if roundLabel then
            roundLabel.Text = "รอบที่: " .. tostring(farmCount)
        end
        if coinLabel then
            coinLabel.Text = "ได้เงินรวม: " .. tostring(totalCoinsEarned)
        end
        if rateLabel then
            local elapsed = os.clock() - startTime
            local ratePerMinute = 0
            if elapsed > 0 then
                ratePerMinute = math.floor(totalCoinsEarned / elapsed * 60)
            end
            rateLabel.Text = "เงินต่อนาที: " .. tostring(ratePerMinute)
        end
    end
end

-- หาตำแหน่ง DarknessPart
local function getDarknessPartPos(index)
    local success, pos = pcall(function()
        local caveStage = workspace:WaitForChild("BoatStages", 10)
            :WaitForChild("NormalStages", 10)
            :WaitForChild("CaveStage" .. index, 10)
        return caveStage:WaitForChild("DarknessPart", 10).Position
    end)
    return success and pos or nil
end

-- สร้างแพ
local function createPlatformAtPosition(index, position)
    local platform = Instance.new("Part")
    platform.Name = "AutoPlatform_" .. index
    platform.Size = Vector3.new(20, 2, 20)
    platform.Anchored = true
    platform.Position = position
    platform.Color = Color3.fromRGB(0, 255, 255)
    platform.Material = Enum.Material.Neon
    platform.Parent = workspace
    return platform
end

-- เทเลพอร์ตข้ามแพ
local function teleportAndManagePlatforms(hrp)
    local currentPlatform = nil
    for i = 1, platformCount do
        local pos = getDarknessPartPos(i)
        if pos then
            local newPlatform = createPlatformAtPosition(i, pos)
            wait(0.2)
            hrp.CFrame = CFrame.new(newPlatform.Position + Vector3.new(0, 5, 0))
            wait(3)
            if currentPlatform and currentPlatform ~= newPlatform then
                currentPlatform:Destroy()
            end
            currentPlatform = newPlatform
        else
            warn("❌ ข้าม CaveStage" .. i)
        end
    end

    local success, goldenPos = pcall(function()
        return workspace:WaitForChild("BoatStages", 10)
            :WaitForChild("NormalStages", 10)
            :WaitForChild("TheEnd", 10)
            :WaitForChild("GoldenChest", 10)
            :WaitForChild("Trigger", 10).Position
    end)
    if success then
        hrp.CFrame = CFrame.new(goldenPos + Vector3.new(0, 5, 0))
    end
end

-- หา server ใหม่และ teleport
local function getNewServer()
    local PlaceId = game.PlaceId
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in pairs(servers.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            return server.id
        end
    end
    return nil
end

local function hopToNewServer()
    local newServerId = getNewServer()
    if newServerId then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, newServerId, player)
    else
        warn("❌ ไม่พบเซิร์ฟใหม่ กำลังลองใหม่...")
        task.wait(5)
        hopToNewServer()
    end
end

-- รันฟาร์มวน + hop ทุก 15 นาที
local function runAutoFarm()
    createFarmCounterGUI()
    while true do
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        wait(5)
        teleportAndManagePlatforms(hrp)

        totalCoinsEarned += goldPerRound
        farmCount += 1
        updateFarmCounter()

        -- ครบ 15 นาที = 900 วิ → hop
        local elapsed = os.clock() - startTime
        if elapsed >= 900 then
            hopToNewServer()
            break
        end

        player.CharacterAdded:Wait()
    end
end

-- 🔁 เริ่มรัน
runAutoFarm()
