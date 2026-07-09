local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "pulse.lol",
   LoadingTitle = "pulse.lol Loading",
   LoadingSubtitle = "by pulse",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "pulse"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- Tabs
local TabMain = Window:CreateTab("Main", 4483362458)
local TabVisuals = Window:CreateTab("Visuals", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)
local TabCredits = Window:CreateTab("Credits", 4483362458)

-- Variables
local aimEnabled = false
local teamCheck = false
local wallCheck = false
local aimPart = "Head"
local smoothness = 0.1
local fovRadius = 100
local fovVisible = false

local espEnabled = false
local espBox = false
local espName = false
local espDistance = false
local espHealth = false
local espSkeleton = false
local espColor = Color3.fromRGB(255, 255, 255)

local speedEnabled = false
local speedValue = 16
local jumpEnabled = false
local jumpValue = 50
local noclipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false
local flySpeed = 50

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Radius = fovRadius
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 1
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ESP Drawings
local espObjects = {}

-- FLY BODYVELOCITY
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Functions
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(aimPart) then
            if teamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local character = player.Character
            local part = character[aimPart]

            if wallCheck then
                local origin = Camera.CFrame.Position
                local direction = (part.Position - origin).Unit * 500
                local ray = Ray.new(origin, direction)
                local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
                if hitPart ~= part then
                    continue
                end
            end

            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude

                if distance < fovRadius and distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

local function aimAt(player)
    if player and player.Character and player.Character:FindFirstChild(aimPart) then
        local part = player.Character[aimPart]
        local aimPosition = part.Position
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPosition), smoothness)
    end
end

local function createESP(player)
    if espObjects[player] then return end

    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        health = Drawing.new("Text"),
        healthBar = Drawing.new("Line"),
        healthBarOutline = Drawing.new("Line"),
        skeleton = {}
    }

    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Color = espColor
    esp.box.Visible = false

    esp.name.Size = 13
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Color = espColor
    esp.name.Visible = false

    esp.distance.Size = 13
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Color = espColor
    esp.distance.Visible = false

    esp.health.Size = 13
    esp.health.Center = false
    esp.health.Outline = true
    esp.health.Color = Color3.fromRGB(0, 255, 0)
    esp.health.Visible = false

    esp.healthBar.Thickness = 2
    esp.healthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.healthBar.Visible = false

    esp.healthBarOutline.Thickness = 4
    esp.healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.healthBarOutline.Visible = false

    for i = 1, 15 do
        esp.skeleton[i] = Drawing.new("Line")
        esp.skeleton[i].Thickness = 1
        esp.skeleton[i].Color = espColor
        esp.skeleton[i].Visible = false
    end

    espObjects[player] = esp
end

local function removeESP(player)
    if espObjects[player] then
        local esp = espObjects[player]
        for key, drawing in pairs(esp) do
            if key == "skeleton" then
                for _, line in pairs(drawing) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() drawing:Remove() end)
            end
        end
        espObjects[player] = nil
    end
end

local function hideAllESP(esp)
    esp.box.Visible = false
    esp.name.Visible = false
    esp.distance.Visible = false
    esp.health.Visible = false
    esp.healthBar.Visible = false
    esp.healthBarOutline.Visible = false
    for _, line in pairs(esp.skeleton) do
        line.Visible = false
    end
end

