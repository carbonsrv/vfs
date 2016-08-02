-- FFI PhysFS backend

local ffi = ffi or require("ffi")

ffi.cdef [[
typedef unsigned char				 PHYSFS_uint8;
typedef signed char					 PHYSFS_sint8;
typedef unsigned short				PHYSFS_uint16;
typedef signed short					PHYSFS_sint16;
typedef unsigned int					PHYSFS_uint32;
typedef signed int						PHYSFS_sint32;
typedef unsigned long long		PHYSFS_uint64;
typedef signed long long			PHYSFS_sint64;

typedef struct PHYSFS_File
{
		void *opaque;	/**< That's all you get. Don't touch. */
} PHYSFS_File;

typedef struct PHYSFS_ArchiveInfo
{
		const char *extension;	 /**< Archive file extension: "ZIP", for example. */
		const char *description; /**< Human-readable archive description. */
		const char *author;			/**< Person who did support for this archive. */
		const char *url;				 /**< URL related to this archive */
} PHYSFS_ArchiveInfo;

typedef struct PHYSFS_Version
{
		PHYSFS_uint8 major; /**< major revision */
		PHYSFS_uint8 minor; /**< minor revision */
		PHYSFS_uint8 patch; /**< patchlevel */
} PHYSFS_Version;

void PHYSFS_getLinkedVersion(PHYSFS_Version *ver);
int PHYSFS_init(const char *argv0);
int PHYSFS_deinit(void);
const PHYSFS_ArchiveInfo **PHYSFS_supportedArchiveTypes(void);
void PHYSFS_freeList(void *listVar);
const char *PHYSFS_getLastError(void);
const char *PHYSFS_getDirSeparator(void);
void PHYSFS_permitSymbolicLinks(int allow);
char **PHYSFS_getCdRomDirs(void);
const char *PHYSFS_getBaseDir(void);
// const char *PHYSFS_getUserDir(void); // this will probably crash
const char *PHYSFS_getWriteDir(void);
int PHYSFS_setWriteDir(const char *newDir);
// legacy calls
// int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);
// int PHYSFS_removeFromSearchPath(const char *oldDir);
// char **PHYSFS_getSearchPath(void);
int PHYSFS_setSaneConfig(const char *organization, const char *appName, const char *archiveExt, int includeCdRoms, int archivesFirst); // who needs sane?
int PHYSFS_mkdir(const char *dirName);
int PHYSFS_delete(const char *filename);
const char *PHYSFS_getRealDir(const char *filename);
char **PHYSFS_enumerateFiles(const char *dir);
int PHYSFS_exists(const char *fname);
int PHYSFS_isDirectory(const char *fname);
int PHYSFS_isSymbolicLink(const char *fname);
PHYSFS_sint64 PHYSFS_getLastModTime(const char *filename);
PHYSFS_File *PHYSFS_openWrite(const char *filename);
PHYSFS_File *PHYSFS_openAppend(const char *filename);
PHYSFS_File *PHYSFS_openRead(const char *filename);
int PHYSFS_close(PHYSFS_File *handle);
PHYSFS_sint64 PHYSFS_read(PHYSFS_File *handle, void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);
PHYSFS_sint64 PHYSFS_write(PHYSFS_File *handle, void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);
int PHYSFS_eof(PHYSFS_File *handle);
PHYSFS_sint64 PHYSFS_tell(PHYSFS_File *handle);
int PHYSFS_seek(PHYSFS_File *handle, PHYSFS_uint64 pos);
PHYSFS_sint64 PHYSFS_fileLength(PHYSFS_File *handle);
int PHYSFS_setBuffer(PHYSFS_File *handle, PHYSFS_uint64 bufsize);
int PHYSFS_flush(PHYSFS_File *handle);
PHYSFS_sint16 PHYSFS_swapSLE16(PHYSFS_sint16 val);
PHYSFS_uint16 PHYSFS_swapULE16(PHYSFS_uint16 val);
PHYSFS_sint32 PHYSFS_swapSLE32(PHYSFS_sint32 val);
PHYSFS_uint32 PHYSFS_swapULE32(PHYSFS_uint32 val);
PHYSFS_sint64 PHYSFS_swapSLE64(PHYSFS_sint64 val);
PHYSFS_uint64 PHYSFS_swapULE64(PHYSFS_uint64 val);
PHYSFS_sint16 PHYSFS_swapSBE16(PHYSFS_sint16 val);
PHYSFS_uint16 PHYSFS_swapUBE16(PHYSFS_uint16 val);
PHYSFS_sint32 PHYSFS_swapSBE32(PHYSFS_sint32 val);
PHYSFS_uint32 PHYSFS_swapUBE32(PHYSFS_uint32 val);
PHYSFS_sint64 PHYSFS_swapSBE64(PHYSFS_sint64 val);
PHYSFS_uint64 PHYSFS_swapUBE64(PHYSFS_uint64 val);
int PHYSFS_readSLE16(PHYSFS_File *file, PHYSFS_sint16 *val);
int PHYSFS_readULE16(PHYSFS_File *file, PHYSFS_uint16 *val);
int PHYSFS_readSBE16(PHYSFS_File *file, PHYSFS_sint16 *val);
int PHYSFS_readUBE16(PHYSFS_File *file, PHYSFS_uint16 *val);
int PHYSFS_readSLE32(PHYSFS_File *file, PHYSFS_sint32 *val);
int PHYSFS_readULE32(PHYSFS_File *file, PHYSFS_uint32 *val);
int PHYSFS_readSBE32(PHYSFS_File *file, PHYSFS_sint32 *val);
int PHYSFS_readUBE32(PHYSFS_File *file, PHYSFS_uint32 *val);
int PHYSFS_readSLE64(PHYSFS_File *file, PHYSFS_sint64 *val);
int PHYSFS_readULE64(PHYSFS_File *file, PHYSFS_uint64 *val);
int PHYSFS_readSBE64(PHYSFS_File *file, PHYSFS_sint64 *val);
int PHYSFS_readUBE64(PHYSFS_File *file, PHYSFS_uint64 *val);

int PHYSFS_writeSLE16(PHYSFS_File *file, PHYSFS_sint16 *val);
int PHYSFS_writeULE16(PHYSFS_File *file, PHYSFS_uint16 *val);
int PHYSFS_writeSBE16(PHYSFS_File *file, PHYSFS_sint16 *val);
int PHYSFS_writeUBE16(PHYSFS_File *file, PHYSFS_uint16 *val);
int PHYSFS_writeSLE32(PHYSFS_File *file, PHYSFS_sint32 *val);
int PHYSFS_writeULE32(PHYSFS_File *file, PHYSFS_uint32 *val);
int PHYSFS_writeSBE32(PHYSFS_File *file, PHYSFS_sint32 *val);
int PHYSFS_writeUBE32(PHYSFS_File *file, PHYSFS_uint32 *val);
int PHYSFS_writeSLE64(PHYSFS_File *file, PHYSFS_sint64 *val);
int PHYSFS_writeULE64(PHYSFS_File *file, PHYSFS_uint64 *val);
int PHYSFS_writeSBE64(PHYSFS_File *file, PHYSFS_sint64 *val);
int PHYSFS_writeUBE64(PHYSFS_File *file, PHYSFS_uint64 *val);
// everything below here is physfs 2.0
int PHYSFS_isInit(void);
int PHYSFS_symbolicLinksPermitted(void);
// int PHYSFS_setAllocator(const PHYSFS_Allocator *allocator);
int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);

const char *PHYSFS_getMountPoint(const char *dir);
typedef void (*PHYSFS_StringCallback)(void *data, const char *str);
typedef void (*PHYSFS_EnumFilesCallback)(void *data, const char *origdir, const char *fname);
void PHYSFS_getSearchPathCallback(PHYSFS_StringCallback c, void *d);
void PHYSFS_enumerateFilesCallback(const char *dir, PHYSFS_EnumFilesCallback c, void *d);
void PHYSFS_utf8FromUcs4(const PHYSFS_uint32 *src, char *dst, PHYSFS_uint64 len);
void PHYSFS_utf8ToUcs4(const char *src, PHYSFS_uint32 *dst, PHYSFS_uint64 len);
void PHYSFS_utf8FromUcs2(const PHYSFS_uint16 *src, char *dst, PHYSFS_uint64 len);
void PHYSFS_utf8ToUcs2(const char *src, PHYSFS_uint16 *dst, PHYSFS_uint64 len);
void PHYSFS_utf8FromLatin1(const char *src, char *dst, PHYSFS_uint64 len);
]]

