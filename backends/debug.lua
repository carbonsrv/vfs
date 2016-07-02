-- Debug backend to show what the VFS is doing.
local abspath = vfs.abspath
return {
	debug = function() -- stubs, not actually usable
		local cwd = "/"
		return {
			write = function(loc, str) print("Write to "..abspath(loc, cwd).." with content: "..str) return true end,
			read = function(loc) print("Reading "..abspath(loc, cwd)) return "" end,
			size = function(loc) print("size check at "..abspath(loc, cwd)) return 0 end,
			exists = function(loc) print("check if "..abspath(loc, cwd).." exists") return true end,
			mkdir = function(loc) print("mkdir at "..abspath(loc)) return true end,
			delete = function(loc) print("delete at "..abspath(loc, cwd)) return true end,
			list = function(loc) print("list at "..abspath(loc, cwd)) return {} end,
			chdir = function(loc) print("cwd is now "..vfs.abspath(loc, cwd)) cwd = vfs.abspath(loc, cwd) return cwd end,
			getcwd = function() print("getcwd (is "..cwd..")") return cwd end,
		}
	end
}
