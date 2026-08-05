getgenv().Owner = "wrnqzc"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local OwnerName = getgenv().Owner:lower()
local Whitelist = {}
local Prefix = "."

local FlingActive = false
local FlingTarget = nil
local BodyThrust = nil

-- Busqueda inteligente (nombre o apodo parcial)
local function FindPlayer(partial)
    if not partial then return nil end
    partial = partial:lower()
    
    for _, p in pairs(Players:GetPlayers()) do
        local name = (p.Name or ""):lower()
        local display = (p.DisplayName or ""):lower()
        
        -- Coincidencia parcial en nombre o apodo
        if name:find(partial, 1, true) or display:find(partial, 1, true) then
            return p
        end
    end
    return nil
end

local function GetChar()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsWL(name)
    if not name then return false end
    return Whitelist[name:lower()] == true or name:lower() == OwnerName
end

-- ORBITA CAMUFLADA (Cielo alto + movimiento aleatorio)
local function StartRandomOrbit()
    spawn(function()
        while true do
            wait(0.1)
            
            local hrp = GetHRP()
            if not hrp then continue end
            
            -- Altura muy alta (cielo) + variacion aleatoria
            local height = 2000 + math.random(-500, 500)
            
            -- Movimiento completamente aleatorio (no circular)
            local x = math.random(-3000, 3000)
            local z = math.random(-3000, 3000)
            
            -- Pequeña variacion de posicion (movimiento erratico)
            local current = hrp.Position
            local newPos = Vector3.new(
                current.X + math.random(-50, 50),
                height + math.random(-100, 100),
                current.Z + math.random(-50, 50)
            )
            
            -- Limites para no irse muy lejos
            if math.abs(newPos.X) > 5000 then newPos = Vector3.new(math.random(-1000, 1000), newPos.Y, newPos.Z) end
            if math.abs(newPos.Z) > 5000 then newPos = Vector3.new(newPos.X, newPos.Y, math.random(-1000, 1000)) end
            
            hrp.CFrame = CFrame.new(newPos)
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- FLING (BodyThrust)
local function StartFling(target)
    if not target then return end
    if FlingActive then StopFling() end
    
    FlingActive = true
    FlingTarget = target
    
    print("[STAND] Fling: " .. target.Name)
    
    local hrp = GetHRP()
    if not hrp then return end
    
    -- Desactivar colisiones
    spawn(function()
        while FlingActive do
            wait()
            local c = GetChar()
            if not c then break end
            
            for _, part in pairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    -- BodyThrust
    BodyThrust = Instance.new("BodyThrust")
    BodyThrust.Force = Vector3.new(999999, 0, 999999)
    BodyThrust.Location = hrp.Position
    BodyThrust.Parent = hrp
    
    -- Seguimiento del target
    spawn(function()
        while FlingActive and FlingTarget do
            wait(0.1)
            
            if not FlingActive then break end
            
            local tChar = FlingTarget.Character
            if not tChar then 
                print("[STAND] Target perdido")
                StopFling()
                break
            end
            
            local tHum = tChar:FindFirstChild("Humanoid")
            if tHum and tHum.Health <= 0 then
                print("[STAND] Target muerto")
                StopFling()
                break
            end
            
            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
            local hrp = GetHRP()
            
            if tHRP and hrp and BodyThrust then
                BodyThrust.Location = tHRP.Position
                -- Acercarse para tocar
                hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end)
end

local function StopFling()
    FlingActive = false
    FlingTarget = nil
    
    if BodyThrust then
        BodyThrust:Destroy()
        BodyThrust = nil
    end
    
    -- Reactivar colisiones
    local c = GetChar()
    if c then
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    print("[STAND] Fling detenido")
end

-- FALL (todos menos WL)
local function FallAll()
    print("[STAND] FALL")
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if IsWL(p.Name) then continue end
        
        local char = p.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 5000, 0)
            
            spawn(function()
                wait(0.5)
                if hrp then
                    hrp.Velocity = Vector3.new(0, -20000, 0)
                end
            end)
        end
    end
end

-- WHITELIST
local function AddWL(name)
    local target = FindPlayer(name)
    if target then
        Whitelist[target.Name:lower()] = true
        print("[STAND] WL: " .. target.Name)
    else
        Whitelist[name:lower()] = true
        print("[STAND] WL (offline): " .. name)
    end
end

local function RemoveWL(name)
    local target = FindPlayer(name)
    if target then
        Whitelist[target.Name:lower()] = nil
        print("[STAND] UnWL: " .. target.Name)
    else
        Whitelist[name:lower()] = nil
        print("[STAND] UnWL: " .. name)
    end
end

-- COMANDOS
local function ProcessCommand(msg, sender)
    if not sender then return end
    
    local sName = sender.Name:lower()
    if sName ~= OwnerName and not IsWL(sender.Name) then
        return
    end
    
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then return end
    if args[1]:sub(1, 1) ~= Prefix then return end
    
    local cmd = args[1]:sub(2):lower()
    local arg2 = args[2]
    
    if cmd == "lk" and arg2 then
        local t = FindPlayer(arg2)
        if t then 
            StartFling(t)
        else
            print("[STAND] No encontrado: " .. arg2)
        end
        
    elseif cmd == "unlk" then
        StopFling()
        
    elseif cmd == "wl" and arg2 then
        AddWL(arg2)
        
    elseif cmd == "unwl" and arg2 then
        RemoveWL(arg2)
        
    elseif cmd == "fall" then
        FallAll()
    end
end

-- CONEXIONES
for _, p in pairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end

Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(m) ProcessCommand(m, p) end)
end)

-- INICIAR
StartRandomOrbit()

print("=== STAND ===")
print("Owner: " .. getgenv().Owner)
print("Orbita: Cielo alto + aleatorio")
print("Comandos: .lk .unlk .wl .unwl .fall")