local C = ffi.C

local function e(msg)
	error("VFS: "..msg, 0)
end

-- init
if not vfs.backends._physfs_inited == true then
	ffi.load("physfs", true)
	C.PHYSFS_init(nil)
	vfs.backends._physfs_inited = true
end

-- helpers
local physfs_open = function(path, mode)
	local mode = (mode and mode:sub(1,1)) or "r"
	local f
	if mode == "r" then
		f = C.PHYSFS_openRead(path)
	elseif mode == "w" then
		f = C.PHYSFS_openWrite(path)
	elseif mode == "a" then
		f = C.PHYSFS_openAppend(path)
	end
	if f ~= nil then
		return ffi.gc(f, C.PHYSFS_close)
	end
end

local file_mt =
{
	__index = {
		length = function(self)
			return tonumber(ffi.C.PHYSFS_fileLength(self))
		end,

		read = function(self, spec)
			local len

			if type(spec) == "number" then
				len = spec
			end

			if spec == "*all" or spec == "*a" then
				len = self:length()
			end

			local buf = ffi.new("uint8_t[?]", len)
			local ret = tonumber(C.PHYSFS_read(self, buf, 1, len))

			if ret == 0 then
				return nil
			else
				return ffi.string(buf, ret)
			end
		end,

		readat = function(self, at, n)
			n = n or 1
			local buf = ffi.new("uint8_t[?]", n)
			C.PHYSFS_seek(self, at)
			local ret = tonumber(C.PHYSFS_read(self, buf, 1, n))
			if ret == 0 then
				return nil
			else
				return ffi.string(buf, ret)
			end
		end,

		close = function(self)
			return ffi.C.PHYSFS_close(self) ~= 0
		end
	}
}

