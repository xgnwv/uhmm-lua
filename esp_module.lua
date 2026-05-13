--[[ 
    SEXVDKA | ULTIMATE EXTERNAL ESP & TARGETING MODULE 
    VERSION: 3.0 (Professional Infrastructure)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// CONFIGURACIÓN GLOBAL
_G.SexvdkaConfig.EspEnabled = false
_G.SexvdkaConfig.EspTracers = false
_G.SexvdkaConfig.EspBoxes = false
_G.SexvdkaConfig.ShowNames = false
_G.SexvdkaConfig.TracerTargetOnly = false
_G.SexvdkaConfig.RainbowESP = false
_G.SexvdkaConfig.TargetList = {}

--// CACHÉ DE DIBUJOS
local Drawings = { Players = {} }

local function CreateDrawings(player)
    if Drawings.Players[player] then return end
    local table_draw = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text")
    }
    
    table_draw.Box.Thickness = 1.5
    table_draw.Box.Filled = false
    table_draw.Box.Transparency = 1
    
    table_draw.Tracer.Thickness = 1.5
    table_draw.Tracer.Transparency = 1
    
    table_draw.Name.Size = 16
    table_draw.Name.Center = true
    table_draw.Name.Outline = true
    table_draw.Name.Font = 2 
    
    Drawings.Players[player] = table_draw
end

local function RemoveDrawings(player)
    local d = Drawings.Players[player]
    if d then
        d.Box:Remove()
        d.Tracer:Remove()
        d.Name:Remove()
        Drawings.Players[player] = nil
    end
end

--// UI: AVATAR VIEWER (DISEÑO MEJORADO)
local Viewer = { Main = nil, Vp = nil, Title = nil, Stroke = nil }

local function SetupViewer()
    local Main = Instance.new("Frame")
    local Corner = Instance.new("UICorner", Main)
    local Stroke = Instance.new("UIStroke", Main)
    local Vp = Instance.new("ViewportFrame", Main)
    local Tl = Instance.new("TextLabel", Main)

    Main.Name = "Sexvdka_Viewer_V3"
    Main.Parent = CoreGui:FindFirstChild("sexvdka") or CoreGui
    Main.Size = UDim2.new(0, 200, 0, 280)
    Main.Position = UDim2.new(1, -210, 0.5, -140)
    Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    Main.BackgroundTransparency = 0.05
    Main.Visible = false

    Corner.CornerRadius = UDim.new(0, 10)
    Stroke.Color = Color3.fromRGB(255, 0, 255)
    Stroke.Thickness = 2

    Tl.Size = UDim2.new(1, 0, 0, 35)
    Tl.BackgroundTransparency = 1
    Tl.Text = "TARGET IDENTIFIED"
    Tl.Font = Enum.Font.GothamBold
    Tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tl.TextSize = 13

    Vp.Size = UDim2.new(0.9, 0, 0.8, 0)
    Vp.Position = UDim2.new(0.05, 0, 0.15, 0)
    Vp.BackgroundTransparency = 1

    Viewer.Main = Main
    Viewer.Vp = Vp
    Viewer.Title = Tl
    Viewer.Stroke = Stroke
end

local function PreviewAvatar(player)
    if not player or not player.Character then 
        Viewer.Main.Visible = false
        return 
    end
    
    Viewer.Vp:ClearAllChildren()
    Viewer.Main.Visible = true
    Viewer.Title.Text = player.Name:upper()
    
    player.Character.Archivable = true
    local clone = player.Character:Clone()
    clone.Parent = Viewer.Vp
    
    local cam = Instance.new("Camera", Viewer.Vp)
    local hrp = clone:FindFirstChild("HumanoidRootPart")
    if hrp then
        cam.CFrame = CFrame.new(hrp.Position + (hrp.CFrame.LookVector * 5.5) + Vector3.new(0, 1.5, 0), hrp.Position + Vector3.new(0, 1.5, 0))
        Viewer.Vp.CurrentCamera = cam
    end
end

--// SISTEMA DE LISTA CON SCROLL
local ScrollFrame = nil

local function UpdateTargetUI()
    if not ScrollFrame then return end
    ScrollFrame:ClearAllChildren()
    
    local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            -- Creamos un contenedor personalizado para el Scroll
            local Entry = Instance.new("Frame")
            Entry.Size = UDim2.new(0.95, 0, 0, 30)
            Entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            Entry.BorderSizePixel = 0
            Entry.Parent = ScrollFrame
            Instance.new("UICorner", Entry).CornerRadius = UDim.new(0, 4)

            local NameLabel = Instance.new("TextLabel", Entry)
            NameLabel.Size = UDim2.new(0.7, 0, 1, 0)
            NameLabel.Position = UDim2.new(0.05, 0, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = p.Name
            NameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            NameLabel.Font = Enum.Font.GothamMedium
            NameLabel.TextSize = 12
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left

            local TBtn = Instance.new("TextButton", Entry)
            TBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
            TBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
            TBtn.BackgroundColor3 = table.find(_G.SexvdkaConfig.TargetList, p.Name) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(40, 40, 40)
            TBtn.Text = ""
            Instance.new("UICorner", TBtn).CornerRadius = UDim.new(0, 4)

            -- LOGICA DE HOVER (Al pasar el cursor)
            Entry.MouseEnter:Connect(function()
                TweenService:Create(Entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                PreviewAvatar(p)
            end)

            Entry.MouseLeave:Connect(function()
                TweenService:Create(Entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
                Viewer.Main.Visible = false
            end)

            -- LOGICA DE TARGET
            TBtn.MouseButton1Click:Connect(function()
                local idx = table.find(_G.SexvdkaConfig.TargetList, p.Name)
                if idx then
                    table.remove(_G.SexvdkaConfig.TargetList, idx)
                    TBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                else
                    table.insert(_G.SexvdkaConfig.TargetList, p.Name)
                    TBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end)
        end
    end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end

--// CORE: ACTUALIZACIÓN DE ESP
RunService.RenderStepped:Connect(function()
    for p, d in pairs(Drawings.Players) do
        if p and p.Parent and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local head = p.Character:FindFirstChild("Head")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local isTarget = table.find(_G.SexvdkaConfig.TargetList, p.Name)

            if onScreen and _G.SexvdkaConfig.EspEnabled then
                -- Color dinámico
                local mainCol = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
                if _G.SexvdkaConfig.RainbowESP then mainCol = Color3.fromHSV(tick() % 5 / 5, 1, 1) end

                -- Box logic
                if _G.SexvdkaConfig.EspBoxes then
                    local sizeX = 2200 / pos.Z
                    local sizeY = 3200 / pos.Z
                    d.Box.Visible = true
                    d.Box.Size = Vector2.new(sizeX, sizeY)
                    d.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    d.Box.Color = mainCol
                else d.Box.Visible = false end

                -- Tracer logic
                if _G.SexvdkaConfig.EspTracers then
                    if not _G.SexvdkaConfig.TracerTargetOnly or isTarget then
                        d.Tracer.Visible = true
                        d.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        d.Tracer.To = Vector2.new(pos.X, pos.Y)
                        d.Tracer.Color = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 0, 255)
                    else d.Tracer.Visible = false end
                else d.Tracer.Visible = false end

                -- Name logic (Overhead)
                if _G.SexvdkaConfig.ShowNames and head then
                    local hPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                    d.Name.Visible = true
                    d.Name.Text = p.Name
                    d.Name.Position = Vector2.new(hPos.X, hPos.Y)
                    d.Name.Color = Color3.fromRGB(255, 255, 255)
                else d.Name.Visible = false end
            else
                d.Box.Visible = false; d.Tracer.Visible = false; d.Name.Visible = false
            end
        else
            d.Box.Visible = false; d.Tracer.Visible = false; d.Name.Visible = false
        end
    end
end)

--// INITIALIZATION & UI INJECTION
local function Start()
    SetupViewer()
    
    local Page = _G.SexvdkaFunctions.CreateTab("ESP & TARGET", 4)
    _G.SexvdkaFunctions.CreateToggle(Page, "Enable ESP Master", "EspEnabled")
    _G.SexvdkaFunctions.CreateToggle(Page, "Draw Boxes", "EspBoxes")
    _G.SexvdkaFunctions.CreateToggle(Page, "Draw Tracers", "EspTracers")
    _G.SexvdkaFunctions.CreateToggle(Page, "Overhead Names", "ShowNames")
    _G.SexvdkaFunctions.CreateToggle(Page, "Tracers: Target Only", "TracerTargetOnly")
    
    -- Crear el ScrollingFrame para los jugadores
    local ListTitle = Instance.new("TextLabel", Page)
    ListTitle.Size = UDim2.new(1, 0, 0, 25)
    ListTitle.Text = "--- PLAYER LIST (HOVER FOR AVATAR) ---"
    ListTitle.BackgroundTransparency = 1
    ListTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
    ListTitle.Font = Enum.Font.GothamBold
    ListTitle.TextSize = 11

    ScrollFrame = Instance.new("ScrollingFrame", Page)
    ScrollFrame.Size = UDim2.new(1, 0, 0, 180)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 3
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 255)

    -- Lifecycle Events
    Players.PlayerAdded:Connect(function(p)
        CreateDrawings(p)
        UpdateTargetUI()
    end)
    Players.PlayerRemoving:Connect(function(p)
        RemoveDrawings(p)
        UpdateTargetUI()
    end)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then CreateDrawings(p) end
    end
    UpdateTargetUI()
end

-- Ejecución
task.spawn(Start)

-- Loop de seguridad para actualización de Canvas y Dibujos
task.spawn(function()
    while task.wait(3) do
        for p, d in pairs(Drawings.Players) do
            if not p or not p.Parent then RemoveDrawings(p) end
        end
    end
end)

print("SEXVDKA ESP V3: SCROLLING & HOVER AVATAR ACTIVE")
