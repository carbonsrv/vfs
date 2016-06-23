-- Carbon GoFS backend

if not carbon then
	error("VFS: carbon backends can only be loaded when running in Carbon: https://github.com/carbonsrv/carbon", 0)
end

local function e(msg)
	error("VFS: "..msg, 0)
end

-- Allows any generic http.FileSystem to be used as a VFS.
return {
	gofs = function(drivename, fs, prefix)
		if not fs then
			e("Backend GOFS: Needs http.FileSystem.")
		end

		local cwd = "/"
		local base = "/"..(prefix or "")
		local function getdir(path)
			return base .. vfs.abspath(path or ".", cwd)
		end

		return {
			-- disabled modifying functions
			write = function() e("Drive "..drivename..": writing disabled!") end,
			mkdir = function() e("Drive "..drivename..": directory creation disabled!") end,
			delete = function() e("Drive "..drivename..": file removal disabled!") end,
			rename = function() e("Drive "..drivename..": renaming disabled!") end,

			-- read only funcs
			exists = function(loc) return carbon._filesystem_exists(fs, getdir(loc)) end,
			isdir = function(loc) return carbon._filesystem_isdir(fs, getdir(loc)) end,
			read = function(loc)
				local str, err = carbon._filesystem_readfile(fs, getdir(loc))
				if err then
					return nil, err
				end
				return str
			end,
			reader = function(loc)
				local i = 1
				return function()
					local chunk, err = carbon._filesystem_readat(fs, getdir(loc), i, ltn12.BLOCKSIZE)
					i = i + ltn12.BLOCKSIZE
					if err or chunk == "" then
						return nil
					end
					return chunk, i
				end
			end,
			list = function(loc)
				local res, err = carbon._filesystem_list(fs, getdir(loc))
				if err then
					return nil, err
				end
				return luar.slice2table(res), nil
			end,
			modtime = function(loc)
				local res, err = carbon._filesystem_modtime(fs, getdir(loc))
				if err then
					return nil, err
				end
				return res, nil
			end,
			size = function(loc)
				local res, err = carbon._filesystem_size(fs, getdir(loc))
				if err then
					return nil, err
				end
				return res, nil
			end,

			-- generic functions
			chdir = function(loc) cwd = abspath(loc, cwd) return cwd end,
			getcwd = function(loc) return cwd end,
		}
	end,
}
