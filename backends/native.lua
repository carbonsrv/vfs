-- VFS Backend using the native Lua functions.
local abspath = vfs.abspath
return {
	native = function(drivename, path) -- native backend
		local cwd = "/"
		local base = (path or (os.pwd and os.pwd()) or "") .. "/"

		local function getpath(rel)
			return base .. abspath(rel or ".", cwd)
		end


		local drv = { -- create all always existing funcs here
			read = function(loc)
				local fh, err = io.open(getpath(loc), "r")
				if err then
					return nil, err
				end
				local txt = fh:read("*all")
				fh:close()
				return txt
			end,
			reader = function(loc)
				return ltn12.source.file(io.open(getpath(loc)))
			end,
			write = function(loc, txt)
				local fh, err = io.open(getpath(loc), "w")
				if err then
					return nil, err
				end
				fh:write(txt)
				fh:close()
				return true
			end,
			writer = function(loc)
				return ltn12.sink.file(io.open(getpath(loc)))
			end,
			copy = function(src, dst)
				return ltn12.pump.all(
					ltn12.source.file(io.open(getpath(src))),
					ltn12.sink.file(io.open(getpath(dst)))
				)
			end,

			delete = function(loc)
				return os.remove(getpath(loc))
			end,
			rename = function(loc1, loc2)
				return os.rename(getpath(loc1), getpath(loc2))
			end,
		}

		-- Mostly carbon specific additions.
		-- TODO: Maybe add LFS support?
		if os.exists then
			drv.exists = function(loc)
				return os.exists(getpath(loc))
			end
		end
		if io.list then
			drv.list = function(loc)
				return io.list(getpath(loc))
			end
		end
		if io.modtime then
			drv.modtime = function(loc)
				return io.modtime(getpath(loc))
			end
		end
		if io.isDir then
			drv.isdir = function(loc)
				return io.isDir(getpath(loc))
			end
		end
		if io.size then
			drv.size = function(loc)
				return io.size(getpath(loc))
			end
		end

		return drv
	end

}
