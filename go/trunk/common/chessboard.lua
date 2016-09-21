local filelog = require "filelog"

local InfluenceRange = 3
local InfluenceBase = 2      --影响力基数

local CHESSCOLOR ={Black = 1,White = 2,}

local ChessBoard = require "godefine"

local debug = 1
local print = print
if debug == 0 then
	print = function(...)end
end


local Goboard = 
{
	GoboardTable = {},   --棋子
	Influence = {},	--影响力
	WinNum={}, --
	HandChess = {},
}
 

local CaptureList = {}
local ChessLink = {}
--local chess = {color=CHESSCOLOR.Black,gas=4,pos={}}
local BlackPlayer = 1
local WhitePlayer = 1

local function GetPosValid( PosX,PosY )
	if (PosX > 0 and PosX <= ChessBoard.MaxWidth) and (PosY > 0 and PosY <= ChessBoard.MaxHeight) then 
		return 1
	end
	return 0
end

local function rprint(...)
end

local function RecoveryPos( Pos )
	if Pos > 0 and Pos <= ChessBoard.MaxWidth*ChessBoard.MaxHeight then
		if Pos > ChessBoard.MaxWidth then
			local PosX = Pos % ChessBoard.MaxWidth
			local PosY = ((Pos - PosX)/ChessBoard.MaxHeight) + 1
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
	return (PosY - 1) *ChessBoard.MaxWidth + PosX
end 

function Goboard:InitGoBoard(BlackPlayer1, WhitePlayer2)
	if self.Influence == nil then
		self.Influence = {}
	else
		for k,v in pairs(self.Influence) do
			self.Influence[k]=nil
		end
		self.Influence = {}
	end
	for i=1,ChessBoard.MaxWidth*ChessBoard.MaxHeight do
		self.Influence[i] = 0
	end

	if self.GoboardTable ~= nil then
		for k,v in pairs(self.GoboardTable) do
			self.GoboardTable[k]=nil
		end
		self.GoboardTable = {}
	else
		self.GoboardTable = {}
	end
	
	self.WinNum=nil
	self.WinNum = {}
	self.WinNum[BlackPlayer1] = 0
	self.WinNum[WhitePlayer2] = 0

	self.HandChess = nil
	self.HandChess ={}
	self.HandChess[BlackPlayer1] = ChessBoard.HandChessNum
	self.HandChess[WhitePlayer2] = ChessBoard.HandChessNum
	BlackPlayer = BlackPlayer1
	WhitePlayer = WhitePlayer2
end

function Goboard:Release(  )
	if self.Influence ~= nil then 
		for k,v in pairs(self.Influence) do
			self.Influence[k]=nil
		end
	end

	if self.GoboardTable ~= nil then
		for k,v in pairs(self.GoboardTable) do
			self.GoboardTable[k]=nil
		end
	end
	self.WinNum=nil
end

function Goboard:new(o )
	 o = o or {}
	 setmetatable(o, self)
	 self.__index = self 
	--  self.Influence = {}
	-- for i=1,ChessBoard.MaxWidth*ChessBoard.MaxHeight do
	-- 	self.Influence[i] = 0
	-- end
	 return o
end

function Goboard:GetboardTable( )
	local chesstable = {}
	assert(self.GoboardTable ~= nil,"GoboardTable nil")
	local colorchess = 0
	for i=1,ChessBoard.MaxRange do
		if self.GoboardTable ~= nil then
			if self.GoboardTable[i] ~= nil and self.GoboardTable[i].color ~= nil then
				chesstable[i] = self.GoboardTable[i].color
				colorchess = colorchess + 1
			else
				chesstable[i] = 0
			end
		end 
	end
	--print("GetboardTable colorchess "..colorchess)
	--filelog.sys_info(chesstable)
	return chesstable
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
		if PosY == 1 or PosY == ChessBoard.MaxHeight then
			Gasnum = Gasnum - 1
		end

		if PosX == 1 or PosX == ChessBoard.MaxWidth then
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

		if PosX < ChessBoard.MaxWidth then
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

		if PosY < ChessBoard.MaxHeight then
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
		-- for k,v in pairs(ChessLink[linkindex].linkid) do
		-- 	if v == Pos then
		-- 		return 1
		-- 	end
		-- end
		table.insert(ChessLink[linkindex].linkid,Pos)
		ChessLink[linkindex].linknum = ChessLink[linkindex].linknum + 1
		return 1
	end
	return 0
