# local command=$(sd '(.+?):(.+?)$' '"$1" $2' | xargs $ASH_RIPGREP --smart-case --fixed-strings --no-heading --column --with-filename --max-count=1 --color=never | tabulate -d ':' -i 1,2,3 | sd '(.+?)\s+(\d+)\s+(\d+)' '$1:$2:$3')
# local position=$(echo "$command" | grep -Po '(\d+:\d+)$')
# local filename=$(echo "$command" | sd '(:\d+:\d+)$' '')
# micro $filename $position

# local command=$(sd '(.+?):(.+?)$' '"$1" $2' | xargs $ASH_RIPGREP --smart-case --fixed-strings --no-heading --column --with-filename --max-count=1 --color=never | tabulate -d ':' -i 1,2,3 | sd '(.+?)\s+(\d+)\s+(\d+)' '$1 +$2:$3')
# echo $command | tabulate | xargs micro

sd '(.+?):(.+?)$' '"$1" $2' | xargs $ASH_RIPGREP --smart-case --fixed-strings --no-heading --column --with-filename --max-count=1 --color=never | tabulate -d ':' -i 1,2,3 | sd '(.+?)\s+(\d+)\s+(\d+)' 'micro $1 +$2:$3' | $SHELL
