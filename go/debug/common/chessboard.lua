local filelog = nil
if os.getenv("OS") == nil then
	filelog = require "filelog"
end

local InfluenceRange = 3
local InfluenceBase = 2      --影响力基数
local CurrentHands = 0 		--当前手数
local CurrentEats = {}		--当前的提子操作
local CHESSCOLOR ={Black = 1,White = 2,}

local ChessBoard = require "godefine"
local ChessLinktable = require "chesslink"

local debug = 0
local print = print
if debug == 0 then
	print = PrintWnd
	--print = function(...)end
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
local Linkmergedata = {}
--local chess = {color=CHESSCOLOR.Black,gas=4,pos={}}
local BlackPlayer = 1
local WhitePlayer = 1
local NullObject = {}

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
		local PosY = Pos / ChessBoard.MaxWidth
		local PosX = 0
		if Pos % ChessBoard.MaxWidth == 0 then
			PosX = ChessBoard.MaxWidth
		else
			PosX = Pos % ChessBoard.MaxWidth
			PosY = PosY + 1
		end
		return PosX,PosY
	end 
	return nil
end 

local function IsValidPos( Pos )
	if Pos > 0 and Pos <= ChessBoard.MaxRange then
		return 1
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


	if self.CaptureList ~= nil then
		for k,v in pairs(self.CaptureList) do
			self.CaptureList[k]=nil
		end
	end
	self.CaptureList={}

	if ChessLink ~= nil then
		for k,v in pairs(ChessLink) do
			ChessLink[k]=nil
		end
	end
	ChessLink = {}

	CurrentEats.hands = 0
	CurrentEats.color = 0
	CurrentEats.pos = 0
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
	local Pos = CoverPos(PosX,PosY)
	return self:GetPosChess(Pos)
end

function Goboard:GetPosChess( Pos ) --坐标上棋子
	if Pos > 0 and Pos <= ChessBoard.MaxRange then
		if self.GoboardTable ~= nil then
			if self.GoboardTable[Pos] ~= nil and self.GoboardTable[Pos].color ~= nil then
				return self.GoboardTable[Pos]
			end
		end
	end
	return nil
end



function Goboard:GetGas(Player,PosX,PosY)  --获取坐标的气
	local Pos = CoverPos(PosX,PosY)
	return self:GetPosGas(Pos)
	--local chess =  self:GetChess(PosX,PosY)
	--print(self.GoboardTable==nil)
end


function Goboard:GetPosGas(Pos)  --获取坐标的气
	--local chess = self:GetPosChess(Pos)
	assert(IsValidPos(Pos)>0,"IsValidPos  "..Pos)
	
	local Gasnum = 4
	if Pos % ChessBoard.MaxHeight == 0   then
		Gasnum = Gasnum - 1
	else
		local other = self:GetPosChess(Pos+1)
		if other ~= nil then
			Gasnum = Gasnum - 1
		else
			self:AddnullPos(Pos+1)
		end
	end

	if Pos % ChessBoard.MaxHeight == 1  then
		Gasnum = Gasnum - 1
	else
		local other = self:GetPosChess(Pos-1)
		if other ~= nil then
			Gasnum = Gasnum - 1
		else
			self:AddnullPos(Pos-1)
		end
	end

	if Pos <= ChessBoard.MaxHeight  then
		Gasnum = Gasnum - 1
	else
		local other = self:GetPosChess(Pos-ChessBoard.MaxHeight)
		if other ~= nil then
			Gasnum = Gasnum - 1
		else
			self:AddnullPos(Pos-ChessBoard.MaxHeight)
		end
	end

	if Pos >= (ChessBoard.MaxHeight - 1) * ChessBoard.MaxHeight then
		Gasnum = Gasnum - 1
	else
		local other = self:GetPosChess(Pos+ChessBoard.MaxHeight)
		if other ~= nil then
			Gasnum = Gasnum - 1
		else
			self:AddnullPos(Pos+ChessBoard.MaxHeight)
		end
	end

	return Gasnum
