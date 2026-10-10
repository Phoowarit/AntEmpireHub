--[[
    Build An Ant Empire Hub (Lite)
    Events: Strawberry Coins, Travelling Snail, Starfall, Claim Index
    Dungeon: Auto Dungeon (กดปุ่ม Start ให้อัตโนมัติ) + Auto 4x Attack Speed
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
    AutoDungeon = false,
    AutoStarDungeon = false,        -- ปิดตายตัว (ไม่มีสวิตช์ในเมนู)
    AutoPressDungeonStart = true,   -- เปิดตายตัว: ลงดันแล้วกดปุ่ม Start ให้เอง
    Auto4xAttackSpeed = false,
    AutoPickupStrawberryCoins = false,
    CoinPickupDelay = 0.10,
    AutoClickTravellingSnail = false,
    AutoStarfallEvent = false,
    AutoClaimIndex = false,
    AutoSaveConfig = true           -- บันทึกการตั้งค่าอัตโนมัติทุก 30 วินาที
}


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
            Content = "Settings saved.",
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
                    Content = "Settings loaded.",
                    Duration = 2.5
                })
            end
        end
    end)
    return success
end

local function sendEcsCommand(commandName, payload)
    pcall(function()
        local EventBus = require(ReplicatedStorage.Packages.EventBus)
        EventBus.FireServer("ECS_COMMAND", commandName, payload or {})
    end)
end

-- ค้นหาห้องรังของตนเอง (My Room)
local function teleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and cf then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

-- ดึงค่าตัวคูณราคาขายปัจจุบันอย่างแม่นยำ (รองรับทั้ง PlayerDataHelper, FoodSellPriceService และ SellShopModel)

-- โหลดคอนฟิกที่บันทึกไว้ แล้วบังคับค่าที่ไม่มีสวิตช์ในเมนู
loadConfig(true)
Flags.AutoPressDungeonStart = true
Flags.AutoStarDungeon = false
Flags.AutoSaveConfig = true

-- ========================================================================
-- Menu tabs (Lite: Events and Dungeon only)
-- ========================================================================
local Tabs = {
    Events = Window:Tab({ Title = "Events", Icon = "sparkles" }),
    Dungeon = Window:Tab({ Title = "Dungeon", Icon = "swords" })
}

-- ---------- EVENTS ----------
Tabs.Events:Toggle({
    Title = "Auto Pickup Strawberry Coins",
    Value = Flags.AutoPickupStrawberryCoins,
    Callback = function(v) Flags.AutoPickupStrawberryCoins = v end
})

Tabs.Events:Slider({
    Title = "Coin Pickup Delay",
    Step = 0.05,
    Value = { Min = 0.05, Max = 1.00, Default = math.clamp(tonumber(Flags.CoinPickupDelay) or 0.10, 0.05, 1.00) },
    Callback = function(val)
        Flags.CoinPickupDelay = tonumber(string.format("%.2f", val)) or 0.10
    end
})

Tabs.Events:Toggle({
    Title = "Auto Click Travelling Snail",
    Value = Flags.AutoClickTravellingSnail,
    Callback = function(v) Flags.AutoClickTravellingSnail = v end
})

Tabs.Events:Toggle({
    Title = "Auto Starfall Event",
    Value = Flags.AutoStarfallEvent,
    Callback = function(v) Flags.AutoStarfallEvent = v end
})

Tabs.Events:Toggle({
    Title = "Auto Claim Index",
    Value = Flags.AutoClaimIndex,
    Callback = function(v) Flags.AutoClaimIndex = v end
})

-- ---------- DUNGEON ----------
Tabs.Dungeon:Toggle({
    Title = "Auto Dungeon",
    Value = Flags.AutoDungeon,
    Callback = function(v) Flags.AutoDungeon = v end
})

Tabs.Dungeon:Toggle({
    Title = "Auto 4x Attack Speed",
    Value = Flags.Auto4xAttackSpeed,
    Callback = function(v) Flags.Auto4xAttackSpeed = v end
})


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


WindUI:Notify({
    Title = "Ant Empire Hub",
    Content = "Loaded successfully. Welcome, " .. (LocalPlayer and LocalPlayer.DisplayName or "Player"),
    Duration = 4
})
