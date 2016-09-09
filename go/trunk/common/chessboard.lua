
local MaxHeight = 19
local MaxWidth = 19
local InfluenceRange = 3
local InfluenceBase = 2      --影响力基数
local MaxRange = MaxWidth*MaxHeight
local CHESSCOLOR ={Black = 0,White = 1,}
local Goboard = 
{
	GoboardTable = {},   --棋子
	Influence = {},	--影响力
}
 

local CaptureList = {}
local ChessLink = {}
--local chess = {color=CHESSCOLOR.Black,gas=4,pos={}}
local ChessPlayer = 1
function InitGoBoard(...)
	if Goboard ~= nil then
		for k,v in pairs(Goboard) do
			v=nil
		end
		Goboard = {}
		Goboard.Influence = {}
		for i=1,MaxWidth*MaxHeight do
			Goboard.Influence[i] = 0
		end
	end
end

local function GetPosValid( PosX,PosY )
	if (PosX > 0 and PosX <= MaxWidth) and (PosY > 0 and PosY <= MaxHeight) then 
		return 1
	end
	return 0
end

local function RecoveryPos( Pos )
	if Pos > 0 and Pos <= MaxWidth*MaxHeight then
		if Pos > MaxWidth then
			local PosX = Pos % MaxWidth
			local PosY = ((Pos - PosX)/MaxHeight) + 1
			return PosX,PosY
		else
			return Pos,1
		end
	end 
	return nil
end 

local function IsValidPos( Pos )
	local PosX,PosY = RecoveryPos(Pos)
	if PosX ~= nil then
		return GetPosValid(PosX,PosY)
	end
	return 0
end 

local function CoverPos(PosX,PosY  )
	return (PosY - 1) *MaxWidth + PosX
end 



function Goboard:new(o )
	 o = o or {}
	 setmetatable(o, self)
	 self.__index = self 
	 self.Influence = {}
	for i=1,MaxWidth*MaxHeight do
		self.Influence[i] = 0
	end
	 return o
end

function Goboard:GetChess( PosX,PosY ) --坐标上棋子
	if GetPosValid(PosX,PosY) > 0 then 
	 	local Pos = CoverPos(PosX,PosY)
		if self.GoboardTable ~= nil then
			if self.GoboardTable[Pos] ~= nil and self.GoboardTable[Pos].color ~= nil then
				return self.GoboardTable[Pos]
			end
		end
	end
	return nil
end

function Goboard:GetPosChess( Pos ) --坐标上棋子
	local PosX,PosY = RecoveryPos(Pos)
	if PosX ~= nil then
		return self:GetChess(PosX,PosY)
	end
	return nil
end



function Goboard:GetGas(Player,PosX,PosY)  --获取坐标的气
	local Gasnum = 4
	--local chess =  self:GetChess(PosX,PosY)
	--print(self.GoboardTable==nil)
	if self.GoboardTable ~= nil then
		if PosY == 1 or PosY == MaxHeight then
			Gasnum = Gasnum - 1
		end

		if PosX == 1 or PosX == MaxWidth then
			Gasnum = Gasnum - 1
		end

		local chesscolor = 0
		if Player == 1 then
			chesscolor = CHESSCOLOR.Black
		else
			chesscolor = CHESSCOLOR.White
		end

		if PosX > 1 then
			local other = self:GetChess(PosX-1,PosY)
			if other ~= nil  then
				Gasnum = Gasnum - 1
			end
		end

		if PosX < MaxWidth then
			local other = self:GetChess(PosX+1,PosY)
			if other ~= nil then
				Gasnum = Gasnum - 1
			end
		end

		if PosY > 1 then
			local other = self:GetChess(PosX,PosY-1)
			if other ~= nil  then
				Gasnum = Gasnum - 1
			end
		end

		if PosY < MaxHeight then
			local other = self:GetChess(PosX,PosY+1)
			if other ~= nil  then
				Gasnum = Gasnum - 1
			end
		end

		return Gasnum
	end
	return 0
end


