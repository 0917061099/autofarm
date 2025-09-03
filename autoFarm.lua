--BAB

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local platformCount = 9
local fixedWaitTime = 4 -- เวลารอคงที่ (วิ)
local serverHopInterval = 15 * 60 -- ⏳ ทุก ๆ 15 นาที (900 วินาที)

-- 📌 ฟังก์ชันย้ายเซิร์ฟเวอร์
local function serverHop()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    local success, result

    repeat
        success, result = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor)
            )
        end)
        if success and result and result.data then
            for _, v in pairs(result.data) do
                if v.playing < v.maxPlayers then
                    table.insert(servers, v.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until cursor == "" or not success

    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        print("🌍 ย้ายไปเซิร์ฟใหม่:", randomServer)
        TeleportService:TeleportToPlaceInstance(placeId, randomServer, player)
    else
        warn("❌ หาเซิร์ฟใหม่ไม่เจอ")
    end
end

-- ฟังก์ชันหาตำแหน่ง DarknessPart
local function getDarknessPartPos(index)
    local success, pos = pcall(function()
        local caveStage = workspace:WaitForChild("BoatStages", 10)
            :WaitForChild("NormalStages", 10)
            :WaitForChild("CaveStage" .. index, 10)
        return caveStage:WaitForChild("DarknessPart", 10).Position
    end)
    return success and pos or nil
end

-- ฟังก์ชันหาตำแหน่ง GoldenChest
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
            task.wait(0.2)
            hrp.CFrame = CFrame.new(newPlatform.Position + Vector3.new(0, 5, 0))
            task.wait(3)
            if currentPlatform and currentPlatform ~= newPlatform then
                currentPlatform:Destroy()
            end
            currentPlatform = newPlatform
        else
            warn("❌ ข้าม CaveStage" .. i)
        end
    end
end

-- ตรวจสอบ RemoteFunction InstaLoad Function
local function checkInstaLoad()
    local InstaLoad = ReplicatedStorage:FindFirstChild("InstaLoad Function")
    return InstaLoad ~= nil
end

-- TP สลับไปมาระหว่าง GoldenChest ↔ Trees[8][5] จนเจอ InstaLoad
local function tpGoldenChestAndTree(hrp)
    local goldenPos = getGoldenChestPos()
    local treesPartPos = nil

    -- หา Trees[8][5].Part
    local success, pos = pcall(function()
        return workspace.BoatStages.NormalStages.TheEnd.Trees:GetChildren()[8]:GetChildren()[5].Part.Position
    end)
    if success and pos then
        treesPartPos = pos
    else
        warn("❌ ไม่พบ Trees[8][5].Part")
        return
    end

    if not goldenPos then
        warn("❌ ไม่พบ GoldenChest")
        return
    end

    print("⏳ เริ่ม TP สลับไปมาระหว่าง GoldenChest ↔ Trees[8][5] จนเจอ InstaLoad Function")

    while not checkInstaLoad() do
        hrp.CFrame = CFrame.new(goldenPos + Vector3.new(0, 5, 0))
        task.wait(0.5)
        hrp.CFrame = CFrame.new(treesPartPos + Vector3.new(0, 5, 0))
        task.wait(0.5)
    end

    print("✅ พบ InstaLoad Function! ฟาร์มต่อได้ทันที")
end

-- ฟังก์ชันฟาร์มหลัก
local function farmCycle(char)
    local hrp = char:WaitForChild("HumanoidRootPart")

    while true do
        -- ฟาร์มแพทีละแพ
        teleportAndManagePlatforms(hrp)

        -- TP ไป GoldenChest + สลับ Trees จนเจอ InstaLoad
        tpGoldenChestAndTree(hrp)

        -- รอคงที่ท้ายรอบ
        task.wait(fixedWaitTime)
    end
end

-- ฟังก์ชันเริ่มออโต้ฟาร์ม
local function startAutoFarm()
    local function onCharacterAdded(char)
        task.wait(1) -- กัน error ตอนเพิ่ง spawn
        task.spawn(function()  
            farmCycle(char)
        end)
    end

    -- กรณีที่ตัวละครโหลดแล้ว
    if player.Character then
        onCharacterAdded(player.Character)
    end

    -- กรณีตาย/รีเซ็ตตัว
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- 🔥 เริ่มทำงาน
startAutoFarm()

-- 🔥 เริ่มตัวจับเวลา server hop ทุก ๆ 15 นาที
task.spawn(function()
    while true do
        task.wait(serverHopInterval)
        print("⏳ ครบเวลา 15 นาที → ย้ายเซิร์ฟ")
        serverHop()
    end
end)
