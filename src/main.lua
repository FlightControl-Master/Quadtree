require "MooseStuff"
require "PepperFish"

-- My Code Actually Starts Here
----------------------------------------------------------------------------------------------------------------
Quadrant = {SE= "SE", NE = "NE",  NW = "NW", SW = "SW"}

--- @type POINT
POINT = {
  X,
  Y,
  Data
}

function POINT:New(X, Y, Data)
  local self = BASE:Inherit( self, BASE:New() )
  self.X = X
  self.Y = Y
  self.Data = Data
  --print("New Point : "..self.X..", "..self.Y..", "..self.Data)
  return self
end

function POINT:Distance(Point)
  -- This is not cool for the programer, but very optimized... sorry :)
  -- dont use math.pow it is slow af !
  return math.sqrt((self.X - Point.X) * (self.X - Point.X) + (self.Y - Point.Y) * (self.Y - Point.Y)) 
end

--- @type BOUNDING_BOX
BOUNDING_BOX = {
  X,
  Y,
  W,
  H
}

function BOUNDING_BOX:New(X, Y, W, H)
  local self = BASE:Inherit( self, BASE:New() )
  self.X = X
  self.Y = Y
  self.W = W
  self.H = H
  return self
end

function BOUNDING_BOX:ContainPoint(Point) -- @TODO : Optimize this shit to death
  if Point.X > self.X then
    if Point.X <= self.W + self.X then
      if Point.Y > self.Y then
        if Point.Y <= self.H + self.Y then
          return true
        end
      end
    end
  end
  return false
end

function BOUNDING_BOX:Intersect(CircleCenter, CircleRadius)
  -- This is not cool for the programer, but very optimized... sorry :)

  local HalfW = self.W/2
  local HalfH = self.H/2

  local cx = math.abs(CircleCenter.X - self.X - HalfW)
  local xDist = HalfW + CircleRadius 
  if (cx > xDist) then return false end
  
  local cy = math.abs(CircleCenter.Y - self.Y - HalfH)
  local yDist = HalfH + CircleRadius
  if (cy > yDist) then return false end
  
  if (cx <= HalfW or cy <= HalfH) then return true end
  
  
  local xCornerDist = cx - HalfW
  local yCornerDist = cy - HalfH
  local xCornerDistSq = xCornerDist * xCornerDist
  local yCornerDistSq = yCornerDist * yCornerDist
  local maxCornerDistSq = CircleRadius * CircleRadius
  return xCornerDistSq + yCornerDistSq <= maxCornerDistSq

end

function BOUNDING_BOX:GetNewQuadrants()
  local X = self.X
  local Y = self.Y
  local W = self.W
  local H = self.H
  local BoundingBoxes =  {}
  
  BoundingBoxes[1] = BOUNDING_BOX:New(X, Y, W/2, H/2)
  BoundingBoxes[2] = BOUNDING_BOX:New(X, Y + H/2, W/2, H/2)
  BoundingBoxes[3] = BOUNDING_BOX:New(X + W/2, Y + H/2, W/2, H/2)
  BoundingBoxes[4] = BOUNDING_BOX:New(X + W/2, Y, W/2, H/2)
  return BoundingBoxes
end

--- @type NODE
NODE = {
  Point = nil,
  BoundingBox,
  Node_SE,
  Node_NE,
  Node_NW,
  Node_SW,
  Node_Previous
}

function NODE:New(BoundingBox, Node_Previous)
  local self = BASE:Inherit( self, BASE:New() )
  self.BoundingBox = BoundingBox
  self.Node_Previous = Node_Previous
  --print("New NODE ! Bounding Box : X="..self.BoundingBox.X.." Y="..self.BoundingBox.Y.." Width = "..self.BoundingBox.W.." Height = "..self.BoundingBox.H)
  return self
end

function NODE:_Subdivide()
  local NewBoundingBoxes = self.BoundingBox:GetNewQuadrants()
  self.Node_SE = NODE:New(NewBoundingBoxes[1], self)
  self.Node_NE = NODE:New(NewBoundingBoxes[2], self)
  self.Node_NW = NODE:New(NewBoundingBoxes[3], self)
  self.Node_SW = NODE:New(NewBoundingBoxes[4], self)
  return self
end

function NODE:Insert(Point)
  if not self.BoundingBox:ContainPoint(Point) then
    --print("Point "..Point.Data.." does not fit in this Quadtree")
    return false
  end
  
  if self.Point == nil then
    --print("Point "..Point.Data.." added to this Quadtree")
    self.Point = Point
    return true
  end
  
  --print("There is already a POINT here, need to subdivide !")
  if self.Node_SE == nil then
    self:_Subdivide()
  end
  
  if self.Node_SE:Insert(Point) then return true end
  if self.Node_NE:Insert(Point) then return true end
  if self.Node_NW:Insert(Point) then return true end
  if self.Node_SW:Insert(Point) then return true end
  
  --print("The POINT didn't fit in any of the subdivisions")