end

function Goboard:PopfromLink( linkindex,Pos  )
	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		if ChessLink[linkindex].linknum > 0 then
			return
		end
	end
end

function Goboard:UpdateLink( linkindex,Pos,color )
	if Pos > 1 then
		if Pos % ChessBoard.MaxWidth > 1 then
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

	if Pos < ChessBoard.MaxWidth then
		if Pos % ChessBoard.MaxWidth > 1 then
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

	if Pos > ChessBoard.MaxWidth then
		local bpos = Pos - ChessBoard.MaxWidth
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

	if Pos + ChessBoard.MaxWidth <= ChessBoard.MaxWidth * ChessBoard.MaxHeight then
		local tpos = Pos + ChessBoard.MaxWidth
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
	self:CapturesChess()
	self:ComputeInf(Pos,chess.color)
end

function Goboard:CanMove( Player,PosX,PosY ) --能否落子
	if GetPosValid(PosX,PosY) == 0 then 
		print("InValid Pos "..PosX.."  "..PosY)
		return 0
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

	if self.HandChess[Player] == nil then
		return 0
	end

	if self.HandChess[Player] - 1 <= 0 then
		return 0
	end


	return 1
end

function Goboard:IsCanMove( Player,PosX,PosY ) --能否落子
	if GetPosValid(PosX,PosY) == 0 then 
		print("InValid Pos "..PosX.."  "..PosY)
		return 0
	end
	
	local other = self:GetChess(PosX,PosY)
	if other ~= nil then
		print("other chess had "..other.color)
		return 0
	end

	if self.HandChess[Player] == nil then
		return 0
	end

	if self.HandChess[Player] - 1 <= 0 then
		return 0
	end

	local Gasnum = self:GetGas(Player,PosX,PosY)
	assert(Gasnum>=0,"GetGas Error")
	if Gasnum > 0 then
		return 1
	end

	local bismove = 0

	self:PlayerMove(Player,PosX,PosY)
	local chess = self:GetChess(PosX,PosY)
	assert(chess~=nil,"IsCanMove chess==nil")
	if chess.link > 0 then
		if self:GetChessLinkGas(chess.link) > 0 then
			bismove = 1
		end
	else
		if self:GetGas(Player,PosX,PosY) > 0 then
			bismove = 1
		end
	end

	local Pos = CoverPos(PosX,PosY)
	self:EatChess(Pos)
	self.HandChess[Player] = self.HandChess[Player] +1
	return bismove

end

function Goboard:PlayerMove(Player,PosX,PosY) 
	local chess = {}

	if Player == BlackPlayer then
		chess.color = CHESSCOLOR.Black
	else
		chess.color = CHESSCOLOR.White
	end

	if self.CaptureList ~= nil then
		for k,v in pairs(self.CaptureList) do
			self.CaptureList[k]=nil
		end
	end
	self.CaptureList={}
	
	local Gasnum = self:GetGas(Player,PosX,PosY)

	assert(Gasnum>=0,"GetGas Error")
	-- if Gasnum == 0 then
	-- 	print("Gasnum == 0 ")
	-- 	return 0
	-- end

	self.HandChess[Player] = self.HandChess[Player] -1

	chess.gas = Gasnum
	chess.link = 0

	print("PlayerMove  "..PosX.."    "..PosY)
	
	if PosX > 1 then
		local other = self:GetChess(PosX-1,PosY)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				-- if self:AddToLink(chess.link,Pos1) > 1 then
				-- 	self:UpdateLink(chess.link,Pos1,chess.color)
				-- end
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

	if PosX < ChessBoard.MaxWidth then
		local other = self:GetChess(PosX+1,PosY)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				-- if self:AddToLink(chess.link,Pos1) > 1 then
				-- 	self:UpdateLink(chess.link,Pos1,chess.color)
				-- end
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
				-- if self:AddToLink(chess.link,Pos1) > 1 then
				-- 	self:UpdateLink(chess.link,Pos1,chess.color)
				-- end
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

	if PosY < ChessBoard.MaxHeight then
		local other = self:GetChess(PosX,PosY+1)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				local Pos1 = CoverPos(PosX,PosY)
				-- if self:AddToLink(chess.link,Pos1) > 1 then
				-- 	self:UpdateLink(chess.link,Pos1,chess.color)
				-- end
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
	table.insert(self.CaptureList,Pos)

