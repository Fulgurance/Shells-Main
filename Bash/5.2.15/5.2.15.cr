class Target < ISM::Software
    
    def configure
        super

        if option("Pass1")
            configureSource(arguments:  "--prefix=/usr                          \
                                        --build=$(support/config.guess)         \
                                        --host=#{Ism.settings.chrootTarget}     \
                                        --without-bash-malloc",
                        path:           buildDirectoryPath)
        else
            configureSource(arguments:  "--prefix=/usr                      \
                                        --docdir=/usr/share/doc/bash-5.2.15 \
                                        --without-bash-malloc               \
                                        --with-installed-readline",
                            path:       buildDirectoryPath)
        end
    end
    
    def build
        super

        makeSource(path: buildDirectoryPath)
    end
    
    def prepareInstallation
        super

        makeSource( arguments:  "DESTDIR=#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath} install",
                    path:       buildDirectoryPath)

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

            export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share/}
            export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg/}
            export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

            NORMAL="\[\e[0m\]"
            RED="\[\e[1;31m\]"
            GREEN="\[\e[1;32m\]"
            if [[ $EUID == 0 ]] ; then
            PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
            else
            PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
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

            NORMAL="\[\e[0m\]"
            RED="\[\e[1;31m\]"
            GREEN="\[\e[1;32m\]"

            if [[ $EUID == 0 ]] ; then
                PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
            else
                PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
            fi

            unset RED GREEN NORMAL
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/bashrc",bashrcData)

            completionData = <<-CODE
            if [ -f /usr/share/bash-completion/bash_completion ]; then

                if [ -n "${BASH_VERSION-}" -a -n "${PS1-}" -a -z "${BASH_COMPLETION_VERSINFO-}" ]; then

                    if [ ${BASH_VERSINFO[0]} -gt 4 ] || \
                    [ ${BASH_VERSINFO[0]} -eq 4 -a ${BASH_VERSINFO[1]} -ge 1 ]; then
                    [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ] && \
                            . "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
                        if shopt -q progcomp && [ -r /usr/share/bash-completion/bash_completion ]; then
                            . /usr/share/bash-completion/bash_completion
                        fi
                    fi
                fi

                else

                if shopt -q progcomp; then
                    for script in /etc/bash_completion.d/* ; do
                        if [ -r $script ] ; then
                            . $script
                        fi
                    done
                fi
            fi
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/completion.sh",completionData)

            dircolorsData = <<-CODE
            if [ -f "/etc/dircolors" ] ; then
                eval $(dircolors -b /etc/dircolors)
            fi

            if [ -f "$HOME/.dircolors" ] ; then
                eval $(dircolors -b $HOME/.dircolors)
            fi

            alias ls='ls --color=auto'
            alias grep='grep --color=auto'
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/dircolors.sh",dircolorsData)

            extrapathData = <<-CODE
            if [ -d /usr/local/lib/pkgconfig ] ; then
                pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
            fi
            if [ -d /usr/local/bin ]; then
                pathprepend /usr/local/bin
            fi
            if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
                pathprepend /usr/local/sbin
            fi

            if [ -d /usr/local/share ]; then
                pathprepend /usr/local/share XDG_DATA_DIRS
            fi

            pathappend /usr/share/man  MANPATH
            pathappend /usr/share/info INFOPATH
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/extrapath.sh",extrapathData)

            readlineData = <<-CODE
            if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
                INPUTRC=/etc/inputrc
            fi
            export INPUTRC
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/readline.sh",readlineData)

            umaskData = <<-CODE
            if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
                umask 002
            else
                umask 022
            fi
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/umask.sh",umaskData)

            i18nData = <<-CODE
            #export LANG=<ll>_<CC>.<charmap><@modifiers>
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/profile.d/i18n.sh",i18nData)

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
            if [ -f "/etc/bashrc" ] ; then
                source /etc/bashrc
            fi

            #export LANG=<ll>_<CC>.<charmap><@modifiers>
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/skel/.bashrc",skelBashrcData)
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}root/.bashrc",skelBashrcData)

            skelBashProfileData = <<-CODE
            if [ -f "$HOME/.bashrc" ] ; then
                source $HOME/.bashrc
            fi

            if [ -d "$HOME/bin" ] ; then
                pathprepend $HOME/bin
            fi
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/skel/.bash_profile",skelBashProfileData)
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}root/.bash_profile",skelBashProfileData)

            skelBashLogoutData = <<-CODE
            # Personal calls on logout.
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/skel/.bash_logout",skelBashLogoutData)
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}root/.bash_logout",skelBashLogoutData)


            shellData = <<-CODE
            /bin/sh
            /bin/bash
            CODE
            fileWriteData("#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}etc/shells",shellData)
        end

        if option("Pass1")
            makeLink(   target: "bash",
                        path:   "#{builtSoftwareDirectoryPath}#{Ism.settings.rootPath}usr/bin/sh",
                        type:   :symbolicLink)
        end
    end

    def install
        super

        if !option("Pass1")
            runChownCommand("-R root:root /etc/profile.d")
            runChmodCommand("0755 /etc/profile.d")
            runDircolorsCommand("-p > /etc/dircolors")
        end
    end

end
