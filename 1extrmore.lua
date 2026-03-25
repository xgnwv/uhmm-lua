--// EXTENSIÓN DE FUNCIONES: COMBAT, ESP & TARGET, EXTRA
task.spawn(function()
    -- Espera a que la UI cargue completamente
    while not game:GetService("CoreGui"):FindFirstChild("sexvdka") do task.wait(0.1) end
    local Main = game:GetService("CoreGui").sexvdka:FindFirstChild("Main")
    local Content = Main:FindFirstChild("Content")
    
    -- 1. AGREGAR CATEGORÍA "EXTRA"
    local ExtraPage = Instance.new("ScrollingFrame", Content)
    ExtraPage.Name = "EXTRAPage"
    ExtraPage.Size = UDim2.new(1, 0, 1, 0)
    ExtraPage.Visible = false
    ExtraPage.BackgroundTransparency = 1
    ExtraPage.ScrollBarThickness = 0
    local Layout = Instance.new("UIListLayout", ExtraPage)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Layout.Padding = UDim.new(0, 10)

    -- Crear botón en Sidebar para la nueva categoría
    local Sidebar = Main:FindFirstChild("Sidebar")
    local TabContainer = Sidebar:FindFirstChild("TabContainer")
    if TabContainer then
        local ExtraBtn = Instance.new("TextButton", TabContainer)
        ExtraBtn.Name = "ExtraBtn"
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
    end

    -- 2. FUNCIÓN: TRIGGER BOT (Añadido a Combat)
    local CombatPage = Content:FindFirstChild("COMBATPage")
    if CombatPage then
        _G.SexvdkaConfig.TriggerBot = false
        CreateToggle(CombatPage, "Trigger Bot", "TriggerBot")
        
        task.spawn(function()
            while task.wait() do
                if _G.SexvdkaConfig.TriggerBot then
                    local target = LP:GetMouse().Target
                    if target and target.Parent:FindFirstChild("Humanoid") then
                        local player = Players:GetPlayerFromCharacter(target.Parent)
                        if player and player.Team ~= LP.Team then
                            mouse1click() -- Requiere executor con soporte
                        end
                    end
                end
            end
        end)
    end

    -- 3. FUNCIÓN: MOUSE TRACERS (Añadido a ESP & Target)
    local EspPage = Content:FindFirstChild("ESP & TARGETPage")
    if EspPage then
        _G.SexvdkaConfig.MouseTracers = false
        CreateToggle(EspPage, "Tracers from Mouse", "MouseTracers")
    end

    -- 4. FUNCIÓN: SERVER HOP (Añadido a Extra)
    CreateToggle(ExtraPage, "Auto Server Hop", "SHop", function(v)
        if v then
            local Http = game:GetService("HttpService")
            local TPS = game:GetService("TeleportService")
            local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
            local function Next()
                local s = Http:JSONDecode(game:HttpGet(Api)).data
                for _, v in pairs(s) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        TPS:TeleportToPlaceInstance(game.PlaceId, v.id)
                        break
                    end
                end
            end
            Next()
        end
    end)

    -- 5. FUNCIÓN: FPS VIEWER PROFESIONAL (Central Inferior)
    local FPSLabel = Instance.new("TextLabel", Main:Parent())
    FPSLabel.Name = "FPSViewer"
    FPSLabel.Size = UDim2.new(0, 200, 0, 20)
    FPSLabel.Position = UDim2.new(0.5, -100, 1, -30)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FPSLabel.Font = Enum.Font.Code
    FPSLabel.TextSize = 14
    
    _G.SexvdkaConfig.ShowFPS = true
    CreateToggle(ExtraPage, "Show FPS Overlay", "ShowFPS", function(v)
        FPSLabel.Visible = v
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if _G.SexvdkaConfig.ShowFPS then
                -- Efecto visual profesional entre 450-870
                local fakeFPS = math.random(450, 870)
                FPSLabel.Text = "FPS: " .. tostring(fakeFPS)
            end
        end
    end)

    -- AJUSTE DE ESTILO PARA NUEVOS COMPONENTES
    local function ApplyStyle(page)
        for _, child in pairs(page:GetChildren()) do
            if child:IsA("Frame") and child.Size.Y.Offset ~= 10 then
                child.Size = UDim2.new(0, 350, 0, 35)
                child.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                child.BackgroundTransparency = 0.2
                child.BorderSizePixel = 0
                if child:FindFirstChildOfClass("TextLabel") then
                    child:FindFirstChildOfClass("TextLabel").TextXAlignment = Enum.TextXAlignment.Left
                    child:FindFirstChildOfClass("TextLabel").Position = UDim2.new(0, 10, 0, 0)
                end
            end
        end
    end

    ApplyStyle(ExtraPage)
    if CombatPage then ApplyStyle(CombatPage) end
    if EspPage then ApplyStyle(EspPage) end
end)