--==================================================
-- BLACK -> cập nhật: đổi Hints/Cause thành Hauntstep + cố gắng thay image thành Hauntstep
-- Paste whole file into your executor and run
--==================================================

if game.Workspace:FindFirstChild("SeekMovingNewClone") then return end

---====== CONFIG ======---
local HAUNTSTEP_IMAGE_ID = "11631793705" -- image Hauntstep (H80)
local LIGHT_TARGET_COLOR = Color3.fromRGB(61, 0, 152) -- tím đậm (giữ sửa map)
local LIGHT_BRIGHTNESS = 6
local LIGHT_RANGE = 30
local LIGHT_TWEEN_TIME = 0.8

---====== Global light tween (map) ======---
local TweenService = game:GetService("TweenService")
local rooms = workspace:FindFirstChild("CurrentRooms")
if rooms then
    local colorInfo = TweenInfo.new(3)
    local targetColor = { Color = LIGHT_TARGET_COLOR }
    for _, obj in pairs(rooms:GetDescendants()) do
        if obj:IsA("Light") then
            pcall(function() TweenService:Create(obj, colorInfo, targetColor):Play() end)
            if obj.Parent and obj.Parent.Name == "LightFixture" then
                pcall(function() TweenService:Create(obj.Parent, colorInfo, targetColor):Play() end)
            end
        end
    end
end

---====== Load spawner ======---
local spawner = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"
))()

---====== Helper: robust image setter (tries many types) ======---
local function SetModelImage(model, imageId)
    if not model then return false end
    local newImage = "rbxassetid://" .. tostring(imageId)
    local changed = false

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            pcall(function() obj.Image = newImage end)
            changed = true
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj.Texture = newImage end)
            changed = true
        elseif obj:IsA("SpecialMesh") then
            pcall(function() obj.TextureId = newImage end)
            changed = true
        elseif obj:IsA("MeshPart") then
            pcall(function() obj.TextureID = newImage end)
            changed = true
        end
    end

    -- try direct BillboardGui case
    local gui = model:FindFirstChildWhichIsA("BillboardGui", true)
    if gui then
        local img = gui:FindFirstChildWhichIsA("ImageLabel", true) or gui:FindFirstChildWhichIsA("ImageButton", true)
        if img then
            pcall(function() img.Image = newImage end)
            changed = true
        end
    end

    return changed
end

---====== Apply light settings helper ======---
local function ApplyLightSettings(model, targetColor, brightness, range, tweenTime)
    if not model then return end
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            pcall(function()
                obj.Brightness = brightness
                obj.Range = range
                obj.Shadows = true
            end)
            -- tween color
            pcall(function()
                local goal = { Color = targetColor }
                local info = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local t = TweenService:Create(obj, info, goal)
                t:Play()
            end)
        end
    end
end

---====== Create entity (Black) ======---
local entity = spawner.Create({
	Entity = {
		Name = "Black",
		Asset = "rbxassetid://111518803521850",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = true,
			Duration = 4
		},
		Shatter = false,
		Repair = false
	},
	Earthquake = { Enabled = false },
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {5, 15, 0.1, 1}
	},
	Movement = {
		Speed = 330,
		Delay = 8,
		Reversed = false
	},
	Rebounding = {
		Enabled = true,
		Type = "Ambush",
		Min = 3,
		Max = 4,
		Delay = 2
	},
	Damage = {
		Enabled = true,
		Range = 75,
		Amount = 125
	},
	Crucifixion = {
		Enabled = true,
		Range = 40,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {
			"You died to who you call Hauntstep.",
			"Hauntstep moves extremely fast.",
			"It rebounds multiple times.",
			"Hide when you hear it coming."
		},
		Cause = "Hauntstep"
	}
})

---====== Callbacks ======---

entity:SetCallback("OnSpawned", function()
    -- wait model to exist/populate
    local model = entity.Model
    local tries = 0
    while (not model or #model:GetDescendants() == 0) and tries < 40 do
        task.wait(0.05)
        model = entity.Model
        tries = tries + 1
    end

    if not model then
        warn("[Black->Hauntstep] Model not found on spawn.")
        return
    end

    -- try to replace image
    local ok = SetModelImage(model, HAUNTSTEP_IMAGE_ID)
    if ok then
        print("[Black->Hauntstep] Image set to", HAUNTSTEP_IMAGE_ID)
    else
        warn("[Black->Hauntstep] Couldn't replace image automatically. Model contains the following ClassNames:")
        local types = {}
        for _, d in ipairs(model:GetDescendants()) do types[d.ClassName] = true end
        local keys = {}
        for k in pairs(types) do table.insert(keys, k) end
        warn(table.concat(keys, ", "))
        warn("[Black->Hauntstep] If you see 'ViewportFrame' or 'SurfaceAppearance' above, the image cannot be changed by script on client/mobile.")
    end

    -- apply light settings on the model (tween color)
    ApplyLightSettings(model, LIGHT_TARGET_COLOR, LIGHT_BRIGHTNESS, LIGHT_RANGE, LIGHT_TWEEN_TIME)
end)

-- keep other debug callbacks
entity:SetCallback("OnStartMoving", function() print("[Black->Hauntstep] started moving") end)
entity:SetCallback("OnEnterRoom", function(room, firstTime)
    if firstTime then print("[Black->Hauntstep] entered room:", room.Name) else print("[Black->Hauntstep] re-entered room:", room.Name) end
end)
entity:SetCallback("OnLookAt", function(lineOfSight) if lineOfSight then print("[Black->Hauntstep] Player looking") end end)
entity:SetCallback("OnRebounding", function(start) if start then print("[Black->Hauntstep] Rebound start") else print("[Black->Hauntstep] Rebound end") end end)
entity:SetCallback("OnDespawning", function() print("[Black->Hauntstep] Despawning") end)
entity:SetCallback("OnDespawned", function() print("[Black->Hauntstep] Despawned") end)
entity:SetCallback("OnDamagePlayer", function(h)
    if h == 0 then print("[Black->Hauntstep] Player killed") else print("[Black->Hauntstep] Player damaged, new health:", h) end
end)

---====== Run entity ======---
entity:Run()
