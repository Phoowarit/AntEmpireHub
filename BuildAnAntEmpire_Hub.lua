--[[
    Build An Ant Empire Hub
    Auto Roll & Filter, Food Selling with Target Multiplier,
    Dungeon, Events, Snail Click, Strawberry Coins, Ant Speed,
    FPS Cap Lock, Config Manager, Anti-AFK & Performance Boost.
]]

-- ========================================================================
-- บริการหลักของ ROBLOX (Core Services)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- โหลด WindUI Library อย่างปลอดภัย
local WindUI = nil
local windUiSuccess, windUiErr = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not windUiSuccess or not WindUI then
    warn("[AntEmpireHub] Failed to load WindUI library: " .. tostring(windUiErr))
    return
end

-- 1. ลงทะเบียนธีม VibrantNeon อย่างปลอดภัย (ปุ่มเปิดสวิตช์สีเขียว #00e676)
pcall(function()
    if WindUI.AddTheme then
        WindUI:AddTheme({
            Name = "VibrantNeon",
            Accent = Color3.fromHex("#00e676"),
            Dialog = Color3.fromHex("#181924"),
            Outline = Color3.fromHex("#2a2b36"),
            Text = Color3.fromHex("#ffffff"),
            Placeholder = Color3.fromHex("#888899"),
            Background = Color3.fromHex("#12131a"),
            Button = Color3.fromHex("#252738"),
            Icon = Color3.fromHex("#a1a1aa"),
            Toggle = Color3.fromHex("#00e676"),
            Slider = Color3.fromHex("#00e676"),
            Checkbox = Color3.fromHex("#00e676"),
            PanelBackground = Color3.fromHex("#14151f"),
            PanelBackgroundTransparency = 0.95,
            SliderIcon = Color3.fromHex("#00e676"),
            Primary = Color3.fromHex("#00e676"),
            LabelBackground = Color3.fromHex("#000000"),
            LabelBackgroundTransparency = 0.83,
            ElementBackground = Color3.fromHex("#1b1d28"),
            ElementBackgroundTransparency = 0
        })
    end
end)

-- 2. กำหนดธีมเริ่มต้น (Dark เป็นธีมในตัวที่มีสวิตช์เปิดสีเขียว #33C759 เป็นค่าเริ่มต้น)
local selectedTheme = "Dark"
pcall(function()
    if WindUI.Themes and WindUI.Themes["VibrantNeon"] then
        selectedTheme = "VibrantNeon"
    end
end)

-- 3. สร้างหน้าต่างหลัก (ไม่มีอิโมจิ)
local Window = WindUI:CreateWindow({
    Title = "Ant Empire Hub",
    Author = "Pro Edition v3.0",
    Folder = "AntEmpireHub",
    Size = UDim2.fromOffset(780, 560),
    Transparent = true,
    Theme = selectedTheme,
    SideBarWidth = 210,
    HasOutline = true,
    ToggleKey = Enum.KeyCode.RightControl,
    User = {
        Enabled = true,
        Anonymous = false,
        Title = LocalPlayer and LocalPlayer.DisplayName or "Player",
        Desc = LocalPlayer and ("@" .. LocalPlayer.Name) or "@Player",
        Callback = function() end
    }
})

-- ========================================================================
-- ค่าตัวแปรระบบ (Flags)
-- ========================================================================
local Flags = {
    -- Master Toggles
    MasterAutoFarm = false,

    -- Rolling & Purchasing
    AutoRollAnt = false,
    DisableCloverEffect = false,
    AutoBuyAnt = false,
    AutoBuyStar = false,
    AutoBuyRollForIndex = false,
    BuyRarities = { "Epic", "Legendary", "Mythic", "Exotic", "Secret", "Divine", "OP", "Celestial" },
    BuyMutations = { "None" },
    SkipIfNotEnoughGold = true,

    -- Food & Farm
    AutoCollect = false,
    AutoSell = false,
    SellAtMultiplier = false,
    Multiplier = 1.80,
    AutoSellToFoodBuyer = false,

    -- Ants & Upgrades
    AutoPlaceAnt = false,
    AutoEquipBest = false,
    AutoUnlockAntHole = false,
    HideAnts = false,
    AutoUpgradeEquippedAnts = false,
    AutoStrokePets = false,
    AutoAntSpeedPotion = false,
    AntAnimationSpeed = 1.0,
    AutoUpgradeAntSpeed = false,
    AutoBuyUpgrades = false,
    UpgradeInterval = 3.0,
    SelectedUpgrades = { "Nest Layer (เพิ่มชั้นรัง)", "Ant Speed (ความเร็วมด)", "Ant Atk (พลังโจมตี)" },

    -- Dungeon
    AutoDungeon = false,
    AutoPressDungeonStart = true,
    Auto4xAttackSpeed = false,
    AutoStarDungeon = false,

    -- Events
    AutoPickupStrawberryCoins = false,
    CoinPickupDelay = 0.10,
    AutoClickTravellingSnail = false,
    AutoStarfallEvent = false,
    AutoClaimIndex = false,

    -- Converter & Shop
    AutoResourceConverter = false,
    ConverterAnts = "None",
    KeepPerStack = 15,
    AutoBuyFood = false,
    SelectedFood = "None",

    -- Player & Movement
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,

    -- Utilities, AFK & Performance
    AntiAFK = true,
    FPSBoost = false,
    BlackScreen = false,
    LowGraphics = false,
    Fullbright = false,
    LockAFK15FPS = false,
    TargetFPS = 60,
    HideUIOnStart = false,
    AutoSaveConfig = false,
    EnteredCode = ""
}

local MultiplierLiveStatus = nil

-- Config File Path
local ConfigPath = "AntEmpireHub/config.json"

-- บันทึกการตั้งค่า (Save Config)
local function saveConfig()
    local success = false
    pcall(function()
        if not isfolder or not writefile then return end
        if not isfolder("AntEmpireHub") then
            makefolder("AntEmpireHub")
        end
        local data = {}
        for k, v in pairs(Flags) do
            if type(v) ~= "function" and type(v) ~= "userdata" then
                data[k] = v
            end
        end
        writefile(ConfigPath, HttpService:JSONEncode(data))
        success = true
        WindUI:Notify({
            Title = "Config Saved",
            Content = "บันทึกการตั้งค่าทั้งหมดลงในไฟล์เรียบร้อยแล้ว",
            Duration = 2.5
        })
    end)
    return success
end

-- โหลดการตั้งค่า (Load Config)
local function loadConfig(silent)
    local success = false
    pcall(function()
        if not isfile or not readfile then return end
        if not isfile(ConfigPath) then return end
        local raw = readfile(ConfigPath)
        local data = HttpService:JSONDecode(raw)
        if type(data) == "table" then
            for k, v in pairs(data) do
                if Flags[k] ~= nil then
                    Flags[k] = v
                end
            end
            success = true
            if not silent then
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = "โหลดการตั้งค่าที่บันทึกไว้เรียบร้อยแล้ว",
                    Duration = 2.5
                })
            end
        end
    end)
    return success
end

-- รีเซ็ตการตั้งค่า (Reset Config)
local function resetConfig()
    pcall(function()
        if isfile and isfile(ConfigPath) and delfile then
            delfile(ConfigPath)
        end
        WindUI:Notify({
            Title = "Config Reset",
            Content = "รีเซ็ตการตั้งค่ากลับเป็นค่าเริ่มต้นแล้ว",
            Duration = 2.5
        })
    end)
end

-- แมปชื่ออัปเกรดเป็นชื่อจริงในระบบเกม
local UpgradeMapping = {
    ["Nest Layer (เพิ่มชั้นรัง)"] = "巢穴层数",
    ["Ant Speed (ความเร็วมด)"] = "蚂蚁移速",
    ["Ant Atk (พลังโจมตี)"] = "蚂蚁攻击力",
    ["Queen Level (เลเวลนางพญา)"] = "蚁后等级",
    ["Luck (ค่าโชคสุ่มมด)"] = "幸运值",
    ["Single Roll Count (จำนวนสุ่ม)"] = "单抽数量"
}

local RarityList = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", 
    "Mythic", "Exotic", "Secret", "Divine", "OP", "Celestial"
}

local MutationList = {
    "Any", "None", "Leaf", "Bubblegum", "Candy", "Rainbow", "Petal", "Starlight"
}

local TagMapping = {
    [0] = "None",
    [1] = "Leaf",
    [2] = "Bubblegum",
    [3] = "Candy",
    [4] = "Rainbow",
    [5] = "Petal",
    [6] = "Starlight"
}

-- ========================================================================
-- Helper ฟังก์ชันระบบ และแคชการตั้งค่าเกม
-- ========================================================================
local battle_tbattribute
pcall(function()
    local gc = ReplicatedStorage:WaitForChild("_genConfigs", 3) or ReplicatedStorage:FindFirstChild("_genConfigs")
    if gc then
        local cf = gc:WaitForChild("battle_tbattribute", 2) or gc:FindFirstChild("battle_tbattribute")
        if cf then battle_tbattribute = require(cf) end
    end
end)

local battle_tbnestunlock
pcall(function()
    local gc = ReplicatedStorage:WaitForChild("_genConfigs", 3) or ReplicatedStorage:FindFirstChild("_genConfigs")
    if gc then
        local cf = gc:WaitForChild("battle_tbnestunlock", 2) or gc:FindFirstChild("battle_tbnestunlock")
        if cf then battle_tbnestunlock = require(cf) end
    end
end)

local battle_tbunit
pcall(function()
    local gc = ReplicatedStorage:WaitForChild("_genConfigs", 3) or ReplicatedStorage:FindFirstChild("_genConfigs")
    if gc then
        local cf = gc:WaitForChild("battle_tbunit", 2) or gc:FindFirstChild("battle_tbunit")
        if cf then battle_tbunit = require(cf) end
    end
end)

local battle_tbtag
pcall(function()
    local gc = ReplicatedStorage:WaitForChild("_genConfigs", 3) or ReplicatedStorage:FindFirstChild("_genConfigs")
    if gc then
        local cf = gc:WaitForChild("battle_tbtag", 2) or gc:FindFirstChild("battle_tbtag")
        if cf then battle_tbtag = require(cf) end
    end
end)

-- ----- ตัวช่วยอ่านราคาอัปเกรด (ทนต่อรูปแบบข้อมูลที่ต่างกัน) -----
local function reloadAttrConfig()
    if battle_tbattribute then return end
    pcall(function()
        local gc = ReplicatedStorage:FindFirstChild("_genConfigs")
        local cf = gc and gc:FindFirstChild("battle_tbattribute")
        if cf then battle_tbattribute = require(cf) end
    end)
end

local function extractCost(entry)
    if type(entry) ~= "table" then return nil end
    for _, k in ipairs({ "Cost", "cost", "CostGold", "Gold", "Price", "Coin", "CostFood" }) do
        local v = entry[k]
        if type(v) == "number" and v > 0 then return v end
        if type(v) == "string" and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
        if type(v) == "table" then
            local n = tonumber(v.Count or v.Amount or v.Num or v.Value)
            if not n then
                for i = #v, 1, -1 do
                    if type(v[i]) == "number" then n = v[i] break end
                end
            end
            if n and n > 0 then return n end
        end
    end
    return nil
end

-- คืนค่า: เลเวลปัจจุบัน, ราคาถัดไป, สถานะ ("ok" | "maxed" | "nocfg" | "nocost")
local function getUpgradeInfo(attr)
    local lvl = 1
    pcall(function()
        local WuKong = require(ReplicatedStorage.WuKong)
        lvl = tonumber(WuKong:ExecuteQuery(string.format("/属性/%s?属性数量", attr))) or 1
    end)
    reloadAttrConfig()
    local cfg = battle_tbattribute and battle_tbattribute[attr]
    if type(cfg) ~= "table" or type(cfg.Info) ~= "table" then
        return lvl, nil, "nocfg"
    end
    local nextInfo = cfg.Info[lvl + 1]
    if nextInfo == nil then
        local maxKey = 0
        for k in pairs(cfg.Info) do
            if type(k) == "number" and k > maxKey then maxKey = k end
        end
        if maxKey > 0 and lvl >= maxKey then
            return lvl, nil, "maxed"
        end
        return lvl, nil, "nocost"
    end
    local cost = extractCost(nextInfo)
    if cost then return lvl, cost, "ok" end
    return lvl, nil, "nocost"
end

-- ถ้าอ่านราคาไม่ได้: ลองกดอย่างระวัง (ครั้งต่อไปเมื่อเงินเพิ่มขึ้นมากพอ หรือเลเวลขึ้นแล้วเท่านั้น)
local probeState = {}
local function probeAllowed(key, gold, lvl, interval)
    local now = os.clock()
    local st = probeState[key]
    if gold <= 0 then return false end
    if not st then return true end
    if (now - st.t) < math.max(interval, 3) then return false end
    if lvl > st.lvl then return true end
    if gold >= st.gold * 1.3 and (now - st.t) >= math.max(interval * 5, 15) then return true end
    return (now - st.t) >= 120
end
local function probeMark(key, gold, lvl)
    probeState[key] = { t = os.clock(), gold = gold, lvl = lvl }
end

