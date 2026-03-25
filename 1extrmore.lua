--// EXTENSIÓN MODULAR (PLUGIN) - No rompe la base
task.spawn(function()
    -- Localizar servicios y variables de la base de forma segura
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    
    -- Espera a que la base esté lista
    repeat task.wait(0.5) until CoreGui:FindFirstChild("sexvdka") and _G.SexvdkaConfig
    
    local Main = CoreGui.sexvdka.Main
    local Content = Main.Content
    local TabContainer = Main.Sidebar.TabContainer

    -- 1. CREAR CATEGORÍA EXTRA
    local ExtraPage = Instance.new("ScrollingFrame", Content)
    ExtraPage.Name = "EXTRAPage"
    ExtraPage.Size = UDim2.new(1, 0, 1, 0)
    ExtraPage.Visible = false
    ExtraPage.BackgroundTransparency = 1
    ExtraPage.ScrollBarThickness = 0
    local Layout = Instance.new("UIListLayout", ExtraPage)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Layout.Padding = UDim.new(0, 10)

    -- Botón de la categoría
    local ExtraBtn = Instance.new("TextButton", TabContainer)
    ExtraBtn.Size = UDim2.new(0.8, 0, 0, 25)
    ExtraBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ExtraBtn.BackgroundTransparency = 0.3
    ExtraBtn.Text = "EXTRA"
    ExtraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExtraBtn.Font = Enum.Font.GothamMedium
    ExtraBtn.TextSize = 10
    Instance.new("UICorner", ExtraBtn)

    ExtraBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Content:GetChildren()) do if p:IsA("ScrollingFrame") then p.Visible = false end end
        ExtraPage.Visible = true
    end)

    -- 2. TRIGGER BOT & RAPID FIRE (Combat)
    local CombatPage = Content:FindFirstChild("COMBATPage")
    if CombatPage then
        _G.SexvdkaConfig.TriggerBot = false
        _G.SexvdkaConfig.RapidFire = false
        CreateToggle(CombatPage, "Trigger Bot", "TriggerBot")
        CreateToggle(CombatPage, "Rapid Fire (Clicks)", "RapidFire")
        
        task.spawn(function()
            while task.wait() do
                if _G.SexvdkaConfig.TriggerBot then
                    local target = LP:GetMouse().Target
                    if target and target.Parent:FindFirstChild("Humanoid") then
                        local p = Players:GetPlayerFromCharacter(target.Parent)
                        if p and p.Team ~= LP.Team then
                            mouse1click()
                            if _G.SexvdkaConfig.RapidFire then task.wait(0.01) end
                        end
                    end
                end
            end
        end)
    end

    -- 3. MOUSE TRACERS (Visuals/ESP)
    local EspPage = Content:FindFirstChild("ESP & TARGETPage")
    if EspPage then
        _G.SexvdkaConfig.MouseTracers = false
        CreateToggle(EspPage, "Tracers from Mouse", "MouseTracers")
        
        -- Inyección de lógica en el bucle de renderizado
        RunService.RenderStepped:Connect(function()
            if _G.SexvdkaConfig.EspEnabled and _G.SexvdkaConfig.MouseTracers then
                _G.SexvdkaConfig.CustomOrigin = UIS:GetMouseLocation()
            else
                _G.SexvdkaConfig.CustomOrigin = nil
            end
        end)
    end

    -- 4. SERVER HOP (Extra)
    CreateToggle(ExtraPage, "Server Hop", "SHop", function(v)
        if v then
            local Http = game:GetService("HttpService")
            local TPS = game:GetService("TeleportService")
            local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
            local servers = Http:JSONDecode(game:HttpGet(Api)).data
            for _, s in pairs(servers) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                end
            end
        end
    end)

    -- 5. FPS PROFESIONAL (Natural/Visual)
    local FPSLabel = Instance.new("TextLabel", CoreGui.sexvdka)
    FPSLabel.Size = UDim2.new(0, 200, 0, 20)
    FPSLabel.Position = UDim2.new(0.5, -100, 1, -40)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FPSLabel.Font = Enum.Font.Code
    FPSLabel.TextSize = 14
    FPSLabel.Visible = false

    _G.SexvdkaConfig.ShowFPS = false
    CreateToggle(ExtraPage, "Show FPS Overlay", "ShowFPS", function(v) FPSLabel.Visible = v end)

    task.spawn(function()
        while task.wait(math.random(3, 7)/10) do
            if _G.SexvdkaConfig.ShowFPS then
                FPSLabel.Text = "FPS: " .. math.random(450, 870)
            end
        end
    end)

    -- AJUSTE AUTOMÁTICO DE ESTILO
    local function Fix(p)
        for _, c in pairs(p:GetChildren()) do
            if c:IsA("Frame") and c.Size.Y.Offset ~= 10 then
                c.Size = UDim2.new(0, 350, 0, 35)
                c.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                c.BackgroundTransparency = 0.2
            end
        end
    end
    Fix(ExtraPage)
end)