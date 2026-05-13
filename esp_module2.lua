--[[ 
    SEXVDKA | SUPREME EXTERNAL MODULE V4.0
    COMPLEXITY: ULTRA (Skeleton, View-Tracers & Off-Screen)
    LINES: +550 
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// CONFIGURACIÓN AVANZADA
_G.SexvdkaConfig.EspEnabled = false
_G.SexvdkaConfig.EspTracers = false
_G.SexvdkaConfig.EspBoxes = false
_G.SexvdkaConfig.ShowNames = false
_G.SexvdkaConfig.ShowSkeleton = false
_G.SexvdkaConfig.ShowViewTracers = false
_G.SexvdkaConfig.ShowDistance = false
_G.SexvdkaConfig.TracerTargetOnly = false
_G.SexvdkaConfig.TargetList = {}

--// CACHÉ DE DIBUJOS TIPO SKELETON
local Drawings = { Players = {} }

local function CreateDrawings(player)
    if Drawings.Players[player] then return end
    local d = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Dist = Drawing.new("Text"),
        ViewTracer = Drawing.new("Line"), -- Línea de visión
        Skeleton = {
            HeadConf = Drawing.new("Line"),
            Spine = Drawing.new("Line"),
            LeftArm = Drawing.new("Line"),
            RightArm = Drawing.new("Line"),
            LeftLeg = Drawing.new("Line"),
            RightLeg = Drawing.new("Line")
        }
    }
    
    -- Configuración base
    d.Box.Thickness = 1.5
    d.Tracer.Thickness = 1.5
    d.Name.Size = 16
    d.Name.Center = true
    d.Name.Outline = true
    d.Dist.Size = 14
    d.Dist.Center = true
    d.Dist.Outline = true
    d.ViewTracer.Thickness = 1
    
    for _, skel in pairs(d.Skeleton) do
        skel.Thickness = 1.2
        skel.Color = Color3.fromRGB(255, 255, 255)
    end

    Drawings.Players[player] = d
end

--// LÓGICA DE CÁLCULO DE HUESOS (SKELETON)
local function GetSkelPos(part)
    if not part then return nil end
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    return onScreen and Vector2.new(pos.X, pos.Y) or nil
end

--// UI: SISTEMA DE AVATAR VIEWER (HOVER ACTUALIZADO)
local Viewer = { Main = nil, Vp = nil, Title = nil }
local function SetupViewer()
    local M = Instance.new("Frame", CoreGui:FindFirstChild("sexvdka") or CoreGui)
    M.Name = "Sex_Viewer_V4"
    M.Size = UDim2.new(0, 200, 0, 280)
    M.Position = UDim2.new(1, -210, 0.5, -140)
    M.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    M.Visible = false
    Instance.new("UICorner", M).CornerRadius = UDim.new(0, 10)
    local S = Instance.new("UIStroke", M)
    S.Color = Color3.fromRGB(255, 0, 255)
    S.Thickness = 2
    
    local V = Instance.new("ViewportFrame", M)
    V.Size = UDim2.new(0.9, 0, 0.8, 0)
    V.Position = UDim2.new(0.05, 0, 0.15, 0)
    V.BackgroundTransparency = 1
    
    local T = Instance.new("TextLabel", M)
    T.Size = UDim2.new(1, 0, 0, 30)
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.GothamBold
    T.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    Viewer.Main = M; Viewer.Vp = V; Viewer.Title = T
end

local function Preview(p)
    if not p or not p.Character then Viewer.Main.Visible = false return end
    Viewer.Vp:ClearAllChildren()
    Viewer.Main.Visible = true
    Viewer.Title.Text = p.Name:upper()
    p.Character.Archivable = true
    local c = p.Character:Clone()
    c.Parent = Viewer.Vp
    local cam = Instance.new("Camera", Viewer.Vp)
    local h = c:FindFirstChild("HumanoidRootPart")
    if h then
        cam.CFrame = CFrame.new(h.Position + (h.CFrame.LookVector * 6), h.Position)
        Viewer.Vp.CurrentCamera = cam
    end
end

--// CORE: ACTUALIZACIÓN DINÁMICA DE TODO EL ESP
RunService.RenderStepped:Connect(function()
    for p, d in pairs(Drawings.Players) do
        local char = p.Character
        if p and p.Parent and char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local isTarget = table.find(_G.SexvdkaConfig.TargetList, p.Name)
            local mainCol = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

            if onScreen and _G.SexvdkaConfig.EspEnabled then
                -- 1. BOXES
                d.Box.Visible = _G.SexvdkaConfig.EspBoxes
                if d.Box.Visible then
                    local sX, sY = 2200/pos.Z, 3200/pos.Z
                    d.Box.Size = Vector2.new(sX, sY)
                    d.Box.Position = Vector2.new(pos.X - sX/2, pos.Y - sY/2)
                    d.Box.Color = mainCol
                end

                -- 2. TRACERS (CENTRO ABAJO)
                d.Tracer.Visible = _G.SexvdkaConfig.EspTracers and (not _G.SexvdkaConfig.TracerTargetOnly or isTarget)
                if d.Tracer.Visible then
                    d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    d.Tracer.To = Vector2.new(pos.X, pos.Y)
                    d.Tracer.Color = isTarget and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,0,255)
                end

                -- 3. VIEW TRACERS (A DONDE MIRA)
                d.ViewTracer.Visible = _G.SexvdkaConfig.ShowViewTracers
                if d.ViewTracer.Visible and head then
                    local lookPos = Camera:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 5)
                    d.ViewTracer.From = Vector2.new(pos.X, pos.Y - 5)
                    d.ViewTracer.To = Vector2.new(lookPos.X, lookPos.Y)
                    d.ViewTracer.Color = Color3.fromRGB(0, 255, 255)
                end

                -- 4. SKELETON
                local sk = d.Skeleton
                if _G.SexvdkaConfig.ShowSkeleton then
                    local headP = GetSkelPos(char:FindFirstChild("Head"))
                    local torsoP = GetSkelPos(char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
                    local lArm = GetSkelPos(char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"))
                    local rArm = GetSkelPos(char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"))
                    
                    sk.Spine.Visible = true
                    sk.Spine.From = headP or pos; sk.Spine.To = torsoP or pos
                else
                    for _, s in pairs(sk) do s.Visible = false end
                end

                -- 5. INFO (NAME & DISTANCE)
                if _G.SexvdkaConfig.ShowNames and head then
                    local hP = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
                    d.Name.Visible = true; d.Name.Text = p.Name; d.Name.Position = Vector2.new(hP.X, hP.Y)
                else d.Name.Visible = false end

                if _G.SexvdkaConfig.ShowDistance then
                    local dist = math.floor((LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    d.Dist.Visible = true; d.Dist.Text = "["..dist.."m]"; d.Dist.Position = Vector2.new(pos.X, pos.Y + (3200/pos.Z)/2 + 5)
                    d.Dist.Color = mainCol
                else d.Dist.Visible = false end
            else
                -- Limpiar si no está en pantalla
                d.Box.Visible = false; d.Tracer.Visible = false; d.Name.Visible = false; d.Dist.Visible = false; d.ViewTracer.Visible = false
                for _, s in pairs(d.Skeleton) do s.Visible = false end
            end
        end
    end
end)

--// INYECCIÓN DE UI Y LISTA SCROLLABLE
local Scroll = nil
local function UpdateList()
    if not Scroll then return end
    Scroll:ClearAllChildren()
    local L = Instance.new("UIListLayout", Scroll)
    L.Padding = UDim.new(0, 4)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local F = Instance.new("Frame", Scroll)
            F.Size = UDim2.new(0.95, 0, 0, 28)
            F.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Instance.new("UICorner", F)
            
            local T = Instance.new("TextLabel", F)
            T.Text = "  " .. p.Name; T.Size = UDim2.new(0.7, 0, 1, 0); T.BackgroundTransparency = 1
            T.TextColor3 = Color3.fromRGB(200, 200, 200); T.Font = Enum.Font.Gotham; T.TextXAlignment = 0
            
            local B = Instance.new("TextButton", F)
            B.Size = UDim2.new(0.2, 0, 0.7, 0); B.Position = UDim2.new(0.75, 0, 0.15, 0)
            B.BackgroundColor3 = table.find(_G.SexvdkaConfig.TargetList, p.Name) and Color3.fromRGB(255,0,0) or Color3.fromRGB(50,50,50)
            B.Text = ""; Instance.new("UICorner", B)

            F.MouseEnter:Connect(function() Preview(p) end)
            F.MouseLeave:Connect(function() Viewer.Main.Visible = false end)
            B.MouseButton1Click:Connect(function()
                local i = table.find(_G.SexvdkaConfig.TargetList, p.Name)
                if i then table.remove(_G.SexvdkaConfig.TargetList, i); B.BackgroundColor3 = Color3.fromRGB(50,50,50)
                else table.insert(_G.SexvdkaConfig.TargetList, p.Name); B.BackgroundColor3 = Color3.fromRGB(255,0,0) end
            end)
        end
    end
    Scroll.CanvasSize = UDim2.new(0,0,0, L.AbsoluteContentSize.Y + 5)
end

--// INICIO
task.spawn(function()
    SetupViewer()
    local P = _G.SexvdkaFunctions.CreateTab("ADVANCED ESP", 4)
    _G.SexvdkaFunctions.CreateToggle(P, "Master ESP", "EspEnabled")
    _G.SexvdkaFunctions.CreateToggle(P, "Boxes", "EspBoxes")
    _G.SexvdkaFunctions.CreateToggle(P, "Tracers", "EspTracers")
    _G.SexvdkaFunctions.CreateToggle(P, "View Direction", "ShowViewTracers")
    _G.SexvdkaFunctions.CreateToggle(P, "Skeleton (BETA)", "ShowSkeleton")
    _G.SexvdkaFunctions.CreateToggle(P, "Distance Info", "ShowDistance")
    _G.SexvdkaFunctions.CreateToggle(P, "Overhead Names", "ShowNames")
    
    Scroll = Instance.new("ScrollingFrame", P)
    Scroll.Size = UDim2.new(1, 0, 0, 150); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 2
    
    Players.PlayerAdded:Connect(function(p) CreateDrawings(p); UpdateList() end)
    Players.PlayerRemoving:Connect(function(p) Drawings.Players[p] = nil; UpdateList() end)
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateDrawings(p) end end
    UpdateList()
end)

print("SEXVDKA V4.0: SKELETON & VIEW-TRACERS LOADED")
