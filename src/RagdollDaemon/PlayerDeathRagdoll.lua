--[[

    This class exists due to the fun interactions with players dying and deleting their old character upon death.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local build = require(script.Parent.build)

local PlayerDeathRagdoll = Component.new({
    Tag = "PlayerDeathRagdoll"
})
PlayerDeathRagdoll.RenderPriority = Enum.RenderPriority.Camera.Value

local function safeClone(instance)
    local oldArchivable = instance.Archivable
    
    instance.Archivable = true
    local clone = instance:Clone()
    clone.Name = "Ragdoll_"..clone.Name
    for attribName, _ in pairs(clone:GetAttributes()) do
        clone:SetAttribute(attribName, nil)
    end
    for _, part in pairs(instance:GetChildren()) do
        if part:IsA("BasePart") then
            clone[part.Name]:ApplyImpulseAtPosition(part:GetVelocityAtPosition(part.Position), clone[part.Name].Position)
        end
    end
    instance.Archivable = oldArchivable
    
    return clone
end

function PlayerDeathRagdoll:Construct()
    assert(self.Instance:IsA("Humanoid"), "PlayerDeathRagdoll instances must be a Humanoid")
    assert(Players:GetPlayerFromCharacter(self.Instance.Parent), "PlayerDeathRagdoll can only be applied to Humanoids that descend from Players!")

    self.Instance.BreakJointsOnDeath = false
    self.Player = Players:GetPlayerFromCharacter(self.Instance.Parent) :: Player

    self._removingConnection = self.Player.CharacterRemoving:Connect(function(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoid:SetAttribute("PreserveRagdoll", true)
        CollectionService:RemoveTag(humanoid, "Ragdoll")
        CollectionService:RemoveTag(humanoid, "PlayerDeathRagdoll") -- No longer needed.
        if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            return
        end

        local clone = safeClone(character)
        repeat task.wait() until not character:IsDescendantOf(workspace)
        local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")

        -- Don't clutter the game with nameplates / healthbars
        cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        -- Roblox will try to rebuild joints when the clone is parented to Workspace and
        -- break the ragdoll, so disable automatic scaling to prevent that. We don't need
        -- it anyway since the character is already scaled from when it was originally created
        cloneHumanoid.AutomaticScalingEnabled = false
        
        -- Clean up junk so we have less scripts running and don't have ragdolls
        -- spamming random sounds
        local animate = character:FindFirstChild("Animate")
        local sound = character:FindFirstChild("Sound")
        local health = character:FindFirstChild("Health")
        
        if animate then
            animate:Destroy()
        end
        if sound then
            sound:Destroy()
        end
        if health then
            health:Destroy()
        end
        
        clone.Parent = workspace
        task.delay(10, function()
            clone:Destroy()
        end)
        
        -- State is not preserved when cloning. We need to set it back to Dead or the
        -- character won't ragdoll. This has to be done AFTER parenting the character
        -- to Workspace or the state change won't replicate to clients that can then
        -- start simulating the character if they get close enough
        cloneHumanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end)

    self._diedConnection = self.Instance.Died:Connect(function()
        CollectionService:AddTag(self.Instance, "Ragdoll")
    end)
end

function PlayerDeathRagdoll:Stop()
    self._diedConnection:Disconnect()
    self._removingConnection:Disconnect()
end

return PlayerDeathRagdoll