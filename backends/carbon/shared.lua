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
		local kvstore_key_base = "carbon:vfs:driver:shared:"..drivename..":"
		if not sharedbackend then
			local initstatus = kvstore._get(kvstore_key_base.."initialized")
			if initstatus ~= true then
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
				elseif res[1] == true and res[2] then
					return unpack(res, 2, res.n)
				end
			end

			local tmp = {
				unmount = function(...)
					if sharedbackend == false then
						call("unmount")
						kvstore._del(kvstore_key_base.."com")
						kvstore._del(kvstore_key_base.."args")
						kvstore._del(kvstore_key_base.."methods")
						kvstore._del(kvstore_key_base.."initialized")
					end
				end
			}
			for _, k in pairs(luar.slice2table(kvstore._get(kvstore_key_base.."methods"))) do
				if k ~= "unmount" then
					tmp[k] = function(...)
						return call(k, ...)
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
				local suc, drive = pcall(vfs_backend, drivename, unpack(bargs, 1, bargs.n))
				if not suc then
					com.send(threadcom, tostring(drive))
					return
				end

				local methodlist = {}
				for k, _ in pairs(drive) do
					table.insert(methodlist, k)
				end
				kvstore._set(kvstore_key_base.."methods", methodlist)
				com.send(threadcom, "") -- indicate that we are done initializing

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
			local err = com.receive(shrd) -- block until thread is done with init
			if err and err ~= "" then
				error(err, 0)
			end
			kvstore._set(kvstore_key_base.."com", shrd)
			kvstore._set(kvstore_key_base.."initialized", true)
			return vfs.backends.shared(drivename, false)
		end
	end,
}
