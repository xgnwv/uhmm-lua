--[[
    SOLO Animaciones Zombie (sin Korblox ni headless)
    Optimizado para evitar conflictos y recargas innecesarias
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Lógica de Animaciones
local function applyAnimations(character)
    local animate = character:WaitForChild("Animate", 5)
    if not animate then return end

    -- IDLE (Zombie)
    if animate:FindFirstChild("idle") then
        if animate.idle:FindFirstChild("Animation1") then
            animate.idle.Animation1.AnimationId = "rbxassetid://616158929"
        end
        if animate.idle:FindFirstChild("Animation2") then
            animate.idle.Animation2.AnimationId = "rbxassetid://616160636"
        end
    end

    -- WALK (Zombie)
    if animate:FindFirstChild("walk") then
        local walkAnim = animate.walk:FindFirstChildOfClass("Animation")
        if walkAnim then
            walkAnim.AnimationId = "rbxassetid://616168032"
        end
    end

    -- RUN (Zombie)
    if animate:FindFirstChild("run") then
        local runAnim = animate.run:FindFirstChildOfClass("Animation")
        if runAnim then
            runAnim.AnimationId = "rbxassetid://616163682"
        end
    end

    -- Refrescar humanoide para aplicar cambios
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end
end

-- Aplicación segura
local function onCharacter(character)
    if not character then return end
    character:WaitForChild("Humanoid")
    task.wait(0.3)
    applyAnimations(character)
end

-- Conexión
if player.Character then
    onCharacter(player.Character)
end

player.CharacterAdded:Connect(onCharacter)