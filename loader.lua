-- FISH.OS Auto Fisher Hub - All Features OFF by Default
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")

local autoFish = false
local autoClickFish = false
local autoCrackGeodes = false
local autoSellFish = false
local autoUpgrade = false
local autoPrestige = false
local autoFleetUpgrade = false
local afkMode = true
local minigameStartTime = 0

-- ==================== RAYFIELD GUI ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "FISH.OS Auto Fisher Hub",
    LoadingTitle = "FISH.OS Auto Fisher",
    LoadingSubtitle = "by Grok",
    ConfigurationSaving = { Enabled = true, FolderName = "FISHOSHub", FileName = "Config" }
})

local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({ Name = "Auto Fisher", CurrentValue = false, Callback = function(v) autoFish = v end })
MainTab:CreateToggle({ Name = "Auto ClickFish", CurrentValue = false, Callback = function(v) autoClickFish = v end })
MainTab:CreateToggle({ Name = "Auto Crack Geodes", CurrentValue = false, Callback = function(v) autoCrackGeodes = v end })
MainTab:CreateToggle({ Name = "Auto Sell Fish (>2.0)", CurrentValue = false, Callback = function(v) autoSellFish = v end })
MainTab:CreateToggle({ Name = "Auto Rod Upgrades", CurrentValue = false, Callback = function(v) autoUpgrade = v end })

MainTab:CreateToggle({
    Name = "Auto Fleet Boats Upgrade",
    CurrentValue = false,
    Callback = function(v) autoFleetUpgrade = v end,
})

MainTab:CreateToggle({ Name = "Auto Prestige", CurrentValue = false, Callback = function(v) autoPrestige = v end })
MainTab:CreateToggle({ Name = "AFK Mode (Anti-Kick)", CurrentValue = true, Callback = function(v) afkMode = v end })

local StatusLabel = MainTab:CreateLabel("Status: Waiting...")
local GeodeLabel = MainTab:CreateLabel("Geodes: 0")
local MarketLabel = MainTab:CreateLabel("Market Price: --")
local UpgradeLabel = MainTab:CreateLabel("Upgrades: Checking...")
local FleetLabel = MainTab:CreateLabel("Fleet: Checking...")
local PrestigeLabel = MainTab:CreateLabel("Prestige: Checking...")

-- ==================== STRONG FALLBACK FLEET UPGRADE (10s) ====================
spawn(function()
    while task.wait(10) do
        if not autoFleetUpgrade then 
            FleetLabel:Set("Fleet: Disabled")
            continue 
        end
        
        pcall(function()
            print("🔍 [Fleet] Fetching data...")
            ReplicatedStorage:WaitForChild("GetFleetData"):InvokeServer()
            ReplicatedStorage:WaitForChild("GetExpeditions"):InvokeServer()
            
            local upgraded = 0
            
            -- Try upgrading slots 1 to 25 (covers current and future boats)
            for slot = 1, 25 do
                local success = pcall(function()
                    ReplicatedStorage:WaitForChild("BuyBestEquipment"):InvokeServer(slot)
                end)
                
                if success then
                    print("🚤 [Fleet] Tried upgrading slot", slot)
                    upgraded += 1
                    task.wait(1.2)
                end
            end
            
            if upgraded > 0 then
                FleetLabel:Set("Fleet: Tried " .. upgraded .. " slots")
            else
                FleetLabel:Set("Fleet: No upgrades attempted")
            end
        end)
    end
end)

-- ==================== AUTO PRESTIGE ====================
spawn(function()
    while task.wait(8) do
        if not autoPrestige then 
            PrestigeLabel:Set("Prestige: Disabled")
            continue 
        end
        pcall(function()
            local data = ReplicatedStorage:WaitForChild("GetPrestige"):InvokeServer()
            if data then
                PrestigeLabel:Set("Prestige: Level " .. (data.level or data.prestige or 0))
                if data.canPrestige then
                    print("🌟 Prestiging...")
                    ReplicatedStorage:WaitForChild("DoPrestige"):FireServer()
                end
            end
        end)
    end
end)

-- ==================== AFK MODE ====================
spawn(function()
    while task.wait(45) do
        if afkMode then
            pcall(function()
                VirtualInput:SendMouseWheelEvent(0, 0, true, game)
                task.wait(0.1)
                VirtualInput:SendMouseWheelEvent(0, 0, false, game)
            end)
        end
    end
end)

