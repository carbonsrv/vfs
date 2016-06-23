-- Carbon sharing backend

if not carbon then
	error("VFS: carbon backends can only be loaded when running in Carbon: https://github.com/carbonsrv/carbon", 0)
end

local function e(msg)
	error("VFS: "..msg, 0)
end

-- Some very cool special goodie: A thread-safe proxy backend.
-- Allows a single instance of a backend to be used by serveral threads, sharing it's cwd and whatnot.
return {
	shared = function(drivename, sharedbackend, ...)
		local msgpack = require("msgpack")
		local kvstore_key_base = "carbon:vfs:"..drivename..":"
		if not sharedbackend then
			if not kvstore._get(kvstore_key_base.."com") then
				e("Shared backend has not been initialized for drive "..drivename)
			end
				local function call(name, ...)
				local shrd = kvstore._get(kvstore_key_base.."com")
				com.send(shrd, msgpack.pack({
					method = name,
					args = table.pack(...)
				}))

				local res = msgpack.unpack(com.receive(shrd))
				if res[1] == false then
					error(res[2], 0)
				elseif res[1] == true then
					return unpack(res, 2, res.n)
				end
			end
			local tmp = {
				unmount = function(...)
					call("unmount")
					kvstore._del(kvstore_key_base.."com")
					kvstore._del(kvstore_key_base.."args")
				end
			}
			for k, v in pairs(luar.slice2table(kvstore._get(kvstore_key_base.."methods"))) do
				if not k == "unmount" then
					tmp[v] = function(...)
						return call(v, ...)
					end
				end
			end
			return tmp
		else -- init backend and put the com in the kvstore
			local vfs_backend = vfs.backends[sharedbackend]
			kvstore._set(kvstore_key_base.."args", msgpack.pack(table.pack(...)))
			local shrd = thread.spawn(function()
				local msgpack = require("msgpack")
				local bargs = msgpack.unpack(kvstore._get(kvstore_key_base.."args"))
				--require("vfs") -- already loaded by default
				local drive = vfs_backend(drivename, unpack(bargs, 1, bargs.n))

				local methodlist = {}
				for k, _ in pairs(drive) do
					table.insert(methodlist, k)
				end
				kvstore._set(kvstore_key_base.."methods", methodlist)
				com.send(threadcom, true) -- indicate that we are done initializing

				while true do
					local src = com.receive(threadcom)
					local cmd = msgpack.unpack(src)
						local name, args = cmd.method, cmd.args
					local res = table.pack(pcall(drive[name], unpack(args, 1, args.n)))
					com.send(threadcom, msgpack.pack(res))
					if name == "unmount" then -- I guess it is time to go.
						return
					end
				end
			end)
			com.receive(shrd) -- block until thread is done with init
			kvstore._set(kvstore_key_base.."com", shrd)
			return vfs.backends.shared(drivename)
		end
	end,
}
