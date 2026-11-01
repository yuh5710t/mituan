-- =====================================================================
-- 脚本名称：索尼克中心
-- 作者：李佳
-- 版本：V1.0.0 (223行精准定稿版)
-- 功能：卡密系统 + 全图身份透视 + 掉落物透视 + 防黑屏
-- =====================================================================

-- ==========================================
-- 模块 0：引入服务与初始化变量
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- 配置区
local CorrectKey = "2026"
local QQGroup = "2066484928"
local NoKeyMsg = "卡密错误，请加QQ群获取：" .. QQGroup

-- 创建卡密 GUI 容器
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SonicCenterAuth"
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ==========================================
-- 模块 1：卡密验证 UI 构建
-- ==========================================
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 180)
Frame.Position = UDim2.new(0.5, -160, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(218, 165, 32)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

-- 标题
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = "索尼克中心 | 李佳"
Title.TextColor3 = Color3.fromRGB(218, 165, 32)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Frame

-- 输入框
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.8, 0, 0, 40)
InputBox.Position = UDim2.new(0.1, 0, 0, 60)
InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderText = "请输入卡密"
InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.Text = ""
InputBox.Parent = Frame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 6)
BoxCorner.Parent = InputBox

-- 验证按钮
local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.8, 0, 0, 35)
SubmitBtn.Position = UDim2.new(0.1, 0, 0, 120)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(218, 165, 32)
SubmitBtn.Text = "验证并启动脚本"
SubmitBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 15
SubmitBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = SubmitBtn

-- ==========================================
-- 模块 2：核心逻辑与 UI 加载
-- ==========================================
SubmitBtn.MouseButton1Click:Connect(function()
    -- 验证卡密
    if InputBox.Text ~= CorrectKey then
        player:Kick(NoKeyMsg)
        return
    end
    
    -- 验证通过，销毁验证框
    ScreenGui:Destroy()

    -- 加载 WindUI 库
    local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    
    -- 创建主窗口
    local Window = WindUI:CreateWindow({
        Title = "索尼克中心", 
        Author = "李佳", 
        Folder = "SonicCenterV1", 
        Size = UDim2.fromOffset(460, 350), 
        Theme = "Dark"
    })

    -- 状态变量
    local isPlayerESP = false
    local isItemESP = false
    local isNoFlash = false
    
    local ESPObjects = {}
    local ItemObjects = {}

    -- ==========================================
    -- 模块 3：渲染循环 (RenderStepped)
    -- ==========================================
    RunService.RenderStepped:Connect(function()
        
        -- 3.1 玩家身份透视逻辑
        if isPlayerESP then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local char = plr.Character
                    local hum = char:FindFirstChild("Humanoid")
                    local head = char:FindFirstChild("Head")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    
                    if hum and hum.Health > 0 and head and root then
                        -- 身份判定
                        local roleText = "平民"
                        local roleColor = Color3.fromRGB(0, 255, 0)
                        
                        if char:FindFirstChild("Knife") then 
                            roleText = "杀手"
                            roleColor = Color3.fromRGB(255, 0, 0)
                        elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then 
                            roleText = "警长"
                            roleColor = Color3.fromRGB(0, 150, 255)
                        end
                        
                        -- 距离计算
                        local dist = math.floor((root.Position - camera.CFrame.Position).Magnitude)
                        
                        -- 生成 UI 节点
                        if not ESPObjects[plr] then
                            local HL = Instance.new("Highlight")
                            HL.Parent = char
                            HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            
                            local BB = Instance.new("BillboardGui")
                            BB.Parent = head
                            BB.Size = UDim2.new(0, 150, 0, 50)
                            BB.StudsOffset = Vector3.new(0, 2.5, 0)
                            BB.AlwaysOnTop = true
                            
                            local NameLabel = Instance.new("TextLabel")
                            NameLabel.Parent = BB
                            NameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                            NameLabel.BackgroundTransparency = 1
                            NameLabel.Font = Enum.Font.GothamBold
                            NameLabel.TextSize = 16
                            NameLabel.TextStrokeTransparency = 0
                            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            
                            local RoleLabel = Instance.new("TextLabel")
                            RoleLabel.Parent = BB
                            RoleLabel.Size = UDim2.new(1, 0, 0.5, 0)
                            RoleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                            RoleLabel.BackgroundTransparency = 1
                            RoleLabel.Font = Enum.Font.GothamBold
                            RoleLabel.TextSize = 14
                            RoleLabel.TextStrokeTransparency = 0
                            
                            ESPObjects[plr] = {Highlight = HL, NameUI = NameLabel, RoleUI = RoleLabel}
                        end
                        
                        -- 更新节点数据
                        local esp = ESPObjects[plr]
                        esp.Highlight.FillColor = roleColor
                        esp.NameUI.Text = plr.Name .. " [" .. dist .. "m]"
                        esp.RoleUI.Text = roleText
                        esp.RoleUI.TextColor3 = roleColor
                    end
                end
            end
        else
            -- 清理玩家透视
            for _, v in pairs(ESPObjects) do 
                if v.Highlight then v.Highlight:Destroy() end
                if v.NameUI then v.NameUI.Parent:Destroy() end
            end
            ESPObjects = {}
        end

        -- 3.2 掉落物透视逻辑
        if isItemESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj.Name == "GunDrop" or obj.Name == "RevolverDrop" or obj.Name == "KnifeDrop") and obj:IsA("BasePart") then
                    if not ItemObjects[obj] then
                        local HL = Instance.new("Highlight")
                        HL.Parent = obj
                        HL.FillColor = Color3.fromRGB(255, 255, 0)
                        HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        ItemObjects[obj] = HL
                    end
                end
            end
        else
            -- 清理掉落物透视
            for _, hl in pairs(ItemObjects) do hl:Destroy() end
            ItemObjects = {}
        end
    end)

    -- ==========================================
    -- 模块 4：环境光干预 (防黑屏)
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
    -- 模块 5：UI 面板挂载
    -- ==========================================
    local MainTab = Window:Tab({ Title = "视觉辅助", Icon = "eye" })
    
    MainTab:Toggle({
        Title = "全图身份透视",
        Desc = "红框杀手 / 蓝框警长 / 绿框平民",
        Value = false,
        Callback = function(state) isPlayerESP = state end
    })
    
    MainTab:Toggle({
        Title = "掉落物高亮",
        Desc = "高亮地上掉落的枪和刀",
        Value = false,
        Callback = function(state) isItemESP = state end
    })
    
    MainTab:Toggle({
        Title = "防黑屏 (手电强化)",
        Desc = "杀手关灯时依然保持视野清晰",
        Value = false,
        Callback = function(state) isNoFlash = state end
    })
end)
