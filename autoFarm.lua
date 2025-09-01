local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local platformCount = 9
local fixedWaitTime = 3 -- เวลารอคงที่หลังเจอ InstaLoad (วิ)

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

-- ตรวจสอบ RemoteFunction InstaLoad Function
local function checkInstaLoad()
    local InstaLoad = ReplicatedStorage:FindFirstChild("InstaLoad Function")
    return InstaLoad ~= nil
end

-- TP ไป GoldenChest แล้วรอเวลาคงที่
local function tpToGoldenChest(hrp)
    local goldenPos = getGoldenChestPos()
    if not goldenPos then
        warn("❌ ไม่พบ GoldenChest")
        return
    end

    while not checkInstaLoad() do
        hrp.CFrame = CFrame.new(goldenPos + Vector3.new(0,5,0))
        wait(0.5)
    end

    print("✅ พบ InstaLoad Function! รอ " .. fixedWaitTime .. " วิ ก่อนฟาร์มต่อ")
    wait(fixedWaitTime)
end

-- ฟังก์ชันฟาร์มหลัก
local function farmCycle(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    while true do
        -- ฟาร์มแพทีละแพ
        teleportAndManagePlatforms(hrp)
        
        -- TP ไป GoldenChest แล้วรอเวลาคงที่
        tpToGoldenChest(hrp)
    end
end

-- เริ่มฟาร์มและเชื่อมต่อกับ CharacterAdded
local function startAutoFarm()
    if player.Character then
        spawn(function()
            farmCycle(player.Character)
        end)
    end

    player.CharacterAdded:Connect(function(char)
        spawn(function()
            farmCycle(char)
        end)
    end)
end

startAutoFarm()
