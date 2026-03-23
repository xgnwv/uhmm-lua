--// SEXVDKA | EXTERNAL ESP MODULE (Independent)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuración en la tabla global para compatibilidad
_G.SexvdkaConfig.EspEnabled = false
_G.SexvdkaConfig.EspTracers = false
_G.SexvdkaConfig.EspBoxes = false

local function CreateESP(player)
    local tracer = Drawing.new("Line")
    local box = Drawing.new("Square")
    
    local connection; connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then 
            tracer:Remove()
            box:Remove()
            connection:Disconnect()
            return 
        end

        if _G.SexvdkaConfig.EspEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                -- Tracers (Estilo exacto al video: Centro Inferior)
                tracer.Visible = _G.SexvdkaConfig.EspTracers
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(pos.X, pos.Y)
                tracer.Color = Color3.fromRGB(255, 0, 255)
                tracer.Thickness = 1.2
                
                -- Boxes (Estilo exacto al video: Blanco)
                box.Visible = _G.SexvdkaConfig.EspBoxes
                local sizeX = 2200 / pos.Z
                local sizeY = 3200 / pos.Z
                box.Size = Vector2.new(sizeX, sizeY)
                box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                box.Color = Color3.fromRGB(255, 255, 255)
                box.Thickness = 1
            else
                tracer.Visible = false
                box.Visible = false
            end
        else
            tracer.Visible = false
            box.Visible = false
        end
    end)
end

-- Ejecución para jugadores
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- Inyección automática en la UI existente
task.spawn(function()
    local UI = CoreGui:FindFirstChild("sexvdka")
    if UI then
        -- Crear nueva pestaña ESP o añadir a Visuals
        local content = UI.Main.Content
        -- Usamos la función CreateTab que ya está definida en tu script principal
        local EspPage = _G.SexvdkaFunctions.CreateTab("ESP", 4) 
        
        -- Añadir los Toggles usando tu función original
        _G.SexvdkaFunctions.CreateToggle(EspPage, "Master Switch", "EspEnabled")
        _G.SexvdkaFunctions.CreateToggle(EspPage, "Draw Tracers", "EspTracers")
        _G.SexvdkaFunctions.CreateToggle(EspPage, "Draw Boxes", "EspBoxes")
    end
end)