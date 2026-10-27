#!/usr/bin/env fish
# tests/run.fish — execution test suite for posix-fish
# usage: fish tests/run.fish

set -l here (dirname (status filename))
set -l root (cd $here/..; and pwd)
set -g fish_function_path $root/functions $fish_function_path
# the only function is sh (forwards to bash); autoload is enough

set -g _pass 0
set -g _fail 0

function check -a name expected code
    set -l out (sh -c "$code" $argv[4..-1] 2>&1 | string collect)
    if test "$out" = "$expected"
        set -g _pass (math $_pass + 1)
        printf 'ok   %s\n' "$name"
    else
        set -g _fail (math $_fail + 1)
        printf 'FAIL %s\n     expected: %s\n     got:      %s\n' "$name" (string escape -- "$expected") (string escape -- "$out")
    end
end

function check_status -a name expected code
    sh -c "$code" >/dev/null 2>&1
    set -l st $status
    if test $st -eq $expected
        set -g _pass (math $_pass + 1)
        printf 'ok   %s\n' "$name"
    else
        set -g _fail (math $_fail + 1)
        printf 'FAIL %s (expected status %d, got %d)\n' "$name" $expected $st
    end
end

# --- simple commands ----------------------------------------------------
check echo hello 'echo hello'
check variable bar 'FOO=bar; echo $FOO'
set -l eu (string join \n 'bar' '[def]' | string collect)
check 'export+unset' "$eu" 'export FOO=bar; echo $FOO; unset FOO; echo "[${FOO:-def}]"'
check 'flag assignment' 'FOO=bar' 'FOO=bar env | grep "^FOO="'

# --- control structures -------------------------------------------------
check if yes 'if [ 1 -eq 1 ]; then echo yes; fi'
check if/else no 'if [ 1 -eq 2 ]; then echo yes; else echo no; fi'
check elif b 'if false; then echo a; elif true; then echo b; else echo c; fi'
check while 3 'n=0; while [ $n -lt 3 ]; do n=$((n+1)); done; echo $n'
check until 2 'i=0; until [ $i -ge 2 ]; do i=$((i+1)); done; echo $i'
set -l fore (string join \n a b c | string collect)
check for "$fore" 'for f in a b c; do echo $f; done'
check case OK 'case x in x) echo OK;; *) echo BAD;; esac'
check 'case alt' BY 'case y in x) echo A;; y|z) echo BY;; *) echo C;; esac'
check 'case glob' match 'case abc in a*) echo match;; *) echo no;; esac'

# --- arithmetic and expansions -----------------------------------------
check arith 14 'echo $((2+3*4))'
check 'arith div/mod' '3 1' 'echo $((10/3)) $((10%3))'
check 'arith in test' ok 'if [ $((1+1)) -eq 2 ]; then echo ok; fi'
check '# prefix' llo 'v=hello; echo ${v#he}'
check '% suffix' hel 'v=hello; echo ${v%lo}'
check '## / %%' 'world hello' 'v=hello/world; echo ${v##*/} ${v%/*}'
check length 3 'v=abc; echo ${#v}'
check default '[def]' 'v=; echo "[${v:-def}]"'
check alternative x 'v=abc; echo ${v:+x}'

# --- substitutions ------------------------------------------------------
check 'substitution $()' nested 'echo $(echo nested)'
check backquote nested 'echo `echo nested`'
check nested deep 'echo $(echo $(echo deep))'
check 'status $?' 1 'false; echo $?'

# --- functions and scope ------------------------------------------------
check function 'in hello' 'f() { echo in "$1"; }; f hello'
set -l lpe (string join \n 1 '[empty]' | string collect)
check 'local scope' "$lpe" 'f() { local x=1; echo $x; }; f; echo "[${x:-empty}]"'

# --- subshells and pipes ------------------------------------------------
check subshell sub '(echo sub)'
check 'subshell pipe' x '(echo x) | cat'
check 'pipe wc' 2 "printf 'a\\nb\\n' | wc -l | tr -d ' '"
check 'logic && ||' OK 'false || true && echo OK || echo KO'
check_status 'negation !' 1 '! true'

# --- here-documents -----------------------------------------------------
set -l hd1 (string join \n 'g=you; cat <<EOF' 'Hello $g' 'EOF' | string collect)
check heredoc 'Hello you' "$hd1"
set -l hd2 (string join \n 'cat <<EOF' 'val: $(echo fixed)' 'EOF' | string collect)
check 'heredoc csub' 'val: fixed' "$hd2"
set -l hd3 (string join \n "g=you; cat <<'EOF'" 'Hello $g' 'EOF' | string collect)
check 'heredoc quote' 'Hello $g' "$hd3"
set -l hd4 (string join \n 'cat <<EOF' '# some text' 'EOF' | string collect)
check 'heredoc comment' '# some text' "$hd4"
set -l tabcode (printf 'cat <<-EOF\n\tbody\n\tEOF' | string collect)
check 'heredoc tab' body "$tabcode"

# --- arguments and keywords --------------------------------------------
check arg0 myscript 'echo $0' myscript
check arg1 second 'echo $1' myscript second
set -l sh1 (string join \n a b | string collect)
check shift "$sh1" 'echo $1; shift; echo $1' myscript a b
check 'arg count' 2 'echo $#' myscript a b
check 'exit status' inside 'echo inside; exit 0'
check_status 'exit code' 3 'echo x; exit 3'
check_status 'command status' 127 nosuchcmd_posixfish

# --- traps --------------------------------------------------------------
set -l t1 (string join \n body bye | string collect)
check 'trap EXIT' "$t1" "trap 'echo bye' EXIT; echo body"
check_status 'trap EXIT code' 4 'trap "true" EXIT; exit 4'

# --- getopts ------------------------------------------------------------
set -l go1 (string join \n A B | string collect)
check getopts "$go1" 'while getopts ab o; do case $o in a) echo A;; b) echo B;; *) echo X;; esac; done' script -a -b
check 'getopts arg' val 'while getopts a: o; do case $o in a) echo "$OPTARG";; esac; done' script -aval

# --- stdin / script file ------------------------------------------------
set -l stdinout (echo 'echo from-stdin' | sh | string collect)
if test "$stdinout" = from-stdin
    set -g _pass (math $_pass + 1)
    printf 'ok   %s\n' stdin
else
    set -g _fail (math $_fail + 1)
    printf 'FAIL %s (%s)\n' stdin (string escape -- "$stdinout")
end

set -l script /tmp/opencode/posix-fish-test-$fish_pid.sh
printf 'echo "script $1 $2"\n' >$script
set -l fileout (sh $script one two | string collect)
if test "$fileout" = 'script one two'
    set -g _pass (math $_pass + 1)
    printf 'ok   %s\n' 'script+args'
else
    set -g _fail (math $_fail + 1)
    printf 'FAIL %s (%s)\n' 'script+args' (string escape -- "$fileout")
end
rm -f $script

# --- summary ------------------------------------------------------------
printf '\n%d ok, %d failure(s)\n' $_pass $_fail
test $_fail -eq 0
