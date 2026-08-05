getgenv().Script = "standd"
getgenv().Owner = "wrnqzc" -- Tu username aquí

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Variables
local OwnerName = string.lower(getgenv().Owner or "")
local Prefix = "."
local Whitelist = {}
local Flinging = false
local Orbiting = false
local CurrentTarget = nil
local OrbitConnection = nil
local FlingConnection = nil
local ControlConnection = nil

-- Configuración AUMENTADA
local ORBIT_RADIUS = 3000 -- Mucho más lejos
local ORBIT_HEIGHT = 100
local VOID_DEPTH = -50000
local FLING_POWER = 999999

-- Función segura para obtener character
local function GetChar(player)
    if not player then player = LocalPlayer end
    return player.Character
end

local function GetHRP(player)
    local char = GetChar(player)
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function GetHum(player)
    local char = GetChar(player)
    if char then
        return char:FindFirstChild("Humanoid")
    end
    return nil
end

-- Buscar owner
local function GetOwnerPlayer()
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == OwnerName then
            return p
        end
    end
    return nil
end

-- Verificar whitelist
local function IsWL(name)
    if not name then return false end
    local n = string.lower(name)
    return n == OwnerName or Whitelist[n] == true
end

-- Buscar jugador (versión segura)
local function FindPlayer(partial)
    if not partial or partial == "" then return nil end
    partial = string.lower(partial)
    
    for _, p in ipairs(Players:GetPlayers()) do
        local nameLower = string.lower(p.Name)
        local displayLower = string.lower(p.DisplayName)
        
        if string.sub(nameLower, 1, #partial) == partial or 
           string.sub(displayLower, 1, #partial) == partial then
            return p
        end
    end
    return nil
end

-- Bloquear controles completamente
local function BlockControls()
    if ControlConnection then return end
    
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.PlatformStand = true
    end
    
    ControlConnection = RunService.Heartbeat:Connect(function()
        local hum = GetHum()
        local hrp = GetHRP()
        
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end)
        end
        
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    end)
end

local function UnblockControls()
    if ControlConnection then
        ControlConnection:Disconnect()
        ControlConnection = nil
    end
    
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.PlatformStand = false
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

-- ORBITA ULTRA-RÁPIDA Y LEJOS (3000 studs)
local function StartOrbit()
    if Orbiting then return end
    Orbiting = true
    
    print("[Stand] Órbita 3000 studs iniciada...")
    BlockControls()
    
    local angle = math.random() * math.pi * 2
    
    OrbitConnection = RunService.Heartbeat:Connect(function()
        if not Orbiting then return end
        
        local hrp = GetHRP()
        if not hrp then return end
        
        local owner = GetOwnerPlayer()
        local centerPos
        
        if owner and GetHRP(owner) then
            centerPos = GetHRP(owner).Position
        else
            -- Si no hay owner, orbitar alrededor de spawn
            centerPos = Vector3.new(0, 100, 0)
        end
        
        -- Velocidad EXTREMA
        angle = angle + 0.3
        
        -- Radio variable 3000 studs
        local radius = ORBIT_RADIUS + math.random(-500, 500)
        local height = ORBIT_HEIGHT + math.random(-100, 300)
        
        local newPos = Vector3.new(
            centerPos.X + math.cos(angle) * radius,
            centerPos.Y + height,
            centerPos.Z + math.sin(angle) * radius
        )
        
        -- Teletransporte instantáneo
        hrp.CFrame = CFrame.new(newPos, centerPos)
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        
        -- Anti-muerte
        local hum = GetHum()
        if hum then
            hum.PlatformStand = true
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end)
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

-- Detener fling
local function StopFling()
    Flinging = false
    CurrentTarget = nil
    
    if FlingConnection then
        FlingConnection:Disconnect()
        FlingConnection = nil
    end
    
    local char = GetChar()
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or 
               obj:IsA("BodyPosition") or obj:IsA("AlignPosition") or 
               obj:IsA("AlignOrientation") or obj:IsA("Attachment") then
                obj:Destroy()
            end
        end
    end
    
    local hrp = GetHRP()
    if hrp then
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end
end

-- FLING 100% EFECTIVO (LoopKill)
local function StartFling(target)
    if Flinging then StopFling() end
    if not target then return end
    
    local tChar = GetChar(target)
    if not tChar then return end
    
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    
    Flinging = true
    CurrentTarget = target
    
    print("[Stand] LoopKill: " .. target.Name)
    
    local hrp = GetHRP()
    local hum = GetHum()
    if not hrp then return end
    
    -- Crear attachments y align
    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = hrp
    
    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attachment0
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.MaxForce = FLING_POWER
    alignPos.Responsiveness = 200
    alignPos.Parent = hrp
    
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Attachment0 = attachment0
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.MaxTorque = FLING_POWER
    alignOri.Responsiveness = 200
    alignOri.Parent = hrp
    
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not Flinging or not CurrentTarget then
            StopFling()
            return
        end
        
        local tChar = GetChar(CurrentTarget)
        if not tChar then
            StopFling()
            return
        end
        
        local tHRP = tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar:FindFirstChild("Humanoid")
        
        if not tHRP or not tHum then
            StopFling()
            return
        end
        
        if tHum.Health <= 0 then
            print("[Stand] Objetivo eliminado")
            StopFling()
            return
        end
        
        -- FLING AGRESIVO
        local targetPos = tHRP.Position + Vector3.new(
            math.random(-30, 30),
            math.random(-20, 40),
            math.random(-30, 30)
        )
        
        alignPos.Position = targetPos
        alignOri.CFrame = CFrame.new(targetPos) * CFrame.Angles(
            math.random(-5, 5),
            math.random(-5, 5),
            math.random(-5, 5)
        )
        
        -- Daño constante
        pcall(function()
            tHum:TakeDamage(1)
        end)
    end)
    
    -- Verificador de muerte
    task.spawn(function()
        while Flinging and CurrentTarget do
            task.wait(0.3)
            if not CurrentTarget then break end
            
            local tChar = GetChar(CurrentTarget)
            if not tChar then
                StopFling()
                break
            end
            
            local tHum = tChar:FindFirstChild("Humanoid")
            if not tHum or tHum.Health <= 0 then
                StopFling()
                break
            end
        end
    end)