local function updateESP()
    for player, esp in pairs(espObjects) do
        if not player or not player.Parent then
            removeESP(player)
            continue
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local humanoid = char.Humanoid
            local head = char.Head

            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen and espEnabled then
                local headPos, _ = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos, _ = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2

                -- Box ESP
                if espBox then
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = Vector2.new(screenPos.X - width / 2, headPos.Y)
                    esp.box.Color = espColor
                    esp.box.Visible = true
                else
                    esp.box.Visible = false
                end

                -- Name ESP
                if espName then
                    esp.name.Text = player.Name
                    esp.name.Position = Vector2.new(screenPos.X, headPos.Y - 15)
                    esp.name.Color = espColor
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end

                -- Distance ESP
                if espDistance then
                    local lchar = LocalPlayer.Character
                    if lchar and lchar:FindFirstChild("HumanoidRootPart") then
                        local dist = (lchar.HumanoidRootPart.Position - hrp.Position).Magnitude
                        esp.distance.Text = math.floor(dist) .. " studs"
                        esp.distance.Position = Vector2.new(screenPos.X, legPos.Y + 5)
                        esp.distance.Color = espColor
                        esp.distance.Visible = true
                    end
                else
                    esp.distance.Visible = false
                end

                -- Health ESP
                if espHealth then
                    local hp = humanoid.Health
                    local maxHp = humanoid.MaxHealth
                    local healthPercent = (maxHp > 0) and (hp / maxHp) or 0
                    local r = math.floor(255 * (1 - healthPercent))
                    local g2 = math.floor(255 * healthPercent)

                    esp.health.Text = math.floor(hp) .. " HP"
                    esp.health.Position = Vector2.new(screenPos.X - width / 2 - 40, headPos.Y)
                    esp.health.Color = Color3.fromRGB(r, g2, 0)
                    esp.health.Visible = true

                    local barHeight = height * healthPercent
                    local barX = screenPos.X - width / 2 - 6

                    esp.healthBarOutline.From = Vector2.new(barX, headPos.Y)
                    esp.healthBarOutline.To = Vector2.new(barX, legPos.Y)
                    esp.healthBarOutline.Visible = true

                    esp.healthBar.From = Vector2.new(barX, legPos.Y)
                    esp.healthBar.To = Vector2.new(barX, legPos.Y - barHeight)
                    esp.healthBar.Color = Color3.fromRGB(r, g2, 0)
                    esp.healthBar.Visible = true
                else
                    esp.health.Visible = false
                    esp.healthBar.Visible = false
                    esp.healthBarOutline.Visible = false
                end

                -- Skeleton ESP
                if espSkeleton then
                    local joints = {
                        {char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")},
                        {char:FindFirstChild("UpperTorso"), char:FindFirstChild("LowerTorso")},
                        {char:FindFirstChild("UpperTorso"), char:FindFirstChild("LeftUpperArm")},
                        {char:FindFirstChild("LeftUpperArm"), char:FindFirstChild("LeftLowerArm")},
                        {char:FindFirstChild("LeftLowerArm"), char:FindFirstChild("LeftHand")},
                        {char:FindFirstChild("UpperTorso"), char:FindFirstChild("RightUpperArm")},
                        {char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm")},
                        {char:FindFirstChild("RightLowerArm"), char:FindFirstChild("RightHand")},
                        {char:FindFirstChild("LowerTorso"), char:FindFirstChild("LeftUpperLeg")},
                        {char:FindFirstChild("LeftUpperLeg"), char:FindFirstChild("LeftLowerLeg")},
                        {char:FindFirstChild("LeftLowerLeg"), char:FindFirstChild("LeftFoot")},
                        {char:FindFirstChild("LowerTorso"), char:FindFirstChild("RightUpperLeg")},
                        {char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg")},
                        {char:FindFirstChild("RightLowerLeg"), char:FindFirstChild("RightFoot")},
                    }

                    for i = 1, #joints do
                        local joint = joints[i]
                        if joint[1] and joint[2] and esp.skeleton[i] then
                            local p1, os1 = Camera:WorldToViewportPoint(joint[1].Position)
                            local p2, os2 = Camera:WorldToViewportPoint(joint[2].Position)
                            if os1 and os2 then
                                esp.skeleton[i].From = Vector2.new(p1.X, p1.Y)
                                esp.skeleton[i].To = Vector2.new(p2.X, p2.Y)
                                esp.skeleton[i].Color = espColor
                                esp.skeleton[i].Visible = true
                            else
                                esp.skeleton[i].Visible = false
                            end
                        else
                            if esp.skeleton[i] then
                                esp.skeleton[i].Visible = false
                            end
                        end
                    end
                else
                    for _, line in pairs(esp.skeleton) do
                        line.Visible = false
                    end
                end
            else
                hideAllESP(esp)
            end
        else
            hideAllESP(esp)
        end
    end
end

-- Fly Setup
local function enableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Crée BodyVelocity
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.P = 1e4
    flyBodyVelocity.Parent = hrp

    -- Crée BodyGyro
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P = 1e4
    flyBodyGyro.D = 100
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
end

local function disableFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function updateFly()
    if not flyEnabled then return end
    if not flyBodyVelocity or not flyBodyGyro then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local move = Vector3.new(0, 0, 0)
    local cam = Camera

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        move = move + (cam.CFrame.LookVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        move = move - (cam.CFrame.LookVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        move = move - (cam.CFrame.RightVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        move = move + (cam.CFrame.RightVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        move = move + Vector3.new(0, flySpeed, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        move = move - Vector3.new(0, flySpeed, 0)
    end

    flyBodyVelocity.Velocity = move
    flyBodyGyro.CFrame = cam.CFrame
end

-- ==================== MAIN TAB ====================
local SectionAimbot = TabMain:CreateSection("Aimbot")

TabMain:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
      aimEnabled = Value
   end,
})

TabMain:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "TeamCheckToggle",
   Callback = function(Value)
      teamCheck = Value
   end,
})

TabMain:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false,
   Flag = "WallCheckToggle",
   Callback = function(Value)
      wallCheck = Value
   end,
})

TabMain:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
   CurrentOption = {"Head"},
   Flag = "AimPartDropdown",
   Callback = function(Option)
      aimPart = Option[1] or Option
   end,
})

