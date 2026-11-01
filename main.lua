-- =====================================================================
-- 脚本名称：索尼克中心
-- 作者：李佳
-- 版本：V3.0.0 (免卡密 · 自动分配版)
-- 功能：自动身份识别分配 + 全图透视 + 掉落物透视 + 防黑屏
-- =====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

-- ==========================================
-- 模块 1：初始化 UI
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "索尼克中心", 
    Author = "李佳", 
    Folder = "SonicV3", 
    Size = UDim2.fromOffset(460, 380), 
    Theme = "Dark"
})

-- ==========================================
-- 模块 2：顶部全自动身份显示 UI
-- ==========================================
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name = "AutoAllocateUI"
StatusGui.ResetOnSpawn = false
StatusGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local StatusFrame = Instance.new("Frame", StatusGui)
StatusFrame.Size = UDim2.new(0, 240, 0, 45)
StatusFrame.Position = UDim2.new(0.5, -120, 0, 20)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
StatusFrame.BackgroundTransparency = 0.2
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", StatusFrame)
UIStroke.Thickness = 1.5

local StatusText = Instance.new("TextLabel", StatusFrame)
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "当前身份: 正在检测..."
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 16

-- ==========================================
-- 模块 3：核心自动分配检测逻辑
-- ==========================================
local isAutoAllocate = false
local currentRole = "未知"

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            -- 检测身上的物品（刀或枪）
            local hasKnife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
            local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")))
            
            if hasKnife then
                currentRole = "杀手"
                StatusText.Text = "当前身份: 杀手 (Murderer)"
                StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
                UIStroke.Color = Color3.fromRGB(255, 50, 50)
                -- 如果自动分配开启了，这里可以联动其他代码
            elseif hasGun then
                currentRole = "警长"
                StatusText.Text = "当前身份: 警长 (Sheriff)"
                StatusText.TextColor3 = Color3.fromRGB(50, 150, 255)
                UIStroke.Color = Color3.fromRGB(50, 150, 255)
            else
                currentRole = "平民"
                StatusText.Text = "当前身份: 平民 (Innocent)"
                StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
                UIStroke.Color = Color3.fromRGB(0, 255, 100)
            end
        else
            StatusText.Text = "当前身份: 等待复活..."
            StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- 模块 4：全图透视渲染系统
-- ==========================================
local isESP = false
local isItemESP = false
local isNoFlash = false

local ESPCache = {}
local ItemCache = {}

RunService.RenderStepped:Connect(function()
    -- 4.1 玩家身份透视
    if isESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char = plr.Character
                local hum = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")
                local root = char:FindFirstChild("HumanoidRootPart")
                
                if hum and hum.Health > 0 and head and root then
                    local roleName, roleColor = "平民", Color3.fromRGB(0, 255, 0)
                    if char:FindFirstChild("Knife") then 
                        roleName, roleColor = "杀手", Color3.fromRGB(255, 50, 50)
                    elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then 
                        roleName, roleColor = "警长", Color3.fromRGB(50, 150, 255)
                    end
                    
                    local dist = math.floor((root.Position - CurrentCamera.CFrame.Position).Magnitude)
                    
                    if not ESPCache[plr] then
                        local hl = Instance.new("Highlight", char)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        local bb = Instance.new("BillboardGui", head)
                        bb.Size, bb.StudsOffset, bb.AlwaysOnTop = UDim2.new(0, 150, 0, 50), Vector3.new(0, 2.5, 0), true
                        local n = Instance.new("TextLabel", bb)
                        n.Size, n.BackgroundTransparency, n.Font, n.TextSize, n.TextStrokeTransparency = UDim2.new(1, 0, 0.5, 0), 1, Enum.Font.GothamBold, 16, 0
                        local r = Instance.new("TextLabel", bb)
                        r.Size, r.Position, r.BackgroundTransparency, r.Font, r.TextSize, r.TextStrokeTransparency = UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), 1, Enum.Font.GothamBold, 14, 0
                        ESPCache[plr] = {HL = hl, Name = n, Role = r}
                    end
                    
                    local esp = ESPCache[plr]
                    esp.HL.FillColor = roleColor
                    esp.Name.Text = plr.Name .. " [" .. dist .. "m]"
                    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
                    esp.Role.Text, esp.Role.TextColor3 = roleName, roleColor
                end
            end
        end
    else
        for _, v in pairs(ESPCache) do 
            if v.HL then v.HL:Destroy() end
            if v.Name then v.Name.Parent:Destroy() end
        end
        ESPCache = {}
    end

    -- 4.2 掉落物透视
    if isItemESP then
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj.Name == "GunDrop" or obj.Name == "KnifeDrop" or obj.Name == "RevolverDrop") and obj:IsA("BasePart") then
                if not ItemCache[obj] then
                    local hl = Instance.new("Highlight", obj)
                    hl.FillColor = Color3.fromRGB(255, 255, 0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    ItemCache[obj] = hl
                end
            end
        end
    else
        for _, v in pairs(ItemCache) do v:Destroy() end
        ItemCache = {}
    end
end)

-- ==========================================
-- 模块 5：防黑屏逻辑
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if isNoFlash then
            Lighting.Ambient = Color3.fromRGB(150, 150, 150)
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            Lighting.Brightness = 2
        end
    end
end)

-- ==========================================
-- 模块 6：UI 功能面板挂载
-- ==========================================
local MainTab = Window:Tab({ Title = "视觉辅助", Icon = "eye" })

MainTab:Toggle({
    Title = "全图身份透视",
    Desc = "红杀手 / 蓝警长 / 绿平民",
    Value = false,
    Callback = function(state) isESP = state end
})

MainTab:Toggle({
    Title = "掉落物高亮",
    Desc = "高亮地上的枪和刀",
    Value = false,
    Callback = function(state) isItemESP = state end
})

MainTab:Toggle({
    Title = "防黑屏 (手电强化)",
    Desc = "杀手关灯时依然视野清晰",
    Value = false,
    Callback = function(state) isNoFlash = state end
})

local AutoTab = Window:Tab({ Title = "自动分配", Icon = "zap" })

AutoTab:Toggle({
    Title = "开启顶部身份提示",
    Desc = "屏幕正上方自动显示你当前被分配的身份",
    Value = true,
    Callback = function(state) StatusFrame.Visible = state end
})