function Goboard:GetPosGas(Pos)  --获取坐标的气
	local PosX,PosY = RecoveryPos(Pos)
	if PosX ~= nil then
		return self:GetGas(1,PosX,PosY)
	end
	return 0
end

function Goboard:MergeLink( link1,link2 )
	if ChessLink[link1] ~= nil and ChessLink[link2] ~= nil then
		for k,v in pairs(ChessLink[link2].linkid) do
			local other = self:GetPosChess(v)
			if other ~= nil then
				other.link = link1
			end
			table.insert(ChessLink[link1].linkid,v)
			ChessLink[link1].linknum = ChessLink[link1].linknum + 1
		end
		ChessLink[link2] = nil
		ChessLink[link2] = {}
		ChessLink[link2].linkid = {}
		ChessLink[link2].linknum = 0
	end
end

function Goboard:CreateLink( Pos1,Pos2 )
	local linkindex = #ChessLink
	local bcreatelink = 0
	if linkindex > 0 then
		for i,v in ipairs(ChessLink) do
			if v.linknum == 0 then  --合并后的空链接
				table.insert(v.linkid,Pos1)
				table.insert(v.linkid,Pos2)
				v.linknum = 2
				return i
			end
		end
	end

	linkindex = linkindex + 1
	ChessLink[linkindex] = {}
	local linktable = {}
	linktable.linknum = 2
	linktable.linkid = {}
	table.insert(linktable.linkid,Pos1)
	table.insert(linktable.linkid,Pos2)
	ChessLink[linkindex] = linktable
	return linkindex
end

function Goboard:AddToLink( linkindex,Pos )
	if ChessLink[linkindex] ~= nil then
		table.insert(ChessLink[linkindex].linkid,Pos)
		ChessLink[linkindex].linknum = ChessLink[linkindex].linknum + 1
		return 1
	end
	return 0
end

function Goboard:UpdateLink( linkindex,Pos,color )
	if Pos > 1 then
		if Pos % MaxWidth > 1 then
			local other = self:GetPosChess(Pos-1)
			if other ~= nil and other.color == color then
				if other.link > 0 and other.link ~= linkindex then
					if other.link > linkindex then
						self:MergeLink(linkindex,other.link)
					else
						self:MergeLink(other.link,linkindex)
					end
				elseif other.link == 0 then
					other.link = linkindex
					self:AddToLink(linkindex,Pos-1)
				end
			end	
		end

	end

	if Pos < MaxWidth then
		if Pos % MaxWidth > 1 then
			local other = self:GetPosChess(Pos+1)
			if other ~= nil and other.color == color then
				if other.link > 0 and other.link ~= linkindex then
					if other.link > linkindex then
						self:MergeLink(linkindex,other.link)
					else
						self:MergeLink(other.link,linkindex)
					end
				elseif other.link == 0 then
					other.link = linkindex
					self:AddToLink(linkindex,Pos+1)
				end
			end	
		end
	end

	if Pos > MaxWidth then
		local bpos = Pos - MaxWidth
		local other = self:GetPosChess(bpos)
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				if other.link > linkindex then
					self:MergeLink(linkindex,other.link)
				else
					self:MergeLink(other.link,linkindex)
				end
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,bpos)
			end
		end	
	end

	if Pos + MaxWidth <= MaxWidth * MaxHeight then
		local tpos = Pos + MaxWidth
		local other = self:GetPosChess(tpos)
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				if other.link > linkindex then
					self:MergeLink(linkindex,other.link)
				else
					self:MergeLink(other.link,linkindex)
				end
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,tpos)
			end
		end	
	end
end

function Goboard:PutChess( Pos,chess )
	self.GoboardTable[Pos] = chess
	self:ComputeInf(Pos,chess.color)
end