end

function Goboard:EatPosChess(PosX,PosY )
	local Pos = CoverPos(PosX,PosY)
	self:EatChess(Pos)
end

function Goboard:GetCaptureList( )
	return self.CaptureList
end

function Goboard:CheckWinLose(  )
	if 	self.HandChess[BlackPlayer] == 0 then
		return BlackPlayer
	elseif self.HandChess[WhitePlayer] == 0 then
		return WhitePlayer
	end
	return 0
end

function Goboard:GetChessLinkGas( linkindex )
	local linkgas = 0
	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		if ChessLink[linkindex].linknum > 0 then
			for j,k in pairs( ChessLink[linkindex].linkid) do
				linkgas = linkgas + self:GetPosGas(k)
			end
		end
	end
	return linkgas
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

function Goboard:CapturesOne( PosX,PosY,color )
	local chess = self:GetChess(PosX,PosY+1)
	if chess ~= nil and chess.color ~= color and chess.link == 0 then
		local gas = self:GetGas(1,PosX,PosY+1)
		if gas == 0 then
			self:EatPosChess(PosX,PosY+1)
			return
		end
	end

	chess = self:GetChess(PosX,PosY-1)
	if chess ~= nil and chess.color ~= color and chess.link == 0 then
		local gas = self:GetGas(1,PosX,PosY-1)
		if gas == 0 then
			self:EatPosChess(PosX,PosY-1)
			return
		end
	end

	chess = self:GetChess(PosX+1,PosY)
	if chess ~= nil and chess.color ~= color and chess.link == 0 then
		local gas = self:GetGas(1,PosX+1,PosY)
		if gas == 0 then
			self:EatPosChess(PosX+1,PosY)
			return
		end
	end

	chess = self:GetChess(PosX-1,PosY)
	if chess ~= nil and chess.color ~= color and chess.link == 0 then
		local gas = self:GetGas(1,PosX-1,PosY)
		if gas == 0 then
			self:EatPosChess(PosX-1,PosY)
			return
		end
	end
end

function Goboard:RequestDM(  ) --玩家点目,返回输家
	local x ,y = self:ChessInfluence()
	if x - 4 + y > 0 then
		return WhitePlayer
	end
	return BlackPlayer
end

function Goboard:RequestDMNum( ... ) --点目的具体数量
	local x ,y = self:ChessInfluence()
	return x - 4 + y 
end

function Goboard:Print( ... )
	local file = io.open("D:\\work\\framework\\go\\chess.txt","w+")
	if file ~= nil then
		local x ,y = self:ChessInfluence()
		file:write("RequestDM : "..self:RequestDM().." \n")
		file:write("RequestDMNum : "..self:RequestDMNum().." \n")
		file:write("black : "..x.." \n")
		file:write("white : "..y.." \n")

		local Chesstable = self:GetboardTable()
		print("MaxRange "..ChessBoard.MaxRange)
		local i = ChessBoard.MaxRange
		local start = 1
		while i > 0 do
			start = i - ChessBoard.MaxHeight
			for j=start+1,start+ChessBoard.MaxHeight do
				--print(j)
				if Chesstable[j] == 0 then
					file:write("x ")
				else
					file:write(Chesstable[j].." ")
				end
			end
			file:write("\n")
			i = i - ChessBoard.MaxHeight
		end
		-- for i,v in ipairs(Chesstable) do
		-- 	if v == 0 then
		-- 		file:write("x ")
		-- 	else
		-- 		file:write(v.." ")
		-- 	end

		-- 	if i % ChessBoard.MaxHeight == 0 and i > 0 then
		-- 		file:write("\n")
		-- 	end
		-- end
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
		--print("return  ".." Pos "..InfluencePos.." Influence "..chessInfluence)
	end
	--
	return chessInfluence
end

function Goboard:ComputeInf( Pos,color)
	local PosX,PosY = RecoveryPos(Pos)
	if PosX == nil then
		return
	end
	self:CapturesOne(PosX,PosY,color)

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
	-- for i=1,ChessBoard.ChessBoard do
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

	for i=1,ChessBoard.MaxRange do
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


