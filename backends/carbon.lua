-- Carbon specific backends

if not carbon then
	error("VFS: carbon backends can only be loaded when running in Carbon: https://github.com/carbonsrv/carbon", 0)
end

-- Load all of them!
vfs.loadbackends("carbon.physfs")
vfs.loadbackends("carbon.gofs")
vfs.loadbackends("carbon.shared")
