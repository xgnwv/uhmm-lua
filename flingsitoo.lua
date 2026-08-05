getgenv().Script = "standd"
getgenv().Owner = "wrnqzc" -- Tu username aquí

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variables
local OwnerName = getgenv().Owner:lower()
local Prefix = "."
local Whitelist = {} -- {username = true}
local Flinging = false
local Orbiting = false
local CurrentTarget = nil
local OrbitConnection = nil
local FlingConnection = nil
local ControlConnection = nil

-- Configuración (ÓRBITA MUCHO MÁS ALEJADA)
local ORBIT_RADIUS = 3500 -- Aumentado para orbitar muy lejos
local ORBIT_HEIGHT = 150  -- Incrementado proporcionalmente
local VOID_DEPTH = -50000
local FLING_POWER = 50000

-- Utilidades
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function GetOwner()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == OwnerName then
            return p
        end
    end
    return nil
end

local function IsWhitelisted(name)
    return Whitelist[name:lower()] or name:lower() == OwnerName
end

local function GetPlayer(partial)
    if not partial then return nil end
    partial = partial:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #partial) == partial or 
           p.DisplayName:lower():sub(1, #partial) == partial then
            return p
        end
    end
    return nil
end

-- BLOQUEAR CONTROLES COMPLETAMENTE
local function BlockControls()
    if ControlConnection then return end
    
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.PlatformStand = true
    end
    
    ControlConnection = RunService.Heartbeat:Connect(function()
        local hum = GetHumanoid()
        local hrp = GetHRP()
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function UnblockControls()
    if ControlConnection then
        ControlConnection:Disconnect()
        ControlConnection = nil
    end
    
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- ORBITA ULTRA-RÁPIDA Y DISTANTE
local function StartOrbit()
    if Orbiting then return end
    Orbiting = true
    
    print("[Stand] Iniciando órbita a gran distancia...")
    BlockControls()
    
    local angle = math.random() * math.pi * 2
    
    OrbitConnection = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        local owner = GetOwner()
        
        if not hrp then return end
        
        local targetPos = Vector3.zero
        
        if owner and owner.Character then
            targetPos = owner.Character:GetPivot().Position
        end
        
        -- Velocidad de giro y fluctuación de distancia
        angle = angle + 0.08
        local radius = ORBIT_RADIUS + math.random(-300, 300)
        
        local offset = Vector3.new(
            math.cos(angle) * radius,
            ORBIT_HEIGHT + math.random(-50, 50),
            math.sin(angle) * radius
        )
        
        local finalCFrame = CFrame.new(targetPos + offset, targetPos)
        
        hrp.CFrame = finalCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            hum.PlatformStand = true
        end
    end)
end

local function StopOrbit()
    Orbiting = false
    if OrbitConnection then
        OrbitConnection:Disconnect()
        OrbitConnection = nil
    end
    UnblockControls()
    print("[Stand] Órbita detenida")
end

-- FLING (LOOP KILL)
local function StopLoopFling()
    Flinging = false
    CurrentTarget = nil
    
    if FlingConnection then
        FlingConnection:Disconnect()
        FlingConnection = nil
    end
    
    local hrp = GetHRP()
    local char = GetCharacter()
    
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or 
               obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("Attachment") then
                obj:Destroy()
            end
        end
    end
    
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    print("[Stand] LoopKill detenido")
end

local function StartLoopFling(target)
    if Flinging then StopLoopFling() end
    if not target or not target.Character then return end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    Flinging = true
    CurrentTarget = target
    
    print("[Stand] LoopKill iniciado: " .. target.Name)
    
    local hrp = GetHRP()
    if not hrp then return end
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp
    
    local alignPos = Instance.new("AlignPosition")
    alignPos.MaxForce = FLING_POWER * 100
    alignPos.Responsiveness = 200
    alignPos.Attachment0 = attachment
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Parent = hrp
    
    local alignOri = Instance.new("AlignOrientation")
    alignOri.MaxTorque = FLING_POWER * 100
    alignOri.Responsiveness = 200
    alignOri.Attachment0 = attachment
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Parent = hrp
    
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not Flinging or not CurrentTarget or not CurrentTarget.Character then
            StopLoopFling()
            return
        end
        
        local tHRP = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        local tHum = CurrentTarget.Character:FindFirstChild("Humanoid")
        
        if not tHRP or not tHum or tHum.Health <= 0 then
            print("[Stand] Objetivo muerto o perdido")
            StopLoopFling()
            return
        end
        
        local randomPos = tHRP.Position + Vector3.new(
            math.random(-20, 20),
            math.random(-10, 30),
            math.random(-20, 20)
        )
        
        alignPos.Position = randomPos
        alignOri.CFrame = CFrame.new(randomPos) * CFrame.Angles(
            math.random(-3, 3),
            math.random(-3, 3),
            math.random(-3, 3)
        )
        
        hrp.AssemblyLinearVelocity = Vector3.new(
            math.random(-5000, 5000),
            math.random(-5000, 5000),
            math.random(-5000, 5000)
        )
    end)
    
    task.spawn(function()
        while Flinging and CurrentTarget do
            task.wait(0.5)
            if not CurrentTarget.Character then
                StopLoopFling()
                break
            end
            local th = CurrentTarget.Character:FindFirstChild("Humanoid")
            if not th or th.Health <= 0 then
                StopLoopFling()
                break
            end
        end
    end)
