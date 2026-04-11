--[[
    Animaciones:
    - Walk (Zombie)
    - Run (Zombie)
    - Jump (Ninja)
    - Fall (Ninja)
    Sin idle, sin korblox
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function applyAnimations(character)
    local animate = character:WaitForChild("Animate", 5)
    if not animate then return end

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

    -- JUMP (Ninja)
    if animate:FindFirstChild("jump") then
        local jumpAnim = animate.jump:FindFirstChildOfClass("Animation")
        if jumpAnim then
            jumpAnim.AnimationId = "rbxassetid://656117878"
        end
    end

    -- FALL (Ninja)
    if animate:FindFirstChild("fall") then
        local fallAnim = animate.fall:FindFirstChildOfClass("Animation")
        if fallAnim then
            fallAnim.AnimationId = "rbxassetid://656115606"
        end
    end

    -- Refrescar humanoide
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end
end

local function onCharacter(character)
    if not character then return end
    character:WaitForChild("Humanoid")
    task.wait(0.3)
    applyAnimations(character)
end

if player.Character then
    onCharacter(player.Character)
end

player.CharacterAdded:Connect(onCharacter)