-- Helper อัปเดตข้อความ Paragraph ของ WindUI อย่างเสถียร
local function updateParagraph(para, title, desc)
    if not para then return end
    pcall(function()
        if para.SetTitle then
            para:SetTitle(title)
        end
        if para.SetDesc and desc then
            para:SetDesc(desc)
        end
        local frame = para.ParagraphFrame or para.Frame
        if frame and frame.UIElements then
            if frame.UIElements.Title and title then
                frame.UIElements.Title.Text = tostring(title)
                frame.UIElements.Title.Visible = true
            end
            if frame.UIElements.Desc and desc then
                frame.UIElements.Desc.Text = tostring(desc)
                frame.UIElements.Desc.Visible = true
            end
        end
    end)
end

-- Helper ควบคุมขีดจำกัดเฟรมเรต (FPS Cap) และฟังก์ชันจำกัดเฟรมเรตสำหรับโหมด AFK
local fpsThrottleConnection = nil

local function applyFpsCap(fps)
    local target = math.floor(tonumber(fps) or 60)
    if target < 5 then target = 5 end

    -- 1. เรียกใช้งานฟังก์ชันของ Executor หลากหลายรูปแบบ
    pcall(function()
        local fn = setfpscap or set_fpscap or setfps or set_fps or (getgenv and (getgenv().setfpscap or getgenv().set_fpscap))
        if fn then
            fn(target)
        end
    end)

    -- 2. เคลียร์ RenderStepped throttle เดิม
    if fpsThrottleConnection then
        fpsThrottleConnection:Disconnect()
        fpsThrottleConnection = nil
    end

    -- 3. หากตั้งค่า <= 30 FPS (เช่น 15 FPS โหมด AFK) ให้หน่วงเวลา RenderStepped โดยตรงเพื่อให้เฟรมเรตลดลง 15 FPS จริง 100%
    if target <= 30 then
        local minDelta = 1 / target
        local lastTime = os.clock()
        fpsThrottleConnection = RunService.RenderStepped:Connect(function()
            local now = os.clock()
            local elapsed = now - lastTime
            local diff = minDelta - elapsed
            if diff > 0 then
                local t0 = os.clock()
                while (os.clock() - t0) < diff do end
            end
            lastTime = os.clock()
        end)
    end
end

local lowGraphicsOriginals = {}
local terrainDecorationOriginal

local function applyLowGraphics(enabled)
    Flags.LowGraphics = enabled
    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if enabled then
        if terrain and terrainDecorationOriginal == nil then
            terrainDecorationOriginal = terrain.Decoration
            terrain.Decoration = false
        end

        for _, root in ipairs({ Workspace, Lighting }) do
            for _, instance in ipairs(root:GetDescendants()) do
                if not lowGraphicsOriginals[instance] then
                    local original = {}
                    if instance:IsA("BasePart") then
                        original.Material = instance.Material
                        original.Reflectance = instance.Reflectance
                        original.CastShadow = instance.CastShadow
                    end
                    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
                        or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles")
                        or instance:IsA("PostEffect") or instance:IsA("Highlight") then
                        original.Enabled = instance.Enabled
                    end
                    if next(original) then
                        lowGraphicsOriginals[instance] = original
                    end
                end

                if instance:IsA("BasePart") then
                    instance.Material = Enum.Material.SmoothPlastic
                    instance.Reflectance = 0
                    instance.CastShadow = false
                end
                if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
                    or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles")
                    or instance:IsA("PostEffect") or instance:IsA("Highlight") then
                    instance.Enabled = false
                end
            end
        end
        return
    end

    if terrain and terrainDecorationOriginal ~= nil then
        terrain.Decoration = terrainDecorationOriginal
    end
    terrainDecorationOriginal = nil

    for instance, original in pairs(lowGraphicsOriginals) do
        if instance and instance.Parent then
            pcall(function()
                for property, value in pairs(original) do
                    instance[property] = value
                end
            end)
        end
        lowGraphicsOriginals[instance] = nil
    end
end

-- ดึงจำนวนเงิน/ทองปัจจุบันของผู้เล่นอย่างแม่นยำ
local function getPlayerGold()
    local gold = 0
    pcall(function()
        local wk = ReplicatedStorage:WaitForChild("WuKong", 2) or ReplicatedStorage:FindFirstChild("WuKong")
        if wk then
            local WuKong = require(wk)
            local val = WuKong:ExecuteQuery("/货币/金币?属性数量")
            if val then gold = tonumber(val) or 0 end
        end
    end)
    if gold == 0 then
        pcall(function()
            local Battle = ReplicatedStorage:FindFirstChild("Battle")
            if Battle and Battle:FindFirstChild("Game") and Battle.Game:FindFirstChild("Helper") and Battle.Game.Helper:FindFirstChild("PlayerDataHelper") then
                local PlayerDataHelper = require(Battle.Game.Helper.PlayerDataHelper)
                gold = tonumber(PlayerDataHelper.GetPlayerGold(LocalPlayer.UserId)) or 0
            end
        end)
    end
    return gold
end

-- รับส่งแพ็กเกจ ECS Command
local function sendEcsCommand(commandName, payload)
    pcall(function()
        local EventBus = require(ReplicatedStorage.Packages.EventBus)
        EventBus.FireServer("ECS_COMMAND", commandName, payload or {})
    end)
end

-- ค้นหาห้องรังของตนเอง (My Room)
local function getMyRoom()
    local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex")
    local rooms = Workspace:FindFirstChild("Rooms") or Workspace:FindFirstChild("Map")
    if not rooms then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:FindFirstChild("PlayerFood") or (child:FindFirstChild("1") and child:FindFirstChild("2")) then
                rooms = child
                break
            end
        end
    end
    if rooms then
        if myRoomIdx then
            local rm = rooms:FindFirstChild(tostring(myRoomIdx)) or rooms:FindFirstChild("Room" .. tostring(myRoomIdx))
            if rm then return rm end
        end
        for _, rm in ipairs(rooms:GetChildren()) do
            local owner = rm:GetAttribute("OwnerUserId") or rm:GetAttribute("UserId") or rm:GetAttribute("Owner")
            if owner == LocalPlayer.UserId or owner == LocalPlayer.Name then
                return rm
            end
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            local closestRoom = nil
            local minDist = 999999
            for _, rm in ipairs(rooms:GetChildren()) do
                local pf = rm:FindFirstChild("PlayerFood") or rm:FindFirstChild("Spawn") or rm:FindFirstChild("Floor")
                if pf then
                    local ppos = pf:IsA("Model") and pf:GetPivot().Position or pf.Position
                    local dist = (pos - ppos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestRoom = rm
                    end
                end
            end
            if closestRoom and minDist < 200 then
                return closestRoom
            end
        end
    end
    return nil
end

local function teleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and cf then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

-- ดึงค่าตัวคูณราคาขายปัจจุบันอย่างแม่นยำ (รองรับทั้ง PlayerDataHelper, FoodSellPriceService และ SellShopModel)
local function getCurrentFoodMultiplier()
    local curMul = 1.0
    
    -- วิธีที่ 1: ตรวจสอบจาก PlayerDataHelper (มีบัพ VIP, เพื่อน, สัตว์เลี้ยง ครบถ้วน)
    pcall(function()
        local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)
        if PlayerDataHelper and PlayerDataHelper.GetPlayerFoodSellPriceState then
            local state = PlayerDataHelper.GetPlayerFoodSellPriceState(LocalPlayer.UserId)
            if state and state.GoldPerFood then
                local v = tonumber(state.GoldPerFood)
                if v and v > 0 then curMul = v return end
            end
        end
    end)
    
    -- วิธีที่ 2: ตรวจสอบจาก FoodSellPriceService ของห้อง
    if curMul == 1.0 then
        pcall(function()
            local FoodSellPriceService = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellPriceService)
            if FoodSellPriceService and FoodSellPriceService.GetGoldPerFood then
                local v = tonumber(FoodSellPriceService.GetGoldPerFood())
                if v and v > 0 then curMul = v return end
            end
        end)
    end
    
    -- วิธีที่ 3: ตรวจสอบจาก SellShopModel
    if curMul == 1.0 then
        pcall(function()
            local sellShopModel = require(ReplicatedStorage.UI.Main.Model.SellShopModel)
            if sellShopModel then
                if not sellShopModel.Initialized then
                    sellShopModel:Init()
                end
                sellShopModel:RequestState(nil, true)
                if sellShopModel.State then
                    local v = tonumber(sellShopModel.State.GoldPerFood) or tonumber(sellShopModel.State.BaseGoldPerFood)
                    if v and v > 0 then curMul = v return end
                end
            end
        end)
    end
    
    return curMul
end

-- ตรวจสอบว่าตัวคูณราคาขายถึงเป้าหมายที่ผู้เล่นตั้งไว้หรือไม่ (เข้มงวด 100%)
local function isFoodMultiplierMet()
    if not Flags.SellAtMultiplier then
        return true
    end
    local cur = getCurrentFoodMultiplier()
    local target = tonumber(Flags.Multiplier) or 1.80
    return cur >= target
end

-- แปลงสตริงตัวเลขที่มีหน่วยย่อ (K, M, B, T, QA, QI) เป็นตัวเลขจริง
local function parseFormattedNumber(str)
    if not str or str == "" then return 0 end
    local clean = tostring(str):gsub("%$", ""):gsub(",", ""):gsub("%s+", ""):upper()
    if clean == "FREE" or clean:find("FREE") then
        return 0
    end
    
    local numStr, suffix = clean:match("^([%d%.]+)%s*([A-Z]*)$")
    if not numStr then
        numStr = clean:match("([%d%.]+)")
    end
    local val = tonumber(numStr) or 0
    if suffix and suffix ~= "" then
        if suffix == "K" then
            val = val * 1e3
        elseif suffix == "M" then
            val = val * 1e6
        elseif suffix == "B" then
            val = val * 1e9
        elseif suffix == "T" then
            val = val * 1e12
        elseif suffix == "QA" then
            val = val * 1e15
        elseif suffix == "QI" then
            val = val * 1e18
        end
    end
    return val
end

-- Helper บล็อคเอฟเฟกต์การสุ่ม (Clover / Luck / Super Roll Animation) เพื่อความรวดเร็ว
local function applyCloverEffectSetting()
    pcall(function()
        local Battle = ReplicatedStorage:FindFirstChild("Battle")
        if not Battle or not Battle:FindFirstChild("Game") or not Battle.Game:FindFirstChild("Helper") then return end
        local rollHelper = Battle.Game.Helper:FindFirstChild("RollPresentationHelper")
        if not rollHelper then return end

        local presRegMod = rollHelper:FindFirstChild("PresentationRegistry")
        local presDir = rollHelper:FindFirstChild("Presentations")
        if not presRegMod or not presDir then return end

        local presReg = require(presRegMod)
        local normalPres = require(presDir:WaitForChild("Normal", 2))
        local luck2Pres = presDir:FindFirstChild("Luck2") and require(presDir.Luck2)
        local luck4Pres = presDir:FindFirstChild("Luck4") and require(presDir.Luck4)
        local luck8Pres = presDir:FindFirstChild("Luck8") and require(presDir.Luck8)
        local superPres = presDir:FindFirstChild("Super") and require(presDir.Super)

        if not presReg._origResolve then
            presReg._origResolve = presReg.Resolve
            presReg.Resolve = function(a1)
                if Flags.DisableCloverEffect then
                    return "Normal", normalPres
                end
                return presReg._origResolve(a1)
            end
        end

        local function wrapPres(presMod)
            if presMod and not presMod._origPlay then
                presMod._origPlay = presMod.Play
                presMod.Play = function(a1, a2, a3, a4, a5, a6)
                    if Flags.DisableCloverEffect then
                        if a5 then a5.SuppressRollEffects = true end
                        return normalPres.Play(a1, a2, a3, a4, a5, a6)
                    end
                    return presMod._origPlay(a1, a2, a3, a4, a5, a6)
                end
            end
        end

        wrapPres(luck2Pres)
        wrapPres(luck4Pres)
        wrapPres(luck8Pres)
        wrapPres(superPres)
    end)
end

-- แกะข้อมูลมดจาก RollManager หรือ ProximityPrompt อย่างแม่นยำ
local function getPromptAntInfo(prompt)
    local info = {
        Cost = 0,
        Rarity = "",
        Mutation = "None",
        DisplayName = "Ant",
        UnitId = "",
        ClaimId = nil,
        IsItem = false,
        IsStar = false
    }

    -- 1. ดึงจาก RollPresentationHelper โดยตรง (แม่นยำ 100%)
    pcall(function()
        local Battle = ReplicatedStorage:FindFirstChild("Battle")
        if Battle and Battle:FindFirstChild("Game") and Battle.Game:FindFirstChild("Helper") and Battle.Game.Helper:FindFirstChild("RollPresentationHelper") then
            local rph = require(Battle.Game.Helper.RollPresentationHelper)
            local mgr = rph.GetManager()
            if mgr and mgr.ClaimPlatforms then
                for claimId, platform in pairs(mgr.ClaimPlatforms) do
                    if platform.ClaimPrompt == prompt or (platform.ResultModel and (prompt:IsDescendantOf(platform.ResultModel) or prompt.Parent == platform.ResultModel)) then
                        info.ClaimId = claimId
                        local res = platform.Result
                        if res then
                            if res.ResultType == "Item" then
                                info.IsItem = true
                                info.IsStar = true
                                info.Cost = 0
                                return
                            end
                            info.Cost = tonumber(res.Cost) or 0
                            info.UnitId = tostring(res.UnitId or "")
                            info.Rarity = tostring(res.Rarity or "Common")
                            local tagId = tonumber(res.TagId) or 0
                            info.Mutation = TagMapping[tagId] or "None"
                            return
                        end
                    end
                end
            end
        end
    end)

    if info.ClaimId and info.Rarity ~= "" then
        return info
    end

    -- 2. Fallback: ดึงจากข้อความและโมเดล
    local actionText = tostring(prompt.ActionText or "")
    local objectText = tostring(prompt.ObjectText or "")

    if objectText:find("Star") or actionText:find("Star") or prompt.Name:find("Star") then
        info.IsItem = true
        info.IsStar = true
        info.Cost = 0
        return info
    end

    local costNum = parseFormattedNumber(objectText)
    if not costNum or costNum == 0 then
        costNum = parseFormattedNumber(actionText)
    end
    if costNum and costNum > 0 then
        info.Cost = costNum
    end

    local model = prompt:FindFirstAncestorOfClass("Model")
    if model then
        for _, rar in ipairs(RarityList) do
            if model.Name:find(rar) or (model.Parent and model.Parent.Name:find(rar)) then
                info.Rarity = rar
                break
            end
        end

        local unitAttr = model:GetAttribute("UnitId") or model:GetAttribute("Id") or model.Name
        if unitAttr and battle_tbunit and battle_tbunit[unitAttr] then
            local cfg = battle_tbunit[unitAttr]
            if info.Rarity == "" and cfg.Rarity then
                info.Rarity = tostring(cfg.Rarity)
            end
            if cfg.DisplayName then
                info.DisplayName = tostring(cfg.DisplayName)
            end
            if info.Cost == 0 and cfg.Price then
                info.Cost = tonumber(cfg.Price) or 0
            end
        end
    end

    if info.Rarity == "" then
        for _, rar in ipairs(RarityList) do
            if objectText:find(rar) or actionText:find(rar) then
                info.Rarity = rar
                break
            end
        end
    end

    return info
