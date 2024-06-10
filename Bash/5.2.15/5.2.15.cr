class Target < ISM::Software
    
    def configure
        super

        if option("Pass1")
            configureSource([   "--prefix=/usr",
                                "--build=$(support/config.guess)",
                                "--host=#{Ism.settings.chrootTarget}",
                                "--without-bash-malloc"],
                                buildDirectoryPath)
        else
            configureSource([   "--prefix=/usr",
                                "--docdir=/usr/share/doc/bash-5.2.15",
                                "--without-bash-malloc",
                                "--with-installed-readline"],
                                buildDirectoryPath)
        end
    end
    
    def build
        super

        makeSource(path: buildDirectoryPath)
    end
    
    def prepareInstallation
        super

        makeSource(["DESTDIR=#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}","install"],buildDirectoryPath)

        if !option("Pass1")
            makeDirectory("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d")
            makeDirectory("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/skel/")
            makeDirectory("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}root/")

            profileData = <<-CODE
            pathremove () {
            local IFS=':'
            local NEWPATH
            local DIR
            local PATHVARIABLE=${2:-PATH}
            for DIR in ${!PATHVARIABLE} ; do
                    if [ "$DIR" != "$1" ] ; then
                    NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                    fi
            done
            export $PATHVARIABLE="$NEWPATH"
            }

            pathprepend () {
                    pathremove $1 $2
                    local PATHVARIABLE=${2:-PATH}
                    export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
            }

            pathappend () {
                    pathremove $1 $2
                    local PATHVARIABLE=${2:-PATH}
                    export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
            }

            export -f pathremove pathprepend pathappend

            export PATH=/usr/bin

            if [ ! -L /bin ]; then
                    pathappend /bin
            fi

            if [ $EUID -eq 0 ] ; then
                    pathappend /usr/sbin
                    if [ ! -L /sbin ]; then
                            pathappend /sbin
                    fi
                    unset HISTFILE
            fi

            export HISTSIZE=1000
            export HISTIGNORE="&:[bf]g:exit"

            #export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share/}
            #export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg/}
            #export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

            NORMAL="\\[\\e[0m\\]"
            RED="\\[\\e[1;31m\\]"
            GREEN="\\[\\e[1;32m\\]"
            if [[ $EUID == 0 ]] ; then
            PS1="$RED\\u [ $NORMAL\\w$RED ]# $NORMAL"
            else
            PS1="$GREEN\\u [ $NORMAL\\w$GREEN ]\\$ $NORMAL"
            fi

            for script in /etc/profile.d/*.sh ; do
                    if [ -r $script ] ; then
                            . $script
                    fi
            done

            unset script RED GREEN NORMAL
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile",profileData)

            bashrcData = <<-CODE
            alias ls='ls --color=auto'
            alias grep='grep --color=auto'

            NORMAL="\\[\\e[0m\\]"
            RED="\\[\\e[1;31m\\]"
            GREEN="\\[\\e[1;32m\\]"
            if [[ $EUID == 0 ]] ; then
            PS1="$RED\\u [ $NORMAL\\w$RED ]# $NORMAL"
            else
            PS1="$GREEN\\u [ $NORMAL\\w$GREEN ]\\$ $NORMAL"
            fi

            unset RED GREEN NORMAL
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/bashrc",bashrcData)

            qt5Data = <<-CODE
            QT5DIR=/usr
            export QT5DIR
            pathappend $QT5DIR/bin
            pathappend /usr/lib/qt5/plugins QT_PLUGIN_PATH
            pathappend $QT5DIR/lib/plugins QT_PLUGIN_PATH
            pathappend /usr/lib/qt5/qml QML2_IMPORT_PATH
            pathappend $QT5DIR/lib/qml QML2_IMPORT_PATH
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/qt5.sh",qt5Data)

            kf5Data = <<-CODE
            export KF5_PREFIX=/usr
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/kf5.sh",kf5Data)

            skelBashrcData = <<-CODE
            . /etc/profile
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/skel/.bashrc",skelBashrcData)

            rootBashrcData = <<-CODE
            . /etc/profile
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}root/.bashrc",rootBashrcData)

            shellData = <<-CODE
            /bin/sh
            /bin/bash
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/shells",shellData)
        end

        if option("Pass1")
            makeLink("bash","#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}usr/bin/sh",:symbolicLink)
        end
    end

end
