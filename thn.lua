-- =====================================================================
-- 脚本名称：索尼克中心 (神级强化版)
-- 作者：李佳
-- 版本：V4.0.0 (静默自瞄 + 幽灵穿墙 + 自动分配)
-- =====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

-- ==========================================
-- 模块 1：UI 初始化
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "索尼克中心", Author = "李佳", Folder = "SonicV4", Size = UDim2.fromOffset(460, 380), Theme = "Dark"
})

-- ==========================================
-- 模块 2：自动分配与状态
-- ==========================================
local Config = {
    IsESP = false, IsItemESP = false, IsNoFlash = false,
    IsSilentAim = false, IsNoclip = false, IsAutoPickup = false
}
local currentRole = "未知"
local TargetMurderer = nil

local StatusGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local StatusFrame = Instance.new("Frame", StatusGui)
StatusFrame.Size = UDim2.new(0, 240, 0, 45)
StatusFrame.Position = UDim2.new(0.5, -120, 0, 20)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", StatusFrame)

local StatusText = Instance.new("TextLabel", StatusFrame)
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "身份: 检测中..."
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.Font = Enum.Font.GothamBold

-- ==========================================
-- 模块 3：核心逻辑与物理干预
-- ==========================================
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        
        if char and hum then
            local hasKnife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
            local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")))
            
            -- 自动识别身份
            if hasKnife then
                currentRole = "杀手"
                StatusText.Text = "当前身份: 杀手 (Murderer)"
                StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
                UIStroke.Color = Color3.fromRGB(255, 50, 50)
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
            
            -- 【神级功能1】：幽灵穿墙
            if Config.IsNoclip then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            else
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
            
            -- 自动捡枪
            if Config.IsAutoPickup and currentRole == "警长" then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if (obj.Name == "GunDrop" or obj.Name == "RevolverDrop") and obj:IsA("BasePart") and (obj.Position - root.Position).Magnitude < 50 then
                            firetouchinterest(root, obj, 0)
                            firetouchinterest(root, obj, 1)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ==========================================
-- 模块 4：神级功能 - 静默自瞄 (Silent Aim)
-- ==========================================
-- 原理：在本地相机准备开火时，瞬间把目标的头部坐标替换到鼠标指向的位置
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- 如果本地在进行射线检测（通常对应开枪）
    if tostring(method) == "Raycast" or tostring(self) == "Ray" then
        -- 如果开启了自瞄且场上有杀手
        if Config.IsSilentAim and TargetMurderer and TargetMurderer.Character then
            local targetHead = TargetMurderer.Character:FindFirstChild("Head")
            if targetHead then
                -- 强行把瞄准方向改成杀手的头
                local origin = CurrentCamera.CFrame.Position
                local direction = (targetHead.Position - origin).Unit * 1000
                -- 替换参数
                if type(args[2]) == "Vector3" then
                    args[2] = direction
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

-- ==========================================
-- 模块 5：全图透视渲染系统
-- ==========================================
local ESPCache, ItemCache = {}, {}

RunService.RenderStepped:Connect(function()
    TargetMurderer = nil -- 每帧重置杀手目标

    if Config.IsESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char, hum, head, root = plr.Character, plr.Character:FindFirstChild("Humanoid"), plr.Character:FindFirstChild("Head"), plr.Character:FindFirstChild("HumanoidRootPart")
                
                if hum and hum.Health > 0 and head and root then
                    local roleName, roleColor = "平民", Color3.fromRGB(0, 255, 0)
                    if char:FindFirstChild("Knife") then 
                        roleName, roleColor = "杀手", Color3.fromRGB(255, 50, 50)
                        TargetMurderer = plr -- 找到杀手了，自动分配给静默自瞄
                    elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then 
                        roleName, roleColor = "警长", Color3.fromRGB(50, 150, 255)
                    end
                    
                    if not ESPCache[plr] then
                        local hl = Instance.new("Highlight", char)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        local bb = Instance.new("BillboardGui", head)
                        bb.Size, bb.StudsOffset, bb.AlwaysOnTop = UDim2.new(0, 150, 0, 50), Vector3.new(0, 2.5, 0), true
                        local n = Instance.new("TextLabel", bb)
                        n.Size, n.BackgroundTransparency, n.Font, n.TextSize = UDim2.new(1, 0, 0.5, 0), 1, Enum.Font.GothamBold, 16
                        local r = Instance.new("TextLabel", bb)
                        r.Size, r.Position, r.BackgroundTransparency, r.Font, r.TextSize = UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), 1, Enum.Font.GothamBold, 14
                        ESPCache[plr] = {HL = hl, Name = n, Role = r}
                    end
                    local esp = ESPCache[plr]
                    esp.HL.FillColor = roleColor
                    esp.Name.Text = plr.Name
                    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
                    esp.Role.Text, esp.Role.TextColor3 = roleName, roleColor
                end
            end
        end
    else
        for _, v in pairs(ESPCache) do v.HL:Destroy() v.Name.Parent:Destroy() end
        ESPCache = {}
    end

    if Config.IsItemESP then
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj.Name == "GunDrop" or obj.Name == "KnifeDrop") and obj:IsA("BasePart") then
                if not ItemCache[obj] then
                    local hl = Instance.new("Highlight", obj)
                    hl.FillColor, hl.DepthMode = Color3.fromRGB(255, 255, 0), Enum.HighlightDepthMode.AlwaysOnTop
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
-- 模块 6：防黑屏与 UI 挂载
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if Config.IsNoFlash then
            Lighting.Ambient = Color3.fromRGB(150, 150, 150)
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            Lighting.Brightness = 2
        end
    end
end)

local MainTab = Window:Tab({ Title = "视觉辅助", Icon = "eye" })
MainTab:Toggle({ Title = "全图身份透视", Value = false, Callback = function(s) Config.IsESP = s end })
MainTab:Toggle({ Title = "掉落物高亮", Value = false, Callback = function(s) Config.IsItemESP = s end })
MainTab:Toggle({ Title = "防黑屏", Value = false, Callback = function(s) Config.IsNoFlash = s end })

local CombatTab = Window:Tab({ Title = "神级战斗", Icon = "crosshair" })
CombatTab:Toggle({ 
    Title = "警长静默自瞄", 
    Desc = "只要按住左键，子弹自动锁杀手头，无需瞄准", 
    Value = false, 
    Callback = function(s) Config.IsSilentAim = s end 
})
CombatTab:Toggle({ 
    Title = "幽灵穿墙 (杀手/平民通用)", 
    Desc = "无视墙体，可以直接穿墙躲藏或抓人", 
    Value = false, 
    Callback = function(s) Config.IsNoclip = s end 
})
CombatTab:Toggle({ 
    Title = "警长秒捡枪", 
    Desc = "附近 50 格内的枪自动拾取", 
    Value = false, 
    Callback = function(s) Config.IsAutoPickup = s end 
})
