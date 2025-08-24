-- PetService.lua
-- Author: akoni_boss1786
-- Backend-only Pet System (spawn, gift, inventory)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Ensure remotes exist
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local REQ_SPAWN = Remotes:FindFirstChild("RequestSpawnPet") or Instance.new("RemoteEvent", Remotes)
REQ_SPAWN.Name = "RequestSpawnPet"

local REQ_GIFT = Remotes:FindFirstChild("RequestGiftPet") or Instance.new("RemoteEvent", Remotes)
REQ_GIFT.Name = "RequestGiftPet"

local REQ_LIST = Remotes:FindFirstChild("RequestListInventory") or Instance.new("RemoteFunction", Remotes)
REQ_LIST.Name = "RequestListInventory"

-- Pet catalog (add more pets here)
local Catalog = {
	["sproutling"] = {name = "Sproutling", power = 5},
	["blossom"]    = {name = "Blossom", power = 20},
	["sunbud"]     = {name = "Sunbud", power = 45},
}

-- Player inventories (in-memory only)
local Inventories = {}

local function GetInventory(userId)
	Inventories[userId] = Inventories[userId] or {}
	return Inventories[userId]
end

local function NewPet(ownerId, petType)
	local def = Catalog[petType]
	if not def then return nil end
	return {
		id = HttpService:GenerateGUID(false), -- unique id
		type = petType,
		name = def.name,
		owner = ownerId,
		stats = {power = def.power, level = 1, xp = 0},
	}
end

-- Handle spawn requests
REQ_SPAWN.OnServerEvent:Connect(function(player, petType)
	local inv = GetInventory(player.UserId)
	local pet = NewPet(player.UserId, petType)
	if pet then
		inv[pet.id] = pet
		print(player.Name .. " spawned pet:", pet.name)
	else
		warn("Invalid pet type:", petType)
	end
end)

-- Handle gifting
REQ_GIFT.OnServerEvent:Connect(function(player, toUserId, petId)
	local fromInv = GetInventory(player.UserId)
	local pet = fromInv[petId]
	if pet and pet.owner == player.UserId then
		fromInv[petId] = nil
		pet.owner = toUserId
		local toInv = GetInventory(toUserId)
		toInv[pet.id] = pet
		print(player.Name .. " gifted " .. pet.name .. " to UserId " .. toUserId)
	else
		warn("Gift failed for", player.Name)
	end
end)

-- Handle listing inventory
REQ_LIST.OnServerInvoke = function(player)
	local inv = GetInventory(player.UserId)
	local list = {}
	for _, pet in pairs(inv) do
		table.insert(list, pet)
	end
	return list
end

print("PetService.lua by akoni_boss1786 loaded successfully!")
