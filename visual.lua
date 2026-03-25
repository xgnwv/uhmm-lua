--// Configuración de Imagen con Tamaño Ajustado (Más ancho y largo)
local MinimizedSize = UDim2.new(0, 160, 0, 50) -- Ajuste de ancho (160) y largo (50)
Minimized.Size = MinimizedSize
Minimized.Position = UDim2.new(0.5, -80, 0.05, 0) -- Centrado corregido para el nuevo ancho

local MinImage = Instance.new("ImageLabel", Minimized)
MinImage.Name = "CustomBackground"
MinImage.Size = UDim2.new(1, 0, 1, 0)
MinImage.Image = "rbxassetid://135353505866584"
MinImage.BackgroundTransparency = 1
MinImage.ZIndex = 1
MinImage.ScaleType = Enum.ScaleType.Crop -- Corta los bordes para mantener proporción perfecta
MinImage.ResampleMode = Enum.ResamplerMode.Pixelated 
Instance.new("UICorner", MinImage).CornerRadius = UDim.new(0, 8)

--// Limpieza y Ajustes Finales
if MinStroke then MinStroke:Destroy() end
MinLabel.Text = "" 
Minimized.BackgroundTransparency = 1 
MinLabel.ZIndex = 2 

-- Opcional: Si quieres que el botón de maximizar cubra todo el nuevo tamaño
MinLabel.Size = UDim2.new(1, 0, 1, 0)