end

-- ตรวจสอบว่ามดตรงตามเงื่อนไขฟิลเตอร์ที่ผู้เล่นเลือกไว้หรือไม่
local function isDesiredAnt(info, currentGold)
    if info.IsItem or info.IsStar then
        return Flags.AutoBuyStar or Flags.AutoStarDungeon
    end

    local rarityPassed = false
    if type(Flags.BuyRarities) ~= "table" or #Flags.BuyRarities == 0 then
        rarityPassed = true
    else
        local antRarity = string.lower(tostring(info.Rarity or ""))
        for _, rar in ipairs(Flags.BuyRarities) do
            if string.lower(tostring(rar)) == antRarity then
                rarityPassed = true
                break
            end
        end
    end

    if not rarityPassed then
        return false
    end

    local mutationPassed = false
    if type(Flags.BuyMutations) ~= "table" or #Flags.BuyMutations == 0 or table.find(Flags.BuyMutations, "Any") then
        mutationPassed = true
    else
        local antMut = string.lower(tostring(info.Mutation or "None"))
        for _, mut in ipairs(Flags.BuyMutations) do
            if string.lower(tostring(mut)) == antMut then
                mutationPassed = true
                break
            end
        end
    end

    if not mutationPassed then
        return false
    end

    return true
end

loadConfig(true)

-- ========================================================================
-- ตัวช่วยจัดการสวิตช์ (Toggle Registry) ให้ปุ่มลัดและสวิตช์ในเมนูซิงก์กันเสมอ
-- ========================================================================
local ToggleRegistry = {}
local ActiveMetric = nil
local UtilityGroups = { Teleport = true, Settings = true }

local function regToggle(tab, group, flagName, cfg)
    local el = tab:Toggle(cfg)
    ToggleRegistry[flagName] = { el = el, group = group, title = cfg.Title or flagName }
    return el
end

local function setFlagUI(flagName, value)
    Flags[flagName] = value
    local reg = ToggleRegistry[flagName]
    if reg and reg.el then
        pcall(function()
            if reg.el.Set then reg.el:Set(value) end
        end)
    end
end

local function stopAllAutomation()
    for flagName, reg in pairs(ToggleRegistry) do
        if not UtilityGroups[reg.group] and Flags[flagName] then
            setFlagUI(flagName, false)
        end
    end
    Flags.MasterAutoFarm = false
end

local function refreshActiveMetric()
    if not ActiveMetric then return end
    local names = {}
    for flagName, reg in pairs(ToggleRegistry) do
        if not UtilityGroups[reg.group] and flagName ~= "MasterAutoFarm" and Flags[flagName] then
            table.insert(names, reg.title)
        end
    end
    table.sort(names)
    if #names == 0 then
        updateParagraph(ActiveMetric, "สถานะ: ว่าง (ยังไม่ได้เปิดระบบใด)", "เปิด Master Auto Farm ด้านล่างเพื่อเริ่มฟาร์มได้ทันที")
    else
        local shown = {}
        for i = 1, math.min(4, #names) do shown[i] = names[i] end
        local more = #names > 4 and string.format(" และอีก %d ระบบ", #names - 4) or ""
        updateParagraph(ActiveMetric,
            string.format("สถานะ: กำลังทำงาน %d ระบบ", #names),
            table.concat(shown, " • ") .. more)
    end
end

-- ========================================================================
-- สร้างแท็บเมนู (ไม่มีอิโมจิ ออกแบบเรียบหรู คมชัด สไตล์มินิมอล)
-- ========================================================================
-- จัดกลุ่มเมนูด้านซ้าย (ถ้า WindUI เวอร์ชันนี้ไม่รองรับ Section จะใช้แบบเดิมอัตโนมัติ)
local function makeGroup(title)
    local ok, sec = pcall(function() return Window:Section({ Title = title, Opened = true }) end)
    if ok and sec and sec.Tab then return sec end
    return Window
end

local GroupMain = makeGroup("เริ่มต้น")
local GroupFarm = makeGroup("ฟาร์มอัตโนมัติ")
local GroupGame = makeGroup("กิจกรรม & ร้านค้า")
local GroupTools = makeGroup("เครื่องมือ")

local Tabs = {
    Home = GroupMain:Tab({ Title = "หน้าหลัก", Icon = "layout-grid" }),
    Roll = GroupFarm:Tab({ Title = "สุ่มมด", Icon = "sparkles" }),
    Farm = GroupFarm:Tab({ Title = "อาหาร & ขาย", Icon = "apple" }),
    Ants = GroupFarm:Tab({ Title = "มด & อัปเกรด", Icon = "bug" }),
    Dungeon = GroupGame:Tab({ Title = "ดันเจี้ยน", Icon = "swords" }),
    Events = GroupGame:Tab({ Title = "อีเวนต์", Icon = "sparkle" }),
    Shop = GroupGame:Tab({ Title = "แปลง & ร้านค้า", Icon = "recycle" }),
    Teleport = GroupTools:Tab({ Title = "วาร์ป & ผู้เล่น", Icon = "map-pin" }),
    Settings = GroupTools:Tab({ Title = "ตั้งค่า", Icon = "settings" })
}

-- ========================================================================
-- 1. TAB: OVERVIEW (แดชบอร์ดสรุปสถานะ Analytics & เมนูควบคุมด่วน)
-- ========================================================================
ActiveMetric = Tabs.Home:Paragraph({
    Title = "สถานะ: กำลังตรวจสอบ...",
    Desc = "สรุประบบที่กำลังทำงานอยู่"
})

Tabs.Home:Paragraph({
    Title = "Live Empire Analytics",
    Desc = "สรุปภาพรวมสถานะและข้อมูลสำคัญของรังมดแบบเรียลไทม์"
})

local GoldMetric = Tabs.Home:Paragraph({
    Title = "Total Gold: คำนวณ...",
    Desc = "เหรียญทองปัจจุบันในกระเป๋าของคุณ"
})

local FoodMetric = Tabs.Home:Paragraph({
    Title = "Nest & Held Food: คำนวณ...",
    Desc = "อาหารที่สะสมในรัง & อาหารที่กำลังถืออยู่"
})

local MarketMetric = Tabs.Home:Paragraph({
    Title = "Shop Multiplier: คำนวณ...",
    Desc = "เรตตัวคูณราคาขายอาหารที่ร้านค้าในขณะนี้"
})

Tabs.Home:Divider()

Tabs.Home:Paragraph({
    Title = "Quick Actions",
    Desc = "เปิดการทำงานหลักหรือสั่งขายทันทีในคลิกเดียว"
})

regToggle(Tabs.Home, "Home", "MasterAutoFarm", {
    Title = "เปิดฟาร์มทุกอย่างพร้อมกัน",
    Desc = "เปิด Auto Roll + Auto Buy + Auto Collect + Auto Sell ครบวงจรในคลิกเดียว",
    Value = Flags.MasterAutoFarm,
    Callback = function(v)
        Flags.MasterAutoFarm = v
        for _, f in ipairs({ "AutoRollAnt", "AutoBuyAnt", "AutoBuyStar", "AutoCollect", "AutoSell" }) do
            setFlagUI(f, v)
        end
        WindUI:Notify({
            Title = "Master Farm",
            Content = v and "เริ่มระบบฟาร์มครบวงจรแล้ว" or "หยุดระบบฟาร์มแล้ว",
            Duration = 2.5
        })
    end
})

Tabs.Home:Button({
    Title = "หยุดทุกระบบทันที",
    Desc = "ปิดระบบอัตโนมัติทั้งหมดในครั้งเดียว (ไม่แตะการตั้งค่าและวาร์ป)",
    Callback = function()
        stopAllAutomation()
        refreshActiveMetric()
        WindUI:Notify({ Title = "หยุดทุกระบบ", Content = "ปิดระบบอัตโนมัติทั้งหมดแล้ว", Duration = 2.5 })
    end
})

Tabs.Home:Button({
    Title = "กดขายอาหารทั้งหมดทันที",
    Callback = function()
        pcall(function()
            local foodCarry = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellCarryState)
            local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)
            local carriedFood = tonumber(LocalPlayer:GetAttribute("CarriedSellFoodAmount")) or 0
            local food = 0
            pcall(function()
                food = PlayerDataHelper.GetPlayerFood(LocalPlayer.UserId) or 0
            end)
            if food <= 0 then food = carriedFood end
            if food <= 0 then
                local snap = foodCarry.GetSnapshot()
                food = (snap and tonumber(snap.FoodAmount)) or 0
            end

            if food > 0 or foodCarry.HasSnapshot() or carriedFood > 0 then
                local sellAmt = math.max(food, 1)
                if not foodCarry.HasSnapshot() then
                    local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex") or 1
                    foodCarry.SetSnapshot({
                        Source = "PlayerFoodPrompt",
                        FoodAmount = sellAmt,
                        RoomIndex = myRoomIdx
                    })
                end

                pcall(function()
                    foodCarry.RequestSell({
                        SendCommand = function(cmd, payload)
                            payload = payload or {}
                            payload.FoodAmount = payload.FoodAmount or sellAmt
                            payload.Source = "PlayerFoodSellPrompt"
                            payload.UserId = LocalPlayer.UserId
                            sendEcsCommand(cmd, payload)
                        end
                    }, { Source = "PlayerFoodSellPrompt" })
                end)

                WindUI:Notify({
                    Title = "Quick Sell",
                    Content = "ส่งคำสั่งขายอาหารจำนวน " .. tostring(sellAmt) .. " หน่วยแล้ว",
                    Duration = 2.5
                })
            else
                WindUI:Notify({
                    Title = "Quick Sell",
                    Content = "ไม่มีอาหารในรังหรือในมือให้ขายในขณะนี้",
                    Duration = 2.5
                })
            end
        end)
    end
})

Tabs.Home:Button({
    Title = "กดสุ่มมดทันที 1 ครั้ง",
    Callback = function()
        sendEcsCommand("RollAnt", { Source = "ProximityPrompt" })
    end
})

-- ลูปอัปเดตสถิติเรียลไทม์แบบ Dashboard
task.spawn(function()
    while true do
        pcall(function()
            local currentGold = getPlayerGold()
            local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)
            local foodInNest = PlayerDataHelper.GetPlayerFood(LocalPlayer.UserId) or 0
            
            local foodCarry = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellCarryState)
            local snap = foodCarry.GetSnapshot()
            local heldFood = (snap and snap.FoodAmount) or 0
            
            local mul = getCurrentFoodMultiplier()
            local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex") or 1
            local farmStatus = Flags.MasterAutoFarm and "Farming Active" or "Standby"
            refreshActiveMetric()

            updateParagraph(GoldMetric,
                string.format("Gold: %s | Room: #%s", tostring(currentGold), tostring(myRoomIdx)),
                string.format("สถานะระบบ: %s • Anti-AFK: %s", farmStatus, Flags.AntiAFK and "เปิด" or "ปิด")
            )

            updateParagraph(FoodMetric,
                string.format("Nest Food: %s | Carried: %s", tostring(foodInNest), tostring(heldFood)),
                "พร้อมขายได้ทันทีเมื่อเปิดใช้งานระบบ Auto Sell Food"
            )

            local mulText = string.format("%.2fX", mul)
            local trend = mul >= 1.5 and "(เรตสูง คุ้มค่าแก่การขาย)" or "(เรตปกติ)"
            local targetInfo = Flags.SellAtMultiplier and string.format(" | เป้าหมาย: %.2fX", Flags.Multiplier) or " | ขายทันทีทุกเรต"
            updateParagraph(MarketMetric,
                string.format("Current Sell Multiplier: %s %s%s", mulText, trend, targetInfo),
                "ราคาจะรีเฟรชอย่างต่อเนื่องตามกลไกตลาดของเกม"
            )

            if MultiplierLiveStatus then
                if Flags.SellAtMultiplier then
                    if mul >= Flags.Multiplier then
                        updateParagraph(MultiplierLiveStatus,
                            string.format("ตัวคูณตลาด: %.2fX >= เป้าหมาย: %.2fX (กำลังเก็บและขาย)", mul, Flags.Multiplier),
                            "ตัวคูณถึงเป้าหมายที่ตั้งไว้แล้ว ระบบจะดูดอาหารจากรังและขายทันที"
                        )
                    else
                        updateParagraph(MultiplierLiveStatus,
                            string.format("ตัวคูณตลาด: %.2fX < เป้าหมาย: %.2fX (กำลังสะสมอาหารในรัง)", mul, Flags.Multiplier),
                            "อาหารกำลังสะสมอย่างปลอดภัยในรัง จะไม่ดูดเข้าตัวจนกว่าตัวคูณจะถึงเป้าหมาย"
                        )
                    end
                else
                    updateParagraph(MultiplierLiveStatus,
                        string.format("ตัวคูณตลาด: %.2fX (โหมดขายทันที ไม่รอตัวคูณ)", mul),
                        "ระบบจะดูดอาหารและขายทันทีตลอดเวลาโดยไม่จำกัดเรตตัวคูณ"
                    )
                end
            end
        end)
        task.wait(1.2)
    end
