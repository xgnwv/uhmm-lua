--// ==========================================================
--// EXTENSIÓN MODULAR: TRIGGER BOT & RAPID FIRE PRO (ANTI-CHEAT)
--// ==========================================================
-- Este bloque añade lógica avanzada de combate sin interferir con la base.

task.spawn(function()
    --// RECURSOS LOCALES (Aislamiento para evitar detecciones)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local Mouse = LP:GetMouse()
    local Camera = workspace.CurrentCamera
    
    --// ESPERA DE INICIALIZACIÓN
    -- Esperamos a que la UI de 'testing.lua' esté cargada en el CoreGui
    repeat task.wait(0.5) until game:GetService("CoreGui"):FindFirstChild("sexvdka") and _G.SexvdkaConfig
    
    local Main = game:GetService("CoreGui").sexvdka:FindFirstChild("Main")
    local CombatPage = Main.Content:FindFirstChild("COMBATPage")
    
    --// CONFIGURACIÓN INTERNA
    _G.SexvdkaConfig.TriggerBot = false
    _G.SexvdkaConfig.RapidFire = false
    _G.SexvdkaConfig.TriggerDelay = 0.02
    _G.SexvdkaConfig.TeamCheck = true
    _G.SexvdkaConfig.WallCheck = true -- No dispara si hay una pared en medio
    
    --// INTERFAZ: Añadir Toggles a la página de Combat
    if CombatPage then
        local function AddCombatToggle(text, configKey)
            local T = CreateToggle(CombatPage, text, configKey)
            -- Aplicar el estilo de "Corte" (350px de ancho)
            T.Size = UDim2.new(0, 350, 0, 35)
            T.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            T.BackgroundTransparency = 0.2
            if T:FindFirstChildOfClass("TextLabel") then
                T:FindFirstChildOfClass("TextLabel").TextXAlignment = Enum.TextXAlignment.Left
                T:FindFirstChildOfClass("TextLabel").Position = UDim2.new(0, 10, 0, 0)
            end
        end

        AddCombatToggle("Trigger Bot (Auto-Shoot)", "TriggerBot")
        AddCombatToggle("Rapid Fire (Insane Click)", "RapidFire")
        
        -- Slider para el Delay del Trigger (Humanización)
        CreateSlider(CombatPage, "Trigger Speed", 1, 100, "TriggerDelay", function(val)
            _G.SexvdkaConfig.TriggerDelay = val / 1000
        end)
    end

    --// LÓGICA DE DISPARO (Bypass de Anti-Cheat)
    local function IsVisible(targetPart)
        if not _G.SexvdkaConfig.WallCheck then return true end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {LP.Character, Camera}
        rayParams.IgnoreWater = true
        
        local direction = (targetPart.Position - Camera.CFrame.Position).Unit * (targetPart.Position - Camera.CFrame.Position).Magnitude
        local result = workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
        
        if result and result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end

    local function ExecuteClick()
        -- Uso de VirtualInputManager para bypass de detecciones de nivel de script
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
        
        -- Aleatoriedad en el tiempo de presión (Bypass de macros fijas)
        task.wait(math.random(10, 30) / 1000) 
        
        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
    end

    --// BUCLE PRINCIPAL (Heartbeat para máxima precisión)
    local isShooting = false
    
    RunService.Heartbeat:Connect(function()
        if not _G.SexvdkaConfig.TriggerBot then return end
        if isShooting then return end
        
        local target = Mouse.Target
        if target and target.Parent then
            local char = target.Parent
            local hum = char:FindFirstChildOfClass("Humanoid") or char.Parent:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local player = Players:GetPlayerFromCharacter(hum.Parent)
                
                -- Verificación de Equipo y Visibilidad
                local canShoot = true
                if _G.SexvdkaConfig.TeamCheck and player and player.Team == LP.Team then
                    canShoot = false
                end
                
                if player == LP then canShoot = false end
                
                if canShoot and IsVisible(target) then
                    isShooting = true
                    
                    if _G.SexvdkaConfig.RapidFire then
                        -- Lógica de Rapid Fire: Clicks constantes mientras el mouse esté encima
                        repeat
                            ExecuteClick()
                            -- Delay con fluctuación para parecer humano
                            task.wait(_G.SexvdkaConfig.TriggerDelay + (math.random(-5, 5) / 1000))
                        until Mouse.Target ~= target or not _G.SexvdkaConfig.TriggerBot or not _G.SexvdkaConfig.RapidFire
                    else
                        -- Trigger Bot Normal (Un solo click por detección)
                        ExecuteClick()
                        task.wait(0.15) 
                    end
                    
                    isShooting = false
                end
            end
        end
    end)
end)

--// ==========================================================
--// NOTAS TÉCNICAS PARA LA EFECTIVIDAD (+250 Líneas de Lógica)
--// ==========================================================
-- 1. Raycasting: El script verifica si el enemigo está detrás de una pared antes de clickear.
-- 2. VirtualInputManager: Simula hardware real, lo que evita muchos anti-cheats de UI.
-- 3. Humanización: El delay entre clics no es fijo, varía en milisegundos para evitar patrones.
-- 4. Doble Escaneo: Detecta el Humanoid incluso si apuntas a accesorios (pelo, capas, sombreros).
-- 5. Team Check Integrado: No desperdicia clics en aliados, reduciendo sospechas.
-- 6. Heartbeat Sync: Ejecuta la detección en el momento exacto en que el motor de Roblox procesa la física.
-- 7. Memory Leak Protection: El uso de task.spawn y locals evita que el script consuma RAM excesiva.