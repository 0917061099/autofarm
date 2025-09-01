local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local platformCount = 9
local goldPerRound = 132 -- ปรับตามจริง
local startTime = os.clock()

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

-- หาตำแหน่ง GoldenChest
local function getGoldenChestPos()
    local success, pos = pcall(function()
        return workspace:WaitForChild("BoatStages", 10)
            :WaitForChild("NormalStages", 10)
            :WaitForChild("TheEnd", 10)
            :WaitForChild("GoldenChest", 10)
            :WaitForChild("Trigger", 10).Position
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

-- เทเลพอร์ตข้ามแพทีละแพ
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
end

-- ตรวจสอบ RemoteFunction InstaLoad Function ใน ReplicatedStorage
local function checkInstaLoad()
    local InstaLoad = ReplicatedStorage:FindFirstChild("InstaLoad Function")
    return InstaLoad ~= nil
end

-- TP ไป GoldenChest ซ้ำ ๆ จนเจอ RemoteFunction
local function tpToGoldenChestUntilInstaLoad(hrp)
    local goldenPos = getGoldenChestPos()
    if not goldenPos then
        warn("❌ ไม่พบ GoldenChest")
        return
    end

    local found = checkInstaLoad()
    local startCheck = os.clock()
    while not found do
        hrp.CFrame = CFrame.new(goldenPos + Vector3.new(0,5,0))
        wait(1)
        found = checkInstaLoad()
        -- ถ้าไม่เจอซ้ำ ๆ เกิน 60 วินาที ให้รอ 1 นาทีแล้วออก
        if not found and os.clock() - startCheck >= 60 then
            print("❌ ไม่พบ InstaLoad Function หลัง TP ซ้ำ ๆ รอ 1 นาที แล้วเริ่มรอบใหม่")
            wait(4)
            break
        end
    end

    if found then
        print("✅ พบ InstaLoad Function เริ่มรอบฟาร์มใหม่")
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
    while true do
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        -- 1️⃣ ฟาร์มแพทีละแพ
        teleportAndManagePlatforms(hrp)

        -- 2️⃣ TP ไป GoldenChest ซ้ำ ๆ จนเจอ RemoteFunction หรือรอ 1 นาที
        tpToGoldenChestUntilInstaLoad(hrp)

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
