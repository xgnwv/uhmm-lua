--// SEXVDKA | ADVANCED ESP & TARGETING MODULE
--// Creado para integrarse externamente vía GitHub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// CONFIGURACIÓN DE CATEGORÍA
_G.SexvdkaConfig.EspEnabled = false
_G.SexvdkaConfig.EspTracers = false
_G.SexvdkaConfig.EspBoxes = false
_G.SexvdkaConfig.ShowNames = false
_G.SexvdkaConfig.TracerTargetOnly = false
_G.SexvdkaConfig.TargetList = {} -- Almacena múltiples targets

--// INTERFAZ DE AVATAR VIEWER (DISEÑO NEÓN)
local ViewerGui = Instance.new("Frame")
local ViewPort = Instance.new("ViewportFrame")
local ViewTitle = Instance.new("TextLabel")

local function SetupViewer()
    ViewerGui.Name = "AvatarViewer"
    ViewerGui.Parent = CoreGui:FindFirstChild("sexvdka") and CoreGui.sexvdka.Main or CoreGui
    ViewerGui.Size = UDim2.new(0, 200, 0, 250)
    ViewerGui.Position = UDim2.new(1, 10, 0, 0)
    ViewerGui.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    ViewerGui.BorderSizePixel = 0
    ViewerGui.Visible = false
    
    local Stroke = Instance.new("UIStroke", ViewerGui)
    Stroke.Color = Color3.fromRGB(255, 0, 255)
    Stroke.Thickness = 1.5
    
    Instance.new("UICorner", ViewerGui).CornerRadius = UDim.new(0, 8)
    
    ViewTitle.Size = UDim2.new(1, 0, 0, 30)
    ViewTitle.Text = "TARGET PREVIEW"
    ViewTitle.Font = Enum.Font.GothamBold
    ViewTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ViewTitle.TextSize = 12
    ViewTitle.BackgroundTransparency = 1
    ViewTitle.Parent = ViewerGui

    ViewPort.Size = UDim2.new(0.9, 0, 0.8, 0)
    ViewPort.Position = UDim2.new(0.05, 0, 0.15, 0)
    ViewPort.BackgroundTransparency = 1
    ViewPort.Parent = ViewerGui
end

local function UpdateViewer(player)
    ViewPort:ClearAllChildren()
    if not player or not player.Character then ViewerGui.Visible = false return end
    
    ViewerGui.Visible = true
    player.Character.Archivable = true
    local Clone = player.Character:Clone()
    Clone.Parent = ViewPort
    
    local Cam = Instance.new("Camera")
    Cam.CFrame = CFrame.new(Clone.HumanoidRootPart.Position + (Clone.HumanoidRootPart.CFrame.LookVector * 5), Clone.HumanoidRootPart.Position)
    ViewPort.CurrentCamera = Cam
    Cam.Parent = ViewPort
end

--// LÓGICA DE ESP MEJORADA
local function CreateESP(player)
    local tracer = Drawing.new("Line")
    local box = Drawing.new("Square")
    local nameTag = Drawing.new("Text")
    
    local connection; connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent or not player.Character then 
            tracer.Visible = false
            box.Visible = false
            nameTag.Visible = false
            if not player.Parent then 
                tracer:Remove()
                box:Remove()
                nameTag:Remove()
                connection:Disconnect() 
            end
            return 
        end

        local isTarget = table.find(_G.SexvdkaConfig.TargetList, player.Name)
        
        if _G.SexvdkaConfig.EspEnabled and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                -- Lógica de Tracers (Opción Target Only)
                local canShowTracer = _G.SexvdkaConfig.EspTracers
                if _G.SexvdkaConfig.TracerTargetOnly and not isTarget then
                    canShowTracer = false
                end
                
                tracer.Visible = canShowTracer
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(pos.X, pos.Y)
                tracer.Color = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 0, 255)
                tracer.Thickness = isTarget and 2 or 1.2
                
                -- Boxes (Cambia a Rojo si es Target)
                box.Visible = _G.SexvdkaConfig.EspBoxes
                local sizeX = 2200 / pos.Z
                local sizeY = 3200 / pos.Z
                box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                box.Size = Vector2.new(sizeX, sizeY)
                box.Color = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
                box.Thickness = isTarget and 2 or 1
                
                -- Nombres (Opcional)
                nameTag.Visible = _G.SexvdkaConfig.ShowNames
                nameTag.Text = player.Name
                nameTag.Position = Vector2.new(pos.X, pos.Y - (sizeY/2) - 15)
                nameTag.Center = true
                nameTag.Outline = true
                nameTag.Size = 14
                nameTag.Font = 2
                nameTag.Color = Color3.fromRGB(255, 255, 255)
            else
                tracer.Visible = false
                box.Visible = false
                nameTag.Visible = false
            end
        else
            tracer.Visible = false
            box.Visible = false
            nameTag.Visible = false
        end
    end)
end

--// INYECCIÓN EN EL MENÚ PRINCIPAL
if _G.SexvdkaFunctions then
    SetupViewer()
    local EspPage = _G.SexvdkaFunctions.CreateTab("ESP & TARGET", 4)
    
    -- Toggles Principales
    _G.SexvdkaFunctions.CreateToggle(EspPage, "Master ESP", "EspEnabled")
    _G.SexvdkaFunctions.CreateToggle(EspPage, "Draw Boxes", "EspBoxes")
    _G.SexvdkaFunctions.CreateToggle(EspPage, "Draw Tracers", "EspTracers")
    _G.SexvdkaFunctions.CreateToggle(EspPage, "Show Player Names", "ShowNames")
    _G.SexvdkaFunctions.CreateToggle(EspPage, "Tracers: Targets Only", "TracerTargetOnly")
    
    -- Sistema de Lista de Usuarios para Target
    local ListLabel = Instance.new("TextLabel", EspPage)
    ListLabel.Size = UDim2.new(0.9, 0, 0, 20)
    ListLabel.Text = "--- MULTI-TARGET SELECTOR ---"
    ListLabel.Font = Enum.Font.GothamBold
    ListLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
    ListLabel.BackgroundTransparency = 1
    
    local function RefreshTargetList()
        for _, child in pairs(EspPage:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("TBtn") and child.TLabel.Text:find("Target:") then
                child:Destroy()
            end
        end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                _G.SexvdkaFunctions.CreateToggle(EspPage, "Target: "..p.Name, "Target_"..p.Name, function(state)
                    if state then
                        table.insert(_G.SexvdkaConfig.TargetList, p.Name)
                        UpdateViewer(p)
                    else
                        local index = table.find(_G.SexvdkaConfig.TargetList, p.Name)
                        if index then table.remove(_G.SexvdkaConfig.TargetList, index) end
                        ViewerGui.Visible = false
                    end
                end)
            end
        end
    end
    
    RefreshTargetList()
    Players.PlayerAdded:Connect(RefreshTargetList)
    Players.PlayerRemoving:Connect(RefreshTargetList)
end

-- Iniciar ESP para todos
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

print("ESP Module v2 Loaded [Target System & Avatar Viewer Active]")