end

--合并已经存在的2个链，创建新的链，设置当前的链无效,纪录链接合并的坐标
function Goboard:MergeLink( link1,link2,Pos )
	if ChessLink[link1] ~= nil and ChessLink[link2] ~= nil then
		local newlinkindex = self:GeneraLinkIndex()
		ChessLink[newlinkindex] = {}
		ChessLink[newlinkindex] = ChessLink[link1].mergelink(newlinkindex,ChessLink[link1],ChessLink[link2])
		ChessLink[newlinkindex].updatechess(ChessLink[newlinkindex],self)

		if Linkmergedata[Pos] == nil then
			Linkmergedata[Pos] = {}
		end
		table.insert(Linkmergedata[Pos],link1)
		table.insert(Linkmergedata[Pos],link2)
		return newlinkindex
	end
	return 0
end

function Goboard:GetChessLink( linkindex)
	if ChessLink[linkindex] ~= nil  then
		return ChessLink[linkindex]
	end
	return nil
end

function Goboard:GeneraLinkIndex(  )
	local linkindex = #ChessLink
	if linkindex > 0 then
		for i,v in ipairs(ChessLink) do
			if v.linknum == 0 then  --合并后的空链接
				return i
			end
		end
	end
	linkindex = linkindex + 1
	return linkindex
end

--使用2个坐标创建1个链
function Goboard:CreateLink( Pos1,Pos2 )
	
	local linkindex = self:GeneraLinkIndex()
	ChessLink[linkindex] = {}

	local linktable = ChessLinktable.new(linktable,linkindex)
	linktable.addtolink(linktable,Pos1)
	linktable.addtolink(linktable,Pos2)
	linktable.updatechess(linktable,self)
	ChessLink[linkindex] = linktable
	return linkindex
end


--把坐标加入到已经存在的链中
function Goboard:AddToLink( linkindex,Pos )
	if ChessLink[linkindex] ~= nil then
		ChessLink[linkindex].addtolink(ChessLink[linkindex],Pos)
		ChessLink[linkindex].updatechess(ChessLink[linkindex],self)
		return 1
	end
	return 0
end

function Goboard:PopfromLink( linkindex,Pos  )
	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		ChessLink[linkindex].poplink(ChessLink[linkindex],Pos)

		if Linkmergedata[Pos] == nil then
			print("no mergedata ")
			return
		end
		for k,v in pairs(Linkmergedata[Pos]) do
			if ChessLink[v].isvalid == false then
				ChessLink[v].isvalid = true
				ChessLink[v].poplink(ChessLink[v],Pos)
				ChessLink[v].updatechess(ChessLink[v],self)
				print("breakLink "..v.."   num "..ChessLink[v].linknum)
			end
		end
		ChessLink[linkindex].clear(ChessLink[linkindex])
		Linkmergedata[Pos] = nil
		Linkmergedata[Pos] = {}
	end
end

--得到指定的链中的棋子数量
function Goboard:GetLinkChessNum( linkindex )
	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		return  ChessLink[linkindex].linknum
	end
	return 0
end

function Goboard:SortLink( linkindex )
	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		
	end
end


