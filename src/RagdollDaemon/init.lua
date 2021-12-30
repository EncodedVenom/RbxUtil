-- // Bootstrap.

--[[
    Require this script on both the client and server to set up.
    Additional helper functions are provided below.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local PlayerDeathRagdoll = require(script.PlayerDeathRagdoll)
local Ragdoll = require(script.Ragdoll)
local RagdollOnDeath = require(script.RagdollOnDeath)

local HelperFunctions = {}

function HelperFunctions.MakePlayerCharactersRagdollOnDeath()
    local function OnCharacterAdded(Character)
        local Humanoid = Character:WaitForChild("Humanoid", 2)
        if not Humanoid then
            warn("Character Humanoid does not exist?")
            return
        end
        CollectionService:AddTag(Humanoid, "PlayerDeathRagdoll")
    end

    local function OnPlayerAdded(Player: Player)
        OnCharacterAdded(Player.Character or Player.CharacterAdded:Wait())
        Player.CharacterAdded:Connect(OnCharacterAdded)
    end

    Players.PlayerAdded:Connect(function(Player)
        OnPlayerAdded(Player)
    end)
    for _, Player in ipairs(Players:GetPlayers()) do
        OnPlayerAdded(Player)
    end
end

function HelperFunctions.MakeNonPlayerCharactersRagdollOnDeath()
    local function handleHumanoid(humanoid: Humanoid)
        if not humanoid:IsA("Humanoid") then
            return
        end

        if humanoid.Health <= 0 then
            return
        end

        if Players:GetPlayerFromCharacter(humanoid.Parent) then
            return -- NPCs only.
        end

        CollectionService:AddTag(humanoid, if humanoid:IsDescendantOf(Players) then "PlayerDeathRagdoll" else "RagdollOnDeath")
    end
    
    for _, humanoid: Humanoid in ipairs(workspace:GetDescendants()) do
        handleHumanoid(humanoid)
    end

    workspace.DescendantAdded:Connect(handleHumanoid)
end

function HelperFunctions.MakeEveryoneRagdollOnDeath() -- Do NOT use any of the above functions if you use this.
    HelperFunctions.MakeNonPlayerCharactersRagdollOnDeath()
    HelperFunctions.MakePlayerCharactersRagdollOnDeath()
end


function HelperFunctions.SetRagdollState(humanoid: Humanoid, state: boolean)
    CollectionService[if state then "AddTag" else "RemoveTag"](CollectionService, humanoid, "Ragdoll")
end

return HelperFunctions