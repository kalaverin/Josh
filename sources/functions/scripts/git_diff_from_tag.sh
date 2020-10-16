grep -P '(?<=tag: )(.+?)(?=,|\))' -o | head -1 | xargs -I% git show-ref refs/tags/% | cut -d ' ' -f 1 | xargs -I% git diff --diff-algorithm=histogram %
