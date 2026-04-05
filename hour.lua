local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local SantiagoLabel = Instance.new("TextLabel")
local LimaLabel = Instance.new("TextLabel")
local ArubaLabel = Instance.new("TextLabel")

ScreenGui.Name = "ClockOverlay_Central"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 1.000
MainFrame.Position = UDim2.new(0.5, -125, 0, 5) 
MainFrame.Size = UDim2.new(0, 250, 0, 80)

UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 0)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function StyleLabel(label, name, layoutOrder)
    label.Name = name
    label.Parent = MainFrame
    label.BackgroundTransparency = 1.000
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.Code
    label.TextColor3 = Color3.fromRGB(255, 255, 255) 
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 16.000
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.LayoutOrder = layoutOrder
end

StyleLabel(SantiagoLabel, "Santiago", 1)
StyleLabel(LimaLabel, "Lima", 2)
StyleLabel(ArubaLabel, "Aruba", 3)

task.spawn(function()
    while task.wait(1) do
        local utc = os.time()
        
        -- Ajuste: Chile (UTC-4 Invierno), Lima (UTC-5), Aruba (UTC-4)
        local timeSantiago = os.date("!%I:%M %p", utc - (4 * 3600))
        local timeLima = os.date("!%I:%M %p", utc - (5 * 3600))
        local timeAruba = os.date("!%I:%M %p", utc - (4 * 3600))
        
        SantiagoLabel.Text = timeSantiago:lower()
        LimaLabel.Text = timeLima:lower()
        ArubaLabel.Text = timeAruba:lower()
    end
end)