end)

-- ========================================================================
-- 2. TAB: AUTO ROLL (ระบบสุ่มมด & ฟิลเตอร์กรองมด)
-- ========================================================================
Tabs.Roll:Paragraph({
    Title = "ระบบสุ่มมด",
    Desc = "ตั้งค่าการสุ่มมดอย่างต่อเนื่องและตัวเลือกข้ามอนิเมชั่น"
})

regToggle(Tabs.Roll, "Roll", "AutoRollAnt", {
    Title = "สุ่มมดอัตโนมัติ",
    Desc = "กดสุ่มมดที่แท่นสุ่มให้อัตโนมัติอย่างต่อเนื่อง",
    Value = Flags.AutoRollAnt,
    Callback = function(v) Flags.AutoRollAnt = v end
})

Tabs.Roll:Toggle({
    Title = "ข้ามอนิเมชั่นโชค",
    Desc = "ปิดเอฟเฟกต์ไข่เด้งและแสง เพื่อให้สุ่มได้เร็วขึ้นและไม่แล็ก",
    Value = Flags.DisableCloverEffect,
    Callback = function(v)
        Flags.DisableCloverEffect = v
        applyCloverEffectSetting()
    end
})

Tabs.Roll:Divider()

Tabs.Roll:Paragraph({
    Title = "ซื้อและเคลมมด / ดาว",
    Desc = "ระบบซื้อและเคลมมดที่สุ่มได้ตามเกณฑ์ที่เลือกอย่างปลอดภัย"
})

regToggle(Tabs.Roll, "Roll", "AutoBuyAnt", {
    Title = "ซื้อมดที่สุ่มได้ตามฟิลเตอร์",
    Desc = "ซื้อเฉพาะมดที่ตรงตามเกณฑ์ Rarity และ Mutation ที่เลือกไว้ด้านล่าง (จะไม่กดซ้ำถ้าเงินไม่พอ)",
    Value = Flags.AutoBuyAnt,
    Callback = function(v) Flags.AutoBuyAnt = v end
})

regToggle(Tabs.Roll, "Roll", "AutoBuyStar", {
    Title = "ซื้อดาวสุ่มมดฟรี",
    Desc = "เก็บดาวสุ่มมดอัตโนมัติทันทีเมื่อสุ่มได้",
    Value = Flags.AutoBuyStar,
    Callback = function(v) Flags.AutoBuyStar = v end
})

regToggle(Tabs.Roll, "Roll", "SkipIfNotEnoughGold", {
    Title = "ถ้าเงินไม่พอให้สุ่มข้ามทันที",
    Desc = "หากเงินไม่พอซื้อมดที่สุ่มได้ ให้กดสุ่มตัวใหม่เพื่อข้ามทันทีโดยไม่ต้องรอ",
    Value = Flags.SkipIfNotEnoughGold,
    Callback = function(v) Flags.SkipIfNotEnoughGold = v end
})

Tabs.Roll:Divider()

Tabs.Roll:Paragraph({
    Title = "ฟิลเตอร์กรองระดับและบัพมด",
    Desc = "เลือกเฉพาะระดับมดและบัพที่คุณต้องการซื้อ ระบบจะไม่ซื้อมดที่ไม่ตรงเงื่อนไข"
})

Tabs.Roll:Dropdown({
    Title = "เลือกระดับมดที่ต้องการซื้อ",
    Values = RarityList,
    Value = Flags.BuyRarities,
    Multi = true,
    Callback = function(selected)
        Flags.BuyRarities = selected
    end
})

Tabs.Roll:Dropdown({
    Title = "เลือกบัพ Mutation ที่ต้องการซื้อ",
    Values = MutationList,
    Value = Flags.BuyMutations,
    Multi = true,
    Callback = function(selected)
        Flags.BuyMutations = selected
    end
})

-- ========================================================================
-- 3. TAB: FOOD & FARM (อาหาร & การขาย)
-- ========================================================================
Tabs.Farm:Paragraph({
    Title = "เก็บอาหาร",
    Desc = "ระบบเก็บอาหารในรังเข้าตัวผู้เล่น"
})

regToggle(Tabs.Farm, "Farm", "AutoCollect", {
    Title = "เก็บอาหารในรังอัตโนมัติ",
    Desc = "ดูดอาหารเข้าตัว (หากเปิด 'Sell At Multiplier' จะรอจนกว่าตัวคูณถึงเป้าก่อนจึงเริ่มเก็บ)",
    Value = Flags.AutoCollect,
    Callback = function(v) Flags.AutoCollect = v end
})

Tabs.Farm:Divider()

Tabs.Farm:Paragraph({
    Title = "ระบบขายอาหาร",
    Desc = "ระบบขายอาหารอัตโนมัติตามเรตตัวคูณราคาของตลาดอย่างแม่นยำ"
})

regToggle(Tabs.Farm, "Farm", "AutoSell", {
    Title = "ขายอาหารอัตโนมัติ",
    Desc = "ขายอาหารที่ถืออยู่หรือในรังเพื่อรับเหรียญทอง",
    Value = Flags.AutoSell,
    Callback = function(v) Flags.AutoSell = v end
})

regToggle(Tabs.Farm, "Farm", "SellAtMultiplier", {
    Title = "รอเก็บและขายเมื่อได้ตัวคูณที่กำหนด",
    Desc = "หากเปิด: อาหารจะสะสมอยู่ในรัง และจะเริ่มเก็บ+ขายเมื่อตัวคูณถึงเป้าหมายเท่านั้น",
    Value = Flags.SellAtMultiplier,
    Callback = function(v) Flags.SellAtMultiplier = v end
})

Tabs.Farm:Slider({
    Title = "ตัวคูณเป้าหมาย",
    Step = 0.05,
    Value = { Min = 1.0, Max = 2.5, Default = 1.80 },
    Callback = function(val)
        Flags.Multiplier = tonumber(string.format("%.2f", val))
    end
})

MultiplierLiveStatus = Tabs.Farm:Paragraph({
    Title = "Multiplier Status: กำลังโหลด...",
    Desc = "ตรวจสอบสถานะตัวคูณราคาของร้านค้าแบบเรียลไทม์"
})

regToggle(Tabs.Farm, "Farm", "AutoSellToFoodBuyer", {
    Title = "ขายให้พ่อค้าอาหาร Black Market",
    Desc = "ส่งอาหารขายให้กับพ่อค้าพิเศษอัตโนมัติเมื่อมีอีเวนต์",
    Value = Flags.AutoSellToFoodBuyer,
    Callback = function(v) Flags.AutoSellToFoodBuyer = v end
})

-- ========================================================================
-- 4. TAB: ANTS & UPGRADES (ระบบมด & อัปเกรดรัง)
-- ========================================================================
Tabs.Ants:Paragraph({
    Title = "จัดการฝูงมด",
    Desc = "ระบบจัดการมดและขยายช่องในรังเมื่อเงินเพียงพอ"
})

regToggle(Tabs.Ants, "Ants", "AutoEquipBest", {
    Title = "ใส่มดที่ดีที่สุดอัตโนมัติ",
    Desc = "ตรวจเช็คและสวมใส่มดที่มีสเตตัสสูงที่สุดให้คุณตลอดเวลา",
    Value = Flags.AutoEquipBest,
    Callback = function(v) Flags.AutoEquipBest = v end
})

regToggle(Tabs.Ants, "Ants", "AutoUpgradeEquippedAnts", {
    Title = "อัปเกรดมดที่ใส่อยู่",
    Desc = "อัปเกรดเลเวลมดที่อยู่ในรังทุกตัวเพื่อเพิ่มพลังผลิต (จะกดต่อเมื่อมีเงินพอเท่านั้น)",
    Value = Flags.AutoUpgradeEquippedAnts,
    Callback = function(v) Flags.AutoUpgradeEquippedAnts = v end
})

regToggle(Tabs.Ants, "Ants", "AutoUnlockAntHole", {
    Title = "ปลดล็อคช่องมดอัตโนมัติ",
    Desc = "ซื้อขยายช่องวางมดเพิ่มเมื่อเงินของคุณเพียงพอ (จะไม่กดซ้ำถ้าเงินไม่พอ)",
    Value = Flags.AutoUnlockAntHole,
    Callback = function(v) Flags.AutoUnlockAntHole = v end
})

regToggle(Tabs.Ants, "Ants", "AutoPlaceAnt", {
    Title = "วางมดลงรังอัตโนมัติ",
    Desc = "นำมดที่ได้ใหม่มาจัดวางลงในรังทันที",
    Value = Flags.AutoPlaceAnt,
    Callback = function(v) Flags.AutoPlaceAnt = v end
})

regToggle(Tabs.Ants, "Ants", "AutoStrokePets", {
    Title = "ลูบตัวมดรับรางวัล",
    Desc = "ลูบตัวมดที่สวมใส่อยู่อัตโนมัติเพื่อรับค่าความผูกพันและบัฟ",
    Value = Flags.AutoStrokePets,
    Callback = function(v) Flags.AutoStrokePets = v end
})

regToggle(Tabs.Ants, "Ants", "HideAnts", {
    Title = "ซ่อนตัวมดเพื่อลดแล็ก",
    Desc = "ซ่อนโมเดลมดในรังและในแมพ ช่วยเพิ่มความลื่นไหลของเกมอย่างเห็นได้ชัด",
    Value = Flags.HideAnts,
    Callback = function(v) Flags.HideAnts = v end
})

Tabs.Ants:Divider()

Tabs.Ants:Paragraph({
    Title = "ระบบเร่งสปีดมด",
    Desc = "เพิ่มความเร็วการทำงานและการเดินของมดในรัง"
})

regToggle(Tabs.Ants, "Ants", "AutoAntSpeedPotion", {
    Title = "กดใช้น้ำยาเร่งสปีดมดอัตโนมัติ",
    Desc = "เปิดใช้งานน้ำยาเร่งสปีดความเร็วให้กับมดทุกตัวในช่องสวมใส่",
    Value = Flags.AutoAntSpeedPotion,
    Callback = function(v) Flags.AutoAntSpeedPotion = v end
})

Tabs.Ants:Button({
    Title = "กดใช้น้ำยาสปีดมดทุกตัวทันที",
    Callback = function()
        pcall(function()
            local EventBus = require(ReplicatedStorage.Packages.EventBus)
            for slot = 1, 30 do
                EventBus.FireServer("SetAutoUsePotion", {
                    RequestId = HttpService:GenerateGUID(false),
                    SlotIndex = slot,
                    AutoUsePotion = true
                })
            end
            WindUI:Notify({
                Title = "Speed Potion",
                Content = "ส่งคำสั่งใช้น้ำยาเร่งสปีดให้มดทุกช่องแล้ว",
                Duration = 2.5
            })
        end)
    end
})

Tabs.Ants:Slider({
    Title = "เร่งสปีดอนิเมชั่นมดในรัง",
    Step = 0.2,
    Value = { Min = 1.0, Max = 5.0, Default = 1.0 },
    Callback = function(val)
        Flags.AntAnimationSpeed = tonumber(val) or 1.0
    end
})

Tabs.Ants:Divider()

Tabs.Ants:Paragraph({
    Title = "อัปเกรดฐานและสเตตัส",
    Desc = "ซื้ออัปเกรดสเตตัสฐานอัตโนมัติเมื่อเงินเพียงพอ (จะไม่กดซ้ำถ้าเงินไม่พอ)"
})

Tabs.Ants:Slider({
    Title = "ระยะห่างการอัปเกรดอัตโนมัติ (วินาที)",
    Desc = "ยิ่งค่ามาก ยิ่งกดซื้อช้าลง ใช้กับทั้งอัปเกรดมดที่ใส่อยู่และอัปเกรดฐาน",
    Step = 0.5,
    Value = { Min = 1, Max = 30, Default = math.clamp(tonumber(Flags.UpgradeInterval) or 3, 1, 30) },
    Callback = function(val)
        Flags.UpgradeInterval = tonumber(val) or 3
    end
})

