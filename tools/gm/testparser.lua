package.cpath = "../../skynet/luaclib/?.so"
package.path = "../../skynet/lualib/?.lua;../../core/?.lua;../../ddz/trunk/common/?.lua;../../core/3rd/lua-pbc/?.lua"

local protobuf = require "protobuf"
local parser = require "parser"

t = parser.register("addressbook.proto","../../msgproto")

local addressbook = {
	name = "Alice",
	id = 12345,
	phone = {
		{ number = "1301234567" },
		{ number = "87654321", type = "WORK" },
	}
}

local code = protobuf.encode("tutorial.Person", addressbook)
local decode = protobuf.decode("tutorial.Person" , code)

print(decode.name)
print(decode.id)
for _,v in ipairs(decode.phone) do
	print("\t"..v.number, v.type)
end

local buffer = protobuf.pack("tutorial.Person name id", "Alice", 123)
print(protobuf.unpack("tutorial.Person name id", buffer))