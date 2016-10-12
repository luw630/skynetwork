local linktable = 
{
	linknum = 0,
	linkid = nil,
	isvalid = true,
	linkindex = 0,
	mergefrom = nil,
}

local func = nil

function linktable.new( o,linkindex )
	 o = o or {}
	 setmetatable(o, linktable)
	 linktable.__index = linktable 
	 o.linkindex = linkindex
	 func = o.funclib()
	 --linktable.linkid = {}
	 --linktable.mergefrom = {}
	 --linktable.__add = linktable.addlink
	 return o
end

function linktable.addtolink( lt,Pos )
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end

	if lt.linkid == nil then
		lt.linkid = {}
	end
	for k,v in pairs(lt.linkid) do
		if v == Pos then
			return 1
		end
	end
	table.insert(lt.linkid,Pos)
	lt.linknum = lt.linknum + 1
	return lt
end

function linktable.setindex( linkindex)
	func.setindex(linkindex)
end

function linktable.getindex()
	return func.getindex()
end

function linktable.funclib( )
	local self = {linknum=0,linkindex=0,}
	local setindex = function (linkindex)
		self.linkindex = linkindex
	end
	local getindex = function ()
		return self.linkindex
	end
	return {setindex = setindex,getindex = getindex}

end

function linktable.updatechess( lt,chessboard )
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end
	for k,v in pairs(lt.linkid) do
		local chess = chessboard:GetPosChess(v)
		if chess ~= nil then
			chess.link = lt.linkindex
		end
	end
	return lt
end

function linktable.clear( lt )
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end
	lt.linknum = 0
	lt.linkid = nil
	lt.linkid = {}
	return lt
end

function linktable.mergelink(ltnew,lt1,lt2 )
	if getmetatable(lt1) ~= linktable and getmetatable(lt2) ~= linktable then
		print("wrong tye")
		return 0
	end

	if getmetatable(ltnew) ~= linktable then
		print("wrong tye")
		return 0
	end

	for k,v in pairs(lt2.linkid) do
		ltnew.addtolink(ltnew,v)
	end

	for k,v in pairs(lt1.linkid) do
		ltnew.addtolink(ltnew,v)
	end

	lt1.isvalid = false
	lt2.isvalid = false
	return ltnew
end

function linktable.poplink( lt ,Pos)
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end
	for k,v in pairs(lt.linkid) do
		if v == Pos then
			table.remove(lt.linkid,k)
			lt.linknum = lt.linknum - 1
			break
		end
	end
	return lt
end

function linktable.breaklink(ltm,Pos,lt )
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end

	if lt.mergefrom[Pos] == nil then
		print("no mergefrom data")
		return 0
	end

	-- for k,v in pairs(lt.mergefrom[Pos]) do
	-- 	local ltm = chessboard:GetChessLink(v)
	-- 	if ltm ~= nil and getmetatable(ltm) == linktable then
	-- 		if ltm.isvalid == false then
	-- 			for p,q in pairs(ltm.linkid) do
	-- 				lt.poplink(q,lt)
	-- 			end
	-- 			ltm.isvalid = true
	-- 		end
	-- 	end
	-- end


	if ltm ~= nil and getmetatable(ltm) == linktable then
		if ltm.isvalid == false then
			for p,q in pairs(ltm.linkid) do
				lt.poplink(q,lt)
			end
			ltm.isvalid = true
		end
	end
	
	lt.mergefrom[Pos] = nil
	lt.mergefrom[Pos] = {}
	return lt

end

function linktable.debugprint( lt )
	--local lttable = getmetatable(lt)
	print("linktable.debugprint")
end

function linktable.print(lt )
	if getmetatable(lt) ~= linktable then
		print("wrong tye")
		return 0
	end

	if lt.linkid ~= nil then
		for k,v in pairs(lt.linkid) do
			print(v)
		end
	end


	print("linknum  "..lt.linknum)
	print(lt.isvalid)
	print("linkindex "..lt.linkindex)

	print("mergefrom info ")
	if lt.mergefrom ~= nil then
		for q,p in pairs(lt.mergefrom) do
			for k,v in pairs(p) do
				print(k,v)
			end
		end
	end
end


return linktable