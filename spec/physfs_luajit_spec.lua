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
	local teststr = "Testfile.\n"

	local fdir = drive..":/spec/"
	local fp = fdir.."testfile"

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
	
	tst("list", function()
		local found = false
		local list = assert(vfs.list(fp))
		for k, v in pairs(list) do
			print(k, v)
			if v == "testfile" then
				found = true
			end
		end
		eq(found, true)
	end)
end

-- actual tests
if jit then
	describe("carbonvfs", function()
		vfs = dofile("init.lua")
		vfs.loadbackends("physfs-ffi")
		describe("should be able to use the ffi physfs backend on luajit", function()
			vfs.new("physfstest", "physfs", ".")
			for k,v in pairs(vfs.drives)do print(k,v)end
			basicvfstest("physfstest")
		end) 
	end)
end
