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

-- Configuración
local ORBIT_RADIUS = 700
local ORBIT_HEIGHT = 50
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
    
    -- Bloquear input
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

-- ORBITA ULTRA-RÁPIDA (NUNCA SE DETIENE)
local function StartOrbit()
    if Orbiting then return end
    Orbiting = true
    
    print("[Stand] Iniciando órbita ULTRA...")
    BlockControls()
    
    local angle = math.random() * math.pi * 2
    
    OrbitConnection = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        local owner = GetOwner()
        
        if not hrp then return end
        if not owner or not owner.Character then
            -- Si no hay owner, orbitar alrededor de 0,0,0
            local radius = ORBIT_RADIUS + math.random(-100, 100)
            angle = angle + 0.15 -- Velocidad EXTREMA
            
            local pos = Vector3.new(
                math.cos(angle) * radius,
                ORBIT_HEIGHT + math.random(-30, 100),
                math.sin(angle) * radius
            )
            
            hrp.CFrame = CFrame.new(pos)
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            return
        end
        
        local ownerPos = owner.Character:GetPivot().Position
        
        -- Velocidad EXTREMA + aleatoriedad
        angle = angle + (math.random() * 0.2 - 0.05)
        local radius = ORBIT_RADIUS + math.random(-150, 150)
        
        local offset = Vector3.new(
            math.cos(angle) * radius,
            math.random(-50, 150),
            math.sin(angle) * radius
        )
        
        local targetPos = ownerPos + offset
        
        -- Teletransporte instantáneo (sin tween, máxima velocidad)
        hrp.CFrame = CFrame.new(targetPos, ownerPos)
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        
        -- Anti-muerte por caída
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

-- FLING 100% EFECTIVO (LOOP KILL)
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
    
    -- Crear anclaje invisible
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
        
        -- FLING ULTRA AGRESIVO
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
        
        -- Velocidad de choque
        hrp.Velocity = Vector3.new(
            math.random(-5000, 5000),
            math.random(-5000, 5000),
            math.random(-5000, 5000)
        )
        
        -- Hacer daño constante
        tHum:TakeDamage(0.5)
    end)
    
    -- Hilo de verificación
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
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end
    
    print("[Stand] LoopKill detenido")
end

-- VOID (último fling antes)
local function VoidPlayer(target)
    if not target or not target.Character then return end
    
    print("[Stand] Enviando al vacío: " .. target.Name)
    
    -- Fling final antes del void
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        tHRP.Velocity = Vector3.new(0, -10000, 0)
        tHRP.CFrame = CFrame.new(0, VOID_DEPTH, 0)
    end
    
    task.wait(0.1)
    StopLoopFling()
    
    local hum = target.Character:FindFirstChild("Humanoid")
    if hum then hum.Health = 0 end
end

-- FALL (todos menos whitelist y owner)
local function FallAll()
    print("[Stand] Activando FALL para todos...")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if IsWhitelisted(player.Name) then 
            print("[Stand] Saltando whitelisted: " .. player.Name)
            continue 
        end
        
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Lanzar al aire y dejar caer
                hrp.Velocity = Vector3.new(0, 1000, 0)
                task.delay(0.5, function()
                    if hrp then
                        hrp.Velocity = Vector3.new(0, -5000, 0)
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
        -- Agregar por nombre directo si no está en servidor
        Whitelist[name:lower()] = true
        print("[Stand] Agregado a whitelist (offline): " .. name)
    end
end

local function RemoveWhitelist(name)
    local key = name:lower()
    if Whitelist[key] then
        Whitelist[key] = nil
        print("[Stand] Removido de whitelist: " .. name)
    else
        print("[Stand] No estaba en whitelist: " .. name)
    end
end

-- PROCESAR COMANDOS
local function ProcessCommand(msg, sender)
    local senderName = sender.Name:lower()
    
    -- Verificar permisos (owner o whitelist)
    if senderName ~= OwnerName and not IsWhitelisted(sender.Name) then
        return
    end
    
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 or args[1]:sub(1, 1) ~= Prefix then return end
    
    local cmd = args[1]:sub(2):lower()
    
    -- COMANDOS
    if cmd == "lk" and args[2] then -- LoopKill
        local target = GetPlayer(args[2])
        if target then StartLoopFling(target) end
        
    elseif cmd == "unlk" then -- UnLoopKill
        StopLoopFling()
        
    elseif cmd == "v" and args[2] then -- Void
        local target = GetPlayer(args[2])
        if target then VoidPlayer(target) end
        
    elseif cmd == "b" then -- Bring
        BringStand()
        
    elseif cmd == "wl" and args[2] then -- Whitelist
        AddWhitelist(args[2])
        
    elseif cmd == "unwl" and args[2] then -- UnWhitelist
        RemoveWhitelist(args[2])
        
    elseif cmd == "fall" then -- Fall (todos menos whitelist)
        FallAll()
        
    elseif cmd == "orbit" then -- Iniciar órbita
        StartOrbit()
        
    elseif cmd == "unorbit" then -- Detener órbita
        StopOrbit()
        
    elseif cmd == "kill" and args[2] then -- Kill rápido
        local target = GetPlayer(args[2])
        if target and target.Character then
            local hum = target.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end

-- CONEXIONES
for _, p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end

Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    if Orbiting then
        StartOrbit()
    end
end)

-- Iniciar órbita automáticamente
task.delay(1, StartOrbit)

-- Anti-AFK
game:GetService("VirtualUser").Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.zero, Workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.zero, Workspace.CurrentCamera.CFrame)
end)

print("╔════════════════════════════════════╗")
print("║      [STAND] Sistema Activado      ║")
print("╠════════════════════════════════════╣")
print("║ Owner: " .. string.format("%-26s", getgenv().Owner) .. "║")
print("║ Modo: ÓRBITA ULTRA-RÁPIDA           ║")
print("║ Estado: INMORTAL + ANTIBLOQUEO      ║")
print("╠════════════════════════════════════╣")
print("║ COMANDOS:                          ║")
print("║ .lk nombre  = LoopKill (fling)     ║")
print("║ .unlk       = Detener LoopKill      ║")
print("║ .v nombre   = Void + fling final   ║")
print("║ .b          = Traer stand           ║")
print("║ .wl nombre  = Agregar whitelist    ║")
print("║ .unwl nombre= Quitar whitelist     ║")
print("║ .fall       = Caer a todos (-wl)   ║")
print("║ .orbit      = Iniciar órbita       ║")
print("║ .unorbit    = Detener órbita       ║")
print("╚════════════════════════════════════╝")