--更新链。主动探测坐标的四向位置是否有需要加入到链中的棋子
function Goboard:UpdateLink( linkindex,Pos,color )
	--print("UpdateLink")
	local UpLink = linkindex
	if Pos % ChessBoard.MaxWidth > 1 or Pos % ChessBoard.MaxWidth <= 0 then
		local other = self:GetPosChess(Pos-1)
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				UpLink = self:MergeLink(linkindex,other.link,Pos)
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,Pos-1)
				self:UpdateLink(linkindex,Pos-1)
				--print("1 AddToLink")
			end
		end	
	end

	

	if Pos % ChessBoard.MaxWidth > 0 then
		local other = self:GetPosChess(Pos+1)
		--print("2 otherlink "..other.link.." color "..other.color.."  upcolor "..color )
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				UpLink = self:MergeLink(linkindex,other.link,Pos)
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,Pos+1)
				self:UpdateLink(linkindex,Pos+1)
				--print("AddToLink Pos+1 "..Pos+1)
			end
		end		
	end
	

	if Pos > ChessBoard.MaxWidth then
		local bpos = Pos - ChessBoard.MaxWidth
		local other = self:GetPosChess(bpos)
		--print("3 otherlink "..other.link.." color "..other.color.."  upcolor "..color )
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				UpLink = self:MergeLink(linkindex,other.link,Pos)
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,bpos)
				self:UpdateLink(linkindex,bpos)
				--print("AddToLink bpos "..bpos)
			end
		end		
	end

	if Pos + ChessBoard.MaxWidth <= ChessBoard.MaxWidth * ChessBoard.MaxHeight then
		
		local tpos = Pos + ChessBoard.MaxWidth
		local other = self:GetPosChess(tpos)
		--print("4  otherlink "..other.link.." color "..other.color.."  upcolor "..color )
		if other ~= nil and other.color == color then
			if other.link > 0 and other.link ~= linkindex then
				UpLink = self:MergeLink(linkindex,other.link,Pos)
			elseif other.link == 0 then
				other.link = linkindex
				self:AddToLink(linkindex,tpos)
				self:UpdateLink(linkindex,tpos)
				--print("AddToLink tpos"..tpos)
			end
		end		
	end
	return UpLink
end



function Goboard:PutChess( Pos,chess )
	self.GoboardTable[Pos] = chess
	--local PosX,PosY = RecoveryPos(Pos)
	self:CapturesOne(Pos,chess.color)
	--self:CapturesChess()
	self:ComputeInf(Pos,chess.color)
end

function Goboard:CanMove( Player,PosX,PosY ) --能否落子
	if PosY == nil then
		PosX,PosY = RecoveryPos(PosX)
	end
	if GetPosValid(PosX,PosY) == 0 then 
		print("InValid Pos "..PosX.."  "..PosY)
		return 0
	end
	
	local other = self:GetChess(PosX,PosY)
	if other ~= nil then
		print("other chess had "..other.color)
		return 0
	end

	-- local Gasnum = self:GetGas(Player,PosX,PosY)
	-- assert(Gasnum>=0,"GetGas Error")
	-- if Gasnum == 0 then
	-- 	print("Gasnum == 0 ")
	-- 	return 0
	-- end

	if self.HandChess[Player] == nil then
		return 0
	end

	if self.HandChess[Player] - 1 <= 0 then
		return 0
	end

	return self:PutLink(Player,PosX,PosY)
end

function Goboard:PlayerMove( Player,PosX,PosY,linkindex )
	if PosY == nil then
		PosX,PosY = RecoveryPos(PosX)
	end
	local chess = {}
	if Player == BlackPlayer then
		chess.color = CHESSCOLOR.Black
	else
		chess.color = CHESSCOLOR.White
	end
	chess.gas = self:GetGas(Player,PosX,PosY)
	assert(chess.gas>=0,"GetGas Error")
	chess.link = linkindex
	self.HandChess[Player] = self.HandChess[Player] -1
	local Pos1 = CoverPos(PosX,PosY)
	self:PutChess(Pos1,chess)

	CurrentHands = CurrentHands + 1

	return 1
end



