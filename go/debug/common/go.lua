local Goboard = require "chessboard"
local t = Goboard:new(t)
t:InitGoBoard(1,2)


function testput( player,pos)
	local iscan,index =t:CanMove(player,pos)
	t:PlayerMove(player,pos,nil,index)
	t:Print()
end

function test( ... )
	--t:PlayerMove(1,2,1)
	--t:CapturesChess()
	--t:Print()
	testput(1,175)
	testput(2,176)
	testput(1,177)
	testput(2,178)
	testput(1,195)
	testput(2,196)
	testput(1,157)
	testput(2,158)
	testput(1,181)
	testput(2,176)
	testput(1,187)
	while true do
	    local params = io.read()
	    if params ~= nil  then
	    	local tableparams = {}
	    	for Player in string.gmatch(params, "%d+") do
       			table.insert(tableparams,Player)
     		end

	       	if params ==  "quit" or params == "exit" then
	       		break
	       	end

	       	if params ==  "print" then
	       		t:Print()
	       	else
	       		local iscan,index = t:CanMove(tonumber(tableparams[1]),tonumber(tableparams[2]))
	       		if iscan > 0 then
	       			t:PlayerMove(tonumber(tableparams[1]),tonumber(tableparams[2]),nil,index)
	       			t:Print()
	       		end
	
	       	end
	       --	print(tonumber(tableparams[1]),tonumber(tableparams[2]),tonumber(tableparams[3]))

	    end
	end
end
test()

