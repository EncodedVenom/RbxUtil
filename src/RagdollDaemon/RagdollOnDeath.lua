local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)

local RagdollOnDeath = Component.new({
    Tag = "RagdollOnDeath"
})
RagdollOnDeath.RenderPriority = Enum.RenderPriority.Camera.Value

function RagdollOnDeath:Start()
    local humanoid: Humanoid;
    if self.Instance:IsA("Humanoid") then
        humanoid = self.Instance
    else
        humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then
            error("Tag improperly placed on non-humanoid type object.")
        else
            warn("Tag is meant to be placed on humanoids.")
        end
    end
    humanoid:SetAttribute("IsPlayerHumanoid", humanoid:IsDescendantOf(Players))
    self._connection = humanoid.Died:Connect(function()
        CollectionService:AddTag(humanoid, "Ragdoll")
    end)
end

function RagdollOnDeath:Stop()
    self._connection:Disconnect()
end

return RagdollOnDeath