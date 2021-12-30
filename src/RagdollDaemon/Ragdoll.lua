local Players = game:GetService("Players")

local IS_SERVER = game:GetService("RunService"):IsServer()
local Component = require(script.Parent.Parent.Component)
local build = require(script.Parent.build)

local Ragdoll = Component.new({
    Tag = "Ragdoll"
})
Ragdoll.RenderPriority = Enum.RenderPriority.Camera.Value

local function setStateEnabled(Humanoid: Humanoid, State: boolean)
    local ragdollConstraints = Humanoid.Parent:FindFirstChild("RagdollConstraints")

    if not ragdollConstraints then
        return
    end
	
	for _,constraint in pairs(ragdollConstraints:GetChildren()) do
		if constraint:IsA("Constraint") then
			local rigidJoint = constraint.RigidJoint.Value
			local expectedValue = (not State) and constraint.Attachment1.Parent or nil
			
			if rigidJoint.Part1 ~= expectedValue then
				rigidJoint.Part1 = expectedValue
			end
		end
	end
end

function Ragdoll:Construct()
    self.Constraints = build.fromHumanoid(self.Instance :: Humanoid)
end

function Ragdoll:Start()
    local Player = Players:GetPlayerFromCharacter(self.Instance.Parent)
    if (Player and self.Instance.Health > 0 and (not IS_SERVER)) or ((not Player) and IS_SERVER) then
        self.Instance:ChangeState(Enum.HumanoidStateType.Physics)
    end
    setStateEnabled(self.Instance, true)
end

function Ragdoll:Stop()
    if self.Instance:GetAttribute("PreserveRagdoll") then -- Used to preserve ragdolls for corpses basically.
        return
    end
    local Player = Players:GetPlayerFromCharacter(self.Instance.Parent)
    if (Player and self.Instance.Health > 0 and (not IS_SERVER)) or ((not Player) and IS_SERVER) then
        self.Instance:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if self.Instance then -- Character might not exist anymore. It could have been yeeted out of existence for all I know.
        setStateEnabled(self.Instance, false)
    end
    print("Removing")
    build.removeFromHumanoid(self.Instance :: Humanoid)
end

return Ragdoll