--能否落子时会加入到链中判断能否落子提子
function Goboard:PutLink(Player,PosX,PosY) 
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

	--self.HandChess[Player] = self.HandChess[Player] -1

	chess.gas = Gasnum
	chess.link = 0
	local LinkGas = 0
	
	
	local bputchess = 0
	local Pos1 = CoverPos(PosX,PosY)
	local otherpos = 0
	if Pos1 % ChessBoard.MaxWidth > 1 or Pos1 % ChessBoard.MaxWidth <=0 then
		otherpos = Pos1 -1
		local other = self:GetPosChess(otherpos)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
		
				self:AddToLink(chess.link,Pos1)
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)

				bputchess = 1
				--self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				--return 1
			elseif other.link == 0 then
				local linkid = self:CreateLink(Pos1,otherpos)
				chess.link = linkid
				other.link = linkid
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)
				
				bputchess = 1
				--self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				--return 1
			end
		end
	end

	if Pos1 % ChessBoard.MaxWidth > 0 and chess.link == 0 then
		otherpos = Pos1 +1
		local other = self:GetPosChess(otherpos)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				self:AddToLink(chess.link,Pos1)
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)
				--print(Pos1.."put chess")
				bputchess = 1
				--self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				--return 1
			elseif other.link == 0  then
				local linkid = self:CreateLink(Pos1,otherpos)
				chess.link = linkid
				other.link = linkid
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)
				--print(Pos1.."put chess")
				bputchess = 1
				--self:PutChess(Pos1,chess)
				--self.GoboardTable[Pos1] = chess
				--return 1
			end
		end
	end

	if Pos1 > ChessBoard.MaxHeight and chess.link == 0 then
		otherpos = Pos1 - ChessBoard.MaxHeight
		local other = self:GetPosChess(otherpos)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				self:AddToLink(chess.link,Pos1)
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas = self:GetChessLinkGas(chess.link,Pos1)
			elseif other.link == 0  then
				local linkid = self:CreateLink(Pos1,otherpos)
				chess.link = linkid
				other.link = linkid
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)
				--print(Pos1.."put chess")
				bputchess = 1
			end
		end
	end

	if Pos1 + ChessBoard.MaxHeight  <= ChessBoard.MaxRange  and chess.link == 0  then
		otherpos = Pos1 + ChessBoard.MaxHeight
		local other = self:GetPosChess(otherpos)
		if other ~= nil and other.color == chess.color then
			if other.link > 0 then
				chess.link = other.link
				self:AddToLink(chess.link,Pos1)
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas = self:GetChessLinkGas(chess.link,Pos1)
			elseif other.link == 0  then
				local linkid = self:CreateLink(Pos1,otherpos)
				chess.link = linkid
				other.link = linkid
				chess.link = self:UpdateLink(chess.link,Pos1,chess.color)
				LinkGas= self:GetChessLinkGas(chess.link,Pos1)
				--print(Pos1.."put chess")
				bputchess = 1
			end
		end
	end


	local Pos1 = CoverPos(PosX,PosY)
	if LinkGas > 0 then
	 	--self:PutChess(Pos1,chess)
		print(Pos1.." can put chess LinkGas "..LinkGas.."  linknum "..self:GetLinkChessNum(chess.link))
		return 1,chess.link
	elseif chess.gas > 0 then
		--self:PutChess(Pos1,chess)
		print(Pos1.." can put chess chess.gas "..chess.gas)
		return 1,chess.link
	elseif self:CanEat( Pos1,chess ) > 0 then
		print(Pos1.." can put chess CanEat ")
		return 1,chess.link
	end
	print(Pos1.." chess not gas ")
	self:PopfromLink(chess.link,Pos1)
	return 0
end

function Goboard:CanEat( Pos,chess )
	--local Pos = CoverPos(PosX,PosY)
	--print(" CurrentHands "..CurrentHands.." CurrentEats.hands "..CurrentEats.hands)
	if CurrentHands - CurrentEats.hands == 1 then
		if CurrentEats.pos == Pos then
			return 0
		end
	end

	self.GoboardTable[Pos] = chess
	if self:CapturesOne(Pos,chess.color) > 0 then
		return 1
	end
	self.GoboardTable[Pos] = nil
	self.GoboardTable[Pos] = {}
	return 0
end


--提子，需要记录当前的操作
function Goboard:EatChess(Pos)
	local chess = self:GetPosChess(Pos)
	assert(chess~=nil,"EatChess Pos "..Pos.." nil")
	CurrentEats.hands = CurrentHands
	CurrentEats.color = chess.color
	CurrentEats.pos = Pos
	self.WinNum[chess.color] = self.WinNum[chess.color] + 1
	self.GoboardTable[Pos] = nil
	self.GoboardTable[Pos] = {}
	table.insert(self.CaptureList,Pos)
	print("EatChess "..Pos)
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

