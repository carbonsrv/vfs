-- Carbon VFS
-- modular simplistic virtual filesystem handling designed for carbon

vfs = vfs or {}

-- Depends on: ltn12
ltn12 = ltn12 or require("ltn12")

-- Helpers:
-- Relative <-> Absolute Path conversion
vfs.helpers = {}

-- from http://lua-users.org/wiki/SplitJoin
local function strsplit(self, sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)

	local aRecord = {}

	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField, nStart = 1, 1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
	end

	return aRecord
end


local function e(msg)
	error("VFS: "..msg, 0)
end

local function is_relative(path)
	return string.sub(path, 1, 1) ~= "/" -- that's probably not the best...
end

local function cleanpath(path)
	if string.sub(path, -1) == "/" then
		path = string.gsub(path, "^/+", "/")
	end
	return string.gsub(path, "//+", "/")
end

local function abspath(rel, base)
	if string.sub(rel, 1, 1) == "/" then -- just in case rel is actually absolute
		return cleanpath(rel)
	end
	if rel == "" or rel == "." then
		return cleanpath(base) -- didn't change path
	end

	base = string.gsub(base, "^/+", "")
	local path = strsplit(base, "/")
	local pathn = #path
	local relpath = strsplit(rel, "/")
	for i=0, #relpath do
		local elm = relpath[i]
		if elm == ".." then -- step back
			if pathn > 0 then
				path[pathn] = nil
				pathn = pathn - 1
			end
		elseif elm ~= nil and elm ~= "" and elm ~= "." then
			pathn = pathn + 1
			path[pathn] = elm
		end
	end
	return "/"..table.concat(path, "/")
end
vfs.abspath = abspath
vfs.is_relative = is_relative

-- Backends:
-- Backends have an init function with arguments to support it.
-- These functions should set up the env for the other functions, like read.

-- You should at least provide read for a read-only fs, add write if you have a read-write fs. However, you should probably add exists, size, modtime, rename, mkdir, delete, isdir, getcwd, chdir and list if you want to have a fully fledged filesystem that is read-writable, has directories and keeps track of the current directory.
-- You can also implement other methods for your backends specific features.
-- One thing to implement would be LTN12 compatible reader and writer, however they don't have to exist.
-- If they don't, rather crude LTN12 wrappers around read and write exists as a fallback if they don't.
-- LTN12 compatibility would make things more efficient given proper implementation, because of the streaming ability, resulting in possibly faster transfer but mostly less memory use.

vfs.backends = vfs.backends or {}

function vfs.loadbackends(name)
	local newbackends = require("vfs.backends."..name)
	package.loaded["vfs.backends."..name] = nil
	if type(newbackends) == "table" then
		for k, v in pairs(newbackends) do
			vfs.backends[k] = v
		end
	end
end

-- Load native backend
vfs.loadbackends("native")

if carbon then
	-- Load the vfs.backends.carbon file, which initializes all the backends specific to carbon.
	vfs.loadbackends("carbon")
end

-- drives:
-- Basically instances of backends

vfs.drives = vfs.drives or {}

local function get_drive_field(drive, field)
	local drv = vfs.drives[drive]
	if drv then
		return drv[field]
	end
	e("No such drive: "..drive)
end

local function call_backend(drive, func, ...)
	local f = get_drive_field(drive, func)
	if f then
		return f(...)
	end
	e("Drive "..drive.." provides no function named "..func)
end

vfs.get_drive_field = get_drive_field
vfs.call_backend = call_backend

-- drive init and unmount
function vfs.new(drivename, backend, ...)
	if vfs.backends[backend] then
		if not vfs.drives[drivename] then
			vfs.drives[drivename] = vfs.backends[backend](drivename, ...)
			return true
		end
		return false
	end
	e("No such backend: "..backend)
end
vfs.mount = vfs.new

function vfs.unmount(drivename)
	local drive = vfs.drives[drivename]
	if drive then
		if drive.unmount then
			drive.unmount()
		end
		vfs.drives[drivename] = nil
	end
end

-- default drive selection:
-- if the path is not in the form of "drive:whatever", use the default drive.

-- call vfs.default_drive with"root" or whatever drive you want the default.
if carbon then
	local default_drive_key = "carbon:vfs:default_drive"
	function vfs.set_default_drive(drivename)
		kvstore._set(default_drive_key, drivename)
	end
	function vfs.default_drive()
		return kvstore._get(default_drive_key)
	end
else
	function vfs.set_default_drive(drivename)
		vfs._default_drive = drivename
	end
	function vfs.default_drive()
		return vfs._default_drive
	end
end

