random()
# usage: random [range] [digits]
# description: gen random number
{
    tr -dc ${1:-1-9} < /dev/urandom | head -c${2:-4}
}
