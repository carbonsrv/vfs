-- Custom type check, doesn't work. :V
--[[
local say = require("say")
-- Type checker
local function is_type(obj, t)
	return type(obj) == t
end
say:set("assertion.type.positive", "Expected %s to be type %s")
say:set("assertion.type.negative", "Expected %s to not be type %s")
assert:register("assertion", "type", is_type, "assertion.is_type.postitive", "assertion.is_type.negative")
--]]

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

local function basicvfstest(drive)
	local eq = function(a, b)
		if type(assert) == "function" then
			assert(a == b)
		else
			assert.equals(a, b)
		end
	end

	local teststr = "Hello World!"

	assert(vfs.write(drive..":/test.txt", teststr))
	local str = assert(vfs.read(drive..":/test.txt"))
	eq(str, teststr)

	local size = assert(vfs.size(drive..":/test.txt"))
	eq(size, #teststr)

	local list = assert(vfs.list(drive..":/"))
	eq(list[1], "test.txt")
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
				it("normally", function()
					local db = assert(sql.open("ql-mem", "sqltest"))
					vfs.new("sqltest", "sql", db, {
						tablename = "files",
					})

					basicvfstest("sqltest")

					db:close()
				end)
				it("using the shared backend", function()
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
					db:close()
				end)
			end)
		else
			it("should work flawlessly", function()
				pending("But the tests aren't running under carbon...")
			end)
		end
	end)
end)
