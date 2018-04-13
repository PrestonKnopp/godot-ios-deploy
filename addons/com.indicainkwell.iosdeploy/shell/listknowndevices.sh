# redir stderr to dev/null because I'm getting CoreData error from
# instruments
instruments -s devices 2>/dev/null | sed '1d'