function Goboard:AddnullPos( Pos)
	for k,v in pairs(NullObject) do
		if v == Pos then
			return
		end
	end
	table.insert(NullObject,Pos)
end

function Goboard:RemovePos( Pos ) --棋子自身所占用的气
	for k,v in pairs(NullObject) do
		if v == Pos then
			return 1
		end
	end
	return 0
end

--在落子时返回所在链的气
function Goboard:GetChessLinkGas( linkindex ,Pos)
	local linkgas = 0
	NullObject = {}

	if ChessLink ~= nil and ChessLink[linkindex] ~= nil then
		if ChessLink[linkindex].linknum > 0 then
			for j,k in pairs( ChessLink[linkindex].linkid) do
				self:GetPosGas(k)
				--print("GetChessLinkGas link"..linkindex.." Pos "..k.." Gas "..self:GetPosGas(k))
				--linkgas = linkgas + self:GetPosGas(k)
			end
		end
		if Pos ~= nil then
			if self:RemovePos(Pos) > 0 then
				return #NullObject - 1
			end
		end

	end
	return #NullObject
end

--多个提子。遍历所有的链，如果有链的气为0，将整个链提子，并将链置为空链，在创建链接时会优先使用空链
function Goboard:CapturesChess(  )
	--print("CapturesChess")

	local linknum = #ChessLink
	if linknum > 0 then
		for i,v in ipairs(ChessLink) do
			local linkgas = 0
			if v.linknum > 0 then
				linkgas = self:GetChessLinkGas(i)
				print("linkgas "..i.."   "..linkgas.."   num "..v.linknum)
				if linkgas == 0 then
					for j,k in pairs(v.linkid) do
						self:EatChess(k)
					end
					v.linkid = nil
					v.linkid = {}
					v.linknum = 0
				end
				linkgas = 0
			end

		end
	end

end

function Goboard:CapturesLink( linkindex )
	local EatNum = 0
	if ChessLink[linkindex] ~= nil and ChessLink[linkindex].isvalid == true then
		local linkgas = self:GetChessLinkGas(linkindex)
		print("CapturesLink  "..linkindex.."  linkgas "..linkgas)
		if linkgas == 0 then
			for j,k in pairs(ChessLink[linkindex].linkid) do
				self:EatChess(k)
				EatNum = EatNum + 1
			end
			ChessLink[linkindex].clear(ChessLink[linkindex])
		end
	end
	return EatNum
end


--单个提子，对落子以后坐标做出四向探测，如果有不同颜色的棋子并且没气，会做出一次提子
function Goboard:CapturesOne( Pos,color ) 
	local EatNum = 0
	local otherpos = Pos + ChessBoard.MaxHeight
	for i=1,4 do
		if i == 2 then
			otherpos = Pos - ChessBoard.MaxHeight
		elseif i == 3 then
			otherpos = Pos + 1
		elseif i == 4 then
			otherpos = Pos - 1
		end

		local chess = self:GetPosChess(otherpos)
		if chess ~= nil and chess.color ~= color   then
			print("CapturesOne "..chess.link.."     "..self:GetLinkChessNum(chess.link))
			if chess.link == 0 then
				local gas = self:GetPosGas(otherpos)
				if gas == 0 then
					self:EatChess(otherpos)
					EatNum = EatNum + 1
					--print("EatChess "..PosX.."  "..(PosY+1))
				end
			else 
				EatNum = EatNum + self:CapturesLink(chess.link)
			end
		end

	end

	
	return EatNum 
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


--写当前的棋盘信息到文件中
function Goboard:Print( ... )
	local file = io.open("./chess.txt","w+")
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

--计算棋子的形势
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
	--self:CapturesOne(PosX,PosY,color)

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