function Goboard:PlayerMove(Player,PosX,PosY) 
	local chess = {}
	if GetPosValid(PosX,PosY) == 0 then 
		print("InValid Pos ")
		return 0
	end
	
	if Player == 1 then
		chess.color = CHESSCOLOR.Black
	else
		chess.color = CHESSCOLOR.White
	end


	local other = self:GetChess(PosX,PosY)
	if other ~= nil then
		print("other chess had "..other.color)
		return 0
	end

	

	local Gasnum = self:GetGas(Player,PosX,PosY)
	assert(Gasnum>=0,"GetGas Error")
	if Gasnum == 0 then
		print("Gasnum == 0 ")
		return 0
	end

	chess.gas = Gasnum
	chess.link = 0
	
	if PosX > 1 then
		local other = self:GetChess(PosX-1,PosY)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				self:AddToLink(chess.link,Pos1)
				self:UpdateLink(chess.link,Pos1,chess.color)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			elseif other.link == 0 then
				local Pos1 = CoverPos(PosX,PosY)
				local Pos2 = CoverPos(PosX-1,PosY)
				local linkid = self:CreateLink(Pos1,Pos2)
				chess.link = linkid
				other.link = linkid
				self:UpdateLink(chess.link,Pos1)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			end
		end
	end

	if PosX < MaxWidth then
		local other = self:GetChess(PosX+1,PosY)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				self:AddToLink(chess.link,Pos1)
				self:UpdateLink(chess.link,Pos1,chess.color)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			elseif other.link == 0  then
				local Pos1 = CoverPos(PosX,PosY)
				local Pos2 = CoverPos(PosX+1,PosY)
				local linkid = self:CreateLink(Pos1,Pos2)
				chess.link = linkid
				other.link = linkid
				self:UpdateLink(chess.link,Pos1)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			end
		end
	end

	if PosY > 1 then
		local other = self:GetChess(PosX,PosY-1)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				self:AddToLink(chess.link,Pos1)
				self:UpdateLink(chess.link,Pos1,chess.color)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			elseif other.link == 0  then
				local Pos1 = CoverPos(PosX,PosY)
				local Pos2 = CoverPos(PosX,PosY-1)
				local linkid = self:CreateLink(Pos1,Pos2)
				chess.link = linkid
				other.link = linkid
				self:UpdateLink(chess.link,Pos1)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			end
		end
	end

	if PosY < MaxHeight then
		local other = self:GetChess(PosX,PosY+1)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				self:AddToLink(chess.link,Pos1)
				self:UpdateLink(chess.link,Pos1,chess.color)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			elseif other.link == 0  then
				local Pos1 = CoverPos(PosX,PosY)
				local Pos2 = CoverPos(PosX,PosY+1)
				local linkid = self:CreateLink(Pos1,Pos2)
				chess.link = linkid
				other.link = linkid
				self:UpdateLink(chess.link,Pos1)
				print(Pos1.."put chess")
				self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				return 1
			end
		end
	end
	local Pos1 = CoverPos(PosX,PosY)
	self:PutChess(Pos1,chess)
	--self.GoboardTable[Pos1] = chess
	print(Pos1.."put chess")
	return 1
end

function Goboard:EatChess(Pos)
	self.GoboardTable[Pos] = nil
	self.GoboardTable[Pos] = {}
end

function Goboard:CapturesChess(  )
	--print("CapturesChess")
	local linknum = #ChessLink
	if linknum > 0 then
		local InValidLink = 0
		for i,v in ipairs(ChessLink) do
			local linkgas = 0
			if v.linknum > 0 then
				for j,k in pairs(v.linkid) do
					linkgas = linkgas + self:GetPosGas(k)
				end
				if linkgas == 0 then
					for j,k in pairs(v.linkid) do
						self:EatChess(k)
					end
					InValidLink = i
				end
			end
			if InValidLink > 0 then
				v.linkid = nil
				v.linkid = {}
				v.linknum = 0
				InValidLink = 0
			end
		end
	end

end

function Goboard:Print( ... )
	local file = io.open("D:\\work\\framework\\go\\chess.txt","w+")
	if file ~= nil then
		local x ,y = self:ChessInfluence()
		file:write("black : "..x.." \n")
		file:write("white : "..y.." \n")
		for i=1,MaxHeight do
			for v=1,MaxHeight do

				local other = self:GetChess(i,v)
				if other ~= nil and other.color ~= nil then
					file:write(other.color.." ")
				else
					file:write("x ")
				end

				if v % MaxHeight == 0 then
					file:write("\n")
				end
			end
		end
		io.close(file)
	end