-- ==================== AUTO CLICKFISH ====================
spawn(function()
    while true do
        task.wait(0.22)
        if autoClickFish then
            pcall(function() ReplicatedStorage:WaitForChild("ClickFish"):FireServer() end)
        end
    end
end)

-- ==================== AUTO CRACK GEODES ====================
spawn(function()
    while task.wait(1.1) do
        if not autoCrackGeodes then continue end
        pcall(function()
            local data = ReplicatedStorage:WaitForChild("GetGeodes"):InvokeServer()
            if data and data.geodes then
                GeodeLabel:Set("Geodes: " .. #data.geodes)
                if #data.geodes > 0 then
                    for i = 1, math.min(#data.geodes, 10) do
                        ReplicatedStorage:WaitForChild("CrackGeode"):FireServer(1)
                        task.wait(0.1)
                    end
                end
            end
        end)
    end
end)

-- ==================== AUTO SELL ====================
spawn(function()
    while task.wait(2.5) do
        if not autoSellFish then
            MarketLabel:Set("Market Price: --")
            continue
        end
        pcall(function()
            local marketData = ReplicatedStorage:WaitForChild("GetMarketData"):InvokeServer()
            local price = marketData and (marketData.price or marketData.CurrentPrice or 0) or 0
            MarketLabel:Set("Market Price: $" .. string.format("%.2f", price))
           
            if price >= 2.0 then
                print("💰 High price! Selling...")
                ReplicatedStorage:WaitForChild("SellFish"):FireServer(100)
            end
        end)
    end
end)

-- ==================== AUTO ROD UPGRADES ====================
spawn(function()
    while task.wait(2.5) do
        if not autoUpgrade then
            UpgradeLabel:Set("Upgrades: Disabled")
            continue
        end
        pcall(function()
            local data = ReplicatedStorage:WaitForChild("GetUpgrades"):InvokeServer()
            local bought = 0
            if data and data.rods then
                for _, rod in ipairs(data.rods) do
                    if rod.level and rod.maxLevel and rod.level < rod.maxLevel then
                        ReplicatedStorage:WaitForChild("BuyUpgrade"):FireServer(rod.rodIndex)
                        bought += 1
                        task.wait(0.8)
                    end
                end
            end
            UpgradeLabel:Set(bought > 0 and "Upgrades: +"..bought or "Upgrades: Nothing to buy")
        end)
    end
end)

-- ==================== FISHING LOGIC ====================
game:GetService("RunService").RenderStepped:Connect(function()
    if not autoFish then 
        StatusLabel:Set("Status: Paused") 
        return 
    end
    
    local fishos = player.PlayerGui:FindFirstChild("FishOS", true)
    if not fishos then 
        StatusLabel:Set("Status: Looking for bobber...") 
        return 
    end
    
    local overlay = fishos:FindFirstChild("MinigameOverlay")
    if overlay then
        StatusLabel:Set("Status: In Minigame")
        
        local barOuter = overlay:FindFirstChild("BarOuter")
        local fishingBar = barOuter and barOuter:FindFirstChild("FishingBar")
        local fishIcon = fishingBar and fishingBar:FindFirstChild("FishIcon")
        
        if fishIcon and fishingBar then
            if minigameStartTime == 0 then minigameStartTime = tick() end
            local fishY = fishIcon.AbsolutePosition.Y + (fishIcon.AbsoluteSize.Y / 2)
            local barY = fishingBar.AbsolutePosition.Y + (fishingBar.AbsoluteSize.Y / 2)
            
            if fishY < barY - 8 then
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            else
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    else
        minigameStartTime = 0
        StatusLabel:Set("Status: Waiting for bobber...")
    end
end)

-- Bobber & Completion
spawn(function()
    while task.wait(0.35) do
        if autoFish then
            local hasMinigame = player.PlayerGui:FindFirstChild("FishOS", true) and player.PlayerGui.FishOS:FindFirstChild("MinigameOverlay")
            if not hasMinigame then
                pcall(function() ReplicatedStorage:WaitForChild("ClickBobber"):FireServer() end)
            end
        end
    end
end)

spawn(function()
    while task.wait(0.5) do
        if minigameStartTime > 0 and tick() - minigameStartTime >= 5 then
            pcall(function() ReplicatedStorage:WaitForChild("MinigameResult"):FireServer(true, 1) end)
            minigameStartTime = 0
        end
    end
end)

print("✅ Full Hub Loaded - All features OFF by default!")
Rayfield:Notify({Title = "Success", Content = "Auto Fleet Upgrade Added\nEverything starts OFF", Duration = 8})
