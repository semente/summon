# summon &ndash; assemble user config files (aka dotfiles)

If you manage dozens of *dotfiles* in a Git repository **summon** can help you
to setup them using the Unix-like systems symbolic link capability.

If you are a [GNU Stow](https://www.gnu.org/software/stow/) user, this tool is
for you! It shares basically the same concept with the key difference of not
setting up links to directories to avoid non-tracked files inside it pollute
your Git repository.

Although not tested on BSDs, Mac OS X, cygnus and the like, it should work fine
in any machine with *GNU coreutils, findutils, diffutils and bash*
installed. Feel free to send pull requests to increase compatibility and ease of
deploy in systems other than GNU/Linux.

## Usage

To run `summon` you must have the following software installed on your machine:

  - Bash
  - GNU coreutils (`dirname`, `ln`)
  - GNU findutils (`find`)
  - GNU diffutils (`cmp`)
  - GNU sed (`sed`)

### Synopsis

```sh
summon [OPTION]... TARGET...
```

### Description

Creates links into your $HOME directory to the files inside TARGET.

### Usage examples

Considering a TARGET directory contained the following *dotfiles*:

```
TARGET
├── bin
│   └── .local
│       └── bin
│           ├── bandana
│           └── knife
├── emacs
│   ├── .emacs.d
│   │   └── custom.el
│   └── .init.el
├── git
│   ├── .config
│   │   └── git
│   │       └── gitk
│   └── .gitconfig
└── tmux
    └── .tmux.conf
```

Running the command `summon TARGET/{bin,emacs,git,tmux}` or `summon TARGET/*`
will result on this setup:

```
$HOME
├── .config
│   └── git
│       └── gitk -> TARGET/git/.config/git/gitk
├── .emacs.d
│   └── custom.el -> TARGET/emacs/.emacs.d/custom.el
├── .gitconfig -> TARGET/git/.gitconfig
├── .init.el -> TARGET/emacs/.init.el
├── .local
│   └── bin
│       ├── bandana -> TARGET/bin/.local/bin/bandana
│       └── knife -> TARGET/bin/.local/bin/knife
└── .tmux.conf -> TARGET/tmux/.tmux.conf
 ```

(By default *summon* backup any existing file on the destination link path by
renaming it adding a numbered `~` suffix.)


You may sort your dotfiles the way you wish. Some people has different setup
from different hosts:

```
.
├── common
│   └── vim
│       └── .vimrc
├── laptop
│   └── tmux
│       └── .tmux.conf
├── remote
│   └── tmux
│       └── .tmux.conf
└── somehost
    └── vim
        └── .vimrc
```

**Using hard instead symbolic links**

Some software may not work well with *symlinks*. You can switch to hard links
using the argument `-H`:

```sh
$ summon -H ~/dotfiles/bash ~/dotfiles/screen
```

#### All options

```
  -H                      make hard links instead of symbolic links
  -b BACKUP-METHOD        choose between numbered (default), simple or off
  -v                      verbose (i.e. give more information during processing)
  -d                      print commands as they are executed (for debug)
  -V                      print version number
  -h                      show this help text
```

# Testing

Summon use the command line tester tool
[clitest](https://github.com/aureliojargas/clitest) to perform automatic
testing.

Once `clitest` is installed in your system, just run following
commmand:

```sh
$ clitest test.txt
```