end

--- @type QUADTREE
QUADTREE = {}

function QUADTREE:New(BoundingBox)
  local self = BASE:Inherit( self, NODE:New(BoundingBox) )
  self.Node_Previous = nil
  return self
end

function QUADTREE:Print()
  local Queue = {self}
  
  while table.maxn(Queue) > 0 do
    local LevelNodes = table.maxn(Queue)
    while LevelNodes > 0 do
      if Queue[1].Node_SE then
        io.write(" "..Queue[1].Point.Data)
        table.insert(Queue, Queue[1].Node_SE)
        table.insert(Queue, Queue[1].Node_NE)
        table.insert(Queue, Queue[1].Node_NW)
        table.insert(Queue, Queue[1].Node_SW)
      end
      table.remove(Queue, 1)
      LevelNodes = LevelNodes - 1
    end
    io.write("\n")
  end
      
end

function QUADTREE:Find(Point)
  local CurrentNode = self
  local i = 0
  while true do
  
    if CurrentNode.Point then
      if CurrentNode.Point.Data == Point.Data then
        --print("Unit found. Search Depth : "..i)
        return CurrentNode
      end
    end 
    
    if not CurrentNode.Node_SE then
      --print("Unit not found. Search Depth : "..i)
      break
    end
    
    i = i+1
    
    if CurrentNode.Node_SE.BoundingBox:ContainPoint(Point) then
      CurrentNode = CurrentNode.Node_SE
      --print("Taking SE route !")
    elseif CurrentNode.Node_NE.BoundingBox:ContainPoint(Point) then
      CurrentNode = CurrentNode.Node_NE
      --print("Taking NE route !")
    elseif CurrentNode.Node_NW.BoundingBox:ContainPoint(Point) then
      CurrentNode = CurrentNode.Node_NW
      --print("Taking NW route !")
    elseif CurrentNode.Node_SW.BoundingBox:ContainPoint(Point) then
      CurrentNode = CurrentNode.Node_SW
      --print("Taking SW route !")
    end
  end
    
  -- This would be good enough if the UNIT stayed in its square since last update. But it may not be the case
  -- so we need to walk back the tree, comparing the Point to any Point found in the Tree.
  -- This should be still efficient, as Units usually don't move too much too fast
  -- This will be very inefficient if the UNIT is an OVNI, moving at light speed
  --print("Unit moved, searching around...")
  
  local PotentialUnits = {}
  local PotentialUnitsSize
  local PreviousSize
  local Radius = 100
  
  while not CurrentNode.Point do
    CurrentNode = CurrentNode.Node_Previous
  end
  
  while true do
    
    -- print("Search radius : "..tostring(Radius))
    
    PotentialUnits = self:PointsInCircle(CurrentNode.Point, Radius)
    PotentialUnitsSize = table.getn(PotentialUnits)
    
    if PotentialUnitsSize > 0 then
      
      if PotentialUnitsSize >= 1E12 then
        return nil
      end
    
      for i=1, PotentialUnitsSize do
        
        if PotentialUnits[i].Data == Point.Data then
          print(Radius)
          return PotentialUnits[i]
        end
      end
      
      PreviousSize = PotentialUnitsSize 
    end
    
    Radius = Radius + 100
     
  end
    
  --[[
  i=0
  local Queue = {}
  local PreviousNode
  while CurrentNode do
    i=i+1
    --print("BFS #"..i)
    
    PreviousNode = CurrentNode
    
    if not CurrentNode.Node_Previous then break end
    CurrentNode = CurrentNode.Node_Previous
    
    if CurrentNode.Node_SE ~= PreviousNode then table.insert(Queue, CurrentNode.Node_SE) end
    if CurrentNode.Node_NE ~= PreviousNode then table.insert(Queue, CurrentNode.Node_NE) end
    if CurrentNode.Node_NW ~= PreviousNode then table.insert(Queue, CurrentNode.Node_NW) end
    if CurrentNode.Node_SW ~= PreviousNode then table.insert(Queue, CurrentNode.Node_SW) end
    
    -- Breadth First Search with CurrentNode as a Root Node, exluding the tree already searched
    while table.maxn(Queue) > 0 do
      if Queue[1].Point then
        if Queue[1].Point.Data == Point.Data then
          --print("Unit Found !")
          return Queue[1]
        end
      end
      if Queue[1].Node_SE then
        table.insert(Queue, Queue[1].Node_SE)
        table.insert(Queue, Queue[1].Node_NE)
        table.insert(Queue, Queue[1].Node_NW)
        table.insert(Queue, Queue[1].Node_SW)
      end
      
      table.remove(Queue, 1)
    end
  end
  return nil
  ]]--
  
end