local function parse_path(path, default)
	local drive, filepath = string.match(path or "", "^(%w-):(.+)$")
	if drive and filepath then -- full vfs path
		return drive, filepath
	else -- "normal" path, like /bla
		return default or vfs.default_drive(), path
	end
end
vfs.parse_path = parse_path

-- Helpers which overwrite backend functions.
function vfs.copy(fpsrc, fpdst)
	local fpsrc_drivename, fpsrc_path = parse_path(fpsrc)
	local fpdst_drivename, fpdst_path = parse_path(fpdst)
	local fpsrc_drive = vfs.drives[fpsrc_drivename]
	local fpdst_drive = vfs.drives[fpdst_drivename]
	local fpsrc_backend = vfs.backends[fpsrc_drive]
	local fpdst_backend = vfs.backends[fpdst_drive]

	if fpsrc_drive == fpdst_drive then -- same device copy
		if fpsrc_drive.copy then -- backend has a specific copy function
			return fpsrc_drive.copy(fpsrc_path, fpdst_path)
		end
	end

	-- streaming inter device copy
	if fpsrc_drive.reader and fpdst_drive.writer then -- ltn12! woo!
		return ltn12.pump.all(
			fpsrc_backend.reader(fpsrc_path),
			fpdst_backend.writer(fpdst_path)
		)
	end

	-- fallback
	local src = fpsrc_drive.read(fpsrc_path)
	return fpdst_drive.write(fpdst_path, src)
end

function vfs.reader(src)
	local src_drivename, src_path = parse_path(src)
	local src_drive = vfs.drives[src_drivename]

	if src_drive.reader then -- native LTN12 reader exists
		return src_drive.reader(src_path)
	end

	-- A quite dirty hack, just for programs which definitly want a LTN12 reader, but the backend doesn't have one.
	-- Probably not that efficient.
	local str = src_drive.read(src_path)
	return ltn12.source.string(str)
end

function vfs.writer(dst)
	local dst_drivename, dst_path = parse_path(dst)
	local dst_drive = vfs.drives[dst_drivename]

	if dst_drive.writer then
		return dst_drive.writer(dst_path)
	end

	-- Another dirty hack. This one just concatenates chunk after chunk and writes it out when there is no more.
	local s = ""
	return function(chunk)
		if not chunk then
			return dst_drive.write(dst_path, chunk)
		end
		s = s .. tostring(chunk)
		return 1
	end
end

-- A package.loader for all your vfs-y needs.
-- Call vfs.searchpath("mydrive:/lualibs/?.lua;mydrive:/lualibs/?/init.lua") to set your search path and what not.

if carbon then
	function vfs.searchpath(new)
		if new then
			kvstore._set("carbon:vfs:searchpath", new)
		else
			return kvstore._get("carbon:vfs:searchpath")
		end
	end
else
	function vfs.searchpath(new)
		if new then
			vfs._searchpath = new
		else
			return vfs._searchpath
		end
	end
end

-- carbon cache vars
local carbon_do_cache_prefix = "carbon:do_cache:"
local carbon_dont_cache_vfs = "carbon:dont_cache:vfs"
local carbon_cache_prefix = "carbon:lua_module:bc:"
local carbon_cache_prefix_loc = "carbon:lua_module:loc:"

-- Actual loader
function vfs.loader(name)
	local sp = vfs.searchpath()
	if not sp then
		return "\n\tno vfs searchpath set"
	end

	local estr = ""
	local modname = tostring(name):gsub("%.", "/")

	-- iterate over the split things in the searchpath, replacing the ? with the modname
	local entries = strsplit(string.gsub(sp, "%?", modname), ";")
	for ne=1, #entries do
		local fp = entries[ne]

		-- read file and load it if it is found
		local drive, path = parse_path(fp)
		if vfs.drives[drive] then
			local src = call_backend(drive, "read", path)
			if src then -- found
				local f, err = loadstring(src, fp)
				if err then error(err, 0) end
				if carbon then -- carbon has an integrated cache for loading libs and stuff.
					if kvstore._get(carbon_do_cache_prefix..modname) ~= false and kvstore._get(carbon_dont_cache_vfs) ~= true then
						kvstore._set(carbon_cache_prefix..modname, string.dump(f))
						kvstore._set(carbon_cache_prefix_loc..modname, fp)
					end
				end
				return f
			else
				estr = estr .. "\n\tno file in vfs under "..fp
			end
		else
			estr = estr .. "\n\tno vfs drive named "..drive
		end
	end

	return estr
end

-- Generic function addition
-- Magic!

setmetatable(vfs, {__index=function(_, name)
	return function(filepath, ...)
		local drive, path = parse_path(filepath)
		if path then
			return call_backend(drive, name, path, ...)
		end
		return call_backend(drive, name, ...)
	end
end})

-- End
return vfs
