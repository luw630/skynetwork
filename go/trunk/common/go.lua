local Goboard = require "chessboard"

function test( ... )

	local t = Goboard:new(t)
	t:InitGoBoard(1,2)
	t:PlayerMove(1,2,1)
	--t:CapturesChess()
	t:Print()
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
	       		if t:CanMove(tonumber(tableparams[1]),tonumber(tableparams[2]),tonumber(tableparams[3])) > 0 then
		       		t:PlayerMove(tonumber(tableparams[1]),tonumber(tableparams[2]),tonumber(tableparams[3]))
		       --	t:CapturesChess()
		       		t:Print()
		       	end
	       	end
	       --	print(tonumber(tableparams[1]),tonumber(tableparams[2]),tonumber(tableparams[3]))

	    end
	end
end
test()