function QUADTREE:_Remove(Node, ParentNode, Quadrant)
  if Node.Node_SE then
    ParentNode[Quadrant] = Node.Node_SE
    Node.Node_Parent = ParentNode
  elseif Node.Node_NE then
    ParentNode[Quadrant] = Node.Node_NE
    Node.Node_Parent = ParentNode
  elseif Node.Node_NW then
    ParentNode[Quadrant] = Node.Node_NW
    Node.Node_Parent = ParentNode
  elseif Node.Node_SW then
    ParentNode[Quadrant] = Node.Node_SW
    Node.Node_Parent = ParentNode
  else
    ParentNode[Quadrant] = NODE:New(ParentNode[Quadrant].BoundingBox, ParentNode)
  end
end

function QUADTREE:Remove(Point)
  local CurrentNode = self:Find(Point)
  
  if not CurrentNode then
    return nil
  end

  if not CurrentNode.Node_Previous then
    CurrentNode.Point = nil
    return true
  end
  
  local ParentNode = CurrentNode.Node_Previous
  local ParentQuadrant
  
  if ParentNode.Node_SE then
    if ParentNode.Node_SE.Point then
      if ParentNode.Node_SE.Point.Data == CurrentNode.Point.Data then
        self:_Remove(CurrentNode, ParentNode, "Node_SE")
      end
    end
  end
  if ParentNode.Node_NE then
    if ParentNode.Node_NE.Point then
      if ParentNode.Node_NE.Point.Data == CurrentNode.Point.Data then
        self:_Remove(CurrentNode, ParentNode, "Node_NE")
      end
    end
  end
  if ParentNode.Node_NW then
    if ParentNode.Node_NW.Point then
      if ParentNode.Node_NW.Point.Data == CurrentNode.Point.Data then
        self:_Remove(CurrentNode, ParentNode, "Node_NW")
      end
    end
  end
  if ParentNode.Node_SW then
    if ParentNode.Node_SW.Point then
      if ParentNode.Node_SW.Point.Data == CurrentNode.Point.Data then
        self:_Remove(CurrentNode, ParentNode, "Node_SW")
      end
    end
  end
end

function QUADTREE:NearestNeighbour(Point)
  local Stack = {self}
  local CurrentNode
  local CurrentDist
  local CurrentRadius = 1E12
  local NearestNeighbour
  local NNDist = 1E12
  local i = 0
  
  while true do
    i = i + 1
    print("Step : "..tostring(i))
    
    CurrentNode = Stack[table.maxn(Stack)]
    table.remove(Stack)
    
    if not CurrentNode then break end
    
    if CurrentNode.Node_SE then
    
      if CurrentNode.Node_SE.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_SE)
        if CurrentNode.Node_SE.Point then
        CurrentDist = Point:Distance(CurrentNode.Node_SE.Point)
          if CurrentDist < CurrentRadius then
            NearestNeighbour = CurrentNode.Node_SE.Point
            CurrentRadius = CurrentDist
          end 
        end
      end
      
      if CurrentNode.Node_NE.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_NE)
        if CurrentNode.Node_NE.Point then
          CurrentDist = Point:Distance(CurrentNode.Node_NE.Point)
          if CurrentDist < CurrentRadius then
            NearestNeighbour = CurrentNode.Node_NE.Point
            CurrentRadius = CurrentDist
          end
        end
      end
      if CurrentNode.Node_NW.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_NW) 
        if CurrentNode.Node_NW.Point then
          CurrentDist = Point:Distance(CurrentNode.Node_NW.Point)
          if CurrentDist < CurrentRadius then
            NearestNeighbour = CurrentNode.Node_NW.Point
            CurrentRadius = CurrentDist
          end
        end
      end
      if CurrentNode.Node_SW.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_SW)
        if CurrentNode.Node_SW.Point then
          CurrentDist = Point:Distance(CurrentNode.Node_SW.Point)
          if CurrentDist < CurrentRadius then
            NearestNeighbour = CurrentNode.Node_SW.Point
            CurrentRadius = CurrentDist
          end
        end
      end
    end
    
    if Point.X == NearestNeighbour.X then
      if Point.Y == NearestNeighbour.Y then
        print("Point Already Exists !")
        break
      end
    end
    
  end 
  return NearestNeighbour
end

