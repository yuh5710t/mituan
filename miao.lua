-- =====================================================================
-- 脚本名称：索尼克中心
-- 作者：李佳
-- 版本：V2.2.0 (精准240行定稿版)
-- 功能：加密卡密 + 防抖透视 + 掉落物高亮 + 防黑屏
-- =====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

-- ==========================================
-- 模块 1：加密与配置
-- ==========================================
local Config = {
    EncryptedKey = 1940, -- 2026 ^ 66
    XORKey = 66,
    QQGroup = "2066484928",
    MaxAttempts = 3
}
local CurrentAttempts = 0

local function GetHWID()
    return LocalPlayer.UserId .. "-" .. game.JobId
end

-- ==========================================
-- 模块 2：卡密 UI 构建
-- ==========================================
local AuthGui = Instance.new("ScreenGui")
AuthGui.Name = "SonicAuthUI"
AuthGui.DisplayOrder = 99999
AuthGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 220)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = AuthGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 255, 150)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

task.spawn(function()
    while AuthGui.Parent do
        TweenService:Create(Stroke, TweenInfo.new(1), {Transparency = 0}):Play()
        task.wait(1)
        TweenService:Create(Stroke, TweenInfo.new(1), {Transparency = 0.6}):Play()
        task.wait(1)
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 20)
Title.BackgroundTransparency = 1
Title.Text = "索尼克中心 - 授权验证"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

local HwidLabel = Instance.new("TextLabel")
HwidLabel.Size = UDim2.new(1, 0, 0, 20)
HwidLabel.Position = UDim2.new(0, 0, 0, 50)
HwidLabel.BackgroundTransparency = 1
HwidLabel.Text = "机器码: " .. string.sub(GetHWID(), 1, 12) .. "***"
HwidLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
HwidLabel.Font = Enum.Font.Code
HwidLabel.TextSize = 12
HwidLabel.Parent = MainFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.8, 0, 0, 45)
InputBox.Position = UDim2.new(0.1, 0, 0, 80)
InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderText = "请输入卡密"
InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.Parent = MainFrame
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 8)

local ErrorLabel = Instance.new("TextLabel")
ErrorLabel.Size = UDim2.new(1, 0, 0, 15)
ErrorLabel.Position = UDim2.new(0, 0, 0, 130)
ErrorLabel.BackgroundTransparency = 1
ErrorLabel.Text = ""
ErrorLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
ErrorLabel.Font = Enum.Font.Gotham
ErrorLabel.TextSize = 12
ErrorLabel.Parent = MainFrame

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.8, 0, 0, 40)
SubmitBtn.Position = UDim2.new(0.1, 0, 0, 150)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
SubmitBtn.Text = "验证授权"
SubmitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 16
SubmitBtn.Parent = MainFrame
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 8)

SubmitBtn.MouseEnter:Connect(function() TweenService:Create(SubmitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 120)}):Play() end)
SubmitBtn.MouseLeave:Connect(function() TweenService:Create(SubmitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play() end)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0.8, 0, 0, 20)
CopyBtn.Position = UDim2.new(0.1, 0, 0, 195)
CopyBtn.BackgroundTransparency = 1
CopyBtn.Text = "没卡密？点击复制群号"
CopyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CopyBtn.Font = Enum.Font.Gotham
CopyBtn.TextSize = 12
CopyBtn.Parent = MainFrame

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(Config.QQGroup) end
    CopyBtn.Text = "群号已复制！"
    task.wait(2)
    CopyBtn.Text = "没卡密？点击复制群号"
end)

-- ==========================================
-- 模块 3：验证逻辑
-- ==========================================
SubmitBtn.MouseButton1Click:Connect(function()
    local inputStr = InputBox.Text
    local numInput = tonumber(inputStr)

    if not numInput or (numInput ~ Config.XORKey) ~= Config.EncryptedKey then
        CurrentAttempts = CurrentAttempts + 1
        ErrorLabel.Text = "卡密错误！剩余次数: " .. (Config.MaxAttempts - CurrentAttempts)
        
        task.spawn(function()
            local origPos = MainFrame.Position
            for i = 1, 4 do
                MainFrame.Position = origPos + UDim2.new(0, math.random(-10, 10), 0, 0)
                task.wait(0.05)
            end
            MainFrame.Position = origPos
        end)

        if CurrentAttempts >= Config.MaxAttempts then
            SubmitBtn.Text = "已锁定"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(1)
            LocalPlayer:Kick("验证失败次数过多，请加群：" .. Config.QQGroup)
        end
        return
    end

    -- 验证成功
    SubmitBtn.Text = "验证成功，加载中..."
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    task.wait(0.5)
    AuthGui:Destroy()

    -- ==========================================
    -- 模块 4：主功能加载
    -- ==========================================
    local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    local Window = WindUI:CreateWindow({
        Title = "索尼克中心", Author = "李佳", Folder = "SonicV2", Size = UDim2.fromOffset(460, 350), Theme = "Dark"
    })

    local isESP, isItemESP, isNoFlash = false, false, false
    local ESPCache, ItemCache = {}, {}

    -- 渲染循环
    RunService.RenderStepped:Connect(function()
        if isESP then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local char, hum, head, root = plr.Character, plr.Character:FindFirstChild("Humanoid"), plr.Character:FindFirstChild("Head"), plr.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and head and root then
                        local role, color = "平民", Color3.fromRGB(0, 255, 0)
                        if char:FindFirstChild("Knife") then role, color = "杀手", Color3.fromRGB(255, 50, 50)
                        elseif char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then role, color = "警长", Color3.fromRGB(50, 150, 255) end
                        
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
                        esp.HL.FillColor = color
                        esp.Name.Text = plr.Name .. " [" .. math.floor((root.Position - CurrentCamera.CFrame.Position).Magnitude) .. "m]"
                        esp.Role.Text, esp.Role.TextColor3 = role, color
                    end
                end
            end
        else
            for _, v in pairs(ESPCache) do v.HL:Destroy() v.Name.Parent:Destroy() end
            ESPCache = {}
        end

        if isItemESP then
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

    -- 防黑屏
    task.spawn(function()
        while task.wait(0.5) do
            if isNoFlash then
                Lighting.Ambient = Color3.fromRGB(150, 150, 150)
                Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                Lighting.Brightness = 2
            end
        end
    end)

    -- 挂载 UI
    local Tab = Window:Tab({ Title = "视觉辅助", Icon = "eye" })
    Tab:Toggle({ Title = "全图身份透视", Value = false, Callback = function(s) isESP = s end })
    Tab:Toggle({ Title = "掉落物高亮", Value = false, Callback = function(s) isItemESP = s end })
    Tab:Toggle({ Title = "防黑屏", Value = false, Callback = function(s) isNoFlash = s end })
end)
