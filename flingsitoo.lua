getgenv().Script = "standd"
getgenv().Owner = "wrnqzc" -- Tu username aquí

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- Variables
local OwnerName = getgenv().Owner:lower()
local Prefix = "."
local Whitelist = {}
local Flinging = false
local Orbiting = false
local CurrentTarget = nil
local OrbitConnection = nil
local FlingConnection = nil
local ControlConnection = nil

-- Configuración
local ORBIT_RADIUS = 3500
local ORBIT_HEIGHT = 150
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

-- CONTROLES
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

-- ÓRBITA
local function StartOrbit()
    if Orbiting then return end
    Orbiting = true
    
    print("[Stand] Órbita iniciada...")
    BlockControls()
    
    local angle = math.random() * math.pi * 2
    
    OrbitConnection = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        local owner = GetOwner()
        
        if not hrp then return end
        
        local targetPos = Vector3.zero
        if owner and owner.Character then
            local ownerHRP = owner.Character:FindFirstChild("HumanoidRootPart")
            if ownerHRP then
                targetPos = ownerHRP.Position
            end
        end
        
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

-- FLING / LOOPKILL
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
    
    print("[Stand] Fling detenido")
end

local function StartLoopFling(target)
    if Flinging then StopLoopFling() end
    if not target or not target.Character then return end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    Flinging = true
    CurrentTarget = target
    
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
end

-- VOID
local function VoidPlayer(target)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        tHRP.AssemblyLinearVelocity = Vector3.new(0, -10000, 0)
        tHRP.CFrame = CFrame.new(0, VOID_DEPTH, 0)
    end
    task.wait(0.1)
    StopLoopFling()
end

-- BRING
local function BringStand()
    StopOrbit()
    StopLoopFling()
    
    local owner = GetOwner()
    local hrp = GetHRP()
    
    if owner and owner.Character and hrp then
        local ownerHRP = owner.Character:FindFirstChild("HumanoidRootPart")
        if ownerHRP then
            hrp.CFrame = CFrame.new(ownerHRP.Position + Vector3.new(0, 5, 3))
        end
    end
end

-- COMANDOS DE PROCESAMIENTO
local function ProcessCommand(msg, senderName)
    senderName = senderName:lower()
    
    if senderName ~= OwnerName and not Whitelist[senderName] then
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
        local player = GetPlayer(args[2])
        if player then Whitelist[player.Name:lower()] = true end
    elseif cmd == "unwl" and args[2] then
        Whitelist[args[2]:lower()] = nil
    elseif cmd == "orbit" then
        StartOrbit()
    elseif cmd == "unorbit" then
        StopOrbit()
    end
end

-- SISTEMA DE DETECCIÓN DE CHAT COMPATIBLE CON AMBOS SISTEMAS
local function RegisterPlayer(p)
    p.Chatted:Connect(function(m) ProcessCommand(m, p.Name) end)
end

for _, p in ipairs(Players:GetPlayers()) do
    RegisterPlayer(p)
end
Players.PlayerAdded:Connect(RegisterPlayer)

-- Soporte para TextChatService (NUEVO CHAT DE ROBLOX)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(message)
        if message.TextSource then
            local senderPlayer = Players:GetPlayerByUserId(message.TextSource.UserId)
            if senderPlayer then
                ProcessCommand(message.Text, senderPlayer.Name)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Orbiting then
        StartOrbit()
    end
end)

task.delay(1, StartOrbit)
print("[STAND] Listo y ejecutado correctamente.")