local PHYSFS_File = ffi.metatype("PHYSFS_File", file_mt)

local physfs_exists = function(path)
	return C.PHYSFS_exists(path) ~= 0
end


-- backend
return {
	physfs = function(drivename, path, ismounted)
		if not ismounted and not physfs_exists("/"..drivename) then
			assert(C.PHYSFS_mount(path, "/"..drivename, 0) ~= 0)
		end

		local cwd = "/"
		local base = "/"..drivename
		local function getdir(path)
			return base .. vfs.abspath(path or ".", cwd)
		end

		return {
			-- rw funcs
			write = function() e("Drive "..drivename..": PhysFS writing not implemented!") end,
			mkdir = function(loc) return ffi.C.PHYSFS_mkdir(getdir(loc)) ~= 0 end,
			delete = function() return ffi.C.PHYSFS_delete(getdir(loc)) ~= 0 end,
			rename = function() e("Drive "..drivename..": PhysFS renaming not implemented!") end,

			-- read only funcs
			exists = function(loc) return physfs_exists(getdir(loc)) end,
			isdir = function(loc) return C.PHYSFS_isDirectory(getdir(loc)) ~= 0 end,
			read = function(loc) return physfs_open(getdir(loc), "r"):read("*all") end,
			reader = function(loc)
				local i = 1
				local fp = getdir(loc)
				local f = physfs_open(fp, "r")
				return function()
					local chunk, err = f:readat(i, ltn12.BLOCKSIZE)
					if err or chunk == "" then
						fp:close()
						return nil
					end
					i = i + ltn12.BLOCKSIZE
					return chunk, i
				end
			end,

			list = function(loc)
				local l = ffi.C.PHYSFS_enumerateFiles(getdir(loc))

				local t = {}
				local i = 0
				while tonumber(ffi.cast("intptr_t", l[i])) ~= 0 do
						t[#t+1] = ffi.string(l[i])
						i = i + 1
				end

				C.PHYSFS_freeList(l)
				return t
			end,

			modtime = function(loc)
				local fp = physfs_open(getdir(loc), "r")
				return tonumber(C.PHYSFS_getLastModTime(fp))
			end,
			size = function(loc) return physfs_open(getdir(loc), "r"):length() end,

			-- generic functions
			chdir = function(loc) cwd = vfs.abspath(loc, cwd) return cwd end,
			getcwd = function(loc) return cwd end,

		-- deinit function
			unmount = function() if not ismounted then return C.PHYSFS_removeFromSearchPath(path) end end,
		}
	end,
}
