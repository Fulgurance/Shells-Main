class Target < ISM::Software
    
    def configure
        super

        if option("Pass1")
            configureSource([   "--prefix=/usr",
                                "--build=$(support/config.guess)",
                                "--host=#{Ism.settings.target}",
                                "--without-bash-malloc"],
                                buildDirectoryPath)
        else
            configureSource([   "--prefix=/usr",
                                "--docdir=/usr/share/doc/bash-5.1.8",
                                "--without-bash-malloc",
                                "--with-installed-readline"],
                                buildDirectoryPath)
        end
    end
    
    def build
        super

        makeSource([Ism.settings.makeOptions],buildDirectoryPath)
    end
    
    def prepareInstallation
        super

        makeSource([Ism.settings.makeOptions,"DESTDIR=#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}","install"],buildDirectoryPath)
    end

    def install
        super

        if option("Pass1")
            makeLink("bash","#{Ism.settings.rootPath}bin/sh",:symbolicLink)
        end
    end

end
