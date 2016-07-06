local function loadvfs()
	package.loaders[1] = function(modname)
		local fh, err = io.open("./"..modname:gsub("%.", "/")..".lua", "r")
		if err then
			return "\n\tnot found using temp loader"
		end
		local src = fh:read("*all")
		fh:close()
		return load(src)
	end
	vfs = dofile("init.lua")
	return vfs
end

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

	local fdir = drive..":/path/to"
	local fp = fdir.."/test.txt"

	tst("mkdir", function()
		assert(vfs.mkdir(fdir))
	end)

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

	tst("list", function()
		local list = assert(vfs.list(fdir))
		eq(list[1], "test.txt")
	end)

	tst("delete", function()
		assert(vfs.delete(fp))
	end)

	tst("exists", function()
		exists, err = vfs.exists(fp)
		neq(exists, true)
	end)
end

-- Actual tests
describe("carbonvfs", function()
	describe("should run under carbon and it", function()
		if carbon then
			loadvfs()
			it("should load carbon specific backends", function()
				assert.equals(type(vfs.backends.physfs), "function")
				assert.equals(type(vfs.backends.sql), "function")
				assert.equals(type(vfs.backends.shared), "function")
			end)
			describe("should be able to use the sql backend", function()
				describe("normally", function()
					local db = assert(sql.open("ql-mem", "sqltest"))
					vfs.new("sqltest", "sql", db, {
						tablename = "files",
					})

					basicvfstest("sqltest")

				end)

				describe("using the shared backend", function()
					local db = assert(sql.open("ql-mem", "sqltestshared"))
					vfs.new("sqlsharedtest", "shared", "sql", db, {
						tablename = "files",
					})

					basicvfstest("sqlsharedtest")

					local waiter = thread.run(function()
						loadvfs()
						vfs.new("sqlsharedtest", "shared")

						basicvfstest("sqlsharedtest")
					end)

					waiter()
				end)
			end)
		else
			it("should work flawlessly", function()
				pending("But the tests aren't running under carbon...")
			end)
		end
	end)
end)