TabMain:CreateSlider({
   Name = "Smoothness",
   Range = {1, 100},
   Increment = 1,
   CurrentValue = 10,
   Flag = "SmoothnessSlider",
   Callback = function(Value)
      smoothness = Value / 100
   end,
})

TabMain:CreateSlider({
   Name = "FOV Radius",
   Range = {10, 500},
   Increment = 10,
   CurrentValue = 100,
   Flag = "FOVSlider",
   Callback = function(Value)
      fovRadius = Value
      fovCircle.Radius = Value
   end,
})

TabMain:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "FOVToggle",
   Callback = function(Value)
      fovVisible = Value
      fovCircle.Visible = Value
   end,
})

local SectionMovement = TabMain:CreateSection("Movement")

TabMain:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedToggle",
   Callback = function(Value)
      speedEnabled = Value
      if not Value then
         local char = LocalPlayer.Character
         if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
         end
      end
   end,
})

TabMain:CreateSlider({
   Name = "Speed Value",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Flag = "SpeedSlider",
   Callback = function(Value)
      speedValue = Value
   end,
})

TabMain:CreateToggle({
   Name = "Jump Power",
   CurrentValue = false,
   Flag = "JumpToggle",
   Callback = function(Value)
      jumpEnabled = Value
      if not Value then
         local char = LocalPlayer.Character
         if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = 50
         end
      end
   end,
})

TabMain:CreateSlider({
   Name = "Jump Value",
   Range = {50, 300},
   Increment = 1,
   CurrentValue = 50,
   Flag = "JumpSlider",
   Callback = function(Value)
      jumpValue = Value
   end,
})

TabMain:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJumpToggle",
   Callback = function(Value)
      infiniteJumpEnabled = Value
   end,
})

TabMain:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      noclipEnabled = Value
   end,
})

TabMain:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      if Value then
         enableFly()
      else
         disableFly()
      end
   end,
})

TabMain:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 10,
   CurrentValue = 50,
   Flag = "FlySlider",
   Callback = function(Value)
      flySpeed = Value
   end,
})

-- ==================== VISUALS TAB ====================
local SectionESP = TabVisuals:CreateSection("ESP")

TabVisuals:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
      espEnabled = Value
      if not Value then
         for player, _ in pairs(espObjects) do
            removeESP(player)
         end
      end
   end,
})

TabVisuals:CreateToggle({
   Name = "Box ESP",
   CurrentValue = false,
   Flag = "BoxESPToggle",
   Callback = function(Value)
      espBox = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Name ESP",
   CurrentValue = false,
   Flag = "NameESPToggle",
   Callback = function(Value)
      espName = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Distance ESP",
   CurrentValue = false,
   Flag = "DistanceESPToggle",
   Callback = function(Value)
      espDistance = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Health ESP",
   CurrentValue = false,
   Flag = "HealthESPToggle",
   Callback = function(Value)
      espHealth = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Skeleton ESP",
   CurrentValue = false,
   Flag = "SkeletonESPToggle",
   Callback = function(Value)
      espSkeleton = Value
   end,
})

