-- Carbon PhysFS backend

if not carbon then
	error("VFS: carbon backends can only be loaded when running in Carbon: https://github.com/carbonsrv/carbon", 0)
end

-- Read-only (for now) physfs backend for carbon
-- TODO: Maybe write compatibility?
local physfs = physfs or fs

local function e(msg)
	error("VFS: "..msg, 0)
end

return {
	physfs = function(drivename, path, ismounted)
		if not ismounted and not physfs.exists("/"..drivename) then
			physfs.mount(path, "/"..drivename)
		end

		local cwd = "/"
		local base = "/"..drivename
		local function getdir(path)
			return base .. vfs.abspath(path or ".", cwd)
		end

		return {
			-- disabled modifying functions
			write = function() e("Drive "..drivename..": PhysFS writing disabled!") end,
			mkdir = function() e("Drive "..drivename..": PhysFS directory creation disabled!") end,
			delete = function() e("Drive "..drivename..": PhysFS file removal disabled!") end,
			rename = function() e("Drive "..drivename..": PhysFS renaming disabled!") end,

			-- read only funcs
			exists = function(loc) return physfs.exists(getdir(loc)) end,
			isdir = function(loc) return physfs.isDir(getdir(loc)) end,
			read = function(loc) return physfs.readfile(getdir(loc)) end,
			reader = function(loc)
				local i = 1
				local fp = getdir(loc)
				physfs.needfile(fp)
				return function()
					local chunk, err = physfs.readn(fp, ltn12.BLOCKSIZE)
					if err or chunk == "" then
						physfs.close(fp)
						return nil
					end
					return chunk, i
				end
			end,
			list = function(loc) return physfs.list(getdir(loc)) end,
			modtime = function(loc) return physfs.modtime(getdir(loc)) end,
			size = function(loc) return physfs.size(getdir(loc)) end,

			-- generic functions
			chdir = function(loc) cwd = vfs.abspath(loc, cwd) return cwd end,
			getcwd = function(loc) return cwd end,

		-- deinit function
			unmount = function() if not ismounted then physfs.unmount(base) end end,
		}
	end,
}