Tabs.Ants:Button({
    Title = "ตรวจสอบราคาอัปเกรด",
    Desc = "แสดงเลเวล ราคา และสถานะของอัปเกรดที่เลือกไว้ (ใช้เช็คว่าทำไมไม่ซื้อ)",
    Callback = function()
        local lines = { "เงินปัจจุบัน: " .. tostring(getPlayerGold()) }
        for _, uiName in ipairs(Flags.SelectedUpgrades or {}) do
            local attr = UpgradeMapping[uiName]
            if attr then
                local lvl, cost, state = getUpgradeInfo(attr)
                local detail = state == "ok" and ("ราคา " .. tostring(cost))
                    or state == "maxed" and "เลเวลเต็มแล้ว"
                    or state == "nocfg" and "ไม่พบข้อมูลราคาในเกม"
                    or "อ่านราคาไม่ได้"
                table.insert(lines, string.format("%s: Lv.%s • %s", uiName:match("^[^%(]+") or uiName, tostring(lvl), detail))
            end
        end
        WindUI:Notify({ Title = "สถานะอัปเกรด", Content = table.concat(lines, "\n"), Duration = 10 })
    end
})

regToggle(Tabs.Ants, "Ants", "AutoBuyUpgrades", {
    Title = "ซื้ออัปเกรดอัตโนมัติ",
    Desc = "ซื้ออัปเกรดตามรายการที่เลือกไว้ด้านล่าง (ซื้อเฉพาะเมื่อมีเงินพอ)",
    Value = Flags.AutoBuyUpgrades,
    Callback = function(v) Flags.AutoBuyUpgrades = v end
})

Tabs.Ants:Dropdown({
    Title = "เลือกสิ่งที่ต้องการอัปเกรด",
    Values = {
        "Nest Layer (เพิ่มชั้นรัง)",
        "Ant Speed (ความเร็วมด)",
        "Ant Atk (พลังโจมตี)",
        "Queen Level (เลเวลนางพญา)",
        "Luck (ค่าโชคสุ่มมด)",
        "Single Roll Count (จำนวนสุ่ม)"
    },
    Value = { "Nest Layer (เพิ่มชั้นรัง)", "Ant Speed (ความเร็วมด)", "Ant Atk (พลังโจมตี)" },
    Multi = true,
    Callback = function(selected)
        Flags.SelectedUpgrades = selected
    end
})

-- ========================================================================
-- 5. TAB: DUNGEON (ระบบลงดันเจี้ยน & บอส)
-- ========================================================================
Tabs.Dungeon:Paragraph({
    Title = "ควบคุมด่วน",
    Desc = "กดครั้งเดียวเปิดหรือปิดระบบดันเจี้ยนทั้งชุด (สวิตช์ด้านล่างจะเปลี่ยนตามให้อัตโนมัติ)"
})

Tabs.Dungeon:Button({
    Title = "เริ่มระบบดันทั้งหมด",
    Desc = "เปิด ลงดัน + ดันดาว + กดปุ่ม Start + เร่งโจมตี 4x",
    Callback = function()
        setFlagUI("AutoDungeon", true)
        setFlagUI("AutoStarDungeon", true)
        setFlagUI("AutoPressDungeonStart", true)
        setFlagUI("Auto4xAttackSpeed", true)
        WindUI:Notify({ Title = "ดันเจี้ยน", Content = "เริ่มระบบดันทั้งหมดแล้ว", Duration = 2.5 })
    end
})

Tabs.Dungeon:Button({
    Title = "หยุดระบบดันทั้งหมด",
    Callback = function()
        setFlagUI("AutoDungeon", false)
        setFlagUI("AutoStarDungeon", false)
        setFlagUI("AutoPressDungeonStart", false)
        setFlagUI("Auto4xAttackSpeed", false)
        WindUI:Notify({ Title = "ดันเจี้ยน", Content = "หยุดระบบดันทั้งหมดแล้ว", Duration = 2.5 })
    end
})

Tabs.Dungeon:Divider()

Tabs.Dungeon:Paragraph({
    Title = "ระบบลงดันเจี้ยนอัตโนมัติ",
    Desc = "ลงดันเจี้ยนและเร่งความเร็วการโจมตีอัตโนมัติ"
})

regToggle(Tabs.Dungeon, "Dungeon", "AutoDungeon", {
    Title = "ลงดันเจี้ยนอัตโนมัติ",
    Desc = "เดินเข้าดันเจี้ยนอัตโนมัติและเริ่มการต่อสู้อย่างต่อเนื่อง",
    Value = Flags.AutoDungeon,
    Callback = function(v) Flags.AutoDungeon = v end
})

regToggle(Tabs.Dungeon, "Dungeon", "AutoStarDungeon", {
    Title = "ส่งดาวและเข้าดันดาวอัตโนมัติ",
    Desc = "ถือดาวไปส่งที่จุด StarEvent และเข้าดันเจี้ยนดาวให้เอง",
    Value = Flags.AutoStarDungeon,
    Callback = function(v) Flags.AutoStarDungeon = v end
})

regToggle(Tabs.Dungeon, "Dungeon", "AutoPressDungeonStart", {
    Title = "กดปุ่ม Start ตอนเข้าดันอัตโนมัติ",
    Desc = "หลังเข้าดันเจี้ยน จะหาและกดปุ่ม Start/เริ่ม บนหน้าจอให้เอง",
    Value = Flags.AutoPressDungeonStart,
    Callback = function(v) Flags.AutoPressDungeonStart = v end
})

regToggle(Tabs.Dungeon, "Dungeon", "Auto4xAttackSpeed", {
    Title = "เร่งความเร็วโจมตี 4X อัตโนมัติ",
    Desc = "รัวคลิกโจมตีในดันเจี้ยนเพื่อรักษาระดับบัพ ClickBoost 4X สูงสุดตลอดเวลา",
    Value = Flags.Auto4xAttackSpeed,
    Callback = function(v) Flags.Auto4xAttackSpeed = v end
})

-- ========================================================================
-- 6. TAB: EVENTS (ระบบอีเวนต์พิเศษ)
-- ========================================================================
Tabs.Events:Paragraph({
    Title = "ระบบเก็บของอีเวนต์",
    Desc = "เก็บเหรียญอีเวนต์สตอเบอรี่ กดรับรางวัลหอยทากสัญจร และเคลมรางวัลสมุดภาพ"
})

regToggle(Tabs.Events, "Events", "AutoPickupStrawberryCoins", {
    Title = "เก็บเหรียญสตรอว์เบอร์รี่อัตโนมัติ",
    Desc = "เก็บเหรียญสตรอว์เบอร์รี่ที่เกิดตามจุดต่างๆ ในแมพอัตโนมัติ",
    Value = Flags.AutoPickupStrawberryCoins,
    Callback = function(v) Flags.AutoPickupStrawberryCoins = v end
})

Tabs.Events:Slider({
    Title = "ความหน่วงในการเก็บเหรียญ",
    Step = 0.05,
    Value = { Min = 0.05, Max = 1.00, Default = 0.10 },
    Callback = function(val)
        Flags.CoinPickupDelay = tonumber(string.format("%.2f", val)) or 0.10
    end
})

Tabs.Events:Divider()

Tabs.Events:Paragraph({
    Title = "กิจกรรมพิเศษ",
    Desc = "กดรับรางวัลจากหอยทากสัญจรและเคลมรางวัลสมุดภาพ"
})

regToggle(Tabs.Events, "Events", "AutoClickTravellingSnail", {
    Title = "กดรับรางวัลหอยทากสัญจร",
    Desc = "กดรับรางวัลจากหอยทากสัญจร (Travelling Snail) อัตโนมัติเมื่อตัวหอยเปิด",
    Value = Flags.AutoClickTravellingSnail,
    Callback = function(v) Flags.AutoClickTravellingSnail = v end
})

regToggle(Tabs.Events, "Events", "AutoStarfallEvent", {
    Title = "เข้าร่วมอีเวนต์ฝนดาวตก",
    Desc = "เข้าร่วมอีเวนต์ Starfall อัตโนมัติเมื่อเริ่มกิจกรรม",
    Value = Flags.AutoStarfallEvent,
    Callback = function(v) Flags.AutoStarfallEvent = v end
})

regToggle(Tabs.Events, "Events", "AutoClaimIndex", {
    Title = "รับรางวัลสมุดภาพดัชนีอัตโนมัติ",
    Desc = "กดรับรางวัลจากการค้นพบมดและการกลายพันธุ์ใหม่ในสมุดภาพ Index ให้อัตโนมัติ",
    Value = Flags.AutoClaimIndex,
    Callback = function(v) Flags.AutoClaimIndex = v end
})

-- ========================================================================
-- 7. TAB: CONVERTER & SHOP (เครื่องย่อยปุ๋ย & ร้านค้า)
-- ========================================================================
Tabs.Shop:Paragraph({
    Title = "เครื่องแปลงทรัพยากร",
    Desc = "ย่อยมดที่ไม่ใช้เพื่อรับทรัพยากรปุ๋ยและของอัปเกรด"
})

regToggle(Tabs.Shop, "Shop", "AutoResourceConverter", {
    Title = "ย่อยมดทำปุ๋ยอัตโนมัติ",
    Desc = "ดึงมดระดับที่เลือกเข้าเครื่องย่อยและดึงคันโยกอัตโนมัติ",
    Value = Flags.AutoResourceConverter,
    Callback = function(v) Flags.AutoResourceConverter = v end
})

Tabs.Shop:Dropdown({
    Title = "เลือกระดับมดที่จะย่อย",
    Values = { "None", "Common", "Uncommon", "Rare", "Epic", "Legendary" },
    Value = Flags.ConverterAnts,
    Callback = function(v) Flags.ConverterAnts = v end
})

Tabs.Shop:Slider({
    Title = "จำนวนที่เก็บไว้ไม่ย่อย",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 15 },
    Callback = function(v) Flags.KeepPerStack = v end
})

Tabs.Shop:Divider()

Tabs.Shop:Paragraph({
    Title = "ซื้ออาหารดำ",
    Desc = "ซื้ออาหารจากร้านค้า Black Market อัตโนมัติ"
})

regToggle(Tabs.Shop, "Shop", "AutoBuyFood", {
    Title = "ซื้ออาหารอัตโนมัติ",
    Desc = "ซื้ออาหารประเภทที่เลือกจากร้านค้าดำอัตโนมัติเมื่อมีขาย",
    Value = Flags.AutoBuyFood,
    Callback = function(v) Flags.AutoBuyFood = v end
})

Tabs.Shop:Dropdown({
    Title = "เลือกชนิดอาหาร",
    Values = { "None", "Strawberry", "Watermelon", "Cake", "Diamond Candy" },
    Value = Flags.SelectedFood,
    Callback = function(v) Flags.SelectedFood = v end
})

-- ========================================================================
-- 8. TAB: PLAYER & TELEPORTS (การเคลื่อนที่ & วาร์ป)
-- ========================================================================
Tabs.Teleport:Paragraph({
    Title = "การเคลื่อนที่ผู้เล่น",
    Desc = "ปรับแต่งความเร็วและพลังกระโดดของตัวละคร"
})