end

-- VOID
local function VoidPlayer(target)
    if not target or not target.Character then return end
    
    print("[Stand] Enviando al vacío: " .. target.Name)
    
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        tHRP.AssemblyLinearVelocity = Vector3.new(0, -10000, 0)
        tHRP.CFrame = CFrame.new(0, VOID_DEPTH, 0)
    end
    
    task.wait(0.1)
    StopLoopFling()
end

-- FALL
local function FallAll()
    print("[Stand] Activando FALL para todos...")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if IsWhitelisted(player.Name) then continue end
        
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 1000, 0)
                task.delay(0.5, function()
                    if hrp then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
                    end
                end)
            end
        end
    end
end

-- BRING
local function BringStand()
    StopOrbit()
    StopLoopFling()
    
    local owner = GetOwner()
    local hrp = GetHRP()
    
    if owner and owner.Character and hrp then
        local ownerPos = owner.Character:GetPivot().Position
        hrp.CFrame = CFrame.new(ownerPos + Vector3.new(0, 5, 3))
        print("[Stand] Stand traído al owner")
    end
end

-- WHITELIST
local function AddWhitelist(name)
    local player = GetPlayer(name)
    if player then
        Whitelist[player.Name:lower()] = true
        print("[Stand] Agregado a whitelist: " .. player.Name)
    else
        Whitelist[name:lower()] = true
        print("[Stand] Agregado a whitelist (offline): " .. name)
    end
end

local function RemoveWhitelist(name)
    local key = name:lower()
    if Whitelist[key] then
        Whitelist[key] = nil
        print("[Stand] Removido de whitelist: " .. name)
    end
end

-- COMANDOS
local function ProcessCommand(msg, sender)
    local senderName = sender.Name:lower()
    
    if senderName ~= OwnerName and not IsWhitelisted(sender.Name) then
        return
    end
    
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 or args[1]:sub(1, 1) ~= Prefix then return end
    
    local cmd = args[1]:sub(2):lower()
    
    if cmd == "lk" and args[2] then
        local target = GetPlayer(args[2])
        if target then StartLoopFling(target) end
    elseif cmd == "unlk" then
        StopLoopFling()
    elseif cmd == "v" and args[2] then
        local target = GetPlayer(args[2])
        if target then VoidPlayer(target) end
    elseif cmd == "b" then
        BringStand()
    elseif cmd == "wl" and args[2] then
        AddWhitelist(args[2])
    elseif cmd == "unwl" and args[2] then
        RemoveWhitelist(args[2])
    elseif cmd == "fall" then
        FallAll()
    elseif cmd == "orbit" then
        StartOrbit()
    elseif cmd == "unorbit" then
        StopOrbit()
    end
end

-- CONEXIONES DE CHAT
for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end

Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    if Orbiting then
        StartOrbit()
    end
end)

task.delay(1, StartOrbit)

print("[STAND] Creado e iniciado correctamente con distancia extendida.")