TabVisuals:CreateColorPicker({
   Name = "ESP Color",
   Color = Color3.fromRGB(255, 255, 255),
   Flag = "ESPColorPicker",
   Callback = function(Value)
      espColor = Value
   end
})

-- ==================== MISC TAB ====================
local SectionMisc = TabMisc:CreateSection("Miscellaneous")

TabMisc:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
      local TeleportService = game:GetService("TeleportService")
      pcall(function()
         TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
      end)
   end,
})

TabMisc:CreateButton({
   Name = "Server Hop",
   Callback = function()
      local PlaceId = game.PlaceId
      local HttpService = game:GetService("HttpService")
      local TeleportService = game:GetService("TeleportService")

      local success, result = pcall(function()
         return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
         ))
      end)

      if success and result and result.data then
         local AllServers = {}
         for _, server in pairs(result.data) do
            if type(server) == "table" and server.id and server.id ~= game.JobId then
               table.insert(AllServers, server)
            end
         end

         if #AllServers > 0 then
            local randomServer = AllServers[math.random(1, #AllServers)]
            pcall(function()
               TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.id, LocalPlayer)
            end)
         else
            Rayfield:Notify({
               Title = "Server Hop",
               Content = "Aucun autre serveur trouvé.",
               Duration = 3,
            })
         end
      end
   end,
})

TabMisc:CreateButton({
   Name = "FPS Boost",
   Callback = function()
      local g = game
      local l = g.Lighting
      local t = workspace.Terrain

      pcall(function() t.WaterWaveSize = 0 end)
      pcall(function() t.WaterWaveSpeed = 0 end)
      pcall(function() t.WaterReflectance = 0 end)
      pcall(function() t.WaterTransparency = 0 end)
      pcall(function() l.GlobalShadows = false end)
      pcall(function() l.FogEnd = 9e9 end)
      pcall(function() l.Brightness = 0 end)
      pcall(function() settings().Rendering.QualityLevel = "Level01" end)

      for _, v in pairs(g:GetDescendants()) do
         pcall(function()
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") or v:IsA("MeshPart") then
               v.Material = Enum.Material.Plastic
               v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
               v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
               v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
               v.BlastPressure = 1
               v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
               v.Enabled = false
            end
         end)
      end

      for _, e in pairs(l:GetChildren()) do
         pcall(function()
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
               e.Enabled = false
            end
         end)
      end

      Rayfield:Notify({
         Title = "FPS Boost",
         Content = "Boost appliqué avec succès !",
         Duration = 3,
      })
   end,
})

-- ==================== CREDITS TAB ====================
local SectionCredits = TabCredits:CreateSection("Credits")
TabCredits:CreateLabel("Created by pulse")
TabCredits:CreateLabel("Version: 1.0")
TabCredits:CreateLabel("pulse.lol")

-- ==================== RUNTIME ====================
RunService.RenderStepped:Connect(function()
    -- FOV Circle
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot
    if aimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayerToCursor()
        if target then
            aimAt(target)
        end
    end

    -- ESP : créer les objets si manquants
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not espObjects[player] then
                createESP(player)
            end
        end
    end

    -- Update ESP
    updateESP()

    -- Speed & Jump
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            if speedEnabled then
                humanoid.WalkSpeed = speedValue
            end
            if jumpEnabled then
                humanoid.JumpPower = jumpValue
            end
        end

        -- Noclip
        if noclipEnabled then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    -- Fly update
    if flyEnabled then
        updateFly()
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Player Added/Removed
Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Cleanup on death / respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    -- Réinitialise le fly si actif
    if flyEnabled then
        task.wait(0.5)
        disableFly()
        task.wait(0.1)
        enableFly()
    end

    character:WaitForChild("Humanoid").Died:Connect(function()
        if flyEnabled then
            flyEnabled = false
            disableFly()
        end
    end)
end)
