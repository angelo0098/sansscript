-- ================================================= --
-- [[ 1. FAKE INPUTS & SERVICES ]]
-- ================================================= --
local Player = game.Players:GetPlayerFromCharacter(script.Parent)

local repStorage = game:GetService("ReplicatedStorage")
local mobileEvent = repStorage:FindFirstChild("SansMobileButtonEvent")
if not mobileEvent then
	mobileEvent = Instance.new("RemoteEvent")
	mobileEvent.Name = "SansMobileButtonEvent"
	mobileEvent.Parent = repStorage
end

local invEvent = repStorage:FindFirstChild("SansInvertionEvent")
if not invEvent then
	invEvent = Instance.new("RemoteEvent")
	invEvent.Name = "SansInvertionEvent"
	invEvent.Parent = repStorage
end

local Mouse,mouse,UserInputService,ContextActionService
do
	script.Parent = Player.Character
	local CAS = {Actions={}}
	local Event = Instance.new("RemoteEvent")
	Event.Name = "UserInput_Event"
	Event.Parent = Player.Character
	local fakeEvent = function()
		local t = {_fakeEvent=true}
		t.Connect = function(self,f)self.Function=f end
		t.connect = t.Connect
		return t
	end
	local m = {Target=nil,Hit=CFrame.new(),KeyUp=fakeEvent(),KeyDown=fakeEvent(),Button1Up=fakeEvent(),Button1Down=fakeEvent()}
	local UIS = {InputBegan=fakeEvent(),InputEnded=fakeEvent()}
	function CAS:BindAction(name,fun,touch,...)
		CAS.Actions[name] = {Name=name,Function=fun,Keys={...}}
	end
	function CAS:UnbindAction(name)
		CAS.Actions[name] = nil
	end
	local function te(self,ev,...)
		local t = m[ev]
		if t and t._fakeEvent and t.Function then
			t.Function(...)
		end
	end
	m.TrigEvent = te
	UIS.TrigEvent = te
	local function GetAimPosition(hitCFrame)
		local ws = game:GetService("Workspace")
		local char = Player and Player.Character
		local rp = char and char:FindFirstChild("HumanoidRootPart")
		
		local function isVectorNaN(v)
			return v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z
		end
		
		local defaultPos = rp and rp.Position or Vector3.new(0, 3, 0)
		
		if typeof(hitCFrame) ~= "CFrame" then
			return defaultPos, nil
		end
		
		if isVectorNaN(hitCFrame.Position) or isVectorNaN(hitCFrame.LookVector) then
			return defaultPos, nil
		end
		
		local effectsFolder = ws:FindFirstChild("Stuff") or ws:FindFirstChild("Effects") or (char and (char:FindFirstChild("Stuff") or char:FindFirstChild("Effects")))
		
		local currentIgnore = {char}
		local maxCasts = 15
		local startPos = hitCFrame.Position - hitCFrame.LookVector * 5
		local direction = hitCFrame.LookVector * 1500
		
		while maxCasts > 0 do
			maxCasts = maxCasts - 1
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = currentIgnore
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true
			
			local result = ws:Raycast(startPos, direction, params)
			if not result then
				break
			end
			
			local hitPart = result.Instance
			local isWall = ((hitPart.Transparency >= 0.95) or hitPart.Name:lower():find("wall") or hitPart.Name:lower():find("barrier") or hitPart.Name:lower():find("field")) and not hitPart.Name:lower():find("platform")
			
			if isWall then
				table.insert(currentIgnore, hitPart)
			else
				return result.Position, hitPart
			end
		end
		
		return hitCFrame.Position, nil
	end

	Event.OnServerEvent:Connect(function(plr,io)
		if plr~=Player then 
			if io and io.KeyCode == Enum.KeyCode.P and io.UserInputState == Enum.UserInputState.Begin then
				if _G.PhaseThroughPlatformForPlayer then
					_G.PhaseThroughPlatformForPlayer(plr)
				end
			end
			return 
		end
		
		local defaultPos = (Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")) and Player.Character.HumanoidRootPart.Position or Vector3.new(0, 3, 0)
		if io and io.Hit then
			if typeof(io.Hit) ~= "CFrame" then
				io.Hit = CFrame.new(defaultPos)
			end
			local correctedPos, hitPart = GetAimPosition(io.Hit)
			io.Hit = CFrame.new(correctedPos) * io.Hit.Rotation
			if hitPart then io.Target = hitPart end
			m.Hit = io.Hit
			m.Target = io.Target
		end
		
		if io.isMouse then
			-- already processed above!
		elseif io.UserInputType == Enum.UserInputType.MouseButton1 then
			if io.UserInputState == Enum.UserInputState.Begin then
				m:TrigEvent("Button1Down")
			else
				m:TrigEvent("Button1Up")
			end
		else
			for n,t in pairs(CAS.Actions) do
				for _,k in pairs(t.Keys) do
					if k==io.KeyCode then
						t.Function(t.Name,io.UserInputState,io)
					end
				end
			end
			if io.UserInputState == Enum.UserInputState.Begin then
				m:TrigEvent("KeyDown",io.KeyCode.Name:lower())
				UIS:TrigEvent("InputBegan",io,false)
			else
				m:TrigEvent("KeyUp",io.KeyCode.Name:lower())
				UIS:TrigEvent("InputEnded",io,false)
			end
		end
	end)
	Mouse,mouse,UserInputService,ContextActionService = m,m,UIS,CAS
end

-- Custom workspace Proxy to handle raycast interception so players and Sans can aim bones/blasters at moving platforms
local realWorkspace = game:GetService("Workspace")
local physicsService = game:GetService("PhysicsService")
pcall(function()
	physicsService:RegisterCollisionGroup("SansGroup")
	physicsService:RegisterCollisionGroup("BoneGroup")
	physicsService:CollisionGroupSetCollidable("SansGroup", "BoneGroup", false)
end)
local workspace
workspace = setmetatable({}, {
	__index = function(self, key)
		if key == "FindPartOnRayWithIgnoreList" then
			return function(_, ray, ignoreList)
				local list = ignoreList or {}
				local char = Player and Player.Character
				local effectsFolder = realWorkspace:FindFirstChild("Stuff") or realWorkspace:FindFirstChild("Effects") or (char and (char:FindFirstChild("Stuff") or char:FindFirstChild("Effects")))
				local hasEffects = false
				local filteredIgnore = {}
				for _, item in ipairs(list) do
					if item == effectsFolder then
						hasEffects = true
					elseif item == char then
						if char then
							for _, child in ipairs(char:GetChildren()) do
								if child ~= effectsFolder then
									table.insert(filteredIgnore, child)
								end
							end
						end
					else
						table.insert(filteredIgnore, item)
					end
				end

				-- We also always want to ignore invisible walls during raycasting
				local maxCasts = 15
				local currentIgnore = {table.unpack(filteredIgnore)}
				while maxCasts > 0 do
					maxCasts = maxCasts - 1
					local hit, pos, normal, material = realWorkspace.FindPartOnRayWithIgnoreList(realWorkspace, ray, currentIgnore)
					if not hit then
						return nil, pos, normal, material
					end
					
					-- Check if hit is an invisible wall
					local isWall = ((hit.Transparency >= 0.95) or hit.Name:lower():find("wall") or hit.Name:lower():find("barrier") or hit.Name:lower():find("field")) and not hit.Name:lower():find("platform")
					
					if isWall then
						table.insert(currentIgnore, hit)
					elseif hasEffects and effectsFolder and hit:IsDescendantOf(effectsFolder) then
						if hit.Name:lower():find("platform") then
							return hit, pos, normal, material
						else
							table.insert(currentIgnore, hit)
						end
					else
						return hit, pos, normal, material
					end
				end
				local finalIgnore = hasEffects and filteredIgnore or list
				return realWorkspace.FindPartOnRayWithIgnoreList(realWorkspace, ray, finalIgnore)
			end
		elseif key == "Raycast" then
			return function(_, origin, direction, params)
				local char = Player and Player.Character
				local effectsFolder = realWorkspace:FindFirstChild("Stuff") or realWorkspace:FindFirstChild("Effects") or (char and (char:FindFirstChild("Stuff") or char:FindFirstChild("Effects")))
				if params then
					local list = params.FilterDescendantsInstances
					local hasEffects = false
					local filteredIgnore = {}
					for _, item in ipairs(list) do
						if item == effectsFolder then
							hasEffects = true
						elseif item == char then
							if char then
								for _, child in ipairs(char:GetChildren()) do
									if child ~= effectsFolder then
										table.insert(filteredIgnore, child)
									end
								end
							end
						else
							table.insert(filteredIgnore, item)
						end
					end

					local maxCasts = 15
					local currentIgnore = {table.unpack(filteredIgnore)}
					while maxCasts > 0 do
						maxCasts = maxCasts - 1
						local newParams = RaycastParams.new()
						newParams.FilterDescendantsInstances = currentIgnore
						newParams.FilterType = params.FilterType
						newParams.CollisionGroup = params.CollisionGroup
						newParams.IgnoreWater = params.IgnoreWater
						local result = realWorkspace:Raycast(origin, direction, newParams)
						if not result then
							return nil
						end
						local hit = result.Instance
						
						-- Check if hit is an invisible wall
						local isWall = ((hit.Transparency >= 0.95) or hit.Name:lower():find("wall") or hit.Name:lower():find("barrier") or hit.Name:lower():find("field")) and not hit.Name:lower():find("platform")
						
						if isWall then
							table.insert(currentIgnore, hit)
						elseif hasEffects and effectsFolder and hit:IsDescendantOf(effectsFolder) then
							if hit.Name:lower():find("platform") then
								return result
							else
								table.insert(currentIgnore, hit)
							end
						else
							return result
						end
					end
				end
				return realWorkspace:Raycast(origin, direction, params)
			end
		end
		local val = realWorkspace[key]
		if type(val) == "function" then
			return function(selfArg, ...)
				local targetSelf = selfArg
				if targetSelf == workspace then
					targetSelf = realWorkspace
				end
				return val(targetSelf, ...)
			end
		end
		return val
	end,
	__newindex = function(self, key, value)
		realWorkspace[key] = value
	end
})

-- ================================================= --
-- [[ 2. CHARACTER SETUP & RIGGING ]]
-- ================================================= --
local Player, Character = game.Players:GetPlayerFromCharacter(script.Parent), Player.Character;

pcall(function()
	for _, child in pairs(Character:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CollisionGroup = "SansGroup"
		end
	end
	Character.DescendantAdded:Connect(function(child)
		if child:IsA("BasePart") then
			child.CollisionGroup = "SansGroup"
		end
	end)
end)
local Torso = Character:FindFirstChild("Torso")
local rootPart = Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character:FindFirstChild("Humanoid")
local Head = Character:FindFirstChild("Head")
local Right_Arm = Character:FindFirstChild("Right Arm")
local Left_Arm = Character:FindFirstChild("Left Arm")
local Right_Leg = Character:FindFirstChild("Right Leg")
local Left_Leg = Character:FindFirstChild("Left Leg")
local Right_Shoulder = Torso:FindFirstChild("Right Shoulder")
local Left_Shoulder = Torso:FindFirstChild("Left Shoulder")
local Right_Hip = Torso:FindFirstChild("Right Hip")
local Left_Hip = Torso:FindFirstChild("Left Hip")
local Neck = Torso:FindFirstChild("Neck")
local rootJoint = rootPart:FindFirstChild("RootJoint")
local CurrentIdle = "Idling1"
local isAttacking = false
local jumpCooldown = false
Humanoid.UseJumpPower = true
Humanoid.JumpPower = 0
Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

-- Prevent default animations from overriding
local animateScript = Character:FindFirstChild("Animate")
if animateScript then animateScript.Disabled = true end

local blockSlowdownEnd = 0
local heldKeys = {}
_G.SansOnPlatform = false
local isSprinting = false
local Animations = false
local Angle = 0
local Axis = 0
local angleSpeed = 1
local axisSpeed = angleSpeed
local currentAnim

-- ================================================= --
-- [[ 3. CLOTHING & R6 ENFORCER ]]
-- ================================================= --
local loadWait = 0
while not Player:HasAppearanceLoaded() and loadWait < 2 do
	wait(0.1)
	loadWait = loadWait + 0.1
end

loadWait = 0
while not Character:FindFirstChildOfClass("Shirt") and not Character:FindFirstChildOfClass("Pants") and loadWait < 1.5 do
	wait(0.1)
	loadWait = loadWait + 0.1
end

local OriginalShirtObj = nil
local OriginalPantsObj = nil
local OriginalTShirtObj = nil
local OriginalBodyColors = nil

if Character:FindFirstChild("Body Colors") then
	OriginalBodyColors = Character["Body Colors"]:Clone()
else
	OriginalBodyColors = Instance.new("BodyColors")
	OriginalBodyColors.HeadColor3 = Head.Color
	OriginalBodyColors.TorsoColor3 = Torso.Color
	OriginalBodyColors.LeftArmColor3 = Left_Arm.Color
	OriginalBodyColors.RightArmColor3 = Right_Arm.Color
	OriginalBodyColors.LeftLegColor3 = Left_Leg.Color
	OriginalBodyColors.RightLegColor3 = Right_Leg.Color
end

for _, obj in pairs(Character:GetChildren()) do
	if obj:IsA("CharacterMesh") then
		obj:Destroy()
	elseif obj:IsA("Shirt") then
		if not OriginalShirtObj then OriginalShirtObj = obj:Clone() end
	elseif obj:IsA("Pants") then
		if not OriginalPantsObj then OriginalPantsObj = obj:Clone() end
	elseif obj:IsA("ShirtGraphic") then
		if not OriginalTShirtObj then OriginalTShirtObj = obj:Clone() end
	end
end

local sansClothesEnabled = true

local function UpdateClothing()
	for _, obj in pairs(Character:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
			obj:Destroy()
		end
	end

	if sansClothesEnabled then
		local s = Instance.new("Shirt", Character)
		s.Name = "Shirt"
		s.ShirtTemplate = "rbxassetid://388330836"

		local p = Instance.new("Pants", Character)
		p.Name = "Pants"
		p.PantsTemplate = "rbxassetid://386822275"
	else
		if OriginalShirtObj then OriginalShirtObj:Clone().Parent = Character end
		if OriginalPantsObj then OriginalPantsObj:Clone().Parent = Character end
		if OriginalTShirtObj then OriginalTShirtObj:Clone().Parent = Character end

		if OriginalBodyColors then
			if Character:FindFirstChild("Body Colors") then
				local bc = Character["Body Colors"]
				bc.HeadColor3 = OriginalBodyColors.HeadColor3
				bc.TorsoColor3 = OriginalBodyColors.TorsoColor3
				bc.RightArmColor3 = OriginalBodyColors.RightArmColor3
				bc.LeftArmColor3 = OriginalBodyColors.LeftArmColor3
				bc.RightLegColor3 = OriginalBodyColors.RightLegColor3
				bc.LeftLegColor3 = OriginalBodyColors.LeftLegColor3
			end
			-- Force the actual parts back to original color
			Head.BrickColor = BrickColor.new(OriginalBodyColors.HeadColor3)
			Torso.BrickColor = BrickColor.new(OriginalBodyColors.TorsoColor3)
			Left_Arm.BrickColor = BrickColor.new(OriginalBodyColors.LeftArmColor3)
			Right_Arm.BrickColor = BrickColor.new(OriginalBodyColors.RightArmColor3)
			Left_Leg.BrickColor = BrickColor.new(OriginalBodyColors.LeftLegColor3)
			Right_Leg.BrickColor = BrickColor.new(OriginalBodyColors.RightLegColor3)
		end
	end
end

UpdateClothing() 
Humanoid.MaxHealth = 100
Humanoid.Health = Humanoid.MaxHealth
Humanoid.BreakJointsOnDeath = false 

-- ================================================= --
-- [[ 4. ANIMATION MATH & WELDS ]]
-- ================================================= --
sine = 0
change = 1
sprint=false
idly = 0
idle = idly
Sanim = 0.025
dedebounce = false
attack2 = false
attack = false

local CreateMovesGUI

sin = math.sin
Right_Leg.FormFactor 		= "Custom";
Left_Leg.FormFactor			= "Custom";
rootPart.Archivable 		= true;
rootJoint.Archivable 		= true;
c_new						= CFrame.new;
cam = game.Workspace.CurrentCamera
c_angles					= CFrame.Angles;
i_new = Instance.new

newWeld = function(wp0, wp1, wc0x, wc0y, wc0z)
	local wld = Instance.new("Weld", wp1)
	wld.Part0 = wp0
	wld.Part1 = wp1
	wld.C0 = CFrame.new(wc0x, wc0y, wc0z)
	return wld
end

Frame_Speed = 1 / 60
ArtificialHB = Instance.new("BindableEvent", script)
ArtificialHB.Name = "ArtificialHB"
script:WaitForChild("ArtificialHB")

frame = Frame_Speed -- FIX: RESTORED THIS LINE!
tf = 0
allowframeloss = false
tossremainder = false
lastframe = tick()
script.ArtificialHB:Fire()

game:GetService("RunService").Heartbeat:connect(function(s, p)
	tf = tf + s
	if tf >= frame then
		if allowframeloss then
			script.ArtificialHB:Fire()
			lastframe = tick()
		else
			for i = 1, math.floor(tf / frame) do
				script.ArtificialHB:Fire()
			end
			lastframe = tick()
		end
		if tossremainder then
			tf = 0
		else
			tf = tf - frame * math.floor(tf / frame)
		end
	end
end)

_G.CancelAttackTrigger = false

-- =====================================================
-- ResolveAimHit: snaps the mouse target onto moving platforms.
-- Because moving platforms slide between the client's click and the server
-- receiving the input, mouse.Hit.p ends up in mid-air OR points at the floor
-- below the platform's old position. This helper detects when the player is
-- actually aiming at a moving platform and returns its CURRENT top surface
-- so bone rises / blasters land on the platform as intended.
-- Returns: aimPos (Vector3), platform (BasePart or nil)
-- =====================================================
function ResolveAimHit()
	local hit = mouse.Hit.p
	local target = mouse.Target
	
	local char = Player and Player.Character
	local effectsFolder = realWorkspace:FindFirstChild("Stuff") or realWorkspace:FindFirstChild("Effects") or (char and (char:FindFirstChild("Stuff") or char:FindFirstChild("Effects")))
	
	if target and effectsFolder and target:IsDescendantOf(effectsFolder) then
		local n = target.Name:lower()
		if n:find("platform") then
			local topY = target.Position.Y + (target.Size.Y / 2)
			return Vector3.new(hit.X, topY, hit.Z), target
		end
	end
	
	if effectsFolder then
		local ray = Ray.new(Vector3.new(hit.X, 300, hit.Z), Vector3.new(0, -500, 0))
		local ignoreList = {Character}
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p.Character and p.Character ~= Character then
				table.insert(ignoreList, p.Character)
			end
		end
		
		local maxCasts = 15
		local currentIgnore = {table.unpack(ignoreList)}
		while maxCasts > 0 do
			maxCasts = maxCasts - 1
			local hitPart, hitPos, normal, material = realWorkspace.FindPartOnRayWithIgnoreList(realWorkspace, ray, currentIgnore)
			if not hitPart then
				break
			end
			
			-- Check if hitPart is an invisible wall
			local isWall = ((hitPart.Transparency >= 0.95) or hitPart.Name:lower():find("wall") or hitPart.Name:lower():find("barrier") or hitPart.Name:lower():find("field")) and not hitPart.Name:lower():find("platform")
			
			if isWall then
				table.insert(currentIgnore, hitPart)
			elseif hitPart:IsDescendantOf(effectsFolder) then
				local n = hitPart.Name:lower()
				if n:find("platform") then
					return hitPos, hitPart
				else
					table.insert(currentIgnore, hitPart)
				end
			else
				break
			end
		end
	end
	
	return hit, nil
end

local function setupOneWayPlatformBehavior(p, isActive, canVanish, fadeSeconds, respawnSeconds)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local activeFadeSeconds = fadeSeconds or 5
	local activeRespawnSeconds = respawnSeconds or 10
	local noCollisionByCharacter = {}
	local vanished = false
	local fading = false
	local armed = true

	local function clearCollisionForCharacter(char)
		local constraints = noCollisionByCharacter[char]
		if constraints then
			for _, constraint in ipairs(constraints) do
				if constraint then constraint:Destroy() end
			end
			noCollisionByCharacter[char] = nil
		end
	end

	local function clearAllCollisions()
		for char, constraints in pairs(noCollisionByCharacter) do
			if constraints then
				for _, constraint in ipairs(constraints) do
					if constraint then constraint:Destroy() end
				end
			end
			noCollisionByCharacter[char] = nil
		end
	end

	local function setPhaseThrough(char, hrp, phaseThrough)
		local existing = noCollisionByCharacter[char]
		if phaseThrough then
			if existing then
				return
			end
			local constraints = {}
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					local noCollision = Instance.new("NoCollisionConstraint")
					noCollision.Name = "OneWayPlatformNoCollision"
					noCollision.Part0 = p
					noCollision.Part1 = part
					noCollision.Parent = p
					table.insert(constraints, noCollision)
				end
			end
			noCollisionByCharacter[char] = constraints
		else
			clearCollisionForCharacter(char)
		end
	end

	p.CanCollide = true
	p.CanTouch = true

	task.spawn(function()
		while p and p.Parent and isActive() do
			if vanished then
				p.CanCollide = false
				p.CanTouch = false
				task.wait(0.03)
			else
				local topY = p.Position.Y + (p.Size.Y / 2)
				local halfX = (p.Size.X / 2) + 2.5 -- Pad X boundaries by 2.5 studs to seamlessly cover side/edge contacts
				local halfZ = (p.Size.Z / 2) + 2.5 -- Pad Z boundaries by 2.5 studs to seamlessly cover side/edge contacts
				local anyStanding = false

				for _, plr in ipairs(Players:GetPlayers()) do
					local char = plr.Character
					if char and char ~= Character then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hrp and hum and hum.Health > 0 then
							local relPos = p.CFrame:PointToObjectSpace(hrp.Position)
							local withinXZ = math.abs(relPos.X) <= halfX and math.abs(relPos.Z) <= halfZ
							
							local velocityY = hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y or hrp.Velocity.Y
							local isAbove = hrp.Position.Y >= topY - 0.5
							
							if withinXZ then
								local shouldPhase = false
								if isAbove then
									-- If they are already above, they only phase if they are passing through the platform (center is very close to topY) AND moving upwards!
									shouldPhase = (hrp.Position.Y < topY + 1.5) and (velocityY > 1.5)
								else
									-- If they are physically below the platform, they always phase through
									shouldPhase = true
								end
								
								if shouldPhase then
									setPhaseThrough(char, hrp, true)
								else
									anyStanding = true
									setPhaseThrough(char, hrp, false)
								end
							else
								setPhaseThrough(char, hrp, false)
							end
						end
					end
				end

				p.CanCollide = true
				p.CanTouch = true

				if canVanish then
					if not anyStanding and not fading and not vanished then
						armed = true
					end

					if armed and anyStanding and not fading and not vanished then
						armed = false
						fading = true
						
						task.spawn(function()
							local steps = math.floor(activeFadeSeconds * 20)
							local stepTime = activeFadeSeconds / steps
							for i = 1, steps do
								if not (p and p.Parent and isActive()) then
									fading = false
									return
								end
								p.Transparency = i / steps
								task.wait(stepTime)
							end

							if not (p and p.Parent and isActive()) then
								fading = false
								return
							end

							vanished = true
							clearAllCollisions()
							p.CanCollide = false
							p.CanTouch = false

							task.wait(activeRespawnSeconds)
							if not (p and p.Parent and isActive()) then
								fading = false
								return
							end

							vanished = false
							p.CanCollide = true
							p.CanTouch = true
							p.Transparency = 1
							
							for i = 1, 10 do
								if not (p and p.Parent and isActive()) then
									fading = false
									return
								end
								p.Transparency = 1 - (i / 10)
								task.wait(0.05)
							end
							p.Transparency = 0
							fading = false
						end)
					end
				end
			end

			task.wait(0.03)
		end

		clearAllCollisions()
	end)
end

function swait(num)
	if _G.CancelAttackTrigger then
		coroutine.yield()
	end
	if num == 0 or num == nil then
		ArtificialHB.Event:wait()
	else
		for i = 1, num do
			if _G.CancelAttackTrigger then coroutine.yield() end
			ArtificialHB.Event:wait()
		end
	end
end

function bwait(num)
	if _G.CancelAttackTrigger then
		coroutine.yield()
	end
	if num == 0 or num == nil then
		ArtificialHB.Event:wait()
	else
		for i = 1, num do
			if _G.CancelAttackTrigger then coroutine.yield() end
			ArtificialHB.Event:wait()
		end
	end
end

function clerp(a, b, t)
	return a:lerp(b, t)
end

-- Force replace the head with a classic R6 head Part to guarantee uniform behavior, avoid face issues, and fix transparency bugs
if Head then
	local newHead = Instance.new("Part")
	newHead.Name = "Head"
	newHead.Size = Vector3.new(2, 1, 1)
	newHead.Color = Head.Color
	newHead.Material = Enum.Material.SmoothPlastic
	newHead.CFrame = Head.CFrame
	newHead.CanCollide = true
	newHead.TopSurface = Enum.SurfaceType.Smooth
	newHead.BottomSurface = Enum.SurfaceType.Smooth
	
	local mesh = Instance.new("SpecialMesh", newHead)
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	
	-- Re-weld any existing joints/welds connected to the old head (accessories, neck, etc.)
	for _, desc in pairs(Character:GetDescendants()) do
		if desc:IsA("Weld") or desc:IsA("Motor6D") or desc:IsA("WeldConstraint") then
			if desc.Part0 == Head then
				desc.Part0 = newHead
			end
			if desc.Part1 == Head then
				desc.Part1 = newHead
			end
		end
	end
	
	-- Copy attachments and other decals (except default face decals)
	for _, child in pairs(Head:GetChildren()) do
		if child:IsA("Attachment") then
			child:Clone().Parent = newHead
		elseif child:IsA("Decal") and child.Name:lower() ~= "face" then
			child:Clone().Parent = newHead
		end
	end
	
	newHead.Parent = Character
	Head:Destroy()
	Head = newHead
end

swait()
LA_Weld = newWeld(Torso, Left_Arm, -1.5, 0.5, 0)
Left_Arm.Weld.C1 = CFrame.new(0, 0.5, 0)
RA_Weld = newWeld(Torso, Right_Arm, 1.5, 0.5, 0)
Right_Arm.Weld.C1 = CFrame.new(0, 0.5, 0)
LL_Weld = newWeld(Torso, Left_Leg, -0.5, -1, 0)
Left_Leg.Weld.C1 = CFrame.new(0, 1, 0)
RL_Weld = newWeld(Torso, Right_Leg, 0.5, -1, 0)
Right_Leg.Weld.C1 = CFrame.new(0, 1, 0)
Torso_Weld = newWeld(rootPart, Torso, 0, -1, 0)
Torso.Weld.C1 = CFrame.new(0, -1, 0)
Head_Weld = newWeld(Torso, Head, 0, 1.5, 0)

_G.RightArmLocked = false
currentBeamArmC0 = nil
game:GetService("RunService").Stepped:Connect(function()
	if _G.RightArmLocked and currentBeamArmC0 and RA_Weld and RA_Weld.Parent then
		RA_Weld.C0 = currentBeamArmC0
	end
end)

local S = Instance.new("Sound")
function CreateSound(ID, PARENT, VOLUME, PITCH)
	local NEWSOUND
	coroutine.resume(coroutine.create(function()
		NEWSOUND = S:Clone()
		NEWSOUND.Parent = PARENT
		NEWSOUND.Volume = VOLUME
		NEWSOUND.Pitch = PITCH
		NEWSOUND.SoundId = "http://www.roblox.com/asset/?id=" .. ID
		swait()
		NEWSOUND:play()
		game:GetService("Debris"):AddItem(NEWSOUND, 15)
	end))
	return NEWSOUND
end

function newbosschatfunc(text,color1,color2,delay,typea)
	for _,v in next, game:service'Players':players() do
		coroutine.wrap(function()
			if(script:FindFirstChild'TalkChat' and v.Character)then
				local cha = script.TalkChat:Clone()
				cha.Color1.Value=color1
				cha.Color2.Value=color2
				cha.Text.Value=text
				cha.Ghghghghgh.Value=delay
				cha.Mode.Value=1
				cha.Parent=v.Character
				wait()
				cha.Disabled = false
				game:service'Debris':AddItem(cha,(delay/30))
			end
		end)()
	end
end

function bosschatfunc(text,color,watval,type)
	newbosschatfunc(text,BrickColor.new("Institutional white").Color,color,watval,type)
end

function Pointing()
	attack = true
	Animations = true
	local Point= Instance.new("BodyGyro")
	Point.Parent = rootPart
	Point.D = 175
	Point.P = 20000
	Point.MaxTorque = Vector3.new(0,4000000,0)
	for i = 0,0.08,0.01 do
		Point.cframe = CFrame.new(rootPart.Position,mouse.Hit.Position)
		RA_Weld.C0		= clerp(RA_Weld.C0, c_new(1.5, 0.5 + math.sin(sine/7.5)/15, 0.3) * c_angles(math.rad(90),math.rad(0),math.rad(60)), 0.15)
		LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), 0.15)
		LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0),math.rad(0),math.rad(-10)), 0.15)
		RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5, -1.05 - math.sin(sine/7.5)/5 , 0) * c_angles(math.rad(0),math.rad(0),math.rad(10)), 0.15)
		Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(0, -1 + math.sin(sine/7.5)/15, 0) * c_angles(math.rad(0), math.rad(60),math.rad(0)), 0.15)
		Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0, 1.5 - math.sin(sine/15)/15, 0) * c_angles(math.rad(-10),math.rad(-60), math.rad(0)), 0.15)
		swait()
	end
	swait(5)
	attack = false
	Animations = false
	Point:Destroy()
end

local existingFace = Character.Head:FindFirstChild("face") or Character.Head:FindFirstChild("Face")
if existingFace then existingFace:Destroy() end
-- Also remove any other decals on the head that might conflict
for _, d in pairs(Head:GetChildren()) do
	if d:IsA("Decal") and d.Name ~= "Expression" then
		d:Destroy()
	end
end
Expression = Instance.new("Decal", Head)
Expression.Name = "Expression"
Expression.Face = Enum.NormalId.Front
Expression.Texture = "rbxassetid://4484405390"
local rapid = false
local rapid2 = false
local rapid3 = false
local debouncing = false
repeat wait() until Character ~= nil

function rayCast2(Pos, Dir, Max, Ignore)
	return game:service("Workspace"):FindPartOnRay(Ray.new(Pos, Dir.unit * (Max or 999.999)), Ignore) 
end

local themeMoos = Instance.new("Sound")
themeMoos.Parent = Torso
themeMoos.SoundId = "rbxassetid://123571742502259"
themeMoos.Looped = true
themeMoos.Volume = 5
themeMoos.Pitch = 1
themeMoos.Name = "MusicTheme"
wait()
themeMoos:Play()
local Happened = false
local Death = false
local Death2 = false
local isCtrlHeld = false

local emitters={}
local emitter = Instance.new("ParticleEmitter")
emitter.Name = "Dust"
emitter.LightEmission = 1
emitter.Transparency = NumberSequence.new(0,1)
emitter.Size = NumberSequence.new(0,0.2)
emitter.SpreadAngle = Vector2.new(360,360)
emitter.Speed = NumberRange.new(0.5)
emitter.Lifetime = NumberRange.new(0.75)
emitter.Texture = "rbxassetid://241812810"
emitter.Rate = 1000
emitter.Color = ColorSequence.new(Color3.new(1,1,1))
emitter.LockedToPart = false
table.insert(emitters,emitter)
function particles(art)
	emitter:Clone().Parent = art
end

local Slash = Instance.new("Decal", Torso)
Slash.Texture = ""
local bill = script.HealthBar
bill.Frame.PName.Text = "sans"
bill.Parent = Head
FLOOR = math.floor
local damagedsound = Instance.new("Sound")
damagedsound.Name = "damaged"
damagedsound.SoundId = "rbxassetid://357417055" 
damagedsound.Pitch = 1
damagedsound.Volume = 3
damagedsound.Parent = Torso

-- ================================================= --
-- [[ 5. PHASE 3 ASSET GENERATORS ]]
-- ================================================= --
local Phase3Screen = nil
local Phase3TextLabel = nil
local Phase3ScreenWeld = nil 
local screenLines = {}

function spawnHoloScreen(text, duration, isPermanent)
	if isPermanent and Phase3Screen and Phase3Screen.Parent then
		if Phase3TextLabel then 
			table.insert(screenLines, "> " .. text)
			if #screenLines > 8 then table.remove(screenLines, 1) end
			Phase3TextLabel.Text = table.concat(screenLines, "\n")
		end
		return
	end

	local holoGroup = Instance.new("Model", Character)
	holoGroup.Name = "HoloScreenGroup"

	local screen = Instance.new("Part", holoGroup)
	screen.Name = "Screen"
	screen.Size = Vector3.new(5.5, 4, 0.1)
	screen.Material = Enum.Material.Glass
	screen.Color = Color3.fromRGB(0, 20, 0)
	screen.Transparency = 1 
	screen.CanCollide = false
	screen.Massless = true 
	screen.Anchored = false

	local weld = Instance.new("Weld", screen)
	weld.Part0 = rootPart
	weld.Part1 = screen

	if isPermanent then
		weld.C0 = CFrame.new(4.5, 1.5, 2.5) * CFrame.Angles(0, math.rad(-30), 0)
		Phase3ScreenWeld = weld
		Phase3Screen = holoGroup
		screenLines = { "> " .. text }
	else
		weld.C0 = CFrame.new(-3.5, 1.5, -2) * CFrame.Angles(0, math.rad(15), 0)
	end

	local gui = Instance.new("SurfaceGui", screen)
	gui.Face = Enum.NormalId.Front
	local txt = Instance.new("TextLabel", gui)
	txt.Size = UDim2.new(1, -30, 1, -30)
	txt.Position = UDim2.new(0, 15, 0, 15)
	txt.BackgroundTransparency = 1
	txt.Text = "" 
	txt.TextColor3 = Color3.fromRGB(0, 255, 0)
	txt.TextScaled = true
	txt.Font = Enum.Font.Code
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextYAlignment = Enum.TextYAlignment.Top
	txt.TextTransparency = 1

	if isPermanent then Phase3TextLabel = txt end

	coroutine.wrap(function()
		for i = 1, 10 do
			if screen then screen.Transparency = screen.Transparency - 0.06 end
			if txt and isPermanent then txt.TextTransparency = txt.TextTransparency - 0.1 end
			task.wait(0.05)
		end
	end)()

	if not isPermanent then
		coroutine.wrap(function()
			task.wait(0.2)
			txt.TextTransparency = 0
			local currentText = "> "
			for i = 1, #text do
				currentText = "> " .. string.sub(text, 1, i)
				txt.Text = currentText
				task.wait(0.02) 
			end

			task.wait(duration - 0.5) 
			for i = 1, 10 do
				if screen and txt then
					screen.Transparency = screen.Transparency + 0.06
					txt.TextTransparency = txt.TextTransparency + 0.1
				end
				task.wait(0.05)
			end
			if holoGroup then holoGroup:Destroy() end
		end)()
	else
		txt.TextTransparency = 0
		txt.Text = "> " .. text
	end
end

local function SpawnWingding()
	local chars = {"☠", "✡", "☼", "G", "A", "S", "T", "E", "R", "!", "?", "@", "%"}
	local p = Instance.new("Part")
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.Position = rootPart.Position + Vector3.new(math.random(-40,40)/10, math.random(-30,20)/10, math.random(-40,40)/10)
	p.Parent = realWorkspace

	local bgui = Instance.new("BillboardGui", p)
	bgui.Size = UDim2.new(1.5, 0, 1.5, 0)

	local txt = Instance.new("TextLabel", bgui)
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Text = chars[math.random(1, #chars)]
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextScaled = true
	txt.Font = Enum.Font.Arcade

	coroutine.wrap(function()
		for t = 1, 30 do
			p.Position = p.Position + Vector3.new(0, 0.15, 0)
			txt.TextTransparency = t/30
			game:GetService("RunService").Stepped:Wait()
		end
		p:Destroy()
	end)()
end

function createSkeletonHand(parent, handName, handColor)
	local GHand = Instance.new("Part", parent)
	GHand.Name = handName
	GHand.Size = Vector3.new(0.6, 0.2, 0.6)
	GHand.Transparency = 1 
	GHand.CanCollide = false
	GHand.Massless = true
	GHand.Anchored = false

	local function createHandPiece(name, size, offset, angle)
		local p = Instance.new("Part", GHand)
		p.Name = name
		p.Size = size
		p.Color = handColor
		p.Material = Enum.Material.Neon
		p.CanCollide = false
		p.Massless = true
		p.Anchored = false
		local w = Instance.new("Weld", p)
		w.Part0 = GHand
		w.Part1 = p
		w.C0 = CFrame.new(offset) * (angle or CFrame.Angles(0,0,0))
		return p
	end

	createHandPiece("PalmLeft", Vector3.new(0.15, 0.15, 0.6), Vector3.new(-0.2, 0, 0))
	createHandPiece("PalmRight", Vector3.new(0.15, 0.15, 0.6), Vector3.new(0.2, 0, 0))
	createHandPiece("PalmTop", Vector3.new(0.25, 0.15, 0.15), Vector3.new(0, 0, -0.225))
	createHandPiece("PalmBottom", Vector3.new(0.25, 0.15, 0.15), Vector3.new(0, 0, 0.225))
	createHandPiece("Index", Vector3.new(0.1, 0.1, 0.3), Vector3.new(-0.15, 0, -0.45))
	createHandPiece("Middle", Vector3.new(0.1, 0.1, 0.35), Vector3.new(-0.025, 0, -0.475))
	createHandPiece("Ring", Vector3.new(0.1, 0.1, 0.3), Vector3.new(0.1, 0, -0.45))
	createHandPiece("Pinky", Vector3.new(0.1, 0.1, 0.2), Vector3.new(0.225, 0, -0.4))

	return GHand
end

function createGrippingSkeletonHand(parent, handName, handColor)
	local GHand = Instance.new("Part", parent)
	GHand.Name = handName
	GHand.Size = Vector3.new(0.6, 0.2, 0.6)
	GHand.Transparency = 1 
	GHand.CanCollide = false
	GHand.Massless = true
	GHand.Anchored = false

	local function createHandPiece(name, size, offset, angle)
		local p = Instance.new("Part", GHand)
		p.Name = name
		p.Size = size
		p.Color = handColor
		p.Material = Enum.Material.SmoothPlastic -- FIX: SmoothPlastic material
		p.CanCollide = false
		p.Massless = true
		p.Anchored = false
		local w = Instance.new("Weld", p)
		w.Part0 = GHand
		w.Part1 = p
		w.C0 = CFrame.new(offset) * (angle or CFrame.Angles(0,0,0))
		return p
	end

	createHandPiece("PalmLeft", Vector3.new(0.15, 0.15, 0.6), Vector3.new(-0.2, 0, 0))
	createHandPiece("PalmRight", Vector3.new(0.15, 0.15, 0.6), Vector3.new(0.2, 0, 0))
	createHandPiece("PalmTop", Vector3.new(0.25, 0.15, 0.15), Vector3.new(0, 0, -0.225))
	createHandPiece("PalmBottom", Vector3.new(0.25, 0.15, 0.15), Vector3.new(0, 0, 0.225))

	local gripAngle = CFrame.Angles(math.rad(-70), 0, 0)
	createHandPiece("Index", Vector3.new(0.1, 0.1, 0.3), Vector3.new(-0.15, -0.15, -0.3), gripAngle)
	createHandPiece("Middle", Vector3.new(0.1, 0.1, 0.35), Vector3.new(-0.025, -0.17, -0.32), gripAngle)
	createHandPiece("Ring", Vector3.new(0.1, 0.1, 0.3), Vector3.new(0.1, -0.15, -0.3), gripAngle)

	createHandPiece("Pinky", Vector3.new(0.1, 0.1, 0.2), Vector3.new(0.25, -0.1, -0.15), CFrame.Angles(math.rad(40), math.rad(-45), 0))

	return GHand
end

function UniversalFade(targetGroup, targetTrans, duration)
	coroutine.wrap(function()
		local steps = math.floor(duration * 30)
		if steps <= 0 then steps = 1 end
		local waitTime = duration / steps

		local items = {}
		local ignoreNames = {
			["HumanoidRootPart"] = true, ["BlockBone"] = true, 
			["GasterHand"] = true,
			["Hand1"] = true, ["Hand2"] = true, ["Hand3"] = true, 
			["Hand4"] = true,
			["Point X"] = true, ["Point XYZ"] = true,
			["Special"] = true, ["Shield"] = true, ["Shield2"] = true
		}

		local function addObj(p)
			if ignoreNames[p.Name] then return end
			if p:IsA("BasePart") and p.Transparency >= 1 and targetTrans < 1 then
				if p.Name:match("Root") or p.Name:match("Invisible") or p.Size == Vector3.new(0.6, 0.2, 0.6) then
					return
				end
			end
			-- FIX: Ignored Highlight so Gaster doesn't turn pitch black
			if p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture") then
				table.insert(items, {obj = p, startTrans = p.Transparency, isText = false})
			elseif p:IsA("TextLabel") then
				table.insert(items, {obj = p, startTrans = p.TextTransparency, isText = true})
			end
		end

		if typeof(targetGroup) == "Instance" then
			addObj(targetGroup)
			for _, p in pairs(targetGroup:GetDescendants()) do addObj(p) end
		end

		for i = 1, steps do
			local alpha = i / steps
			for _, data in ipairs(items) do
				if data.obj and data.obj.Parent then
					if data.isText then
						data.obj.TextTransparency = data.startTrans + (targetTrans - data.startTrans) * alpha
					else
						data.obj.Transparency = data.startTrans + (targetTrans - data.startTrans) * alpha
					end
				end
			end
			task.wait(waitTime)
		end
	end)()
end

_G.ScreenOffsetL = CFrame.new(-3.5, 2, 0)
_G.ScreenRotL    = CFrame.Angles(0, math.rad(25), 0)
_G.ScreenOffsetR = CFrame.new(3.5, 2, 2.5)
_G.ScreenRotR    = CFrame.Angles(0, math.rad(-25), 0)
_G.CursorIdleOffset = CFrame.new(-0.6, -0.4, -0.15) * CFrame.Angles(0, 0, math.rad(-25))

local function setupCursorAndScreen(parent, isRight)
	local ms = Instance.new("Part", parent)
	ms.Name = "MiniHoloScreen" -- FIX: Renamed so UniversalFade doesn't ignore it
	ms.Size = Vector3.new(1.8, 1.2, 0.05)
	ms.Color = Color3.fromRGB(0, 20, 0)
	ms.Material = Enum.Material.Glass
	ms.Transparency = 1 
	ms.CanCollide, ms.Massless = false, true
	ms.Anchored = false
	local sWeld = Instance.new("Weld", ms) sWeld.Part0 = rootPart sWeld.Part1 = ms

	local gui = Instance.new("SurfaceGui", ms) 
	gui.Face = Enum.NormalId.Front
	local txt = Instance.new("TextLabel", gui)
	txt.Size = UDim2.new(1, -10, 1, -10) txt.Position = UDim2.new(0, 5, 0, 5)
	txt.BackgroundTransparency = 1 txt.TextColor3 = Color3.new(0,1,0)
	txt.TextScaled = true txt.Font = Enum.Font.Code txt.Text = "code\n..."
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextTransparency = 1 

	coroutine.wrap(function()
		while ms.Parent do
			local lines = {}
			for j=1, 4 do table.insert(lines, "0x"..string.format("%04X", math.random(0, 65535))) end
			txt.Text = table.concat(lines, "\n")
			task.wait(1.2) 
		end
	end)()

	local cursorPart = Instance.new("Part", parent)
	cursorPart.Name = "InvisibleCursorRoot"
	cursorPart.Size = Vector3.new(0.2, 0.2, 0.2)
	cursorPart.Transparency = 1
	cursorPart.CanCollide, cursorPart.Massless = false, true
	cursorPart.Anchored = false

	local cursorColor = Color3.fromRGB(255, 255, 255)
	local cursorMat = Enum.Material.SmoothPlastic

	local palm = Instance.new("Part", cursorPart)
	palm.Name = "CursorHandPiece"
	palm.Size = Vector3.new(0.4, 0.4, 0.1)
	palm.Color = cursorColor palm.Material = cursorMat
	palm.CanCollide, palm.Massless, palm.Anchored = false, true, false
	palm.Transparency = 1
	local wp = Instance.new("Weld", palm) wp.Part0 = cursorPart wp.Part1 = palm
	wp.C0 = CFrame.new(0, -0.1, 0)

	local indexF = Instance.new("Part", cursorPart)
	indexF.Name = "CursorHandPiece"
	indexF.Size = Vector3.new(0.12, 0.45, 0.1)
	indexF.Color = cursorColor indexF.Material = cursorMat
	indexF.CanCollide, indexF.Massless, indexF.Anchored = false, true, false
	indexF.Transparency = 1
	local wIndex = Instance.new("Weld", indexF) wIndex.Part0 = cursorPart wIndex.Part1 = indexF
	wIndex.C0 = CFrame.new(-0.1, 0.3, 0)

	local foldedF = Instance.new("Part", cursorPart)
	foldedF.Name = "CursorHandPiece"
	foldedF.Size = Vector3.new(0.3, 0.2, 0.1)
	foldedF.Color = cursorColor foldedF.Material = cursorMat
	foldedF.CanCollide, foldedF.Massless, foldedF.Anchored = false, true, false
	foldedF.Transparency = 1
	local wFolded = Instance.new("Weld", foldedF) wFolded.Part0 = cursorPart wFolded.Part1 = foldedF
	wFolded.C0 = CFrame.new(0.1, 0.1, 0)

	local thumb = Instance.new("Part", cursorPart)
	thumb.Name = "CursorHandPiece"
	thumb.Size = Vector3.new(0.15, 0.2, 0.1)
	thumb.Color = cursorColor thumb.Material = cursorMat
	thumb.CanCollide, thumb.Massless, thumb.Anchored = false, true, false
	thumb.Transparency = 1
	local wThumb = Instance.new("Weld", thumb) wThumb.Part0 = cursorPart wThumb.Part1 = thumb
	wThumb.C0 = CFrame.new(-0.25, -0.05, 0)

	local cWeld = Instance.new("Weld", cursorPart) cWeld.Part0 = rootPart cWeld.Part1 = cursorPart

	return cWeld, sWeld, cursorPart, ms
end

function spawnDustPuddle(centerCFrame)
	local DustFolder = Instance.new("Model", realWorkspace)
	DustFolder.Name = "SansDustPile"

	local BaseDust = Instance.new("Part", DustFolder)
	BaseDust.Anchored = true
	BaseDust.CanCollide = false
	BaseDust.Size = Vector3.new(0, 0, 0) 
	BaseDust.CFrame = centerCFrame * CFrame.new(0, -2.8, 0)
	BaseDust.BrickColor = BrickColor.new("Institutional white")
	BaseDust.Material = Enum.Material.Sand
	local BaseMesh = Instance.new("SpecialMesh", BaseDust)
	BaseMesh.MeshType = Enum.MeshType.Sphere

	local lumps = {}
	for l = 1, 6 do
		local lump = BaseDust:Clone()
		lump.Parent = DustFolder
		local angle = math.rad(l * (360/6) + math.random(-20, 20))
		local dist = math.random(6, 12) / 10
		local sizeScale = math.random(5, 9) / 10 
		lump.Size = Vector3.new(0, 0, 0)
		lump.CFrame = BaseDust.CFrame * CFrame.new(math.cos(angle) * dist, -0.1, math.sin(angle) * dist)
		table.insert(lumps, {part = lump, targetSize = Vector3.new(4 * sizeScale, 0.6 * sizeScale, 4 * sizeScale)})
	end

	local ts = game:GetService("TweenService")
	local tiForm = TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	ts:Create(BaseDust, tiForm, {Size = Vector3.new(4, 0.6, 4)}):Play()
	for _, data in ipairs(lumps) do
		ts:Create(data.part, tiForm, {Size = data.targetSize}):Play()
	end

	coroutine.wrap(function()
		task.wait(6)
		local windSound = Instance.new("Sound", BaseDust)
		windSound.SoundId = "rbxassetid://444667611" 
		windSound.Volume = 3
		windSound.PlaybackSpeed = 0.8
		windSound:Play()

		local ts = game:GetService("TweenService")
		local ti = TweenInfo.new(3, Enum.EasingStyle.Linear)

		for _, part in pairs(DustFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local emit = Instance.new("ParticleEmitter", part)
				emit.Texture = "rbxassetid://241812810"
				emit.Color = ColorSequence.new(Color3.new(1,1,1))
				emit.Size = NumberSequence.new(0.3, 0)
				emit.Speed = NumberRange.new(5, 15)
				emit.Acceleration = Vector3.new(15, 2, 0) 
				emit.SpreadAngle = Vector2.new(15, 15)
				emit.Rate = 50
				emit.Lifetime = NumberRange.new(1, 2.5)

				ts:Create(part, ti, {Size = Vector3.new(0,0,0), Transparency = 1}):Play()
			end
		end

		task.wait(3)
		for _, part in pairs(DustFolder:GetChildren()) do
			if part:IsA("BasePart") and part:FindFirstChildOfClass("ParticleEmitter") then
				part:FindFirstChildOfClass("ParticleEmitter").Enabled = false
			end
		end
		task.wait(2.5)
		DustFolder:Destroy()
	end)()
end

-- ================================================= --
-- [[ 6. DODGE BAR & UI LOGIC ]]
-- ================================================= --
local MaxDodges = 25 
local CurrentDodges = MaxDodges
local CurrentMode = "Dodges" 
local dodgeDebounce = false 
local Phase3Timer = 60 
local GlitchText = ""
local Phase2_5Timer = 15 
local Phase2_5_Completed = false

local function UpdateDodgeBar()
	if not Head:FindFirstChild("HealthBar") then return end
	local frame = Head.HealthBar.Frame
	local bar = frame.Health
	local label = frame.HealthLabel
	local pname = frame.PName

	local maxBarWidth = 0.55 
	local barHeight = 0.25

	local bgBar = frame:FindFirstChild("BgBar")
	if not bgBar then
		bgBar = Instance.new("Frame")
		bgBar.Name = "BgBar"
		bgBar.Parent = frame
		bgBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		bgBar.BorderSizePixel = 0
		bgBar.Position = bar.Position
		bgBar.ZIndex = 1
	end
	bgBar.Size = UDim2.new(maxBarWidth, 0, barHeight, 0)
	bar.ZIndex = 2 

	local leftLabel = frame:FindFirstChild("DynamicLeftLabel")
	if not leftLabel then
		leftLabel = Instance.new("TextLabel")
		leftLabel.Name = "DynamicLeftLabel"
		leftLabel.Parent = frame
		leftLabel.BackgroundTransparency = 1
		leftLabel.Position = UDim2.new(0, 0, bar.Position.Y.Scale, bar.Position.Y.Offset)
		leftLabel.Size = UDim2.new(bar.Position.X.Scale, bar.Position.X.Offset - 5, barHeight, 0)
		leftLabel.Font = Enum.Font.Arcade
		leftLabel.TextScaled = true
		leftLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		leftLabel.TextStrokeTransparency = 0
		leftLabel.TextXAlignment = Enum.TextXAlignment.Right

		for _, v in pairs(frame:GetChildren()) do
			if v:IsA("GuiObject") and v ~= leftLabel and v ~= bar and v ~= label and v ~= pname and v ~= bgBar then
				v.Visible = false
			end
		end
	end

	label.Position = bar.Position
	label.Size = UDim2.new(maxBarWidth, 0, barHeight, 0) 
	label.ZIndex = 5
	label.TextStrokeTransparency = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true 
	label.TextWrapped = true

	local constraint = label:FindFirstChild("TextConstraint")
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Name = "TextConstraint"
		constraint.Parent = label
		constraint.MaxTextSize = 22 
	end

	if CurrentMode == "Transition" then
		pname.Text = "sans"
		leftLabel.Text = "HP"
		if Death == true or Death2 == true then
			label.Text = "0 / 1"
			bar:TweenSize(UDim2.new(0, 0, barHeight, 0), "Out", "Quad", 0.2, true)
		else
			label.Text = "0.0001 / 1"
			bar:TweenSize(UDim2.new(0.01 * maxBarWidth, 0, barHeight, 0), "Out", "Quad", 0.2, true)
		end
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) 
		bgBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

	elseif CurrentMode == "Dodges" or CurrentMode == "Blocks" then
		pname.Text = "sans"
		leftLabel.Text = CurrentMode:upper()
		label.Text = CurrentDodges .. " / " .. MaxDodges
		bar:TweenSize(UDim2.new((CurrentDodges / MaxDodges) * maxBarWidth, 0, barHeight, 0), "Out", "Quad", 0.2, true)
		bar.BackgroundColor3 = (CurrentMode == "Dodges") and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 85, 0)
		bgBar.BackgroundColor3 = Color3.fromRGB(150, 0, 0)

	elseif CurrentMode == "HP" then
		pname.Text = "sans"
		leftLabel.Text = "HP"
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
		bgBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

		if Death == false and Death2 == false then
			label.Text = "1 / 1"
			bar:TweenSize(UDim2.new(1 * maxBarWidth, 0, barHeight, 0), "Out", "Quad", 0.2, true)
		elseif Death == true and Death2 == false then
			label.Text = "0.0001 / 1"
			bar:TweenSize(UDim2.new(0.01 * maxBarWidth, 0, barHeight, 0), "Out", "Quad", 0.2, true)
		end

	elseif CurrentMode == "Transition2_5" then
		pname.Text = "sans"
		leftLabel.Text = "BLOCKS"
		label.Text = "1 / " .. MaxDodges
		bar.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
		bgBar.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		bar:TweenSize(UDim2.new((1 / MaxDodges) * maxBarWidth, 0, barHeight, 0), "Out", "Quad", 0.2, true)

	elseif CurrentMode == "Timer2_5" then
		pname.Text = "LAST STAND"
		leftLabel.Text = "TIMER"
		label.Text = Phase2_5Timer .. "s" 
		bgBar.BackgroundColor3 = Color3.fromRGB(0, 0, 60)
		bar.BackgroundColor3 = Color3.fromRGB(0, 200, 255) 
		bar:TweenSize(UDim2.new((Phase2_5Timer / 15) * maxBarWidth, 0, barHeight, 0), "Out", "Linear", 1, true)

	elseif CurrentMode == "Timer" then
		pname.Text = "Time: " .. Phase3Timer .. "s" 
		leftLabel.Text = "HP"
		label.Text = GlitchText 
		bgBar.BackgroundColor3 = Color3.fromRGB(80, 0, 0) 
		bar:TweenSize(UDim2.new((Phase3Timer / 60) * maxBarWidth, 0, barHeight, 0), "Out", "Linear", 1, true)

	elseif CurrentMode == "Dead" then
		pname.Text = "sans"
		leftLabel.Text = "HP"
		label.Text = "0 / 1"
		bar:TweenSize(UDim2.new(0, 0, barHeight, 0), "Out", "Quad", 0.2, true)
	end
end

UpdateDodgeBar()

Humanoid.HealthChanged:Connect(function()
	if _G.InTransition then
		if Humanoid.Health < Humanoid.MaxHealth then
			Humanoid.Health = Humanoid.MaxHealth
		end
		return
	end
	if CurrentMode == "Timer" or CurrentMode == "Timer2_5" or CurrentMode == "Transition" or CurrentMode == "Dead" then 
		if Humanoid.Health < Humanoid.MaxHealth then
			Humanoid.Health = Humanoid.MaxHealth -- Prevent bar drops completely!
		end
		return 
	end 
	if CurrentDodges <= 0 and Humanoid.Health < Humanoid.MaxHealth then
		damagedsound:Play()
	end
	UpdateDodgeBar()
end)

local lockedEntities = {}

local function LockArena(radius)
	lockedEntities = {}
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= Character then
			local eRoot = obj:FindFirstChild("HumanoidRootPart")
			local eHum = obj:FindFirstChildOfClass("Humanoid")
			if eRoot and eHum then
				local dist = (eRoot.Position - rootPart.Position).Magnitude
				if dist <= radius then
					local GUI = Instance.new("BillboardGui")
					GUI.Name = "BlueHeartLock"
					GUI.Size = UDim2.new(2,0,2,0)
					GUI.MaxDistance = 150
					GUI.AlwaysOnTop = true
					GUI.Parent = eRoot

					local Body = Instance.new("ImageLabel",GUI)
					Body.Image = "rbxassetid://338425795" 
					Body.BackgroundTransparency = 1
					Body.Size = UDim2.new(1,0,1,0)

					local FF = Instance.new("ForceField", obj)
					FF.Visible = false

					table.insert(lockedEntities, {
						Humanoid = eHum,
						OldWS = eHum.WalkSpeed,
						OldJP = eHum.JumpPower,
						GUI = GUI,
						FF = FF
					})
					eHum.WalkSpeed = 0
					eHum.JumpPower = 0
				end
			end
		end
	end
	Humanoid.WalkSpeed = 0
	Humanoid.JumpPower = 0
end

local function UnlockArena()
	for _, data in ipairs(lockedEntities) do
		if data.Humanoid and data.Humanoid.Parent then
			data.Humanoid.WalkSpeed = data.OldWS
			data.Humanoid.JumpPower = data.OldJP
		end
		if data.GUI then data.GUI:Destroy() end
		if data.FF then data.FF:Destroy() end
	end
	lockedEntities = {}
	Humanoid.WalkSpeed = 16
	Humanoid.JumpPower = 0
end

-- ================================================= --
-- [[ 7. PHASE TRANSITIONS (START, DEAD, DEAD2) ]]
-- ================================================= --
function Start()
	Animations = true
	attack = true
	themeMoos:Stop()
	Expression.Texture = "rbxassetid://4484446057"
	chatfunc("* it's a beautiful day outside.")
	wait(3)
	chatfunc("* birds are singing, flowers are blooming...")
	wait(5)
	chatfunc("* on days like these, kids like you...")
	wait(4)
	Expression.Texture = "rbxassetid://4484436948"
	chatfunc("* Should be burning in hell.")
	wait(15)
	idle=idly
	Animations = true
	Expression.Texture = "rbxassetid://4484405390"
	chatfunc("* huh.")
	wait(6)
	Expression.Texture = "rbxassetid://4484407199"
	chatfunc("* always wondered why people never use their strongest attack first.")
	wait(5)
	Expression.Texture = "rbxassetid://4484405390"
	themeMoos:Play()
	bosschatfunc("* You feel like you're going to have a bad time.",BrickColor.new("Institutional white").Color,120)
	Animations = false
	attack = false
end

function Dead()
	_G.InTransition = "Phase2"
	local function cWait(sec)
		local start = tick()
		while tick() - start < sec do
			if _G.CancelAttackTrigger then return true end
			task.wait(0.05)
		end
		return false
	end

	local function runSkipPhase2()
		_G.InTransition = nil
		if Character:FindFirstChild("Soul") then
			for _, part in pairs(Character:GetChildren()) do
				if part.Name == "Soul" then part:Destroy() end
			end
		end
		if Slash then Slash.Transparency = 1 end

		Sanim = 0.0001
		attack = false
		attack2 = false
		Animations = false

		Humanoid.MaxHealth = 100
		Humanoid.Health = 100

		MaxDodges = 25 
		CurrentDodges = MaxDodges
		CurrentMode = "Blocks"
		UpdateDodgeBar()

		if not Character:FindFirstChild("Phase2Weapon") then
			local p2Bone = Instance.new("Part", Character)
			p2Bone.Name = "Phase2Weapon"
			p2Bone.Size = Vector3.new(0.2, 2, 0.2)
			p2Bone.BrickColor = BrickColor.new("White")
			p2Bone.Material = "SmoothPlastic"
			p2Bone.CanCollide = false
			p2Bone.Massless = true

			local bMesh = Instance.new("SpecialMesh", p2Bone)
			bMesh.MeshType = "FileMesh"
			bMesh.MeshId = "http://www.roblox.com/asset/?id=921085633"
			bMesh.Scale = Vector3.new(0.010, 0.010, 0.010)
			local bWeld = Instance.new("Weld", p2Bone)
			bWeld.Part0 = Right_Arm
			bWeld.Part1 = p2Bone
			bWeld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0.8, 0)
		else
			Character.Phase2Weapon.Transparency = 0
		end

		UnlockArena() 
		pcall(CreateMovesGUI)

		dodgeDebounce = true
		coroutine.wrap(function()
			task.wait(2)
			dodgeDebounce = false
		end)()
	end

	CurrentMode = "Transition" 
	UpdateDodgeBar()
	pcall(function() CreateMovesGUI() end)
	LockArena(150) 
	spawnHoloScreen("sans.def = 9999\n> scanning anomalies...\n> intercepting attack code...\n> block successful.", 3)
	UniversalFade(Character, 0.2, 1)

	for _, c in pairs(Character:GetChildren()) do
		if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then
			if not c:FindFirstChild("Dust") then
				particles(c)
			end
			c.Dust.Rate = 50 
		end
	end

	for _, part in pairs(Character:GetChildren()) do
		if part.Name == "Soul" then part:Destroy() end
	end

	attack = true
	attack2 = true
	Animations = true
	candodge = false
	dodging = false
	Happened = true
	canblock = true
	blocking = false
	Humanoid.MaxHealth = math.huge
	Humanoid.Health = math.huge
	Expression.Texture = "rbxassetid://1371827222"
	local Dizz = Instance.new("Sound")
	Dizz.Parent = Character.Torso
	Dizz.SoundId = "rbxassetid://623904185"
	Dizz.Volume = 10
	Dizz.Looped = false
	Dizz.Pitch = 1
	Dizz:Play()
	Slash.Texture = "rbxassetid://403969152"

	themeMoos:Stop()
	themeMoos.Pitch = 1
	themeMoos.Volume = 10
	themeMoos.SoundId = "rbxassetid://110567314004188"
	themeMoos:Play()

	-- 1. KNEEL DOWN FIRST (Torso Y Drops to -2)
	for fallStep = 1, 20 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(20), math.rad(0), math.rad(10)), 0.1)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.2, 0.1, -0.6) * c_angles(math.rad(80), math.rad(0), math.rad(30)), 0.1) 
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, -0.5) * c_angles(math.rad(-20), math.rad(0), math.rad(0)), 0.1) 
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.8) * c_angles(math.rad(-10), math.rad(0), math.rad(0)), 0.1) 
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -2.2, -0.5) * c_angles(math.rad(-30), math.rad(-15), math.rad(-10)), 0.1) 
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-10), math.rad(15), math.rad(0)), 0.1)
		swait()
	end

	if cWait(1.0) then runSkipPhase2() return end

	-- 2. COLLAPSE TO SIT ON GROUND (Torso Y Drops to -3, Identical to P2 Transition)
	for fallStep = 1, 30 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(-20),0), 0.15)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(20),0), 0.15)
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, 0) * c_angles(math.rad(60),math.rad(20),0), 0.15)
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(60),math.rad(-20),0), 0.15)
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -3, 0) * c_angles(math.rad(20), 0, 0), 0.15)
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-20),0,0), 0.15)
		swait()
	end

	local Soul1 = Instance.new("Part", Character)
	Soul1.Name = "Soul"
	Soul1.Anchored = true
	Soul1.Shape = Enum.PartType.Block
	Soul1.CanCollide = false
	Soul1.BrickColor = BrickColor.new("Institutional white")
	Soul1.Transparency = 0.001
	Soul1.Material = "Neon"
	Soul1.Size = Vector3.new(0.26, 0.5, 0.21)
	local M1 = Instance.new("SpecialMesh", Soul1)
	M1.MeshType = "Sphere"

	local Soul2 = Soul1:Clone()
	Soul2.Parent = Character

	Dizz:Destroy()
	S = Instance.new("Sound", Character.Torso)
	S.SoundId = "rbxassetid://1292392651"
	S.Volume = 10
	S.Looped = false
	S.Pitch = 1
	S:Play()

	Soul1.CFrame = rootPart.CFrame * CFrame.new(0.1, 1, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(30))
	Soul2.CFrame = rootPart.CFrame * CFrame.new(-0.1, 1, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(-30))

	Death = true

	chatfunc("* ...")
	if cWait(2) then runSkipPhase2() return end
	S:Stop()
	for i = 0,1.7,0.01 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		Soul1.CFrame = rootPart.CFrame * CFrame.new(math.random(5,15)/100, math.random(95,105)/100, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(30))
		Soul2.CFrame = rootPart.CFrame * CFrame.new(math.random(-15,-5)/100, math.random(95,105)/100, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(-30))
		swait()
	end
	chatfunc("* !?")
	if cWait(3) then runSkipPhase2() return end
	CreateSound("446961725", Head, 7, 1)

	Soul1.CFrame = rootPart.CFrame * CFrame.new(0.1, 1, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(30))
	Soul2.CFrame = rootPart.CFrame * CFrame.new(-0.1, 1, -1)*CFrame.fromEulerAnglesXYZ(0,0,math.rad(-30))
	if cWait(5) then runSkipPhase2() return end
	for i = 1,60,2 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		Soul1.Transparency = i/30
		Soul2.Transparency = i/30
		swait()
	end
	if cWait(2) then runSkipPhase2() return end
	chatfunc("* i'm not throwing in the towel just yet.")
	Expression.Texture = "rbxassetid://4899271896"

	for i = 1, 45 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(20), math.rad(0), math.rad(10)), 0.1)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.2, 0.1, -0.6) * c_angles(math.rad(80), math.rad(0), math.rad(30)), 0.1) 
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, -0.5) * c_angles(math.rad(-20), math.rad(0), math.rad(0)), 0.1) 
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.8) * c_angles(math.rad(-10), math.rad(0), math.rad(0)), 0.1) 
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -2.2, -0.5) * c_angles(math.rad(-30), math.rad(-15), math.rad(-10)), 0.1) 
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-10), math.rad(15), math.rad(0)), 0.1)
		swait()
	end

	if cWait(3) then runSkipPhase2() return end
	chatfunc("* ...")
	if cWait(3) then runSkipPhase2() return end
	for i = 1, 60 do
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		RA_Weld.C0		= clerp(RA_Weld.C0, c_new(1.25, 0.3, 0) * c_angles(math.rad(23),math.rad(0),math.rad(0)), 0.05)
		LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3, 0) * c_angles(math.rad(23),math.rad(0),math.rad(0)), 0.05)
		LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5, -1.05, 0) * c_angles(math.rad(20),math.rad(0),math.rad(-10)), 0.05)
		RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5, -1.05, 0) * c_angles(math.rad(20),math.rad(0),math.rad(10)), 0.05)
		Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(0, -0.95, 0) * c_angles(math.rad(-20), math.rad(0),math.rad(0)), 0.05)
		Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(0),math.rad(0), math.rad(0)), 0.05)
		swait()
	end
	if cWait(1) then runSkipPhase2() return end
	Animations = false
	chatfunc("* because even if this fight is unwinnable")
	Expression.Texture = "rbxassetid://4899271517"
	if cWait(3) then runSkipPhase2() return end
	chatfunc("* i am willing to give it my all.")
	if cWait(3) then runSkipPhase2() return end
	chatfunc("it's not like i have any other choice...")
	if cWait(3) then runSkipPhase2() return end
	chatfunc("* i am willing to put you into place once and for all.")
	if cWait(3) then runSkipPhase2() return end
	chatfunc("* and even if i fail..")
	if cWait(2) then runSkipPhase2() return end
	chatfunc("* at least i die with a feeling of satisfaction.")
	if cWait(3) then runSkipPhase2() return end
	chatfunc("* that i finally got to see who you really are.")
	if cWait(3) then runSkipPhase2() return end
	chatfunc("* prepare yourself, kid... or whatever you are.")
	if cWait(5) then runSkipPhase2() return end
	chatfunc("* because...")
	local Rev = Instance.new("Sound", Character.Torso)
	Rev.SoundId = "rbxassetid://364420478"
	Rev.Volume = 10
	Rev:Play()
	repeat
		if _G.CancelAttackTrigger then runSkipPhase2() return end
		wait()
	until Rev.Playing == false
	local RevB = Instance.new("Sound", Character.Torso)
	RevB.SoundId = "rbxassetid://446961725"
	RevB.Volume = 10
	RevB:Play()
	Expression.Texture = "rbxassetid://4899271236"
	chatfunc("* you're about to get dunked on even harder than before.")
	if cWait(2.4) then runSkipPhase2() return end
	themeMoos:Stop()
	themeMoos.Pitch = 1
	themeMoos.Volume = 5
	themeMoos.SoundId = "rbxassetid://95134271083417"
	themeMoos:Play()
	bosschatfunc("* Sans is 'dead' serious about this.",BrickColor.new("Institutional white").Color,120)

	if Character:FindFirstChild("Soul") then
		for _, part in pairs(Character:GetChildren()) do
			if part.Name == "Soul" then part:Destroy() end
		end
	end

	Sanim = 0.0001
	attack = false
	attack2 = false
	Animations = false

	Humanoid.MaxHealth = 100
	Humanoid.Health = 100

	MaxDodges = 25 
	CurrentDodges = MaxDodges
	CurrentMode = "Blocks"
	UpdateDodgeBar()

	local p2Bone = Instance.new("Part", Character)
	p2Bone.Name = "Phase2Weapon"
	p2Bone.Size = Vector3.new(0.2, 2, 0.2)
	p2Bone.BrickColor = BrickColor.new("White")
	p2Bone.Material = "SmoothPlastic"
	p2Bone.CanCollide = false
	p2Bone.Massless = true

	local bMesh = Instance.new("SpecialMesh", p2Bone)
	bMesh.MeshType = "FileMesh"
	bMesh.MeshId = "http://www.roblox.com/asset/?id=921085633"
	bMesh.Scale = Vector3.new(0.010, 0.010, 0.010)
	local bWeld = Instance.new("Weld", p2Bone)
	bWeld.Part0 = Right_Arm
	bWeld.Part1 = p2Bone
	bWeld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0.8, 0)

	UnlockArena() 
	pcall(CreateMovesGUI)

	dodgeDebounce = true
	coroutine.wrap(function()
		task.wait(5)
		dodgeDebounce = false
	end)()

	_G.InTransition = nil
	return
end

local GHand_X = 1.4
local GHand_Y = 1
local GHand_Z = 0
local GHand_RotX = 15
local GHand_RotY = 15
local GHand_RotZ = 15

local EyeSettings = {
	OffsetX = 0.16,
	OffsetY = 0.16,
	DepthZ  = -0.6,
	SizeX   = 0.45,
	SizeY   = 0.27,
	MakeRound = false
}

local p3Wingdings = false

function Phase2Point5()
	_G.InTransition = "Phase2.5"
	local function cWait(sec)
		local start = tick()
		while tick() - start < sec do
			if _G.CancelAttackTrigger then return true end
			task.wait(0.05)
		end
		return false
	end

	local function runSkipPhase2_5()
		_G.InTransition = nil
		if BodyGlow then BodyGlow.FillTransparency, BodyGlow.OutlineTransparency = 0.7, 0.4 end
		if GhostGroup then
			for _, v in pairs(GhostGroup:GetChildren()) do
				if v.Name ~= "GuardianGB" then v:Destroy() end
			end
		end
		
		UnlockArena()
		attack, attack2, Animations = false, false, false
		CurrentMode, Phase2_5Timer = "Timer2_5", 15
		UpdateDodgeBar()

		coroutine.wrap(function()
			for t = 15, 0, -1 do
				if CurrentMode ~= "Timer2_5" then break end
				Phase2_5Timer = t
				UpdateDodgeBar()
				if t <= 0 then
					LockArena(150) 
					CurrentMode = "Transition2_5"
					UpdateDodgeBar()

					coroutine.wrap(function()
						for f = 1, 20 do
							if BodyGlow then BodyGlow.FillTransparency = BodyGlow.FillTransparency + 0.05 BodyGlow.OutlineTransparency = BodyGlow.OutlineTransparency + 0.05 end
							task.wait(0.05)
						end
						if BodyGlow then BodyGlow:Destroy() end
					end)()

					-- RESTORE ORIGINAL WHITE DUST
					for _, c in pairs(Character:GetChildren()) do
						if c:IsA("BasePart") and c:FindFirstChild("Dust") then
							c.Dust.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
							c.Dust.Rate, c.Dust.Speed = 50, NumberRange.new(0.5)
							c.Dust.SpreadAngle, c.Dust.Acceleration = Vector2.new(360, 360), Vector3.new(0, 0, 0)
							c.Dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0)})
						end
					end

					chatfunc("* alright... guess you lived.")
					task.wait(2.5)
					if GhostGroup then GhostGroup:Destroy() end

					UnlockArena()
					CurrentMode, canblock, candodge = "Blocks", true, false
					Animations, dodgeDebounce = false, false
					Humanoid.MaxHealth, Humanoid.Health = 100, 100
					UpdateDodgeBar()
					break
				end
				task.wait(1)
			end
		end)()
	end

	-- === 🛠️ FINE TUNING: POSITION, ROTATION & SCALE 🛠️ === --
	-- Change X for Right/Left spacing, Y for Altitude (Up/Down), Z for Depth (Behind Sans)
	-- 'Rot_Y' rotates the character (Positive/Negative degree turning!). 
	-- 'Scale' resizes the entire model! (1.0 is normal, 0.5 is half size, 2.0 is double)

	local P_PAPYRUS = { X = -7.5, Y = 2, Z =  4.5, Rot_Y = 0, Scale = 1.0  }
	local P_TORIEL  = { X =  5.5, Y = -2.5, Z =  5.0, Rot_Y = 0, Scale = 0.75 } -- Shrunk Toriel!
	local P_UNDYNE  = { X =  0.0, Y =  1.5, Z =  5.5, Rot_Y = -90, Scale = 1.0  }
	local P_GASTER  = { X =  2.0, Y =  2.5, Z =  10.5, Rot_Y = -90, Scale = 1.0  }

	-- Configure where Blasters spawn beside him and their ultimate idle Max size!
	local GB_LEFT   = { HoverX = -4.5, HoverY = 4, HoverZ = -1, Size = 1.3 }
	local GB_RIGHT  = { HoverX =  4.5, HoverY = 4, HoverZ = -1, Size = 1.3 }
	-- ============================================================== --

	CurrentMode = "Transition2_5"
	UpdateDodgeBar()
	LockArena(150) 

	attack, attack2, Animations = true, true, true
	candodge, canblock = false, false
	Humanoid.MaxHealth, Humanoid.Health = math.huge, math.huge

	Expression.Texture = "rbxassetid://4484407199" 

	-- BODY HIGHLIGHT
	local BodyGlow = Instance.new("Highlight", Character)
	BodyGlow.Name = "P2_5Glow"
	BodyGlow.FillColor = Color3.fromRGB(0, 80, 255)
	BodyGlow.OutlineColor = Color3.fromRGB(0, 220, 255)
	BodyGlow.FillTransparency, BodyGlow.OutlineTransparency = 1, 1
	BodyGlow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	coroutine.wrap(function()
		for t = 1, 20 do
			BodyGlow.FillTransparency = BodyGlow.FillTransparency - 0.015
			BodyGlow.OutlineTransparency = BodyGlow.OutlineTransparency - 0.03
			task.wait(0.05)
		end
	end)()

	-- BLUE DUST AURA
	for _, c in pairs(Character:GetChildren()) do
		if c:IsA("BasePart") and c:FindFirstChild("Dust") then
			c.Dust.Color = ColorSequence.new(Color3.fromRGB(0, 80, 255), Color3.fromRGB(0, 220, 255))
			c.Dust.Rate, c.Dust.Speed = 350, NumberRange.new(8, 15)
			c.Dust.SpreadAngle, c.Dust.Acceleration = Vector2.new(90, 90), Vector3.new(0, 8, 0)
			c.Dust.Size = NumberSequence.new(0.35)
		end
	end

	local auraSound = Instance.new("Sound", rootPart)
	auraSound.SoundId, auraSound.Volume = "rbxassetid://446961725", 5
	auraSound:Play()
	game.Debris:AddItem(auraSound, 3)

	coroutine.wrap(function()
		chatfunc("* you will certainly beat me...")
		task.wait(2.2)
		chatfunc("* but i'll make you pay.")
		task.wait(2.2)
		chatfunc("* for all those you've killed.")
	end)()

	local GhostGroup = Instance.new("Model", Character)
	GhostGroup.Name = "P2_5_Ghosts"
	local RS = game:GetService("ReplicatedStorage")

	local ghostData = {
		{name = "PapyrusModel", offset = CFrame.new(P_PAPYRUS.X, P_PAPYRUS.Y, P_PAPYRUS.Z), rY = P_PAPYRUS.Rot_Y, Scale = P_PAPYRUS.Scale},
		{name = "TorielModel",  offset = CFrame.new(P_TORIEL.X, P_TORIEL.Y, P_TORIEL.Z), rY = P_TORIEL.Rot_Y, Scale = P_TORIEL.Scale},
		{name = "UndyneModel",  offset = CFrame.new(P_UNDYNE.X, P_UNDYNE.Y, P_UNDYNE.Z), rY = P_UNDYNE.Rot_Y, Scale = P_UNDYNE.Scale},
		{name = "GasterModel",  offset = CFrame.new(P_GASTER.X, P_GASTER.Y, P_GASTER.Z), rY = P_GASTER.Rot_Y, Scale = P_GASTER.Scale}
	}

	local mappedGhosts = {} 

	for _, data in ipairs(ghostData) do
		local ref = RS:FindFirstChild(data.name)
		if ref then
			local clone = ref:Clone()

			if not clone:IsA("Model") then
				local newModel = Instance.new("Model")
				for _, child in pairs(clone:GetChildren()) do child.Parent = newModel end
				newModel.Name = clone.Name
				clone:Destroy()
				clone = newModel
			end

			clone.Parent = GhostGroup

			local rootNode = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart", true) or clone:FindFirstChild("Torso", true) or clone:FindFirstChild("UpperTorso", true) or clone:FindFirstChildWhichIsA("BasePart", true)

			if rootNode then
				clone.PrimaryPart = rootNode

				-- Pivot the model into position BEFORE changing physics
				local targetCFrame = rootPart.CFrame * data.offset * CFrame.Angles(0, math.rad(data.rY), 0)
				clone:PivotTo(targetCFrame)

				-- APPLIES THE FINE TUNING SCALE!
				clone:ScaleTo(data.Scale)

				for _, item in pairs(clone:GetDescendants()) do
					if item:IsA("Humanoid") or item:IsA("Script") or item:IsA("Highlight") then 
						item:Destroy() 
					elseif item:IsA("BasePart") then
						item.Anchored = false 
						item.CanCollide = false 
						item.Massless = true 
						for _, c in pairs(item:GetChildren()) do
							if c:IsA("BodyMover") or c:IsA("BodyVelocity") or c:IsA("BodyGyro") then c:Destroy() end
						end

						-- Weld rigidly to rootNode
						if item ~= rootNode then
							local wc = Instance.new("WeldConstraint")
							wc.Part0 = rootNode
							wc.Part1 = item
							wc.Parent = rootNode
						end
					end

					-- Map Visibles
					if item:IsA("BasePart") or item:IsA("Decal") or item:IsA("Texture") then
						if item.Transparency < 1 and item.Name ~= "HumanoidRootPart" then
							local startT = item.Transparency
							item.Transparency = 1 
							local targetV = (data.name == "GasterModel") and 0.7 or (startT + 0.3)
							table.insert(mappedGhosts, {obj = item, targetVis = targetV}) 
						end
					end
				end

				-- Anchor to Sans & Save Weld for Custom Animations!
				local pw = Instance.new("Weld", rootNode)
				pw.Part0 = rootPart
				pw.Part1 = rootNode
				pw.C0 = data.offset * CFrame.Angles(0, math.rad(data.rY), 0)
				pw.C1 = CFrame.new() 

				data.ActiveWeld = pw
				data.BaseC0 = pw.C0
			end
		end
	end

	-- GASTER BLASTERS
	local function SummonBlasterGuard()
		local gb = Instance.new("Part", GhostGroup)
		gb.Name, gb.CanCollide, gb.Massless, gb.Transparency = "GuardianGB", false, true, 1
		gb.Material = Enum.Material.SmoothPlastic
		gb.BrickColor = BrickColor.new("White")
		local sm = Instance.new("SpecialMesh", gb)
		sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0, 0, 0) 
		table.insert(mappedGhosts, {obj = gb, targetVis = 0})
		local weld = Instance.new("Weld", gb) weld.Part0, weld.Part1 = rootPart, gb
		return gb, weld, sm
	end

	local leftGB, leftWeld, leftSM = SummonBlasterGuard()
	local rightGB, rightWeld, rightSM = SummonBlasterGuard()

	-- MAIN ANIMATION LOOP (Characters + Blasters!)
	coroutine.wrap(function()
		local tStep, curLS, curRS = 0, 0, 0
		while CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" do
			tStep = tStep + 0.1

			-- Blaster Scale Growth
			if curLS < GB_LEFT.Size then curLS = curLS + 0.05 end 
			if curRS < GB_RIGHT.Size then curRS = curRS + 0.05 end 
			leftSM.Scale, rightSM.Scale = Vector3.new(curLS, curLS, curLS), Vector3.new(curRS, curRS, curRS)

			-- Blaster Hovering
			local bobY = math.sin(tStep * 0.8) * 0.5
			local pitchX, yawY = math.cos(tStep * 0.5) * 5, math.sin(tStep * 0.5) * 5
			leftWeld.C0 = leftWeld.C0:lerp(CFrame.new(GB_LEFT.HoverX, GB_LEFT.HoverY + bobY, GB_LEFT.HoverZ) * CFrame.Angles(math.rad(pitchX - 10), math.rad(yawY - 25), math.rad(-5)), 0.2)
			rightWeld.C0 = rightWeld.C0:lerp(CFrame.new(GB_RIGHT.HoverX, GB_RIGHT.HoverY + bobY, GB_RIGHT.HoverZ) * CFrame.Angles(math.rad(pitchX - 10), math.rad(yawY + 25), math.rad(5)), 0.2)

			-- 🌟 GHOST CHARACTER UNIQUE ANIMATIONS 🌟
			for _, gData in ipairs(ghostData) do
				if gData.ActiveWeld then
					if gData.name == "PapyrusModel" then
						-- Heroic rhythmic bob and confident side-to-side sway
						local pBob = math.sin(tStep * 1.2) * 0.3
						local pSway = math.cos(tStep * 0.6) * 3
						gData.ActiveWeld.C0 = gData.BaseC0 * CFrame.new(0, pBob, 0) * CFrame.Angles(0, 0, math.rad(pSway))

					elseif gData.name == "TorielModel" then
						-- Calm, maternal, very slow breathing/floating
						local tBob = math.sin(tStep * 0.6) * 0.4
						gData.ActiveWeld.C0 = gData.BaseC0 * CFrame.new(0, tBob, 0)

					elseif gData.name == "UndyneModel" then
						-- Aggressive, leans forward, fast jittery shakes!
						local uBob = math.sin(tStep * 1.8) * 0.2
						local jitterX = math.random(-1, 1) / 100
						local jitterZ = math.random(-1, 1) / 100
						gData.ActiveWeld.C0 = gData.BaseC0 * CFrame.new(jitterX, uBob, jitterZ) * CFrame.Angles(math.rad(8), 0, 0)

					elseif gData.name == "GasterModel" then
						-- Erratic, ominous float with tilted pitches
						local gBob = math.sin(tStep * 0.9) * 0.5
						local gPitch = math.cos(tStep * 1.1) * 4
						gData.ActiveWeld.C0 = gData.BaseC0 * CFrame.new(0, gBob, 0) * CFrame.Angles(math.rad(gPitch), 0, 0)
					end
				end
			end

			task.wait(0.03)
		end

		-- Shrink Blasters back down when combat ends
		for bDown = GB_LEFT.Size, 0, -0.1 do
			leftSM.Scale, rightSM.Scale = Vector3.new(bDown, bDown, bDown), Vector3.new(bDown, bDown, bDown)
			task.wait(0.03)
		end
	end)()

	-- FADE IN ALL MODELS
	coroutine.wrap(function()
		for step = 1, 30 do
			if _G.CancelAttackTrigger then break end
			local blend = step/30
			for _, pD in ipairs(mappedGhosts) do
				if pD.obj and pD.obj.Parent then pD.obj.Transparency = 1 - ((1 - pD.targetVis) * blend) end
			end
			task.wait(0.05)
		end
	end)()

	if cWait(4.5) then runSkipPhase2_5() return end

	-- FADE OUT MODELS (Except Blasters)
	coroutine.wrap(function()
		for step = 1, 30 do
			if _G.CancelAttackTrigger then break end
			local blend = step/30
			for _, pD in ipairs(mappedGhosts) do
				if pD.obj and pD.obj.Parent and pD.obj.Name ~= "GuardianGB" then
					pD.obj.Transparency = pD.targetVis + ((1 - pD.targetVis) * blend)
				end
			end
			task.wait(0.05)
		end
		for _, v in pairs(GhostGroup:GetChildren()) do if v.Name ~= "GuardianGB" then v:Destroy() end end
	end)()

	if cWait(1.5) then runSkipPhase2_5() return end
	
	_G.InTransition = nil
	if BodyGlow then BodyGlow.FillTransparency, BodyGlow.OutlineTransparency = 0.7, 0.4 end
	if GhostGroup then
		for _, v in pairs(GhostGroup:GetChildren()) do
			if v.Name ~= "GuardianGB" then v:Destroy() end
		end
	end
	
	UnlockArena()
	attack, attack2, Animations = false, false, false
	CurrentMode, Phase2_5Timer = "Timer2_5", 15
	UpdateDodgeBar()

	-- FINAL 15 SECOND COMBAT TIMER
	coroutine.wrap(function()
		for t = 15, 0, -1 do
			if CurrentMode ~= "Timer2_5" then break end
			Phase2_5Timer = t
			UpdateDodgeBar()
			if t <= 0 then
				LockArena(150) 
				CurrentMode = "Transition2_5"
				UpdateDodgeBar()

				coroutine.wrap(function()
					for f = 1, 20 do
						if BodyGlow then BodyGlow.FillTransparency = BodyGlow.FillTransparency + 0.05 BodyGlow.OutlineTransparency = BodyGlow.OutlineTransparency + 0.05 end
						task.wait(0.05)
					end
					if BodyGlow then BodyGlow:Destroy() end
				end)()

				-- RESTORE ORIGINAL WHITE DUST
				for _, c in pairs(Character:GetChildren()) do
					if c:IsA("BasePart") and c:FindFirstChild("Dust") then
						c.Dust.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
						c.Dust.Rate, c.Dust.Speed = 50, NumberRange.new(0.5)
						c.Dust.SpreadAngle, c.Dust.Acceleration = Vector2.new(360, 360), Vector3.new(0, 0, 0)
						c.Dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0)})
					end
				end

				chatfunc("* alright... guess you lived.")
				task.wait(2.5)
				if GhostGroup then GhostGroup:Destroy() end

				UnlockArena()
				CurrentMode, canblock, candodge = "Blocks", true, false
				Animations, dodgeDebounce = false, false
				Humanoid.MaxHealth, Humanoid.Health = 100, 100
				UpdateDodgeBar()
				break
			end
			task.wait(1)
		end
	end)()
end

function Dead2()
	_G.InTransition = "Phase3"
	local function cWait(sec)
		local start = tick()
		while tick() - start < sec do
			if _G.CancelAttackTrigger then return true end
			task.wait(0.05)
		end
		return false
	end

	local GasterClone, GasterHand, ColoredHands, LeftEye, RightEye, isShaking, p3Wingdings

	local function startPhase3Combat()
		isShaking = false
		p3Wingdings = true
		_G.p3WingdingsSlow = false
		coroutine.wrap(function()
			while p3Wingdings do
				if _G.CancelAttackTrigger then break end
				SpawnWingding()
				task.wait(_G.p3WingdingsSlow and 0.15 or 0.04)
			end
			end)()

		dodgeDebounce = true
		coroutine.wrap(function()
			wait(0.5)
			dodgeDebounce = false
		end)()

		_G.isGlitching = false
		coroutine.wrap(function()
			while CurrentMode == "Timer" do
				task.wait(math.random(30, 80) / 10) 
				if CurrentMode ~= "Timer" then break end

				_G.isGlitching = true
				local gSound = Instance.new("Sound", Head)
				gSound.SoundId = "rbxassetid://821439273"
				gSound.Volume = 2
				gSound:Play()

				task.wait(math.random(5, 15) / 10) 

				_G.isGlitching = false
				gSound:Destroy()
			end
		end)()

		coroutine.wrap(function()
			local chars = {"?", "!", "@", "#", "%", "&", "G", "A", "S", "T", "E", "R", "☠", "✡", "☼"}
			while CurrentMode == "Timer" do
				local str = ""
				for j = 1, math.random(8, 15) do
					str = str .. chars[math.random(1, #chars)]
				end
				GlitchText = str 
				UpdateDodgeBar() 
				bwait(4) 
			end
		end)()

		coroutine.wrap(function()
			local bodyParts = {Right_Arm, Left_Arm, Right_Leg, Left_Leg, Head, Torso}
			local toggleCursor = false 
			while CurrentMode == "Timer" do
				task.wait(1) 
				if not _G.isPhase3Jumping and Phase3Timer > 2 then
					toggleCursor = not toggleCursor 
					local isLeft = toggleCursor
					local targetPart = bodyParts[math.random(1, #bodyParts)]

					local clickOffset = rootPart.CFrame:ToObjectSpace(targetPart.CFrame) * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(30), math.rad(180), math.rad(-45))

					if isLeft then _G.TargetCFL = clickOffset else _G.TargetCFR = clickOffset end
					task.wait(0.2)

					local flash = Instance.new("Part", Character)
					flash.Size = Vector3.new(1,1,1) flash.Shape = Enum.PartType.Ball flash.Color = Color3.new(0,1,0)
					flash.Material = Enum.Material.Neon flash.Anchored = true flash.CanCollide = false
					flash.CFrame = targetPart.CFrame
					coroutine.wrap(function()
						for i=1, 10 do flash.Size = flash.Size + Vector3.new(0.5,0.5,0.5) flash.Transparency = i/10 task.wait(0.03) end
						flash:Destroy()
					end)()

					task.wait(0.3)
					if isLeft then _G.TargetCFL = "IDLE" else _G.TargetCFR = "IDLE" end
				end
			end
		end)()

		coroutine.wrap(function()
			local snippets = {
				"sans.health = infinite", "human.delete.save.file", "override.code.666", 
				"gaster.protocol = true", "system.breach()", "void.access.granted",
				"loop.break()", "determination.overflow", "bypass.defense()"
			}
			while CurrentMode == "Timer" do
				task.wait(math.random(1, 3) / 10) 
				if Phase3Timer > 2 then
					spawnHoloScreen(snippets[math.random(1, #snippets)] .. " [OK]", 0, true)
				end
			end
		end)()

		coroutine.wrap(function()
			task.wait(1)

			for i = 60, 0, -1 do
				if CurrentMode ~= "Timer" then break end
				Phase3Timer = i
				UpdateDodgeBar()

				-- 10 SECONDS MECHANICS
				if i <= 10 and i > 0 then
					_G.p3WingdingsSlow = true
					_G.EyeUpdateDelay = 0.15

					script.textboard.TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
					if i % 2 == 0 then
						Expression.Texture = "rbxassetid://4239634623"
					else
						Expression.Texture = "rbxassetid://4484448817"
					end

					local sansAlpha = 0.5
					for _, c in pairs(Character:GetChildren()) do
						if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" and not c.Name:match("Hand") and not c.Name:match("Eye") and not c.Name:match("Root") then
							c.Transparency = sansAlpha
							if c:FindFirstChild("Dust") then
								c.Dust.Rate = 200 
								c.Dust.Speed = NumberRange.new(2, 5)
							end
						end
					end
					if Expression then Expression.Transparency = sansAlpha end
					if Slash then Slash.Transparency = sansAlpha end
				end

				-- TIMER HITS 0 MECHANICS
				if i <= 0 then
					CurrentMode = "Dead"
					p3Wingdings = false
					_G.EyesOff = true

					if Expression then Expression.Texture = "rbxassetid://1371827222" end

					if Head:FindFirstChild("HealthBar") then
						Head.HealthBar.Enabled = false
						if Head.HealthBar:FindFirstChild("Frame") then Head.HealthBar.Frame.Visible = false end
					end

	if not isPhase2 then
		themeMoos:Stop()
	end
					attack = true
					attack2 = true
					Animations = true -- Locks animations for the death pose

					-- 1. KNEEL DOWN FIRST (Torso Y Drops to -2)
					for fallStep = 1, 20 do
						RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(20), math.rad(0), math.rad(10)), 0.1)
						LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.2, 0.1, -0.6) * c_angles(math.rad(80), math.rad(0), math.rad(30)), 0.1) 
						LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, -0.5) * c_angles(math.rad(-20), math.rad(0), math.rad(0)), 0.1) 
						RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.8) * c_angles(math.rad(-10), math.rad(0), math.rad(0)), 0.1) 
						Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -2.2, -0.5) * c_angles(math.rad(-30), math.rad(-15), math.rad(-10)), 0.1) 
						Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-10), math.rad(15), math.rad(0)), 0.1)
						swait()
					end

					task.wait(1)

					-- 2. COLLAPSE TO SIT ON GROUND (Torso Y Drops to -3, Identical to P2 Transition)
					for fallStep = 1, 30 do
						RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(-20),0), 0.15)
						LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(20),0), 0.15)
						LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, 0) * c_angles(math.rad(60),math.rad(20),0), 0.15)
						RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(60),math.rad(-20),0), 0.15)
						Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -3, 0) * c_angles(math.rad(20), 0, 0), 0.15)
						Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-20),0,0), 0.15)
						swait()
					end

					local GasterClonePart = Character:FindFirstChild("GasterModel")

					-- 3. FADE GASTER & ASSETS OUT
					for fadeStep = 1, 60 do
						local fadeAmt = fadeStep / 60
						if GasterClonePart then
							for _, p in pairs(GasterClonePart:GetDescendants()) do
								if p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture") then p.Transparency = fadeAmt end
							end
						end
						local gHand = Character:FindFirstChild("GasterHand")
						if gHand then for _, p in pairs(gHand:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = fadeAmt end end end
						local cHands = Character:FindFirstChild("ColoredHands")
						if cHands then for _, p in pairs(cHands:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = fadeAmt end end end
						if Phase3Screen then for _, p in pairs(Phase3Screen:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 0.4 + (fadeAmt * 0.6) end if p:IsA("TextLabel") then p.TextTransparency = fadeAmt end end end
						if _G.ScreenL then _G.ScreenL.Transparency = 0.3 + (fadeAmt * 0.7) local gui = _G.ScreenL:FindFirstChildOfClass("SurfaceGui") if gui and gui:FindFirstChildOfClass("TextLabel") then gui.TextLabel.TextTransparency = fadeAmt end end
						if _G.ScreenR then _G.ScreenR.Transparency = 0.3 + (fadeAmt * 0.7) local gui = _G.ScreenR:FindFirstChildOfClass("SurfaceGui") if gui and gui:FindFirstChildOfClass("TextLabel") then gui.TextLabel.TextTransparency = fadeAmt end end
						if _G.CursorL then for _, p in pairs(_G.CursorL:GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = fadeAmt end end end
						if _G.CursorR then for _, p in pairs(_G.CursorR:GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = fadeAmt end end end
						task.wait(0.05)
					end

					local function stopDust(mod) if mod then for _, p in pairs(mod:GetDescendants()) do if p:IsA("ParticleEmitter") then p.Enabled = false end end end end
					stopDust(GasterClonePart) stopDust(Character:FindFirstChild("GasterHand")) stopDust(Character:FindFirstChild("ColoredHands"))
					if _G.CursorL then _G.CursorL:Destroy() end if _G.CursorR then _G.CursorR:Destroy() end

					task.wait(1)

					-- 4. THEN DUST SANS (DUST PERSISTS)
					local DustSound = Instance.new("Sound", rootPart) DustSound.SoundId, DustSound.Volume = "rbxassetid://444667611", 5 DustSound:Play()
					local sweepDuration, steps, sweepStart, sweepEnd = 3, 60 * 3, -2.5, 2.5

					for step = 1, steps do
						local stepProgress = step / steps
						local currentSweepX = sweepStart + ((sweepEnd - sweepStart) * stepProgress)

						for _, part in pairs(Character:GetDescendants()) do
							if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "BlockBone" then
								local relativeX = rootPart.CFrame:ToObjectSpace(part.CFrame).X
								local diff = currentSweepX - relativeX
								local targetTrans = math.clamp((diff + 0.4) / 0.8, 0, 1)
								if targetTrans > part.Transparency then part.Transparency = targetTrans end
								if part:FindFirstChild("Dust") then
									if targetTrans > 0.05 and targetTrans < 0.95 then
										part.Dust.Rate, part.Dust.Speed, part.Dust.Acceleration, part.Dust.SpreadAngle = 2000, NumberRange.new(4, 9), Vector3.new(5, 5, 0), Vector2.new(45, 45)
									end
								end
							elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
								local h = part.Handle
								local targetTrans = math.clamp(((currentSweepX - rootPart.CFrame:ToObjectSpace(h.CFrame).X) + 0.4) / 0.8, 0, 1)
								if targetTrans > h.Transparency then h.Transparency = targetTrans end
							end
						end
						if Expression then Expression.Transparency = Head.Transparency end if Slash then Slash.Transparency = Torso.Transparency end
						task.wait()
					end

					for _, c in pairs(Character:GetDescendants()) do
						if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" then
							c.Transparency = 1 
						end
					end
					spawnDustPuddle(rootPart.CFrame)

					task.wait(1) 
					candie = true 

					-- 🌟 FIX: Change the mode so his own script stops healing him!
					CurrentMode = "ActuallyDead" 

					-- Ensure proper structural break of limbs telling the Game the player MUST respawn:
					Humanoid.BreakJointsOnDeath = true 
					if rootPart then rootPart:BreakJoints() end 

					Humanoid.MaxHealth = 100 
					Humanoid.Health = 0
					Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

					script.Parent = realWorkspace 
					game:GetService("Debris"):AddItem(script, 15) 

					-- 🌟 FIX: Forcibly respawn the player after letting them look at the dust for 3 seconds
					task.delay(3, function()
						if Player then 
							Player:LoadCharacter() 
						end
					end)

					break
				end

				task.wait(1) 
			end
		end)()
	end

	local function runSkipPhase3()
		_G.InTransition = nil
		isShaking = false
		p3Wingdings = true
		_G.p3WingdingsSlow = false
		coroutine.wrap(function()
			while p3Wingdings do
				if _G.CancelAttackTrigger then break end
				SpawnWingding()
				task.wait(_G.p3WingdingsSlow and 0.15 or 0.04)
			end
		end)()

		if GasterClone then
			for _, part in pairs(GasterClone:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then part.Transparency = 0 end
			end
		end
		if GasterHand then
			for _, part in pairs(GasterHand:GetDescendants()) do
				if part:IsA("BasePart") then part.Transparency = 0 end
			end
		end
		if ColoredHands then
			for _, hand in pairs(ColoredHands:GetChildren()) do
				for _, part in pairs(hand:GetChildren()) do
					if part:IsA("BasePart") then part.Transparency = 0 end
				end
			end
		end
		if LeftEye then LeftEye.Transparency = 0 end
		if RightEye then RightEye.Transparency = 0 end
		if _G.CursorL then
			for _, part in pairs(_G.CursorL:GetDescendants()) do
				if part:IsA("BasePart") then part.Transparency = 0 end
			end
		end
		if _G.CursorR then
			for _, part in pairs(_G.CursorR:GetDescendants()) do
				if part:IsA("BasePart") then part.Transparency = 0 end
			end
		end
		if _G.ScreenL then _G.ScreenL.Transparency = 0.3 end
		if _G.ScreenR then _G.ScreenR.Transparency = 0.3 end

		spawnHoloScreen("INITIALIZING SYSTEM...", 0, true)

		Expression.Texture = "rbxassetid://4239634623" 
		script.textboard.TextLabel.TextColor3 = Color3.fromRGB(255,0,0)

		themeMoos:Stop()
		themeMoos.SoundId = "rbxassetid://3343011842"
		themeMoos:Play()

		Sanim = 0.0001
		attack = false
		attack2 = false
		Animations = false
		idle = 2500 

		for _, part in pairs(Character:GetChildren()) do
			if part.Name == "Soul" then part:Destroy() end
		end
		UnlockArena()
		pcall(CreateMovesGUI)

		CurrentMode = "Timer"
		Phase3Timer = 60

		startPhase3Combat()
	end

CurrentMode = "Transition" 
	UpdateDodgeBar()
	pcall(function() CreateMovesGUI() end)
	LockArena(150) 
	spawnHoloScreen("negate.damage = true\n> var.reason= ACCESS DENIED\n> forcing survival state...\n> here i come, anomaly", 3)

	UniversalFade(Character, 0.2, 1)

	for _, c in pairs(Character:GetChildren()) do
		if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" then
			if not c:FindFirstChild("Dust") then
				particles(c)
			end
			c.Dust.Rate = 50 
		end
	end

	if Character:FindFirstChild("Phase2Weapon") then
		Character.Phase2Weapon:Destroy()
	end

	attack = true
	attack2 = true
	specialattack = false
	Animations = true
	candodge = false
	canblock = false
	Humanoid.MaxHealth = math.huge
	Humanoid.Health = math.huge
	Expression.Texture = "rbxassetid://1371827222"

	Slash.Texture = "rbxassetid://403969152"
	Slash.Transparency = 0

	local Dizz = Instance.new("Sound", Character.Torso)
	Dizz.SoundId = "rbxassetid://623904185"
	Dizz.Volume = 10
	Dizz.Looped = false
	Dizz.Pitch = 0.7
	Dizz:Play()

	coroutine.wrap(function()
		for pitchStep = 1, 100 do
			if _G.CancelAttackTrigger then break end
			themeMoos.Pitch = math.max(0, themeMoos.Pitch - 0.01)
			task.wait(0.02)
		end
	end)()

	-- 1. KNEEL DOWN FIRST (Torso Y Drops to -2)
	for fallStep = 1, 20 do
		if _G.CancelAttackTrigger then runSkipPhase3() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(20), math.rad(0), math.rad(10)), 0.1)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.2, 0.1, -0.6) * c_angles(math.rad(80), math.rad(0), math.rad(30)), 0.1) 
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, -0.5) * c_angles(math.rad(-20), math.rad(0), math.rad(0)), 0.1) 
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.8) * c_angles(math.rad(-10), math.rad(0), math.rad(0)), 0.1) 
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -2.2, -0.5) * c_angles(math.rad(-30), math.rad(-15), math.rad(-10)), 0.1) 
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-10), math.rad(15), math.rad(0)), 0.1)
		swait()
	end

	if cWait(1.0) then runSkipPhase3() return end

	-- 2. COLLAPSE TO SIT ON GROUND (Torso Y Drops to -3, Identical to P2 Transition)
	for fallStep = 1, 30 do
		if _G.CancelAttackTrigger then runSkipPhase3() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(-20),0), 0.15)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.1, 0.5, 0) * c_angles(math.rad(-20),math.rad(20),0), 0.15)
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, 0) * c_angles(math.rad(60),math.rad(20),0), 0.15)
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(60),math.rad(-20),0), 0.15)
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -3, 0) * c_angles(math.rad(20), 0, 0), 0.15)
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-20),0,0), 0.15)
		swait()
	end

	if cWait(1) then runSkipPhase3() return end
	Expression.Texture = "rbxassetid://4484446057"
	chatfunc("* so...")

	for i = 0,1,0.01 do
		if _G.CancelAttackTrigger then runSkipPhase3() return end
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.1, 0.5 + math.sin(sine/7.5)/10, 0) * c_angles(math.rad(-20),math.rad(-20),math.rad(0)), 0.15)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.1, 0.5 + math.sin(sine/7.5)/10, 0) * c_angles(math.rad(40),math.rad(20),math.rad(70)), 0.15)
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1 - math.sin(sine/7.5)/10, 0) * c_angles(math.rad(60),math.rad(20),math.rad(0)), 0.15)
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1 - math.sin(sine/7.5)/10, 0) * c_angles(math.rad(60),math.rad(-20),math.rad(0)), 0.15)
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -3 + math.sin(sine/7.5)/10, 0) * c_angles(math.rad(20), math.rad(0),math.rad(0)), 0.15)
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5 + math.sin(sine/15)/10, 0) * c_angles(math.rad(-20),math.rad(0), math.rad(0) + math.sin(sine/15)/5), 0.15)
		swait()
	end

	if cWait(1) then runSkipPhase3() return end
	chatfunc("* guess that's it, huh?")
	if cWait(2) then runSkipPhase3() return end
	Expression.Texture = "rbxassetid://4484446057"

	-- START ASYNC DIALOGUE (Plays at the exact same time as the visual sequence)
	coroutine.wrap(function()
		chatfunc("* Y0U KN0W? A P3RF3CT W0RLD CAN BE ACHIEVED")
		task.wait(2)
		chatfunc("* A W0RLD WH3R3 N0B0DY HAS T0 DI3")
		task.wait(1.7)
		chatfunc("* A W0RLD WH3R3 W3 THRIVE!")
		task.wait(1.7)
		chatfunc("* such world can be achieved only...")
	end)()

	-- 1. LOCK ANIMATIONS & STAND UP SMOOTHLY (2-Step: Sit -> Kneel -> Stand)
	Animations = true 

	-- Step A: Sit to Kneel
	for standStep = 1, 20 do
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(20), math.rad(0), math.rad(10)), 0.1)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.2, 0.1, -0.6) * c_angles(math.rad(80), math.rad(0), math.rad(30)), 0.1) 
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1, -0.5) * c_angles(math.rad(-20), math.rad(0), math.rad(0)), 0.1) 
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.8) * c_angles(math.rad(-10), math.rad(0), math.rad(0)), 0.1) 
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -2.2, -0.5) * c_angles(math.rad(-30), math.rad(-15), math.rad(-10)), 0.1) 
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-10), math.rad(15), math.rad(0)), 0.1)
		swait()
	end

	task.wait(0.3)

	-- Step B: Kneel to Stand
	local Bam = Instance.new("Sound", Character.Torso)
	Bam.SoundId = "rbxassetid://367453005"
	Bam.Volume = 10
	Bam:Play()

	for standStep = 1, 30 do
		RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4, -0.1) * c_angles(math.rad(-10), math.rad(0), math.rad(5)), 0.15)
		LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.4, 0.4, -0.1) * c_angles(math.rad(-10), math.rad(0), math.rad(-5)), 0.15)
		LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1.05, 0) * c_angles(math.rad(0), math.rad(0), math.rad(0)), 0.15)
		RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1.05, 0) * c_angles(math.rad(0), math.rad(0), math.rad(0)), 0.15)
		Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.2, 0) * c_angles(math.rad(0), math.rad(0), math.rad(0)), 0.15)
		Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-15), math.rad(0), math.rad(0)), 0.15) 
		swait()
	end

	Death = false
	Death2 = true
	_G.EyesOff = false

	-- 2. SPAWN EYES COMPLETELY INVISIBLE (Explicitly separated to fix clipping bug)
	local LeftEye = Instance.new("Part", Character)
	LeftEye.Name = "StaticEyeL"
	LeftEye.Material = Enum.Material.Neon
	LeftEye.CanCollide = false LeftEye.Massless = true LeftEye.Anchored = false
	LeftEye.Transparency = 1
	if EyeSettings.MakeRound then Instance.new("CylinderMesh", LeftEye) end
	local WeldL = Instance.new("Weld", LeftEye)
	WeldL.Part0 = Head
	WeldL.Part1 = LeftEye
	if EyeSettings.MakeRound then
		LeftEye.Size = Vector3.new(0.05, EyeSettings.SizeY, EyeSettings.SizeX)
		WeldL.C0 = CFrame.new(-EyeSettings.OffsetX, EyeSettings.OffsetY, EyeSettings.DepthZ) * CFrame.Angles(0,0,math.rad(90))
	else
		LeftEye.Size = Vector3.new(EyeSettings.SizeX, EyeSettings.SizeY, 0.05)
		WeldL.C0 = CFrame.new(-EyeSettings.OffsetX, EyeSettings.OffsetY, EyeSettings.DepthZ)
	end
	local LightL = Instance.new("PointLight", LeftEye)
	LightL.Name = "EyeGlow" LightL.Brightness = 0 LightL.Range = 5 LightL.Shadows = true

	local RightEye = Instance.new("Part", Character)
	RightEye.Name = "StaticEyeR"
	RightEye.Material = Enum.Material.Neon
	RightEye.CanCollide = false RightEye.Massless = true RightEye.Anchored = false
	RightEye.Transparency = 1
	if EyeSettings.MakeRound then Instance.new("CylinderMesh", RightEye) end
	local WeldR = Instance.new("Weld", RightEye)
	WeldR.Part0 = Head
	WeldR.Part1 = RightEye
	if EyeSettings.MakeRound then
		RightEye.Size = Vector3.new(0.05, EyeSettings.SizeY, EyeSettings.SizeX)
		WeldR.C0 = CFrame.new(EyeSettings.OffsetX, EyeSettings.OffsetY, EyeSettings.DepthZ) * CFrame.Angles(0,0,math.rad(90))
	else
		RightEye.Size = Vector3.new(EyeSettings.SizeX, EyeSettings.SizeY, 0.05)
		WeldR.C0 = CFrame.new(EyeSettings.OffsetX, EyeSettings.OffsetY, EyeSettings.DepthZ)
	end
	local LightR = Instance.new("PointLight", RightEye)
	LightR.Name = "EyeGlow" LightR.Brightness = 0 LightR.Range = 5 LightR.Shadows = true

	local GasterModel = game:GetService("ReplicatedStorage"):FindFirstChild("GasterModel")
	local GasterClone = nil
	if GasterModel then
		GasterClone = GasterModel:Clone()
		GasterClone.Parent = Character
		local GasterRoot = GasterClone.PrimaryPart or GasterClone:FindFirstChildWhichIsA("BasePart")
		if GasterRoot then
			if not GasterClone.PrimaryPart then GasterClone.PrimaryPart = GasterRoot end
			local offsetPosicion = CFrame.new(0, 0, 6)
			local offsetRotacion = CFrame.Angles(0, math.rad(-90), 0) 
			GasterClone:PivotTo(rootPart.CFrame * offsetPosicion * offsetRotacion)

			local GasterWeld = Instance.new("Weld") 
			GasterWeld.Name = "GasterMainWeld"
			GasterWeld.Part0 = rootPart
			GasterWeld.Part1 = GasterRoot
			GasterWeld.C0 = CFrame.new(0, 1.5, 4.5) * CFrame.Angles(0, math.rad(-90), 0) 
			GasterWeld.Parent = rootPart 

			for _, part in pairs(GasterClone:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false part.Massless = true part.Anchored = false 
					part.Transparency = 1
					for _, mv in pairs(part:GetChildren()) do
						if mv:IsA("BodyMover") or mv:IsA("BodyVelocity") or mv:IsA("BodyGyro") or mv:IsA("BodyPosition") then mv:Destroy() end
					end

					if part ~= GasterRoot then
						local internalWeld = Instance.new("WeldConstraint")
						internalWeld.Part0 = GasterRoot internalWeld.Part1 = part internalWeld.Parent = part
					end
				elseif part:IsA("Decal") or part:IsA("Texture") then
					part.Transparency = 1
				elseif part:IsA("Highlight") then
					part.FillTransparency = 1
					part.OutlineTransparency = 1
				end
			end
		end
	end

	local GasterHand = createGrippingSkeletonHand(Character, "GasterHand", Color3.fromRGB(200,200,200))
	for _, p in pairs(GasterHand:GetChildren()) do
		if p:IsA("BasePart") then
			p.Size = p.Size * 1.4
			local w = p:FindFirstChildOfClass("Weld")
			if w then w.C0 = w.C0 + (w.C0.Position * 0.4) end
		end
	end
	local gHWeld = Instance.new("Weld", GasterHand)
	gHWeld.Name = "GHandWeld" gHWeld.Part0 = Torso gHWeld.Part1 = GasterHand
	gHWeld.C0 = CFrame.new(GHand_X, GHand_Y, GHand_Z) * CFrame.Angles(math.rad(GHand_RotX), math.rad(GHand_RotY), math.rad(GHand_RotZ))

	local ColoredHands = Instance.new("Folder", Character)
	ColoredHands.Name = "ColoredHands"
	local handColors = { Color3.fromRGB(255, 128, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 0, 0) }

	for i, hColor in ipairs(handColors) do
		local ch = createSkeletonHand(ColoredHands, "Hand"..i, hColor)
		local w = Instance.new("Weld", ch)
		w.Part0 = rootPart w.Part1 = ch
		local angle = (i - 2.5) * 45 
		w.C0 = CFrame.new(math.sin(math.rad(angle)) * 6, 3, 5) * CFrame.Angles(0, math.rad(180 + angle), 0)
	end

	_G.CursorWeldL, _G.ScreenWeldL, _G.CursorL, _G.ScreenL = setupCursorAndScreen(Character, false)
	_G.CursorWeldR, _G.ScreenWeldR, _G.CursorR, _G.ScreenR = setupCursorAndScreen(Character, true)
	_G.TargetCFL = "IDLE"
	_G.TargetCFR = "IDLE"
	_G.isPhase3Jumping = false

	-- 2. IMMEDIATELY -> SHAKING STARTS
	local isShaking = true
	coroutine.wrap(function()
		local twitchSound = Instance.new("Sound", Head)
		twitchSound.SoundId = "rbxassetid://821439273"
		twitchSound.Volume = 0.8
		twitchSound.Looped = true
		twitchSound:Play()

		while isShaking do 
			local rx = math.rad(math.random(-3, 3))
			local ry = math.rad(math.random(-3, 3))
			local rz = math.rad(math.random(-3, 3))

			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4, -0.1) * c_angles(math.rad(-10)+rx, math.rad(0)+ry, math.rad(5)+rz), 0.5)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.4, 0.4, -0.1) * c_angles(math.rad(-10)+rx, math.rad(0)+ry, math.rad(-5)+rz), 0.5)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1.05, 0) * c_angles(rx,ry,rz), 0.5)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1.05, 0) * c_angles(rx,ry,rz), 0.5)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.2, 0) * c_angles(rx, ry, rz), 0.5)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(-15)+rx, ry, rz), 0.5)
			swait()
		end
		twitchSound:Stop()
		twitchSound:Destroy()
	end)()

	-- 3. 1 SECOND LATER -> WINGDINGS SPAWN
	if cWait(1) then runSkipPhase3() return end
	p3Wingdings = true
	_G.p3WingdingsSlow = false
	coroutine.wrap(function()
		while p3Wingdings do
			if _G.CancelAttackTrigger then break end
			SpawnWingding()
			task.wait(_G.p3WingdingsSlow and 0.15 or 0.04)
		end
	end)()

	-- 4. 1 SECOND LATER -> GASTER FADES IN
	if cWait(1) then runSkipPhase3() return end
	if GasterClone then UniversalFade(GasterClone, 0, 1.5) end

	-- 5. 1 SECOND LATER -> MAIN HACKER SCREEN FADES IN
	if cWait(1) then runSkipPhase3() return end
	spawnHoloScreen("INITIALIZING SYSTEM...", 0, true)

	-- 6. 1 SECOND LATER -> MINI HACKER SCREENS APPEAR
	if cWait(1) then runSkipPhase3() return end
	UniversalFade(LeftEye, 0, 1)
	UniversalFade(RightEye, 0, 1)
	UniversalFade(_G.CursorL, 0, 1)
	UniversalFade(_G.CursorR, 0, 1)
	UniversalFade(_G.ScreenL, 0.3, 1)
	UniversalFade(_G.ScreenR, 0.3, 1)

	-- 7. 1 SECOND LATER -> COLORED HANDS APPEAR
	if cWait(1) then runSkipPhase3() return end
	UniversalFade(ColoredHands, 0, 1.5)

	-- 8. IMMEDIATELY AFTER -> GASTER HAND ON SHOULDER APPEARS
	UniversalFade(GasterHand, 0, 1)

	-- 9. 1 SECOND LATER -> SHAKING STOPS
	if cWait(1) then runSkipPhase3() return end
	isShaking = false
	if cWait(0.2) then runSkipPhase3() return end

	-- 10. IMMEDIATELY AFTER -> PHASE 3 STARTS
	Expression.Texture = "rbxassetid://4239634623" 

	script.textboard.TextLabel.TextColor3 = Color3.new(255,0,0)
	chatfunc("* WITHOUT YOU.")
	themeMoos:Stop()
	themeMoos.SoundId = "rbxassetid://3343011842"
	themeMoos:Play()

	Sanim = 0.0001
	attack = false
	attack2 = false

	Animations = false
	idle = 2500 

	for _, part in pairs(Character:GetChildren()) do
		if part.Name == "Soul" then part:Destroy() end
	end
	UnlockArena()
	pcall(CreateMovesGUI)

	CurrentMode = "Timer"
	Phase3Timer = 60

	_G.InTransition = nil
	startPhase3Combat()
	return

	end

-- ================================================= --
-- [[ 8. COMBAT / ATTACK FUNCTIONS ]]
-- ================================================= --
local Effects = Instance.new("Folder",realWorkspace)
Effects.Name = "Stuff"

-- 🌟 GLOBAL TARGETING HELPER: Finds the closest player to a specific position
local function GetClosestTarget(pos, maxRadius)
	local target, closestDist = nil, maxRadius or 100
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= Character then
			local eRoot = obj:FindFirstChild("HumanoidRootPart")
			local eHum = obj:FindFirstChildOfClass("Humanoid")
			if eRoot and eHum and eHum.Health > 0 then
				local dist = (eRoot.Position - pos).Magnitude
				if dist < closestDist then
					closestDist, target = dist, eHum
				end
			end
		end
	end
	return target
end

function teleport()
	local targetPos = ResolveAimHit()
	-- Added blue glow and significantly shortened the delay!
	local hl = Instance.new("Highlight", Character)
	hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)

	local tele1 = CreateSound("12222170", Head, 5, 0.6)
	task.wait(0.15)

	Torso.CFrame = CFrame.new(Vector3.new(targetPos.X, targetPos.Y + 1.5, targetPos.Z), Torso.CFrame.p)

	local tele2 = CreateSound("12222170", Head, 5, 0.65)
	task.wait(0.15)
	hl:Destroy()
end

local mp = Instance.new("Part",Effects)
mp.CanCollide = false
mp.Name = "Point X"
mp.Transparency = 1
mp.Size = Vector3.new(1, 1, 1)

Point = Instance.new("BodyGyro")
Point.Parent = mp
Point.D = 175
Point.P = 200000
Point.MaxTorque = Vector3.new(0,400000000,0)

local mp2 = Instance.new("Part",Effects)
mp2.CanCollide = false
mp2.Name = "Point XYZ"
mp2.Transparency = 1
mp2.Size = Vector3.new(1, 1, 1)

Point2 = Instance.new("BodyGyro")
Point2.Parent = mp2
Point2.D = 175
Point2.P = 200000
Point2.MaxTorque = Vector3.new(400000000,400000000,400000000)

local mousep = nil
local pos = Instance.new("BodyPosition",mp)
pos.D = 1250
pos.P = 200000
pos.MaxForce = Vector3.new(4000000000, 4000000000, 4000000000)
local pos2 = Instance.new("BodyPosition",mp2)
pos2.D = 1250
pos2.P = 200000
pos2.MaxForce = Vector3.new(4000000000, 4000000000, 4000000000)
coroutine.wrap(function()
	while true do
		mousep = mouse.Hit.p
		Point.cframe = CFrame.new(rootPart.Position,Mouse.Hit.Position)
		pos.Position = rootPart.Position + Vector3.new(0,0,0)
		Point2.cframe = CFrame.new(rootPart.Position,Mouse.Hit.Position)
		pos2.Position = rootPart.Position + Vector3.new(0,0,0)
		bwait()
	end
end)()

padebounce = false
debounce = true

local TS = game:GetService("TweenService")

-- 🌟 MODERN BEAM LOGIC: ZERO PHYSICS SPAZZING, 100% ACCURATE HITBOX 🌟
local function FireModernBeam(blasterPart, size, color, tickDamage)
	local mag = 300 -- Phases through everything!

	-- 1. The Visual Beam
	local beam = Instance.new("Part", Effects)
	beam.Anchored, beam.CanCollide, beam.Massless = true, false, true
	beam.Material, beam.Color, beam.Shape = Enum.Material.Neon, color, Enum.PartType.Cylinder
	beam.Size = Vector3.new(mag, 0, 0)
	beam.CFrame = blasterPart.CFrame * CFrame.new(0, 0, -mag/2) * CFrame.Angles(0, math.rad(90), 0)

	-- 2. The Invisible Damage Hitbox (Uses Spatial Queries instead of .Touched)
	local hitbox = Instance.new("Part", Effects)
	hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
	hitbox.Size = Vector3.new(size * 1.5, size * 1.5, mag)
	hitbox.CFrame = blasterPart.CFrame * CFrame.new(0, 0, -mag/2)

	-- Smoothly Tween the beam size up
	local tInfoIn = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TS:Create(beam, tInfoIn, {Size = Vector3.new(mag, size, size)}):Play()

	-- 3. THE DAMAGE ENGINE: Melts health incredibly fast and consistently
	local beamActive = true
	task.spawn(function()
		local hitCache = {}
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {Character, Effects}

		while beamActive do
			-- GetPartsInPart is Roblox's modern, 100% reliable hitbox scanner
			local parts = workspace:GetPartsInPart(hitbox, overlapParams)
			for _, p in ipairs(parts) do
				local hum = p.Parent:FindFirstChildOfClass("Humanoid") or (p.Parent.Parent and p.Parent.Parent:FindFirstChildOfClass("Humanoid"))
				if hum and hum.Health > 0 and hum.Parent ~= Character then
					-- Hits the player every 0.1 seconds they stand in the beam
					if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
						hitCache[hum] = tick()
						-- Bypass standard defense, subtract health natively
						local actualTickDamage = tickDamage
						if Death == true or Death2 == true then
							actualTickDamage = actualTickDamage * 2
						end
						hum.Health = hum.Health - actualTickDamage 

						-- Optional impact effect
						local impact = Instance.new("Sound", p)
						impact.SoundId = "rbxassetid://131238474"
						impact.Volume = 0.5
						impact:Play()
						game.Debris:AddItem(impact, 1)
					end
				end
			end
			task.wait(0.05) -- Checks 20 times a second
		end
	end)

	-- Hold the blast
	task.wait(0.4)
	beamActive = false

	-- Smoothly Tween the beam away
	local tInfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local outTween = TS:Create(beam, tInfoOut, {Size = Vector3.new(mag, 0, 0)})
	outTween:Play()
	outTween.Completed:Wait()

	beam:Destroy()
	hitbox:Destroy()
end
local TS = game:GetService("TweenService")

local WarnAndRise
local Attack_BoneRise
local _activeWarnAndRiseCount = 0 -- FIX: track concurrent bone rises to prevent lag spikes

local function SummonModernBone(startCF, scaleVec, isHoming, lifeTime, speed, damageHitInterval, damageMultiplier, isBlue)
	local bone = Instance.new("Part", Effects)
	bone.Name = "HomingBone"
	bone.CanCollide, bone.Anchored, bone.Massless = false, true, true
	-- FIX: Dynamic Hitbox sizing based on scaleVec so the entire edge does damage!
	bone.Size = Vector3.new(scaleVec.X * 37.5, scaleVec.Y * 300, scaleVec.Z * 37.5)
	
	if isBlue then
		bone.Material, bone.BrickColor = Enum.Material.Neon, BrickColor.new("Cyan")
	else
		bone.Material, bone.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
	end
	bone.CFrame = startCF

	local sm = Instance.new("SpecialMesh", bone)
	sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633", scaleVec

	local sound = Instance.new("Sound", bone) sound.SoundId, sound.Volume = "rbxassetid://306247749", 1 sound:Play()

	local isStalker = (scaleVec.X >= 0.05)

	-- 🌟 RECENT REQUEST: Dynamic blue bone sweep helper function for Phase 1 cinematics!
	-- We define this globally or within scope so all cinematic attacks can call it cleanly.
	if not _G.SpawnCinematicBlueBoneSweep then
		_G.SpawnCinematicBlueBoneSweep = function(boxGroup, center, directionName, sweepDuration)
			task.spawn(function()
				local numBones = 16
				local spacing = 56 / (numBones - 1)
				local blueBones = {}
				
				for k = 0, numBones - 1 do
					local xOffset = -28 + k * spacing
					-- Create vertical cyan neon bones using SummonModernBone!
					local startCF = CFrame.new(center) * CFrame.new(xOffset, -20, 0)
					local b = SummonModernBone(startCF, Vector3.new(0.015, 0.05, 0.015), false, sweepDuration + 1, 0, nil, nil, true)
					table.insert(blueBones, {part = b, xOffset = xOffset})
				end
				
				CreateSound("340722848", Head, 4, 1.2) -- laser sound for entry
				
				local startTime = tick()
				while tick() - startTime < sweepDuration do
					if _G.CancelAttackTrigger or not boxGroup.Parent then break end
					local sweepT = (tick() - startTime) / sweepDuration
					local blueZ = -28 + 56 * sweepT
					if directionName == "Back" then
						blueZ = 28 - 56 * sweepT
					end
					
					for _, bData in ipairs(blueBones) do
						if bData.part and bData.part.Parent then
							bData.part.CFrame = CFrame.new(center) * CFrame.new(bData.xOffset, 7.5, blueZ)
						end
					end
					task.wait()
				end
				
				for _, bData in ipairs(blueBones) do
					if bData.part and bData.part.Parent then
						bData.part:Destroy()
					end
				end
			end)
		end
	end

	task.spawn(function()
		local active, hitCache = true, {}
		local overlapParams = OverlapParams.new() overlapParams.FilterDescendantsInstances = {Character, Effects}
		local hitDelay = damageHitInterval or 0.1

		task.spawn(function()
			while active and bone.Parent do
				for _, p in ipairs(workspace:GetPartsInPart(bone, overlapParams)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						local shouldDamage = true
						if isBlue then
							-- Blue bone: Only deal damage if the victim is moving!
							if hum.MoveDirection.Magnitude <= 0.05 then
								shouldDamage = false
							end
						end
						
						if shouldDamage then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= hitDelay then
								hitCache[hum] = tick()
								if damageMultiplier then
									_G.ApplyKarmaHit(hum, damageMultiplier)
								else
									_G.ApplyKarmaHit(hum)
								end
							end
						end
					end
				end
				task.wait(0.05)
			end
		end)

		local startTime = tick()
		local currentSpeed = speed * 0.5
		local touchTime = 0 -- For the new crash mechanic

		while tick() - startTime < lifeTime do
			if isHoming then
				local cPos, cDist = mouse.Hit.p, 150
				for _, obj in pairs(workspace:GetChildren()) do
					if obj:IsA("Model") and obj ~= Character then
						local eHum, eRoot = obj:FindFirstChildOfClass("Humanoid"), obj:FindFirstChild("HumanoidRootPart")
						if eHum and eHum.Health > 0 and eRoot and (eRoot.Position - bone.Position).Magnitude < cDist then
							cDist, cPos = (eRoot.Position - bone.Position).Magnitude, eRoot.Position
						end
					end
				end

				if isStalker then
					-- Stalker bone: massive slowdown on contact + crash mechanic after 5s of contact
					if cDist < 12 then
						touchTime = touchTime + (1/60)
						currentSpeed = (speed * 0.5) * 0.05 -- Massive slowdown, practically undodgeable if caught
					else
						touchTime = math.max(0, touchTime - (1/120)) 
						currentSpeed = speed * 0.5
					end

					if touchTime >= 5 then
						active = false

						-- Crash directly into the tracked player's current position
						local crashTarget = bone.Position - Vector3.new(0, 30, 0) -- safe fallback
						for _, obj in pairs(workspace:GetChildren()) do
							if obj:IsA("Model") and obj ~= Character then
								local eHum = obj:FindFirstChildOfClass("Humanoid")
								local eRoot = obj:FindFirstChild("HumanoidRootPart")
								if eHum and eHum.Health > 0 and eRoot and (eRoot.Position - bone.Position).Magnitude < cDist + 5 then
									crashTarget = eRoot.Position
									break
								end
							end
						end
						local floorPos = crashTarget

						local crashCF = CFrame.lookAt(bone.Position, floorPos) * CFrame.Angles(math.rad(-90), 0, 0)
						TS:Create(bone, TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = crashCF}):Play()
						task.wait(0.15)

						-- Deep plunge (150 * scaleVec.Y is roughly half the bone length)
						local distToGround = (bone.Position - floorPos).Magnitude
						local dropTarget = crashCF * CFrame.new(0, distToGround + (scaleVec.Y * 150), 0)
						TS:Create(bone, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {CFrame = dropTarget}):Play()
						task.wait(0.1)

						local sndPart = Instance.new("Part", Effects)
						sndPart.Position = floorPos
						sndPart.Anchored = true
						sndPart.Transparency = 1
						sndPart.CanCollide = false
						local explodeSound = Instance.new("Sound", sndPart)
						explodeSound.SoundId = "rbxassetid://12222084"
						explodeSound.Volume = 8
						explodeSound:Play()
						game.Debris:AddItem(sndPart, 3)

						-- Shockwave effect
						local shockwave = Instance.new("Part", Effects)
						shockwave.Anchored = true
						shockwave.CanCollide = false
						shockwave.Size = Vector3.new(1, 1, 1)
						shockwave.Position = floorPos
						shockwave.Color = BrickColor.new("White").Color
						shockwave.Material = Enum.Material.Neon
						shockwave.Transparency = 0.2
						local ringMesh = Instance.new("SpecialMesh", shockwave)
						ringMesh.MeshType = Enum.MeshType.Sphere
						TS:Create(shockwave, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(45, 0.5, 45), Transparency = 1}):Play()
						game.Debris:AddItem(shockwave, 1)

						-- 🌟 SHOCKWAVE DAMAGE 🌟
						task.spawn(function()
							local hitSet = {}
							local shockParams = OverlapParams.new()
							shockParams.FilterDescendantsInstances = {Character, Effects}
							local parts = workspace:GetPartBoundsInRadius(floorPos, 22.5, shockParams)
							for _, p in ipairs(parts) do
								local hum = p.Parent:FindFirstChildOfClass("Humanoid") or (p.Parent.Parent and p.Parent.Parent:FindFirstChildOfClass("Humanoid"))
								if hum and hum.Health > 0 and hum.Parent ~= Character and not hitSet[hum] then
									hitSet[hum] = true
									local shockDamage = 15
									if Death == true or Death2 == true then
										shockDamage = shockDamage * 2
									end
									hum.Health = hum.Health - shockDamage
									_G.ApplyKarmaHit(hum)
								end
							end
						end)

						-- More debris/particles
						for i = 1, 12 do
							local p = Instance.new("Part", Effects)
							p.Anchored, p.CanCollide = true, false
							p.Size = Vector3.new(3, 3, 3)
							p.Color = Color3.new(1,1,1)
							p.Material = Enum.Material.Neon
							local thrust = CFrame.Angles(math.rad(math.random(-60,60)), math.rad(math.random(0,360)), 0).LookVector
							p.CFrame = CFrame.new(floorPos) * CFrame.Angles(math.rad(math.random(-180,180)), math.rad(math.random(-180,180)), math.rad(math.random(-180,180)))
							local psm = Instance.new("SpecialMesh", p)
							psm.MeshType = Enum.MeshType.FileMesh
							psm.MeshId = "http://www.roblox.com/asset/?id=921085633"
							psm.Scale = Vector3.new(0.015, 0.015, 0.015)

							local targetCF = p.CFrame + (thrust * math.random(25, 55))
							TS:Create(p, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF, Transparency = 1}):Play()
							TS:Create(psm, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = Vector3.new(0, 0, 0)}):Play()
							game.Debris:AddItem(p, 1)
						end

						-- 50/50 Chance of Normal Rise at crash site or Multiple Homing Bones (C Variant)
						if math.random() > 0.5 then
							WarnAndRise(floorPos, math.random(0,180), 14, 14, "Rise")
						else
							Attack_BoneRise(true)
						end

						bone:Destroy()
						return
					end
				else
					-- Regular homing bone: also slows down noticeably when close to the player
					if cDist < 12 then
						currentSpeed = (speed * 0.5) * 0.2 -- Slow down significantly when near the player
					else
						currentSpeed = speed * 0.5
					end
				end

				-- PERFECT HOMING: Locks directly onto the target
				local tCF = CFrame.lookAt(bone.Position, cPos) * CFrame.Angles(math.rad(-90), 0, 0)
				bone.CFrame = CFrame.new(bone.Position) * tCF.Rotation
			end
			bone.CFrame = bone.CFrame * CFrame.new(0, currentSpeed, 0)
			swait()
		end

		active = false
		for i = 1, 10 do bone.Transparency = i/10 swait() end
		bone:Destroy()
	end)
end

WarnAndRise = function(centerPos, rotationY, width, depth, visualMode, speedMult, noKR, onlyFasterSpawn)
	speedMult = speedMult or 1
	local baseCF = (typeof(centerPos) == "CFrame" and centerPos) or (CFrame.new(centerPos) * CFrame.Angles(0, rotationY or 0, 0))
	task.spawn(function()

		local warn = Instance.new("Part", Effects)
		warn.Anchored, warn.CanCollide, warn.Massless = true, false, true
		warn.Material, warn.Color = Enum.Material.Neon, Color3.new(1, 0, 0)
		warn.Shape = Enum.PartType.Block
		warn.Size = Vector3.new(width, 0.1, depth)
		warn.CFrame = baseCF

		TS:Create(warn, TweenInfo.new(0.4 / speedMult), {Transparency = 1, Size = Vector3.new(width*1.1, 0.1, depth*1.1)}):Play()
		task.wait(0.4 / speedMult)
		warn:Destroy()

		local hitbox = Instance.new("Part", Effects)
		hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
		hitbox.Size = Vector3.new(width, 15, depth)
		hitbox.CFrame = baseCF * CFrame.new(0, -12, 0)

		-- VISUAL BONES: Always use a single stretched bone regardless of mode or load.
		-- This is both lag-free and visually clear.
		local visualBones = {}
		do
			local b = Instance.new("Part", Effects)
			b.Anchored, b.CanCollide = true, false
			b.Size = Vector3.new(width * 0.95, 15, depth * 0.95)
			b.CFrame = baseCF * CFrame.new(0, -12, 0)
			b.Material, b.Color = Enum.Material.SmoothPlastic, Color3.new(1,1,1)
			local sm = Instance.new("SpecialMesh", b)
			sm.MeshType, sm.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633"
			sm.Scale = Vector3.new(width * 0.015, 0.05, depth * 0.015)
			table.insert(visualBones, b)
		end

		local sound = Instance.new("Sound", hitbox) sound.SoundId, sound.Volume = "rbxassetid://306247749", 2 sound:Play()

		local tUp = TweenInfo.new(0.2 / speedMult, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TS:Create(hitbox, tUp, {CFrame = baseCF * CFrame.new(0, 7.5, 0)}):Play()
		for _, b in ipairs(visualBones) do TS:Create(b, tUp, {CFrame = b.CFrame * CFrame.new(0, 19.5, 0)}):Play() end

		local active = true
		task.spawn(function()
			local hitCache = {}
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while active and hitbox.Parent do
				for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.2 then
							hitCache[hum] = tick()
							-- TRIPLED DAMAGE: Drops 3 HP directly alongside applying 1 KR tick!
							local boneDamage = 4
							if Death == true or Death2 == true then
								boneDamage = boneDamage * 2
							end
							hum.Health = hum.Health - boneDamage -- Slightly more direct damage if no KR
							if not noKR then _G.ApplyKarmaHit(hum) end
						end
					end
				end
				task.wait(0.1)
			end
		end)

		task.wait(onlyFasterSpawn and 1.5 or (1.5 / speedMult))
		active = false

		local tDownDur = onlyFasterSpawn and 0.5 or (0.5 / speedMult)
		local tDown = TweenInfo.new(tDownDur)
		TS:Create(hitbox, tDown, {CFrame = baseCF * CFrame.new(0, -15, 0)}):Play()
		for _, b in ipairs(visualBones) do TS:Create(b, tDown, {CFrame = b.CFrame * CFrame.new(0, -19.5, 0)}):Play() end

		task.wait(tDownDur)
		hitbox:Destroy()
		for _, b in ipairs(visualBones) do b:Destroy() end
	end)
end

-- ============================================================
-- HELPER: CREATE DETAIL SANS AFTERIMAGE
-- ============================================================
local function CreateAfterimage(cframe, transparency, duration)
	local imgRoot = Instance.new("Model", Effects)
	imgRoot.Name = "Afterimage"

	local parts = {
		{ name = "Torso", size = Vector3.new(2, 2, 1), offset = CFrame.new(0, 0, 0), color = Color3.fromRGB(0, 170, 255), trans = transparency },
		{ name = "Head", size = Vector3.new(1, 1, 1), offset = CFrame.new(0, 1.5, 0), color = Color3.fromRGB(0, 170, 255), trans = transparency },
		{ name = "LArm", size = Vector3.new(0.8, 1.8, 0.8), offset = CFrame.new(-1.4, 0, 0), color = Color3.fromRGB(0, 130, 220), trans = transparency + 0.1 },
		{ name = "RArm", size = Vector3.new(0.8, 1.8, 0.8), offset = CFrame.new(1.4, 0, 0), color = Color3.fromRGB(0, 130, 220), trans = transparency + 0.1 },
		{ name = "LLeg", size = Vector3.new(0.8, 1.8, 0.8), offset = CFrame.new(-0.6, -1.9, 0), color = Color3.fromRGB(0, 100, 190), trans = transparency + 0.1 },
		{ name = "RLeg", size = Vector3.new(0.8, 1.8, 0.8), offset = CFrame.new(0.6, -1.9, 0), color = Color3.fromRGB(0, 100, 190), trans = transparency + 0.1 },
		{ name = "LeftEye", size = Vector3.new(0.22, 0.22, 0.22), offset = CFrame.new(-0.22, 1.55, -0.52), color = Color3.fromRGB(0, 255, 255), trans = 0, isBall = true },
		{ name = "RightEye", size = Vector3.new(0.22, 0.22, 0.22), offset = CFrame.new(0.22, 1.55, -0.52), color = Color3.fromRGB(0, 255, 255), trans = 0, isBall = true }
	}

	local torsoPart
	for _, pData in ipairs(parts) do
		local p = Instance.new("Part", imgRoot)
		p.Name = pData.name
		p.Anchored, p.CanCollide = true, false
		p.Size = pData.size
		p.CFrame = cframe * pData.offset
		p.Color = pData.color
		p.Material = Enum.Material.Neon
		p.Transparency = math.clamp(pData.trans, 0, 1)
		p.CastShadow = false
		if pData.isBall then
			p.Shape = Enum.PartType.Ball
		end
		if pData.name == "Torso" then
			torsoPart = p
		end
	end

	if torsoPart then
		local aura = Instance.new("SelectionBox", imgRoot)
		aura.Adornee = torsoPart
		aura.Color3 = Color3.fromRGB(0, 200, 255)
		aura.LineThickness = 0.04
		aura.SurfaceTransparency = 1
	end

	if duration and duration > 0 then
		task.spawn(function()
			task.wait(duration)
			for t = 1, 8 do
				for _, p in ipairs(imgRoot:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Transparency = math.min(1, p.Transparency + 0.12)
					end
				end
				task.wait(0.1)
			end
			imgRoot:Destroy()
		end)
	end

	return imgRoot
end

-- ============================================================
-- TELEPORT VARIANT 1 (E + M1)
-- Backstab: teleport behind victim → 0.2s → Sans escapes →
-- 0.25s → no-warning bone rise on the floor beneath victim.
-- ============================================================
function Attack_TeleportVariant1(boxCenter, boxSize)
	if attack then return end

	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if isPhase2 then
		local tHum = GetClosestTarget(mouse.Hit.p, 150)
		local tChar = tHum and tHum.Parent
		local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if tHRP then
			attack = true
			Pointing()
			
			local playerPos = tHRP.Position
			local savedCF = rootPart.CFrame
			
			local offsets = {
				Vector3.new(0, 0, 20),
				Vector3.new(20, 0, 0),
				Vector3.new(0, 0, -20),
				Vector3.new(-20, 0, 0)
			}
			
			task.spawn(function()
				for i, offset in ipairs(offsets) do
					if _G.CancelAttackTrigger then break end
					local targetPos = tHRP.Position -- track in real-time
					local spawnCF = CFrame.lookAt(targetPos + offset + Vector3.new(0, 1.5, 0), targetPos)
					
					-- Teleport Sans
					rootPart.CFrame = spawnCF
					CreateSound("12222170", Head, 5, 0.8)
					
					-- Leave afterimage
					CreateAfterimage(spawnCF, 0.3, 1.5)
					
					-- Spawn small blaster
					local blasterSize = 0.8
					local blSpawn = spawnCF.Position + Vector3.new(0, 10, 0)
					SummonModernBlaster(blSpawn, spawnCF.Position, targetPos, blasterSize)
					
					task.wait(0.12)
				end
				
				-- Teleport Sans back to safety
				rootPart.CFrame = savedCF
				CreateSound("12222170", Head, 5, 0.8)
				
				task.wait(0.2)
				attack = false
			end)
		else
			teleport()
		end
		return
	end

	local targets = {}
	if boxCenter and boxSize then
		local half = boxSize / 2
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
				local hrp = p.Character.HumanoidRootPart
				local pos = hrp.Position
				if math.abs(pos.X - boxCenter.X) <= half and
					math.abs(pos.Z - boxCenter.Z) <= half and
					pos.Y >= boxCenter.Y - 5 and pos.Y <= boxCenter.Y + 55 then
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum.Health > 0 and p.Character ~= Character then
						table.insert(targets, p.Character)
					end
				end
			end
		end
	else
		local tHum = GetClosestTarget(mouse.Hit.p, 120)
		if tHum and tHum.Parent and tHum.Parent:FindFirstChild("HumanoidRootPart") then
			table.insert(targets, tHum.Parent)
		end
	end

	if #targets == 0 then
		if not boxCenter then
			teleport()
		end
		return
	end

	-- Cancel any active grab immediately
	grabbing = false
	_G.isSlamKeyHeld = false

	attack = true

	local primaryTarget = targets[1]
	local otherTargets = {}
	for i = 2, #targets do
		table.insert(otherTargets, targets[i])
	end

	-- Execute teleport on primary target (where real Sans teleports)
	task.spawn(function()
		local hl = Instance.new("Highlight", Character)
		hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
		CreateSound("12222170", Head, 5, 0.6)
		task.wait(0.05)

		local behindCF = primaryTarget.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		rootPart.CFrame = behindCF
		hl:Destroy()

		task.wait(0.2)

		local escapeAngle = math.rad(math.random(0, 359))
		local escapeDist = 30
		local escapePos = rootPart.Position + Vector3.new(math.cos(escapeAngle) * escapeDist, 0, math.sin(escapeAngle) * escapeDist)
		local hl2 = Instance.new("Highlight", Character)
		hl2.FillColor, hl2.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
		CreateSound("12222170", Head, 5, 0.65)
		task.wait(0.05)
		rootPart.CFrame = CFrame.new(escapePos + Vector3.new(0, 1.5, 0))
		hl2:Destroy()

		task.wait(0.25)

		local victimPos = primaryTarget.HumanoidRootPart.Position
		local rayOrigin = victimPos + Vector3.new(0, 3, 0)
		local rayDir = Vector3.new(0, -40, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {primaryTarget, Character, Effects}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayResult = workspace:Raycast(rayOrigin, rayDir, raycastParams)
		local floorPos = rayResult and rayResult.Position or (victimPos - Vector3.new(0, 3, 0))

		WarnAndRise(floorPos, 0, 14, 14, "Rise", 5, false, true)
	end)

	-- Execute afterimage teleports on other targets simultaneously
	for _, target in ipairs(otherTargets) do
		task.spawn(function()
			CreateSound("12222170", target.HumanoidRootPart, 3, 0.6)
			task.wait(0.05)

			local behindCF = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
			local afterimage = CreateAfterimage(behindCF, 0.35, 0.2)

			task.wait(0.2)

			CreateSound("12222170", target.HumanoidRootPart, 3, 0.65)
			task.wait(0.25)

			local victimPos = target.HumanoidRootPart.Position
			local rayOrigin = victimPos + Vector3.new(0, 3, 0)
			local rayDir = Vector3.new(0, -40, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {target, Character, Effects}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local rayResult = workspace:Raycast(rayOrigin, rayDir, raycastParams)
			local floorPos = rayResult and rayResult.Position or (victimPos - Vector3.new(0, 3, 0))

			WarnAndRise(floorPos, 0, 14, 14, "Rise", 5, false, true)
		end)
	end

	task.wait(0.6)
	attack = false
end

-- ============================================================
-- TELEPORT VARIANT 2 (E + M1)
-- Blitz: 3s circling with detailed afterimages → freeze →
-- bones appear (still) → escape → 0.5s → bones thrown at
-- player → unfreeze when any bone gets close enough.
-- ============================================================
function Attack_TeleportVariant2(boxCenter, boxSize)
	if attack then return end

	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if isPhase2 then
		attack = true
		Pointing()
		
		-- Play field activation sound
		CreateSound("482211201", Head, 6, 0.7)
		
		-- Create visual 20-stud radius (40-stud diameter) blue neon sphere field
		local field = Instance.new("Part", Effects)
		field.Name = "InvertionField"
		field.Shape = Enum.PartType.Ball
		field.Size = Vector3.new(40, 40, 40)
		field.Color = Color3.fromRGB(0, 170, 255)
		field.Material = Enum.Material.Neon
		field.Transparency = 0.88
		field.CanCollide = false
		field.Anchored = false
		field.Massless = true
		
		local w = Instance.new("Weld", field)
		w.Part0 = rootPart
		w.Part1 = field
		w.C0 = CFrame.new(0, 0, 0)
		
		task.spawn(function()
			local teleportCount = 0
			
			while true do
				if _G.CancelAttackTrigger then break end
				if teleportCount >= 5 then break end
				
				for _, p in ipairs(game.Players:GetPlayers()) do
					local char = p.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hrp and hum and hum.Health > 0 and char ~= Character and p ~= Player then
						local dist = (hrp.Position - rootPart.Position).Magnitude
						if dist < 20 then
							-- Teleport them 30 studs away!
							local dir = (hrp.Position - rootPart.Position)
							local flatDir = Vector3.new(dir.X, 0, dir.Z)
							local teleportDir = Vector3.new(1, 0, 0)
							local mag = flatDir.Magnitude
							if mag > 0.1 then
								teleportDir = flatDir / mag
							end
							
							local targetPos = rootPart.Position + (teleportDir * 30)
							
							-- Snap to floor (uses the proxy workspace to ignore invisible walls)
							local ray = Ray.new(targetPos + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0))
							local hitPart, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, {char, Character, Effects}, false, true)
							local finalPos = (hitPart and floorPos) or targetPos
							
							-- Visual effects
							CreateSound("12222170", hrp, 5, 0.8)
							local hl = Instance.new("Highlight", char)
							hl.FillColor = Color3.fromRGB(0, 170, 255)
							hl.OutlineColor = Color3.fromRGB(255, 255, 255)
							game.Debris:AddItem(hl, 0.5)
							
							hrp.CFrame = CFrame.new(finalPos + Vector3.new(0, 3, 0))
							teleportCount = teleportCount + 1
							if teleportCount >= 5 then break end
						end
					end
				end
				task.wait(0.05)
			end
			
			if teleportCount >= 5 then
				if field then field:Destroy() end
				Animations = false
				attack = true
				_G.heavilyBreathing = true
				Expression.Texture = "rbxassetid://4484447540"
				_G.SansCannotMoveEnd = tick() + 2 -- Tired unable to move for 2 seconds
				task.wait(2) -- Tired unable to move for 2 seconds
				_G.heavilyBreathing = false
				Expression.Texture = "rbxassetid://4899271236"
				attack = false
				_G.SansSlowDebuffEnd = tick() + 5 -- Moving at slow walkspeed for 5 seconds
			else
				-- Fade out field
				for i = 1, 10 do
					if field then field.Transparency = 0.88 + (i * 0.012) end
					task.wait(0.03)
				end
				if field then field:Destroy() end
				attack = false
			end
		end)
		return
	end

	local targets = {}
	if boxCenter and boxSize then
		local half = boxSize / 2
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
				local hrp = p.Character.HumanoidRootPart
				local pos = hrp.Position
				if math.abs(pos.X - boxCenter.X) <= half and
					math.abs(pos.Z - boxCenter.Z) <= half and
					pos.Y >= boxCenter.Y - 5 and pos.Y <= boxCenter.Y + 55 then
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum.Health > 0 and p.Character ~= Character then
						table.insert(targets, p.Character)
					end
				end
			end
		end
	else
		local tHum = GetClosestTarget(mouse.Hit.p, 120)
		if tHum and tHum.Parent and tHum.Parent:FindFirstChild("HumanoidRootPart") then
			table.insert(targets, tHum.Parent)
		end
	end

	if #targets == 0 then
		return
	end

	-- Cancel any active grab immediately
	grabbing = false
	_G.isSlamKeyHeld = false

	attack = true

	local primaryTarget = targets[1]
	local otherTargets = {}
	for i = 2, #targets do
		table.insert(otherTargets, targets[i])
	end

	local NUM_IMAGES   = 12
	local TOTAL_DURATION = 1.2
	local FLASH_DURATION = 0.05
	local ORBIT_RADIUS = 14
	local timePerStop  = TOTAL_DURATION / NUM_IMAGES

	-- Execute blitz on primary target (real Sans orbits them)
	task.spawn(function()
		local targetPos = primaryTarget.HumanoidRootPart.Position
		local hum = primaryTarget:FindFirstChildOfClass("Humanoid")
		local savedWS = hum.WalkSpeed
		local savedJP = hum.JumpPower
		local savedUJP = hum.UseJumpPower
		local savedJH = hum.JumpHeight

		hum.WalkSpeed = 0
		hum.JumpPower = 0
		pcall(function() hum.UseJumpPower = true end)

		local frozenBP = Instance.new("BodyPosition", primaryTarget.HumanoidRootPart)
		frozenBP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		frozenBP.D, frozenBP.P = 1000, 50000
		frozenBP.Position = primaryTarget.HumanoidRootPart.Position

		local frozenBG = Instance.new("BodyGyro", primaryTarget.HumanoidRootPart)
		frozenBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		frozenBG.D, frozenBG.P = 1000, 50000
		frozenBG.CFrame = primaryTarget.HumanoidRootPart.CFrame

		local blueGui = Instance.new("BillboardGui", primaryTarget.HumanoidRootPart)
		blueGui.Size, blueGui.AlwaysOnTop = UDim2.new(2.5, 0, 2.5, 0), true
		local blueImg = Instance.new("ImageLabel", blueGui)
		blueImg.Image = "rbxassetid://338425795"
		blueImg.BackgroundTransparency, blueImg.Size = 1, UDim2.new(1, 0, 1, 0)
		blueImg.ImageColor3 = Color3.fromRGB(0, 100, 255)

		local blueHighlight = Instance.new("Highlight", primaryTarget)
		blueHighlight.Name = "BlueSoulHighlight"
		blueHighlight.FillColor = Color3.fromRGB(0, 100, 255)
		blueHighlight.OutlineColor = Color3.fromRGB(0, 200, 255)
		blueHighlight.FillTransparency = 0.5
		blueHighlight.OutlineTransparency = 0

		local afterimages = {}
		for i = 1, NUM_IMAGES do
			local angle = math.rad((360 / NUM_IMAGES) * i)
			local orbitPos = targetPos + Vector3.new(math.cos(angle) * ORBIT_RADIUS, 0, math.sin(angle) * ORBIT_RADIUS)
			local lookCF = CFrame.lookAt(orbitPos + Vector3.new(0, 1.5, 0), targetPos)

			local hl = Instance.new("Highlight", Character)
			hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
			CreateSound("12222170", Head, 5, 0.6)
			rootPart.CFrame = lookCF
			task.wait(FLASH_DURATION)
			hl:Destroy()

			local imgRoot = CreateAfterimage(lookCF, 0.35, 0)
			local boneLaunchCF = CFrame.lookAt(orbitPos + Vector3.new(0, 2, 0), targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
			table.insert(afterimages, {model = imgRoot, boneCF = boneLaunchCF})

			task.wait(math.max(0, timePerStop - FLASH_DURATION))
		end

		local homingCFrames = {}
		for _, imgData in ipairs(afterimages) do
			table.insert(homingCFrames, imgData.boneCF)
		end

		local escapeAngle = math.rad(math.random(0, 359))
		local escapePos = targetPos + Vector3.new(math.cos(escapeAngle) * 50, 0, math.sin(escapeAngle) * 50)
		local hl3 = Instance.new("Highlight", Character)
		hl3.FillColor, hl3.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
		CreateSound("12222170", Head, 5, 0.65)
		task.wait(0.08)
		rootPart.CFrame = CFrame.new(escapePos + Vector3.new(0, 1.5, 0), targetPos)
		hl3:Destroy()

		task.wait(0.5)

		task.spawn(function()
			for t = 1, 8 do
				for _, imgData in ipairs(afterimages) do
					if imgData.model and imgData.model.Parent then
						for _, p in ipairs(imgData.model:GetDescendants()) do
							if p:IsA("BasePart") then
								p.Transparency = math.min(1, p.Transparency + 0.12)
							end
						end
					end
				end
				task.wait(0.1)
			end
			for _, imgData in ipairs(afterimages) do
				if imgData.model and imgData.model.Parent then imgData.model:Destroy() end
			end
		end)

		for _, boneCF in ipairs(homingCFrames) do
			SummonModernBone(boneCF, Vector3.new(0.015, 0.015, 0.015), true, 8, 2.0, nil, nil, true)
		end

		local MAX_FREEZE_TIME = 6
		local startTime = tick()
		local unfrozen = false
		while not unfrozen and tick() - startTime < MAX_FREEZE_TIME do
			if not primaryTarget.HumanoidRootPart or not primaryTarget.HumanoidRootPart.Parent then break end
			for _, obj in pairs(Effects:GetChildren()) do
				if obj:IsA("Part") and obj.Name == "HomingBone" then
					local dist = (obj.Position - primaryTarget.HumanoidRootPart.Position).Magnitude
					if dist < 10 then
						unfrozen = true
						break
					end
				end
			end
			task.wait(0.05)
		end

		if frozenBP and frozenBP.Parent then frozenBP:Destroy() end
		if frozenBG and frozenBG.Parent then frozenBG:Destroy() end
		if blueGui and blueGui.Parent then blueGui:Destroy() end
		if blueHighlight and blueHighlight.Parent then blueHighlight:Destroy() end
		if primaryTarget and primaryTarget.Parent then
			local h = primaryTarget:FindFirstChildOfClass("Humanoid")
			if h then
				h.WalkSpeed = savedWS
				h.JumpPower = savedJP
				pcall(function() h.UseJumpPower = savedUJP end)
				pcall(function() h.JumpHeight = savedJH end)
			end
		end
	end)

	-- Execute afterimage-only variant on other targets simultaneously (no actual Sans teleporting there)
	for _, target in ipairs(otherTargets) do
		task.spawn(function()
			local targetPos = target.HumanoidRootPart.Position
			local hum = target:FindFirstChildOfClass("Humanoid")
			local savedWS = hum.WalkSpeed
			local savedJP = hum.JumpPower
			local savedUJP = hum.UseJumpPower
			local savedJH = hum.JumpHeight

			hum.WalkSpeed = 0
			hum.JumpPower = 0
			pcall(function() hum.UseJumpPower = true end)

			local frozenBP = Instance.new("BodyPosition", target.HumanoidRootPart)
			frozenBP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			frozenBP.D, frozenBP.P = 1000, 50000
			frozenBP.Position = target.HumanoidRootPart.Position

			local frozenBG = Instance.new("BodyGyro", target.HumanoidRootPart)
			frozenBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			frozenBG.D, frozenBG.P = 1000, 50000
			frozenBG.CFrame = target.HumanoidRootPart.CFrame

			local blueGui = Instance.new("BillboardGui", target.HumanoidRootPart)
			blueGui.Size, blueGui.AlwaysOnTop = UDim2.new(2.5, 0, 2.5, 0), true
			local blueImg = Instance.new("ImageLabel", blueGui)
			blueImg.Image = "rbxassetid://338425795"
			blueImg.BackgroundTransparency, blueImg.Size = 1, UDim2.new(1, 0, 1, 0)
			blueImg.ImageColor3 = Color3.fromRGB(0, 100, 255)

			local blueHighlight = Instance.new("Highlight", target)
			blueHighlight.Name = "BlueSoulHighlight"
			blueHighlight.FillColor = Color3.fromRGB(0, 100, 255)
			blueHighlight.OutlineColor = Color3.fromRGB(0, 200, 255)
			blueHighlight.FillTransparency = 0.5
			blueHighlight.OutlineTransparency = 0

			local afterimages = {}
			for i = 1, NUM_IMAGES do
				local angle = math.rad((360 / NUM_IMAGES) * i)
				local orbitPos = targetPos + Vector3.new(math.cos(angle) * ORBIT_RADIUS, 0, math.sin(angle) * ORBIT_RADIUS)
				local lookCF = CFrame.lookAt(orbitPos + Vector3.new(0, 1.5, 0), targetPos)

				CreateSound("12222170", target.HumanoidRootPart, 3, 0.6)
				local imgRoot = CreateAfterimage(lookCF, 0.35, 0)

				local boneLaunchCF = CFrame.lookAt(orbitPos + Vector3.new(0, 2, 0), targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
				table.insert(afterimages, {model = imgRoot, boneCF = boneLaunchCF})

				task.wait(timePerStop)
			end

			local homingCFrames = {}
			for _, imgData in ipairs(afterimages) do
				table.insert(homingCFrames, imgData.boneCF)
			end

			CreateSound("12222170", target.HumanoidRootPart, 3, 0.65)
			task.wait(0.5)

			task.spawn(function()
				for t = 1, 8 do
					for _, imgData in ipairs(afterimages) do
						if imgData.model and imgData.model.Parent then
							for _, p in ipairs(imgData.model:GetDescendants()) do
								if p:IsA("BasePart") then
									p.Transparency = math.min(1, p.Transparency + 0.12)
								end
							end
						end
					end
					task.wait(0.1)
				end
				for _, imgData in ipairs(afterimages) do
					if imgData.model and imgData.model.Parent then imgData.model:Destroy() end
				end
			end)

			for _, boneCF in ipairs(homingCFrames) do
				SummonModernBone(boneCF, Vector3.new(0.015, 0.015, 0.015), true, 8, 2.0, nil, nil, true)
			end

			local MAX_FREEZE_TIME = 6
			local startTime = tick()
			local unfrozen = false
			while not unfrozen and tick() - startTime < MAX_FREEZE_TIME do
				if not target.HumanoidRootPart or not target.HumanoidRootPart.Parent then break end
				for _, obj in pairs(Effects:GetChildren()) do
					if obj:IsA("Part") and obj.Name == "HomingBone" then
						local dist = (obj.Position - target.HumanoidRootPart.Position).Magnitude
						if dist < 10 then
							unfrozen = true
							break
						end
					end
				end
				task.wait(0.05)
			end

			if frozenBP and frozenBP.Parent then frozenBP:Destroy() end
			if frozenBG and frozenBG.Parent then frozenBG:Destroy() end
			if blueGui and blueGui.Parent then blueGui:Destroy() end
			if blueHighlight and blueHighlight.Parent then blueHighlight:Destroy() end
			if target and target.Parent then
				local h = target:FindFirstChildOfClass("Humanoid")
				if h then
					h.WalkSpeed = savedWS
					h.JumpPower = savedJP
					pcall(function() h.UseJumpPower = savedUJP end)
					pcall(function() h.JumpHeight = savedJH end)
				end
			end
		end)
	end

	task.wait(TOTAL_DURATION + 0.6)
	attack = false
end

-- 💀 MASTER GASTER BLASTER FUNCTION
function SummonModernBlaster(spawnPos, hoverPos, targetPos, size, isOmega, delayShootTime)
	task.spawn(function()
		-- Ensure the blaster remains streamed in/rendered for players asynchronously in the background
		task.spawn(pcall, function()
			for _, ply in ipairs(game:GetService("Players"):GetPlayers()) do
				ply:RequestStreamAroundPoint(hoverPos)
			end
		end)

		local GB = Instance.new("Part", Effects)
		GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
		GB.Material, GB.BrickColor, GB.CFrame = Enum.Material.SmoothPlastic, BrickColor.new("White"), CFrame.new(spawnPos)

		local sm = Instance.new("SpecialMesh", GB)
		sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

		local Charge = Instance.new("Sound", GB)
		Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
		if not delayShootTime or delayShootTime <= 0 then
			Charge:Play()
		end

		local aimCF = CFrame.lookAt(hoverPos, targetPos)
		local blasterCenterCF = aimCF * CFrame.new(0, size * 1.25, 0)
		TS:Create(GB, TweenInfo.new(0.4, Enum.EasingStyle.Back), {CFrame = blasterCenterCF}):Play()
		TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()
		task.wait(0.45)

		if delayShootTime and delayShootTime > 0 then
			local d = delayShootTime - 0.9
			if d > 0 then
				task.wait(d)
			end
			Charge:Play()
			task.wait(0.45)
		end

		sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
		sm.MeshId = "rbxassetid://2649610132"

		local Fire = Instance.new("Sound", GB)
		Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
		Fire:Play()

		local mag = 300
		local beamOffsetY = -size * 1.25
		local beam = Instance.new("Part", Effects)
		beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
		beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)
		beam.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)

		local hitbox = Instance.new("Part", Effects)
		hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
		hitbox.Size, hitbox.CFrame = Vector3.new(size*2.5, size*2.5, mag), GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)

		TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, size*2.5, size*2.5)}):Play()

		local beamActive = true
		task.spawn(function()
			local hitCache = {}
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while beamActive do
				for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
							hitCache[hum] = tick()
							local baseDmg = 1.5
							if isOmega then
								baseDmg = baseDmg * 2
							end
							if _G.Phase2PlatformActive then
								baseDmg = baseDmg * 5
							end
							_G.ApplyKarmaHit(hum, baseDmg)
						end
					end
				end
				task.wait(0.1)
			end
		end)

		-- BEAMS LAST TWICE AS LONG! (2.0s for big, 0.8s for small)
		local beamDuration = (size >= 3) and 2.0 or 0.8
		if isOmega then
			beamDuration = 4.0
		end
		task.wait(beamDuration)
		beamActive = false

		TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
		TS:Create(GB, TweenInfo.new(0.3), {Transparency = 1}):Play()
		task.wait(0.3)
		beam:Destroy() hitbox:Destroy() GB:Destroy()
	end)
end

-- ========================================== --
-- ATTACK TRIGGERS
-- ========================================== --

Attack_BoneRise = function(useVariant)
	-- Auto-aim to the nearest player's real standing position (floor/platform) when Sans is stationed on his standing platform
	if _G.SansOnPlatform and not useVariant then
		local closestHum = GetClosestTarget(rootPart.Position, 500)
		if closestHum and closestHum.Parent and closestHum.Parent:FindFirstChild("HumanoidRootPart") then
			local tRoot = closestHum.Parent.HumanoidRootPart
			-- Target the exact floor position below the player. We start ray slightly above feet
			-- and cast down. We explicitly do NOT ignore Effects here so we hit the moving platforms.
			local floorRay = Ray.new(tRoot.Position + Vector3.new(0, 2, 0), Vector3.new(0, -15, 0))
			local hit, hitPos = realWorkspace:FindPartOnRayWithIgnoreList(floorRay, {Character}, false, true)
			local finalPos = hitPos or (tRoot.Position - Vector3.new(0, 3, 0))
			WarnAndRise(finalPos, 0, 14, 14, "Rise")
		end
		return
	end

	if useVariant then
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if isPhase2 then
			if _G.Phase2PlatformActive then return end
			local centerPos = mouse.Hit.p
			local ignoreList = {Character, Effects}
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
					table.insert(ignoreList, v)
				end
			end
			local ray = Ray.new(centerPos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
			local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
			if not floorPos then floorPos = centerPos - Vector3.new(0, 3, 0) end

			local cellWidth = 28
			for row = -3, 2 do
				for col = -3, 2 do
					if (row + col) % 2 == 0 then
						local offset = Vector3.new(row * cellWidth, 0, col * cellWidth)
						local cellPos = floorPos + offset

						local cRay = Ray.new(cellPos + Vector3.new(0, 20, 0), Vector3.new(0, -100, 0))
						local _, cellFloor = workspace:FindPartOnRayWithIgnoreList(cRay, ignoreList)
						if not cellFloor then cellFloor = cellPos - Vector3.new(0, 3, 0) end

						WarnAndRise(cellFloor, 0, cellWidth, cellWidth, "Rise")
					end
				end
			end
		else
			for i = 1, 6 do
				local startCF = rootPart.CFrame * CFrame.new(math.random(-20,20), 15, math.random(-20,20)) * CFrame.Angles(math.rad(-90),0,0)
				SummonModernBone(startCF, Vector3.new(0.015, 0.015, 0.015), true, 4, 1.8, nil, 0.3)
				task.wait(0.1)
			end
		end
	else
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if isPhase2 and isCtrlHeld then
			if _G.Phase2PlatformActive then return end
			local centerPos = mouse.Hit.p
			local ignoreList = {Character, Effects}
			for _, v in pairs(workspace:GetChildren()) do
				if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
					table.insert(ignoreList, v)
				end
			end
			local ray = Ray.new(centerPos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
			local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
			if not floorPos then floorPos = centerPos - Vector3.new(0, 3, 0) end

			local cellWidth = 24
			local gridRadius = 5
			task.spawn(function()
				for pulse = 1, 6 do
					if _G.CancelAttackTrigger then break end
					local activePattern = (pulse % 2 == 1) and 0 or 1

					for row = -gridRadius, gridRadius - 1 do
						for col = -gridRadius, gridRadius - 1 do
							if (row + col) % 2 == activePattern then
								local offset = Vector3.new(row * cellWidth, 0, col * cellWidth)
								local cellPos = floorPos + offset

								local cRay = Ray.new(cellPos + Vector3.new(0, 20, 0), Vector3.new(0, -100, 0))
								local _, cellFloor = workspace:FindPartOnRayWithIgnoreList(cRay, ignoreList)
								if not cellFloor then cellFloor = cellPos - Vector3.new(0, 3, 0) end

								WarnAndRise(cellFloor, 0, cellWidth, cellWidth, "Rise", 2.0, false, false)
							end
						end
					end
					task.wait(1.4)
				end
			end)
		else
			-- Find the floor directly under any hovered/targeted position by raycasting from
			-- 1 stud below the player's feet downward — always lands flush on the floor surface.
			local targetPos, snapPlatform = ResolveAimHit()
			-- If aiming straight at a moving platform, anchor the bone rise to its
			-- top surface RIGHT NOW (avoids the platform sliding out from under
			-- the raycast and the bone falling into the sea below).
			if snapPlatform then
				WarnAndRise(targetPos, 0, 14, 14, "Rise")
				return
			end
			-- First try to find a player under the mouse, and use their feet position
			local tHum = GetClosestTarget(targetPos, 30)
			local origin
			if tHum and tHum.Parent and tHum.Parent:FindFirstChild("HumanoidRootPart") then
				local hrp = tHum.Parent.HumanoidRootPart
				origin = hrp.Position -- raycast from HRP downward
			else
				origin = targetPos + Vector3.new(0, 10, 0)
			end
			local ray = Ray.new(origin, Vector3.new(0, -50, 0))
			local _, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, {Character, Effects})
			WarnAndRise(hitPos, 0, 14, 14, "Rise")
		end
	end
end

function Attack_HomingBone(useVariant)
	Pointing()

	-- Special auto-homing targeting sequence when Sans is stationed on his standing platform
	if _G.SansOnPlatform then
		local closestHum = GetClosestTarget(rootPart.Position, 500)
		if closestHum and closestHum.Parent and closestHum.Parent:FindFirstChild("HumanoidRootPart") then
			local tRoot = closestHum.Parent.HumanoidRootPart
			local startCF = CFrame.new(rootPart.Position + Vector3.new(0, 15, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
			if useVariant then
				SummonModernBone(startCF, Vector3.new(0.07, 0.07, 0.07), true, 20, 0.7)
			else
				SummonModernBone(startCF, Vector3.new(0.012, 0.012, 0.012), true, 3, 2.5)
			end
		end
		return
	end

	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if isPhase2 then
		-- Phase 2 Homing Bone Attack
		local closestHum = nil
		local closestDist = math.huge
		for _, p in ipairs(game.Players:GetPlayers()) do
			local char = p.Character
			if char and char ~= Character then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local dist = (hrp.Position - rootPart.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestHum = hum
					end
				end
			end
		end

		local targetChar = closestHum and closestHum.Parent
		local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local targetPos = targetHRP and targetHRP.Position or mouse.Hit.p

		if isCtrlHeld then
			if _G.Phase2PlatformActive then return end
			-- ========================================== --
			-- CONTROL VARIANT: 8 Orbiting Bone Circles
			-- ========================================== --
			local targetHumObj = closestHum
			local originalJumpPower = targetHumObj and targetHumObj.JumpPower or 50
			local originalUseJumpPower = targetHumObj and targetHumObj.UseJumpPower or true
			local heartGUI = nil
			if targetHumObj and targetHumObj.Parent then
				targetHumObj.UseJumpPower = true
				targetHumObj.JumpPower = 0
				
				local targetHRPObj = targetHumObj.Parent:FindFirstChild("HumanoidRootPart")
				if targetHRPObj then
					heartGUI = Instance.new("BillboardGui")
					heartGUI.Name = "BlueHeartOrbitLock"
					heartGUI.Size = UDim2.new(2,0,2,0)
					heartGUI.MaxDistance = 150
					heartGUI.AlwaysOnTop = true
					heartGUI.Parent = targetHRPObj

					local img = Instance.new("ImageLabel", heartGUI)
					img.Image = "rbxassetid://338425795" 
					img.BackgroundTransparency = 1
					img.Size = UDim2.new(1,0,1,0)
				end
			end

			local numCircles = 8
			local circles = {}
			local bonesScale = Vector3.new(2 / 37.5, 0.0333, 2 / 37.5)
			
			for c = 1, numCircles do
				local circleData = {
					bones = {},
					radius = 25 + (c * 6),
					orbitSpeed = 0.02,
					angle = math.rad(math.random(0, 359)),
					gapAngleOffset = math.rad(math.random(0, 359)),
					closeSpeed = 0.15,
					isActive = true,
					startedClosing = false
				}
				
				local totalSlots = 24
				for b = 1, 20 do
					local bone = Instance.new("Part", Effects)
					bone.Name = "OrbitingBone"
					bone.CanCollide, bone.Anchored, bone.Massless = false, true, true
					bone.Size = Vector3.new(bonesScale.X * 37.5, 5, bonesScale.Z * 37.5)
					bone.Material, bone.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
					local sm = Instance.new("SpecialMesh", bone)
					sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633", Vector3.new(bonesScale.X, 0.01666, bonesScale.Z)
					
					local sound = Instance.new("Sound", bone)
					sound.SoundId, sound.Volume = "rbxassetid://306247749", 0.5
					sound:Play()
					
					task.spawn(function()
						local hitCache = {}
						local overlapParams = OverlapParams.new()
						overlapParams.FilterDescendantsInstances = {Character, Effects}
						while bone.Parent do
							for _, p in ipairs(workspace:GetPartsInPart(bone, overlapParams)) do
								local hum = p.Parent:FindFirstChildOfClass("Humanoid")
								if hum and hum.Parent ~= Character then
									if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.15 then
										hitCache[hum] = tick()
										-- Check if player is in the air trying to jump over the bones
										local isJumping = (hum.FloorMaterial == Enum.Material.Air)
										local damage = 16
										local karmaTicks = 2
										if isJumping then
											damage = 160 -- Massive instakill / massive damage!
											karmaTicks = 25 -- massive karma ticks
										end
										hum.Health = hum.Health - damage
										_G.ApplyKarmaHit(hum, karmaTicks)
									end
								end
							end
							task.wait(0.05)
						end
					end)
					
					table.insert(circleData.bones, {
						part = bone,
						slotIndex = b
					})
				end
				
				table.insert(circles, circleData)
			end

			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < 27 do
					if _G.CancelAttackTrigger then break end
					if targetHumObj and targetHumObj.Parent then
						targetHumObj.JumpPower = 0
					end
					
					local pPos = targetPos
					if targetHRP and targetHRP.Parent and closestHum and closestHum.Health > 0 then
						pPos = targetHRP.Position
					end
					
					local timeElapsed = tick() - startTime
					
					for cIdx, cData in ipairs(circles) do
						if cData.isActive then
							local currentOrbitSpeed = cData.orbitSpeed
							local currentCloseSpeed = cData.closeSpeed
							
							local delayForThisCircle = 4.5 + (cIdx - 1) * 2.25
							if timeElapsed > delayForThisCircle then
								if not cData.startedClosing then
									cData.startedClosing = true
									cData.lockedCenter = pPos
								end
								-- 25% speed buff per row/circle
								local rowMultiplier = 1.25 ^ (cIdx - 1)
								currentOrbitSpeed = 0.02 * rowMultiplier
								currentCloseSpeed = 0.15 * rowMultiplier
								cData.radius = math.max(0, cData.radius - currentCloseSpeed)
							end
							
							cData.angle = cData.angle + currentOrbitSpeed
							
							local centerForThisCircle = cData.lockedCenter or pPos
							local totalSlots = 24
							for _, boneInfo in ipairs(cData.bones) do
								local bonePart = boneInfo.part
								if bonePart and bonePart.Parent then
									local bAngle = cData.angle + cData.gapAngleOffset + ((boneInfo.slotIndex - 1) * (2 * math.pi / totalSlots))
									local bPos = centerForThisCircle + Vector3.new(math.cos(bAngle) * cData.radius, 0, math.sin(bAngle) * cData.radius)
									bonePart.CFrame = CFrame.new(bPos)
								end
							end
							
							if cData.radius <= 0.1 then
								cData.isActive = false
								for _, boneInfo in ipairs(cData.bones) do
									if boneInfo.part then boneInfo.part:Destroy() end
								end
							end
						end
					end
					
					task.wait(1/60)
				end
				
				for _, cData in ipairs(circles) do
					for _, boneInfo in ipairs(cData.bones) do
						if boneInfo.part then boneInfo.part:Destroy() end
					end
				end
				
				if targetHumObj and targetHumObj.Parent then
					targetHumObj.JumpPower = originalJumpPower
					targetHumObj.UseJumpPower = originalUseJumpPower
				end
				if heartGUI then heartGUI:Destroy() end
			end)

		elseif useVariant then
			if _G.Phase2PlatformActive then return end
			-- ========================================== --
			-- M1 VARIANT: 5x damage limiter + inward circles
			-- ========================================== --
			local centerCircle = targetPos
			local outerBonesCount = 18
			local outerRadius = 24
			
			local sfx = CreateSound("306247749", Head, 5, 0.8)
			
			-- Spawn stationary outer limiter bones (x5 damage, 5x size, vertical/standing up)
			for i = 1, outerBonesCount do
				local angle = math.rad(i * (360 / outerBonesCount))
				local spawnPos = centerCircle + Vector3.new(math.cos(angle) * outerRadius, 0, math.sin(angle) * outerRadius)
				local startCF = CFrame.new(spawnPos)
				SummonModernBone(startCF, Vector3.new(0.125, 0.125, 0.125), false, 24, 0, nil, 100)
			end
			
			-- Spawn inner rings of inward-moving bones continuously (2x size) until outer circle despawns (24 seconds)
			task.spawn(function()
				local startTime = tick()
				local ringCount = 0
				while tick() - startTime < 24 do
					if _G.CancelAttackTrigger then break end
					ringCount = ringCount + 1
					
					-- Target the player's current real-time position when this ring spawns!
					local currentPlayerPos = centerCircle
					if targetHRP and targetHRP.Parent and closestHum and closestHum.Health > 0 then
						currentPlayerPos = targetHRP.Position
					end
					
					local radius = 20 - ((ringCount - 1) % 5) * 3.5
					if radius < 4 then radius = 4 end
					
					local numBones = math.max(4, math.floor(radius * 0.7))
					for i = 1, numBones do
						local angle = math.rad(i * (360 / numBones) + (ringCount * 15))
						local spawnPos = currentPlayerPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
						-- Orient bones to point directly at the player's current position!
						local startCF = CFrame.lookAt(spawnPos, currentPlayerPos) * CFrame.Angles(math.rad(-90), 0, 0)
						SummonModernBone(startCF, Vector3.new(0.03, 0.03, 0.03), false, 12, 1.5, nil, 3)
					end
					task.wait(1.2)
				end
			end)

		else
			-- ========================================== --
			-- NORMAL VARIANT: 12 Homing Bones
			-- ========================================== --
			local count = 12
			local radius = 18
			task.spawn(function()
				for i = 1, count do
					if _G.CancelAttackTrigger then break end
					local angle = math.rad(i * (360 / count))
					local spawnPos = targetPos + Vector3.new(math.cos(angle) * radius, 15, math.sin(angle) * radius)
					local startCF = CFrame.lookAt(spawnPos, targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
					SummonModernBone(startCF, Vector3.new(0.015, 0.015, 0.015), true, 8, 2.2)
					task.wait(0.1)
				end
			end)
		end
		return
	end

	if useVariant then 
		local startCF = rootPart.CFrame * CFrame.new(0, 15, 0) * CFrame.Angles(math.rad(-90),0,0)
		SummonModernBone(startCF, Vector3.new(0.07, 0.07, 0.07), true, 20, 0.7) -- FIX: doubled lifetime (10 → 20)
	else 
		-- FIXED: Normal bone now homes, but is slightly slower and lasts DOUBLE the time!
		local startCF = CFrame.lookAt((rootPart.CFrame * CFrame.new(0, 5, 0)).p, mouse.Hit.p) * CFrame.Angles(math.rad(-90),0,0)
		SummonModernBone(startCF, Vector3.new(0.012, 0.012, 0.012), true, 3, 2.5) -- FIX: doubled lifetime (1.5 → 3)
	end
end

function Attack_Invertion(useVariant)
	if attack then return end
	Pointing()
	attack = true

	local closestHum = nil
	local closestDist = math.huge
	for _, p in ipairs(game.Players:GetPlayers()) do
		local char = p.Character
		if char and char ~= Character then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local dist = (hrp.Position - rootPart.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestHum = hum
				end
			end
		end
	end

	local targetChar = closestHum and closestHum.Parent
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	local targetPlayer = closestHum and game.Players:GetPlayerFromCharacter(targetChar)

	if targetPlayer and targetHRP then
		local directionName = "North"
		if isCtrlHeld then
			directionName = "Right"
		elseif useVariant then
			directionName = "Left"
		end

		local slamSnd = Instance.new("Sound", targetHRP)
		slamSnd.SoundId, slamSnd.Volume = "rbxassetid://446961725", 5
		slamSnd:Play()
		game.Debris:AddItem(slamSnd, 2)

		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(0, 170, 255)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.5
		hl.Parent = targetChar
		game.Debris:AddItem(hl, 8)

		-- Trigger the actual screen rotation via the external LocalScript!
		local repStorage = game:GetService("ReplicatedStorage")
		local invEvent = repStorage:FindFirstChild("SansInvertionEvent")
		if not invEvent then
			invEvent = Instance.new("RemoteEvent")
			invEvent.Name = "SansInvertionEvent"
			invEvent.Parent = repStorage
		end
		
		local duration = 8
		
		_G.InvertionQueues = _G.InvertionQueues or {}
		
		local function processInvertionQueue(plr, hum, hrp)
			local queue = _G.InvertionQueues[plr]
			if not queue or queue.processing then return end
			queue.processing = true
			
			task.spawn(function()
				local originalWalkSpeed = hum.WalkSpeed
				local originalJumpPower = hum.JumpPower
				
				if queue.originalWalkSpeed then
					originalWalkSpeed = queue.originalWalkSpeed
				else
					queue.originalWalkSpeed = originalWalkSpeed
				end
				
				while #queue > 0 do
					local current = table.remove(queue, 1)
					local dirName = current.directionName
					local dur = current.duration
					
					if invEvent then
						invEvent:FireClient(plr, dirName, dur)
					end
					
					hum.WalkSpeed = 0
					
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(1e5, 0, 1e5)
					bv.Velocity = Vector3.new(0, 0, 0)
					bv.Parent = hrp
					
					local startTime = tick()
					while tick() - startTime < dur do
						if not hrp.Parent or hum.Health <= 0 then break end
						
						local moveDir = hum.MoveDirection
						local invertedMove = Vector3.new(0, 0, 0)
						
						if dirName == "North" then
							invertedMove = Vector3.new(moveDir.X, 0, -moveDir.Z)
						elseif dirName == "Left" then
							invertedMove = Vector3.new(moveDir.Z, 0, moveDir.X)
						elseif dirName == "Right" then
							invertedMove = Vector3.new(-moveDir.Z, 0, -moveDir.X)
						end
						
						if invertedMove.Magnitude > 0 then
							local horizVel = invertedMove.Unit * 16
							bv.Velocity = Vector3.new(horizVel.X, 0, horizVel.Z)
						else
							bv.Velocity = Vector3.new(0, 0, 0)
						end
						
						if hum.Jump then
							hum.Jump = false
							if hum.FloorMaterial ~= Enum.Material.Air then
								hrp.Velocity = Vector3.new(hrp.Velocity.X, originalJumpPower > 0 and originalJumpPower or 50, hrp.Velocity.Z)
							end
						end
						
						task.wait()
					end
					
					if bv then bv:Destroy() end
				end
				
				if hum and hum.Parent then
					hum.WalkSpeed = queue.originalWalkSpeed or 16
				end
				_G.InvertionQueues[plr] = nil
			end)
		end
		
		local queue = _G.InvertionQueues[targetPlayer]
		if not queue then
			queue = {}
			_G.InvertionQueues[targetPlayer] = queue
		end
		table.insert(queue, {directionName = directionName, duration = duration})
		processInvertionQueue(targetPlayer, closestHum, targetHRP)
	end

	task.wait(0.5)
	attack = false
end

local function showMobileButton(plr)
	if plr == Player then return end -- Don't show for Sans!
	local repStorage = game:GetService("ReplicatedStorage")
	local mobileEvent = repStorage:FindFirstChild("SansMobileButtonEvent")
	if mobileEvent then
		pcall(function()
			mobileEvent:FireClient(plr, true)
		end)
	end
end

local function DestroyMobileButtons()
	local repStorage = game:GetService("ReplicatedStorage")
	local mobileEvent = repStorage:FindFirstChild("SansMobileButtonEvent")
	if mobileEvent then
		for _, plr in ipairs(game.Players:GetPlayers()) do
			if plr ~= Player and plr.Parent then
				pcall(function()
					mobileEvent:FireClient(plr, false)
				end)
			end
		end
	end
end

_G.PhaseThroughPlatformForPlayer = function(plr)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local platforms = {}
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and p.Name == "M1Platform" then
				table.insert(platforms, p)
			end
		end
		
		if #platforms == 0 then return end
		
		table.sort(platforms, function(a, b)
			return a.Position.Y > b.Position.Y
		end)
		
		local pTop = platforms[1]
		local pBottom = platforms[2]
		
		local currentY = hrp.Position.Y
		
		if pTop and currentY >= pTop.Position.Y - 2.5 then
			-- We are on or above the top platform, teleport to bottom platform
			if pBottom then
				hrp.CFrame = CFrame.new(hrp.Position.X, pBottom.Position.Y + 3.0, hrp.Position.Z)
			end
		elseif pBottom and currentY >= pBottom.Position.Y - 2.5 then
			-- We are on or above the bottom platform, teleport to floor
			local ignore = {char, Character, pTop, pBottom}
			local effectsFolder = workspace:FindFirstChild("Stuff") or workspace:FindFirstChild("Effects")
			if effectsFolder then table.insert(ignore, effectsFolder) end
			
			local ray = Ray.new(pBottom.Position, Vector3.new(0, -300, 0))
			local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
			local floorY = floorPos and floorPos.Y or (pBottom.Position.Y - 10)
			
			hrp.CFrame = CFrame.new(hrp.Position.X, floorY + 3.0, hrp.Position.Z)
		end
	end
end

_G.Phase2PlatformActive = false

function Attack_Platform(useVariant)
	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if not isPhase2 then return end
	if attack then return end
	
	local mousePos = mouse.Hit.p
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local ray = Ray.new(mousePos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local center = floorPos or (mousePos - Vector3.new(0, 3, 0))

	local playerJumpPowers = {}
	local buffActive = true
	task.spawn(function()
		while buffActive do
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local char = plr.Character
				if char and char ~= Character then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						if not playerJumpPowers[plr] then
							playerJumpPowers[plr] = {jp = hum.JumpPower, ujp = hum.UseJumpPower}
						end
						hum.UseJumpPower = true
						local multiplier = _G.ObbyActive and 1.5 or 2.0
						hum.JumpPower = math.max(playerJumpPowers[plr].jp, 50) * multiplier
					end
				end
			end
			task.wait(0.5)
		end
	end)

	local function removeJumpBuff()
		buffActive = false
		DestroyMobileButtons()
		for plr, data in pairs(playerJumpPowers) do
			if plr.Parent and plr.Character then
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.JumpPower = data.jp
					hum.UseJumpPower = data.ujp
				end
			end
		end
	end

	if not isCtrlHeld and not useVariant then
		-- ========================================== --
		-- NORMAL VARIANT: Climbing Vertical Obby
		-- ========================================== --
		_G.ObbyActive = true
		
		-- Create a floating platform for Sans next to the obby
		local sansPlat = Instance.new("Part", Effects)
		sansPlat.Name = "SansObbyPlatform"
		sansPlat.Size = Vector3.new(12, 1.5, 12)
		sansPlat.Color = Color3.fromRGB(0, 200, 255)
		sansPlat.Material = Enum.Material.SmoothPlastic
		sansPlat.Anchored = true
		sansPlat.CanCollide = true
		
		-- Position it 70 studs away from obby center, at Y = 110 (midpoint of vertical obby)
		local sansPlatPos = center + Vector3.new(-70, 110, 0)
		sansPlat.CFrame = CFrame.new(sansPlatPos)
		
		local originalWalkSpeed = Humanoid.WalkSpeed
		local originalJumpPower = Humanoid.JumpPower
		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
		rootPart.Anchored = true
		
		task.spawn(function()
			local connection
			connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
				if not _G.ObbyActive or not sansPlat or not sansPlat.Parent or not rootPart or rootPart.Parent == nil then
					if connection then connection:Disconnect() end
					return
				end
				
				-- Lock Sans firmly on his platform, facing his aim target
				local _sansPos = sansPlatPos + Vector3.new(0, 3, 0)
				local _aimP = mouse.Hit.p
				local _flatAim = Vector3.new(_aimP.X, _sansPos.Y, _aimP.Z)
				if (_flatAim - _sansPos).Magnitude < 0.1 then
					_flatAim = _sansPos + Vector3.new(0, 0, -1)
				end
				rootPart.CFrame = CFrame.lookAt(_sansPos, _flatAim)
				rootPart.Velocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end)
			
			while _G.ObbyActive do
				task.wait(0.1)
			end
			
			if connection then connection:Disconnect() end
			pcall(function()
				rootPart.Anchored = false
				Humanoid.WalkSpeed = originalWalkSpeed
				Humanoid.JumpPower = originalJumpPower
				if sansPlat then sansPlat:Destroy() end
			end)
			pcall(function()
				rootPart.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))
			end)
		end)
		
		attack = true
		Pointing()

		-- Create 120x120x210 box of invisible walls and roof
		local walls = {}
		local wallHeight = 210
		local zoneSize = 120
		local wt = 5
		local wallOffsets = {
			{size = Vector3.new(zoneSize + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, zoneSize/2)},
			{size = Vector3.new(zoneSize + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, -zoneSize/2)},
			{size = Vector3.new(wt, wallHeight, zoneSize + wt*2), offset = Vector3.new(zoneSize/2, wallHeight/2, 0)},
			{size = Vector3.new(wt, wallHeight, zoneSize + wt*2), offset = Vector3.new(-zoneSize/2, wallHeight/2, 0)},
		}

		for _, wData in pairs(wallOffsets) do
			local wall = Instance.new("Part", Effects)
			wall.Name = "InvertionWall"
			wall.Anchored, wall.CanCollide, wall.Transparency = true, true, 1
			wall.CanQuery = false
			wall.Size = wData.size
			wall.CFrame = CFrame.new(center + wData.offset)
			table.insert(walls, wall)
		end

		local roof = Instance.new("Part", Effects)
		roof.Name = "InvertionRoof"
		roof.Size = Vector3.new(zoneSize, wt, zoneSize)
		roof.CFrame = CFrame.new(center + Vector3.new(0, wallHeight, 0))
		roof.Anchored, roof.CanCollide, roof.Transparency = true, true, 1
		roof.CanQuery = false
		table.insert(walls, roof)

		-- Helper for smooth, foolproof one-way collision check without head-bumps
		local function makePlatformPhasable(p, isVanish)
			setupOneWayPlatformBehavior(p, function()
				return _G.ObbyActive
			end, isVanish == true, 5, 10)
		end

		-- Spawn 3 static platform towers fanning up from 5 to 200 studs above ground
		local plats = {}
		
		-- Tower offsets spaced further apart to prevent clutter: Center (0, 0), Left (-45, 0), Right (45, 0)
		local towerOffsets = {Vector3.new(0, 0, 0), Vector3.new(-45, 0, 0), Vector3.new(45, 0, 0)}
		
		for _, towerOffset in ipairs(towerOffsets) do
			local lastX, lastY, lastZ = towerOffset.X, 5, towerOffset.Z
			while lastY < 200 do
				local p = Instance.new("Part", Effects)
				p.Name = "ObbyPlatform"
				p.Anchored = true
				p.Material = Enum.Material.SmoothPlastic
				p.Color = Color3.fromRGB(0, 200, 255)
				p.Size = Vector3.new(12, 1.5, 12)
				
				local angle = math.rad(math.random(0, 359))
				local dist = math.random(11, 16)
				local nextX = math.clamp(lastX + math.cos(angle) * dist, towerOffset.X - 15, towerOffset.X + 15)
				local nextZ = math.clamp(lastZ + math.sin(angle) * dist, towerOffset.Z - 15, towerOffset.Z + 15)
				local nextY = lastY + math.random(7, 11)
				
				p.CFrame = CFrame.new(center + Vector3.new(nextX, nextY, nextZ))
				
				local isTrap = (math.random() > 0.7)
				local isVanish = not isTrap and (math.random() > 0.6) -- Doubled the chance of purple vanish platforms from 20% to 40% (overall 14% to 28%)
				
				if isTrap and nextY < 185 then
					p.Color = Color3.fromRGB(255, 80, 80) -- reddish trap warning!
					local activeLoop = false
					p.Touched:Connect(function(hit)
						local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if activeLoop then return end
							activeLoop = true
							task.spawn(function()
								while p and p.Parent and _G.ObbyActive do
									local standing = false
									for _, plr in ipairs(game.Players:GetPlayers()) do
										local char = plr.Character
										if char and char ~= Character then
											local hrp = char:FindFirstChild("HumanoidRootPart")
											if hrp then
												local relPos = p.CFrame:PointToObjectSpace(hrp.Position)
												local withinXZ = math.abs(relPos.X) <= 6.5 and math.abs(relPos.Z) <= 6.5
												local abovePlatform = hrp.Position.Y >= p.Position.Y
												if withinXZ and abovePlatform then
													standing = true
													break
												end
											end
										end
									end
									
									if not standing then
										activeLoop = false
										break
									end
									
									WarnAndRise(p.CFrame * CFrame.new(0, 1.5, 0), 0, 10, 10, "Rise", 2.0)
									task.wait(1.8)
								end
							end)
						end
					end)
				elseif isVanish then
					p.Color = Color3.fromRGB(200, 0, 255) -- purple vanish warning!
				end

				makePlatformPhasable(p, isVanish)
				table.insert(plats, p)
				
				lastX, lastY, lastZ = nextX, nextY, nextZ
			end
		end

		task.wait(1)

		-- Spawn giant rising bone in the ground
		local giantBone = Instance.new("Part", Effects)
		giantBone.Name = "GiantRisingBonePlatform"
		giantBone.Anchored, giantBone.CanCollide, giantBone.Color = true, false, Color3.new(1,1,1)
		-- True size revealed immediately, 190 studs tall
		giantBone.Size = Vector3.new(120, 190, 120)
		-- Center is underground so top is at Y=0 initially
		giantBone.CFrame = CFrame.new(center + Vector3.new(0, -95, 0))
		local sm = Instance.new("SpecialMesh", giantBone)
		sm.MeshType, sm.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633"
		sm.Scale = Vector3.new(120 / 37.5, 190 / 300, 120 / 37.5)

		local sound = Instance.new("Sound", giantBone) sound.SoundId, sound.Volume = "rbxassetid://306247749", 8 sound:Play()

		-- Rise to exactly 190 studs max height (top of bone).
		-- Y=95 center puts top at 190. Halved speed again: 64 seconds.
		TS:Create(giantBone, TweenInfo.new(64, Enum.EasingStyle.Linear), {CFrame = CFrame.new(center + Vector3.new(0, 95, 0))}):Play()

		local active = true
		task.spawn(function()
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while active and giantBone.Parent do
				for _, hit in ipairs(workspace:GetPartsInPart(giantBone, params)) do
					local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						local giantDamage = 2.5
						if Death == true or Death2 == true then
							giantDamage = giantDamage * 2
						end
						hum.Health = hum.Health - giantDamage
						_G.ApplyKarmaHit(hum)
					end
				end
				task.wait(0.15)
			end
		end)

		task.wait(66)
		active = false

		-- Lower bone back and cleanup
		TS:Create(giantBone, TweenInfo.new(1.5), {CFrame = CFrame.new(center + Vector3.new(0, -95, 0))}):Play()
		task.wait(1.5)

		giantBone:Destroy()
		for _, w in pairs(walls) do w:Destroy() end
		for _, p in pairs(plats) do p:Destroy() end

		_G.ObbyActive = false
		removeJumpBuff()
		attack = false
	elseif useVariant then
		-- ========================================== --
		-- M1 VARIANT: 2 Long Platforms + Custom Combo
		-- ========================================== --
		-- Do-it-yourself combo: we do NOT set attack = true so Sans can freely attack!
		_G.Phase2PlatformActive = true
		for _, plr in ipairs(game.Players:GetPlayers()) do
			showMobileButton(plr)
		end

		-- Create 120x25x50 box of invisible walls
		local walls = {}
		local wallHeight = 50
		local zoneX = 120
		local zoneZ = 25
		local wt = 5
		local wallOffsets = {
			{size = Vector3.new(zoneX + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, zoneZ/2)},
			{size = Vector3.new(zoneX + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, -zoneZ/2)},
			{size = Vector3.new(wt, wallHeight, zoneZ + wt*2), offset = Vector3.new(zoneX/2, wallHeight/2, 0)},
			{size = Vector3.new(wt, wallHeight, zoneZ + wt*2), offset = Vector3.new(-zoneX/2, wallHeight/2, 0)},
		}

		for _, wData in pairs(wallOffsets) do
			local wall = Instance.new("Part", Effects)
			wall.Name = "InvertionWall"
			wall.Anchored, wall.CanCollide, wall.Transparency = true, true, 1
			wall.CanQuery = false
			wall.Size = wData.size
			wall.CFrame = CFrame.new(center + wData.offset)
			table.insert(walls, wall)
		end

		local roof = Instance.new("Part", Effects)
		roof.Name = "InvertionRoof"
		roof.Size = Vector3.new(zoneX, wt, zoneZ)
		roof.CFrame = CFrame.new(center + Vector3.new(0, wallHeight, 0))
		roof.Anchored, roof.CanCollide, roof.Transparency = true, true, 1
		roof.CanQuery = false
		table.insert(walls, roof)

		local p1 = Instance.new("Part", Effects)
		p1.Name = "M1Platform"
		p1.Anchored = true
		p1.Size = Vector3.new(120, 1.5, 20)
		p1.Color = Color3.fromRGB(0, 200, 255)
		p1.Material = Enum.Material.SmoothPlastic
		p1.CFrame = CFrame.new(center + Vector3.new(0, 10, 0))

		local p2 = Instance.new("Part", Effects)
		p2.Name = "M1Platform"
		p2.Anchored = true
		p2.Size = Vector3.new(120, 1.5, 20)
		p2.Color = Color3.fromRGB(0, 200, 255)
		p2.Material = Enum.Material.SmoothPlastic
		p2.CFrame = CFrame.new(center + Vector3.new(0, 20, 0))

		-- Helper for smooth, foolproof one-way collision check without head-bumps
		local function makePlatformPhasable(p)
			setupOneWayPlatformBehavior(p, function()
				return _G.Phase2PlatformActive
			end, false)
		end

		makePlatformPhasable(p1)
		makePlatformPhasable(p2)

		-- Spawn big-sized Gaster Blasters randomly on platform corners or the ground itself to make them unusable
		-- Attack lasts x4 longer (60 seconds)
		task.spawn(function()
			local duration = 60
			local startTime = tick()
			
			local platformList = {p1, p2, "Ground"}
			
			while tick() - startTime < duration and _G.Phase2PlatformActive do
				if _G.CancelAttackTrigger then break end
				
				-- Pick a random platform or the ground
				local selected = platformList[math.random(1, #platformList)]
				local blasterSize = 3.5
				
				if selected == "Ground" then
					-- PERFECT STRAIGHT LINE ALIGNED WITH GROUND (parallel to platforms) - SPAWN 3 BLASTERS
					local halfX = p1.Size.X / 2
					local cornerX = math.random() > 0.5 and halfX or -halfX
					
					local cCF1 = p1.CFrame * CFrame.new(cornerX, 4, -5)
					local tCF1 = p1.CFrame * CFrame.new(-cornerX, 4, -5)
					local cCF2 = p1.CFrame * CFrame.new(-cornerX, 4, 5)
					local tCF2 = p1.CFrame * CFrame.new(cornerX, 4, 5)
					local cCF3 = p1.CFrame * CFrame.new(cornerX, 4, 0)
					local tCF3 = p1.CFrame * CFrame.new(-cornerX, 4, 0)
					
					-- Override Y to match floor/ground height (center.Y + 4)
					local spawnCF1 = Vector3.new(cCF1.X, center.Y + 4, cCF1.Z)
					local targetCF1 = Vector3.new(tCF1.X, center.Y + 4, tCF1.Z)
					local spawnCF2 = Vector3.new(cCF2.X, center.Y + 4, cCF2.Z)
					local targetCF2 = Vector3.new(tCF2.X, center.Y + 4, tCF2.Z)
					local spawnCF3 = Vector3.new(cCF3.X, center.Y + 4, cCF3.Z)
					local targetCF3 = Vector3.new(tCF3.X, center.Y + 4, tCF3.Z)
					
					SummonModernBlaster(spawnCF1 + Vector3.new(0, 15, 0), spawnCF1, targetCF1, blasterSize)
					SummonModernBlaster(spawnCF2 + Vector3.new(0, 15, 0), spawnCF2, targetCF2, blasterSize)
					SummonModernBlaster(spawnCF3 + Vector3.new(0, 15, 0), spawnCF3, targetCF3, blasterSize)
				else
					-- PERFECT STRAIGHT LINE ALIGNED WITH PLATFORM - SPAWN 3 BLASTERS (Z=-5, Z=0, Z=5) TO COVER THE ENTIRE WIDTH
					local halfX = selected.Size.X / 2
					local cornerX = math.random() > 0.5 and halfX or -halfX
					local spawnCF1 = selected.CFrame * CFrame.new(cornerX, 4, -5)
					local targetCF1 = selected.CFrame * CFrame.new(-cornerX, 4, -5)
					local spawnCF2 = selected.CFrame * CFrame.new(-cornerX, 4, 5)
					local targetCF2 = selected.CFrame * CFrame.new(cornerX, 4, 5)
					local spawnCF3 = selected.CFrame * CFrame.new(cornerX, 4, 0)
					local targetCF3 = selected.CFrame * CFrame.new(-cornerX, 4, 0)
					
					SummonModernBlaster(spawnCF1.Position + Vector3.new(0, 15, 0), spawnCF1.Position, targetCF1.Position, blasterSize)
					SummonModernBlaster(spawnCF2.Position + Vector3.new(0, 15, 0), spawnCF2.Position, targetCF2.Position, blasterSize)
					SummonModernBlaster(spawnCF3.Position + Vector3.new(0, 15, 0), spawnCF3.Position, targetCF3.Position, blasterSize)
				end
				
				task.wait(2.2)
			end
			
			_G.Phase2PlatformActive = false
			p1:Destroy()
			p2:Destroy()
			for _, w in pairs(walls) do w:Destroy() end
			removeJumpBuff()
		end)
	end
end

_G.FirstAttackUsed = false

function Attack_FirstCinematic()
	if attack then return end
	attack = true
	currentAnim = "Idling"

	-- Auto-cancel immediately if no player is nearby before anything fires
	if not GetClosestTarget(mouse.Hit.p, 100) then
		attack = false
		return
	end

	local Y_OFFSET = 0

	-- Initial Target Setup
	local targetHum = GetClosestTarget(mouse.Hit.p, 100)
	local center = targetHum and targetHum.Parent.PrimaryPart.Position or mouse.Hit.p
	local ray = Ray.new(center + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0))
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local floorY = floorPos and floorPos.Y or (center.Y - 10)

	center = Vector3.new(center.X, floorY + Y_OFFSET, center.Z)
	_G.CurrentArenaCenter = center

	-- Arena Build
	local boxGroup = Instance.new("Model", Effects)
	local function makeGroundLine(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide = true, false
		w.Color, w.Material = Color3.new(1, 1, 1), Enum.Material.Neon
		w.Size, w.CFrame = wSize, cframe
	end
	local function makeWall(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide, w.Transparency = true, true, 1
		w.CanQuery = false
		w.Size, w.CFrame = wSize, cframe
	end

	local s, h, t = 60, 50, 0.5 
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))

	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))

	if targetHum and targetHum.Parent:FindFirstChild("HumanoidRootPart") then
		targetHum.Parent.HumanoidRootPart.CFrame = CFrame.new(center + Vector3.new(0,3,0))
	end

	local hl = Instance.new("Highlight", Character)
	hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
	CreateSound("12222170", Head, 5, 0.6)
	task.wait(0.15)
	rootPart.CFrame = CFrame.lookAt(center + Vector3.new(0, 3, 45), center)
	CreateSound("12222170", Head, 5, 0.65)
	task.wait(0.15)
	hl:Destroy()

	Humanoid.WalkSpeed = 0
	if not isPhase2 then
		themeMoos:Stop()
	end

	if not _G.FirstAttackUsed then
		Expression.Texture = "rbxassetid://4484446057"
		chatfunc("* it's a beautiful day outside.") task.wait(3)
		chatfunc("* birds are singing, flowers are blooming...") task.wait(4)
		chatfunc("* on days like these, kids like you...") task.wait(3)
		Expression.Texture = "rbxassetid://4484436948"
		chatfunc("* Should be burning in hell.") task.wait(2)
		if not isPhase2 then
			themeMoos:Play()
		end
		-- FIX: Immediately check if any player is still inside the box after the speech.
		-- If nobody is here, cancel Phase 1 before it even starts.
		if not GetClosestTarget(center, 70) then
			chatfunc("* huh. guess not.")
			task.wait(2)
			Humanoid.WalkSpeed = 16
			boxGroup:Destroy()
			attack = false
			return
		end
	else
		Expression.Texture = "rbxassetid://4484407199"
		chatfunc("* let's get to the point.") task.wait(2)
		if not isPhase2 then
			themeMoos:Play()
		end
		-- Also cancel if nobody is in the box on repeated runs
		if not GetClosestTarget(center, 70) then
			chatfunc("* huh. guess not.")
			task.wait(2)
			Humanoid.WalkSpeed = 16
			boxGroup:Destroy()
			attack = false
			return
		end
	end
	_G.FirstAttackUsed = true

	-- Helper: pick a live target inside the arena (returns Humanoid or nil)
	local function pickTarget()
		return GetClosestTarget(center, 70)
	end

	-- Helper: aim position (player feet) inside the arena
	local function getAimPos()
		local t = pickTarget()
		if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
			return t.Parent.HumanoidRootPart.Position - Vector3.new(0, 1.5, 0)
		end
		return center
	end

	-- Helper: aim position at the player's body (slightly above feet) for blasters that should hit them directly
	local function getBodyAimPos()
		local t = pickTarget()
		if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
			return t.Parent.HumanoidRootPart.Position
		end
		return center + Vector3.new(0, 3, 0)
	end

	-- =============================================================================
	-- 🌟 PHASE 1 (15s): Two big corner blasters + nerfed circle blasters + bone rise
	-- =============================================================================
	local phase1Active = true

	-- 🌟 RECENT REQUEST: Spawn a sweeping blue bone wall during Phase 1!
	-- Sweeps from Front to Back starting at 2 seconds, lasting 4 seconds.
	-- Sweeps from Back to Front starting at 8 seconds, lasting 4 seconds.
	task.delay(2, function()
		if phase1Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 4.0)
		end
	end)
	task.delay(8, function()
		if phase1Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Back", 4.0)
		end
	end)

	-- Two BIG persistent blasters in the left and right corners (closest to "south", facing the arena)
	-- They fire repeatedly until phase1Active is false. Size 3 = "big" (uses the long 2.0s beam path).
	-- The corner blasters are STATIONARY, sit OUTSIDE the arena box on the GROUND, and
	-- fire in a STRAIGHT LINE along their edge (NOT diagonally). They don't track the player.
	-- Each one is positioned just past the arena edge so its beam slices straight across
	-- the south or north strip of the arena, "cutting out" that band of safe ground.
	local function CornerBigBlasterLoop(spawnOffset, fixedAimOffset)
		local hoverPos = center + spawnOffset
		local spawnPos = hoverPos + Vector3.new(0, 10, 0)
		local fixedAim = center + fixedAimOffset
		task.spawn(function()
			while phase1Active do
				if _G.CancelAttackTrigger then break end
				SummonModernBlaster(spawnPos, hoverPos, fixedAim, 3) -- size 3 = big
				-- Beam lasts ~2s, plus 0.4s charge + 0.3s fade. Fire continuously, slight gap so they reset.
				task.wait(2.6)
			end
		end)
	end
	-- South-Left blaster sits OUTSIDE the west wall, on the ground, and fires straight east
	-- along the south strip of the arena. North-Right blaster sits OUTSIDE the east wall,
	-- on the ground, and fires straight west along the north strip. Both beams are perfectly
	-- horizontal and parallel to the X axis, just at opposite ends of the arena.
	-- Spawn X is pushed past the wall (-32 / +32) and aim X is past the OPPOSITE wall so the
	-- beam travels the full width of the arena. Y is at ground level (1.5).
	CornerBigBlasterLoop(Vector3.new(-32, 1.5,  22), Vector3.new( 32, 1.5,  22)) -- south-left → straight east
	CornerBigBlasterLoop(Vector3.new( 32, 1.5, -22), Vector3.new(-32, 1.5, -22)) -- north-right → straight west

	-- Moving blasters on the ground
	task.spawn(function()
		local count = 0
		while phase1Active do
			if _G.CancelAttackTrigger then break end
			count = count + 1
			local spawnHeight = 1.2
			local blSize = 0.7
			if count % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end
			task.wait(1.0)
		end
	end)

	-- Nerfed circle blasters (same idea as the fake-final attack, but slower fire / smaller / inside the arena)
	task.spawn(function()
		local CIRCLE_RADIUS = 18
		local BLASTER_HEIGHT_OFFSET = 1.0
		local BLASTER_AIM_HEIGHT = 1.5
		local BLASTER_SPAWN_DEPTH = -10
		local BLASTER_ANGLE_STEP = 30        -- bigger step than the original 25 = fewer blasters per rev
		local BLASTER_FIRE_RATE = 0.35       -- slower than the 0.15 of the fake-final = nerfed
		local angle = 0
		local lockedFloorY = center.Y

		while phase1Active do
			if _G.CancelAttackTrigger then break end
			local aimTarget = pickTarget()
			local tCenter = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or center
			tCenter = Vector3.new(tCenter.X, lockedFloorY, tCenter.Z)

			angle = angle + BLASTER_ANGLE_STEP
			local radAng = math.rad(angle)
			local hoverPos = tCenter + Vector3.new(math.cos(radAng)*CIRCLE_RADIUS, BLASTER_HEIGHT_OFFSET, math.sin(radAng)*CIRCLE_RADIUS)
			local spawnPos = hoverPos + Vector3.new(0, BLASTER_SPAWN_DEPTH, 0)
			SummonModernBlaster(spawnPos, hoverPos, tCenter + Vector3.new(0, BLASTER_AIM_HEIGHT, 0), 1.1) -- smaller than the 1.3 of the fake-final = nerfed
			
			-- 🌟 RECENT REQUEST: Dynamically spawn blue bones in cinematic attack!
			if math.random() > 0.65 then
				local boneSpawnPos = tCenter + Vector3.new(math.random(-15, 15), 25, math.random(-15, 15))
				SummonModernBone(CFrame.new(boneSpawnPos) * CFrame.Angles(math.rad(-90),0,0), Vector3.new(0.015, 0.015, 0.015), true, 4, 1.8, nil, nil, true)
			end
			
			task.wait(BLASTER_FIRE_RATE)
		end
	end)

	-- Phase 1 lasts 15 seconds, then everything in it is told to stop.
	task.wait(15)
	phase1Active = false

	-- Brief beat to let beams clear before phase 2
	task.wait(1.0)

	-- Live-target check between phases
	if not pickTarget() then
		chatfunc("* looks like we're done here.")
		task.wait(2)
		Humanoid.WalkSpeed = 16
		if not isPhase2 then
			themeMoos:Play()
		end
		boxGroup:Destroy()
		attack = false
		return
	end

	-- =============================================================================
	-- 🌟 PHASE 2 (15s): Rotating cross of 4 blasters + stalker bone + tracking miniblaster
	-- =============================================================================
	local phase2Active = true

	-- The 4 cross blasters orbit around the arena center. They start at N/S/E/W (the "+" cross
	-- shape requested) and don't rotate yet — they just persistently fire.
	-- Pattern: 2 on the south & north (z axis) and 2 on the left & right (x axis), exactly as requested.
	local crossAngle = 0          -- shared angle offset; bumped later to make the cross spin
	local crossRotating = false   -- flips to true after the cross starts rotating

	-- The cross of 4 blasters sits OUTSIDE the arena box, on the GROUND, in a "+" shape.
	-- Each blaster fires straight across the arena to the opposite side so the beam covers
	-- the maximum possible range. They use the SAME smooth continuous-beam logic as the
	-- 2 Homing Blasters (SummonOrbitingBlasters): one charge phase, then a single continuous
	-- beam that updates every frame for the entire phase — NOT re-summoned every 1.4s.
	-- The aim is FIXED across the arena (no player tracking). Once crossRotating flips on,
	-- crossAngle increments per frame and orbits the whole "+" rigidly around the center.
	local CROSS_RING = 32  -- distance from center where blasters sit (outside the 25-radius box)
	local CROSS_GROUND_Y = 1.5
	local CROSS_SIZE = 1.5
	local CROSS_BEAM_LEN = 300

	local function SpawnPersistentCrossBlaster(baseAngleDeg)
		task.spawn(function()
			-- ---- Build the blaster head ----
			local GB = Instance.new("Part", Effects)
			GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
			GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
			local sm = Instance.new("SpecialMesh", GB)
			sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

			local Charge = Instance.new("Sound", GB)
			Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
			Charge:Play()
			TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(CROSS_SIZE, CROSS_SIZE, CROSS_SIZE)}):Play()

			-- Helper: resolve current spawn + aim from baseAngleDeg + crossAngle
			local function resolve()
				local angDeg = baseAngleDeg + crossAngle
				local rad = math.rad(angDeg)
				local hp  = center + Vector3.new( math.cos(rad) * CROSS_RING, CROSS_GROUND_Y,  math.sin(rad) * CROSS_RING)
				local aim = center + Vector3.new(-math.cos(rad) * CROSS_RING, CROSS_GROUND_Y, -math.sin(rad) * CROSS_RING)
				return hp, aim
			end

			-- ---- Charge phase ----
			local chargeTime = 1.0
			local startCharge = tick()
			while tick() - startCharge < chargeTime do
				if _G.CancelAttackTrigger or not phase2Active then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, CROSS_SIZE * 1.25, 0)
				task.wait(0.03)
			end

			if not phase2Active or _G.CancelAttackTrigger then GB:Destroy() return end

			-- ---- Fire ----
			sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
			sm.MeshId = "rbxassetid://2649610132"

			local Fire = Instance.new("Sound", GB)
			Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
			Fire:Play()

			local mag = CROSS_BEAM_LEN
			local beamOffsetY = -CROSS_SIZE * 1.25

			local beam = Instance.new("Part", Effects)
			beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
			beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)

			local hitbox = Instance.new("Part", Effects)
			hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
			hitbox.Size = Vector3.new(CROSS_SIZE * 2.5, CROSS_SIZE * 2.5, mag)

			TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, CROSS_SIZE * 2.5, CROSS_SIZE * 2.5)}):Play()

			-- Damage loop (same pattern as SummonOrbitingBlasters)
			local beamActive = true
			task.spawn(function()
				local hitCache = {}
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while beamActive do
					for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
						local hum = p.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
								hitCache[hum] = tick()
								local mult = (_G.FinalCinematicBlasterMult or 1.0)
								_G.ApplyKarmaHit(hum, 1.5 * mult)
							end
						end
					end
					task.wait(0.05)
				end
			end)

			-- Continuous fire loop — updates every frame for buttery rotation
			while phase2Active do
				if _G.CancelAttackTrigger then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, CROSS_SIZE * 1.25, 0)
				beam.CFrame   = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
				hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
				task.wait()
			end

			-- Tear down
			beamActive = false
			TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
			TS:Create(GB,   TweenInfo.new(0.3), {Transparency = 1}):Play()
			task.wait(0.3)
			beam:Destroy() hitbox:Destroy() GB:Destroy()
		end)
	end
	-- South (+Z), North (-Z), Right (+X), Left (-X) → angles 90, 270, 0, 180
	SpawnPersistentCrossBlaster(90)
	SpawnPersistentCrossBlaster(270)
	SpawnPersistentCrossBlaster(0)
	SpawnPersistentCrossBlaster(180)

	-- Moving blasters on the ground
	task.spawn(function()
		local count = 0
		while phase2Active do
			if _G.CancelAttackTrigger then break end
			count = count + 1
			local spawnHeight = 1.2
			local blSize = 0.7
			if count % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end
			task.wait(1.0)
		end
	end)

	-- Small blaster spawns above the player every 0.75 seconds (2x faster than before), facing them.
	task.spawn(function()
		while phase2Active do
			if _G.CancelAttackTrigger then break end
			local t = pickTarget()
			if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
				local pPos = t.Parent.HumanoidRootPart.Position
				local hoverPos = pPos + Vector3.new(0, 12, 0)   -- "above the player"
				local spawnPos = hoverPos + Vector3.new(0, 8, 0)
				SummonModernBlaster(spawnPos, hoverPos, getBodyAimPos(), 0.9) -- small
			end
			task.wait(0.75)
		end
	end)

	-- After 1s the cross starts rotating (so almost the entire phase has the spinning "+").
	task.delay(1, function()
		crossRotating = true
		task.spawn(function()
			while phase2Active do
				if _G.CancelAttackTrigger then break end
				crossAngle = (crossAngle + 2) % 360 -- 2° per tick = smooth rotation
				task.wait(0.05)
			end
		end)
	end)

	-- Phase 2 lasts 15s total
	task.wait(15)
	phase2Active = false

	task.wait(1.0)

	-- =============================================================================
	-- 🌟 ENDING: Platform Traps Variant 2 ("moving platforms")
	-- =============================================================================
	-- The original variant 2 lives inside Attack_BoneZone(true). It randomly picks between
	-- the giant-bone variant and the moving-platform variant, so we force the moving one.
	-- Tear down the cinematic arena first so it doesn't overlap the platform arena.
	Humanoid.WalkSpeed = 16
	if not isPhase2 then
		themeMoos:Play()
	end
	boxGroup:Destroy()

	_G.ForceBoneZoneVariant = "platform"
	-- Briefly release `attack` so Attack_BoneZone can take over cleanly.
	attack = false
	Attack_BoneZone(true)
	_G.ForceBoneZoneVariant = nil
	return
end

function Grab()
	grabbing = true
	local hit = mouse.Target
	if not hit or not hit.Parent or hit.Parent == Character then grabbing = false return end

	local targetHRP = hit.Parent:FindFirstChild("HumanoidRootPart") or hit.Parent:FindFirstChild("Torso")
	local targetHum = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not targetHRP or not targetHum or targetHum.Health <= 0 then grabbing = false return end

	if (targetHRP.Position - rootPart.Position).Magnitude > 60 then grabbing = false return end

	local S = Instance.new("Sound", targetHRP)
	S.SoundId, S.Volume = "rbxassetid://548991605", 5
	S:Play()

	local GUI = Instance.new("BillboardGui", targetHRP)
	GUI.Size, GUI.AlwaysOnTop = UDim2.new(2.5,0,2.5,0), true
	local Body = Instance.new("ImageLabel", GUI)
	Body.Image, Body.BackgroundTransparency, Body.Size = "rbxassetid://338425795", 1, UDim2.new(1,0,1,0)

	coroutine.wrap(function()
		repeat
			Expression.Texture = "rbxassetid://4484422735" task.wait()
			Expression.Texture = "rbxassetid://4484448817"
		until not grabbing and not attack
	end)()

	-- Smooth dragging logic setup
	local bp = Instance.new("BodyPosition", targetHRP)
	bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bp.D, bp.P = 600, 4000 

	local maxGrabRadius = 40

	while grabbing and targetHRP.Parent and targetHum.Health > 0 do
		-- If Z is pressed during the drag, switch to the brutal animation slam!
		if _G.isSlamKeyHeld then
			grabbing = false 
			if bp then bp:Destroy() end

			-- 🌟 ANIMATED SLAM SEQUENCE 🌟
			targetHRP.Anchored = true 
			attack = true
			Animations = true

			local baseCF = targetHRP.CFrame

			-- 🌟 GROUND SMASH REWORK (Variants 1 & 2) 🌟
			local ray = Ray.new(baseCF.p, Vector3.new(0, -200, 0))
			local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, {Character, hit.Parent, Effects})
			local center = CFrame.new(floorPos)

			local walls = {}
			local function createWall(cframe, size)
				local wall = Instance.new("Part", Effects)
				wall.Anchored, wall.CanCollide = true, true
				wall.CanQuery = false
				wall.Size = size
				wall.CFrame = cframe
				wall.Transparency = 1 

				-- 6 Large Bone Visuals (Performance King Replaces "Trillion" logic)
				local isSideWall = (size.X < size.Z)

				for i = 1, 6 do
					local vbone = Instance.new("Part", Effects)
					vbone.Anchored, vbone.CanCollide = true, false
					vbone.Size = Vector3.new(1.8, size.Y, 1.8) -- Slightly thicker for "Bones" look
					vbone.Material = Enum.Material.SmoothPlastic
					vbone.Color = Color3.new(1, 1, 1)

					local vm = Instance.new("SpecialMesh", vbone)
					vm.MeshType, vm.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633"
					vm.Scale = Vector3.new(0.06, size.Y * 0.0035, 0.06) -- Better bone scaling

					if not isSideWall then
						local x = (i - 3.5) * (size.X / 5)
						vbone.CFrame = cframe * CFrame.new(x, 0, 0)
					else
						local z = (i - 3.5) * (size.Z / 5)
						vbone.CFrame = cframe * CFrame.new(0, 0, z)
					end
					table.insert(walls, vbone)
				end

				table.insert(walls, wall)
				return wall
			end

			-- Spawn 3 bone walls (North, Left, Right) - Adjusted to 50 Length and Aligned correctly
			local wallDist = 25
			local wallThick = 3
			createWall(center * CFrame.new(0, 7.5, -(wallDist + wallThick/2)), Vector3.new(50 + wallThick * 2, 15, wallThick)) -- North
			createWall(center * CFrame.new(-(wallDist + wallThick/2), 7.5, 0), Vector3.new(wallThick, 15, 50)) -- Left
			createWall(center * CFrame.new((wallDist + wallThick/2), 7.5, 0), Vector3.new(wallThick, 15, 50)) -- Right

			-- 🌟 INVISIBLE SAFETY BARRIERS 🌟
			-- During Variant 2 (gravity flip), the player walks on bone walls. Without these,
			-- they could walk off the top edge or out the open south side and fall into the void.
			-- These are completely invisible AND non-visual: just collision boxes that close the box.
			local function createBarrier(cframe, size)
				local b = Instance.new("Part", Effects)
				b.Anchored = true
				b.CanCollide = true
				b.Transparency = 1
				b.Size = size
				b.CFrame = cframe
				b.Material = Enum.Material.SmoothPlastic
				b.Name = "ArenaBarrier"
				b.CastShadow = false
				table.insert(walls, b)
				return b
			end

			-- Ceiling: caps the arena at Y=15 so the player can't fly/fall off the top of the bone walls
			-- when gravity is sideways (the "up" while on a side wall is now horizontal, so the
			-- ceiling acts as the far wall on that axis).
			createBarrier(center * CFrame.new(0, 15 + wallThick/2, 0), Vector3.new(50 + wallThick * 2, wallThick, 50 + wallThick * 2))

			-- South wall: closes the open 4th side of the arena. Without this, on the Left/Right
			-- walls the player could walk in the +Z direction right off the edge into the void.
			createBarrier(center * CFrame.new(0, 7.5, (wallDist + wallThick/2)), Vector3.new(50 + wallThick * 2, 15, wallThick))

			-- Floor cap: extends the safe ground area so the player can't fall through gaps
			-- around the original floorPos when wall-walking near the edges.
			createBarrier(center * CFrame.new(0, -wallThick/2, 0), Vector3.new(50 + wallThick * 2, wallThick, 50 + wallThick * 2))

			local variant = 1
			if isCtrlHeld then
				variant = 2
			end

			if variant == 1 then
				-- VARIANT 1: Brutal Rapid Slam Sequence (8 Seconds, 3 Smashes/Sec)
				local smashDuration = 8
				local smashesPerSec = 3
				local totalSmashes = smashDuration * smashesPerSec
				local damagePerSmash = 50 / totalSmashes

				_G.EyesOff = false
				_G.EyeUpdateDelay = 0.05
				Expression.Texture = "rbxassetid://4484448817"

				for smash = 1, totalSmashes do
					if not targetHRP.Parent or targetHum.Health <= 0 then break end

					-- 🌟 ELEVATION PHASE: Lifts victim up 9 studs before next slam
					local elevateCF = center * CFrame.new(0, 9, 0)
					TS:Create(targetHRP, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = elevateCF}):Play()

					-- 🌟 REFINED ARM MOVEMENT: Centered and stable to prevent detachment
					task.spawn(function()
						RA_Weld.C0 = RA_Weld.C0:Lerp(c_new(1.4, 0.5, -0.6) * c_angles(math.rad(120), math.rad(math.random(-8,8)), math.rad(-8)), 0.5)
						Torso_Weld.C0 = Torso_Weld.C0:Lerp(c_new(0, -1, 0) * c_angles(math.rad(5), 0, 0), 0.3)
						swait(2)
					end)
					task.wait(0.12)

					local currentWall = math.random(1, 4) 
					local targetSlamCF

					-- Adjusting position values based on 25 length Arena
					local surfPos = wallDist -- Inner edge is at wallDist
					local pOffset = 2.5 -- Distance from RootPart to feet

					if currentWall == 1 then
						targetSlamCF = center * CFrame.new(0, 1.5, 0)
					elseif currentWall == 2 then -- North
						targetSlamCF = center * CFrame.new(0, 7.5, -(surfPos - pOffset)) * CFrame.Angles(math.rad(90), 0, 0)
					elseif currentWall == 3 then -- Left
						targetSlamCF = center * CFrame.new(-(surfPos - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(-90))
					elseif currentWall == 4 then -- Right
						targetSlamCF = center * CFrame.new((surfPos - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(90))
					end

					-- Teleport Target for instantaneous smash look
					TS:Create(targetHRP, TweenInfo.new(0.08, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = targetSlamCF}):Play()

					-- 🌟 STABLE SWINGS
					task.spawn(function()
						for i=1, 3 do
							local rx, ry, rz = math.random(-15, 15), math.random(-5, 5), math.random(-10, 10)
							RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.5, -0.6) * c_angles(math.rad(rx), math.rad(ry), math.rad(rz)), 0.6)
							Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.05, 0) * c_angles(math.rad(math.random(-3,3)), math.rad(math.random(-3,3)), 0), 0.6)
							swait()
						end
					end)

					-- Impact
					targetHum.Health = targetHum.Health - damagePerSmash
					local slamSnd = Instance.new("Sound", targetHRP)
					slamSnd.SoundId, slamSnd.Volume = "rbxassetid://131238474", 2.5
					slamSnd:Play()
					game.Debris:AddItem(slamSnd, 1)

					task.wait(math.max(0.05, (1 / smashesPerSec) - 0.12)) -- Correct for elevation time
				end

				task.wait(1)
			else
				-- VARIANT 2: Gravity Flip Cycle (North -> Left -> Right -> Ground)
				-- FIX: do NOT use PlatformStand here. PlatformStand disables the victim's controls,
				-- which is why they looked stuck/frozen during this variant.
				targetHRP.Anchored = false

				-- Save everything we touch so the victim never gets permanently stuck if the attack ends.
				local savedWalkSpeed = targetHum.WalkSpeed
				local savedJumpPower = targetHum.JumpPower
				local savedAutoRotate = targetHum.AutoRotate
				local savedPlatformStand = targetHum.PlatformStand
				local savedUseJumpPower = targetHum.UseJumpPower
				local savedJumpHeight = targetHum.JumpHeight

				targetHum.PlatformStand = false -- IMPORTANT: keep player controls alive
				targetHum.AutoRotate = false    -- Stop Roblox from fighting the wall orientation
				targetHum.WalkSpeed = math.max(savedWalkSpeed, 16)
				-- Keep jump enabled. The custom wall-jump code below uses the victim's Jump input.
				pcall(function() targetHum.UseJumpPower = true end)
				targetHum.JumpPower = math.max(savedJumpPower, 50)
				pcall(function() targetHum.JumpHeight = math.max(savedJumpHeight, 7.2) end)
				pcall(function()
					targetHum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
				end)

				-- Destroy the grab-phase heart GUI so it does not stack/twitch with the soul GUI below
				if GUI then GUI:Destroy() end

				-- Decorative blue soul visual
				local soulGui = Instance.new("BillboardGui", targetHRP)
				soulGui.Name = "DecorativeSoul"
				soulGui.Size = UDim2.new(1.8, 0, 1.8, 0)
				soulGui.AlwaysOnTop = true
				local soulImg = Instance.new("ImageLabel", soulGui)
				soulImg.Size = UDim2.new(1, 0, 1, 0)
				soulImg.BackgroundTransparency = 1
				soulImg.Image = "rbxassetid://338425795"

				local surfPos = wallDist
				local pOffset = 2.5
				local standingPos = surfPos - pOffset
				local realGravity = workspace.Gravity

				local function getTargetMass()
					local totalMass = 0
					for _, p in ipairs(hit.Parent:GetDescendants()) do
						if p:IsA("BasePart") and not p.Massless then
							totalMass = totalMass + p:GetMass()
						end
					end
					return math.max(totalMass, 1)
				end

				-- BodyForce handles fake gravity. BodyGyro handles wall rotation.
				-- BodyVelocity gives the victim manual movement while sideways, because normal
				-- Humanoid walking does not behave reliably on vertical surfaces.
				local gravForce = Instance.new("BodyForce", targetHRP)
				gravForce.Name = "WallGravityForce"
				gravForce.Force = Vector3.new(0, 0, 0)

				local gravGyro = Instance.new("BodyGyro", targetHRP)
				gravGyro.Name = "WallGravityGyro"
				gravGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
				gravGyro.P = 1e5
				gravGyro.D = 500
				gravGyro.CFrame = targetHRP.CFrame

				local wallVelocity = Instance.new("BodyVelocity", targetHRP)
				wallVelocity.Name = "WallControlVelocity"
				wallVelocity.MaxForce = Vector3.new(0, 0, 0)
				wallVelocity.P = 6000
				wallVelocity.Velocity = Vector3.new(0, 0, 0)

				-- Manual walk animation for the victim. BodyVelocity movement does not reliably fire
				-- Roblox's normal Running animation event, so without this the victim looks stiff.
				local walkAnim = Instance.new("Animation")
				if targetHum.RigType == Enum.HumanoidRigType.R15 then
					walkAnim.AnimationId = "rbxassetid://507777826" -- default R15 walk
				else
					walkAnim.AnimationId = "rbxassetid://180426354" -- default R6 walk
				end
				local wallWalkTrack
				pcall(function()
					wallWalkTrack = targetHum:LoadAnimation(walkAnim)
					wallWalkTrack.Looped = true
					wallWalkTrack.Priority = Enum.AnimationPriority.Movement
				end)

				local function getWallNormal(currentWall)
					if currentWall == 2 then
						return Vector3.new(0, 0, -1)
					elseif currentWall == 3 then
						return Vector3.new(-1, 0, 0)
					elseif currentWall == 4 then
						return Vector3.new(1, 0, 0)
					else
						return Vector3.new(0, 1, 0)
					end
				end

				local function getWallMaxForce(currentWall)
					-- Only control the axes along the surface. Do NOT force the fake-gravity axis,
					-- otherwise jump impulses get erased every frame.
					if currentWall == 2 then
						return Vector3.new(1e5, 1e5, 0) -- north wall: move X/Y, jump on Z
					elseif currentWall == 3 or currentWall == 4 then
						return Vector3.new(0, 1e5, 1e5) -- side walls: move Y/Z, jump on X
					else
						return Vector3.new(0, 0, 0)
					end
				end

				local function getWallMoveVelocity(currentWall)
					local move = targetHum.MoveDirection
					if move.Magnitude < 0.05 then
						return Vector3.new(0, 0, 0)
					end

					local desired
					if currentWall == 1 then
						desired = Vector3.new(move.X, 0, move.Z)
					else
						-- Arrow-key users often produce a MoveDirection that is already relative to the
						-- rotated character/camera. Projecting onto the wall plane keeps that input alive.
						local normal = getWallNormal(currentWall)
						local projected = move - normal * move:Dot(normal)

						-- WASD/camera-forward input can point into the wall, which would project to zero.
						-- This fallback converts normal ground input into wall X/Y/Z movement.
						local remapped
						if currentWall == 2 then
							-- North wall spec: W=down, S=up, A=right, D=left
							-- move.Z: W produces +Z (forward) → map to -Y (down). S produces -Z → +Y (up).
							-- move.X: A produces -X (left input) → map to +X (right feel). D produces +X → -X (left feel).
							remapped = Vector3.new(-move.X, -move.Z, 0)
						elseif currentWall == 3 then
							-- Left wall spec: W/S same as normal (Z feel), A=right, D=left (A/D inverted in Z)
							-- W/S → Y (vertical on wall surface = normal gravity feel), A/D → Z inverted
							remapped = Vector3.new(0, move.Z, -move.X)
						elseif currentWall == 4 then
							-- Right wall: same as left wall
							remapped = Vector3.new(0, move.Z, -move.X)
						end

						if projected.Magnitude > remapped.Magnitude then
							desired = projected
						else
							desired = remapped
						end
					end

					if desired.Magnitude < 0.05 then
						return Vector3.new(0, 0, 0)
					end
					return desired.Unit * targetHum.WalkSpeed
				end

				local function updateWallWalkAnimation(moveVel)
					if not wallWalkTrack then return end
					if moveVel.Magnitude > 1 then
						if not wallWalkTrack.IsPlaying then
							pcall(function() wallWalkTrack:Play(0.12, 1, 1) end)
						end
						pcall(function() wallWalkTrack:AdjustSpeed(math.clamp(moveVel.Magnitude / 16, 0.6, 1.7)) end)
					else
						if wallWalkTrack.IsPlaying then
							pcall(function() wallWalkTrack:Stop(0.15) end)
						end
					end
				end

				local lastWallJump = 0
				local function isCloseToSurface(currentWall)
					local pos = targetHRP.Position
					if currentWall == 2 then
						return pos.Z <= center.Position.Z - standingPos + 2.2
					elseif currentWall == 3 then
						return pos.X <= center.Position.X - standingPos + 2.2
					elseif currentWall == 4 then
						return pos.X >= center.Position.X + standingPos - 2.2
					else
						return targetHum.FloorMaterial ~= Enum.Material.Air
					end
				end

				local function tryWallJump(currentWall)
					if not targetHum.Jump then return end
					if tick() - lastWallJump < 0.35 then return end
					if not isCloseToSurface(currentWall) then return end

					lastWallJump = tick()
					targetHum.Jump = false
					local jumpPower = math.max(targetHum.JumpPower, savedJumpPower, 50)
					local fakeUp
					if currentWall == 1 then
						fakeUp = Vector3.new(0, 1, 0)
					else
						fakeUp = -getWallNormal(currentWall)
					end
					targetHRP.AssemblyLinearVelocity = targetHRP.AssemblyLinearVelocity + fakeUp * jumpPower
					pcall(function() targetHum:ChangeState(Enum.HumanoidStateType.Jumping) end)
				end

				local function controlledWait(duration, currentWall, gyroTarget)
					local finish = tick() + duration
					while tick() < finish do
						if not targetHRP.Parent or targetHum.Health <= 0 then break end
						local moveVel = getWallMoveVelocity(currentWall)
						wallVelocity.Velocity = moveVel
						updateWallWalkAnimation(moveVel)
						tryWallJump(currentWall)
						if gyroTarget then gravGyro.CFrame = gyroTarget end
						pcall(function()
							targetHum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
						end)
						task.wait()
					end
				end

				-- Cycle through all walls so gravity change is seen from all sides
				local wallCycle = {2, 3, 4, 1}

				for _, currentWall in ipairs(wallCycle) do
					if not targetHRP.Parent or targetHum.Health <= 0 then break end

					local totalMass = getTargetMass()
					local rot
					local gyroTarget

					if currentWall == 1 then -- Ground / normal gravity
						local pos = (center * CFrame.new(0, 2.5, 0)).p
						rot = CFrame.new(pos)
						gyroTarget = rot -- FIX: was nil before, which could error and skip cleanup
						gravForce.Force = Vector3.new(0, 0, 0)
						wallVelocity.MaxForce = Vector3.new(0, 0, 0) -- let Humanoid walk normally on ground

					elseif currentWall == 2 then -- North wall, fake gravity pulls -Z
						local pos = (center * CFrame.new(0, 7.5, -standingPos)).p
						rot = CFrame.fromMatrix(pos, Vector3.new(1, 0, 0), Vector3.new(0, 0, 1))
						gyroTarget = rot
						gravForce.Force = Vector3.new(0, totalMass * realGravity, -totalMass * realGravity)
						wallVelocity.MaxForce = getWallMaxForce(currentWall)

					elseif currentWall == 3 then -- Left wall, fake gravity pulls -X
						local pos = (center * CFrame.new(-standingPos, 7.5, 0)).p
						rot = CFrame.fromMatrix(pos, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0))
						gyroTarget = rot
						gravForce.Force = Vector3.new(-totalMass * realGravity, totalMass * realGravity, 0)
						wallVelocity.MaxForce = getWallMaxForce(currentWall)

					elseif currentWall == 4 then -- Right wall, fake gravity pulls +X
						local pos = (center * CFrame.new(standingPos, 7.5, 0)).p
						rot = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0))
						gyroTarget = rot
						gravForce.Force = Vector3.new(totalMass * realGravity, totalMass * realGravity, 0)
						wallVelocity.MaxForce = getWallMaxForce(currentWall)
					end

					gravGyro.CFrame = gyroTarget
					targetHRP.CFrame = rot
					targetHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					wallVelocity.Velocity = Vector3.new(0, 0, 0)

					local slamSnd = Instance.new("Sound", targetHRP)
					slamSnd.SoundId, slamSnd.Volume = "rbxassetid://131238474", 2.5
					slamSnd:Play()
					game.Debris:AddItem(slamSnd, 1)

					-- 5 Targeted Bone Rises per wall (Total 20)
					for i = 1, 5 do
						if not targetHRP.Parent or targetHum.Health <= 0 then break end

						local boneCF
						local pPos = targetHRP.Position

						if currentWall == 1 then
							boneCF = CFrame.new(pPos.X, center.Position.Y, pPos.Z)
						elseif currentWall == 2 then
							boneCF = CFrame.new(pPos.X, pPos.Y, center.Position.Z - surfPos) * CFrame.Angles(math.rad(90), 0, 0)
						elseif currentWall == 3 then
							boneCF = CFrame.new(center.Position.X - surfPos, pPos.Y, pPos.Z) * CFrame.Angles(0, 0, math.rad(-90))
						elseif currentWall == 4 then
							boneCF = CFrame.new(center.Position.X + surfPos, pPos.Y, pPos.Z) * CFrame.Angles(0, 0, math.rad(90))
						end

						WarnAndRise(boneCF, 0, 7, 7, "Rise", 0.2, false)
						controlledWait(2.0, currentWall, gyroTarget)
						controlledWait(1.0, currentWall, gyroTarget)
					end
					controlledWait(0.3, currentWall, gyroTarget)
				end

				-- Cleanup gravity movers, soul GUI, animation, and restore victim fully
				if wallWalkTrack then pcall(function() wallWalkTrack:Stop(0.1) wallWalkTrack:Destroy() end) end
				if walkAnim then walkAnim:Destroy() end
				if wallVelocity and wallVelocity.Parent then wallVelocity:Destroy() end
				if gravForce and gravForce.Parent then gravForce:Destroy() end
				if gravGyro and gravGyro.Parent then gravGyro:Destroy() end
				if soulGui and soulGui.Parent then soulGui:Destroy() end
				task.wait(1)
				targetHum.WalkSpeed = savedWalkSpeed
				targetHum.JumpPower = savedJumpPower
				pcall(function() targetHum.UseJumpPower = savedUseJumpPower end)
				pcall(function() targetHum.JumpHeight = savedJumpHeight end)
				targetHum.AutoRotate = savedAutoRotate
				targetHum.PlatformStand = savedPlatformStand
				targetHRP.Anchored = false
			end
			for _, w in pairs(walls) do w:Destroy() end

			targetHRP.Anchored = false
			Animations = false
			attack = false
			break
		end

		-- NORMAL DRAG LOGIC (No Slam)
		local targetPos = mouse.Hit.p 
		local offset = targetPos - rootPart.Position
		if offset.Magnitude > maxGrabRadius then
			targetPos = rootPart.Position + (offset.Unit * maxGrabRadius)
		end

		if bp then bp.Position = targetPos end
		swait()
	end

	Expression.Texture = "rbxassetid://4484405390"
	if bp then bp:Destroy() end
	if GUI then GUI:Destroy() end
	_G.isSlamKeyHeld = false -- Safety reset when done
end

function Attack_GBSingle(isAir)
	Pointing()
	local isPhase2 = (Death == true or Death2 == true)
	local size = 1.5
	local isOmega = false

	if isPhase2 and isCtrlHeld then
		size = 7.0
		isOmega = true
	elseif isAir then
		size = 3.5
	end

	-- Special auto-homing targeting sequence when Sans is stationed on his standing platform
	if _G.SansOnPlatform then
		local closestHum = GetClosestTarget(rootPart.Position, 500)
		if closestHum and closestHum.Parent and closestHum.Parent:FindFirstChild("HumanoidRootPart") then
			local tRoot = closestHum.Parent.HumanoidRootPart
			local tPos = tRoot.Position
			-- Spawn 10 studs to the left or right of the player (sides)
			local sideOffset = (math.random() > 0.5 and 1 or -1) * 10
			local rightVec = tRoot.CFrame.RightVector
			local hoverPos = tPos + (rightVec * sideOffset) + Vector3.new(0, 8, 0)
			local spawnPos = hoverPos + Vector3.new(0, 15, 0)
			SummonModernBlaster(spawnPos, hoverPos, tPos, size, isOmega)
		end
		return
	end

	local spawnPos = rootPart.Position + Vector3.new(math.random(-10,10), 10, math.random(-10,10))
	local hoverPos = rootPart.Position + Vector3.new(0, size * 4, 0)
	SummonModernBlaster(spawnPos, hoverPos, mouse.Hit.p, size, isOmega)
end

local function SummonActiveHomingBlaster(size)
	task.spawn(function()
		local GB = Instance.new("Part", Effects)
		GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
		GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
		GB.CFrame = rootPart.CFrame * CFrame.new(math.random(-15,15), 25, math.random(-15,15))

		local sm = Instance.new("SpecialMesh", GB)
		sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

		local Charge = Instance.new("Sound", GB)
		Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
		Charge:Play()

		TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()

		local currentHoverPos = GB.Position
		local chargeTime = 1.5
		local startTime = tick()
		while tick() - startTime < chargeTime do
			local tPos = mouse.Hit.p
			local aimTarget = GetClosestTarget(currentHoverPos, 200)
			if aimTarget and aimTarget.Parent and aimTarget.Parent:FindFirstChild("HumanoidRootPart") then
				tPos = aimTarget.Parent.HumanoidRootPart.Position
			end
			currentHoverPos = currentHoverPos:Lerp(tPos + Vector3.new(0, size*3.5, 0), 0.15)
			local aimCF = CFrame.lookAt(currentHoverPos, tPos)
			GB.CFrame = aimCF * CFrame.new(0, size * 1.25, 0)
			task.wait(0.03)
		end

		sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
		sm.MeshId = "rbxassetid://2649610132"

		local Fire = Instance.new("Sound", GB)
		Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
		Fire:Play()

		local mag = 300
		local beamOffsetY = -size * 1.25
		local beam = Instance.new("Part", Effects)
		beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
		beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)
		beam.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)

		local hitbox = Instance.new("Part", Effects)
		hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
		hitbox.Size, hitbox.CFrame = Vector3.new(size*2.5, size*2.5, mag), GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)

		TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, size*2.5, size*2.5)}):Play()

		local beamActive = true
		task.spawn(function()
			local hitCache = {}
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while beamActive do
				for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
							hitCache[hum] = tick()
							_G.ApplyKarmaHit(hum, 1.5)
						end
					end
				end
				task.wait(0.1)
			end
		end)

		local fireTime = 2.0
		local fireStart = tick()
		while tick() - fireStart < fireTime do
			local tPos = mouse.Hit.p
			local aimTarget = GetClosestTarget(currentHoverPos, 200)
			if aimTarget and aimTarget.Parent and aimTarget.Parent:FindFirstChild("HumanoidRootPart") then
				tPos = aimTarget.Parent.HumanoidRootPart.Position
			end
			-- SLOWDOWN DURING FIRING: original 0.15, now 0.04 to make it dodgable
			currentHoverPos = currentHoverPos:Lerp(tPos + Vector3.new(0, size*3.5, 0), 0.04)
			local aimCF = CFrame.lookAt(currentHoverPos, tPos)
			GB.CFrame = aimCF * CFrame.new(0, size * 1.25, 0)

			beam.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
			hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)

			task.wait(0.03)
		end
		beamActive = false

		TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
		TS:Create(GB, TweenInfo.new(0.3), {Transparency = 1}):Play()
		task.wait(0.3)
		beam:Destroy() hitbox:Destroy() GB:Destroy()
	end)
end

function Attack_BoneZone(useVariant)
	-- FIX: Advanced Ground Detection (Ignores all Characters to find the actual floor)
	local mousePos = mouse.Hit.p
	local ignoreList = {Character, Effects}

	-- Populate ignore list with all characters in the workspace
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end

	-- Cast a long ray from high up down to the floor
	local ray = Ray.new(mousePos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local center = floorPos -- This is now guaranteed to be the ground level

	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if isPhase2 then
		Pointing()
		
		local startPos = (rootPart.CFrame * CFrame.new(0, -2.5, -5)).p
		local dir = (center - startPos).Unit
		local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
		local rotY = math.atan2(-flatDir.Z, flatDir.X) + math.rad(90)
		
		local function rotateVectorY(v, angleRad)
			local cosA = math.cos(angleRad)
			local sinA = math.sin(angleRad)
			return Vector3.new(v.X * cosA - v.Z * sinA, 0, v.X * sinA + v.Z * cosA).Unit
		end

		if isCtrlHeld then
			-- Omni-directional bone walls (8 directions)
			task.spawn(function()
				local directions = 8
				for wave = 1, 8 do
					if _G.CancelAttackTrigger then break end
					for d = 1, directions do
						local angle = math.rad((d - 1) * (360 / directions))
						local waveDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
						local waveRot = math.atan2(-waveDir.Z, waveDir.X) + math.rad(90)
						local wavePos = center + (waveDir * (wave * 6))
						WarnAndRise(wavePos, waveRot, 20, 5, "Wave")
					end
					task.wait(0.18)
				end
			end)
		elseif useVariant then
			-- 5 bone walls (M1 variant): center, 2 left fanning, 2 right fanning
			task.spawn(function()
				for wave = 1, 8 do
					if _G.CancelAttackTrigger then break end
					-- Center Pos
					local centerPos = startPos + (flatDir * (wave * 6))
					WarnAndRise(centerPos, rotY, 35, 5, "Wave")

					-- Left 1 (rotated -15 deg)
					local dirL1 = rotateVectorY(flatDir, math.rad(-15))
					local posL1 = startPos + (dirL1 * (wave * 6))
					WarnAndRise(posL1, rotY - math.rad(15), 35, 5, "Wave")

					-- Left 2 (rotated -30 deg)
					local dirL2 = rotateVectorY(flatDir, math.rad(-30))
					local posL2 = startPos + (dirL2 * (wave * 6))
					WarnAndRise(posL2, rotY - math.rad(30), 35, 5, "Wave")

					-- Right 1 (rotated 15 deg)
					local dirR1 = rotateVectorY(flatDir, math.rad(15))
					local posR1 = startPos + (dirR1 * (wave * 6))
					WarnAndRise(posR1, rotY + math.rad(15), 35, 5, "Wave")

					-- Right 2 (rotated 30 deg)
					local dirR2 = rotateVectorY(flatDir, math.rad(30))
					local posR2 = startPos + (dirR2 * (wave * 6))
					WarnAndRise(posR2, rotY + math.rad(30), 35, 5, "Wave")

					task.wait(0.15)
				end
			end)
		else
			-- 3 bone walls (Normal variant): center, 2 fanning sides
			task.spawn(function()
				for wave = 1, 8 do
					if _G.CancelAttackTrigger then break end
					-- Center Pos
					local centerPos = startPos + (flatDir * (wave * 6))
					WarnAndRise(centerPos, rotY, 40, 5, "Wave")

					-- Left Side (rotated -20 deg)
					local dirL = rotateVectorY(flatDir, math.rad(-20))
					local posL = startPos + (dirL * (wave * 6))
					WarnAndRise(posL, rotY - math.rad(20), 40, 5, "Wave")

					-- Right Side (rotated 20 deg)
					local dirR = rotateVectorY(flatDir, math.rad(20))
					local posR = startPos + (dirR * (wave * 6))
					WarnAndRise(posR, rotY + math.rad(20), 40, 5, "Wave")

					task.wait(0.15)
				end
			end)
		end
		return
	end

	if useVariant then
		-- Allow other attacks (e.g. Attack_FirstCinematic) to force a specific sub-variant
		-- by setting _G.ForceBoneZoneVariant to "giant" or "platform" before calling.
		local _forced = _G.ForceBoneZoneVariant
		local _pickGiant = true
		if _forced == "giant" then
			_pickGiant = true
		elseif _forced == "platform" then
			_pickGiant = false
		else
			_pickGiant = true
		end
		if _pickGiant then
			-- 💀 DIABOLICAL GIANT BONE VARIANT (3x BIGGER) 💀
			-- Auto-cancel: if no players are nearby, skip entirely
			if not GetClosestTarget(center, 200) then
				attack = false
				return
			end

			local redWarn = Instance.new("Part", Effects)
			redWarn.Anchored, redWarn.CanCollide, redWarn.Material, redWarn.Color = true, false, Enum.Material.Neon, Color3.new(1,0,0)
			redWarn.Size = Vector3.new(150, 0.2, 150)
			redWarn.CFrame = CFrame.new(center) -- Spawned at feet

			-- ✨ NEW: Create Invisible Walls to trap players inside the red zone
			local walls = {}
			local wallHeight = 150
			local zoneSize = 150
			local wt = 5 -- wall thickness
			local wallOffsets = {
				{size = Vector3.new(zoneSize + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, zoneSize/2)},
				{size = Vector3.new(zoneSize + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, -zoneSize/2)},
				{size = Vector3.new(wt, wallHeight, zoneSize + wt*2), offset = Vector3.new(zoneSize/2, wallHeight/2, 0)},
				{size = Vector3.new(wt, wallHeight, zoneSize + wt*2), offset = Vector3.new(-zoneSize/2, wallHeight/2, 0)},
			}

			for _, wData in pairs(wallOffsets) do
				local wall = Instance.new("Part", Effects)
				wall.Anchored = true
				wall.CanCollide = true -- IMPORTANT: Physical barrier so players can't escape!
				wall.CanQuery = false
				wall.Transparency = 1 -- Invisible
				wall.Size = wData.size
				wall.CFrame = CFrame.new(center + wData.offset)
				table.insert(walls, wall)
			end

			local whiteWarns = {}
			local platOffsets = {Vector3.new(60, 0.1, 60), Vector3.new(-60, 0.1, 60), Vector3.new(60, 0.1, -60), Vector3.new(-60, 0.1, -60)}
			for _, off in pairs(platOffsets) do
				local w = Instance.new("Part", Effects)
				w.Anchored, w.CanCollide, w.Material, w.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
				w.Size = Vector3.new(20, 0.3, 20)
				w.CFrame = CFrame.new(center + off)
				table.insert(whiteWarns, w)
			end

			task.wait(5)

			-- Cancel check: if nobody is around after the 5s warning, clean up and bail
			if _G.CancelAttackTrigger or not GetClosestTarget(center, 200) then
				for _, w in pairs(walls) do w:Destroy() end
				redWarn:Destroy()
				attack = false
				return
			end

			local plats = {}
			for _, w in pairs(whiteWarns) do
				local p = Instance.new("Part", Effects)
				p.Name = "ObbyPlatform"
				p.Anchored = false -- physical unanchored lift prevents players clipping through
				p.CanCollide = true
				p.Material = Enum.Material.SmoothPlastic
				p.Color = Color3.fromRGB(0, 200, 255)
				p.Size = Vector3.new(20, 1.5, 20)
				p.CFrame = w.CFrame

				local bg = Instance.new("BodyGyro", p)
				bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bg.D, bg.P = 1000, 50000
				bg.CFrame = p.CFrame

				local bp = Instance.new("BodyPosition", p)
				bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bp.D, bp.P = 2000, 40000
				bp.Position = p.Position

				table.insert(plats, p)
				w:Destroy()

				-- Animate the BodyPosition to push physical bodies up cleanly without clip
				task.spawn(function()
					local targetPos = p.Position + Vector3.new(0, 35, 0)
					local duration = 1.5
					local steps = 30
					for i = 1, steps do
						local t = i / steps
						local ease = t * (2 - t)
						bp.Position = p.Position:Lerp(targetPos, ease)
						task.wait(duration / steps)
					end
					bp.Position = targetPos
					p.Anchored = true -- rigidly lock in place once fully ascended
					bp:Destroy()
					bg:Destroy()
				end)
			end

			task.wait(2)

			-- Final cancel check before the bone actually rises
			if _G.CancelAttackTrigger then
				for _, w in pairs(walls) do w:Destroy() end
				for _, p in pairs(plats) do p:Destroy() end
				redWarn:Destroy()
				attack = false
				return
			end

			-- Anchor Sans to prevent him from being uplifted by the giant bone
			local originalAnchored = rootPart.Anchored
			rootPart.Anchored = true

			local giantBone = Instance.new("Part", Effects)
			giantBone.Name = "GiantRisingBonePlatform"
			giantBone.CollisionGroup = "BoneGroup"
			giantBone.Anchored, giantBone.CanCollide, giantBone.Color = true, true, Color3.new(1,1,1)
			giantBone.Size = Vector3.new(144, 30, 144)
			giantBone.CFrame = CFrame.new(center + Vector3.new(0, -35, 0))
			local sm = Instance.new("SpecialMesh", giantBone)
			sm.MeshType, sm.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633"
			sm.Scale = Vector3.new(144*0.015, 30*0.01, 144*0.015)

			local sound = Instance.new("Sound", giantBone) sound.SoundId, sound.Volume = "rbxassetid://306247749", 8 sound:Play()

			TS:Create(giantBone, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(center + Vector3.new(0, 15, 0))}):Play()

			local active = true
			task.spawn(function()
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while active and giantBone.Parent do
					for _, hit in ipairs(workspace:GetPartsInPart(giantBone, params)) do
						local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							local giantDamage = 3
							if Death == true or Death2 == true then
								giantDamage = giantDamage * 2
							end
							hum.Health = hum.Health - giantDamage
							_G.ApplyKarmaHit(hum)
						end
					end
					task.wait(0.1)
				end
			end)

			task.wait(4)
			active = false
			TS:Create(giantBone, TweenInfo.new(1), {CFrame = CFrame.new(center + Vector3.new(0, -35, 0))}):Play()
			redWarn:Destroy()

			-- ✨ NEW: Destroy the invisible walls so the map is clear again
			for _, w in pairs(walls) do w:Destroy() end

			for _, p in pairs(plats) do TS:Create(p, TweenInfo.new(1), {Transparency = 1}):Play() end
			task.wait(1)
			giantBone:Destroy()
			for _, p in pairs(plats) do p:Destroy() end
			rootPart.Anchored = originalAnchored
		else
			-- ✨ NEW: 3D Platform Sliding Attack (Moving Obby)
			-- Auto-cancel immediately if no player is nearby
			if not GetClosestTarget(center, 200) then
				attack = false
				return
			end
			local zoneX = 160
			local zoneZ = 65
			local seaActive = true
			local walls = {}
			local wt = 5
			local wallHeight = 100

			local wallOffsets = {
				{size = Vector3.new(zoneX + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, zoneZ/2 + 2.5)},
				{size = Vector3.new(zoneX + wt*2, wallHeight, wt), offset = Vector3.new(0, wallHeight/2, -zoneZ/2 - 2.5)},
				{size = Vector3.new(wt, wallHeight, zoneZ + wt*2 + 5), offset = Vector3.new(zoneX/2, wallHeight/2, 0)},
				{size = Vector3.new(wt, wallHeight, zoneZ + wt*2 + 5), offset = Vector3.new(-zoneX/2, wallHeight/2, 0)},
				{size = Vector3.new(zoneX + wt*2, wt, zoneZ + wt*2 + 5), offset = Vector3.new(0, wallHeight, 0)} -- Roof!
			}

			for _, wData in pairs(wallOffsets) do
				local wall = Instance.new("Part", Effects)
				wall.Anchored, wall.CanCollide, wall.Transparency = true, true, 1
				wall.CanQuery = false
				wall.Size, wall.CFrame = wData.size, CFrame.new(center + wData.offset)
				table.insert(walls, wall)
			end

			-- Red Warning on Floor
			local redWarn = Instance.new("Part", Effects)
			redWarn.Anchored, redWarn.CanCollide, redWarn.Material, redWarn.Color = true, false, Enum.Material.Neon, Color3.new(1,0,0)
			redWarn.Size = Vector3.new(zoneX, 0.2, zoneZ + 8)
			redWarn.CFrame = CFrame.new(center)

			-- Helper for smooth, foolproof one-way collision check without head-bumps or global locks
			local function makePlatformPhasable(p)
				setupOneWayPlatformBehavior(p, function()
					return seaActive
				end, false)
			end

			-- Initial platform for the player to jump on!
			local startPlat = Instance.new("Part", Effects)
			startPlat.Name = "StartPlatform" -- Named correctly so raycasts detect it!
			startPlat.Anchored, startPlat.CanCollide, startPlat.Material, startPlat.Color = true, false, Enum.Material.SmoothPlastic, Color3.fromRGB(0, 200, 255)
			startPlat.Size = Vector3.new(20, 1.5, 20)
			-- Move starting platform to the edge
			local startXOffset = zoneX/2 - 10
			startPlat.CFrame = CFrame.new(center + Vector3.new(startXOffset, 0.1, 0))

			makePlatformPhasable(startPlat)

			task.wait(1.5)

			local riseY = 28
			TS:Create(startPlat, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = CFrame.new(center + Vector3.new(startXOffset, riseY, 0))}):Play()

			-- 🌟 SANS' CONTROLLED PLATFORM 🌟
			local sansPlat = Instance.new("Part", Effects)
			sansPlat.Name = "SansPlatform"
			sansPlat.Anchored = true
			sansPlat.CanCollide = true
			sansPlat.Size = Vector3.new(16, 1.5, 16)
			sansPlat.Material = Enum.Material.SmoothPlastic
			sansPlat.Color = Color3.fromRGB(0, 162, 255)

			local sansBox = Instance.new("SelectionBox", sansPlat)
			sansBox.Adornee = sansPlat
			sansBox.Color3 = Color3.fromRGB(0, 255, 255)
			sansBox.LineThickness = 0.05

			local currentPlatX = 0
			local currentPlatZ = zoneZ/2 + 15
			local sansPlatTargetPos = center + Vector3.new(currentPlatX, riseY, currentPlatZ)
			sansPlat.CFrame = CFrame.new(sansPlatTargetPos)

			_G.SansOnPlatform = true
			local originalWalkSpeed = Humanoid.WalkSpeed
			local originalJumpPower = Humanoid.JumpPower
			Humanoid.WalkSpeed = 0
			Humanoid.JumpPower = 0

			-- Anchor Sans' RootPart, physically disabling all input physics and preventing walk animation stutter/snapping
			rootPart.Anchored = true
			do
				local _aimP = mouse.Hit.p
				local _sansPos = sansPlatTargetPos + Vector3.new(0, 3, 0)
				local _flatAim = Vector3.new(_aimP.X, _sansPos.Y, _aimP.Z)
				if (_flatAim - _sansPos).Magnitude < 0.1 then
					_flatAim = _sansPos + Vector3.new(0, 0, -1)
				end
				rootPart.CFrame = CFrame.lookAt(_sansPos, _flatAim)
			end

			task.spawn(function()
				local connection
				connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
					if not seaActive or not sansPlat or not sansPlat.Parent or not rootPart or rootPart.Parent == nil then
						if connection then connection:Disconnect() end
						return
					end

					local moveSpeed = 80 -- Studs per second (perfectly responsive & smooth)
					local deltaX = 0
					local deltaZ = 0

					if heldKeys["w"] or heldKeys["up"] then
						deltaX = -moveSpeed * dt
					elseif heldKeys["s"] or heldKeys["down"] then
						deltaX = moveSpeed * dt
					end

					if heldKeys["a"] or heldKeys["left"] then
						deltaZ = -moveSpeed * dt
					elseif heldKeys["d"] or heldKeys["right"] then
						deltaZ = moveSpeed * dt
					end

					currentPlatX = math.clamp(currentPlatX + deltaX, -zoneX/2, zoneX/2)
					currentPlatZ = math.clamp(currentPlatZ + deltaZ, zoneZ/2 + 10, zoneZ/2 + 40)

					sansPlatTargetPos = center + Vector3.new(currentPlatX, riseY, currentPlatZ)
					sansPlat.CFrame = CFrame.new(sansPlatTargetPos)

					-- Lock Sans firmly in place on his custom platform, facing where he's aiming
					local _sansPos = sansPlatTargetPos + Vector3.new(0, 3, 0)
					local _aimP = mouse.Hit.p
					local _flatAim = Vector3.new(_aimP.X, _sansPos.Y, _aimP.Z)
					if (_flatAim - _sansPos).Magnitude < 0.1 then
						_flatAim = _sansPos + Vector3.new(0, 0, -1)
					end
					rootPart.CFrame = CFrame.lookAt(_sansPos, _flatAim)
					rootPart.Velocity = Vector3.new(0, 0, 0)
					rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end)

				-- Yield thread until the platform phase attack is fully ended
				while seaActive do
					task.wait(0.1)
				end

				if connection then connection:Disconnect() end

				_G.SansOnPlatform = false
				pcall(function()
					rootPart.Anchored = false
					Humanoid.WalkSpeed = originalWalkSpeed
					Humanoid.JumpPower = originalJumpPower
					if sansPlat then sansPlat:Destroy() end
				end)
				-- Teleport Sans back to the ground level coordinate safely
				pcall(function()
					rootPart.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))
				end)
			end)

			task.wait(1.0) -- Wait for the platform to fully arrive before teleporting anyone onto it

			-- Teleport ALL nearby players (not Sans) safely onto the start platform.
			-- We anchor them briefly so they don't get flung by residual physics velocity.
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local plrChar = plr.Character
				if plrChar and plrChar ~= Character then -- exclude Sans
					local plrHRP = plrChar:FindFirstChild("HumanoidRootPart")
					if plrHRP then
						local dist = (plrHRP.Position - center).Magnitude
						if dist < 150 then
							-- Zero velocity first to prevent fling, then place on platform
							plrHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							plrHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
							plrHRP.CFrame = CFrame.new(center + Vector3.new(startXOffset, riseY + 3, 0))
						end
					end
				end
			end

			task.delay(2.2, function()
				local startP = center + Vector3.new(startXOffset, riseY, 0)
				local endP = center + Vector3.new(-zoneX/2 - 20, riseY, 0)
				local duration = math.abs(endP.X - startP.X) / 15.0
				local vel = (endP - startP) / duration
				startPlat.Velocity = vel
				startPlat.AssemblyLinearVelocity = vel
				local slideTween = TS:Create(startPlat, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endP)})
				slideTween:Play()
				slideTween.Completed:Connect(function()
					startPlat:Destroy()
				end)

				-- Spawn Stalker Bone
				local tHum = GetClosestTarget(center, 150)
				if tHum and tHum.Parent and tHum.Parent:FindFirstChild("HumanoidRootPart") then
					local tRoot = tHum.Parent.HumanoidRootPart
					local spawnOffset = CFrame.Angles(0, math.rad(math.random(0,360)), 0).LookVector * 30
					local spawnPos = tRoot.Position + spawnOffset + Vector3.new(0, 10, 0)
					SummonModernBone(CFrame.new(spawnPos) * CFrame.Angles(math.rad(-90), 0, 0), Vector3.new(0.07, 0.07, 0.07), true, 15, 0.7, nil, 1/3) -- REDUCED 3x
				end
			end)

			-- Spawn Sea of Bones at bottom
			local seaBone = Instance.new("Part", Effects)
			seaBone.Anchored, seaBone.CanCollide, seaBone.Color = true, false, Color3.new(1,1,1)
			seaBone.Size = Vector3.new(zoneX, 12, zoneZ)
			-- Lower the sea bones to prevent touching platforms
			seaBone.CFrame = CFrame.new(center + Vector3.new(0, -12, 0))
			local smSea = Instance.new("SpecialMesh", seaBone)
			smSea.MeshType, smSea.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633"
			smSea.Scale = Vector3.new(zoneX*0.015, 12*0.01, zoneZ*0.015)

			TS:Create(seaBone, TweenInfo.new(1), {CFrame = CFrame.new(center + Vector3.new(0, -2, 0))}):Play()
			redWarn:Destroy()

			seaActive = true
			task.spawn(function()
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while seaActive and seaBone.Parent do
					for _, hit in ipairs(workspace:GetPartsInPart(seaBone, params)) do
						local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							_G.ApplyKarmaHit(hum, 1/3) -- REDUCED 3x
						end
					end
					task.wait(0.05)
				end
			end)

			-- 🌟 NEW: Jump Boost Mechanic for fallen players
			local jumpBuffs = {}
			task.spawn(function()
				while seaActive do
					for _, p in ipairs(game.Players:GetPlayers()) do
						local char = p.Character
						if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
							local hum = char.Humanoid
							local hrp = char.HumanoidRootPart

							-- Check if player is inside the horizontal bounds of the attack zone
							local relativePos = center - hrp.Position
							if math.abs(relativePos.X) < zoneX/2 + 20 and math.abs(relativePos.Z) < zoneZ/2 + 20 then
								local distToFloor = hrp.Position.Y - center.Y
								-- If they fall below the lowest platform level (around 8-28)
								if distToFloor < 15 and distToFloor > -10 then
									if not jumpBuffs[hum] then
										-- Store original jump power and buff them
										jumpBuffs[hum] = hum.JumpPower
										hum.UseJumpPower = true
										hum.JumpPower = 150 -- Massive leap to get back up
									end
								elseif distToFloor >= 22 then
									-- If they are back at a safe height, restore original power
									if jumpBuffs[hum] then
										hum.JumpPower = jumpBuffs[hum]
										jumpBuffs[hum] = nil
									end
								end
							end
						end
					end
					task.wait(0.1)
				end
				-- Clean up when attack ends
				for hum, oldJP in pairs(jumpBuffs) do
					if hum and hum.Parent then hum.JumpPower = oldJP end
				end
			end)

			local platforms = {startPlat}

			local function SpawnObbyPlatform(startPos, endPos, hasBoneObstacle, hasBoneRiseWarning)
				local p = Instance.new("Part", Effects)
				p.Name = "ObbyPlatform" -- Named correctly so raycasts detect it!
				p.Anchored, p.CanCollide, p.Material, p.Color = true, false, Enum.Material.SmoothPlastic, Color3.fromRGB(0, 200, 255)
				p.Size = Vector3.new(16, 1.5, 16)
				p.CFrame = CFrame.new(startPos)
				table.insert(platforms, p)

				makePlatformPhasable(p)

				local duration = math.abs(endPos.X - startPos.X) / 15.0
				local vel = (endPos - startPos) / duration
				p.Velocity = vel
				p.AssemblyLinearVelocity = vel
				TS:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endPos)}):Play()

				if hasBoneObstacle then
					task.spawn(function()
						local obType = math.random(1, 3)
						local bones = {}
						if obType == 1 then
							-- Precise jump (Blocky horizontal hurdle bone hovering/resting at center)
							local bone = Instance.new("Part", p)
							bone.Anchored, bone.CanCollide = false, false
							bone.Size = Vector3.new(16, 4, 4)
							bone.CFrame = p.CFrame * CFrame.new(0, 2.75, 0)
							bone.Color = Color3.new(1,1,1)
							local weld = Instance.new("Weld", bone) weld.Part0 = p weld.Part1 = bone weld.C0 = CFrame.new(0, 2.75, 0)
							local m = Instance.new("SpecialMesh", bone) m.MeshType, m.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633" m.Scale = Vector3.new(0.16, 4/300, 0.04)
							table.insert(bones, bone)
						elseif obType == 2 then
							-- Center blocky bone (Makes player walk around edges)
							local bone = Instance.new("Part", p)
							bone.Anchored, bone.CanCollide = false, false
							bone.Size = Vector3.new(8, 12, 8)
							bone.CFrame = p.CFrame * CFrame.new(0, 6.75, 0)
							bone.Color = Color3.new(1,1,1)
							local weld = Instance.new("Weld", bone) weld.Part0 = p weld.Part1 = bone weld.C0 = CFrame.new(0, 6.75, 0)
							local m = Instance.new("SpecialMesh", bone) m.MeshType, m.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633" m.Scale = Vector3.new(0.08, 12/300, 0.08)
							table.insert(bones, bone)
						else
							-- Mini bones at edges (Forces player to walk in the center)
							for _, xOff in pairs({-6.5, 6.5}) do
								local bone = Instance.new("Part", p)
								bone.Anchored, bone.CanCollide = false, false
								bone.Size = Vector3.new(4, 10, 16)
								bone.CFrame = p.CFrame * CFrame.new(xOff, 5.75, 0)
								bone.Color = Color3.new(1,1,1)
								local weld = Instance.new("Weld", bone) weld.Part0 = p weld.Part1 = bone weld.C0 = CFrame.new(xOff, 5.75, 0)
								local m = Instance.new("SpecialMesh", bone) m.MeshType, m.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633" m.Scale = Vector3.new(0.04, 10/300, 0.16)
								table.insert(bones, bone)
							end
						end

						local bAct = true
						task.spawn(function()
							local hitCache = {}
							local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
							while bAct and p and p.Parent do
								for _, bone in ipairs(bones) do
									if bone and bone.Parent then
										for _, hit in ipairs(workspace:GetPartsInPart(bone, params)) do
											local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
											if hum and hum.Parent ~= Character then
												if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
													hitCache[hum] = tick()
													_G.ApplyKarmaHit(hum, 1/3) -- REDUCED 3x
												end
											end
										end
									end
								end
								task.wait(0.05)
							end
						end)
						task.wait(duration)
						bAct = false
						for _, bone in ipairs(bones) do if bone then bone:Destroy() end end
					end)
				elseif hasBoneRiseWarning then
					task.spawn(function()
						local trapAct = true
						local warned = false
						local isRising = false
						local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
						while trapAct and p and p.Parent do
							local playerOnIt = false
							local hits = workspace:GetPartBoundsInBox(p.CFrame * CFrame.new(0, 2, 0), Vector3.new(15, 6, 15), params)
							for _, hit in ipairs(hits) do
								local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 and hum.Parent ~= Character then
									playerOnIt = true
									break
								end
							end

							if playerOnIt and not isRising then
								warned = true
								isRising = true
								task.spawn(function()
									local red = Instance.new("Part", Effects)
									red.Anchored, red.CanCollide, red.Color = false, false, Color3.new(1,0,0)
									red.Material = Enum.Material.Neon
									red.Size = Vector3.new(14, 0.2, 14)
									red.CFrame = p.CFrame * CFrame.new(0, 0.86, 0)
									local w1 = Instance.new("Weld", red) w1.Part0 = p w1.Part1 = red w1.C0 = CFrame.new(0, 0.86, 0)

									local s = Instance.new("Sound", red)
									s.SoundId = "rbxassetid://446961725"
									s.Volume = 5 s:Play()

									task.wait(1.5) -- Wait before popping up
									if red then red:Destroy() end

									if p and p.Parent then
										local trapBone = Instance.new("Part", Effects)
										trapBone.Anchored, trapBone.CanCollide = false, false
										-- Fill the full 16x16 platform so no corner is safe
										trapBone.Size = Vector3.new(16, 25, 16)
										trapBone.CFrame = p.CFrame * CFrame.new(0, -12, 0)
										trapBone.Color = Color3.new(1,1,1)
										local w2 = Instance.new("Weld", trapBone) w2.Part0 = p w2.Part1 = trapBone w2.C0 = CFrame.new(0, -12, 0)
										local bm = Instance.new("SpecialMesh", trapBone) bm.MeshType, bm.MeshId = Enum.MeshType.FileMesh, "http://www.roblox.com/asset/?id=921085633" bm.Scale = Vector3.new(0.16, 25/300, 0.16)

										local bs = Instance.new("Sound", p)
										bs.SoundId = "rbxassetid://306247749"
										bs.Volume = 6 bs:Play()

										TS:Create(w2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = CFrame.new(0, 12, 0)}):Play()

										local tbAct = true
										task.spawn(function()
											local hitCache = {}
											local paramsb = OverlapParams.new() paramsb.FilterDescendantsInstances = {Character, Effects}
											while tbAct and trapBone and trapBone.Parent do
												for _, hit in ipairs(workspace:GetPartsInPart(trapBone, paramsb)) do
													local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
													if hum and hum.Parent ~= Character then
														if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
															hitCache[hum] = tick()
															_G.ApplyKarmaHit(hum, 0.5) -- Buffed from 1/3 (0.33) to 0.5 (representing +50%)
														end
													end
												end
												task.wait(0.1)
											end
										end)
										task.wait(2)
										tbAct = false
										TS:Create(w2, TweenInfo.new(1), {C0 = CFrame.new(0, -12, 0)}):Play()
										task.wait(1)
										if trapBone then trapBone:Destroy() end
										isRising = false
									end
								end)
							end
							task.wait(0.1)
						end
					end)
				end

				task.spawn(function()
					task.wait(duration)
					if p then p:Destroy() end
				end)
			end

			-- Fire blasters 2x faster — target the MOST SECURE player (highest Y above sea level, i.e. safest on platforms)
			task.spawn(function()
				while seaActive do
					if _G.CancelAttackTrigger then break end
					local aimPos = mouse.Hit.p

					-- Find the player that is highest up (most secure on a platform), not the closest
					local bestHum, bestY = nil, -math.huge
					for _, p in ipairs(game.Players:GetPlayers()) do
						local char = p.Character
						if char and char ~= Character then
							local hrp = char:FindFirstChild("HumanoidRootPart")
							local hum = char:FindFirstChildOfClass("Humanoid")
							if hrp and hum and hum.Health > 0 then
								local dist = (hrp.Position - center).Magnitude
								if dist < 200 and hrp.Position.Y > bestY then
									bestY = hrp.Position.Y
									bestHum = hum
								end
							end
						end
					end

					if bestHum and bestHum.Parent and bestHum.Parent:FindFirstChild("HumanoidRootPart") then
						aimPos = bestHum.Parent.HumanoidRootPart.Position - Vector3.new(0, 1.5, 0)
					end

					local bZ = (math.random() > 0.5) and (zoneZ/2 + 20) or (-zoneZ/2 - 20)
					local bSpawn = center + Vector3.new(math.random(-25, 25), riseY + math.random(5, 15), bZ)
					SummonModernBlaster(bSpawn + Vector3.new(0,10,0), bSpawn, aimPos, 1.2)
					task.wait(1.0)
				end
			end)

			-- Fire platforms!
			task.wait(2.2)
			local lastZ = 0
			local lastY = riseY
			local nextWait = 0
			for i = 1, 24 do
				if _G.CancelAttackTrigger then break end
				-- FIX: Auto-cancel if no players remain in the arena
				if not GetClosestTarget(center, 200) then
					seaActive = false
					break
				end
				task.wait(nextWait)

				local targetDist = math.random(260, 290) / 10.0

				-- Restrict Z jump distance so the diagonal jump is always exactly 'targetDist'
				local maxDeltaZ = math.sqrt((targetDist^2) - (16^2))

				-- Clamp within arena bounds
				local minZ = math.max(-zoneZ/2 + 8, lastZ - maxDeltaZ)
				local maxZ = math.min(zoneZ/2 - 8, lastZ + maxDeltaZ)

				local newZ = math.random(math.floor(minZ * 10), math.floor(maxZ * 10)) / 10.0
				local deltaZ = math.abs(newZ - lastZ)

				local deltaX2 = (targetDist^2) - (deltaZ^2)
				local deltaX = 16 
				if deltaX2 > 0 then
					deltaX = math.sqrt(deltaX2)
				end

				nextWait = deltaX / 15.0

				local yDir = math.random(50, 100) / 10.0
				if math.random() > 0.5 then
					yDir = -yDir
				end

				local newY = lastY + yDir
				-- newY is a Y-OFFSET relative to center (same as riseY=28).
				-- Sea bone top surface is at offset -6. Require 20 studs clearance = minimum offset of 14.
				local minPlatOffset = 22
				if newY < minPlatOffset then
					newY = lastY + math.abs(yDir)
					if newY < minPlatOffset then newY = minPlatOffset end
				end
				if newY > riseY + 30 then
					newY = lastY - math.abs(yDir)
				end

				-- If any player is currently near the sea surface, bias the next platform LOW so they can reach it
				local anyPlayerLow = false
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char and char ~= Character then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position.Y - center.Y) < 14 then
							anyPlayerLow = true
							break
						end
					end
				end
				if anyPlayerLow then
					newY = math.min(newY, minPlatOffset + 8)
				end
				if newY > riseY + 30 then
					newY = lastY - math.abs(yDir)
				end

				-- If any player is currently near the sea surface, bias the next platform LOW so they can reach it
				local anyPlayerLow = false
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char and char ~= Character then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position.Y - center.Y) < 14 then
							anyPlayerLow = true
							break
						end
					end
				end
				if anyPlayerLow then
					newY = math.min(newY, minPlatOffset + 8) -- keep near the low end so they can jump back up
				end

				local sPos = center + Vector3.new(zoneX/2 + 10, newY, newZ)
				local ePos = center + Vector3.new(-zoneX/2 - 20, newY, newZ)

				local oType = math.random(1, 10)
				local o1 = (oType <= 4)       -- 40% bone obstacle
				local o2 = (oType >= 5)       -- 60% bone rise trap

				if not _G.CancelAttackTrigger then
					SpawnObbyPlatform(sPos, ePos, o1, o2)
				end
				lastZ = newZ
				lastY = newY
			end

			task.wait(4)
			-- Drop sea bones
			TS:Create(seaBone, TweenInfo.new(1), {CFrame = CFrame.new(center + Vector3.new(0, -12, 0))}):Play()
			task.wait(1)
			seaActive = false
			seaBone:Destroy()
			for _, w in pairs(walls) do w:Destroy() end
			for _, p in pairs(platforms) do if p then p:Destroy() end end
		end
	else
		-- Original Bone Wave (F variant 1, no M1) — no auto-cancel here per design
		local startPos = (rootPart.CFrame * CFrame.new(0, -2.5, -5)).p
		local dir = (center - startPos).Unit
		local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
		local rotY = math.atan2(-flatDir.Z, flatDir.X) + math.rad(90)

		task.spawn(function()
			for wave = 1, 8 do
				if _G.CancelAttackTrigger then break end
				local centerOffset = startPos + (flatDir * (wave * 6))
				WarnAndRise(centerOffset, rotY, 45, 5, "Wave")
				task.wait(0.15)
			end
		end)
	end
end

function SummonSweepingMiniblaster(startCF, endCF, size, moveDuration)
	task.spawn(function()
		local GB = Instance.new("Part", Effects)
		GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
		GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
		GB.CFrame = startCF + Vector3.new(0, 10, 0) -- Spawn high

		local sm = Instance.new("SpecialMesh", GB)
		sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

		local Charge = Instance.new("Sound", GB)
		Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
		Charge:Play()

		TS:Create(GB, TweenInfo.new(0.4, Enum.EasingStyle.Back), {CFrame = startCF}):Play()
		TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()
		task.wait(0.45)

		sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
		sm.MeshId = "rbxassetid://2649610132"

		local Fire = Instance.new("Sound", GB)
		Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
		Fire:Play()

		local mag = 300
		local beamOffsetY = -size * 1.25
		local beam = Instance.new("Part", Effects)
		beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
		beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)
		beam.CFrame = startCF * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)

		local hitbox = Instance.new("Part", Effects)
		hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
		hitbox.Size, hitbox.CFrame = Vector3.new(size*2.5, size*2.5, mag), startCF * CFrame.new(0, beamOffsetY, -mag/2)

		TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, size*2.5, size*2.5)}):Play()

		local tInfo = TweenInfo.new(moveDuration, Enum.EasingStyle.Linear)
		TS:Create(GB, tInfo, {CFrame = endCF}):Play()

		local beamActive = true
		task.spawn(function()
			local hitCache = {}
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while beamActive do
				for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
							hitCache[hum] = tick()
							_G.ApplyKarmaHit(hum, 1.5)
						end
					end
				end
				task.wait(0.05)
			end
		end)

		local moveStart = tick()
		while tick() - moveStart < moveDuration do
			beam.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
			hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
			task.wait()
		end

		beamActive = false
		TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
		TS:Create(GB, TweenInfo.new(0.3), {Transparency = 1}):Play()
		task.wait(0.3)
		beam:Destroy() hitbox:Destroy() GB:Destroy()
	end)
end

local function SummonOrbitingBlasters(size, duration, orbitSpeed)
	task.spawn(function()
		local GB1 = Instance.new("Part", Effects)
		GB1.Anchored, GB1.CanCollide, GB1.Massless = true, false, true
		GB1.Material, GB1.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
		local sm1 = Instance.new("SpecialMesh", GB1)
		sm1.MeshType, sm1.MeshId, sm1.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

		local GB2 = GB1:Clone()
		GB2.Parent = Effects
		local sm2 = GB2.Mesh

		local Charge1 = Instance.new("Sound", GB1) Charge1.SoundId, Charge1.Volume = "rbxassetid://482211201", 1 Charge1:Play()
		local Charge2 = Instance.new("Sound", GB2) Charge2.SoundId, Charge2.Volume = "rbxassetid://482211201", 1 Charge2:Play()

		TS:Create(sm1, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()
		TS:Create(sm2, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()

		local currentTargetPos = mouse.Hit.p
		local angle = 0
		local radius = 35

		-- Charge phase
		local chargeTime = 1.0
		local startCharge = tick()
		while tick() - startCharge < chargeTime do
			local aimTarget = GetClosestTarget(currentTargetPos, 200)
			if aimTarget and aimTarget.Parent and aimTarget.Parent:FindFirstChild("HumanoidRootPart") then
				currentTargetPos = currentTargetPos:Lerp(aimTarget.Parent.HumanoidRootPart.Position, 0.2)
			end

			local rad1 = math.rad(angle)
			local rad2 = math.rad(angle + 180)

			local hp1 = currentTargetPos + Vector3.new(math.cos(rad1)*radius, size*3.5, math.sin(rad1)*radius)
			local hp2 = currentTargetPos + Vector3.new(math.cos(rad2)*radius, size*3.5, math.sin(rad2)*radius)

			GB1.CFrame = CFrame.lookAt(hp1, currentTargetPos) * CFrame.new(0, size * 1.25, 0)
			GB2.CFrame = CFrame.lookAt(hp2, currentTargetPos) * CFrame.new(0, size * 1.25, 0)

			task.wait(0.03)
		end

		sm1.MeshId = "rbxassetid://2649597177" sm2.MeshId = "rbxassetid://2649597177" task.wait(0.05)
		sm1.MeshId = "rbxassetid://2649610132" sm2.MeshId = "rbxassetid://2649610132"

		local Fire1 = Instance.new("Sound", GB1) Fire1.SoundId, Fire1.Volume = "rbxassetid://340722848", 2 Fire1:Play()
		local Fire2 = Instance.new("Sound", GB2) Fire2.SoundId, Fire2.Volume = "rbxassetid://340722848", 2 Fire2:Play()

		local mag = 300
		local beamOffsetY = -size * 1.25

		local beam1 = Instance.new("Part", Effects)
		beam1.Anchored, beam1.CanCollide, beam1.Material, beam1.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
		beam1.Shape, beam1.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)

		local beam2 = beam1:Clone() beam2.Parent = Effects

		local hitbox1 = Instance.new("Part", Effects)
		hitbox1.Anchored, hitbox1.CanCollide, hitbox1.Transparency = true, false, 1
		hitbox1.Size = Vector3.new(size*2.5, size*2.5, mag)

		local hitbox2 = hitbox1:Clone() hitbox2.Parent = Effects

		TS:Create(beam1, TweenInfo.new(0.1), {Size = Vector3.new(mag, size*2.5, size*2.5)}):Play()
		TS:Create(beam2, TweenInfo.new(0.1), {Size = Vector3.new(mag, size*2.5, size*2.5)}):Play()

		local beamActive = true
		task.spawn(function()
			local hitCache = {}
			local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
			while beamActive do
				for _, p in ipairs(workspace:GetPartsInPart(hitbox1, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
							hitCache[hum] = tick()
							_G.ApplyKarmaHit(hum, 1.5)
						end
					end
				end
				for _, p in ipairs(workspace:GetPartsInPart(hitbox2, params)) do
					local hum = p.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Parent ~= Character then
						if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
							hitCache[hum] = tick()
							_G.ApplyKarmaHit(hum, 1.5)
						end
					end
				end
				task.wait(0.05)
			end
		end)

		local fireStart = tick()
		while tick() - fireStart < duration do
			local aimTarget = GetClosestTarget(currentTargetPos, 200)
			if aimTarget and aimTarget.Parent and aimTarget.Parent:FindFirstChild("HumanoidRootPart") then
				currentTargetPos = currentTargetPos:Lerp(aimTarget.Parent.HumanoidRootPart.Position, 0.1)
			end

			angle = angle + orbitSpeed
			local rad1 = math.rad(angle)
			local rad2 = math.rad(angle + 180)

			local hp1 = currentTargetPos + Vector3.new(math.cos(rad1)*radius, size*3.5, math.sin(rad1)*radius)
			local hp2 = currentTargetPos + Vector3.new(math.cos(rad2)*radius, size*3.5, math.sin(rad2)*radius)

			GB1.CFrame = CFrame.lookAt(hp1, currentTargetPos) * CFrame.new(0, size * 1.25, 0)
			GB2.CFrame = CFrame.lookAt(hp2, currentTargetPos) * CFrame.new(0, size * 1.25, 0)

			beam1.CFrame = GB1.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
			beam2.CFrame = GB2.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)

			hitbox1.CFrame = GB1.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
			hitbox2.CFrame = GB2.CFrame * CFrame.new(0, beamOffsetY, -mag/2)

			task.wait()
		end

		beamActive = false
		TS:Create(beam1, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
		TS:Create(beam2, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
		TS:Create(GB1, TweenInfo.new(0.3), {Transparency = 1}):Play()
		TS:Create(GB2, TweenInfo.new(0.3), {Transparency = 1}):Play()
		task.wait(0.3)
		beam1:Destroy() beam2:Destroy() hitbox1:Destroy() hitbox2:Destroy() GB1:Destroy() GB2:Destroy()
	end)
end

function Attack_GBShower(useVariant)
	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")

	if isPhase2 or _G.SansOnPlatform then
		Pointing()

		local size = 1.5
		local numBlasters = 8
		local isOmega = false

		if isCtrlHeld then
			size = 7.0
			numBlasters = 4
			isOmega = true
		elseif useVariant then
			size = 3.5
			numBlasters = 4
		end

		local center = mouse.Hit.p

		-- Special auto-homing targeting sequence when Sans is stationed on his standing platform
		if _G.SansOnPlatform then
			local closestHum = GetClosestTarget(rootPart.Position, 500)
			if closestHum and closestHum.Parent and closestHum.Parent:FindFirstChild("HumanoidRootPart") then
				center = closestHum.Parent.HumanoidRootPart.Position
			else
				center = mouse.Hit.p
			end
		end

		local _aimPos, _aimPlat = ResolveAimHit()
		if _aimPlat then
			-- Snap blaster center to the moving platform's CURRENT top surface
			-- so the beams hit the platform instead of clipping into the sea below.
			center = _aimPos
		else
			local groundRay = Ray.new(center + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
			local _, floorPos = workspace:FindPartOnRayWithIgnoreList(groundRay, {Character, Effects})
			center = Vector3.new(center.X, floorPos.Y, center.Z)
		end

		local dir = (center - rootPart.Position).Unit
		local rightVec = Vector3.new(-dir.Z, 0, dir.X).Unit

		local hoverHeight = 15
		local form = math.random(1, 4)

		if form == 1 then
			-- Formation 1: Circle aiming towards center upon activation
			local radius = (size == 1.5) and 15 or (size == 3.5 and 20 or 25)
			for i = 1, numBlasters do
				if _G.CancelAttackTrigger then break end
				local angle = (i - 1) * (360 / numBlasters)
				local rad = math.rad(angle)
				local hoverPos = center + Vector3.new(math.cos(rad) * radius, hoverHeight, math.sin(rad) * radius)
				local spawnPos = hoverPos + Vector3.new(0, 15, 0)
				SummonModernBlaster(spawnPos, hoverPos, center, size, isOmega)
				task.wait(0.08)
			end
		elseif form == 2 then
			-- Formation 2: Straight Line facing/aiming towards the mouse
			local spacing = (size == 1.5) and 6 or (size == 3.5 and 10 or 15)
			local baseOffset = - (numBlasters - 1) * spacing / 2
			for i = 1, numBlasters do
				if _G.CancelAttackTrigger then break end
				local offsetDist = baseOffset + (i - 1) * spacing
				local hoverPos = center + (rightVec * offsetDist) + Vector3.new(0, hoverHeight, 0) - dir * 15
				local spawnPos = hoverPos + Vector3.new(0, 15, 0)
				SummonModernBlaster(spawnPos, hoverPos, center, size, isOmega)
				task.wait(0.08)
			end
		elseif form == 3 then
			-- Formation 3: Square aiming towards the mouse
			local squareSize = (size == 1.5) and 16 or (size == 3.5 and 20 or 28)
			local halfS = squareSize / 2
			local corners = {}
			if numBlasters == 4 then
				corners = {
					Vector3.new(halfS, hoverHeight, halfS),
					Vector3.new(-halfS, hoverHeight, halfS),
					Vector3.new(-halfS, hoverHeight, -halfS),
					Vector3.new(halfS, hoverHeight, -halfS),
				}
			else
				corners = {
					Vector3.new(halfS, hoverHeight, halfS),
					Vector3.new(0, hoverHeight, halfS),
					Vector3.new(-halfS, hoverHeight, halfS),
					Vector3.new(-halfS, hoverHeight, 0),
					Vector3.new(-halfS, hoverHeight, -halfS),
					Vector3.new(0, hoverHeight, -halfS),
					Vector3.new(halfS, hoverHeight, -halfS),
					Vector3.new(halfS, hoverHeight, 0),
				}
			end
			for i = 1, numBlasters do
				if _G.CancelAttackTrigger then break end
				local hoverPos = center + corners[i]
				local spawnPos = hoverPos + Vector3.new(0, 15, 0)
				SummonModernBlaster(spawnPos, hoverPos, center, size, isOmega)
				task.wait(0.08)
			end
		elseif form == 4 then
			-- Formation 4: Death Beam
			local baseHover = center + Vector3.new(0, hoverHeight, 0) - dir * 20
			for i = 1, numBlasters do
				if _G.CancelAttackTrigger then break end
				local hoverPos = baseHover + Vector3.new(0, (i - 1) * (size * 1.5), 0)
				local spawnPos = hoverPos + Vector3.new(0, 20, 0)
				SummonModernBlaster(spawnPos, hoverPos, center, size, isOmega)
				task.wait(0.08)
			end
		end

		return
	end

	local center = mouse.Hit.p

	-- Controlled keys mapping (useVariant is M1, isCtrlHeld is Control):
	if useVariant then
		-- Variant 1: Rotating Circle Blasters (doubled radius) - Activated with M1
		task.spawn(function()
			local CIRCLE_RADIUS = 44 -- doubled from 22
			local BLASTER_HEIGHT_OFFSET = 1.0
			local BLASTER_AIM_HEIGHT = 1.5
			local BLASTER_SPAWN_DEPTH = -10
			local BLASTER_ANGLE_STEP = 25
			local BLASTER_FIRE_RATE = 0.15
			local BLASTER_DURATION = 10

			local startTime = tick()
			local angle = 0
			local lockedFloorY = nil

			while tick() - startTime < BLASTER_DURATION do
				if _G.CancelAttackTrigger then break end
				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tCenter = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p

				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local ray = Ray.new(tCenter + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
				local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

				if not lockedFloorY then lockedFloorY = floorPos.Y end
				if math.abs(floorPos.Y - lockedFloorY) > 5 then lockedFloorY = floorPos.Y end

				tCenter = Vector3.new(tCenter.X, lockedFloorY, tCenter.Z)

				angle = angle + BLASTER_ANGLE_STEP
				local radAng = math.rad(angle)
				local hoverPos = tCenter + Vector3.new(math.cos(radAng)*CIRCLE_RADIUS, BLASTER_HEIGHT_OFFSET, math.sin(radAng)*CIRCLE_RADIUS)
				local spawnPos = hoverPos + Vector3.new(0, BLASTER_SPAWN_DEPTH, 0)

				SummonModernBlaster(spawnPos, hoverPos, tCenter + Vector3.new(0, BLASTER_AIM_HEIGHT, 0), 1.3)
				task.wait(BLASTER_FIRE_RATE)
			end
		end)
		return
	elseif isCtrlHeld then
		-- Variant 2: Tracking Sweeper (two diagonal sweeping miniblasters that follow the player) - Activated with Control
		task.spawn(function()
			local SWEEP_DURATION = 10
			local SWEEP_INTERVAL = 1.5
			local startTime = tick()
			local blSize = 1.2

			while tick() - startTime < SWEEP_DURATION do
				if _G.CancelAttackTrigger then break end

				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tPos = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p
				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local groundRay = Ray.new(tPos + Vector3.new(0, 10, 0), Vector3.new(0, -80, 0))
				local _, groundPos = workspace:FindPartOnRayWithIgnoreList(groundRay, ignoreList)
				local groundY = groundPos and groundPos.Y or (tPos.Y - 3)
				local tCenter = Vector3.new(tPos.X, groundY, tPos.Z)
				local spawnHeight = 1.2
				local b1_start = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight, -28), tCenter + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end   = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight,  28), tCenter + Vector3.new(28, spawnHeight,  28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_start = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight,  28), tCenter + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end   = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight, -28), tCenter + Vector3.new(-28, spawnHeight,-28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)

				task.wait(SWEEP_INTERVAL)
			end
		end)
		return
	end

	local form = math.random(1, 4)
	if form == 1 then 
		local offsets = {Vector3.new(10,10,10), Vector3.new(-10,10,10), Vector3.new(10,10,-10), Vector3.new(-10,10,-10)}
		for _, off in ipairs(offsets) do
			SummonModernBlaster(center + off + Vector3.new(0,10,0), center + off, center, 1.5) task.wait(0.1)
		end
	elseif form == 2 then 
		for i = 1, 6 do
			local angle = math.rad(i * (360/6))
			local hPos = center + Vector3.new(math.cos(angle)*12, 10, math.sin(angle)*12)
			SummonModernBlaster(hPos + Vector3.new(0,15,0), hPos, center, 1.5) task.wait(0.1)
		end
	elseif form == 3 then 
		for i = -1, 1 do
			local hPos = rootPart.Position + (rootPart.CFrame.RightVector * (i * 12)) + Vector3.new(0, 15, 0)
			SummonModernBlaster(hPos + Vector3.new(0, 15, 0), hPos, mouse.Hit.p, 3.5) task.wait(0.15)
		end
	elseif form == 4 then 
		for i = 1, 8 do
			local size = math.random(10, 25) / 10
			local spawnPos = rootPart.Position + Vector3.new(math.random(-20,20), math.random(10, 20), math.random(-20,20))
			local hoverPos = rootPart.Position + Vector3.new(math.random(-15,15), math.random(8, 15), math.random(-15,15))
			SummonModernBlaster(spawnPos, hoverPos, mouse.Hit.p, size) task.wait(0.1)
		end
	end
end

function Attack_BigCircleBlasters(useVariant)
	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if not isPhase2 then return end

	Pointing()

	if isCtrlHeld then
		if _G.Phase2PlatformActive then return end
		-- CONTROL VARIANT: circle super-blasters + x2 speed tracking sweepers from all directions!
		local BLASTER_DURATION = 10
		local blSize = 1.5

		task.spawn(function()
			local CIRCLE_RADIUS = 200 -- 4x Radius (Requested 200)
			local BLASTER_HEIGHT_OFFSET = 1.0
			local BLASTER_AIM_HEIGHT = 1.5
			local BLASTER_SPAWN_DEPTH = -10
			local BLASTER_ANGLE_STEP = -8 -- Smooth rotation around the 200-stud circle
			-- LINE 5367 (USER ADJUSTABLE): Alter the value below (currently 0.5) to change the super circling blasters spawn interval!
			local BLASTER_FIRE_RATE = 0.5
			local startTime = tick()
			local angle = 0
			local lockedFloorY = nil
			local spawnCount = 0

			while tick() - startTime < BLASTER_DURATION do
				if _G.CancelAttackTrigger then break end
				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tCenter = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p

				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local ray = Ray.new(tCenter + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
				local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

				if not lockedFloorY then lockedFloorY = floorPos.Y end
				if math.abs(floorPos.Y - lockedFloorY) > 5 then lockedFloorY = floorPos.Y end

				tCenter = Vector3.new(tCenter.X, lockedFloorY, tCenter.Z)

				angle = angle + BLASTER_ANGLE_STEP
				local radAng = math.rad(angle)
				local hoverPos = tCenter + Vector3.new(math.cos(radAng)*CIRCLE_RADIUS, BLASTER_HEIGHT_OFFSET, math.sin(radAng)*CIRCLE_RADIUS)
				local spawnPos = hoverPos + Vector3.new(0, BLASTER_SPAWN_DEPTH, 0)

				spawnCount = spawnCount + 1
				local desiredShootOffset = 6.0 + (spawnCount - 1) * 0.2
				local delayTime = (startTime + desiredShootOffset) - tick()
				if delayTime < 0.45 then delayTime = 0.45 end

				SummonModernBlaster(spawnPos, hoverPos, tCenter + Vector3.new(0, BLASTER_AIM_HEIGHT, 0), 7.0, true, delayTime)
				task.wait(BLASTER_FIRE_RATE)
			end
		end)

		task.spawn(function()
			local startTime = tick()
			local SWEEP_INTERVAL = 0.8

			while tick() - startTime < (BLASTER_DURATION + 6.0) do
				if _G.CancelAttackTrigger then break end

				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tPos = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p
				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local groundRay = Ray.new(tPos + Vector3.new(0, 10, 0), Vector3.new(0, -80, 0))
				local _, groundPos = workspace:FindPartOnRayWithIgnoreList(groundRay, ignoreList)
				local groundY = groundPos and groundPos.Y or (tPos.Y - 3)
				local tCenter = Vector3.new(tPos.X, groundY, tPos.Z)
				local spawnHeight = 1.2 -- Same jumpable height as Phase 1 circle blasters (1.0 studs above ground)!

				local b1_start = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight, -28), tCenter + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end   = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight,  28), tCenter + Vector3.new(28, spawnHeight,  28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight,  28), tCenter + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end   = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight, -28), tCenter + Vector3.new(-28, spawnHeight,-28)) * CFrame.new(0, blSize*1.25, 0)

				local b3_start = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight, -28), tCenter + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b3_end   = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight, -28), tCenter + Vector3.new( 28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b4_start = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight,  28), tCenter + Vector3.new( 28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b4_end   = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight,  28), tCenter + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 0.48)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 0.48)
				SummonSweepingMiniblaster(b3_start, b3_end, blSize, 0.48)
				SummonSweepingMiniblaster(b4_start, b4_end, blSize, 0.48)

				task.wait(SWEEP_INTERVAL)
			end
		end)

	elseif useVariant then
		-- M1 VARIANT: 4-way tracking sweepers
		task.spawn(function()
			local SWEEP_DURATION = 10
			local SWEEP_INTERVAL = 1.5
			local startTime = tick()
			local blSize = 1.3

			while tick() - startTime < SWEEP_DURATION do
				if _G.CancelAttackTrigger then break end

				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tPos = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p
				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local groundRay = Ray.new(tPos + Vector3.new(0, 10, 0), Vector3.new(0, -80, 0))
				local _, groundPos = workspace:FindPartOnRayWithIgnoreList(groundRay, ignoreList)
				local groundY = groundPos and groundPos.Y or (tPos.Y - 3)
				local tCenter = Vector3.new(tPos.X, groundY, tPos.Z)
				local spawnHeight = 1.2 -- Same jumpable height as Phase 1 circle blasters (1.0 studs above ground)!

				local b1_start = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight, -28), tCenter + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end   = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight,  28), tCenter + Vector3.new(28, spawnHeight,  28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight,  28), tCenter + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end   = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight, -28), tCenter + Vector3.new(-28, spawnHeight,-28)) * CFrame.new(0, blSize*1.25, 0)

				local b3_start = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight, -28), tCenter + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b3_end   = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight, -28), tCenter + Vector3.new( 28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b4_start = CFrame.lookAt(tCenter + Vector3.new( 28, spawnHeight,  28), tCenter + Vector3.new( 28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b4_end   = CFrame.lookAt(tCenter + Vector3.new(-28, spawnHeight,  28), tCenter + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
				SummonSweepingMiniblaster(b3_start, b3_end, blSize, 1.2)
				SummonSweepingMiniblaster(b4_start, b4_end, blSize, 1.2)

				task.wait(SWEEP_INTERVAL)
			end
		end)

	else
		-- NORMAL VARIANT: Big circle blasters
		task.spawn(function()
			local BLASTER_DURATION = 10
			local CIRCLE_RADIUS = 100 -- Radius of 100 studs
			local BLASTER_HEIGHT_OFFSET = 1.0
			local BLASTER_AIM_HEIGHT = 1.5
			local BLASTER_SPAWN_DEPTH = -10
			local BLASTER_ANGLE_STEP = 12.5 -- Halved Speed (was 25) to make it highly dodgeable
			local BLASTER_FIRE_RATE = 0.2
			local startTime = tick()
			local angle = 0
			local lockedFloorY = nil

			while tick() - startTime < BLASTER_DURATION do
				if _G.CancelAttackTrigger then break end
				local aimTarget = GetClosestTarget(mouse.Hit.p, 150)
				local tCenter = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or mouse.Hit.p

				local ignoreList = {Character, Effects}
				if aimTarget then table.insert(ignoreList, aimTarget.Parent) end
				local ray = Ray.new(tCenter + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
				local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

				if not lockedFloorY then lockedFloorY = floorPos.Y end
				if math.abs(floorPos.Y - lockedFloorY) > 5 then lockedFloorY = floorPos.Y end

				tCenter = Vector3.new(tCenter.X, lockedFloorY, tCenter.Z)

				angle = angle + BLASTER_ANGLE_STEP
				local radAng = math.rad(angle)
				local hoverPos = tCenter + Vector3.new(math.cos(radAng)*CIRCLE_RADIUS, BLASTER_HEIGHT_OFFSET, math.sin(radAng)*CIRCLE_RADIUS)
				local spawnPos = hoverPos + Vector3.new(0, BLASTER_SPAWN_DEPTH, 0)

				SummonModernBlaster(spawnPos, hoverPos, tCenter + Vector3.new(0, BLASTER_AIM_HEIGHT, 0), 3.5, false)
				task.wait(BLASTER_FIRE_RATE)
			end
		end)
	end
end

function Attack_Beam(useVariant)
	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
	if not isPhase2 then return end

	_G.activeBeamAttacks = (_G.activeBeamAttacks or 0) + 1
	_G.RightArmLocked = true

	-- Determine size, warnTime, damage, KR and duration
	local size = 1.5
	local warnTime = 0.4
	local dmg = 12
	local kr = 3.0 -- x2 of normal blaster KR (1.5)
	local beamDuration = 0.6
	if isCtrlHeld then
		size = 6.0
		warnTime = 0.8
		dmg = 48 -- x2 of M1 damage (24)
		kr = 12.0 -- x2 of super-blaster KR (6.0)
		beamDuration = 2.4 -- x2 of M1 beam duration (1.2)
	elseif useVariant then
		size = 3.0
		warnTime = 0.4
		dmg = 24 -- x2 of normal damage (12)
		kr = 6.0 -- x2 of big blaster KR (3.0)
		beamDuration = 1.2 -- x2 of normal beam duration (0.6)
	end

	-- Advanced Ground Detection (Ignores all Characters to find the actual floor)
	local mousePos = mouse.Hit.p
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local ray = Ray.new(mousePos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0))
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	if not floorPos then floorPos = mousePos - Vector3.new(0, 3, 0) end

	-- Initialize C0
	currentBeamArmC0 = RA_Weld.C0

	-- Lift arm up (animates for ~0.4s)
	for i = 1, 24 do
		currentBeamArmC0 = clerp(currentBeamArmC0, c_new(1.5, 0.8, -0.2) * c_angles(math.rad(-160), 0, 0), 0.12)
		swait()
	end

	-- Spawn Warning Neon Cyan block
	local warnWidth = size * 2.5
	local warn = Instance.new("Part", Effects)
	warn.Anchored, warn.CanCollide, warn.Massless = true, false, true
	warn.Material, warn.Color = Enum.Material.Neon, Color3.fromRGB(0, 255, 255)
	warn.Shape = Enum.PartType.Block
	warn.Size = Vector3.new(warnWidth, 0.1, warnWidth)
	warn.CFrame = CFrame.new(floorPos)

	local TS = game:GetService("TweenService")
	TS:Create(warn, TweenInfo.new(warnTime), {Transparency = 1, Size = Vector3.new(warnWidth * 1.1, 0.1, warnWidth * 1.1)}):Play()

	-- Hold arm high during the warnTime
	local warnTicks = math.floor(warnTime / (1/60))
	for i = 1, warnTicks do
		if _G.CancelAttackTrigger then break end
		currentBeamArmC0 = clerp(currentBeamArmC0, c_new(1.5, 0.8, -0.2) * c_angles(math.rad(-160), 0, 0), 0.1)
		swait()
	end
	warn:Destroy()

	if _G.CancelAttackTrigger then
		_G.activeBeamAttacks = math.max(0, (_G.activeBeamAttacks or 1) - 1)
		if _G.activeBeamAttacks == 0 then
			_G.RightArmLocked = false
			currentBeamArmC0 = nil
		end
		return
	end

	-- Arm down violently (animates for ~0.2s)
	for i = 1, 12 do
		currentBeamArmC0 = clerp(currentBeamArmC0, c_new(1.5, 0.1, -0.8) * c_angles(math.rad(30), 0, 0), 0.2)
		swait()
	end

	-- BEAM STRIKES!
	local mag = 350
	local beam = Instance.new("Part", Effects)
	beam.Anchored, beam.CanCollide, beam.Massless = true, false, true
	beam.Material, beam.Color, beam.Shape = Enum.Material.Neon, Color3.new(1, 1, 1), Enum.PartType.Cylinder
	beam.Size = Vector3.new(mag, 0, 0)
	beam.CFrame = CFrame.new(floorPos + Vector3.new(0, mag/2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local hitbox = Instance.new("Part", Effects)
	hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
	hitbox.Size = Vector3.new(warnWidth, mag, warnWidth)
	hitbox.CFrame = CFrame.new(floorPos + Vector3.new(0, mag/2, 0))

	local sound = Instance.new("Sound", hitbox)
	sound.SoundId = "rbxassetid://340722848"
	sound.Volume = 3
	sound:Play()

	TS:Create(beam, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(mag, warnWidth, warnWidth)}):Play()

	-- Damage Loop (lasts beamDuration)
	local beamActive = true
	task.spawn(function()
		local hitCache = {}
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {Character, Effects}

		while beamActive do
			local parts = workspace:GetPartsInPart(hitbox, overlapParams)
			for _, p in ipairs(parts) do
				local hum = p.Parent:FindFirstChildOfClass("Humanoid") or (p.Parent.Parent and p.Parent.Parent:FindFirstChildOfClass("Humanoid"))
				if hum and hum.Health > 0 and hum.Parent ~= Character then
					if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
						hitCache[hum] = tick()
						hum.Health = hum.Health - dmg
						_G.ApplyKarmaHit(hum, kr)
					end
				end
			end
			task.wait(0.05)
		end
	end)

	task.wait(beamDuration)
	beamActive = false

	TS:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(mag, 0, 0)}):Play()
	task.wait(0.2)
	beam:Destroy()
	hitbox:Destroy()

	_G.activeBeamAttacks = math.max(0, (_G.activeBeamAttacks or 1) - 1)
	if _G.activeBeamAttacks == 0 then
		_G.RightArmLocked = false
		currentBeamArmC0 = nil
	end
end

function Attack_BoxedBones()
	if attack then return end
	attack = true
	currentAnim = "Idling"

	-- Auto-cancel immediately if no player is nearby before anything fires
	if not GetClosestTarget(mouse.Hit.p, 100) then
		attack = false
		return
	end

	local Y_OFFSET = 0
	local targetHum = GetClosestTarget(mouse.Hit.p, 100)
	local center = targetHum and targetHum.Parent.PrimaryPart.Position or mouse.Hit.p
	local ray = Ray.new(center + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0))
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local floorY = floorPos and floorPos.Y or (center.Y - 10)

	center = Vector3.new(center.X, floorY + Y_OFFSET, center.Z)
	_G.CurrentArenaCenter = center

	-- Arena Build
	local boxGroup = Instance.new("Model", Effects)
	boxGroup.Name = "BoxedBonesArena"
	local function makeGroundLine(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide = true, false
		w.Color, w.Material = Color3.new(1, 1, 1), Enum.Material.Neon
		w.Size, w.CFrame = wSize, cframe
	end
	local function makeWall(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide, w.Transparency = true, true, 1
		w.CanQuery = false
		w.Size, w.CFrame = wSize, cframe
	end

	local s, h, t = 60, 50, 0.5 
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))

	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))

	-- Teleport players inside
	for _, plr in ipairs(game.Players:GetPlayers()) do
		local char = plr.Character
		if char and char ~= Character then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - center).Magnitude
				if dist < 120 then
					hrp.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))
				end
			end
		end
	end

	-- Teleport Sans
	local hl = Instance.new("Highlight", Character)
	hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
	CreateSound("12222170", Head, 5, 0.6)
	task.wait(0.15)
	rootPart.CFrame = CFrame.lookAt(center + Vector3.new(0, 3, 45), center)
	CreateSound("12222170", Head, 5, 0.65)
	task.wait(0.15)
	hl:Destroy()

	Humanoid.WalkSpeed = 0

	Expression.Texture = "rbxassetid://4484436948" -- Serious face
	task.wait(0.5)

	local function createVisualBone(parent, size, color, isBlue)
		local b = Instance.new("Part", parent)
		b.Anchored, b.CanCollide = true, false
		b.Size = size
		b.Material = Enum.Material.SmoothPlastic
		b.Color = color or Color3.new(1, 1, 1)
		if isBlue then
			b.Color = Color3.fromRGB(0, 170, 255)
			b.Material = Enum.Material.Neon
		end
		local sm = Instance.new("SpecialMesh", b)
		sm.MeshType = Enum.MeshType.FileMesh
		sm.MeshId = "http://www.roblox.com/asset/?id=921085633"
		sm.Scale = Vector3.new(size.X / 37.5, size.Y / 300, size.Z / 37.5)
		return b
	end

	-- === CONFIGURATION PARAMETERS ===
	local WaveConfig = {
		-- Bone Dimensions
		BoneWidth = 1.5,       -- Width of each bone (Z axis size)
		BoneHeight = 50,       -- Height of each vertical bone (Y axis size)
		
		-- Wave Math
		BaseLength = 25,       -- Base protrusion length of the bones
		Amplitude = 25,        -- How far the wave extends from the base length
		Frequency = 0.15,      -- Speed of wave shape change along Z (unused if time-based)
		Speed = 0.25,             -- Speed of wave movement over time (halved to make curves x2 larger/gentler)
		Symmetric = false,     -- If true, left and right waves are identical. If false, they are out of phase.
		
		-- Spawning & Movement
		SpawnInterval = 0.08,  -- How fast new bones spawn (lower = denser wave)
		BoneSpeed = 20,        -- Speed at which bones slide along the Z axis
		
		-- Box Size
		BoxSize = 60,          -- Width and depth of the box
		BoxHeight = 50,        -- Height of the box
	}

	-- Stage 1 Setup
	local stage1Bones = {}
	local lastSpawnTime = 0
	local gridBones = {}
	local safeIndicator = nil
	local xBone1 = nil
	local xBone2 = nil
	local blueBones = {}

	local active = true
	local timeElapsed = 0
	local hitCache = {}

	-- Stage 3 blue bone sound tracker
	local playedBlueSound = {}

	task.spawn(function()
		local lastTick = tick()
		while active and boxGroup.Parent do
			if _G.CancelAttackTrigger then break end
			local now = tick()
			local dt = now - lastTick
			lastTick = now
			timeElapsed = timeElapsed + dt

			if timeElapsed < 20 then
				if tick() - lastSpawnTime >= WaveConfig.SpawnInterval then
					lastSpawnTime = tick()
					local L_left = WaveConfig.BaseLength + WaveConfig.Amplitude * math.sin(timeElapsed * WaveConfig.Speed)
					local L_right
					if WaveConfig.Symmetric then
						L_right = L_left
					else
						L_right = WaveConfig.BaseLength + WaveConfig.Amplitude * math.sin(timeElapsed * WaveConfig.Speed + math.pi)
					end

					-- Left bone (vertical, standing straight up, extending from the left wall)
					local bL = createVisualBone(boxGroup, Vector3.new(L_left, WaveConfig.BoneHeight, WaveConfig.BoneWidth), Color3.new(1,1,1))
					bL.CFrame = CFrame.new(center) * CFrame.new(-WaveConfig.BoxSize/2 + L_left/2, WaveConfig.BoneHeight/2, -WaveConfig.BoxSize/2)
					table.insert(stage1Bones, {part = bL, isLeft = true, length = L_left, zOffset = -WaveConfig.BoxSize/2})

					-- Right bone (vertical, standing straight up, extending from the right wall)
					local bR = createVisualBone(boxGroup, Vector3.new(L_right, WaveConfig.BoneHeight, WaveConfig.BoneWidth), Color3.new(1,1,1))
					bR.CFrame = CFrame.new(center) * CFrame.new(WaveConfig.BoxSize/2 - L_right/2, WaveConfig.BoneHeight/2, -WaveConfig.BoxSize/2)
					table.insert(stage1Bones, {part = bR, isLeft = false, length = L_right, zOffset = -WaveConfig.BoxSize/2})
				end

				-- Update bones
				for i = #stage1Bones, 1, -1 do
					local bData = stage1Bones[i]
					if bData.part and bData.part.Parent then
						bData.zOffset = bData.zOffset + WaveConfig.BoneSpeed * dt
						if bData.zOffset > WaveConfig.BoxSize/2 then
							bData.part:Destroy()
							table.remove(stage1Bones, i)
						else
							local posX = bData.isLeft and (-WaveConfig.BoxSize/2 + bData.length/2) or (WaveConfig.BoxSize/2 - bData.length/2)
							bData.part.CFrame = CFrame.new(center) * CFrame.new(posX, WaveConfig.BoneHeight/2, bData.zOffset)
						end
					else
						table.remove(stage1Bones, i)
					end
				end

			elseif timeElapsed >= 20 and timeElapsed < 40 then
				-- Transition to Stage 2 if not done
				if #stage1Bones > 0 or not gridBones[1] then
					for _, bData in ipairs(stage1Bones) do
						if bData.part then bData.part:Destroy() end
					end
					stage1Bones = {}

					-- Setup grid bones
					for x = -28, 28, 4 do
						for z = -28, 28, 4 do
							local b = createVisualBone(boxGroup, Vector3.new(3, 5, 3), Color3.new(1,1,1))
							b.CFrame = CFrame.new(center) * CFrame.new(x, -10, z)
							table.insert(gridBones, b)
						end
					end

					-- Setup safe spot indicator
					safeIndicator = Instance.new("Part", boxGroup)
					safeIndicator.Anchored, safeIndicator.CanCollide = true, false
					safeIndicator.Size = Vector3.new(0.1, 16, 16)
					safeIndicator.Shape = Enum.PartType.Cylinder
					safeIndicator.Material = Enum.Material.Neon
					safeIndicator.Color = Color3.fromRGB(0, 255, 100)
					safeIndicator.Transparency = 0.8
					CreateSound("306247749", Head, 4, 0.8)
				end

				-- Update safe spot position
				local angle = (timeElapsed - 20) * math.pi * 2 * 0.1
				local safeX = math.cos(angle) * 18
				local safeZ = math.sin(angle) * 18
				local safePos = center + Vector3.new(safeX, 0, safeZ)

				if safeIndicator then
					safeIndicator.CFrame = CFrame.new(safePos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
				end

				for _, bone in ipairs(gridBones) do
					local bonePos = bone.Position
					local flatDist = (Vector3.new(bonePos.X, 0, bonePos.Z) - Vector3.new(safePos.X, 0, safePos.Z)).Magnitude
					local targetY = (flatDist < 8) and (center.Y - 10) or (center.Y + 2.5)
					bone.CFrame = bone.CFrame:Lerp(CFrame.new(bonePos.X, targetY, bonePos.Z), 0.2)
				end

			elseif timeElapsed >= 40 and timeElapsed < 60 then
				-- Transition to Stage 3 if not done
				if #gridBones > 0 then
					for _, b in ipairs(gridBones) do b:Destroy() end
					gridBones = {}
					if safeIndicator then safeIndicator:Destroy() end

					-- Setup rotating X (size adjusted so Y is long axis for correct bone mesh scaling)
					xBone1 = createVisualBone(boxGroup, Vector3.new(4, 65, 4), Color3.new(1,1,1))
					xBone2 = createVisualBone(boxGroup, Vector3.new(4, 65, 4), Color3.new(1,1,1))

					-- Remake the blue bone wall from scratch (using multiple vertical bones to avoid goofy stretching)
					blueBones = {}
					local numBones = 16
					local spacing = 56 / (numBones - 1)
					for k = 0, numBones - 1 do
						local xOffset = -28 + k * spacing
						local b = createVisualBone(boxGroup, Vector3.new(3, 15, 3), Color3.fromRGB(0, 170, 255), true)
						b.CFrame = CFrame.new(center) * CFrame.new(xOffset, -20, 0)
						table.insert(blueBones, {part = b, xOffset = xOffset})
					end
					CreateSound("306247749", Head, 5, 0.7)
				end

				-- Update rotating X bones (rotated flat horizontally to form a correct X on the box)
				local angle = (timeElapsed - 40) * math.rad(30)
				if xBone1 and xBone1.Parent then
					xBone1.CFrame = CFrame.new(center) * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, angle, 0) * CFrame.Angles(0, 0, math.rad(90))
				end
				if xBone2 and xBone2.Parent then
					xBone2.CFrame = CFrame.new(center) * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, angle + math.pi/2, 0) * CFrame.Angles(0, 0, math.rad(90))
				end

				-- Update giant blue bone sweeps (3 times during Stage 3: 42-46s, 48-52s, 54-58s)
				local sweepStartTimes = {42.0, 48.0, 54.0}
				local sweepDuration = 4.0
				local isSweepActive = false
				local blueZ = -100

				for i, startT in ipairs(sweepStartTimes) do
					if timeElapsed >= startT and timeElapsed < startT + sweepDuration then
						isSweepActive = true
						if not playedBlueSound[i] then
							playedBlueSound[i] = true
							CreateSound("340722848", Head, 4, 1.2) -- laser sound for blue bone entrance
						end
						local sweepT = (timeElapsed - startT) / sweepDuration
						if i == 2 then
							blueZ = 28 - 56 * sweepT
						else
							blueZ = -28 + 56 * sweepT
						end
						break
					end
				end

				if blueBones then
					for _, bData in ipairs(blueBones) do
						if bData.part and bData.part.Parent then
							if isSweepActive then
								bData.part.CFrame = CFrame.new(center) * CFrame.new(bData.xOffset, 7.5, blueZ)
							else
								bData.part.CFrame = CFrame.new(center) * CFrame.new(bData.xOffset, -20, 0)
							end
						end
					end
				end
			elseif timeElapsed >= 60 then
				break
			end

			-- Damage Check
			for _, plr in ipairs(game.Players:GetPlayers()) do
				local char = plr.Character
				if char and char ~= Character then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hrp and hum and hum.Health > 0 then
						local relPos = hrp.Position - center
						local takesDamage = false
						local krTicks = 1
						local directDmg = 4

						if timeElapsed < 10 then
							for _, bData in ipairs(stage1Bones) do
								if math.abs(relPos.Z - bData.zOffset) < (WaveConfig.BoneWidth + 1.2) then
									if bData.isLeft then
										if relPos.X < -WaveConfig.BoxSize/2 + bData.length + 1.2 and relPos.Y < (WaveConfig.BoneHeight + 2.5) then
											takesDamage = true
											break
										end
									else
										if relPos.X > WaveConfig.BoxSize/2 - bData.length - 1.2 and relPos.Y < (WaveConfig.BoneHeight + 2.5) then
											takesDamage = true
											break
										end
									end
								end
							end
						elseif timeElapsed >= 10 and timeElapsed < 20 then
							local angle = (timeElapsed - 10) * math.pi * 2 * 0.1
							local safeX = math.cos(angle) * 18
							local safeZ = math.sin(angle) * 18
							local safePos = center + Vector3.new(safeX, 0, safeZ)
							local flatDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(safePos.X, 0, safePos.Z)).Magnitude
							if flatDist > 8 and relPos.Y < 5 then
								takesDamage = true
							end
						elseif timeElapsed >= 20 and timeElapsed < 30 then
							local angle = (timeElapsed - 20) * math.rad(30)
							local dist1 = math.abs(relPos.X * math.sin(angle) - relPos.Z * math.cos(angle))
							local dist2 = math.abs(relPos.X * math.sin(angle + math.pi/2) - relPos.Z * math.cos(angle + math.pi/2))
							if (dist1 < 2.5 or dist2 < 2.5) and relPos.Y < 5 then
								takesDamage = true
							end

							local sweepStartTimes = {21.0, 24.0, 27.0}
							local sweepDuration = 2.0
							local isSweepActive = false
							local blueZ = -100
							for i, startT in ipairs(sweepStartTimes) do
								if timeElapsed >= startT and timeElapsed < startT + sweepDuration then
									isSweepActive = true
									local sweepT = (timeElapsed - startT) / sweepDuration
									if i == 2 then
										blueZ = 28 - 56 * sweepT
									else
										blueZ = -28 + 56 * sweepT
									end
									break
								end
							end

							-- Accurate hitbox: thickness check, height check (< 15 studs), and horizontal movement speed check (> 2.0 studs/s)
							if isSweepActive and math.abs(relPos.Z - blueZ) < 3.0 and relPos.Y < 15 then
								local isMoving = (hum.MoveDirection.Magnitude > 0.1) or (Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude > 2.0)
								if isMoving then
									takesDamage = true
									directDmg = 12
								end
							end
						end

						if takesDamage then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.15 then
								hitCache[hum] = tick()
								if Death == true or Death2 == true then
									directDmg = directDmg * 2
								end
								hum.Health = hum.Health - directDmg
								_G.ApplyKarmaHit(hum, krTicks)
							end
						end
					end
				end
			end

			task.wait(0.03)
		end

		active = false
		-- Cleanup
		if boxGroup then boxGroup:Destroy() end
		pcall(function()
			Humanoid.WalkSpeed = 16
		end)
		attack = false
	end)
end

-- FIX 3: The Final Attack (20s Circle Spam in the Arena)
function Attack_FinalCinematic()
	if attack then return end
	attack = true
	currentAnim = "Idling"

	-- Auto-cancel immediately if no player is nearby before anything fires
	if not GetClosestTarget(mouse.Hit.p, 100) then
		attack = false
		return
	end

	local Y_OFFSET = 0

	local targetHum = GetClosestTarget(mouse.Hit.p, 100)
	local center = targetHum and targetHum.Parent.PrimaryPart.Position or mouse.Hit.p
	local ray = Ray.new(center + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0))
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local floorY = floorPos and floorPos.Y or (center.Y - 10)

	center = Vector3.new(center.X, floorY + Y_OFFSET, center.Z)
	_G.CurrentArenaCenter = center

	local boxGroup = Instance.new("Model", Effects)
	local function makeGroundLine(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide = true, false
		w.Color, w.Material = Color3.new(1, 1, 1), Enum.Material.Neon
		w.Size, w.CFrame = wSize, cframe
	end
	local function makeWall(cframe, wSize)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide, w.Transparency = true, true, 1
		w.CanQuery = false
		w.Size, w.CFrame = wSize, cframe
	end

	local s, h, t = 60, 50, 0.5 
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))

	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))

	if targetHum and targetHum.Parent:FindFirstChild("HumanoidRootPart") then
		targetHum.Parent.HumanoidRootPart.CFrame = CFrame.new(center + Vector3.new(0,3,0))
	end

	local hl = Instance.new("Highlight", Character)
	hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
	CreateSound("12222170", Head, 5, 0.6)
	task.wait(0.15)
	rootPart.CFrame = CFrame.lookAt(center + Vector3.new(0, 3, 45), center)
	CreateSound("12222170", Head, 5, 0.65)
	task.wait(0.15)
	hl:Destroy()

	Humanoid.WalkSpeed = 0

	Expression.Texture = "rbxassetid://4484436948" -- Serious expression for the fake final attack
	chatfunc("* survive this, and i'll show you my special attack.")
	task.wait(3.5)

	-- Secretly double all blaster damage during this cinematic only
	_G.FinalCinematicBlasterMult = 2.0

	-- 🌟 RECENT REQUEST: Spawn sweeping blue bone walls during Phase 1 cinematic!
	-- Sweeps repeatedly during the 30-second fake-final circle attack.
	task.spawn(function()
		local sweepCount = 0
		while fakeActive do
			if _G.CancelAttackTrigger or not boxGroup.Parent then break end
			sweepCount = sweepCount + 1
			local dir = (sweepCount % 2 == 1) and "Front" or "Back"
			if _G.SpawnCinematicBlueBoneSweep then
				_G.SpawnCinematicBlueBoneSweep(boxGroup, center, dir, 5.0)
			end
			task.wait(6.0)
		end
	end)

	local function getAimPos()
		local t = GetClosestTarget(center, 70)
		if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
			return t.Parent.HumanoidRootPart.Position - Vector3.new(0, 1.5, 0)
		end
		return center
	end

	local fakeActive = true
	local fakeAngle = 0

	local function SpawnPersistentCircleBlaster(baseAngleDeg)
		task.spawn(function()
			local BLASTER_RADIUS = 34 -- Radius of the circling blasters
			local BLASTER_HEIGHT = 1.5
			local BLASTER_SIZE = 1.2
			local BEAM_LEN = 300

			local GB = Instance.new("Part", Effects)
			GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
			GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
			local sm = Instance.new("SpecialMesh", GB)
			sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

			local Charge = Instance.new("Sound", GB)
			Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
			Charge:Play()
			TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(BLASTER_SIZE, BLASTER_SIZE, BLASTER_SIZE)}):Play()

			local function resolve()
				local angDeg = baseAngleDeg + fakeAngle
				local rad = math.rad(angDeg)
				local hp  = center + Vector3.new(math.cos(rad) * BLASTER_RADIUS, BLASTER_HEIGHT, math.sin(rad) * BLASTER_RADIUS)
				local aim = center + Vector3.new(-math.cos(rad) * BLASTER_RADIUS, BLASTER_HEIGHT, -math.sin(rad) * BLASTER_RADIUS)
				return hp, aim
			end

			local chargeTime = 1.0
			local startCharge = tick()
			while tick() - startCharge < chargeTime do
				if _G.CancelAttackTrigger or not fakeActive then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, BLASTER_SIZE * 1.25, 0)
				task.wait(0.03)
			end

			if not fakeActive or _G.CancelAttackTrigger then GB:Destroy() return end

			sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
			sm.MeshId = "rbxassetid://2649610132"

			local Fire = Instance.new("Sound", GB)
			Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
			Fire:Play()

			local mag = BEAM_LEN
			local beamOffsetY = -BLASTER_SIZE * 1.25

			local beam = Instance.new("Part", Effects)
			beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
			beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)

			local hitbox = Instance.new("Part", Effects)
			hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
			hitbox.Size = Vector3.new(BLASTER_SIZE * 2.5, BLASTER_SIZE * 2.5, mag)

			TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, BLASTER_SIZE * 2.5, BLASTER_SIZE * 2.5)}):Play()

			local beamActive = true
			task.spawn(function()
				local hitCache = {}
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while beamActive do
					for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
						local hum = p.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
								hitCache[hum] = tick()
								local mult = (_G.FinalCinematicBlasterMult or 1.0)
								_G.ApplyKarmaHit(hum, 1.5 * mult)
							end
						end
					end
					task.wait(0.05)
				end
			end)

			while fakeActive do
				if _G.CancelAttackTrigger then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, BLASTER_SIZE * 1.25, 0)
				beam.CFrame   = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
				hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
				task.wait()
			end

			beamActive = false
			TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
			TS:Create(GB,   TweenInfo.new(0.3), {Transparency = 1}):Play()
			task.wait(0.3)
			beam:Destroy() hitbox:Destroy() GB:Destroy()
		end)
	end

	local NUM_CIRCLE_BLASTERS = 6
	for i = 1, NUM_CIRCLE_BLASTERS do
		SpawnPersistentCircleBlaster((i - 1) * (360 / NUM_CIRCLE_BLASTERS))
	end

	task.spawn(function()
		local ROTATION_SPEED = 2 -- Speed of rotation (customizable)
		while fakeActive do
			if _G.CancelAttackTrigger then break end
			fakeAngle = (fakeAngle + ROTATION_SPEED) % 360
			task.wait(0.05)
		end
	end)

	for sec = 1, 46 do
		if _G.CancelAttackTrigger then break end
		local activeTarget = GetClosestTarget(center, 70)
		if not activeTarget then break end -- Ends Prematurely!

		task.spawn(function()
			local spawnHeight = 1.2 -- Keep ground sweeps flush to the ground!
			local blSize = 0.7

			if sec % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end

			local aimPos = getAimPos()

			local bpSpawn = aimPos + Vector3.new(0, 30, 0)
			SummonModernBlaster(bpSpawn, bpSpawn, aimPos, 3)
		end)
		task.wait(0.66)
	end

	fakeActive = false

	task.wait(2.5)
	_G.FinalCinematicBlasterMult = 1.0 -- Restore normal blaster damage
	Expression.Texture = "rbxassetid://4484405390"
	chatfunc("* huff... puff...") task.wait(3)
	chatfunc("* alright. that's it.") task.wait(3)

	Humanoid.WalkSpeed = 16
	boxGroup:Destroy()
	attack = false
end

function Attack_TrueFinalCinematic()
	if attack then return end
	attack = true
	currentAnim = "Idling"

	-- Auto-cancel immediately if no player is nearby before anything fires
	if not GetClosestTarget(mouse.Hit.p, 100) then
		attack = false
		return
	end

	local Y_OFFSET = 0
	local targetHum = GetClosestTarget(mouse.Hit.p, 100)
	local center = targetHum and targetHum.Parent.PrimaryPart.Position or mouse.Hit.p
	local ray = Ray.new(center + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0))
	local ignoreList = {Character, Effects}
	for _, v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(ignoreList, v)
		end
	end
	local _, floorPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	local floorY = floorPos and floorPos.Y or (center.Y - 10)
	center = Vector3.new(center.X, floorY + Y_OFFSET, center.Z)
	_G.CurrentArenaCenter = center

	-- 60x60 Box Arena
	local boxGroup = Instance.new("Model", Effects)
	local function makeGroundLine(cf, sZ)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide, w.Color, w.Material = true, false, Color3.new(1,1,1), Enum.Material.Neon
		w.Size, w.CFrame = sZ, cf
	end
	local function makeWall(cf, sZ)
		local w = Instance.new("Part", boxGroup) w.Anchored, w.CanCollide, w.Transparency = true, true, 1
		w.CanQuery = false
		w.Size, w.CFrame = sZ, cf
	end

	local s, h, t = 60, 50, 0.5 
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))

	if targetHum and targetHum.Parent:FindFirstChild("HumanoidRootPart") then
		targetHum.Parent.HumanoidRootPart.CFrame = CFrame.new(center + Vector3.new(0,3,0))
	end

	local hl = Instance.new("Highlight", Character) hl.FillColor, hl.OutlineColor = Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 255, 255)
	CreateSound("12222170", Head, 5, 0.6) task.wait(0.15)
	rootPart.CFrame = CFrame.lookAt(center + Vector3.new(0, 3, 45), center)
	CreateSound("12222170", Head, 5, 0.65) task.wait(0.15) hl:Destroy()

	Humanoid.WalkSpeed = 0

	Expression.Texture = "rbxassetid://4484436948"
	chatfunc("* ready for the real deal?")
	task.wait(3)

	local function pickTarget()
		return GetClosestTarget(center, 90)
	end

	local function getAimPos()
		local t = pickTarget()
		if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
			return t.Parent.HumanoidRootPart.Position - Vector3.new(0, 1.5, 0)
		end return center
	end

	local function getBodyAimPos()
		local t = pickTarget()
		if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
			return t.Parent.HumanoidRootPart.Position
		end return center + Vector3.new(0, 3, 0)
	end

	-- ========================================================
	-- [STAGE 1]: FIRST ATTACK PHASE 1 (12s instead of 15s - x1.25 SPEEDUP)
	-- ========================================================
	local p1Active = true

	-- 🌟 RECENT REQUEST: Spawn a sweeping blue bone wall during Phase 1 of True Final Cinematic!
	-- Sweeps from Front to Back starting at 2 seconds, lasting 4 seconds.
	-- Sweeps from Back to Front starting at 6 seconds, lasting 4 seconds.
	task.delay(2, function()
		if p1Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 3.2)
		end
	end)
	task.delay(6, function()
		if p1Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Back", 3.2)
		end
	end)

	local function CornerBigBlasterLoop(spawnOffset, fixedAimOffset)
		local hoverPos = center + spawnOffset
		local spawnPos = hoverPos + Vector3.new(0, 10, 0)
		local fixedAim = center + fixedAimOffset
		task.spawn(function()
			while p1Active do
				if _G.CancelAttackTrigger then break end
				SummonModernBlaster(spawnPos, hoverPos, fixedAim, 3)
				task.wait(2.6 / 1.25)
			end
		end)
	end

	CornerBigBlasterLoop(Vector3.new(-32, 1.5,  22), Vector3.new( 32, 1.5,  22))
	CornerBigBlasterLoop(Vector3.new( 32, 1.5, -22), Vector3.new(-32, 1.5, -22))

	task.spawn(function()
		local count = 0
		while p1Active do
			if _G.CancelAttackTrigger then break end
			count = count + 1
			local spawnHeight = 1.2
			local blSize = 0.7
			if count % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end
			task.wait(1.0 / 1.25)
		end
	end)

	task.spawn(function()
		local CIRCLE_RADIUS = 18
		local BLASTER_HEIGHT_OFFSET = 1.0
		local BLASTER_AIM_HEIGHT = 1.5
		local BLASTER_SPAWN_DEPTH = -10
		local BLASTER_ANGLE_STEP = 30
		local BLASTER_FIRE_RATE = 0.35 / 1.25
		local angle = 0
		local lockedFloorY = center.Y

		while p1Active do
			if _G.CancelAttackTrigger then break end
			local aimTarget = pickTarget()
			local tCenter = aimTarget and aimTarget.Parent.HumanoidRootPart.Position or center
			tCenter = Vector3.new(tCenter.X, lockedFloorY, tCenter.Z)

			angle = angle + BLASTER_ANGLE_STEP
			local radAng = math.rad(angle)
			local hoverPos = tCenter + Vector3.new(math.cos(radAng)*CIRCLE_RADIUS, BLASTER_HEIGHT_OFFSET, math.sin(radAng)*CIRCLE_RADIUS)
			local spawnPos = hoverPos + Vector3.new(0, BLASTER_SPAWN_DEPTH, 0)
			SummonModernBlaster(spawnPos, hoverPos, tCenter + Vector3.new(0, BLASTER_AIM_HEIGHT, 0), 1.1)
			task.wait(BLASTER_FIRE_RATE)
		end
	end)

	task.wait(12)
	p1Active = false
	task.wait(0.5)

	-- ========================================================
	-- [STAGE 2]: FIRST ATTACK PHASE 2 (12s instead of 15s - x1.25 SPEEDUP)
	-- ========================================================
	local p2Active = true
	local crossAngle = 0
	local crossRotating = false

	local CROSS_RING = 32
	local CROSS_GROUND_Y = 1.5
	local CROSS_SIZE = 1.5
	local CROSS_BEAM_LEN = 300

	local function SpawnPersistentCrossBlaster(baseAngleDeg)
		task.spawn(function()
			local GB = Instance.new("Part", Effects)
			GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
			GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
			local sm = Instance.new("SpecialMesh", GB)
			sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

			local Charge = Instance.new("Sound", GB)
			Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
			Charge:Play()
			TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(CROSS_SIZE, CROSS_SIZE, CROSS_SIZE)}):Play()

			local function resolve()
				local angDeg = baseAngleDeg + crossAngle
				local rad = math.rad(angDeg)
				local hp  = center + Vector3.new( math.cos(rad) * CROSS_RING, CROSS_GROUND_Y,  math.sin(rad) * CROSS_RING)
				local aim = center + Vector3.new(-math.cos(rad) * CROSS_RING, CROSS_GROUND_Y, -math.sin(rad) * CROSS_RING)
				return hp, aim
			end

			local chargeTime = 1.0
			local startCharge = tick()
			while tick() - startCharge < chargeTime do
				if _G.CancelAttackTrigger or not p2Active then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, CROSS_SIZE * 1.25, 0)
				task.wait(0.03)
			end

			if not p2Active or _G.CancelAttackTrigger then GB:Destroy() return end

			sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
			sm.MeshId = "rbxassetid://2649610132"

			local Fire = Instance.new("Sound", GB)
			Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
			Fire:Play()

			local mag = CROSS_BEAM_LEN
			local beamOffsetY = -CROSS_SIZE * 1.25

			local beam = Instance.new("Part", Effects)
			beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
			beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)

			local hitbox = Instance.new("Part", Effects)
			hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
			hitbox.Size = Vector3.new(CROSS_SIZE * 2.5, CROSS_SIZE * 2.5, mag)

			TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, CROSS_SIZE * 2.5, CROSS_SIZE * 2.5)}):Play()

			local beamActive = true
			task.spawn(function()
				local hitCache = {}
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while beamActive do
					for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
						local hum = p.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
								hitCache[hum] = tick()
								local mult = (_G.FinalCinematicBlasterMult or 1.0)
								_G.ApplyKarmaHit(hum, 1.5 * mult)
							end
						end
					end
					task.wait(0.05)
				end
			end)

			while p2Active do
				if _G.CancelAttackTrigger then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, CROSS_SIZE * 1.25, 0)
				beam.CFrame   = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
				hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
				task.wait()
			end

			beamActive = false
			TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
			TS:Create(GB,   TweenInfo.new(0.3), {Transparency = 1}):Play()
			task.wait(0.3)
			beam:Destroy() hitbox:Destroy() GB:Destroy()
		end)
	end

	SpawnPersistentCrossBlaster(90)
	SpawnPersistentCrossBlaster(270)
	SpawnPersistentCrossBlaster(0)
	SpawnPersistentCrossBlaster(180)

	-- Blue bone wall sweeps during Stage 2
	task.delay(3, function()
		if p2Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 3.2)
		end
	end)
	task.delay(8, function()
		if p2Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Back", 3.2)
		end
	end)

	task.spawn(function()
		local count = 0
		while p2Active do
			if _G.CancelAttackTrigger then break end
			count = count + 1
			local spawnHeight = 1.2
			local blSize = 0.7
			if count % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end
			task.wait(1.0 / 1.25)
		end
	end)

	task.spawn(function()
		while p2Active do
			if _G.CancelAttackTrigger then break end
			local t = pickTarget()
			if t and t.Parent and t.Parent:FindFirstChild("HumanoidRootPart") then
				local pPos = t.Parent.HumanoidRootPart.Position
				local hoverPos = pPos + Vector3.new(0, 12, 0)
				local spawnPos = hoverPos + Vector3.new(0, 8, 0)
				SummonModernBlaster(spawnPos, hoverPos, getBodyAimPos(), 0.9)
			end
			task.wait(0.75 / 1.25)
		end
	end)

	task.delay(1 / 1.25, function()
		crossRotating = true
		task.spawn(function()
			while p2Active do
				if _G.CancelAttackTrigger then break end
				crossAngle = (crossAngle + 2 * 1.25) % 360
				task.wait(0.05 / 1.25)
			end
		end)
	end)

	task.wait(12)
	p2Active = false
	task.wait(0.5)

	-- ========================================================
	-- [STAGE 3]: FAKE FINAL ATTACK (x1.25 SPEEDUP)
	-- ========================================================
	_G.FinalCinematicBlasterMult = 2.0

	local fakeActive = true

	-- Blue bone wall sweeps during Stage 3
	task.spawn(function()
		local sweepCount = 0
		while fakeActive do
			if _G.CancelAttackTrigger or not boxGroup.Parent then break end
			sweepCount = sweepCount + 1
			local dir = (sweepCount % 2 == 1) and "Front" or "Back"
			if _G.SpawnCinematicBlueBoneSweep then
				_G.SpawnCinematicBlueBoneSweep(boxGroup, center, dir, 3.2)
			end
			task.wait(4.5)
		end
	end)
	local fakeAngle = 0

	local function SpawnPersistentCircleBlaster(baseAngleDeg)
		task.spawn(function()
			local BLASTER_RADIUS = 34 -- Radius of the circling blasters
			local BLASTER_HEIGHT = 1.5
			local BLASTER_SIZE = 1.2
			local BEAM_LEN = 300

			local GB = Instance.new("Part", Effects)
			GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
			GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
			local sm = Instance.new("SpecialMesh", GB)
			sm.MeshType, sm.MeshId, sm.Scale = Enum.MeshType.FileMesh, "rbxassetid://2649585735", Vector3.new(0,0,0)

			local Charge = Instance.new("Sound", GB)
			Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1
			Charge:Play()
			TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(BLASTER_SIZE, BLASTER_SIZE, BLASTER_SIZE)}):Play()

			local function resolve()
				local angDeg = baseAngleDeg + fakeAngle
				local rad = math.rad(angDeg)
				local hp  = center + Vector3.new(math.cos(rad) * BLASTER_RADIUS, BLASTER_HEIGHT, math.sin(rad) * BLASTER_RADIUS)
				local aim = center + Vector3.new(-math.cos(rad) * BLASTER_RADIUS, BLASTER_HEIGHT, -math.sin(rad) * BLASTER_RADIUS)
				return hp, aim
			end

			local chargeTime = 1.0
			local startCharge = tick()
			while tick() - startCharge < chargeTime do
				if _G.CancelAttackTrigger or not fakeActive then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, BLASTER_SIZE * 1.25, 0)
				task.wait(0.03)
			end

			if not fakeActive or _G.CancelAttackTrigger then GB:Destroy() return end

			sm.MeshId = "rbxassetid://2649597177" task.wait(0.05)
			sm.MeshId = "rbxassetid://2649610132"

			local Fire = Instance.new("Sound", GB)
			Fire.SoundId, Fire.Volume = "rbxassetid://340722848", 2
			Fire:Play()

			local mag = BEAM_LEN
			local beamOffsetY = -BLASTER_SIZE * 1.25

			local beam = Instance.new("Part", Effects)
			beam.Anchored, beam.CanCollide, beam.Material, beam.Color = true, false, Enum.Material.Neon, Color3.new(1,1,1)
			beam.Shape, beam.Size = Enum.PartType.Cylinder, Vector3.new(mag, 0, 0)

			local hitbox = Instance.new("Part", Effects)
			hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1
			hitbox.Size = Vector3.new(BLASTER_SIZE * 2.5, BLASTER_SIZE * 2.5, mag)

			TS:Create(beam, TweenInfo.new(0.1), {Size = Vector3.new(mag, BLASTER_SIZE * 2.5, BLASTER_SIZE * 2.5)}):Play()

			local beamActive = true
			task.spawn(function()
				local hitCache = {}
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while beamActive do
					for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
						local hum = p.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.1 then
								hitCache[hum] = tick()
								local mult = (_G.FinalCinematicBlasterMult or 1.0)
								_G.ApplyKarmaHit(hum, 1.5 * mult)
							end
						end
					end
					task.wait(0.05)
				end
			end)

			while fakeActive do
				if _G.CancelAttackTrigger then break end
				local hp, aim = resolve()
				GB.CFrame = CFrame.lookAt(hp, aim) * CFrame.new(0, BLASTER_SIZE * 1.25, 0)
				beam.CFrame   = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2) * CFrame.Angles(0, math.rad(90), 0)
				hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -mag/2)
				task.wait()
			end

			beamActive = false
			TS:Create(beam, TweenInfo.new(0.2), {Size = Vector3.new(mag, 0, 0)}):Play()
			TS:Create(GB,   TweenInfo.new(0.3), {Transparency = 1}):Play()
			task.wait(0.3)
			beam:Destroy() hitbox:Destroy() GB:Destroy()
		end)
	end

	local NUM_CIRCLE_BLASTERS = 6
	for i = 1, NUM_CIRCLE_BLASTERS do
		SpawnPersistentCircleBlaster((i - 1) * (360 / NUM_CIRCLE_BLASTERS))
	end

	task.spawn(function()
		local ROTATION_SPEED = 2 * 1.25 -- Speed of rotation (customizable)
		while fakeActive do
			if _G.CancelAttackTrigger then break end
			fakeAngle = (fakeAngle + ROTATION_SPEED) % 360
			task.wait(0.05 / 1.25)
		end
	end)

	local fakeIterations = math.floor(23 / 1.25)
	for sec = 1, fakeIterations do
		if _G.CancelAttackTrigger then break end
		local activeTarget = pickTarget()
		if not activeTarget then break end

		task.spawn(function()
			local spawnHeight = 1.2
			local blSize = 0.7

			if sec % 2 == 1 then
				local b1_start = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, -28), center + Vector3.new(28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)
				local b1_end = CFrame.lookAt(center + Vector3.new(-28, spawnHeight, 28), center + Vector3.new(28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)

				local b2_start = CFrame.lookAt(center + Vector3.new(28, spawnHeight, 28), center + Vector3.new(-28, spawnHeight, 28)) * CFrame.new(0, blSize*1.25, 0)
				local b2_end = CFrame.lookAt(center + Vector3.new(28, spawnHeight, -28), center + Vector3.new(-28, spawnHeight, -28)) * CFrame.new(0, blSize*1.25, 0)

				SummonSweepingMiniblaster(b1_start, b1_end, blSize, 1.2)
				SummonSweepingMiniblaster(b2_start, b2_end, blSize, 1.2)
			end

			local aimPos = getAimPos()
			local bpSpawn = aimPos + Vector3.new(0, 30, 0)
			SummonModernBlaster(bpSpawn, bpSpawn, aimPos, 3)
		end)
		task.wait(0.66 / 1.25)
	end

	fakeActive = false
	_G.FinalCinematicBlasterMult = 1.0
	task.wait(1.0)

	-- ========================================================
	-- [STAGE 4]: PLATFORM TRAP ATTACK (GIGANTIC BONE VARIANT)
	-- ========================================================
	if boxGroup then boxGroup:Destroy() end
	pcall(function() Humanoid.WalkSpeed = 16 end)
	_G.ForceBoneZoneVariant = "giant"
	attack = false
	Attack_BoneZone(true)
	attack = true

	-- ========================================================
	-- [STAGE 5]: THE MIDDLE AREA CORNER-TRAPPING BLASTER ATTACK
	-- ========================================================
	boxGroup = Instance.new("Model", Effects)
	local s, h, t = 60, 50, 0.5 
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(0, h, 0), Vector3.new(s, t, s)) -- Invisible roof

	pcall(function() Humanoid.WalkSpeed = 0 end)

	if targetHum and targetHum.Parent:FindFirstChild("HumanoidRootPart") then
		targetHum.Parent.HumanoidRootPart.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))
	end

	task.wait(0.5)

	local middleActive = true

	-- CUBE PORTION: Create 4 persistent Gaster Blasters + restricting laser beams to lock down corners!
	local function SpawnCubeRestrictingBeam(p1, p2)
		task.spawn(function()
			local dist = (p1 - p2).Magnitude
			local mid = (p1 + p2) / 2

			-- The Laser beam part (Majestic Cylinder, matching the glorious big Gaster Blaster beams!)
			local beam = Instance.new("Part", boxGroup)
			beam.Color, beam.Material = Color3.new(1,1,1), Enum.Material.Neon
			beam.Shape = Enum.PartType.Cylinder
			beam.Size = Vector3.new(dist, 0, 0) -- Starts at 0 density, scales up smoothly
			beam.CFrame = CFrame.lookAt(mid, p2) * CFrame.Angles(0, math.rad(90), 0)
			beam.Anchored, beam.CanCollide = true, false

			-- The physical blaster model/part (fully persistent visual)
			local GB = Instance.new("Part", boxGroup)
			GB.Anchored, GB.CanCollide, GB.Massless = true, false, true
			GB.Material, GB.BrickColor = Enum.Material.SmoothPlastic, BrickColor.new("White")
			local sm = Instance.new("SpecialMesh", GB)
			sm.MeshType, sm.MeshId = Enum.MeshType.FileMesh, "rbxassetid://2649585735"
			sm.Scale = Vector3.new(0, 0, 0)

			local Charge = Instance.new("Sound", GB)
			Charge.SoundId, Charge.Volume = "rbxassetid://482211201", 1.5
			Charge:Play()

			local size = 3.5 -- Big sized blasters (customizable)
			local aimCF = CFrame.lookAt(p1, p2)
			local blasterCenterCF = aimCF * CFrame.new(0, size * 1.25, 0)

			TS:Create(GB, TweenInfo.new(0.4, Enum.EasingStyle.Back), {CFrame = blasterCenterCF}):Play()
			TS:Create(sm, TweenInfo.new(0.4), {Scale = Vector3.new(size, size, size)}):Play()
			task.wait(0.45)

			sm.MeshId = "rbxassetid://2649597177"
			task.wait(0.05)
			sm.MeshId = "rbxassetid://2649610132" -- Mouth fully open

			local Fire = Instance.new("Sound", GB)
			Fire.SoundId, Fire.Volume, Fire.Looped = "rbxassetid://340722848", 2.2, true
			Fire:Play()

			-- Align the beam with the open mouth of the blaster!
			local beamOffsetY = -size * 1.25
			beam.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -dist/2) * CFrame.Angles(0, math.rad(90), 0)

			-- Tween the Cylinder to look thick, round, and absolutely majestic
			TS:Create(beam, TweenInfo.new(0.15), {Size = Vector3.new(dist, size * 2.5, size * 2.5)}):Play()

			local hitbox = Instance.new("Part", boxGroup)
			hitbox.Size = Vector3.new(size * 2.5, 6.0, dist)
			hitbox.CFrame = GB.CFrame * CFrame.new(0, beamOffsetY, -dist/2)
			hitbox.Anchored, hitbox.CanCollide, hitbox.Transparency = true, false, 1

			local trailActive = true
			task.spawn(function()
				local hitCache = {}
				local params = OverlapParams.new() params.FilterDescendantsInstances = {Character, Effects}
				while middleActive and trailActive do
					for _, p in ipairs(workspace:GetPartsInPart(hitbox, params)) do
						local hum = p.Parent:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent ~= Character then
							if not hitCache[hum] or (tick() - hitCache[hum]) >= 0.15 then
								hitCache[hum] = tick()
								_G.ApplyKarmaHit(hum, 1.5)
							end
						end
					end
					task.wait(0.05)
				end
			end)

			while middleActive do
				if _G.CancelAttackTrigger then break end
				task.wait(0.1)
			end
			trailActive = false
			Fire:Stop()
			TS:Create(sm, TweenInfo.new(0.3), {Scale = Vector3.new(0, 0, 0)}):Play()
			TS:Create(beam, TweenInfo.new(0.3), {Size = Vector3.new(dist, 0, 0)}):Play()
			task.wait(0.3)
			GB:Destroy() beam:Destroy() hitbox:Destroy()
		end)
	end

	-- Spawn the diagonal corner/cross blasters before the persistent corner cube blasters as requested!
	SummonModernBlaster(center + Vector3.new(0, 1.5, -28) + Vector3.new(0, 10, 0), center + Vector3.new(0, 1.5, -28), center + Vector3.new(0, 1.5, 28), 3)
	SummonModernBlaster(center + Vector3.new(0, 1.5, 28) + Vector3.new(0, 10, 0), center + Vector3.new(0, 1.5, 28), center + Vector3.new(0, 1.5, -28), 3)
	SummonModernBlaster(center + Vector3.new(28, 1.5, 0) + Vector3.new(0, 10, 0), center + Vector3.new(28, 1.5, 0), center + Vector3.new(-28, 1.5, 0), 3)
	SummonModernBlaster(center + Vector3.new(-28, 1.5, 0) + Vector3.new(0, 10, 0), center + Vector3.new(-28, 1.5, 0), center + Vector3.new(28, 1.5, 0), 3)

	task.wait(1.5)

	SummonModernBlaster(center + Vector3.new(24, 1.5, -24) + Vector3.new(0, 10, 0), center + Vector3.new(24, 1.5, -24), center + Vector3.new(-24, 1.5, 24), 2)
	SummonModernBlaster(center + Vector3.new(-24, 1.5, -24) + Vector3.new(0, 10, 0), center + Vector3.new(-24, 1.5, -24), center + Vector3.new(24, 1.5, 24), 2)
	SummonModernBlaster(center + Vector3.new(24, 1.5, 24) + Vector3.new(0, 10, 0), center + Vector3.new(24, 1.5, 24), center + Vector3.new(-24, 1.5, -24), 2)
	SummonModernBlaster(center + Vector3.new(-24, 1.5, 24) + Vector3.new(0, 10, 0), center + Vector3.new(-24, 1.5, 24), center + Vector3.new(24, 1.5, -24), 2)

	task.wait(1.5)

	-- Customize the cubic blaster offsets from the center here
	local CUBIC_OFFSET_X = s/2 - (3.5 * 2.5)/2
	local CUBIC_OFFSET_Z = s/2 - (3.5 * 2.5)/2
	local CUBIC_HEIGHT = 1.5

	local c1 = center + Vector3.new(-CUBIC_OFFSET_X, CUBIC_HEIGHT, -CUBIC_OFFSET_Z)
	local c2 = center + Vector3.new(CUBIC_OFFSET_X, CUBIC_HEIGHT, -CUBIC_OFFSET_Z)
	local c3 = center + Vector3.new(CUBIC_OFFSET_X, CUBIC_HEIGHT, CUBIC_OFFSET_Z)
	local c4 = center + Vector3.new(-CUBIC_OFFSET_X, CUBIC_HEIGHT, CUBIC_OFFSET_Z)

	SpawnCubeRestrictingBeam(c1, c2)
	SpawnCubeRestrictingBeam(c2, c3)
	SpawnCubeRestrictingBeam(c3, c4)
	SpawnCubeRestrictingBeam(c4, c1)

	task.spawn(function()
		local CIRCLE_RADIUS = 35 -- Spawns outside the 60x60 arena boundary (customizable)
		local BLASTER_AIM_HEIGHT = 1.5
		local BLASTER_SPAWN_DEPTH = -10
		local BLASTER_ANGLE_STEP = 25 -- Match standard G-key circle blasters (customizable)
		local BLASTER_FIRE_RATE = 0.15 -- Match standard G-key circle blasters (customizable)
		local BLASTER_SIZE = 1.2 -- Match other circle blasters (customizable)

		local currentAngle = 0
		while middleActive do
			if _G.CancelAttackTrigger then break end
			local c_ang = math.rad(currentAngle)
			local spawnPos = center + Vector3.new(math.cos(c_ang)*CIRCLE_RADIUS, BLASTER_SPAWN_DEPTH, math.sin(c_ang)*CIRCLE_RADIUS)
			local aimPos = center + Vector3.new(math.cos(c_ang)*CIRCLE_RADIUS, BLASTER_AIM_HEIGHT, math.sin(c_ang)*CIRCLE_RADIUS)

			local target = GetClosestTarget(center, 70) or pickTarget()
			local finalPos = center + Vector3.new(0, BLASTER_AIM_HEIGHT, 0)
			if target and target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") then
				local pPos = target.Parent.HumanoidRootPart.Position
				finalPos = Vector3.new(pPos.X, center.Y + BLASTER_AIM_HEIGHT, pPos.Z)
			end

			SummonModernBlaster(spawnPos, aimPos, finalPos, BLASTER_SIZE)
			currentAngle = currentAngle + BLASTER_ANGLE_STEP
			task.wait(BLASTER_FIRE_RATE)
		end
	end)

	task.spawn(function()
		while middleActive do
			if _G.CancelAttackTrigger then break end
			-- 🌟 RECENT REQUEST: Dynamically spawn blue bones in cinematic attack!
			local isBlue = (math.random() > 0.6)
			SummonModernBone(CFrame.new(center + Vector3.new(math.random(-12,12), 25, math.random(-12,12))) * CFrame.Angles(math.rad(-90),0,0), Vector3.new(0.08, 0.08, 0.08), true, 4, 0.8, nil, nil, isBlue)
			task.wait(1.2)
		end
	end)

	task.wait(12)
	middleActive = false
	task.wait(1.0)

	-- ========================================================
	-- [STAGE 6]: PLATFORM MOVING ATTACK (3D PLATFORM SLIDING ATTACK)
	-- ========================================================
	if boxGroup then boxGroup:Destroy() end
	pcall(function() Humanoid.WalkSpeed = 16 end)
	_G.ForceBoneZoneVariant = "platform"
	attack = false
	Attack_BoneZone(true)
	attack = true

	-- ========================================================
	-- [STAGE 7]: SANS TIRED EXPRESSION & DIABOLICAL GRAVITY FLIP
	-- ========================================================
	Expression.Texture = "rbxassetid://4484405390"
	chatfunc("* whew... you really... hold on...")
	task.wait(2.5)

	boxGroup = Instance.new("Model", Effects)
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(0, 0, -s/2), Vector3.new(s+t, t, t))
	makeGroundLine(CFrame.new(center) * CFrame.new(s/2, 0, 0), Vector3.new(t, t, s+t))
	makeGroundLine(CFrame.new(center) * CFrame.new(-s/2, 0, 0), Vector3.new(t, t, s+t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(0, h/2, -s/2), Vector3.new(s, h, t))
	makeWall(CFrame.new(center) * CFrame.new(s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(-s/2, h/2, 0), Vector3.new(t, h, s))
	makeWall(CFrame.new(center) * CFrame.new(0, h, 0), Vector3.new(s, t, s)) -- Invisible roof prevents voiding out of arena!

	local activeTarget = pickTarget()
	if activeTarget and activeTarget.Parent and activeTarget.Parent:FindFirstChild("HumanoidRootPart") then
		local tHRP = activeTarget.Parent.HumanoidRootPart
		tHRP.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))

		local startCF = rootPart.CFrame * CFrame.new(0, 15, 0) * CFrame.Angles(math.rad(-90),0,0)
		SummonModernBone(startCF, Vector3.new(0.07, 0.07, 0.07), true, 25, 0.7)

		-- RECENT REQUEST: Added beautiful blaster shower targeting gravity flipping player!
		local s7BlastersActive = true
		task.spawn(function()
			while s7BlastersActive and tHRP.Parent and activeTarget.Health > 0 do
				if _G.CancelAttackTrigger then break end
				task.wait(0.8)
				local pPos = tHRP.Position
				local randOffset = Vector3.new(math.random(-25, 25), math.random(10, 30), math.random(-25, 25))
				local spawnPos = center + randOffset
				SummonModernBlaster(spawnPos + Vector3.new(0, 10, 0), spawnPos, pPos, 1.25)
			end
		end)

		local wallDist = 30
		local pOffset = 2.5
		local standingPos = wallDist - pOffset
		local surfPos = wallDist
		local realGravity = workspace.Gravity

		local savedWalkSpeed = activeTarget.WalkSpeed
		local savedJumpPower = activeTarget.JumpPower
		local savedAutoRotate = activeTarget.AutoRotate
		local savedPlatformStand = activeTarget.PlatformStand
		local savedUseJumpPower = activeTarget.UseJumpPower
		local savedJumpHeight = activeTarget.JumpHeight

		activeTarget.PlatformStand = false
		activeTarget.AutoRotate = false
		activeTarget.WalkSpeed = math.max(savedWalkSpeed, 16)
		pcall(function() activeTarget.UseJumpPower = true end)
		activeTarget.JumpPower = math.max(savedJumpPower, 50)
		pcall(function() activeTarget.JumpHeight = math.max(savedJumpHeight, 7.2) end)
		pcall(function() activeTarget:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)

		local soulGui = Instance.new("BillboardGui", tHRP)
		soulGui.Name = "DecorativeSoul"
		soulGui.Size = UDim2.new(1.8, 0, 1.8, 0)
		soulGui.AlwaysOnTop = true
		local soulImg = Instance.new("ImageLabel", soulGui)
		soulImg.Size = UDim2.new(1, 0, 1, 0)
		soulImg.BackgroundTransparency = 1
		soulImg.Image = "rbxassetid://338425795"

		local function getTargetMass()
			local m = 0
			for _, p in ipairs(activeTarget.Parent:GetDescendants()) do
				if p:IsA("BasePart") and not p.Massless then m = m + p:GetMass() end
			end
			return math.max(m, 1)
		end

		local gravForce = Instance.new("BodyForce", tHRP)
		gravForce.Name = "WallGravityForce"
		gravForce.Force = Vector3.new(0, 0, 0)

		local gravGyro = Instance.new("BodyGyro", tHRP)
		gravGyro.Name = "WallGravityGyro"
		gravGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		gravGyro.P, gravGyro.D = 1e5, 500
		gravGyro.CFrame = tHRP.CFrame

		local wallVelocity = Instance.new("BodyVelocity", tHRP)
		wallVelocity.Name = "WallControlVelocity"
		wallVelocity.MaxForce = Vector3.new(0, 0, 0)
		wallVelocity.P = 6000
		wallVelocity.Velocity = Vector3.new(0, 0, 0)

		local walkAnim = Instance.new("Animation")
		if activeTarget.RigType == Enum.HumanoidRigType.R15 then
			walkAnim.AnimationId = "rbxassetid://507777826"
		else
			walkAnim.AnimationId = "rbxassetid://180426354"
		end
		local wallWalkTrack
		pcall(function()
			wallWalkTrack = activeTarget:LoadAnimation(walkAnim)
			wallWalkTrack.Looped = true
			wallWalkTrack.Priority = Enum.AnimationPriority.Movement
		end)

		local function getWallNormal(currentWall)
			if currentWall == 2 then return Vector3.new(0, 0, -1)
			elseif currentWall == 3 then return Vector3.new(-1, 0, 0)
			elseif currentWall == 4 then return Vector3.new(1, 0, 0)
			else return Vector3.new(0, 1, 0) end
		end

		local function getWallMaxForce(currentWall)
			if currentWall == 2 then return Vector3.new(1e5, 1e5, 0)
			elseif currentWall == 3 or currentWall == 4 then return Vector3.new(0, 1e5, 1e5)
			else return Vector3.new(0, 0, 0) end
		end

		local function getWallMoveVelocity(currentWall)
			local move = activeTarget.MoveDirection
			if move.Magnitude < 0.05 then return Vector3.new(0, 0, 0) end
			local desired
			if currentWall == 1 then
				desired = Vector3.new(move.X, 0, move.Z)
			else
				local normal = getWallNormal(currentWall)
				local projected = move - normal * move:Dot(normal)
				local remapped
				if currentWall == 2 then
					remapped = Vector3.new(-move.X, -move.Z, 0)
				elseif currentWall == 3 or currentWall == 4 then
					remapped = Vector3.new(0, move.Z, -move.X)
				end
				if projected.Magnitude > remapped.Magnitude then desired = projected else desired = remapped end
			end
			if not desired or desired.Magnitude < 0.05 then return Vector3.new(0, 0, 0) end
			return desired.Unit * activeTarget.WalkSpeed
		end

		local function updateWallWalkAnimation(moveVel)
			if not wallWalkTrack then return end
			if moveVel.Magnitude > 1 then
				if not wallWalkTrack.IsPlaying then pcall(function() wallWalkTrack:Play(0.12, 1, 1) end) end
				pcall(function() wallWalkTrack:AdjustSpeed(math.clamp(moveVel.Magnitude / 16, 0.6, 1.7)) end)
			else
				if wallWalkTrack.IsPlaying then pcall(function() wallWalkTrack:Stop(0.15) end) end
			end
		end

		local lastWallJump = 0
		local function isCloseToSurface(currentWall)
			local pos = tHRP.Position
			if currentWall == 2 then return pos.Z <= center.Z - standingPos + 2.2
			elseif currentWall == 3 then return pos.X <= center.X - standingPos + 2.2
			elseif currentWall == 4 then return pos.X >= center.X + standingPos - 2.2
			else return activeTarget.FloorMaterial ~= Enum.Material.Air end
		end

		local function tryWallJump(currentWall)
			if not activeTarget.Jump then return end
			if tick() - lastWallJump < 0.35 then return end
			if not isCloseToSurface(currentWall) then return end
			lastWallJump = tick()
			activeTarget.Jump = false
			local jumpPower = math.max(activeTarget.JumpPower, savedJumpPower, 50)
			local fakeUp = (currentWall == 1) and Vector3.new(0, 1, 0) or -getWallNormal(currentWall)
			tHRP.AssemblyLinearVelocity = tHRP.AssemblyLinearVelocity + fakeUp * jumpPower
			pcall(function() activeTarget:ChangeState(Enum.HumanoidStateType.Jumping) end)
		end

		local function controlledWait(duration, currentWall, gyroTarget)
			local finish = tick() + duration
			while tick() < finish do
				if not tHRP.Parent or activeTarget.Health <= 0 then break end
				local moveVel = getWallMoveVelocity(currentWall)
				wallVelocity.Velocity = moveVel
				updateWallWalkAnimation(moveVel)
				tryWallJump(currentWall)
				if gyroTarget then gravGyro.CFrame = gyroTarget end
				pcall(function() activeTarget:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
				task.wait()
			end
		end

		local wallCycle = {2, 3, 4, 1}
		for _, currentWall in ipairs(wallCycle) do
			if not tHRP.Parent or activeTarget.Health <= 0 then break end
			local totalMass = getTargetMass()
			local rot, gyroTarget

			if currentWall == 1 then
				rot = CFrame.new(center + Vector3.new(0, 2.5, 0))
				gyroTarget = rot
				gravForce.Force = Vector3.new(0, 0, 0)
				wallVelocity.MaxForce = Vector3.new(0, 0, 0)
			elseif currentWall == 2 then
				local pos = center + Vector3.new(0, 7.5, -standingPos)
				rot = CFrame.fromMatrix(pos, Vector3.new(1, 0, 0), Vector3.new(0, 0, 1))
				gyroTarget = rot
				gravForce.Force = Vector3.new(0, totalMass * realGravity, -totalMass * realGravity)
				wallVelocity.MaxForce = getWallMaxForce(currentWall)
			elseif currentWall == 3 then
				local pos = center + Vector3.new(-standingPos, 7.5, 0)
				rot = CFrame.fromMatrix(pos, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0))
				gyroTarget = rot
				gravForce.Force = Vector3.new(-totalMass * realGravity, totalMass * realGravity, 0)
				wallVelocity.MaxForce = getWallMaxForce(currentWall)
			elseif currentWall == 4 then
				local pos = center + Vector3.new(standingPos, 7.5, 0)
				rot = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0))
				gyroTarget = rot
				gravForce.Force = Vector3.new(totalMass * realGravity, totalMass * realGravity, 0)
				wallVelocity.MaxForce = getWallMaxForce(currentWall)
			end

			gravGyro.CFrame = gyroTarget
			tHRP.CFrame = rot
			tHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			wallVelocity.Velocity = Vector3.new(0, 0, 0)

			local slamSnd = Instance.new("Sound", tHRP)
			slamSnd.SoundId, slamSnd.Volume = "rbxassetid://131238474", 2.5
			slamSnd:Play()
			game.Debris:AddItem(slamSnd, 1)

			for i = 1, 5 do
				if not tHRP.Parent or activeTarget.Health <= 0 then break end
				local boneCF
				local pPos = tHRP.Position
				if currentWall == 1 then
					boneCF = CFrame.new(pPos.X, center.Y, pPos.Z)
				elseif currentWall == 2 then
					boneCF = CFrame.new(pPos.X, pPos.Y, center.Z - surfPos) * CFrame.Angles(math.rad(90), 0, 0)
				elseif currentWall == 3 then
					boneCF = CFrame.new(center.X - surfPos, pPos.Y, pPos.Z) * CFrame.Angles(0, 0, math.rad(-90))
				elseif currentWall == 4 then
					boneCF = CFrame.new(center.X + surfPos, pPos.Y, pPos.Z) * CFrame.Angles(0, 0, math.rad(90))
				end
				WarnAndRise(boneCF, 0, 7, 7, "Rise", 0.2, false)
				controlledWait(1.5, currentWall, gyroTarget)
			end
			controlledWait(0.3, currentWall, gyroTarget)
		end

		s7BlastersActive = false
		if wallWalkTrack then pcall(function() wallWalkTrack:Stop(0.1) wallWalkTrack:Destroy() end) end
		if walkAnim then walkAnim:Destroy() end
		if wallVelocity and wallVelocity.Parent then wallVelocity:Destroy() end
		if gravForce and gravForce.Parent then gravForce:Destroy() end
		if gravGyro and gravGyro.Parent then gravGyro:Destroy() end
		if soulGui and soulGui.Parent then soulGui:Destroy() end
		task.wait(0.5)
		activeTarget.WalkSpeed = savedWalkSpeed
		activeTarget.JumpPower = savedJumpPower
		pcall(function() activeTarget.UseJumpPower = savedUseJumpPower end)
		pcall(function() activeTarget.JumpHeight = savedJumpHeight end)
		activeTarget.AutoRotate = savedAutoRotate
		activeTarget.PlatformStand = savedPlatformStand
		tHRP.Anchored = false
	end

	-- ========================================================
	-- [STAGE 8]: BONE WAVES & BLASTER SHOWER
	-- ========================================================
	local showerActive = true

	-- Blue bone wall sweeps during Stage 8
	task.delay(2, function()
		if showerActive and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 3.2)
		end
	end)
	task.delay(8, function()
		if showerActive and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Back", 3.2)
		end
	end)

	task.spawn(function()
		for i = 1, 12 do
			if not showerActive or _G.CancelAttackTrigger then break end
			local pPos = getBodyAimPos()
			local hoverPos = pPos + Vector3.new(math.random(-25, 25), 20, math.random(-25, 25))
			SummonModernBlaster(hoverPos + Vector3.new(0, 15, 0), hoverPos, pPos, 1.5)
			task.wait(0.5)
		end
	end)

	for w = 1, 5 do
		if _G.CancelAttackTrigger then break end
		local pPos = getAimPos()
		-- RECENT REQUEST: Use the actual majestic bone wave function here!
		WarnAndRise(pPos, math.random(0, 360), 45, 5, "Wave")
		task.wait(1.2)
	end
	showerActive = false
	task.wait(1.0)

	-- ========================================================
	-- [STAGE 9]: TELEPORT ASSAULTS
	-- ========================================================
	for t1 = 1, 5 do
		if _G.CancelAttackTrigger then break end
		attack = false
		Attack_TeleportVariant1(center, s)
		attack = true
		task.wait(1.0) -- RECENT REQUEST: 1s delay
	end

	for t2 = 1, 3 do
		if _G.CancelAttackTrigger then break end
		attack = false
		Attack_TeleportVariant2(center, s)
		attack = true

		-- Wait for the attack to actually start spawning bones
		task.wait(2.0)

		-- Dynamically wait until all homing bones are gone from the workspace
		local boneCheckActive = true
		local startTime = tick()
		while boneCheckActive and (tick() - startTime < 12) do
			boneCheckActive = false
			for _, obj in pairs(Effects:GetChildren()) do
				if obj:IsA("Part") and obj.Name == "HomingBone" then
					boneCheckActive = true
					break
				end
			end
			if boneCheckActive then task.wait(0.1) end
		end
		task.wait(0.5) -- Tiny comfortable breather once cleared
	end

	-- ========================================================
	-- [STAGE 10]: BRUTAL SLAM VARIANT #1 AGAINST THE WALLS OF THE BOX
	-- ========================================================
	local finalTarget = pickTarget()
	if finalTarget and finalTarget.Parent and finalTarget.Parent:FindFirstChild("HumanoidRootPart") then
		local tHRP = finalTarget.Parent.HumanoidRootPart
		tHRP.Anchored = true

		local smashDuration = 8
		local smashesPerSec = 3
		local totalSmashes = smashDuration * smashesPerSec
		local damagePerSmash = 80 / totalSmashes

		_G.EyesOff = false
		_G.EyeUpdateDelay = 0.05
		Expression.Texture = "rbxassetid://4484448817"

		for smash = 1, totalSmashes do
			if not tHRP.Parent or finalTarget.Health <= 0 then break end

			local elevateCF = CFrame.new(center) * CFrame.new(0, 12, 0)
			TS:Create(tHRP, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = elevateCF}):Play()

			task.spawn(function()
				RA_Weld.C0 = RA_Weld.C0:Lerp(c_new(1.4, 0.5, -0.6) * c_angles(math.rad(120), math.rad(math.random(-8,8)), math.rad(-8)), 0.5)
				Torso_Weld.C0 = Torso_Weld.C0:Lerp(c_new(0, -1, 0) * c_angles(math.rad(5), 0, 0), 0.3)
				swait(2)
			end)
			task.wait(0.12)

			local currentWall = math.random(1, 4)
			local targetSlamCF
			local wallDist = 30
			local pOffset = 2.5

			if currentWall == 1 then
				targetSlamCF = CFrame.new(center) * CFrame.new(0, 1.5, 0)
			elseif currentWall == 2 then
				targetSlamCF = CFrame.new(center) * CFrame.new(0, 7.5, -(wallDist - pOffset)) * CFrame.Angles(math.rad(90), 0, 0)
			elseif currentWall == 3 then
				targetSlamCF = CFrame.new(center) * CFrame.new(-(wallDist - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(-90))
			elseif currentWall == 4 then
				targetSlamCF = CFrame.new(center) * CFrame.new((wallDist - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(90))
			end

			TS:Create(tHRP, TweenInfo.new(0.08, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = targetSlamCF}):Play()

			task.spawn(function()
				for i=1, 3 do
					local rx, ry, rz = math.random(-15, 15), math.random(-5, 5), math.random(-10, 10)
					RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.5, -0.6) * c_angles(math.rad(rx), math.rad(ry), math.rad(rz)), 0.6)
					Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.05, 0) * c_angles(math.rad(math.random(-3,3)), math.rad(math.random(-3,3)), 0), 0.6)
					swait()
				end
			end)

			finalTarget.Health = finalTarget.Health - damagePerSmash
			_G.ApplyKarmaHit(finalTarget)
			local slamSnd = Instance.new("Sound", tHRP)
			slamSnd.SoundId, slamSnd.Volume = "rbxassetid://131238474", 2.5
			slamSnd:Play()
			game.Debris:AddItem(slamSnd, 1)

			task.wait(0.2)
		end

		if tHRP.Parent and finalTarget.Health > 0 then
			tHRP.Anchored = false
			task.wait(0.5)
		end
	end

	-- ========================================================
	-- [STAGE 10 PAUSE AND DIALOGUE]
	-- ========================================================
	_G.heavilyBreathing = true
	Expression.Texture = "rbxassetid://4484447540" -- Sweating / tired face
	task.wait(5.0)
	Expression.Texture = "rbxassetid://4484448817" -- Determined face
	_G.heavilyBreathing = false
	chatfunc("* damn, you are a hard to chew bone!")
	task.wait(3.5)

	-- ========================================================
	-- [STAGE 11]: NORMAL CIRCLING BLASTERS (Non-Nerfed, 20s Straight)
	-- ========================================================
	local s11Active = true

	-- Blue bone wall sweeps during Stage 11
	task.delay(3, function()
		if s11Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 3.2)
		end
	end)
	task.delay(10, function()
		if s11Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Back", 3.2)
		end
	end)
	task.delay(16, function()
		if s11Active and _G.SpawnCinematicBlueBoneSweep then
			_G.SpawnCinematicBlueBoneSweep(boxGroup, center, "Front", 3.2)
		end
	end)

	task.spawn(function()
		local CIRCLE_RADIUS = 35 -- Spawns outside the 60x60 arena boundary (customizable)
		local BLASTER_AIM_HEIGHT = 1.5
		local BLASTER_SPAWN_DEPTH = -10
		local BLASTER_ANGLE_STEP = 25 -- Match standard G-key circle blasters (customizable)
		local BLASTER_FIRE_RATE = 0.15 -- Match standard G-key circle blasters (customizable)
		local BLASTER_SIZE = 1.6 -- Customizable size

		local currentAngle = 0
		while s11Active do
			if _G.CancelAttackTrigger then break end
			local c_ang = math.rad(currentAngle)
			local spawnPos = center + Vector3.new(math.cos(c_ang)*CIRCLE_RADIUS, BLASTER_SPAWN_DEPTH, math.sin(c_ang)*CIRCLE_RADIUS)
			local aimPos = center + Vector3.new(math.cos(c_ang)*CIRCLE_RADIUS, BLASTER_AIM_HEIGHT, math.sin(c_ang)*CIRCLE_RADIUS)

			local target = GetClosestTarget(center, 70) or pickTarget()
			local finalPos = center + Vector3.new(0, BLASTER_AIM_HEIGHT, 0)
			if target and target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") then
				local pPos = target.Parent.HumanoidRootPart.Position
				finalPos = Vector3.new(pPos.X, center.Y + BLASTER_AIM_HEIGHT, pPos.Z)
			end

			SummonModernBlaster(spawnPos, aimPos, finalPos, BLASTER_SIZE)
			currentAngle = currentAngle + BLASTER_ANGLE_STEP
			task.wait(BLASTER_FIRE_RATE)
		end
	end)
	task.wait(20.0)
	s11Active = false
	task.wait(1.0)

	-- ========================================================
	-- [STAGE 12]: SIDE BIG BLASTERS (10 Blasters, every 1.5s)
	-- ========================================================
	for b = 1, 10 do
		if _G.CancelAttackTrigger then break end
		local pPos = getBodyAimPos()
		local side = math.random(1, 4)
		local hoverPos
		local wallDist = 28
		if side == 1 then -- North Wall
			hoverPos = center + Vector3.new(math.random(-25, 25), 1.5, -wallDist)
		elseif side == 2 then -- South Wall
			hoverPos = center + Vector3.new(math.random(-25, 25), 1.5, wallDist)
		elseif side == 3 then -- West Wall
			hoverPos = center + Vector3.new(-wallDist, 1.5, math.random(-25, 25))
		elseif side == 4 then -- East Wall
			hoverPos = center + Vector3.new(wallDist, 1.5, math.random(-25, 25))
		end
		local spawnPos = hoverPos + Vector3.new(0, 15, 0)
		SummonModernBlaster(spawnPos, hoverPos, pPos, 3.5) -- GIGANTIC blasters!
		task.wait(1.5)
	end
	task.wait(1.0)

	-- ========================================================
	-- [STAGE 13]: BRUTAL SLAM VARIANT #1 (15 Seconds straight)
	-- ========================================================
	local lastTarget = pickTarget()
	if lastTarget and lastTarget.Parent and lastTarget.Parent:FindFirstChild("HumanoidRootPart") then
		local tHRP = lastTarget.Parent.HumanoidRootPart
		tHRP.Anchored = true

		local smashDuration = 15
		local smashesPerSec = 3
		local totalSmashes = smashDuration * smashesPerSec
		local damagePerSmash = 100 / totalSmashes -- Extreme threat damage

		_G.EyesOff = false
		_G.EyeUpdateDelay = 0.05
		Expression.Texture = "rbxassetid://4484448817"

		for smash = 1, totalSmashes do
			if not tHRP.Parent or lastTarget.Health <= 0 then break end

			local elevateCF = CFrame.new(center) * CFrame.new(0, 12, 0)
			TS:Create(tHRP, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = elevateCF}):Play()

			task.spawn(function()
				RA_Weld.C0 = RA_Weld.C0:Lerp(c_new(1.4, 0.5, -0.6) * c_angles(math.rad(120), math.rad(math.random(-8,8)), math.rad(-8)), 0.5)
				Torso_Weld.C0 = Torso_Weld.C0:Lerp(c_new(0, -1, 0) * c_angles(math.rad(5), 0, 0), 0.3)
				swait(2)
			end)
			task.wait(0.12)

			local currentWall = math.random(1, 4)
			local targetSlamCF
			local wallDist = 30
			local pOffset = 2.5

			if currentWall == 1 then
				targetSlamCF = CFrame.new(center) * CFrame.new(0, 1.5, 0)
			elseif currentWall == 2 then
				targetSlamCF = CFrame.new(center) * CFrame.new(0, 7.5, -(wallDist - pOffset)) * CFrame.Angles(math.rad(90), 0, 0)
			elseif currentWall == 3 then
				targetSlamCF = CFrame.new(center) * CFrame.new(-(wallDist - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(-90))
			elseif currentWall == 4 then
				targetSlamCF = CFrame.new(center) * CFrame.new((wallDist - pOffset), 7.5, 0) * CFrame.Angles(0, 0, math.rad(90))
			end

			TS:Create(tHRP, TweenInfo.new(0.08, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = targetSlamCF}):Play()

			task.spawn(function()
				for i=1, 3 do
					local rx, ry, rz = math.random(-15, 15), math.random(-5, 5), math.random(-10, 10)
					RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.5, -0.6) * c_angles(math.rad(rx), math.rad(ry), math.rad(rz)), 0.6)
					Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.05, 0) * c_angles(math.rad(math.random(-3,3)), math.rad(math.random(-3,3)), 0), 0.6)
					swait()
				end
			end)

			lastTarget.Health = lastTarget.Health - damagePerSmash
			_G.ApplyKarmaHit(lastTarget)
			local slamSnd = Instance.new("Sound", tHRP)
			slamSnd.SoundId, slamSnd.Volume = "rbxassetid://131238474", 2.5
			slamSnd:Play()
			game.Debris:AddItem(slamSnd, 1)

			task.wait(0.2)
		end

		if tHRP.Parent and lastTarget.Health > 0 then
			tHRP.Anchored = false
			SummonModernBlaster(center + Vector3.new(0, 45, 0), center + Vector3.new(0, 30, 0), center, 7)
			task.wait(2)
		end
	end

	-- ========================================================
	-- [FINAL END TRANSITION]: ORIGINAL RETIRED LOGIC SANS RETREATS
	-- ========================================================
	task.wait(2.5)
	Expression.Texture = "rbxassetid://4484405390"
	chatfunc("* whew...") task.wait(3)
	chatfunc("* i'm going to grillby's.") task.wait(3)

	Humanoid.WalkSpeed = 16
	boxGroup:Destroy()
	attack = false
end

-- ================================================= --
-- [[ 9. DODGING LOGIC & CHAT UI ]]
-- ================================================= --
dodging = false
candodge = true
canblock = false
blocking = false
talking = false
dialogue = 1
dialogue2 = 1

function chatfunc(text)
	local chat = coroutine.wrap(function()
		if Character:FindFirstChild("textboard")~= nil then
			Character:FindFirstChild("textboard"):destroy()
		end
		if Character:FindFirstChild("glitchboard")~= nil then
			Character:FindFirstChild("glitchboard"):destroy()
		end
		local naeeym2 = script.textboard:Clone()
		naeeym2.Parent = Character
		naeeym2.StudsOffset = Vector3.new(0,3,0)
		naeeym2.Adornee = Character.Head
		naeeym2.Enabled = true
		local naeeym3 = script.glitchboard:Clone()
		naeeym3.Parent = Character
		naeeym3.StudsOffset = Vector3.new(0,3,0)
		naeeym3.Adornee = Character.Head
		naeeym3.Enabled = true
		local tecks2 = naeeym2.TextLabel
		tecks2.Text = ""
		for i = 1,string.len(text),1 do
			if _G.CancelAttackTrigger then break end
			local heh = CreateSound("2469886818", Head, 5, 1)
			tecks2.Text = string.sub(text,1,i)
			if i ~= string.len(text) then
				local ADD = string.sub(text,i,i)
				if ADD == "." or ADD == "?" or ADD == "!" then
					bwait(24) -- ~0.4s
				elseif ADD == "," then
					bwait(12) -- ~0.2s
				end
			end
			bwait()
		end
		if not _G.CancelAttackTrigger then
			bwait(120) -- ~2s wait after text finished
		end
		naeeym2:Destroy()
		naeeym3:Destroy()
	end)
	chat()
end

local skipnum = 1
local nochat = false
local MSG
function onChatted(msg)
	if CurrentMode == "Transition" or CurrentMode == "Dead" then return end 
	if string.sub(string.lower(msg), 1, 3) == "/e " then
		msg = string.sub(msg, 4)
		nochat = true
		wait(1)
		nochat = false
	end
	if string.sub(string.lower(msg), 1, 5) == "skip/" then
		MSG = string.sub(msg, 6)
		if MSG == "0" then
			print("You can't do that.")
		else
			skipnum = MSG
			dialogue = skipnum
			print(dialogue)
		end
	end
	if nochat == false then
		chatfunc("* "..msg)
	end
end
Player.Chatted:connect(onChatted)

local Bbone = Instance.new("Part",Character)
Bbone.Name = "BlockBone" 
Bbone.CanCollide = false
Bbone.Size = Vector3.new(0.2, 2, 0.2)
Bbone.Massless = true
Bbone.Material = "SmoothPlastic"
Bbone.BrickColor = BrickColor.new("White")
Bbone.Anchored = false
Bbone.Transparency = 1
local BoneHandle = Instance.new("Weld", Bbone)
BoneHandle.Part0 = Right_Arm
BoneHandle.Part1 = Bbone
BoneHandle.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0.8, 0)
local zxc = Instance.new("SpecialMesh",Bbone)
zxc.MeshType = "FileMesh"
zxc.Scale = Vector3.new(0.012, 0.012, 0.012)
zxc.MeshId = "http://www.roblox.com/asset/?id=921085633"

function blocked()
	if Character:FindFirstChild("Phase2Weapon") then
		Character.Phase2Weapon.Transparency = 1
	end

	coroutine.wrap(function()
		local bBone = Character:FindFirstChild("BlockBone")
		for i = 1,30 do
			if bBone then bBone.Transparency = bBone.Transparency - 0.034 end
			local fx = Instance.new("Part",Effects)
			fx.Anchored = true
			fx.Color = Color3.new(0,0.6,0.5)
			fx.CanCollide = false
			fx.FormFactor = 3
			fx.Name = "Shockwave"
			fx.Material = "Neon"
			fx.Size = Vector3.new(1, 1, 1)
			fx.Transparency = 0.35
			fx.TopSurface = 0
			fx.BottomSurface = 0
			if bBone then fx.CFrame = bBone.CFrame else fx.CFrame = Character.Right_Arm.CFrame end
			fx.CFrame = fx.CFrame * CFrame.new(0,0,0) * CFrame.Angles(math.rad(math.random(-3600,3600)/10),math.rad(math.random(-360,-360)/10),math.rad(math.random(-3600,3600)/10))
			local fxm = Instance.new("SpecialMesh", fx)
			fxm.Scale = Vector3.new(0,0,0)
			fxm.Offset = Vector3.new(0,0,0)
			fxm.MeshType = "Sphere"
			spawn(function()
				for i = 1, 15, 1 do
					fxm.Scale = Vector3.new(0.25 - i*0.00416,.5  - i*0.0083 ,0.25 - i*0.00416)
					fx.CFrame = fx.CFrame * CFrame.new(0,0.5,0)
					fx.Transparency = i/15
					swait()
				end
				wait()
				fx:Destroy()
			end)
		end
	end)()

	wait(0.6)

	local bBone = Character:FindFirstChild("BlockBone")
	if bBone then bBone.Transparency = 1 end
	blocking = false
	if Character:FindFirstChild("Phase2Weapon") then
		Character.Phase2Weapon.Transparency = 0
	end
end

function miss()
	Animations = true
	local number = math.random(1,3)
	if number == 1 then
		for i = 0,0.08,0.01 do
			RA_Weld.C0		= clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(0),math.rad(0),math.rad(-120)), Sanim + 0.025)
			LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(0),math.rad(0),math.rad(120)), Sanim + 0.025)
			LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(-10)), Sanim)
			RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5 , 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(10)), Sanim)
			Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(-5 - math.sin(sine/15)/10, -0.95 + math.sin(sine/7.5)/5, -5) * c_angles(math.rad(17) + math.sin(sine/15)/10, math.rad(20),math.rad(0)), Sanim)
			Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0 - math.sin(sine/15)/6, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/5,math.rad(-20), math.rad(0) + math.sin(sine/15)/4), Sanim)
		end
	elseif number == 2 then
		for i = 0,0.08,0.01 do
			RA_Weld.C0		= clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(-20)), Sanim + 0.025)
			LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), Sanim + 0.025)
			LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(-10)), Sanim)
			RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5 , 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(10)), Sanim)
			Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(-5 - math.sin(sine/15)/10, -0.95 + math.sin(sine/7.5)/5, -5) * c_angles(math.rad(17) + math.sin(sine/15)/10, math.rad(20),math.rad(0)), Sanim)
			Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0 - math.sin(sine/15)/6, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/5,math.rad(-20), math.rad(0) + math.sin(sine/15)/4), Sanim)
		end
	elseif number == 3 then
		for i = 0,0.08,0.01 do
			RA_Weld.C0		= clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(-20)), Sanim + 0.025)
			LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), Sanim + 0.025)
			LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(-10)), Sanim)
			RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5 , 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(10)), Sanim)
			Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(5 - math.sin(sine/15)/10, -0.95 + math.sin(sine/7.5)/5, 5) * c_angles(math.rad(17) + math.sin(sine/15)/10, math.rad(-20),math.rad(0)), Sanim)
			Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0 - math.sin(sine/15)/6, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/5,math.rad(20), math.rad(0) + math.sin(sine/15)/4), Sanim)
		end
	end
	if CurrentMode ~= "Transition" and CurrentMode ~= "Timer" then
		Animations = false
	end
	dodging = false
end

function block()
	talking = true 
	blocking = true
	blockSlowdownEnd = tick() + 1 
	coroutine.resume(coroutine.create(function()
		if CurrentDodges == 20 then
			chatfunc("* blocked. you think a new weapon changes anything?")
		elseif CurrentDodges == 15 then
			chatfunc("* i've survived worse. much worse.")
		elseif CurrentDodges == 10 then
			chatfunc("* you're swinging pretty wide there, buddy.")
		elseif CurrentDodges == 5 then
			chatfunc("* huff... puff... getting a bit heavy...")
		elseif CurrentDodges == 0 then
			chatfunc("* my bone shield... it's shattering...")
		end

		wait(2)
		blocking = false
	end))
	blocked()
end

function dodge()
	talking = true 
	dodging = true
	coroutine.resume(coroutine.create(function()
		if CurrentDodges == 20 then
			chatfunc("* you're gonna have to try a little harder than that.")
		elseif CurrentDodges == 15 then
			chatfunc("* getting tired? 'cause i'm just getting started.")
		elseif CurrentDodges == 10 then
			chatfunc("* look, giving up now would save us both a lot of trouble.")
		elseif CurrentDodges == 5 then
			chatfunc("* huff... puff... you're really pushing it, kid.")
		elseif CurrentDodges == 0 then
			chatfunc("* welp. guess that's it for my dodging streak.")
		end

		wait(2)
		dodging = false
	end))
	miss()
end

-- ================================================= --
-- [[ 10. INPUT KEYBINDS ]]
-- ================================================= --
local isM1Held = false
_G.isSlamKeyHeld = false -- Made Global so Grab() can see it!

mouse.Button1Down:connect(function()
	isM1Held = true
	Grab()
end)

mouse.Button1Up:connect(function()
	isM1Held = false
	grabbing = false
	_G.isSlamKeyHeld = false -- Safety reset
end)

mouse.KeyUp:connect(function(key)
	heldKeys[key] = nil
	if key == "f" then rapid2 = false end
	if key == "r" then rapid = false end
	if key == "q" and debounce == true then rapid3 = false end
	if key == "z" then _G.isSlamKeyHeld = false end -- Detect Slam Key Release
	if key == "leftcontrol" or key == "rightcontrol" then isCtrlHeld = false end
end)

mouse.KeyDown:connect(function(key)
	heldKeys[key] = true
	if _G.SansOnPlatform then
		-- Only allow Q (Gaster Blasters), C (Bone Rise), X (Cancel), Z (Slam key detector), LeftControl/RightControl, LeftAlt/RightAlt
		if key ~= "q" and key ~= "c" and key ~= "x" and key ~= "z" and key ~= "leftcontrol" and key ~= "rightcontrol" and key ~= "leftalt" and key ~= "rightalt" then
			return
		end
	end

	-- Detect Slam Key Press
	if key == "z" then _G.isSlamKeyHeld = true end 
	if key == "leftcontrol" or key == "rightcontrol" then isCtrlHeld = true end

	if key == "space" and not jumpCooldown and currentAnim ~= "Falling" and currentAnim ~= "Jumping" then
		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			jumpCooldown = true
			Animations = true

			local jumpWaitTime = 1.5

			if Death2 == true then
				_G.isPhase3Jumping = true
				jumpWaitTime = 1.5

				local dragForce = Instance.new("BodyVelocity", rootPart)
				dragForce.Velocity = Vector3.new(0, 25, 0) 
				dragForce.MaxForce = Vector3.new(0, 100000, 0) 
				game:GetService("Debris"):AddItem(dragForce, 0.2) 

				Animations = false
				currentAnim = "Jumping"

				coroutine.wrap(function()
					task.wait(0.8)
					_G.isPhase3Jumping = false
				end)()

			elseif Death == true then
				jumpWaitTime = 1.5
				local p2w = Character:FindFirstChild("Phase2Weapon")
				local bWeld, bp, bg
				if p2w then
					bWeld = p2w:FindFirstChildOfClass("Weld")
					if bWeld then bWeld:Destroy() end
					bp = Instance.new("BodyPosition", p2w)
					bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bp.P = 30000
					bg = Instance.new("BodyGyro", p2w)
					bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				end

				for i = 1, 10 do
					if p2w then
						bp.Position = rootPart.Position + Vector3.new(0, -3.5, 0)
						bg.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
					end
					RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.8, -0.1) * c_angles(math.rad(160), 0, math.rad(-20)), 0.3)
					LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3, 0) * c_angles(math.rad(23), 0, math.rad(20)), 0.3)
					LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.5, -0.5) * c_angles(math.rad(-20), 0, 0), 0.3)
					RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.5) * c_angles(math.rad(-20), 0, 0), 0.3)
					Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1, 0) * c_angles(math.rad(-10), 0, 0), 0.3)
					Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0.1) * c_angles(math.rad(10), 0, 0), 0.3)
					swait()
				end

				rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 60, rootPart.Velocity.Z)
				coroutine.wrap(function()
					task.wait(1.2)
					if p2w and p2w.Parent then
						if bp then bp:Destroy() end
						if bg then bg:Destroy() end
						local nWeld = Instance.new("Weld", p2w)
						nWeld.Part0 = Right_Arm
						nWeld.Part1 = p2w
						nWeld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0.8, 0)
					end
				end)()

			else
				jumpWaitTime = 1.5 
				for i = 1, 10 do
					RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.5, 0) * c_angles(math.rad(40), 0, math.rad(-20)), 0.3)
					LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.5, 0) * c_angles(math.rad(40), 0, math.rad(20)), 0.3)
					LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.5, -0.5) * c_angles(math.rad(-40), 0, 0), 0.3)
					RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.5, -0.5) * c_angles(math.rad(-40), 0, 0), 0.3)
					Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1, 0) * c_angles(math.rad(-10), 0, 0), 0.3)
					Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0.1) * c_angles(math.rad(10), 0, 0), 0.3)
					swait()
				end
				rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 60, rootPart.Velocity.Z)
			end

			Animations = false
			currentAnim = "Jumping"

			if Death == true and Death2 == false then
				local ring = Instance.new("Part", realWorkspace)
				ring.Size = Vector3.new(1,0.1,1) ring.Shape = Enum.PartType.Cylinder ring.Color = Color3.new(0,0,1)
				ring.Material = Enum.Material.Neon ring.Anchored = true ring.CanCollide = false
				ring.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0) * CFrame.Angles(0,0,math.rad(90))
				coroutine.wrap(function()
					for i=1, 10 do ring.Size = ring.Size + Vector3.new(0,3,3) ring.Transparency = i/10 task.wait(0.03) end
					ring:Destroy()
				end)()
			end

			coroutine.wrap(function()
				task.wait(0.4)
				if Death2 == true then _G.isPhase3Jumping = false end
			end)()

			coroutine.wrap(function()
				task.wait(jumpWaitTime)
				jumpCooldown = false
			end)()
		end
	end

	if key == "x" then
		task.spawn(function()
			if _G.InTransition then
				_G.CancelAttackTrigger = true
				task.wait(0.1)
				_G.CancelAttackTrigger = false
				return
			end

			_G.CancelAttackTrigger = true

			-- Aggressive looping cleanup for 2 seconds to catch ongoing/spawning objects
			local startTime = tick()
			while tick() - startTime < 2 do
				local stuff = realWorkspace:FindFirstChild("Stuff") or Character:FindFirstChild("Stuff")
				if stuff then
					stuff:ClearAllChildren()
				end
				local effects = realWorkspace:FindFirstChild("Effects") or Character:FindFirstChild("Effects")
				if effects then
					for _, v in pairs(effects:GetChildren()) do
						if v.Name ~= "Point X" and v.Name ~= "Point XYZ" then
							v:Destroy()
						end
					end
				end

				-- IMMEDIATELY destroy chat boards if they exist
				if Character:FindFirstChild("textboard") then Character.textboard:Destroy() end
				if Character:FindFirstChild("glitchboard") then Character.glitchboard:Destroy() end
				if Character:FindFirstChild("TalkChat") then Character.TalkChat:Destroy() end
				for _, v in pairs(game.Players:GetPlayers()) do
					if v.Character and v.Character:FindFirstChild("TalkChat") then
						v.Character.TalkChat:Destroy()
					end
				end

				-- Stop all sounds in torso/head that might be cinematic
				for _, s in pairs(Torso:GetChildren()) do if s:IsA("Sound") and s.Name ~= "MusicTheme" then s:Stop() end end
				for _, s in pairs(Head:GetChildren()) do if s:IsA("Sound") then s:Stop() end end

				-- Reset standard flags to prevent them from getting stuck later
				attack = false
				attack2 = false
				Animations = false
				grabbing = false
				idle = idly -- Reset idle timer so he doesn't sleep

				task.wait(0.1)
			end

			_G.CancelAttackTrigger = false
		end)
	end

	-- Special Cinematic Teleport Back (Alt + E)
	if key == "e" and (heldKeys["leftalt"] or heldKeys["rightalt"]) then
		if attack and _G.CurrentArenaCenter then
			local tHum = GetClosestTarget(mouse.Hit.p, 30)
			if tHum and tHum.Parent and tHum.Parent:FindFirstChild("HumanoidRootPart") then
				local targetChar = tHum.Parent
				local hrp = targetChar.HumanoidRootPart
				
				-- Visual highlight effect on target
				local hl = Instance.new("Highlight", targetChar)
				hl.FillColor = Color3.fromRGB(0, 255, 255)
				hl.OutlineColor = Color3.fromRGB(0, 255, 255)
				game.Debris:AddItem(hl, 0.6)
				
				-- Sound effect on target and sans
				CreateSound("12222170", hrp, 5, 0.7)
				CreateSound("12222170", Head, 5, 0.7)
				
				-- Teleport target to center of box
				hrp.CFrame = CFrame.new(_G.CurrentArenaCenter + Vector3.new(0, 3, 0))
				
				-- Fun speech line from Sans!
				chatfunc("* where do you think you're going?")
				return
			end
		end
	end

	if CurrentMode == "Transition" or CurrentMode == "Dead" or attack then return end 

	-- THIS IS THE MAGIC FIX: It now uses M1 instead of jumping!
	local useVariant = isM1Held 

	if _G.ObbyActive then
		local allowed = false
		if (key == "q" or key == "g" or key == "h" or key == "t") then
			allowed = true
		elseif (key == "r" or key == "c") and not useVariant then
			allowed = true
		end
		
		if not allowed then
			return
		end
	end 

	if key == "v" then
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if isPhase2 then
			Attack_Invertion(useVariant)
		else
			Attack_FirstCinematic()
		end
	end
	if key == "e" then
		grabbing = false
		_G.isSlamKeyHeld = false
		local isCtrl = isCtrlHeld or heldKeys["leftcontrol"] or heldKeys["rightcontrol"]
		if isCtrl then
			Attack_TeleportVariant2()
		elseif isM1Held then
			Attack_TeleportVariant1()
		else
			teleport()
		end
	end
	if key == "l" and Death == false then Dead() end
	if key == "p" and Death2 == false then Dead2() end

	-- Passes the M1 state to the attacks!
	if key == "r" then Attack_HomingBone(useVariant) end
	if key == "c" then Attack_BoneRise(useVariant) end
	if key == "f" then 
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if isM1Held then
			_G.ForceBoneZoneVariant = "giant"
			Attack_BoneZone(true)
		elseif isCtrlHeld then
			_G.ForceBoneZoneVariant = "platform"
			Attack_BoneZone(true)
		else
			Attack_BoneZone(false)
		end
	end 
	if key == "u" then Attack_Platform(useVariant) end 
	if key == "q" then Attack_GBSingle(useVariant) end
	if key == "g" then Attack_GBShower(useVariant) end -- Passes M1 variant to Shower!
	if key == "h" then Attack_BigCircleBlasters(useVariant) end
	if key == "t" then Attack_Beam(useVariant) end
	if key == "b" then 
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if isPhase2 then
			Attack_BoxedBones()
		else
			Attack_FinalCinematic()
		end
	end
	if key == "n" then
		local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")
		if not isPhase2 then
			Attack_TrueFinalCinematic()
		end
	end

	-- FIX 2: Toggles the GUI properly!
	if key == "m" then
		if _G.SansMovesFrame then
			_G.SansMovesFrame.Visible = not _G.SansMovesFrame.Visible
		end
	end

	if key == "k" then
		if _G.SansDescFrame then
			_G.SansDescFrame.Visible = not _G.SansDescFrame.Visible
		end
		if _G.SansCombosFrame then
			_G.SansCombosFrame.Visible = not _G.SansCombosFrame.Visible
		end
	end

	if key == "y" then
		sansClothesEnabled = not sansClothesEnabled
		UpdateClothing()
		if sansClothesEnabled then chatfunc("* putting the jacket back on.") else chatfunc("* taking a breather.") end
	end
end)
-- ================================================= --
-- [[ 11. MAIN RUNSERVICE & IDLE LOGIC ]]
-- ================================================= --
coroutine.wrap(function()
	while true do 
		if currentAnim == "Idling" and attack == false and attack2 == false then
			idle=idle+1
			bwait()
		else
			idle=idly
			bwait()
		end
	end
end)()

local candie = false
local Zzz = Instance.new("ParticleEmitter",Head)
Zzz.EmissionDirection = "Left"
Zzz.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.3,0),NumberSequenceKeypoint.new(1,1)})
Zzz.LightEmission = 1
Zzz.Rate = 1
Zzz.ZOffset = 1
Zzz.Lifetime = NumberRange.new(2)
Zzz.Speed = NumberRange.new(2)
Zzz.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6, 0.3), NumberSequenceKeypoint.new(1, 0.2, 0.1)})
Zzz.Rotation = NumberRange.new(0, 0)
Zzz.RotSpeed = NumberRange.new(30, 30)
Zzz.Texture = "http://www.roblox.com/asset/?id=386098098"
Zzz.Color = ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1))
Zzz.VelocitySpread = 360
Zzz.LockedToPart = false
Zzz.Acceleration = Vector3.new(0,5,0)
Zzz.Enabled = false
local Shields = Instance.new("Folder", Character)
Shields.Name = "workspace"
teleporting = false
restriction = false

coroutine.wrap(function()
	while true and wait() do
		if  dedebounce == false and attack == false then
			Zzz.Enabled = false
			if Death2 == true then
				Expression.Texture = "rbxassetid://4239634623" 
				themeMoos.Volume = 5
				Sanim = 0.025
				themeMoos.PlaybackSpeed = 1
			elseif Death == true then
				if CurrentMode == "HP" then
					Expression.Texture = "rbxassetid://4484447540" 
				else
					Expression.Texture = "rbxassetid://4899271236"
					themeMoos.Volume = 5
					Sanim = 0.025
					themeMoos.PlaybackSpeed = 1
				end
			else
				if CurrentMode == "HP" then
					Expression.Texture = "rbxassetid://4484447540" 
				else
					Expression.Texture = "rbxassetid://4484405390" 
				end
				themeMoos.Volume = 5
				Sanim = 0.025
				themeMoos.PlaybackSpeed = 1
			end
		end
	end
end)()

local respawning = false
local Deaths = 1
function refit()
	rootJoint.Parent = rootPart
	Neck.Parent = Torso
	Right_Shoulder.Parent = Torso
	Left_Shoulder.Parent = Torso
	Right_Hip.Parent = Torso
	Left_Hip.Parent = Torso
	rootPart.Parent = Character
	Left_Arm.Parent = Character
	Right_Arm.Parent = Character
	LA_Weld.Parent = Left_Arm
	RA_Weld.Parent = Right_Arm
	Torso_Weld.Parent = Torso
	Head_Weld.Parent = Head
	LL_Weld.Parent = Left_Leg
	RL_Weld.Parent = Right_Leg
	Right_Leg.Parent = Character
	Left_Leg.Parent = Character
	Torso.Parent = Character
	Head.Parent = Character
end

Humanoid.Died:Connect(function()
	_G.SansOnPlatform = false
	heldKeys = {}
	if CurrentMode == "Dead" or Phase3Timer <= 0 then
		return
	end

	if candie == false then
		if respawning == false then
			respawning = true
			Humanoid.Parent = nil
			refit()
			Humanoid.Parent = Character
			CreateSound("2783295579", Head, 7, 1)
			chatfunc("* Did you think I would go down that easily?")
			Deaths = Deaths + 1
			respawning = false
		end
	end
end)
local HARDMODE = false

function special()
	specialattack = true
	while specialattack do
		local Special = Instance.new ("MeshPart", Shields) Special.Name = "Special" Special.CanCollide = false Special.Transparency = 1 Special.Material = "Neon" Special.BrickColor = BrickColor.new("Really red") Special.Size = Vector3.new(12,12,12) Special.Massless = true Special.CFrame = Character.Torso.CFrame
		local Wed = Instance.new("Weld", Special) Wed.Part0 = Special Wed.Part1 = Character.Torso
		Special.Touched:connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= nil and hit.Parent.Name ~= Character.Name then
				if hit.Parent.HumanoidRootPart ~= false then
					Special:Remove()
					restriction = true
					teleporting = true
					hit.Parent.HumanoidRootPart.CFrame=rootPart.CFrame*CFrame.new(0,0,-25)*CFrame.Angles(math.rad(0),math.rad(180),math.rad(0))
					CreateSound("446961725", Head, 7, 1)
					Humanoid.Health = Humanoid.MaxHealth
					idle=idly
					Expression.Texture = "rbxassetid://4484422735"
					swait(15)
					Expression.Texture = "rbxassetid://4484448817"
					swait(25)
					Expression.Texture = "rbxassetid://4484405390"
				end
			end
		end)
		coroutine.resume(coroutine.create(function()
			wait(1)
			Special:remove()
		end))
		game:GetService("RunService").RenderStepped:wait()
	end
end

local wasGlitching = false
local lastEyeUpdate = 0

game:GetService("RunService").Stepped:connect(function()
	Angle = (Angle % 100) + angleSpeed/10
	Axis = (Axis % 100) + axisSpeed/10


	-- TV STATIC EYES LOGIC (With Binary Swapping)
	if tick() - lastEyeUpdate >= (_G.EyeUpdateDelay or 0.1) then
		lastEyeUpdate = tick()
		if Character:FindFirstChild("StaticEyeL") and Character:FindFirstChild("StaticEyeR") then
			local lEye = Character.StaticEyeL
			local rEye = Character.StaticEyeR
			local lGlow = lEye:FindFirstChild("EyeGlow")
			local rGlow = rEye:FindFirstChild("EyeGlow")

			if _G.EyesOff then
				lEye.Transparency = 1
				rEye.Transparency = 1
				if lGlow then lGlow.Brightness = 0 end
				if rGlow then rGlow.Brightness = 0 end
			else
				lEye.Transparency = 0
				rEye.Transparency = 0

				-- Binary Eye Swapping (One White, One Black)
				_G.EyeFlip = not _G.EyeFlip
				local cWhite = Color3.new(1,1,1)
				local cBlack = Color3.new(0,0,0)

				local chosenColorL = _G.EyeFlip and cWhite or cBlack
				local chosenColorR = _G.EyeFlip and cBlack or cWhite

				lEye.Color = chosenColorL
				rEye.Color = chosenColorR

				-- Adds a flickering ominous glow to his face that matches the white static
				if lGlow then
					lGlow.Color = chosenColorL
					lGlow.Brightness = (chosenColorL == cBlack) and 0 or math.random(15, 25) / 10
				end
				if rGlow then
					rGlow.Color = chosenColorR
					rGlow.Brightness = (chosenColorR == cBlack) and 0 or math.random(15, 25) / 10
				end

				local jitX = EyeSettings.SizeX + (math.random(-5, 5) / 500)
				local jitY = EyeSettings.SizeY + (math.random(-5, 5) / 500)

				if EyeSettings.MakeRound then
					lEye.Size = Vector3.new(0.05, jitY, jitX)
					rEye.Size = Vector3.new(0.05, jitY, jitX)
				else
					lEye.Size = Vector3.new(jitX, jitY, 0.05)
					rEye.Size = Vector3.new(jitX, jitY, 0.05)
				end
			end
		end
	end

	local targetSpeed = 16

	-- Added Transition2_5 and SansOnPlatform here so Sans strictly CANNOT move
	if _G.SansOnPlatform or tick() < (_G.SansCannotMoveEnd or 0) then
		targetSpeed = 0
	elseif CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Dead" then
		targetSpeed = 0 
	elseif tick() < (_G.SansSlowDebuffEnd or 0) then
		targetSpeed = 6
	elseif tick() < blockSlowdownEnd then
		targetSpeed = 8
	elseif CurrentMode == "HP" then 
		targetSpeed = 8 
	end

	Humanoid.WalkSpeed = targetSpeed

	local walkingMagnitude = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z).magnitude
	local jumpVel = rootPart.Velocity.Y
	sine = change + sine

	if Death2 == true then
		local gWeld = rootPart:FindFirstChild("GasterMainWeld")
		if gWeld then
			local bobY = math.sin(sine/25) * 0.5
			local swayX = math.cos(sine/35) * 0.8
			local tiltZ = math.sin(sine/30) * 0.05
			gWeld.C0 = clerp(gWeld.C0, CFrame.new(swayX, 1.5 + bobY, 4.5) * CFrame.Angles(0, math.rad(-90), tiltZ), 0.1)
		end

		if Phase3ScreenWeld then
			local bobY = math.sin(sine/25) * 0.5
			local swayX = math.cos(sine/35) * 0.8
			local tiltZ = math.sin(sine/30) * 0.05
			Phase3ScreenWeld.C0 = clerp(Phase3ScreenWeld.C0, CFrame.new(-3.5 + swayX, 1.5 + bobY, 3) * CFrame.Angles(0, math.rad(-15), tiltZ), 0.1)
		end

		if _G.CursorWeldL and _G.CursorWeldR then
			local bobY = math.sin(sine/20) * 0.3
			if _G.ScreenWeldL then _G.ScreenWeldL.C0 = clerp(_G.ScreenWeldL.C0, _G.ScreenOffsetL * CFrame.new(0, bobY, 0) * _G.ScreenRotL, 0.1) end
			if _G.ScreenWeldR then _G.ScreenWeldR.C0 = clerp(_G.ScreenWeldR.C0, _G.ScreenOffsetR * CFrame.new(0, bobY, 0) * _G.ScreenRotR, 0.1) end

			local hoverL = _G.TargetCFL
			local hoverR = _G.TargetCFR

			if hoverL == "IDLE" and _G.ScreenWeldL then hoverL = _G.ScreenWeldL.C0 * _G.CursorIdleOffset end
			if hoverR == "IDLE" and _G.ScreenWeldR then hoverR = _G.ScreenWeldR.C0 * _G.CursorIdleOffset end

			if _G.isPhase3Jumping then
				local leftArmCF = rootPart.CFrame:ToObjectSpace(Left_Arm.CFrame)
				local rightArmCF = rootPart.CFrame:ToObjectSpace(Right_Arm.CFrame)
				hoverL = leftArmCF * CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(180), 0, math.rad(-30))
				hoverR = rightArmCF * CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(180), 0, math.rad(30))

				_G.CursorWeldL.C0 = hoverL
				_G.CursorWeldR.C0 = hoverR
			else
				_G.CursorWeldL.C0 = clerp(_G.CursorWeldL.C0, hoverL, 0.3)
				_G.CursorWeldR.C0 = clerp(_G.CursorWeldR.C0, hoverR, 0.3)
			end
		end

		local gHand = Character:FindFirstChild("GasterHand")
		if gHand and gHand:FindFirstChild("GHandWeld") then
			local hWeld = gHand.GHandWeld
			local baseOffset = CFrame.new(GHand_X, GHand_Y + math.sin(sine/15)*0.03, GHand_Z)
			local baseAngles = CFrame.Angles(math.rad(GHand_RotX + math.sin(sine/15)*2), math.rad(GHand_RotY), math.rad(GHand_RotZ))
			hWeld.C0 = clerp(hWeld.C0, baseOffset * baseAngles, 0.1)
		end

		local cHands = Character:FindFirstChild("ColoredHands")
		if cHands then
			local numHands = #cHands:GetChildren()
			for i, hand in ipairs(cHands:GetChildren()) do
				local hWeld = hand:FindFirstChildOfClass("Weld")
				if hWeld then
					local orbitAngle = math.rad(i * (360 / numHands)) + (sine / 25)
					hWeld.C0 = clerp(hWeld.C0, CFrame.Angles(0, orbitAngle, 0) * CFrame.new(0, math.sin((sine / 15) + i) * 1.5, 6.5) * CFrame.Angles(math.rad(90), 0, 0), 0.1)
				end
			end
		end
	end

	for i,v in pairs(Character:GetChildren()) do
		if v:IsA('Accoutrement') then
			v:Destroy()
		end
	end
	if Deaths <= 100 then
		HARDMODE = true
	end

	if _G.InTransition then
		if Humanoid.Health < Humanoid.MaxHealth then
			Humanoid.Health = Humanoid.MaxHealth
		end
	elseif (candodge == true or canblock == true) and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth 

		if dodgeDebounce == false then
			dodgeDebounce = true
			CurrentDodges = CurrentDodges - 1

			if candodge == true then
				dodge()
			elseif canblock == true then
				block()
			end
			idle = idly

			if CurrentMode == "Blocks" and CurrentDodges == 1 and not Phase2_5_Completed then
				-- Toggles INSTANTLY (Delay eliminated completely here and up in cutscene logic)
				candodge = false
				canblock = false
				Phase2_5_Completed = true
				Phase2Point5()

			elseif CurrentDodges <= 0 then
				candodge = false
				canblock = false

				if CurrentMode == "Dodges" then
					CurrentMode = "HP"
				elseif CurrentMode == "Blocks" then
					CreateSound("249313328", Head, 8, 1) 
					CurrentMode = "HP"

					coroutine.wrap(function()
						task.wait(0.6) 
						if Character:FindFirstChild("Phase2Weapon") then
							local weapon = Character.Phase2Weapon
							if not weapon:FindFirstChild("Dust") then particles(weapon) end
							weapon.Dust.Rate = 400
							weapon.Dust.Speed = NumberRange.new(3, 7)
							weapon.Dust.Acceleration = Vector3.new(0, 3, 0)
							weapon.Dust.SpreadAngle = Vector2.new(180, 180)
							for t = 0, 1, 0.05 do
								weapon.Transparency = t
								task.wait(0.05)
							end
							weapon:Destroy()
						end
					end)()
				end

				coroutine.wrap(function()
					local closestEnemy = nil
					local closestDist = 30
					for _, obj in pairs(workspace:GetChildren()) do
						if obj:IsA("Model") and obj ~= Character then
							local eRoot = obj:FindFirstChild("HumanoidRootPart")
							local eHum = obj:FindFirstChildOfClass("Humanoid")
							if eRoot and eHum and eHum.Health > 0 then
								local dist = (eRoot.Position - rootPart.Position).Magnitude
								if dist < closestDist then
									closestDist = dist
									closestEnemy = eRoot
								end
							end
						end
					end

					if closestEnemy then
						local S = Instance.new("Sound", closestEnemy)
						S.SoundId = "rbxassetid://548991605"
						S.Volume = 5
						S:Play()

						local GUI = Instance.new("BillboardGui", closestEnemy)
						GUI.Size = UDim2.new(2.5,0,2.5,0)
						GUI.AlwaysOnTop = true
						local Body = Instance.new("ImageLabel", GUI)
						Body.Size = UDim2.new(1,0,1,0)
						Body.BackgroundTransparency = 1
						Body.Image = "rbxassetid://338425795" 

						local pushDir = (closestEnemy.Position - rootPart.Position).Unit
						pushDir = Vector3.new(pushDir.X, 0, pushDir.Z).Unit 
						closestEnemy.Velocity = (pushDir * 85) + Vector3.new(0, 40, 0)

						game.Debris:AddItem(GUI, 1.5)
						game.Debris:AddItem(S, 2)
					end
				end)()

				UpdateDodgeBar()

				coroutine.wrap(function()
					task.wait(1.5) 
					dodgeDebounce = false
				end)()
			else
				UpdateDodgeBar() 

				coroutine.wrap(function()
					task.wait(0.5) 
					dodgeDebounce = false
				end)()
			end
		end
	end

	if CurrentMode == "Timer" then
		if Head:FindFirstChild("HealthBar") then
			Head.HealthBar.Frame.Health.BackgroundColor3 = Color3.fromRGB(255, math.random(0, 220), 0)
		end
	end

	if CurrentMode == "HP" and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth 

		if dodgeDebounce == false and not _G.InTransition then 
			if Death == false and Happened == false then
				Happened = true
				Zzz.Enabled = false
				Dead()
				-- Fixed Missing 'Happened2' variable checking logically below! 
			elseif Death == true and not _G.Phase3_Started then 
				_G.Phase3_Started = true
				Dead2()
			end
		end
	end

	if CurrentMode == "Timer" and Phase3Timer > 0 and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end

	if (CurrentMode == "Transition" or CurrentMode == "Timer2_5") and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end

	if CurrentMode == "Timer2_5" and Phase2_5Timer > 0 and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end

	if candodge == false and specialattack == true and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end

	if (CurrentMode == "Timer" or CurrentMode == "Transition") and Humanoid.Health < Humanoid.MaxHealth then
		Humanoid.Health = Humanoid.MaxHealth
	end

	if specialattack == true then
		if Shields:FindFirstChild("Shield") == nil then
			local Shield = Instance.new ("MeshPart", Shields) Shield.Name = "Shield" Shield.CanCollide = false Shield.Transparency = 1 Shield.Material = "Neon" Shield.BrickColor = BrickColor.new("Really red") Shield.Size = Vector3.new(12,12,12) Shield.Massless = true Shield.CFrame = Character.Torso.CFrame
			local Wed = Instance.new("Weld", Shield) Wed.Part0 = Shield Wed.Part1 = Character.Torso
			Shield.Touched:connect(function(hit)
				if hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= nil and hit.Parent.Name ~= Character.Name then
					if hit.Parent.HumanoidRootPart ~= false then
						Shield:Destroy()
						restriction = true
						teleporting = true
						hit.Parent.HumanoidRootPart.CFrame=rootPart.CFrame*CFrame.new(0,0,-25)*CFrame.Angles(math.rad(0),math.rad(180),math.rad(0))
						CreateSound("446961725", Head, 7, 1)
						Humanoid.Health = Humanoid.MaxHealth
						idle=idly
						Expression.Texture = "rbxassetid://4484422735"
						swait(15)
						Expression.Texture = "rbxassetid://4484448817"
						swait(25)
						Expression.Texture = "rbxassetid://4484405390"
					end
				end
			end)
		end
		if Shields:FindFirstChild("Shield2") == nil then
			local Shield2 = Instance.new ("MeshPart", Shields) Shield2.Name = "Shield2" Shield2.CanCollide = false Shield2.Transparency = 1 Shield2.Material = "Neon" Shield2.BrickColor = BrickColor.new("Really red") Shield2.Size = Vector3.new(7,7,7) Shield2.Massless = true Shield2.CFrame = Character.Torso.CFrame
			local Wed = Instance.new("Weld", Shield2) Wed.Part0 = Shield2 Wed.Part1 = Character.Torso
		end
	end

	if sansClothesEnabled then
		if Character:FindFirstChild('Body Colors') then
			Character['Body Colors'].HeadColor3=Color3.new(1,1,1)
			Character['Body Colors'].TorsoColor3=Color3.new(1,1,1)
			Character['Body Colors'].RightArmColor3=Color3.new(1,1,1)
			Character['Body Colors'].LeftArmColor3=Color3.new(1,1,1)
			Character['Body Colors'].RightLegColor3=Color3.new(1,1,1)
			Character['Body Colors'].LeftLegColor3=Color3.new(1,1,1)
		end

		Left_Arm.BrickColor = BrickColor.new("Institutional white")
		Right_Arm.BrickColor = BrickColor.new("Institutional white")
		Left_Leg.BrickColor = BrickColor.new("Institutional white")
		Right_Leg.BrickColor = BrickColor.new("Institutional white")
		Torso.BrickColor = BrickColor.new("Institutional white")
		Head.BrickColor = BrickColor.new("Institutional white")

		if Death == true and Death2 == false then
			for _, c in pairs(Character:GetChildren()) do
				if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" then
					if c.Transparency < 0.2 and c.Transparency > 0.19 then
						c.Transparency = 0.2
					end
				end
			end
		end
	end

	local floorMat = Humanoid.FloorMaterial
	local isMidair = (floorMat == Enum.Material.Air)

	if jumpVel > 5 and isMidair then
		currentAnim = "Jumping"
	elseif Humanoid.Sit == true then
		currentAnim = "Seated"
	elseif jumpVel < -15 and isMidair then
		currentAnim = "Falling"
	elseif walkingMagnitude < 2 then
		currentAnim = "Idling"
	elseif isSSprint == true then
		currentAnim = "Sprinting"
	elseif walkingMagnitude > 2 then
		currentAnim = "Walking"
	elseif isAttacking == true then
		currentAnim = "Attacking"
	end

	local WALKSPEEDVALUE = 6 / (Humanoid.WalkSpeed / 16)
	local TiltVelocity = CFrame.new(rootPart.CFrame:vectorToObjectSpace(rootPart.Velocity/1.6))

	if currentAnim == "Jumping" and Animations == false then
		angleSpeed = 2
		axisSpeed = 2
		change = 0.5
		local jumpSpeed = 0.4 

		if Death2 == true then
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.5, 0) * c_angles(math.rad(0), 0, math.rad(10)), jumpSpeed)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.4, 0.5, 0) * c_angles(math.rad(0), 0, math.rad(-10)), jumpSpeed)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.8, -0.1) * c_angles(math.rad(-10), 0, 0), jumpSpeed)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.8, -0.1) * c_angles(math.rad(10), 0, 0), jumpSpeed)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, 0.8, 0) * c_angles(math.rad(5), 0, 0), jumpSpeed)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0.1) * c_angles(math.rad(-20), 0, 0), jumpSpeed)

		elseif Death == true then
			if blocking == true then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.3 + math.sin(sine/12)/5, 0) * c_angles(math.rad(90),math.rad(90),math.rad(0)), jumpSpeed / 2)
			elseif Character:FindFirstChild("Phase2Weapon") then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4, -0.1) * c_angles(math.rad(120), 0, math.rad(-20)), jumpSpeed) 
			else
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3, 0) * c_angles(math.rad(23), 0, math.rad(-20)), jumpSpeed)
			end
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3, 0) * c_angles(math.rad(23), 0, math.rad(20)), jumpSpeed)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.5, -0.5) * c_angles(math.rad(-10), 0, 0), jumpSpeed)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(10), 0, 0), jumpSpeed)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1, 0) * c_angles(math.rad(-10), 0, 0), jumpSpeed)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0.1) * c_angles(math.rad(-10), 0, 0), jumpSpeed)

		else
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3, 0) * c_angles(math.rad(23), 0, math.rad(-20)), jumpSpeed)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3, 0) * c_angles(math.rad(23), 0, math.rad(20)), jumpSpeed)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.5, -0.5) * c_angles(math.rad(-10), 0, 0), jumpSpeed)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(10), 0, 0), jumpSpeed)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -0.8, 0) * c_angles(math.rad(-15), 0, 0), jumpSpeed)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0.1) * c_angles(math.rad(10), 0, 0), jumpSpeed)
		end

	elseif currentAnim == "Falling" and Animations == false then
		angleSpeed = 2
		axisSpeed = 2
		change = 0.5
		if blocking == true then
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.3 + math.sin(sine/12)/5, 0) * c_angles(math.rad(90),math.rad(90),math.rad(0)), 0.075)
		else
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.5, 0) * c_angles(math.rad(160),math.rad(0),math.rad(15)), 0.15)
		end
		LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.5, 0.5, 0) * c_angles(math.rad(160),math.rad(0),math.rad(-15)), 0.15)
		LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5, -0.8, 0.2) * c_angles(math.rad(-20),math.rad(0),math.rad(0)), 0.15)
		RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5, -0.8, -0.5) * c_angles(math.rad(15),math.rad(0),math.rad(0)), 0.15)
		Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(0, -1, 0.5) * c_angles(math.rad(-15), math.rad(0),math.rad(0)), 0.15)
		Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0, 1.5, -0.3) * c_angles(math.rad(-20),math.rad(0), math.rad(0)), 0.15)
	elseif currentAnim == "Seated" and Animations == false then
		angleSpeed = 2
		axisSpeed = 2
		change = 0.5
		if blocking == true then
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.3 + math.sin(sine/12)/5, 0) * c_angles(math.rad(90),math.rad(90),math.rad(0)), (Sanim + 0.025) / 2)
		else
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(-20)), Sanim + 0.025)
		end
		LA_Weld.C0		= clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/6)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), Sanim + 0.025)
		LL_Weld.C0		= clerp(LL_Weld.C0, c_new(-0.5, -1, 0) * c_angles(math.rad(50) - math.sin(sine/7.5)/30,math.rad(0) + math.sin(sine/7.5)/30,math.rad(-20)), 0.15)
		RL_Weld.C0 		= clerp(RL_Weld.C0, c_new(0.5, -1, 0) * c_angles(math.rad(50) - math.sin(sine/7.5)/30,math.rad(0) - math.sin(sine/7.5)/30,math.rad(20)), 0.15)
		Torso_Weld.C0 	= clerp(Torso_Weld.C0, c_new(0, -1, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/30, math.rad(0),math.rad(0)), 0.15)
		Head_Weld.C0 	= clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/15,math.rad(0), math.rad(0) + math.sin(sine/7.5)/30), 0.15)

	elseif currentAnim == "Idling" and Animations == false then
		if Death2 == true then
			local sway = math.sin(sine / 12) 
			local sway2 = math.cos(sine / 12)
			local idleAlpha = 0.3 

			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.2, 0) * c_angles(math.rad(0), math.rad(5 * sway), math.rad(10 * sway)), idleAlpha) 
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(math.random(-1,1)/100, 1.5, 0.1 + math.random(-1,1)/100) * c_angles(math.rad(math.random(-3,3)), math.rad(-5 * sway) + math.rad(math.random(-3,3)), math.rad(-10 * sway) + math.rad(math.random(-3,3))), idleAlpha)
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4, -0.1 + 0.1 * sway2) * c_angles(math.rad(-10), math.rad(0), math.rad(5 - 10 * sway)), idleAlpha)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.4, 0.4, -0.1 - 0.1 * sway2) * c_angles(math.rad(-10), math.rad(0), math.rad(-5 - 10 * sway)), idleAlpha)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -1.05 + 0.1 * math.max(0, sway), 0) * c_angles(math.rad(0), math.rad(0), math.rad(-10 * sway)), idleAlpha)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -1.05 + 0.1 * math.max(0, -sway), 0) * c_angles(math.rad(0), math.rad(0), math.rad(-10 * sway)), idleAlpha)

		elseif _G.heavilyBreathing == true then
			-- Highly realistic heavy breathing/exhaustion: slumped torso leaning forward, hanging head, rapid deep gasping chest breaths + exhaustion muscle shivers
			local speed = 0.08
			local breath = math.sin(sine * 1.5) -- Fast panting speed
			local shiver = math.cos(sine * 20) * 0.005 -- High-frequency muscle shiver/vibration (reduced for gentler shaking)

			-- Slumped head looking down, vibrating with fatigue
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(shiver, 1.45 + breath * 0.04, -0.05) * c_angles(math.rad(-22) + breath * 0.05 + shiver * 4, shiver, 0), speed)

			-- Torso slumped forward, rising/shaking with heavy breathing
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(shiver, -1.0 + breath * 0.06, shiver) * c_angles(math.rad(-33) + breath * 0.05, 0, shiver), speed)

			-- Drooping, tired arms dangling down with high shake/tension
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.15, 0.2 + breath * 0.02, -0.1) * c_angles(math.rad(10) + shiver * 6, 0, math.rad(-10) + shiver * 6), speed)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.15, 0.2 + breath * 0.02, -0.1) * c_angles(math.rad(10) + shiver * 6, 0, math.rad(10) + shiver * 6), speed)

			-- Tired bent knees
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.8 + breath * 0.01, -0.1) * c_angles(math.rad(10), 0, math.rad(-10)), speed)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.8 + breath * 0.01, -0.1) * c_angles(math.rad(10), 0, math.rad(10)), speed)

		elseif Death == true then
			if blocking == true then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.3 + math.sin(sine/12)/5, 0) * c_angles(math.rad(90),math.rad(90),math.rad(0)), (Sanim + 0.025) / 2)
			elseif Character:FindFirstChild("Phase2Weapon") then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4 + math.sin(sine/15)/5, -0.1) * c_angles(math.rad(60),math.rad(0),math.rad(-20)), Sanim + 0.025) 
			else
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/15)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(-20)), Sanim + 0.025)
			end
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/15)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), Sanim + 0.025)

			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(10) - math.sin(sine/15)/5,math.rad(0),math.rad(-10)), Sanim)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(10) - math.sin(sine/15)/5,math.rad(0),math.rad(10)), Sanim)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0 - math.sin(sine/15)/10, -0.95 + math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) + math.sin(sine/15)/10, math.rad(-15),math.rad(0)), Sanim)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0 - math.sin(sine/15)/6, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/5,math.rad(15), math.rad(0) + math.sin(sine/15)/4), Sanim)

		else
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine/15)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(-20)), Sanim + 0.025)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine/15)/5, 0) * c_angles(math.rad(23),math.rad(0),math.rad(20)), Sanim + 0.025)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(-10)), Sanim)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5 + math.sin(sine/15)/6, -1.05 - math.sin(sine/7.5)/5 , 0) * c_angles(math.rad(0) - math.sin(sine/15)/5,math.rad(0),math.rad(10)), Sanim)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0 - math.sin(sine/15)/10, -0.95 + math.sin(sine/7.5)/5, 0) * c_angles(math.rad(0) + math.sin(sine/15)/10, math.rad(0),math.rad(0)), Sanim)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0 - math.sin(sine/15)/6, 1.5, 0) * c_angles(math.rad(0) + math.sin(sine/7.5)/5,math.rad(0), math.rad(0) + math.sin(sine/15)/4), Sanim)
		end

	elseif currentAnim == "Walking" and Animations == false then
		angleSpeed = 1
		axisSpeed = 1

		if Death2 == true then
			local walkSway = math.sin(sine / WALKSPEEDVALUE)
			local walkSway2 = math.cos(sine / WALKSPEEDVALUE)

			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1.2, 0) * c_angles(0, math.rad(5 * walkSway), math.rad(10 * walkSway)), 0.3)
			-- FIX: Softened walking head shake in phase 3
			-- Adds violent but localized shaking to head during walking
			local rX, rY, rZ = math.random(-3,3), math.random(-3,3), math.random(-3,3)
			local tX, tZ = math.random(-1,1)/100, math.random(-1,1)/100
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(tX, 1.5, 0.1 + tZ) * c_angles(math.rad(rX), math.rad(-5 * walkSway) + math.rad(rY), math.rad(-10 * walkSway) + math.rad(rZ)), 0.3)
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4, -0.1 + 0.1 * walkSway2) * c_angles(math.rad(-10), 0, math.rad(5 - 10 * walkSway)), 0.3)
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.4, 0.4, -0.1 - 0.1 * walkSway2) * c_angles(math.rad(-10), 0, math.rad(-5 - 10 * walkSway)), 0.3)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.9 - 0.5 * walkSway2 / 2, -0.2 + 0.6 * walkSway2 / 2) * c_angles(math.rad(-15 - 10 * walkSway2), 0, 0), 0.3)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.9 + 0.5 * walkSway2 / 2, -0.2 - 0.6 * walkSway2 / 2) * c_angles(math.rad(-15 + 10 * walkSway2), 0, 0), 0.3)

		elseif Death == true then
			if blocking == true then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.5, 0.3 + math.sin(sine/12)/5, 0) * c_angles(math.rad(90),math.rad(90),math.rad(0)), 0.15)
			elseif Character:FindFirstChild("Phase2Weapon") then
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.4, 0.4 + math.sin(sine / WALKSPEEDVALUE) / 5, -0.1) * c_angles(math.rad(60), 0, math.rad(-20)), 0.3) 
			else
				RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine / WALKSPEEDVALUE) / 5, 0) * c_angles(math.rad(23), 0, math.rad(-20)), 0.3)
			end
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine / WALKSPEEDVALUE) / 5, 0) * c_angles(math.rad(23), 0, math.rad(20)), 0.3)
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.9 - 0.5 * math.cos(sine / WALKSPEEDVALUE) / 2, -0.2 + 0.6 * math.cos(sine / WALKSPEEDVALUE) / 2) * c_angles(math.rad(-15 - 10 * math.cos(sine / WALKSPEEDVALUE)), 0, 0), 0.3)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.9 + 0.5 * math.cos(sine / WALKSPEEDVALUE) / 2, -0.2 - 0.6 * math.cos(sine / WALKSPEEDVALUE) / 2) * c_angles(math.rad(-15 + 10 * math.cos(sine / WALKSPEEDVALUE)), 0, 0), 0.3)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1 + math.abs(math.sin(sine / WALKSPEEDVALUE)) / 6, 0) * c_angles(math.rad(-5), math.rad(-5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(5 * math.cos(sine / WALKSPEEDVALUE))), 0.3)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(5), math.rad(5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(-5 * math.cos(sine / WALKSPEEDVALUE))), 0.3)

		else
			RA_Weld.C0 = clerp(RA_Weld.C0, c_new(1.25, 0.3 + math.sin(sine / WALKSPEEDVALUE) / 5, 0) * c_angles(math.rad(23), 0, math.rad(-20)), 0.3) 
			LA_Weld.C0 = clerp(LA_Weld.C0, c_new(-1.25, 0.3 + math.sin(sine / WALKSPEEDVALUE) / 5, 0) * c_angles(math.rad(23), 0, math.rad(20)), 0.3) 
			RL_Weld.C0 = clerp(RL_Weld.C0, c_new(0.5, -0.9 - 0.5 * math.cos(sine / WALKSPEEDVALUE) / 2, -0.2 + 0.6 * math.cos(sine / WALKSPEEDVALUE) / 2)  * c_angles(math.rad(-15 - 10 * math.cos(sine / WALKSPEEDVALUE)) - Right_Leg.RotVelocity.Y / 75 + -math.sin(sine / WALKSPEEDVALUE) / 2.5 * -math.rad(TiltVelocity.z) * 10, math.rad(0 - 5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(0)) * c_angles(math.rad(0 + 2 * math.cos(sine / WALKSPEEDVALUE)), math.rad(0), math.rad(0 - 25 * math.sin(sine / WALKSPEEDVALUE)*-math.rad(TiltVelocity.x)*5.5)), 0.3)
			LL_Weld.C0 = clerp(LL_Weld.C0, c_new(-0.5, -0.9 + 0.5 * math.cos(sine / WALKSPEEDVALUE) / 2, -0.2 - 0.6 * math.cos(sine / WALKSPEEDVALUE) / 2) * c_angles(math.rad(-15 + 10 * math.cos(sine / WALKSPEEDVALUE)) + Left_Leg.RotVelocity.Y / -75 + math.sin(sine / WALKSPEEDVALUE) / 2.5 * -math.rad(TiltVelocity.z) * 10, math.rad(0 - 5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(0)) * c_angles(math.rad(0 - 2 * math.cos(sine / WALKSPEEDVALUE)), math.rad(0), math.rad(0 - 25 * math.sin(sine / WALKSPEEDVALUE)*math.rad(TiltVelocity.x)*5.5)), 0.3)
			Torso_Weld.C0 = clerp(Torso_Weld.C0, c_new(0, -1 + math.abs(math.sin(sine / WALKSPEEDVALUE)) / 6, 0) * c_angles(math.rad(0), math.rad(-5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(5 * math.cos(sine / WALKSPEEDVALUE))), 0.3)
			Head_Weld.C0 = clerp(Head_Weld.C0, c_new(0, 1.5, 0) * c_angles(math.rad(0), math.rad(5 * math.cos(sine / WALKSPEEDVALUE)), math.rad(-5 * math.cos(sine / WALKSPEEDVALUE))), 0.3)
		end
	end

	-- ================================================= --

	if _G.isGlitching and CurrentMode == "Timer" then
		wasGlitching = true

		local rx = math.rad(math.random(-3, 3))
		local ry = math.rad(math.random(-3, 3))
		local rz = math.rad(math.random(-3, 3))
		local tx = math.random(-5, 5) / 100
		local ty = math.random(-5, 5) / 100
		local tz = math.random(-5, 5) / 100

		local glitchCF = CFrame.new(tx, ty, tz) * CFrame.Angles(rx, ry, rz)

		Torso_Weld.C0 = Torso_Weld.C0 * glitchCF
		Head_Weld.C0 = Head_Weld.C0 * glitchCF
		RA_Weld.C0 = RA_Weld.C0 * glitchCF
		LA_Weld.C0 = LA_Weld.C0 * glitchCF

		if math.random(1, 3) == 1 then
			local flickerAlpha = math.random(30, 80) / 100
			for _, c in pairs(Character:GetChildren()) do
				-- Excludes Eyes and Extra Hands so they don't vanish!
				if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" and not c.Name:match("Hand") and not c.Name:match("Eye") and not c.Name:match("Root") then
					c.Transparency = flickerAlpha
				end
			end
			if Expression then Expression.Transparency = flickerAlpha end
			if Slash then Slash.Transparency = flickerAlpha end
		end

	elseif wasGlitching and CurrentMode == "Timer" then
		wasGlitching = false
		-- RESETS transparency back to normal depending on time left
		local baseTrans = (Phase3Timer <= 10) and 0.5 or 0.2
		for _, c in pairs(Character:GetChildren()) do
			if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" and c.Name ~= "BlockBone" and not c.Name:match("Hand") and not c.Name:match("Eye") and not c.Name:match("Root") then
				c.Transparency = baseTrans
			end
		end
		if Expression then Expression.Transparency = baseTrans end
		if Slash then Slash.Transparency = baseTrans end
	end

	if cam and Head then
		local isClose = (cam.CFrame.Position - Head.Position).Magnitude < 12
		local function applyLocalTransparency(model)
			if not model then return end
			for _, p in pairs(model:GetDescendants()) do
				if p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture") then
					if p.Transparency < 1 then
						p.LocalTransparencyModifier = isClose and 0.85 or 0
					end
				elseif p:IsA("SurfaceGui") or p:IsA("BillboardGui") then
					p.Enabled = not isClose
				end
			end
		end

		applyLocalTransparency(Character:FindFirstChild("GasterModel"))
		applyLocalTransparency(Character:FindFirstChild("GasterHand"))
		applyLocalTransparency(Character:FindFirstChild("ColoredHands"))
		applyLocalTransparency(_G.CursorL)
		applyLocalTransparency(_G.CursorR)
		applyLocalTransparency(_G.ScreenL)
		applyLocalTransparency(_G.ScreenR)
	end
end)

-- ================================================= --
-- [[ 12. LOCAL MOVESET GUI & TRUE KR ENGINE ]]
-- ================================================= --
local KRCache = {}

task.spawn(function()
	while true do
		for hum, data in pairs(KRCache) do
			if hum.Parent and hum.Health > 0 and data.KR > 0 then
				data.KR = data.KR - 1
				hum.Health = hum.Health - 1
			else
				if data.Highlight then data.Highlight:Destroy() end
				-- FIX: Re-enable Roblox's health regen when KR fully expires
				local healthScript = hum.Parent and hum.Parent:FindFirstChild("Health")
				if healthScript and healthScript:IsA("Script") then
					healthScript.Disabled = false
				end
				KRCache[hum] = nil
			end
		end
		task.wait(0.5) -- 2x Faster: 0.5 Seconds Per KR Tick (20 KR = 10 Seconds)
	end
end)

_G.ApplyKarmaHit = function(hum, dmg)
	if not hum or hum.Health <= 0 then return end
	local damage = dmg or 1
	if Death2 == true then
		damage = damage * 2
	end
	hum.Health = hum.Health - damage 

	if not KRCache[hum] then
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(255, 0, 255) 
		hl.OutlineColor = Color3.fromRGB(255, 100, 255)
		hl.FillTransparency = 0.4
		hl.Parent = hum.Parent
		KRCache[hum] = {KR = damage, Highlight = hl}

		-- FIX: Disable Roblox's built-in health regeneration for this humanoid
		-- so KR damage isn't instantly healed back. We do this by finding and
		-- disabling the Health script that Roblox puts in every character.
		local healthScript = hum.Parent and hum.Parent:FindFirstChild("Health")
		if healthScript and healthScript:IsA("Script") then
			healthScript.Disabled = true
		end
		-- Also zero out the auto-regen field directly if it exists (StarterCharacterScripts)
		pcall(function() hum.Health = hum.Health end) -- no-op, just a pcall safety
	else
		KRCache[hum].KR = KRCache[hum].KR + damage 
	end
end

CreateMovesGUI = function()
	local oldGui = Player:WaitForChild("PlayerGui"):FindFirstChild("SansMoves")
	if oldGui then oldGui:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SansMoves"
	sg.ResetOnSpawn = true 
	sg.Parent = Player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame", sg)
	frame.Size, frame.Position = UDim2.new(0, 340, 0, 310), UDim2.new(0, 15, 0.5, -155)
	frame.BackgroundColor3, frame.BackgroundTransparency = Color3.fromRGB(0, 0, 0), 0.5
	frame.BorderSizePixel, frame.BorderColor3 = 2, Color3.fromRGB(255, 255, 255)

	_G.SansMovesFrame = frame 

	local title = Instance.new("TextLabel", frame)
	title.Size, title.BackgroundTransparency = UDim2.new(1, 0, 0, 40), 1
	title.Text, title.TextColor3 = "MOVESET (Press 'M' to Toggle)", Color3.fromRGB(0, 255, 255)
	title.Font, title.TextSize = Enum.Font.Arcade, 16

	local isPhase2 = (Death == true or Death2 == true or CurrentMode == "Transition" or CurrentMode == "Transition2_5" or CurrentMode == "Timer2_5" or CurrentMode == "Timer")

	local moves
	if isPhase2 then
		moves = {
			"--- BLASTERS ---",
			"[Q] - Single Blaster",
			"  M1: Giant Blaster | Ctrl: Omega Super-Blaster",
			"[G] - Gaster Shower",
			"  M1: Big Shower | Ctrl: Super Shower | Formations: Circle, Line, Square, Stack",
			"[H] - Big Circle Blasters",
			"  M1: 4-Way Sweepers | Ctrl: Super + Sweepers",
			"[T] - Beam",
			"  M1: x2 Size/Warn | Ctrl: x4 Size/Warn",
			"--- BONES ---",
			"[R] - Homing Bone",
			"  M1: Inward Circles | Ctrl: 8 Orbiting Circles",
			"[C] - Bone Rise",
			"  M1: Chessboard | Ctrl: Switching Grid",
			"[F] - Bone Wave",
			"  M1: 5 Bone Walls | Ctrl: Omni-Directional",
			"[B] - Boxed Bones",
			"--- UTILITY ---",
			"[E] - Teleportation",
			"  M1: Quad Blaster Blitz | Ctrl: Repulsion Field",
			"[V] - Invertion",
			"  M1: Left | Ctrl: Right | Normal: Upside Down",
			"[U] - Platforms",
			"  M1: 2 Long (DIY) | Normal: Vertical Obby",
		}
	else
		moves = {
			"--- ATTACKS ---",
			"[V] - It's A Beatiful Day",
			"[B] - Keep Pushing",
			"[N] - Here Goes Nothing!",
			"--- BLASTERS ---",
			"[Q] - Single Blaster | M1: Giant Blaster",
			"[G] - Blaster Shower",
			"  [M1+G] - Rotating Circle Blasters",
			"  [Ctrl+G] - Tracking Sweeper Variant",
			"--- BONES ---",
			"[R] - Homing Bone | M1: Stalker Bone",
			"[C] - Bone Rise | M1: 6x Homing Shower",
			"[F] - Bone Wave",
			"  [M1+F] - Giant Bone Variant",
			"  [Ctrl+F] - Platform Obby Trap",
			"--- UTILITY ---",
			"[E] - Teleportation",
			"  [M1+E] - Shadow Backstab",
			"  [Ctrl+E] - Freeze Blitz",
			"[K] - Toggle Attack Descriptions",
			"[Y] - Toggle Jacket",
			"[Click] - Blue Soul Grab & Drag",
			"[Z] (While Grabbing) - Rapid Smash",
			"  [Ctrl+Z] - Side-Wall Gravity Flip",
		}
	end

	for i, move in ipairs(moves) do
		local lbl = Instance.new("TextLabel", frame)
		lbl.Size, lbl.Position = UDim2.new(1, -15, 0, 13), UDim2.new(0, 10, 0, 35 + (i * 16))
		lbl.BackgroundTransparency, lbl.TextColor3 = 1, Color3.fromRGB(255, 255, 255)
		lbl.Text, lbl.Font, lbl.TextScaled = move, Enum.Font.Code, false
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		if move:match("%-%-%-") then
			lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
			lbl.Font = Enum.Font.Arcade
			lbl.TextSize = 11
		elseif move:match("^  ") then
			lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
			lbl.TextSize = 10
		end
	end

	-- Resize the frame to fit all entries and center it
	local frameHeight = 60 + (#moves * 16)
	frame.Size = UDim2.new(0, 340, 0, frameHeight)
	frame.Position = UDim2.new(0, 15, 0.5, -(frameHeight / 2))

	if true then
		-- K-toggle Description Panel
		local descPanel = Instance.new("Frame", sg)
		descPanel.Size = UDim2.new(0, 504, 0, 624)
		descPanel.Position = UDim2.new(0, 365, 0.5, -312)
		descPanel.BackgroundColor3, descPanel.BackgroundTransparency = Color3.fromRGB(0, 0, 0), 0.4
		descPanel.BorderSizePixel, descPanel.BorderColor3 = 2, Color3.fromRGB(255, 255, 255)
		descPanel.Visible = false
		_G.SansDescFrame = descPanel

		local descTitle = Instance.new("TextLabel", descPanel)
		descTitle.Size, descTitle.BackgroundTransparency = UDim2.new(1, 0, 0, 30), 1
		descTitle.Position = UDim2.new(0, 0, 0, 4)
		descTitle.Text = "ATTACK DESCRIPTIONS [K]"
		descTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
		descTitle.Font, descTitle.TextSize = Enum.Font.Arcade, 13

		-- Create 3 Tab buttons at the top of the description frame
		local btn1 = Instance.new("TextButton", descPanel)
		btn1.Size, btn1.Position = UDim2.new(0, 150, 0, 29), UDim2.new(0, 12, 0, 38)
		btn1.BackgroundColor3, btn1.BackgroundTransparency = Color3.fromRGB(15, 15, 15), 0.2
		btn1.BorderSizePixel, btn1.BorderColor3 = 1, Color3.fromRGB(150, 150, 150)
		btn1.Text, btn1.TextColor3 = "CINEMATICS", Color3.fromRGB(220, 220, 220)
		btn1.Font, btn1.TextSize = Enum.Font.Arcade, 10

		local btn2 = Instance.new("TextButton", descPanel)
		btn2.Size, btn2.Position = UDim2.new(0, 150, 0, 29), UDim2.new(0, 174, 0, 38)
		btn2.BackgroundColor3, btn2.BackgroundTransparency = Color3.fromRGB(15, 15, 15), 0.2
		btn2.BorderSizePixel, btn2.BorderColor3 = 1, Color3.fromRGB(150, 150, 150)
		btn2.Text, btn2.TextColor3 = "BONES & SOUL", Color3.fromRGB(220, 220, 220)
		btn2.Font, btn2.TextSize = Enum.Font.Arcade, 10

		local btn3 = Instance.new("TextButton", descPanel)
		btn3.Size, btn3.Position = UDim2.new(0, 156, 0, 29), UDim2.new(0, 336, 0, 38)
		btn3.BackgroundColor3, btn3.BackgroundTransparency = Color3.fromRGB(15, 15, 15), 0.2
		btn3.BorderSizePixel, btn3.BorderColor3 = 1, Color3.fromRGB(150, 150, 150)
		btn3.Text, btn3.TextColor3 = "BLASTERS & SLAM", Color3.fromRGB(220, 220, 220)
		btn3.Font, btn3.TextSize = Enum.Font.Arcade, 10


		-- Tab containers
		local TabFrame1 = Instance.new("Frame", descPanel)
		TabFrame1.Size = UDim2.new(1, 0, 1, -75)
		TabFrame1.Position = UDim2.new(0, 0, 0, 72)
		TabFrame1.BackgroundTransparency = 1

		local TabFrame2 = Instance.new("Frame", descPanel)
		TabFrame2.Size = UDim2.new(1, 0, 1, -75)
		TabFrame2.Position = UDim2.new(0, 0, 0, 72)
		TabFrame2.BackgroundTransparency = 1

		local TabFrame3 = Instance.new("Frame", descPanel)
		TabFrame3.Size = UDim2.new(1, 0, 1, -75)
		TabFrame3.Position = UDim2.new(0, 0, 0, 72)
		TabFrame3.BackgroundTransparency = 1

		local descriptionsTab1, descriptionsTab2, descriptionsTab3, combos
		if isPhase2 then
			descriptionsTab1 = {
				{"[N] True Final Attack", "The real deal — 1m+ of multi-phase madness:\n40s relentless barrage, then final burst.\nUse after [B] to bait the player into thinking\nit's over. Best opener for the fight."},
			}
			descriptionsTab2 = {
				{"[B] Boxed Bones", "Traps the player in a 60x60 box.\nStage 1 (10s): Up/down bone waves.\nStage 2 (10s): Moving safe spot grid.\nStage 3 (10s): Rotating X bones + 3 giant blue sweeping bone walls!"},
				{"[R] Homing Bone", "Fires homing bones at the player.\nNormal: 12 homing bones shower.\nM1 variant (M1+R): Inner closing rings of bones + x5 damage outer limiter ring.\nCtrl variant (Ctrl+R): 8 Orbiting circles of bones closing in sequentially + x2 damage."},
				{"[C] Bone Rise", "Spawns a standard bone rise under the cursor.\nM1 variant (M1+C): Checkerboard 3x3 chessboard grid.\nCtrl variant (Ctrl+C): Switching 5x5 chessboard grid!"},
				{"[F] Bone Wave", "Fires moving bone walls propagating forward.\nNormal: 3 parallel bone walls (center and 2 sides).\nM1 variant (M1+F): 5 parallel bone walls (center, 2 left, 2 right).\nCtrl variant (Ctrl+F): Omni-directional bone walls radiating outwards!"},
				{"[E] Teleportation", "Teleports Sans to the mouse cursor position.\nM1 variant (M1+E): Quad Blaster Blitz (4-way shadow blitz with overhead blasters).\nCtrl variant (Ctrl+E): Repulsion Field (neon sphere repelling players)."},
				{"[V] Invertion", "Emulates gravity flip compatible with all terrains.\nNorth (V): Flips the screen completely upside down.\nLeft (M1+V): Flips the screen 90 deg counterclockwise.\nRight (Ctrl+V): Flips the screen 90 deg clockwise."},
				{"[U] Platforms", "Normal (U): Spawns 3 platform towers up to 200 studs in a 120x120 box.\nRed platforms trigger bone traps! Purple platforms fade out over 5 seconds and reappear 10 seconds later!\nA 190-stud bone slowly rises from the ground. Climb to survive!\nM1 variant (M1+U): Spawns 2 long platforms (10 & 20 studs high).\nPress P to phase down through them.\nBlasters spawn on corners to deny platforms.\nAllows Sans to freely combo with other attacks!"},
			}
			descriptionsTab3 = {
				{"[Q] Single Blaster", "Fires a blaster at the cursor position.\nM1 variant (M1+Q): Giant slow blaster with massive damage.\nCtrl variant (Ctrl+Q): Omega Super-Blaster (Size 7.0, massive beam)."},
				{"[G] Gaster Shower", "Rains blasters from above.\nM1 variant (M1+G): Big Blasters (4 blasters of size 3.5).\nCtrl variant (Ctrl+G): Super Blaster Shower \n(8 blasters of size 7.0 in stack formation)."},
				{"[H] Big Circle Blasters", "[Phase 2] Big Circle Blasters:\nNormal: Large circle of big blasters rotating around target.\nM1: Standard tracking sweepers from ALL 4 directions at once!\nCtrl: Giant circle of super blasters + x2 speed 4-way tracking sweepers!"},
				{"[T] Beam", "Cyan warning on ground, then neon white vertical beam strike.\nM1 variant (M1+T): 2x size/warn time/duration.\nCtrl variant (Ctrl+T): 4x size/warn time/duration.\nSans performs a layered arm-slamming animation!"},
			}
			combos = {
				{"T + C(M1)", "Combine the Beam (T) with a Phase 2\nChessboard Bone Rise (C+M1) for an\nunavoidable checkerboard trap!"},
				{"Q(Ctrl) + G(Ctrl)", "Fire the Omega Super-Blaster (Ctrl+Q)\nto force the player to dodge left/right,\nthen immediately follow with the Super\nShower (Ctrl+G) to cover the safe zones."},
				{"H(Ctrl) + T", "Activate the Super Circle Blasters (Ctrl+H)\nto trap the player inside the center,\nthen spam the Beam attack (T) through\nthe middle to melt their HP."},
			}
		else
			descriptionsTab1 = {
				{"[V] First Attack", "Builds an arena around the nearest player.\nPhase 1: Corner blasters + bone circles.\nPhase 2: Sweeping blasters + persistent cross beams.\nAuto-cancels if no one is inside the box."},
				{"[B] Fake Final Attack", "Survival challenge. Circular blasters\nsweep inward + crossing sweepers every 2s\n+ overhead tracking blasters. Serious face.\nBlasters secretly deal DOUBLE damage here!"},
				{"[N] True Final Attack", "The real deal — 1m+ of multi-phase madness:\n40s relentless barrage, then final burst.\nUse after [B] to bait the player into thinking\nit's over. Best opener for the fight."},
			}
			descriptionsTab2 = {
				{"[Click] Blue Soul Grab & Drag", "Grab and drag any player with your mouse cursor.\nTurns their soul blue, restricting their movement."},
				{"[R] Homing Bone", "Fires a slow homing bone at the cursor.\nSlows down dramatically when near the target.\nM1 variant (M1+R): Fires a large Stalker Bone that\nfollows the player and CRASHES after 5s."},
				{"[C] Bone Rise", "Spawns a full-size bone rise under the cursor,\nsnapped flush to the floor surface.\nM1 variant (M1+C): Fires 6 small homing bones in a shower."},
				{"[F] Bone Wave", "8-wave bone sweep in the direction of cursor.\nM1 variant (M1+F): Giant Bone Variant (massive area, walls trap players).\nCtrl variant (Ctrl+F): Platform slide over a sea of bones."},
			}
			descriptionsTab3 = {
				{"[Z] Brutal Slam (Grabbed)", "Slam a grabbed player into a wall.\nPress Z while grabbing: Rapid Smash (Variant 1).\nPress Ctrl+Z while grabbing: Gravity Flip onto north/side walls (Variant 2)."},
				{"[Q] Single Blaster", "Fires a blaster at the cursor position.\nM1 variant (M1+Q): Giant slow blaster with massive damage and huge beam."},
				{"[G] Blaster Shower", "Rains blasters from above.\nM1 variant (M1+G): Rotating Circle Blasters.\nCtrl variant (Ctrl+G): Tracking Sweeping Blasters that follow target.\n[Phase 2] Normal: 8 | M1: 2x Bigger | Ctrl: Super Formation"},
				{"[E] Teleportation", "Teleports Sans to the mouse cursor position.\nM1 variant (M1+E): Shadow Backstab (warps behind victim, escaping with a bone rise).\nCtrl variant (Ctrl+E): Freeze Blitz (orbits victim with afterimages, freezing and throwing homing bones)."},
			}
			combos = {
				{"V + R(M1)", "Trigger the First Attack cinematic,\nthen fire a Stalker Bone inside the\narena. Bone crashes into the\ntrapped player after 5s."},
				{"B + N", "Use Fake Final (B) first to wear them\ndef and give a false sense of safety,\nthen immediately follow with the True\nFinal (N) for the real punishment."},
				{"Grab + Z(M1) + R(M1)", "Grab the player, Brutal Slam them onto\na wall (M1 variant), then fire a Stalker\nBone (R+M1). The bone tracks them\nwhile they are stuck on the wall."},
				{"F(Ctrl) + C", "Launch platforms (Ctrl+F), then place\nBone Rises (C) on the platforms\nwhile players are forced to jump\nbetween them."},
				{"G(M1) + Q(M1)", "Start the Rotating circle blasters\n(G+M1) for coverage, then fire the\nGiant Blaster (Q+M1) through the\nmiddle for a punishing combo."},
				{"F(Ctrl) + R(M1)", "Platform trap (Ctrl+F) + Stalker Bone (R+M1) is\npossibly the deadliest combo:\nplayers are stuck jumping between\nplatforms with a bone hunting them."},
			}
		end

		local function renderTab(frame, list)
			local yPos = 5
			for _, entry in ipairs(list) do
				local header = Instance.new("TextLabel", frame)
				header.Size = UDim2.new(1, -20, 0, 16)
				header.Position = UDim2.new(0, 10, 0, yPos)
				header.BackgroundTransparency = 1
				header.Text = entry[1]
				header.TextColor3 = Color3.fromRGB(255, 220, 80)
				header.Font, header.TextSize = Enum.Font.Arcade, 12
				header.TextXAlignment = Enum.TextXAlignment.Left
				yPos = yPos + 17

				local lines = entry[2]:split("\n")
				for _, line in ipairs(lines) do
					local lbl = Instance.new("TextLabel", frame)
					lbl.Size = UDim2.new(1, -25, 0, 13)
					lbl.Position = UDim2.new(0, 15, 0, yPos)
					lbl.BackgroundTransparency = 1
					lbl.Text = line
					lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
					lbl.Font, lbl.TextSize = Enum.Font.Code, 11
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.TextScaled = false
					yPos = yPos + 13
				end
				yPos = yPos + 5
			end
		end

		renderTab(TabFrame1, descriptionsTab1)
		renderTab(TabFrame2, descriptionsTab2)
		renderTab(TabFrame3, descriptionsTab3)

		local function selectTab(tabIndex)
			if tabIndex == 1 then
				TabFrame1.Visible = true
				TabFrame2.Visible = false
				TabFrame3.Visible = false

				btn1.BorderColor3 = Color3.fromRGB(0, 255, 255)
				btn1.TextColor3 = Color3.fromRGB(0, 255, 255)
				btn2.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn2.TextColor3 = Color3.fromRGB(120, 120, 120)
				btn3.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn3.TextColor3 = Color3.fromRGB(120, 120, 120)
			elseif tabIndex == 2 then
				TabFrame1.Visible = false
				TabFrame2.Visible = true
				TabFrame3.Visible = false

				btn1.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn1.TextColor3 = Color3.fromRGB(120, 120, 120)
				btn2.BorderColor3 = Color3.fromRGB(0, 255, 255)
				btn2.TextColor3 = Color3.fromRGB(0, 255, 255)
				btn3.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn3.TextColor3 = Color3.fromRGB(120, 120, 120)
			elseif tabIndex == 3 then
				TabFrame1.Visible = false
				TabFrame2.Visible = false
				TabFrame3.Visible = true

				btn1.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn1.TextColor3 = Color3.fromRGB(120, 120, 120)
				btn2.BorderColor3 = Color3.fromRGB(50, 50, 50)
				btn2.TextColor3 = Color3.fromRGB(120, 120, 120)
				btn3.BorderColor3 = Color3.fromRGB(0, 255, 255)
				btn3.TextColor3 = Color3.fromRGB(0, 255, 255)
			end
		end

		btn1.MouseButton1Click:Connect(function() selectTab(1) end)
		btn2.MouseButton1Click:Connect(function() selectTab(2) end)
		btn3.MouseButton1Click:Connect(function() selectTab(3) end)

		selectTab(1)

		-- Combos Panel — separate panel to the right of the description panel, same K toggle
		local combosPanel = Instance.new("Frame", sg)
		combosPanel.Size = UDim2.new(0, 360, 0, 624)
		combosPanel.Position = UDim2.new(0, 884, 0.5, -312) -- right of descPanel (365 + 504 + 15 = 884)
		combosPanel.BackgroundColor3, combosPanel.BackgroundTransparency = Color3.fromRGB(0, 0, 0), 0.4
		combosPanel.BorderSizePixel, combosPanel.BorderColor3 = 2, Color3.fromRGB(255, 255, 255)
		combosPanel.Visible = false
		_G.SansCombosFrame = combosPanel

		local combosTitle = Instance.new("TextLabel", combosPanel)
		combosTitle.Size, combosTitle.BackgroundTransparency = UDim2.new(1, 0, 0, 36), 1
		combosTitle.Text = "COMBOS"
		combosTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
		combosTitle.Font, combosTitle.TextSize = Enum.Font.Arcade, 15

		-- Combos list is dynamically selected based on phase above

		local cYPos = 45
		for _, entry in ipairs(combos) do
			local header = Instance.new("TextLabel", combosPanel)
			header.Size = UDim2.new(1, -20, 0, 18)
			header.Position = UDim2.new(0, 10, 0, cYPos)
			header.BackgroundTransparency = 1
			header.Text = entry[1]
			header.TextColor3 = Color3.fromRGB(255, 220, 80)
			header.Font, header.TextSize = Enum.Font.Arcade, 12
			header.TextXAlignment = Enum.TextXAlignment.Left
			cYPos = cYPos + 20

			local lines = entry[2]:split("\n")
			for _, line in ipairs(lines) do
				local lbl = Instance.new("TextLabel", combosPanel)
				lbl.Size = UDim2.new(1, -25, 0, 13)
				lbl.Position = UDim2.new(0, 15, 0, cYPos)
				lbl.BackgroundTransparency = 1
				lbl.Text = line
				lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
				lbl.Font, lbl.TextSize = Enum.Font.Code, 11
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextScaled = false
				cYPos = cYPos + 13
			end
			cYPos = cYPos + 10
		end
		combosPanel.Size = UDim2.new(0, 432, 0, 624)

	else
		_G.SansDescFrame = nil
		_G.SansCombosFrame = nil
	end

	Character.AncestryChanged:Connect(function(_, parent)
		if not parent and sg then sg:Destroy() end
	end)
end
pcall(CreateMovesGUI)
