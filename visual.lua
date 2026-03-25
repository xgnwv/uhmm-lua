--// Función para esperar a que la UI cargue y evitar el error de 'nil'
local function applyCustomMin()
    -- Esperamos máximo 5 segundos a que la ventana 'Minimized' exista
    local count = 0
    while not _G.SexvdkaConfig or not game:GetService("CoreGui"):FindFirstChild("sexvdka") do
        task.wait(0.1)
        count = count + 0.1
        if count > 5 then return end -- Si tarda demasiado, cancela para no trabar el juego
    end

    local ScreenGui = game:GetService("CoreGui"):FindFirstChild("sexvdka")
    local Minimized = ScreenGui:FindFirstChild("Minimized")
    local MinLabel = Minimized:FindFirstChild("MinLabel")
    local MinStroke = Minimized:FindFirstChild("UIStroke")

    if Minimized and MinLabel then
        --// Configuración de Imagen y Tamaño
        local MinimizedSize = UDim2.new(0, 160, 0, 50)
        Minimized.Size = MinimizedSize
        Minimized.Position = UDim2.new(0.5, -80, 0.05, 0)

        local MinImage = Instance.new("ImageLabel", Minimized)
        MinImage.Name = "CustomBackground"
        MinImage.Size = UDim2.new(1, 0, 1, 0)
        MinImage.Image = "rbxassetid://135353505866584"
        MinImage.BackgroundTransparency = 1
        MinImage.ZIndex = 1
        MinImage.ScaleType = Enum.ScaleType.Crop
        MinImage.ResampleMode = Enum.ResamplerMode.Pixelated 
        Instance.new("UICorner", MinImage).CornerRadius = UDim.new(0, 8)

        --// Limpieza Visual
        if MinStroke then MinStroke:Destroy() end
        MinLabel.Text = "" 
        Minimized.BackgroundTransparency = 1 
        MinLabel.ZIndex = 2 
        MinLabel.Size = UDim2.new(1, 0, 1, 0)
    end
end

-- Ejecutamos la función de forma independiente
task.spawn(applyCustomMin)
