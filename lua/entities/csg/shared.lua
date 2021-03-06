include("csg.lua")
DEFINE_BASECLASS( "base_anim" )
ENT.PrintName = "CSG"
ENT.Author = ""
ENT.Information = ""
ENT.Category = "Fun + Games"
ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false

local defaultSize = 16.0
local gridSize = 1.0
local angleSnap = 45.0
	
function ENT:Initialize()
	self.translationRotationMatrix = Matrix()
	self.translationRotationMatrix:Identity()
	
	self.scaleMatrix = Matrix()
	self.scaleMatrix:Identity()
	
	self:Build()
end

function ENT:GetFullMatrix()
	return self.translationRotationMatrix * self.scaleMatrix
end

function ENT:Think()
	if (SERVER) then
		local pos = self:GetPos()
		pos.x = math.Round(pos.x / gridSize) * gridSize
		pos.y = math.Round(pos.y / gridSize) * gridSize
		pos.z = math.Round(pos.z / gridSize) * gridSize		
		self:SetPos(pos)
		
		local angles = self:GetAngles()
		angles.p = math.Round(angles.p / angleSnap) * angleSnap
		angles.y = math.Round(angles.y / angleSnap) * angleSnap
		angles.r = math.Round(angles.r / angleSnap) * angleSnap
		self:SetAngles(angles)
	end
	
	self.translationRotationMatrix:Identity()
	self.translationRotationMatrix:Translate(self:GetPos())
	self.translationRotationMatrix:Rotate(self:GetAngles())
	
	self.scaleMatrix:Identity()
	self.scaleMatrix:Scale(self:GetSize() * self:GetSizeMultiplier()) 
	
	if (self:GetChanged()) then
		self:Build()
		self:SetChanged(false)
	end
end

function ENT:Build(useTranslationRotationMatrix)
	self.shape = CSG.cube({radius = Vector(1.0, 1.0, 1.0)}) --todo: use the extra shapes from library (spheres, cylinders)
	
	local matrix
	if (useTranslationRotationMatrix) then
		matrix = self.translationRotationMatrix
	else
		matrix = self.scaleMatrix
	end
	
	local color
	if (self:GetAdditive()) then
		color = Color(0,0,255,128)
	else
		color = Color(255,0,0,128)	
	end
	
	self.points, self.vertices, self.tmin, self.tmax = self.shape:toMesh(color, matrix)
	
	if (CLIENT) then
		self.mesh = Mesh()
		self.mesh:BuildFromTriangles(self.vertices)	
		self:SetRenderBounds(self.tmin, self.tmax)
		self:SetModel("")
	else
		self:PhysicsFromMesh(self.vertices)
		self:SetMoveType(MOVETYPE_NOCLIP)
		self:SetSolid(SOLID_BSP)
		self:EnableCustomCollisions(true)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end
end

function ENT:SetupDataTables()
	self.skipEvent = false	
	
	--todo: entities need a "order" variable to define the csg operations execution order
	self:NetworkVar("Bool", 0, "Changed")
	self:NetworkVar("Vector", 1, "Pos", {KeyName = "pos", Edit = {type = "Vector", order = 1}})
	self:NetworkVar("Angle", 2, "Angles", {KeyName = "angles", Edit = {type = "Angle", order = 2}})
	self:NetworkVar("Vector", 3, "Size", {KeyName = "size", Edit = {type = "Vector", order = 3}})
	self:NetworkVar("Float", 4, "SizeMultiplier", {KeyName = "SizeMultiplier", Edit = {type = "float", order = 4}})
	self:NetworkVar("Bool", 5, "Additive", {KeyName = "additive", Edit = {type = "Boolean", order = 5}})
	
	if (SERVER) then
		self:SetSize(Vector(defaultSize, defaultSize, defaultSize))
		self:SetSizeMultiplier(1.0)
		self:SetAdditive(true)
		self:SetChanged(true)
	end
	
	self:NetworkVarNotify("Size", self.OnVarChanged)
	self:NetworkVarNotify("SizeMultiplier", self.OnVarChanged)
	self:NetworkVarNotify("Additive", self.OnVarChanged)
end

function ENT:OnVarChanged(varname, oldvalue, newvalue)
	if (varname == "Changed" or self.skipEvent) then
		return
	end	
	
	--self.skipEvent = true --avoid triggering this event forever
	--
	--local size = self:GetSize()
	--size.x = math.Min(gridSize, math.Round(size.x / gridSize) * gridSize)
	--size.y = math.Min(gridSize, math.Round(size.y / gridSize) * gridSize)
	--size.z = math.Min(gridSize, math.Round(size.z / gridSize) * gridSize)		
	--self:SetSize(size)
	--
	--local sizeMultiplier = self:GetSizeMultiplier()
	--sizeMultiplier = math.Min(gridSize, math.Round(sizeMultiplier / gridSize) * gridSize)
	--self:SetSizeMultiplier(sizeMultiplier)
	--
	--self.skipEvent = false
	
	self:SetChanged(true)
end