end

function Goboard:GetInfluence(PosX,PosY,color,level )
	local chessInfluence = 0
	local InfluencePos = 0
	if GetPosValid(PosX,PosY) > 0 then
		InfluencePos = CoverPos(PosX,PosY)
		if  self.Influence[InfluencePos] == nil then
			self.Influence[InfluencePos] = 0
		end 
		chessInfluence = self.Influence[InfluencePos]
		local chess = self:GetPosChess(InfluencePos)
		if chess ~= nil and chess.color ~= nil then
			if chessInfluence > 0 then
				self.Influence[InfluencePos] = 0
			end
		else
			local InfluencePower = 0
			if level == 1 then
				InfluencePower = InfluenceBase
			elseif level == 2 then
				InfluencePower = InfluenceBase * InfluenceBase
			else
				InfluencePower = InfluenceBase * InfluenceBase * InfluenceBase
			end

			if color == CHESSCOLOR.Black then
				chessInfluence = chessInfluence + InfluencePower
			else
				chessInfluence = chessInfluence - InfluencePower
			end
			self.Influence[InfluencePos] = chessInfluence
		end
		print("return  ".." Pos "..InfluencePos.." Influence "..chessInfluence)
	end
	--
	return chessInfluence
end

function Goboard:ComputeInf( Pos,color)
	local PosX,PosY = RecoveryPos(Pos)
	if PosX == nil then
		return
	end
	for i=1,3 do
		--print("ComputeInf "..Pos)
		if i == 1 then
			self:GetInfluence(PosX-2,PosY+i,color,1)
			self:GetInfluence(PosX-1,PosY+i,color,2)
			self:GetInfluence(PosX,PosY+i,color,3)
			self:GetInfluence(PosX+2,PosY+i,color,1)
			self:GetInfluence(PosX+1,PosY+i,color,2)
		elseif i == 2 then
			self:GetInfluence(PosX-1,PosY+i,color,1)
			self:GetInfluence(PosX,PosY+i,color,2)
			self:GetInfluence(PosX+1,PosY+i,color,1)
		else
			self:GetInfluence(PosX,PosY+i,color,1)
		end
	end

	for i=-3,-1 do
		if i == -1 then
			self:GetInfluence(PosX-2,PosY+i,color,1)
			self:GetInfluence(PosX-1,PosY+i,color,2)
			self:GetInfluence(PosX,PosY+i,color,3)
			self:GetInfluence(PosX+2,PosY+i,color,1)
			self:GetInfluence(PosX+1,PosY+i,color,2)
		elseif i == -2 then
			self:GetInfluence(PosX-1,PosY+i,color,1)
			self:GetInfluence(PosX,PosY+i,color,2)
			self:GetInfluence(PosX+1,PosY+i,color,1)
		else
			self:GetInfluence(PosX,PosY+i,color,1)
		end
	end

	self:GetInfluence(PosX-3,PosY,color,1)
	self:GetInfluence(PosX-2,PosY,color,2)
	self:GetInfluence(PosX-1,PosY,color,3)
	self:GetInfluence(PosX+3,PosY,color,1)
	self:GetInfluence(PosX+2,PosY,color,2)
	self:GetInfluence(PosX+1,PosY,color,3)


	-- local count = 0
	-- for i=1,MaxRange do
	-- 	local x = self.Influence[i]
	-- 	if x > 0 then
	-- 		print("Pos "..i.." Influence "..x)
	-- 		count = count + 1
	-- 	end
	-- end
	--print("Influence num "..count)

end

function Goboard:ChessInfluence( )
	local x=0
	local y = 0

	for i=1,MaxRange do
		local chessinf = self.Influence[i]
		if chessinf > 0 then
			x = x + chessinf
		else
			y = y + chessinf
		end

	end
	return x,y
end

return Goboard


