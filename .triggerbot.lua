task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local Mouse = LP:GetMouse()
    local Camera = workspace.CurrentCamera
    
    repeat task.wait(0.5) until game:GetService("CoreGui"):FindFirstChild("sexvdka") and _G.SexvdkaConfig
    
    local Main = game:GetService("CoreGui").sexvdka:FindFirstChild("Main")
    local CombatPage = Main.Content:FindFirstChild("COMBATPage")
    
    _G.SexvdkaConfig.TriggerBot = false
    _G.SexvdkaConfig.RapidFire = false
    _G.SexvdkaConfig.TriggerDelay = 0.02
    _G.SexvdkaConfig.TeamCheck = true
    _G.SexvdkaConfig.WallCheck = true
    
    if CombatPage then
        local function AddCombatToggle(text, configKey)
            local T = CreateToggle(CombatPage, text, configKey)
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
        
        CreateSlider(CombatPage, "Trigger Speed", 1, 100, "TriggerDelay", function(val)
            _G.SexvdkaConfig.TriggerDelay = val / 1000
        end)
    end

    local function IsVisible(targetPart)
        if not _G.SexvdkaConfig.WallCheck then
            return true
        end
        
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
        local VIM = game:GetService("VirtualInputManager")

        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
        
        task.wait(math.random(10, 30) / 1000) 
        
        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
    end

    local isShooting = false
    
    RunService.Heartbeat:Connect(function()
        if not _G.SexvdkaConfig.TriggerBot then
            return
        end

        if isShooting then
            return
        end
        
        local target = Mouse.Target

        if target and target.Parent then
            local char = target.Parent
            local hum = char:FindFirstChildOfClass("Humanoid") or char.Parent:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local player = Players:GetPlayerFromCharacter(hum.Parent)
                
                local canShoot = true

                if _G.SexvdkaConfig.TeamCheck and player and player.Team == LP.Team then
                    canShoot = false
                end
                
                if player == LP then
                    canShoot = false
                end
                
                if canShoot and IsVisible(target) then
                    isShooting = true
                    
                    if _G.SexvdkaConfig.RapidFire then
                        repeat
                            ExecuteClick()

                            task.wait(_G.SexvdkaConfig.TriggerDelay + (math.random(-5, 5) / 1000))

                        until Mouse.Target ~= target
                            or not _G.SexvdkaConfig.TriggerBot
                            or not _G.SexvdkaConfig.RapidFire
                    else
                        ExecuteClick()
                        task.wait(0.15)
                    end
                    
                    isShooting = false
                end
            end
        end
    end)
end)