function QUADTREE:ExistingPointNearestNeighbour(Point)
  local Stack = {self}
  local CurrentNode
  local CurrentDist
  local CurrentRadius = 1E12
  local NearestNeighbour
  local NNDist = 1E12
  local i = 0

  
  while true do
    i = i + 1
    print("Step : "..tostring(i))
    
    CurrentNode = Stack[table.maxn(Stack)]
    table.remove(Stack)
    
    if not CurrentNode then break end
    
    if CurrentNode.Node_SE then
    
      if CurrentNode.Node_SE.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_SE)
        if CurrentNode.Node_SE.Point then
          if CurrentNode.Node_SE.Point.Data ~= Point.Data then
          CurrentDist = Point:Distance(CurrentNode.Node_SE.Point)
            if CurrentDist < CurrentRadius then
              NearestNeighbour = CurrentNode.Node_SE.Point
              CurrentRadius = CurrentDist
            end
          end 
        end
      end
      
      if CurrentNode.Node_NE.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_NE)
        if CurrentNode.Node_NE.Point then
          if CurrentNode.Node_NE.Point.Data ~= Point.Data then
            CurrentDist = Point:Distance(CurrentNode.Node_NE.Point)
            if CurrentDist < CurrentRadius then
              NearestNeighbour = CurrentNode.Node_NE.Point
              CurrentRadius = CurrentDist
            end
          end
        end
      end
      if CurrentNode.Node_NW.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_NW) 
        if CurrentNode.Node_NW.Point then
          if CurrentNode.Node_NW.Point.Data ~= Point.Data then
            CurrentDist = Point:Distance(CurrentNode.Node_NW.Point)
            if CurrentDist < CurrentRadius then
              NearestNeighbour = CurrentNode.Node_NW.Point
              CurrentRadius = CurrentDist
            end
          end
        end
      end
      if CurrentNode.Node_SW.BoundingBox:Intersect(Point, CurrentRadius) then
        table.insert(Stack, CurrentNode.Node_SW)
        if CurrentNode.Node_SW.Point then
          if CurrentNode.Node_SW.Point.Data ~= Point.Data then
            CurrentDist = Point:Distance(CurrentNode.Node_SW.Point)
            if CurrentDist < CurrentRadius then
              NearestNeighbour = CurrentNode.Node_SW.Point
              CurrentRadius = CurrentDist
            end
          end
        end
      end
    end
    
  end 
  return NearestNeighbour
end

function QUADTREE:PointsInCircle(Center, Radius)
  local Stack = {self}
  local CurrentNode
  local CurrentDist
  local PointsInCircle = {}
  local i = 0
  
  while true do
    i = i + 1
    -- print("Step : "..tostring(i))
    
    CurrentNode = Stack[table.maxn(Stack)]
    table.remove(Stack)
    
    if not CurrentNode then break end
    
    if CurrentNode.Node_SE then
    
      if CurrentNode.Node_SE.BoundingBox:Intersect(Center, Radius) then
        table.insert(Stack, CurrentNode.Node_SE)
        if CurrentNode.Node_SE.Point then
        CurrentDist = Center:Distance(CurrentNode.Node_SE.Point)
          if CurrentDist < Radius then
            table.insert(PointsInCircle, CurrentNode.Node_SE.Point)
          end 
        end
      end
   
      if CurrentNode.Node_NE.BoundingBox:Intersect(Center, Radius) then
        table.insert(Stack, CurrentNode.Node_NE)
        if CurrentNode.Node_NE.Point then
        CurrentDist = Center:Distance(CurrentNode.Node_NE.Point)
          if CurrentDist < Radius then
            table.insert(PointsInCircle, CurrentNode.Node_NE.Point)
          end 
        end
      end
      
      if CurrentNode.Node_NW.BoundingBox:Intersect(Center, Radius) then
        table.insert(Stack, CurrentNode.Node_NW)
        if CurrentNode.Node_NW.Point then
        CurrentDist = Center:Distance(CurrentNode.Node_NW.Point)
          if CurrentDist < Radius then
            table.insert(PointsInCircle, CurrentNode.Node_NW.Point)
          end 
        end
      end
      
      if CurrentNode.Node_SW.BoundingBox:Intersect(Center, Radius) then
        table.insert(Stack, CurrentNode.Node_SW)
        if CurrentNode.Node_SW.Point then
        CurrentDist = Center:Distance(CurrentNode.Node_SW.Point)
          if CurrentDist < Radius then
            table.insert(PointsInCircle, CurrentNode.Node_SW.Point)
          end 
        end
      end
    end
    
  end 
  return PointsInCircle
end


-- Main
-------------------------------------------------------------------------------------
require "Tests"


math.randomseed(os.time())
--[[
profiler = newProfiler()
profiler:start()
--]]
for i=1, 20 do
  local MyQuadtree = QUADTREE:New(BOUNDING_BOX:New(0, 0, 10000, 10000))
  
  QuadtreeTestInsert(MyQuadtree, 10000, 10000, 1000)

  -- MyQuadtree:Print()
  collectgarbage(collect)
end
--]]
--[[
for i=1, 20 do
  local Array = {}
  ArrayTestRemove(Array, 100000, 10000)
end
--]]
--[[
--local outfile = io.open( "profile.txt", "w+" )
--profiler:stop()
--profiler:report( outfile )
--outfile:close()
--]]