Tabs.Teleport:Slider({
    Title = "ความเร็วเดิน",
    Step = 2,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(v)
        Flags.WalkSpeed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

Tabs.Teleport:Slider({
    Title = "พลังกระโดด",
    Step = 5,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v)
        Flags.JumpPower = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end
})

regToggle(Tabs.Teleport, "Teleport", "InfiniteJump", {
    Title = "กระโดดลอยฟ้าไม่จำกัด",
    Desc = "กด Spacebar เพื่อกระโดดกลางอากาศได้ต่อเนื่อง",
    Value = Flags.InfiniteJump,
    Callback = function(v) Flags.InfiniteJump = v end
})

regToggle(Tabs.Teleport, "Teleport", "Noclip", {
    Title = "เดินทะลุกำแพง",
    Desc = "เดินผ่านสิ่งกีดขวางและผนังได้ทุกชนิด",
    Value = Flags.Noclip,
    Callback = function(v) Flags.Noclip = v end
})

Tabs.Teleport:Divider()

Tabs.Teleport:Paragraph({
    Title = "จุดวาร์ปในเกม",
    Desc = "วาร์ปไปยังตำแหน่งสำคัญต่างๆ ในแผนที่ได้ทันที"
})

Tabs.Teleport:Button({
    Title = "วาร์ปกลับห้องรังของฉัน",
    Callback = function()
        local myRoom = getMyRoom()
        if myRoom then
            local targetPart = myRoom:FindFirstChild("Spawn") or myRoom:FindFirstChild("Floor") or myRoom:FindFirstChild("PlayerFood")
            if targetPart then
                local cf = targetPart:IsA("Model") and targetPart:GetPivot() or targetPart.CFrame
                teleportTo(cf)
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "วาร์ปไปแท่นสุ่มมด",
    Callback = function()
        local rollPad = Workspace:FindFirstChild("RollPad", true) or Workspace:FindFirstChild("RollMachine", true)
        if rollPad then
            local cf = rollPad:IsA("Model") and rollPad:GetPivot() or rollPad.CFrame
            teleportTo(cf)
        else
            teleportTo(CFrame.new(0, 10, 0))
        end
    end
})

Tabs.Teleport:Button({
    Title = "วาร์ปไปร้านขายอาหาร",
    Callback = function()
        local myRoom = getMyRoom()
        local playerFood = myRoom and myRoom:FindFirstChild("PlayerFood")
        local sellPrompt = playerFood and playerFood:FindFirstChild("SellPrompt")
        if sellPrompt then
            teleportTo(sellPrompt.CFrame)
        else
            teleportTo(CFrame.new(20, 10, 20))
        end
    end
})

Tabs.Teleport:Button({
    Title = "วาร์ปไปตลาดมืด",
    Callback = function()
        local bm = Workspace:FindFirstChild("BlackMarket", true) or Workspace:FindFirstChild("FoodBuyer", true)
        if bm then
            local cf = bm:IsA("Model") and bm:GetPivot() or bm.CFrame
            teleportTo(cf)
        end
    end
})

Tabs.Teleport:Button({
    Title = "วาร์ปไปทางเข้าดันเจี้ยน",
    Callback = function()
        local dFolder = Workspace:FindFirstChild("DungeonEntrances")
        if dFolder and #dFolder:GetChildren() > 0 then
            local ent = dFolder:GetChildren()[1]
            local cf = ent:IsA("Model") and ent:GetPivot() or ent.CFrame
            teleportTo(cf)
        end
    end
})

-- ========================================================================
-- 9. TAB: SETTINGS (การตั้งค่า & ประสิทธิภาพ)
-- ========================================================================
Tabs.Settings:Paragraph({
    Title = "ระบบบันทึกการตั้งค่า",
    Desc = "บันทึกและโหลดค่าการตั้งค่าเพื่อไม่ต้องมาเปิดใหม่ทุกครั้ง"
})

Tabs.Settings:Button({
    Title = "บันทึกคอนฟิก",
    Callback = function()
        saveConfig()
    end
})

Tabs.Settings:Button({
    Title = "โหลดคอนฟิก",
    Callback = function()
        loadConfig(false)
    end
})

regToggle(Tabs.Settings, "Settings", "AutoSaveConfig", {
    Title = "บันทึกอัตโนมัติ",
    Desc = "บันทึกการตั้งค่าลงไฟล์โดยอัตโนมัติทุกๆ 30 วินาที",
    Value = Flags.AutoSaveConfig,
    Callback = function(v) Flags.AutoSaveConfig = v end
})

Tabs.Settings:Button({
    Title = "รีเซ็ตค่าเริ่มต้น",
    Callback = function()
        resetConfig()
    end
})

Tabs.Settings:Divider()

Tabs.Settings:Paragraph({
    Title = "ประสิทธิภาพและการแสดงผล",
    Desc = "ปรับแต่งเฟรมเรตและการแสดงผลเพื่อการเปิดบอทที่เสถียรที่สุด"
})

Tabs.Settings:Toggle({
    Title = "ซ่อนหน้าต่าง UI ตอนเริ่ม",
    Desc = "หากเปิด: เมื่อรันสคริปต์ใหม่ หน้าต่าง UI จะปิด/ซ่อนไว้โดยอัตโนมัติ (กดปุ่มลัดเพื่อเรียกดู)",
    Value = Flags.HideUIOnStart,
    Callback = function(v)
        Flags.HideUIOnStart = v
        saveConfig()
    end
})

Tabs.Settings:Toggle({
    Title = "ล็อค 15 FPS โหมด AFK",
    Desc = "จำกัดเฟรมเรตไว้ที่ 15 FPS เพื่อประหยัด CPU/GPU ขณะปล่อยบอทข้ามคืน (ปิดเพื่อคืนค่าปกติ)",
    Value = Flags.LockAFK15FPS,
    Callback = function(v)
        Flags.LockAFK15FPS = v
        if v then
            applyFpsCap(15)
        else
            applyFpsCap(Flags.TargetFPS or 60)
        end
    end
})

Tabs.Settings:Slider({
    Title = "ปรับขีดจำกัด FPS",
    Step = 5,
    Value = { Min = 15, Max = 240, Default = Flags.TargetFPS or 60 },
    Callback = function(val)
        Flags.TargetFPS = val
        if not Flags.LockAFK15FPS then
            applyFpsCap(val)
        end
    end
})

regToggle(Tabs.Settings, "Settings", "AntiAFK", {
    Title = "ป้องกันการหลุดจากการไม่ขยับ",
    Desc = "ป้องกันเกมตัดการเชื่อมต่ออัตโนมัติเมื่อไม่มีการขยับเกิน 20 นาที",
    Value = Flags.AntiAFK,
    Callback = function(v) Flags.AntiAFK = v end
})

Tabs.Settings:Toggle({
    Title = "GPU Saver ประหยัดการ์ดจอ 80%",
    Desc = "ปิดการเรนเดอร์ภาพ 3D ชั่วคราว เหมาะมากเวลาพับหน้าจอปล่อยบอท",
    Value = Flags.BlackScreen,
    Callback = function(v)
        Flags.BlackScreen = v
        pcall(function()
            RunService:Set3dRenderingEnabled(not v)
        end)
    end
})

Tabs.Settings:Toggle({
    Title = "ลดกราฟิกเพิ่มความลื่น",
    Desc = "ปิดอนุภาค เอฟเฟกต์ภาพ เงา และวัสดุสะท้อนชั่วคราว; ปิดสวิตช์เพื่อคืนค่าภาพเดิม",
    Value = Flags.LowGraphics,
    Callback = function(enabled)
        applyLowGraphics(enabled)
    end
})

local originalLightingSettings
local function applyFullbright(enabled)
    if enabled then
        if not originalLightingSettings then
            originalLightingSettings = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient
            }
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    elseif originalLightingSettings then
        for property, value in pairs(originalLightingSettings) do
            Lighting[property] = value
        end
        originalLightingSettings = nil
    end
end

Tabs.Settings:Toggle({
    Title = "สว่างตลอดเวลา มองเห็นในที่มืด",
    Value = Flags.Fullbright,
    Callback = function(v)
        Flags.Fullbright = v
        applyFullbright(v)
    end
})

Tabs.Settings:Divider()

Tabs.Settings:Paragraph({
    Title = "โค้ด & เซิร์ฟเวอร์",
    Desc = "ใส่โค้ดรับรางวัลและจัดการการเชื่อมต่อเซิร์ฟเวอร์"
})

Tabs.Settings:Input({
    Title = "กรอกโค้ดของเกม",
    Placeholder = "ใส่โค้ดที่นี่...",
    Callback = function(val) Flags.EnteredCode = val end
})

Tabs.Settings:Button({
    Title = "กดรับของรางวัล",
    Callback = function()
        if Flags.EnteredCode ~= "" then
            pcall(function()
                local codeService = require(ReplicatedStorage.Packages.CodeService)
                local success, msg = codeService.Redeem(LocalPlayer, Flags.EnteredCode)
                WindUI:Notify({
                    Title = "Redeem Code",
                    Content = msg or (success and "สำเร็จ" or "โค้ดไม่ถูกต้อง"),
                    Duration = 3
                })
            end)
        end
    end
})

Tabs.Settings:Button({
    Title = "เข้าเซิร์ฟเดิมใหม่",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
})

Tabs.Settings:Button({
    Title = "สุ่มย้ายเซิร์ฟเวอร์ใหม่",
    Callback = function()
        pcall(function()
            local serversApi = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId))
            local body = HttpService:JSONDecode(game:HttpGet(serversApi))
            if body and body.data then
                for _, server in ipairs(body.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end
})

-- ========================================================================
-- BACKGROUND WORKERS (ระบบเบื้องหลังการทำงานอัตโนมัติ)
-- ========================================================================

-- Helper ตรวจสอบว่ามีมดตรงตามเงื่อนไข filter และเงินพอ กำลังรอให้เคลมอยู่หรือไม่
local function hasPendingDesiredAnt()
    local myGold = getPlayerGold()
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Name == "ClaimRolledAntPrompt" and prompt.Enabled then
            local info = getPromptAntInfo(prompt)
            if isDesiredAnt(info, myGold) then
                if info.Cost > 0 and myGold < info.Cost and Flags.SkipIfNotEnoughGold then
                    return false
                end
                return true
            end
        end
    end
    return false
end

