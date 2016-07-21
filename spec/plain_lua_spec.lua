-- comparison helpers
local eq = function(a, b)
	if type(assert) == "function" then
		assert(a == b, "Expected "..tostring(a).." to be equal to "..tostring(b))
	else
		assert.equals(a, b)
	end
end
local neq = function( a, b)
	if type(assert) == "function" then
		assert(a ~= b, "Expected "..tostring(a).." to not be equal to "..tostring(b))
	else
		assert.are_not.equals(a, b)
	end
end

-- another helper
local function tst(desc, fn)
	if it ~= nil then
		return it("- "..desc, fn)
	end
	return fn()
end

local function basicvfstest(drive)
	local teststr = "Hello World!"

	local fdir = drive..":/"
	local fp = fdir.."test.txt"

	tst("write", function()
		assert(vfs.write(fp, teststr))
	end)

	tst("read", function()
		local str = assert(vfs.read(fp))
		eq(str, teststr)
	end)

	tst("exists", function()
		local exists = assert(vfs.exists(fp))
		eq(exists, true)
	end)

	tst("size", function()
		local size = assert(vfs.size(fp))
		eq(size, #teststr)
	end)

	tst("delete", function()
		local suc, err = vfs.delete(fp)
		neq(suc, false)
		neq(type(err), "string")
	end)

	tst("exists", function()
		exists, err = vfs.exists(fp)
		neq(exists, true)
	end)
end

-- actual tests
describe("carbonvfs", function()
	vfs = dofile("init.lua")
	describe("should be able to use the native backend", function()
		vfs.new("nativetest", "native", "/tmp")
		basicvfstest("nativetest")
	end) 
end)
