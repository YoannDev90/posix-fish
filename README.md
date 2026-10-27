# posix-fish

A **POSIX compatibility** layer for [fish](https://fishshell.com).

This plugin provides an `sh` command that runs POSIX code (a script or a code
snippet) **by delegating to `bash`**, then forwards stdout, stderr, and the exit
status as-is. The goal: full POSIX coverage from bash, with nothing
reimplemented in fish.

> **How it works** : instead of translating `sh` into `fish` (complex and
> error-prone), `sh` hands the code over to bash — the reference POSIX shell —
> and relays the result. Compatibility is therefore optimal, for zero effort.

## Installation

With [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install YoannDev90/posix-fish
```

This installs `functions/sh.fish`. Since fish autoloads functions before
external commands, `sh` shadows `/bin/sh` in fish sessions; use `command sh` or
`command bash` to call the system shell directly.

## Usage

```fish
sh -c 'echo $((1+2))'        # code on the command line
sh script.sh arg1 arg2       # script + arguments ($0, $1, $#…)
echo 'echo hi' | sh          # from stdin
sh 'echo hi'                 # shortcut: code passed as-is
command sh -c 'echo hi'      # system shell, without the layer
```

In every case, `sh` simply hands off to `bash` (with the same arguments) and
propagates stdout / stderr / exit status.

## How it works

`sh` only inspects how it was called (`-c`, file, stdin, shortcut) and then runs
`command bash …`. There is **no translation**: bash interprets the POSIX source
directly.

Consequences:

- **Coverage**: everything bash supports (`case` with classes/`?`, `set --`,
  `$(…)`, `<<<`, arrays, subshells with directory scoping, `exit` inside a
  function, …) works out of the box.
- **Scope**: bash is a superset of POSIX, so it also accepts some bashisms. If
  you need strict POSIX, use `bash --posix` via `command bash --posix …`.
- **Isolation**: the script runs in a child process; its variables do not leak
  back into the fish session (normal behavior, same as `sh -c`).

## Tests

```fish
fish tests/run.fish
```

Expected output: `51 ok, 0 failure(s)`.

## License

[MIT](LICENSE).