-- 1. Auto Roll Worker
local lastRollTriggerTime = 0
task.spawn(function()
    while true do
        if Flags.AutoRollAnt then
            pcall(function()
                local now = os.clock()
                if not hasPendingDesiredAnt() then
                    if (now - lastRollTriggerTime) >= 0.4 then
                        lastRollTriggerTime = now
                        sendEcsCommand("RollAnt", { Source = "ProximityPrompt" })
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- 2. Auto Buy & Claim Ant / Star Worker (ระบบตรวจเช็คเงิน, ฟิลเตอร์ระดับและบัพ, ป้องกันการกดย้ำ)
local claimedPrompts = {}

task.spawn(function()
    while true do
        if Flags.AutoBuyAnt or Flags.AutoBuyStar or Flags.AutoStarDungeon then
            pcall(function()
                local myGold = getPlayerGold()
                local now = os.clock()
                
                for p, t in pairs(claimedPrompts) do
                    if (now - t) > 4 then
                        claimedPrompts[p] = nil
                    end
                end

                -- ค้นหา Prompt การเคลมมด
                local promptsToProcess = {}
                pcall(function()
                    local Battle = ReplicatedStorage:FindFirstChild("Battle")
                    if Battle and Battle:FindFirstChild("Game") and Battle.Game:FindFirstChild("Helper") and Battle.Game.Helper:FindFirstChild("RollPresentationHelper") then
                        local rph = require(Battle.Game.Helper.RollPresentationHelper)
                        local mgr = rph.GetManager()
                        if mgr and mgr.ClaimPlatforms then
                            for claimId, platform in pairs(mgr.ClaimPlatforms) do
                                if platform.ClaimPrompt and platform.ClaimPrompt.Enabled then
                                    table.insert(promptsToProcess, platform.ClaimPrompt)
                                end
                            end
                        end
                    end
                end)

                if #promptsToProcess == 0 then
                    for _, p in ipairs(Workspace:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Name == "ClaimRolledAntPrompt" and p.Enabled then
                            table.insert(promptsToProcess, p)
                        end
                    end
                end

                for _, prompt in ipairs(promptsToProcess) do
                    local lastClaim = claimedPrompts[prompt] or 0
                    if (now - lastClaim) >= 1.5 then
                        local antInfo = getPromptAntInfo(prompt)

                        if antInfo.IsItem and (Flags.AutoBuyStar or Flags.AutoStarDungeon) then
                            claimedPrompts[prompt] = now
                            if antInfo.ClaimId then
                                sendEcsCommand("ClaimRolledAnt", { ClaimId = antInfo.ClaimId })
                            end
                            if fireproximityprompt then
                                fireproximityprompt(prompt, 0)
                                fireproximityprompt(prompt)
                            end
                        elseif Flags.AutoBuyAnt and not antInfo.IsItem then
                            local isDesired = isDesiredAnt(antInfo, myGold)

                            if not isDesired then
                                claimedPrompts[prompt] = now
                                if Flags.AutoRollAnt and (now - lastRollTriggerTime) >= 0.6 then
                                    lastRollTriggerTime = now
                                    sendEcsCommand("RollAnt", { Source = "ProximityPrompt" })
                                end
                            elseif antInfo.Cost > 0 and myGold < antInfo.Cost then
                                claimedPrompts[prompt] = now
                                if Flags.SkipIfNotEnoughGold and Flags.AutoRollAnt and (now - lastRollTriggerTime) >= 0.6 then
                                    lastRollTriggerTime = now
                                    sendEcsCommand("RollAnt", { Source = "ProximityPrompt" })
                                end
                            else
                                claimedPrompts[prompt] = now
                                if antInfo.ClaimId then
                                    sendEcsCommand("ClaimRolledAnt", { ClaimId = antInfo.ClaimId })
                                end
                                if fireproximityprompt then
                                    fireproximityprompt(prompt, 0)
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- 3. Auto Collect Food Worker (เก็บอาหารในรังเข้าตัวผู้เล่นเมื่อตัวคูณถึงเป้าหมาย)
task.spawn(function()
    while true do
        if Flags.AutoCollect or Flags.AutoSell then
            pcall(function()
                -- ถ้าเปิดเงื่อนไขตัวคูณ จะยังไม่เก็บอาหารเข้าตัวเด็ดขาดจนกว่าตัวคูณตลาดจะถึงเป้าหมายที่ตั้งไว้
                if Flags.SellAtMultiplier and not isFoodMultiplierMet() then
                    return
                end

                local myRoom = getMyRoom()
                if myRoom and myRoom:FindFirstChild("PlayerFood") then
                    local promptPart = myRoom.PlayerFood:FindFirstChild("Prompt")
                    local prox = promptPart and promptPart:FindFirstChildOfClass("ProximityPrompt")
                    if prox and fireproximityprompt then
                        prox.MaxActivationDistance = 99999
                        prox.RequiresLineOfSight = false
                        prox.HoldDuration = 0
                        fireproximityprompt(prox, 0)
                        fireproximityprompt(prox)
                    end
                end

                local foodCarry = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellCarryState)
                local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)
                local nestFood = 0
                pcall(function()
                    nestFood = PlayerDataHelper.GetPlayerFood(LocalPlayer.UserId) or 0
                end)
                if nestFood <= 0 then
                    pcall(function()
                        local wk = ReplicatedStorage:WaitForChild("WuKong", 2) or ReplicatedStorage:FindFirstChild("WuKong")
                        if wk then
                            local WuKong = require(wk)
                            nestFood = tonumber(WuKong:ExecuteQuery("/货币/食物?属性数量")) or 0
                        end
                    end)
                end

                if nestFood > 0 and not foodCarry.HasSnapshot() then
                    local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex") or 1
                    foodCarry.SetSnapshot({
                        Source = "PlayerFoodPrompt",
                        FoodAmount = nestFood,
                        RoomIndex = myRoomIdx
                    })
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- 4. Auto Sell Worker (ขายอาหารอัตโนมัติ ตรวจสอบตัวคูณอย่างเข้มงวด)
task.spawn(function()
    while true do
        if Flags.AutoSell then
            pcall(function()
                -- ตรวจสอบเงื่อนไขตัวคูณราคาขาย (Multiplier) ก่อนเป็นอันดับแรก
                if Flags.SellAtMultiplier and not isFoodMultiplierMet() then
                    return
                end

                local foodCarry = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellCarryState)
                local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)

                local carriedFood = tonumber(LocalPlayer:GetAttribute("CarriedSellFoodAmount")) or 0
                local snap = foodCarry.GetSnapshot()
                local snapFood = (snap and tonumber(snap.FoodAmount)) or 0
                local nestFood = 0
                pcall(function()
                    nestFood = PlayerDataHelper.GetPlayerFood(LocalPlayer.UserId) or 0
                end)
                if nestFood <= 0 then
                    pcall(function()
                        local wk = ReplicatedStorage:WaitForChild("WuKong", 2) or ReplicatedStorage:FindFirstChild("WuKong")
                        if wk then
                            local WuKong = require(wk)
                            nestFood = tonumber(WuKong:ExecuteQuery("/货币/食物?属性数量")) or 0
                        end
                    end)
                end

                local foodToSell = carriedFood
                if foodToSell <= 0 then foodToSell = snapFood end
                if foodToSell <= 0 then foodToSell = nestFood end

                local hasFood = (foodToSell > 0) or foodCarry.HasSnapshot() or (carriedFood > 0)
                if not hasFood then
                    return
                end

                if foodToSell <= 0 then foodToSell = 1 end

                if not foodCarry.HasSnapshot() then
                    local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex") or 1
                    foodCarry.SetSnapshot({
                        Source = "PlayerFoodPrompt",
                        FoodAmount = foodToSell,
                        RoomIndex = myRoomIdx
                    })
                end

                pcall(function()
                    foodCarry.RequestSell({
                        SendCommand = function(cmd, payload)
                            payload = payload or {}
                            payload.FoodAmount = payload.FoodAmount or foodToSell
                            payload.Source = "PlayerFoodSellPrompt"
                            payload.UserId = LocalPlayer.UserId
                            sendEcsCommand(cmd, payload)
                        end
                    }, { Source = "PlayerFoodSellPrompt" })
                end)
            end)
        end
        task.wait(0.5)
    end
end)

-- 5. Auto Sell To Food Buyer (BlackMarket พ่อค้าอาหารพิเศษ)
task.spawn(function()
    while true do
        if Flags.AutoSellToFoodBuyer then
            pcall(function()
                local PlayerDataHelper = require(ReplicatedStorage.Battle.Game.Helper.PlayerDataHelper)
                local foodInNest = PlayerDataHelper.GetPlayerFood(LocalPlayer.UserId) or 0
                if foodInNest <= 0 then
                    pcall(function()
                        local wk = ReplicatedStorage:WaitForChild("WuKong", 2) or ReplicatedStorage:FindFirstChild("WuKong")
                        if wk then
                            local WuKong = require(wk)
                            local val = WuKong:ExecuteQuery("/货币/食物?属性数量")
                            foodInNest = tonumber(val) or 0
                        end
                    end)
                end

                if foodInNest > 0 then
                    local foodCarry = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.FoodSellCarryState)
                    if not foodCarry.HasSnapshot() then
                        local myRoomIdx = LocalPlayer:GetAttribute("RoomIndex") or 1
                        foodCarry.SetSnapshot({
                            Source = "PlayerFoodPrompt",
                            FoodAmount = foodInNest,
                            RoomIndex = myRoomIdx
                        })
                    end

                    local blackMarket = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.BlackMarket)
                    if blackMarket and blackMarket.RequestSell then
                        blackMarket.RequestSell()
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- 6. Auto Equip Best Worker
task.spawn(function()
    while true do
        if Flags.AutoEquipBest then
            pcall(function()
                local backpackModel = require(ReplicatedStorage.UI.Backpack.Model.BackpackModel)
                if backpackModel and backpackModel.EquipBest then
                    backpackModel:EquipBest()
                end
            end)
        end
        task.wait(3.0)
    end
end)

-- 7. Auto Upgrade Equipped Ants Worker (ระบบตรวจสอบเงินพอจึงกด)
local antUpgradeLastSent = {}
task.spawn(function()
    while true do
        if Flags.AutoUpgradeEquippedAnts then
            pcall(function()
                local remainingGold = getPlayerGold()
                local backpackStore = require(ReplicatedStorage.WuKongHooks.BackPackStore)
                local interval = math.max(tonumber(Flags.UpgradeInterval) or 3, 0.5)
                for slot = 1, 30 do
                    local ok, hasUpgrade, info = pcall(backpackStore.GetEquippedUpgradeInfo, LocalPlayer.UserId, slot)
                    if ok and hasUpgrade and type(info) == "table" then
                        local cost = extractCost(info) or 0
                        local now = os.clock()
                        local lastAt = antUpgradeLastSent[slot]
                        local spaced = (not lastAt or (now - lastAt) >= interval)
                        if cost > 0 then
                            -- รู้ราคา: กดเมื่อเงินพอเท่านั้น ทีละตัว
                            if spaced and remainingGold >= cost then
                                antUpgradeLastSent[slot] = now
                                sendEcsCommand("UpgradeEquippedAnt", { AntIndex = slot })
                                break
                            end
                        elseif spaced and probeAllowed("ant:" .. slot, remainingGold, tonumber(info.Level or info.Lv) or 0, interval) then
                            -- อ่านราคาไม่ได้: ลองกดอย่างระวัง
                            probeMark("ant:" .. slot, remainingGold, tonumber(info.Level or info.Lv) or 0)
                            antUpgradeLastSent[slot] = now
                            sendEcsCommand("UpgradeEquippedAnt", { AntIndex = slot })
                            break
                        end
                    end
                end
            end)
        end
        task.wait(2.5)
    end
end)

-- 8. Auto Place Ant Worker
task.spawn(function()
    while true do
        if Flags.AutoPlaceAnt then
            pcall(function()
                local myRoom = getMyRoom()
                if myRoom then
                    for _, child in ipairs(myRoom:GetChildren()) do
                        if child.Name:match("^Hole%d+$") or child.Name:match("^AntSlot%d+$") then
                            local prompt = child:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and prompt.ActionText:find("Place") and fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2.0)
    end
end)

-- 9. Auto Stroke Pets Worker
task.spawn(function()
    while true do
        if Flags.AutoStrokePets then
            pcall(function()
                local backpackModel = require(ReplicatedStorage.UI.Backpack.Model.BackpackModel)
                local equippedPets = backpackModel:GetData().EquippedPets or {}
                for petKey in pairs(equippedPets) do
                    sendEcsCommand("StrokePet", { PetKey = petKey })
                    task.wait(0.05)
                end
            end)
        end
        task.wait(3.0)
    end
end)

-- 10. Auto Unlock Ant Hole Worker (ระบบตรวจสอบเงินพอจึงกด ไม่กดซ้ำ)
task.spawn(function()
    while true do
        if Flags.AutoUnlockAntHole then
            pcall(function()
                local myGold = getPlayerGold()
                local myRoom = getMyRoom()
                if myRoom then
                    for _, child in ipairs(myRoom:GetChildren()) do
                        local prompt = child:FindFirstChildOfClass("ProximityPrompt") or child:FindFirstChild("ProximityPrompt", true)
                        if prompt and (prompt.ActionText:find("Unlock") or prompt.ObjectText:find("Hole") or prompt.ObjectText:find("Slot")) then
                            local cost = parseFormattedNumber(prompt.ActionText)
                            if cost == 0 or myGold >= cost then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt, 0)
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2.0)
    end
end)

-- 11. Auto Buy Upgrades Worker (กดเมื่อเงินพอ ทีละอย่าง ไม่รัว)
local upgradeLastSent = {} -- [ชื่อสเตตัส] = { lvl = เลเวลตอนกดล่าสุด, t = เวลาที่กด }
task.spawn(function()
    while true do
        if Flags.AutoBuyUpgrades and #Flags.SelectedUpgrades > 0 then
            pcall(function()
                local myGold = getPlayerGold()
                local interval = math.max(tonumber(Flags.UpgradeInterval) or 3, 0.5)
                for _, uiName in ipairs(Flags.SelectedUpgrades) do
                    local internalAttr = UpgradeMapping[uiName]
                    if internalAttr then
                        local lvl, cost, state = getUpgradeInfo(internalAttr)
                        local now = os.clock()
                        if state == "ok" then
                            local last = upgradeLastSent[internalAttr]
                            local sinceLast = last and (now - last.t) or math.huge
                            local canSend = sinceLast >= interval
                            -- กดไปแล้วแต่เลเวลไม่ขึ้น ให้รอนานขึ้นแทนการกดซ้ำ
                            if canSend and last and last.lvl == lvl and sinceLast < interval * 5 then
                                canSend = false
                            end
                            if canSend and myGold >= cost then
                                upgradeLastSent[internalAttr] = { lvl = lvl, t = now }
                                sendEcsCommand("UpgradePlayerAttribute", { AttributeName = internalAttr })
                                break -- ซื้อทีละอย่าง รอบถัดไปค่อยเช็คเงินใหม่
                            end
                        elseif state ~= "maxed" then
                            -- อ่านราคาไม่ได้: ลองกดอย่างระวัง ไม่รัว
                            if probeAllowed("up:" .. internalAttr, myGold, lvl, interval) then
                                probeMark("up:" .. internalAttr, myGold, lvl)
                                sendEcsCommand("UpgradePlayerAttribute", { AttributeName = internalAttr })
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- 12. Hide Ants Worker (ซ่อนตัวมดจริงในรังและแมพ พร้อมคืนค่าเมื่อปิด)
local hiddenAntModels = {}
task.spawn(function()
    while true do
        pcall(function()
            if Flags.HideAnts then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj:GetAttribute("UnitId") ~= nil or obj:GetAttribute("AntIndex") ~= nil or (obj.Parent and obj.Parent.Name == "Unit")) then
                        if not hiddenAntModels[obj] then
                            hiddenAntModels[obj] = true
                        end
                        for _, p in ipairs(obj:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.LocalTransparencyModifier = 1
                            elseif p:IsA("Decal") or p:IsA("Texture") then
                                p.Transparency = 1
                            elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("BillboardGui") then
                                p.Enabled = false
                            end
                        end
                    end
                end
            else
                if next(hiddenAntModels) ~= nil then
                    for model in pairs(hiddenAntModels) do
                        if model and model.Parent then
                            for _, p in ipairs(model:GetDescendants()) do
                                if p:IsA("BasePart") then
                                    p.LocalTransparencyModifier = 0
                                elseif p:IsA("Decal") or p:IsA("Texture") then
                                    p.Transparency = 0
                                elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") or p:IsA("BillboardGui") then
                                    p.Enabled = true
                                end
                            end
                        end
                        hiddenAntModels[model] = nil
                    end
                end
            end
        end)
        task.wait(Flags.HideAnts and 1.0 or 2.0)
    end
end)

-- 13. Ant Speed Worker (กดใช้น้ำยาสปีด & บูสต์อนิเมชั่น)
task.spawn(function()
    while true do
        if Flags.AutoAntSpeedPotion then
            pcall(function()
                local EventBus = require(ReplicatedStorage.Packages.EventBus)
                for slot = 1, 30 do
                    pcall(function()
                        EventBus.FireServer("SetAutoUsePotion", {
                            RequestId = HttpService:GenerateGUID(false),
                            SlotIndex = slot,
                            AutoUsePotion = true
                        })
                    end)
                end
            end)
        end
        task.wait(4.0)
    end
end)

task.spawn(function()
    while true do
        if Flags.AntAnimationSpeed and Flags.AntAnimationSpeed ~= 1.0 then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj:GetAttribute("UnitId") ~= nil or obj:GetAttribute("AntIndex") ~= nil) then
                        local anim = obj:FindFirstChildOfClass("AnimationController") or obj:FindFirstChildOfClass("Humanoid")
                        if anim then
                            local animator = anim:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                    track:AdjustSpeed(Flags.AntAnimationSpeed)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- ตัวช่วยกดปุ่ม Start ใน GUI ของดันเจี้ยน
local GuiService = game:GetService("GuiService")
local DUNGEON_START_TEXTS = { ["start"] = true, ["start dungeon"] = true, ["begin"] = true, ["เริ่ม"] = true, ["เริ่มดัน"] = true, ["เริ่มดันเจี้ยน"] = true }
local lastStartBtnClickAt = 0

local function isGuiReallyVisible(obj)
    local cur = obj
    while cur and cur ~= game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and cur.Enabled == false then return false end
        cur = cur.Parent
    end
    return true
end

local function cleanText(t)
    t = tostring(t or ""):gsub("<[^>]->", "")
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    return t:lower()
end

-- คืน GuiObject ที่ควรกด (ปุ่มที่ครอบข้อความ Start หรือตัวข้อความเอง)
local function findDungeonStartButton()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and DUNGEON_START_TEXTS[cleanText(d.Text)] and isGuiReallyVisible(d) then
            -- หา ImageButton/TextButton ที่ครอบอยู่ ถ้าไม่มีก็ใช้ตัว GuiObject เอง
            local target = d
            local cur = d
            while cur and not cur:IsA("LayerCollector") do
                if cur:IsA("ImageButton") or cur:IsA("TextButton") then target = cur break end
                cur = cur.Parent
            end
            if target.AbsoluteSize.X > 0 and target.AbsoluteSize.Y > 0 then
                return target
            end
        end
    end
    return nil
end

local function clickGuiButton(btn)
    -- 1) ยิง event ของปุ่มโดยตรง (ถ้า executor รองรับ)
    if btn:IsA("GuiButton") then
        if getconnections then
            for _, sig in ipairs({ btn.MouseButton1Click, btn.Activated, btn.MouseButton1Down, btn.MouseButton1Up }) do
                pcall(function()
                    for _, c in ipairs(getconnections(sig)) do
                        pcall(function() c:Fire() end)
                    end
                end)
            end
        elseif firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
    end
    -- 2) จำลองการคลิกเมาส์จริงที่กลางปุ่ม (ครอบคลุมกรณีเกมใช้ InputBegan)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
        local inset = Vector2.new(0, 0)
        local sg = btn:FindFirstAncestorWhichIsA("ScreenGui")
        if not (sg and sg.IgnoreGuiInset) then
            inset = GuiService:GetGuiInset()
        end
        local x = pos.X + size.X / 2 + inset.X
        local y = pos.Y + size.Y / 2 + inset.Y
        vim:SendMouseMoveEvent(x, y, game)
        vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

-- 14. Dungeon Automation & 4x Attack Speed Worker
local lastStarDungeonPromptAt = 0
task.spawn(function()
    while true do
        if Flags.AutoDungeon or Flags.AutoStarDungeon or Flags.Auto4xAttackSpeed then
            pcall(function()
                local sessionId = LocalPlayer:GetAttribute("DungeonSessionId")
                if sessionId then
                    if Flags.Auto4xAttackSpeed or Flags.AutoDungeon or Flags.AutoStarDungeon then
                        for _ = 1, 3 do
                            sendEcsCommand("DungeonCommand", { Action = "Click", SessionId = sessionId })
                            task.wait(0.04)
                        end
                    end
                else
                    if Flags.AutoStarDungeon then
                        local starEvent = Workspace:FindFirstChild("StarEvent")
                        local submitPart = starEvent and starEvent:FindFirstChild("Flippromt")
                        local enterPart = starEvent and starEvent:FindFirstChild("Enterpromt")
                        local submitPrompt = submitPart and (submitPart:IsA("ProximityPrompt") and submitPart or submitPart:FindFirstChildWhichIsA("ProximityPrompt", true))
                        local enterPrompt = enterPart and (enterPart:IsA("ProximityPrompt") and enterPart or enterPart:FindFirstChildWhichIsA("ProximityPrompt", true))
                        local holdingStar = LocalPlayer:GetAttribute("BackpackHeldKind") == "Item"
                            and LocalPlayer:GetAttribute("BackpackHeldItemId") == "Star"
                            and LocalPlayer:GetAttribute("BackpackHeldEntryKey") == "Item:Star"
                        local now = os.clock()

                        if holdingStar and submitPrompt and submitPrompt.Enabled and (now - lastStarDungeonPromptAt) >= 0.5 then
                            lastStarDungeonPromptAt = now
                            local anchor = submitPrompt.Parent
                            if anchor and anchor:IsA("BasePart") then
                                teleportTo(anchor.CFrame)
                            end
                            if fireproximityprompt then
                                fireproximityprompt(submitPrompt, 0)
                            end
                        elseif enterPrompt and enterPrompt.Enabled and (now - lastStarDungeonPromptAt) >= 2.1 then
                            lastStarDungeonPromptAt = now
                            local anchor = enterPrompt.Parent
                            if anchor and anchor:IsA("BasePart") then
                                teleportTo(anchor.CFrame)
                            end
                            if fireproximityprompt then
                                fireproximityprompt(enterPrompt, 0)
                            end
                        end
                    end
                    if Flags.AutoDungeon then
                        local dungeonFolder = Workspace:FindFirstChild("DungeonEntrances")
                        if dungeonFolder then
                            for _, entrance in ipairs(dungeonFolder:GetChildren()) do
                                local prompt = entrance:FindFirstChildOfClass("ProximityPrompt") or entrance:FindFirstChild("ProximityPrompt", true)
                                if prompt and prompt.Enabled and fireproximityprompt then
                                    fireproximityprompt(prompt, 0)
                                    fireproximityprompt(prompt)
                                    break
                                end
                            end
                        end
                    end
                end
                -- กดปุ่ม Start อัตโนมัติ (ทำงานทั้งก่อนและหลังเข้า session ดัน เพราะปุ่มอาจโผล่ตอนอยู่ในดันแล้ว)
                if Flags.AutoPressDungeonStart and (Flags.AutoDungeon or Flags.AutoStarDungeon) then
                    local now2 = os.clock()
                    if (now2 - lastStartBtnClickAt) >= 1 then
                        local obj = findDungeonStartButton()
                        if obj then
                            lastStartBtnClickAt = now2
                            clickGuiButton(obj)
                        end
                    end
                end
            end)
        end
        task.wait(0.15)
    end
end)

-- 15. Travelling Snail Worker (กดรับรางวัลหอยทากสัญจร)
task.spawn(function()
    while true do
        if Flags.AutoClickTravellingSnail then
            pcall(function()
                local wk = ReplicatedStorage:FindFirstChild("WuKong")
                if wk then
                    local WuKong = require(wk)
                    pcall(function()
                        WuKong:ExecuteAction("/功能商人/蜗牛活动抽奖?购买")
                    end)
                end
                
                for _, name in ipairs({ "TravelSnail", "资本蜗牛", "_TravelSnail" }) do
                    local snail = Workspace:FindFirstChild(name)
                    if snail then
                        for _, desc in ipairs(snail:GetDescendants()) do
                            if desc:IsA("ClickDetector") and fireclickdetector then
                                fireclickdetector(desc)
                            elseif desc:IsA("ProximityPrompt") and fireproximityprompt then
                                fireproximityprompt(desc, 0)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.4)
    end
end)

-- 16. Strawberry Coins Worker (เก็บเหรียญสตอเบอรี่ตาม Delay อย่างรวดเร็ว ไม่กระตุก)
task.spawn(function()
    while true do
        if Flags.AutoPickupStrawberryCoins then
            pcall(function()
                local delayTime = tonumber(Flags.CoinPickupDelay) or 0.10
                local coinFolder = Workspace:FindFirstChild("_StrawberryKingActivityCoins")
                if coinFolder then
                    for _, coinModel in ipairs(coinFolder:GetChildren()) do
                        if not Flags.AutoPickupStrawberryCoins then break end
                        local entityId = coinModel:GetAttribute("StrawberryCoinEntityId")
                        if entityId then
                            sendEcsCommand("PickupStrawberryCoin", { CoinEntityId = tonumber(entityId) })
                        end
                        local prompt = coinModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled and fireproximityprompt then
                            fireproximityprompt(prompt, 0)
                            fireproximityprompt(prompt)
                        end
                        task.wait(delayTime)
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- 17. Auto Claim Index Worker (รับรางวัลสมุดภาพดัชนีอัตโนมัติ)
task.spawn(function()
    while true do
        if Flags.AutoClaimIndex then
            pcall(function()
                local indexModule = (ReplicatedStorage:FindFirstChild("UI") and ReplicatedStorage.UI:FindFirstChild("Index") and ReplicatedStorage.UI.Index:FindFirstChild("Model") and ReplicatedStorage.UI.Index.Model:FindFirstChild("IndexModel"))
                    or (ReplicatedStorage:FindFirstChild("UI") and ReplicatedStorage.UI:FindFirstChild("IndexPanel") and ReplicatedStorage.UI.IndexPanel:FindFirstChild("Model") and ReplicatedStorage.UI.IndexPanel.Model:FindFirstChild("IndexModel"))
                if indexModule then
                    local IndexModel = require(indexModule)
                    if IndexModel then
                        IndexModel:ClaimReward("Ants")
                        IndexModel:ClaimReward("Mutations")
                    end
                end
            end)
        end
        task.wait(4.0)
    end
end)

-- 18. Auto Starfall Event Worker (เข้าร่วมกิจกรรมฝนดาวตกอัตโนมัติ)
task.spawn(function()
    while true do
        if Flags.AutoStarfallEvent then
            pcall(function()
                local StarEventTime = nil
                pcall(function()
                    StarEventTime = require(ReplicatedStorage.Battle.Game.Helper.StarEventTime)
                end)
                local isActive = true
                if StarEventTime and StarEventTime.IsActive then
                    isActive = StarEventTime.IsActive()
                end

                if isActive then
                    local starEvent = Workspace:FindFirstChild("StarEvent")
                    local enterPart = starEvent and starEvent:FindFirstChild("Enterpromt")
                    local enterPrompt = enterPart and (enterPart:IsA("ProximityPrompt") and enterPart or enterPart:FindFirstChildWhichIsA("ProximityPrompt", true))
                    if enterPrompt and enterPrompt.Enabled and fireproximityprompt then
                        fireproximityprompt(enterPrompt, 0)
                    end
                end
            end)
        end
        task.wait(2.5)
    end
end)

-- 18. Auto Save Config Worker (บันทึกคอนฟิกอัตโนมัติทุกๆ 30 วินาที)
task.spawn(function()
    while true do
        task.wait(30)
        if Flags.AutoSaveConfig then
            pcall(saveConfig)
        end
    end
end)

-- 19. Auto Resource Converter Worker
task.spawn(function()
    while true do
        if Flags.AutoResourceConverter and Flags.ConverterAnts ~= "None" then
            pcall(function()
                local compostModel = require(ReplicatedStorage.UI.Compost.Model.CompostModel)
                local backpackModel = require(ReplicatedStorage.UI.Backpack.Model.BackpackModel)
                if not compostModel.Initialized then
                    compostModel:Init()
                end

                local wuKong = require(ReplicatedStorage.WuKong)
                local context = compostModel:GetContext(nil)
                context.PlayerData = {
                    Gold = getPlayerGold(),
                    CompostCoin = tonumber(wuKong:ExecuteQuery("/货币/堆肥币?属性数量")) or 0,
                    CompostLevel = tonumber(wuKong:ExecuteQuery("/属性/堆肥机等级?属性数量")) or 1
                }
                if compostModel.PendingOperation then return end

                local state = compostModel:GetState(context)
                if not state.Unlocked then return end
                if state.CanPull then
                    compostModel:PullLever(context)
                    return
                end
                if state.Progress >= 1 then return end

                local keepCount = math.max(math.floor(tonumber(Flags.KeepPerStack) or 0), 0)
                local selections = {}
                for packedValue, count in pairs(backpackModel:GetData().Stacks or {}) do
                    local unitIndex = backpackModel:DecodeBackpackValue(packedValue)
                    local unitConfig = unitIndex and battle_tbunit and battle_tbunit["Unit" .. tostring(unitIndex)]
                    if unitConfig and unitConfig.Rarity == Flags.ConverterAnts then
                        local depositCount = math.max(math.floor(tonumber(count) or 0) - keepCount, 0)
                        if depositCount > 0 then
                            selections[packedValue] = depositCount
                        end
                    end
                end

                if next(selections) then
                    compostModel:AddAnts(context, selections)
                end
            end)
        end
        task.wait(3.0)
    end
end)

-- 20. Auto Buy Food Worker
task.spawn(function()
    while true do
        if Flags.AutoBuyFood and Flags.SelectedFood ~= "None" then
            pcall(function()
                local bm = require(ReplicatedStorage.Battle.Game.Helper.RoomHelper.BlackMarket)
                if bm and bm.BuyFood then
                    bm.BuyFood(Flags.SelectedFood)
                end
            end)
        end
        task.wait(2.5)
    end
end)

-- 21. Player Movement & Anti-AFK Worker
task.spawn(function()
    while true do
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                if Flags.WalkSpeed and Flags.WalkSpeed ~= 16 then
                    LocalPlayer.Character.Humanoid.WalkSpeed = Flags.WalkSpeed
                end
                if Flags.JumpPower and Flags.JumpPower ~= 50 then
                    LocalPlayer.Character.Humanoid.JumpPower = Flags.JumpPower
                end
            end
        end)
        task.wait(0.5)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Flags.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local originalCanCollide = {}
RunService.Stepped:Connect(function()
    local character = LocalPlayer.Character
    if Flags.Noclip and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCanCollide[part] == nil then
                    originalCanCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, canCollide in pairs(originalCanCollide) do
            if part and part.Parent then
                part.CanCollide = canCollide
            end
            originalCanCollide[part] = nil
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Flags.AntiAFK then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            task.wait(0.2)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end)
    end
end)

-- ========================================================================
-- โหลดคอนฟิกอัตโนมัติ และตรวจเช็คการซ่อนหน้าต่าง UI ตอนเริ่ม (Hide UI On Start)
-- ========================================================================
task.spawn(function()
    applyCloverEffectSetting()
    applyFpsCap(Flags.LockAFK15FPS and 15 or (Flags.TargetFPS or 60))
    applyLowGraphics(Flags.LowGraphics)
    applyFullbright(Flags.Fullbright)
    if Flags.HideUIOnStart then
        task.wait(0.5)
        pcall(function()
            if Window and Window.Close then
                Window:Close()
            elseif Window and Window.Toggle then
                Window:Toggle()
            end
        end)
    end
end)

WindUI:Notify({
    Title = "Ant Empire Hub",
    Content = "โหลดระบบสำเร็จแล้ว ยินดีต้อนรับ " .. (LocalPlayer and LocalPlayer.DisplayName or "Player"),
    Duration = 4
})