end

-- VOID
local function VoidPlayer(target)
    if not target then return end
    
    local tChar = GetChar(target)
    if not tChar then return end
    
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    
    print("[Stand] Void: " .. target.Name)
    
    -- Fling final
    tHRP.Velocity = Vector3.new(0, -50000, 0)
    tHRP.CFrame = CFrame.new(0, VOID_DEPTH, 0)
    
    task.wait(0.1)
    StopFling()
    
    local tHum = tChar:FindFirstChild("Humanoid")
    if tHum then
        tHum.Health = 0
    end
end

-- FALL (todos menos WL)
local function FallAll()
    print("[Stand] FALL activado")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if IsWL(player.Name) then continue end
        
        local pChar = GetChar(player)
        if not pChar then continue end
        
        local pHRP = pChar:FindFirstChild("HumanoidRootPart")
        if not pHRP then continue end
        
        -- Lanzar arriba y caer
        pHRP.Velocity = Vector3.new(0, 2000, 0)
        
        task.delay(0.5, function()
            if pHRP then
                pHRP.Velocity = Vector3.new(0, -10000, 0)
            end
        end)
    end
end

-- BRING
local function Bring()
    StopOrbit()
    StopFling()
    
    local owner = GetOwnerPlayer()
    local hrp = GetHRP()
    
    if owner and GetHRP(owner) and hrp then
        local ownerPos = GetHRP(owner).Position
        hrp.CFrame = CFrame.new(ownerPos + Vector3.new(0, 5, 5))
        print("[Stand] Traído al owner")
    end
end

-- WHITELIST
local function AddWL(name)
    if not name or name == "" then return end
    
    local target = FindPlayer(name)
    if target then
        Whitelist[string.lower(target.Name)] = true
        print("[Stand] WL agregado: " .. target.Name)
    else
        Whitelist[string.lower(name)] = true
        print("[Stand] WL agregado (offline): " .. name)
    end
end

local function RemoveWL(name)
    if not name or name == "" then return end
    local key = string.lower(name)
    
    if Whitelist[key] then
        Whitelist[key] = nil
        print("[Stand] WL removido: " .. name)
    else
        print("[Stand] No estaba en WL: " .. name)
    end
end

-- COMANDOS
local function ProcessCommand(msg, sender)
    if not sender then return end
    
    local senderName = string.lower(sender.Name)
    
    -- Verificar permisos
    if senderName ~= OwnerName and not IsWL(sender.Name) then
        return
    end
    
    -- Parsear args
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then return end
    if string.sub(args[1], 1, 1) ~= Prefix then return end
    
    local cmd = string.lower(string.sub(args[1], 2))
    local arg2 = args[2]
    
    -- EJECUTAR COMANDOS
    if cmd == "lk" and arg2 then
        local t = FindPlayer(arg2)
        if t then StartFling(t) end
        
    elseif cmd == "unlk" then
        StopFling()
        
    elseif cmd == "v" and arg2 then
        local t = FindPlayer(arg2)
        if t then VoidPlayer(t) end
        
    elseif cmd == "b" then
        Bring()
        
    elseif cmd == "wl" and arg2 then
        AddWL(arg2)
        
    elseif cmd == "unwl" and arg2 then
        RemoveWL(arg2)
        
    elseif cmd == "fall" then
        FallAll()
        
    elseif cmd == "orbit" then
        StartOrbit()
        
    elseif cmd == "unorbit" then
        StopOrbit()
        
    elseif cmd == "kill" and arg2 then
        local t = FindPlayer(arg2)
        if t then
            local h = GetHum(t)
            if h then h.Health = 0 end
        end
    end
end

-- CONECTAR CHAT
for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(m)
        ProcessCommand(m, p)
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(m)
        ProcessCommand(m, p)
    end)
end)

-- RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Orbiting then
        StartOrbit()
    end
end)

-- ANTI-AFK
VirtualUser.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.zero, Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.zero, Workspace.CurrentCamera.CFrame)
end)

-- INICIAR ÓRBITA AUTOMÁTICO
task.delay(2, StartOrbit)

-- PRINT INFO
print("=== [STAND] Sistema Cargado ===")
print("Owner: " .. getgenv().Owner)
print("Radio: 3000 studs (ULTRA LEJOS)")
print("Comandos: .lk .unlk .v .b .wl .unwl .fall .orbit .unorbit")
print("===============================")
