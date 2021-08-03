# URL Tools
# Adds handy command line aliases useful for dealing with URLs
#
# Taken from:
# http://ruslanspivak.com/2010/06/02/urlencode-and-urldecode-from-a-command-line/

if [[ $(whence $URLTOOLS_METHOD) = "" ]]; then
    URLTOOLS_METHOD=""
fi

if [[ $(whence python3) != "" && ( "x$URLTOOLS_METHOD" = "x" || "x$URLTOOLS_METHOD" = "xpython" ) ]]; then
    alias urlencode='python3 -c "import sys, urllib.parse as up; print(up.quote_plus(\" \".join(sys.argv[1:])))"'
    alias urldecode='python3 -c "import sys, urllib.parse as up; print(up.unquote_plus(\" \".join(sys.argv[1:])))"'
fi

unset URLTOOLS_METHOD
