function sh -d 'Run POSIX code via bash (posix-fish compatibility layer)'
    # no argparse: fish would permute the script's own options (-a -b...)
    if set -q argv[1]
        switch $argv[1]
            case -h --help
                echo 'usage: sh -c '\''code'\'' [name [args...]]'
                echo '       sh script.sh [args...]'
                echo '       sh '\''code'\''        (shortcut: bash -c)'
                echo '       ... | sh            (script from stdin)'
                echo '       command sh ...      (raw bash, no layer)'
                return 0
        end
    end

    if not set -q argv[1]
        # no argument: bash reads the script from stdin (if piped),
        # or opens an interactive shell (if a tty)
        command bash
        return $status
    end

    if test "$argv[1]" = -c
        # -c code [name [args...]]: bash handles $0/$1... natively
        command bash $argv
        return $status
    end

    if test -f "$argv[1]"
        # script file + arguments: bash handles everything
        command bash $argv
        return $status
    end

    # shortcut: code passed as an argument -> bash -c
    command bash -c "$argv"
    return $status
end
