class Target < ISM::Software
    
    def configure
        super
        configureSource([   "--prefix=/usr",
                            "--docdir=/usr/share/doc/bash-5.1.8",
                            "--without-bash-malloc",
                            "--with-installed-readline"],
                            buildDirectoryPath)
    end
    
    def build
        super
        makeSource([Ism.settings.makeOptions],buildDirectoryPath)
    end
    
    def prepareInstallation
        super
        makeSource([Ism.settings.makeOptions,"DESTDIR=#{builtSoftwareDirectoryPath}/#{Ism.settings.rootPath}","install"],buildDirectoryPath)
    end

end
