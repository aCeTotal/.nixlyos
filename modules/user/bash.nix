{ ... }:

{
    # Bash
    programs = {
        bash = {
            enable = true;
            enableCompletion = true;

            shellAliases = {
                "z" = "zoxide";
            };

            # push: git add -A, prompt for commit message, commit + push
            initExtra = ''
                push() {
                    local msg
                    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                        echo "push: not a git repo" >&2
                        return 1
                    fi
                    git add -A
                    if git diff --cached --quiet; then
                        echo "push: nothing new to commit, pushing existing commits"
                        git push
                        return
                    fi
                    read -rep "commit> " msg || return 1
                    if [ -z "$msg" ]; then
                        echo "push: empty message, aborted" >&2
                        git reset -q
                        return 1
                    fi
                    git commit -m "$msg" && git push
                }

                # hash: print fetchFromGitHub fields (owner/repo/rev/hash)
                # for the repo's pushed HEAD, ready to paste into a derivation
                hash() {
                    local url owner_repo rev sha sri
                    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                        echo "hash: not a git repo" >&2
                        return 1
                    fi
                    url=$(git remote get-url origin 2>/dev/null)
                    if [ -z "$url" ]; then
                        echo "hash: no origin remote" >&2
                        return 1
                    fi
                    owner_repo=''${url#git@github.com:}
                    owner_repo=''${owner_repo#https://github.com/}
                    owner_repo=''${owner_repo%.git}
                    rev=$(git rev-parse HEAD)
                    if [ "$(git rev-parse @{u} 2>/dev/null)" != "$rev" ]; then
                        echo "hash: warning — HEAD differs from upstream, run push first" >&2
                    fi
                    echo "prefetching $owner_repo @ ''${rev:0:7} ..." >&2
                    sha=$(nix-prefetch-url --unpack \
                        "https://github.com/$owner_repo/archive/$rev.tar.gz" 2>/dev/null)
                    if [ -z "$sha" ]; then
                        echo "hash: prefetch failed (is $rev pushed to github?)" >&2
                        return 1
                    fi
                    sri=$(nix hash convert --hash-algo sha256 --to sri "$sha" 2>/dev/null \
                        || nix hash to-sri --type sha256 "$sha")
                    echo "owner = \"''${owner_repo%%/*}\";"
                    echo "repo = \"''${owner_repo##*/}\";"
                    echo "rev = \"$rev\";"
                    echo "hash = \"$sri\";"
                }
            '';
        };
        direnv = {
            enable = true;
            nix-direnv.enable = true;
        };
    };
}
