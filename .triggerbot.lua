--// TRIGGER BOT & RAPID FIRE MODULAR (Anti-Cheat Bypass Edition)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- Variables de estado (puedes cambiarlas manualmente o conectarlas a tu UI)
local TriggerActive = true
local RapidFireActive = true
local ClickDelay = 0.02 -- Velocidad del Rapid Fire (ajustable)

-- Función de Click compatible con la mayoría de executors
local function DoClick()
    if mouse1click then
        mouse1click()
    elseif click_detector then
        click_detector() -- Para algunos executors específicos
    else
        -- Fallback: Simulación de input básica si el executor es limitado
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
        task.wait(ClickDelay)
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
    end
end

-- Bucle principal optimizado
local Shooting = false
RunService.Heartbeat:Connect(function()
    if not TriggerActive then return end

    local target = Mouse.Target
    if target and target.Parent then
        -- Verificación de Humanoid y Equipo
        local character = target.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        -- Si no lo encuentra en el parent, busca en el abuelo (por si toca un accesorio)
        if not humanoid and character.Parent:FindFirstChildOfClass("Humanoid") then
            character = character.Parent
            humanoid = character:FindFirstChildOfClass("Humanoid")
        end

        if humanoid and humanoid.Health > 0 then
            local player = Players:GetPlayerFromCharacter(character)
            
            -- Solo dispara si es un enemigo (o si no es el LocalPlayer)
            if player and player ~= LP and player.Team ~= LP.Team then
                if RapidFireActive then
                    if not Shooting then
                        Shooting = true
                        repeat
                            DoClick()
                            task.wait(ClickDelay)
                        until Mouse.Target ~= target or not RapidFireActive or not TriggerActive
                        Shooting = false
                    end
                else
                    DoClick()
                    task.wait(0.1) -- Delay anti-spam para trigger normal
                end
            end
        end
    end
end)

print("Trigger & RapidFire cargados exitosamente.")