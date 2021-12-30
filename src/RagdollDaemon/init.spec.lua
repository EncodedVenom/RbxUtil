local CollectionService = game:GetService("CollectionService")
local r15DefaultRigId = 1664543044

local function r15RigImported(rig)
	local R15Dummy = game:GetService("InsertService"):LoadAsset(r15DefaultRigId):GetChildren()[1]

	for _, part in pairs(rig:GetChildren()) do
		local matchingPart = R15Dummy:FindFirstChild(part.Name)
		if matchingPart then
			matchingPart:Destroy()
		end
		part.Parent = R15Dummy
	end
	rig:Destroy()

	rig = R15Dummy
	rig.Parent = workspace

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:BuildRigFromAttachments()
	end

	local r15Head = rig:WaitForChild("Head", 1)

	local existingFace = r15Head:FindFirstChild("face") or r15Head:FindFirstChild("Face")
	if existingFace == nil then
		local face = Instance.new("Decal")
        face.Parent = r15Head
		face.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
	end

	return rig
end

local function BuildR15Rig(package)
	local m = Instance.new("Model")
    m.Parent = workspace
	local headMesh = nil
	local face = nil
	if package ~= nil then
		local pkIds = game:GetService("AssetService"):GetAssetIdsForPackage(package)
		for _, v in pairs(pkIds) do
			local a = game:GetService("InsertService"):LoadAsset(v)
			if a:FindFirstChild("R15ArtistIntent") then
				for _, x in pairs(a.R15ArtistIntent:GetChildren()) do
					x.Parent = m
				end
			elseif a:FindFirstChild("R15") then
				for _, x in pairs(a.R15:GetChildren()) do
					x.Parent = m
				end
			elseif a:FindFirstChild("face") then
				face = a.face
			elseif a:FindFirstChild("Face") then
				face = a.Face
			elseif a:FindFirstChild("Mesh") then
				headMesh = a.Mesh
			end
		end
	end

	local rig = r15RigImported(m)

	if headMesh then
		rig.Head.Mesh:Destroy()
		headMesh.Parent = rig.Head
	end

	if face then
		for _, v in pairs(rig.Head:GetChildren()) do
			if v.Name == "face" or v.Name == "Face" then
				v:Destroy()
			end
		end
		face.Parent = rig.Head
	end

    rig.HumanoidRootPart.Anchored = true -- We're in a blank environment. Don't let the rig fall into the void!

    rig.Parent = workspace

	return rig
end

return function()

    local RagdollDaemon = require(script.Parent)

    describe("Ragdoll", function()
        it("should be able to build", function()
            local rig = BuildR15Rig()
            expect(rig).to.be.ok()
            rig:Destroy()
        end)

        it("should be able to ragdoll with tag", function()
            local rig = BuildR15Rig()

            CollectionService:AddTag(rig.Humanoid, "Ragdoll")

            expect(rig:WaitForChild("RagdollConstraints", 1)).to.be.ok()
            rig:Destroy()
        end)

        it("should be able to respond to death", function()
            local rig = BuildR15Rig()

            CollectionService:AddTag(rig.Humanoid, "RagdollOnDeath")

			task.wait()
            rig.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			rig.Humanoid.Health = 0
			rig.HumanoidRootPart.Anchored = false
			task.wait()

            expect(rig:WaitForChild("RagdollConstraints", 1)).to.be.ok()
            expect(CollectionService:HasTag(rig.Humanoid, "Ragdoll")).to.equal(true)
            rig:Destroy()
        end)

        it("should work when NPC ragdolls are set to occur", function()
            RagdollDaemon.MakeNonPlayerCharactersRagdollOnDeath()

            local rig = BuildR15Rig()

            task.wait()
            rig.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			rig.Humanoid.Health = 0
			rig.HumanoidRootPart.Anchored = false
			task.wait()

            expect(rig:WaitForChild("RagdollConstraints", 1)).to.be.ok()
            expect(CollectionService:HasTag(rig.Humanoid, "Ragdoll")).to.equal(true)
            rig:Destroy()
        end) -- These tests don't work in CI for some reason. They work everywhere else.
    end)
end