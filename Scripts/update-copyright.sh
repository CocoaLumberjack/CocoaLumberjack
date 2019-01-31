#!/bin/bash

set -euo pipefail

# Arg1: OLD_YEAR
# Arg2: NEW_YEAR
# Arg3: File Path
replace_copyright() {
	sed -i '' -e "s|Copyright (c) 2010-${1}, Deusty, LLC|Copyright (c) 2010-${2}, Deusty, LLC|g" "$3"
	return $?
}

OLD_YEAR=${OLD_YEAR:-$(date -v'-1y' '+%Y')}
NEW_YEAR=${NEW_YEAR:-$(date '+%Y')}
if [[ $# -gt 0 ]]; then
	if [[ $# -eq 2 ]]; then
		OLD_YEAR="$1"
		NEW_YEAR="$2"
	else
		echo "Specifying years via command line arguments requires two arguments (OLD_YEAR and NEW_YEAR)!"
		echo "Alternatively, the script uses environment variables with above's name or (if unset) the last and current year."
		echo ""
		echo "Usage: $(basename $0) [OLD_YEAR NEW_YEAR]"
		exit -1
	fi
fi

# We need to export the function so that bash can call it from the find exec argument.
export -f replace_copyright

pushd "$(dirname $0)/../" > /dev/null
find -E . -regex ".*\.([hm]|swift|pch)" -exec bash -c "replace_copyright \"${OLD_YEAR}\" \"${NEW_YEAR}\" \"{}\"" \;
replace_copyright "${OLD_YEAR}" "${NEW_YEAR}" "./LICENSE"
replace_copyright "${OLD_YEAR}" "${NEW_YEAR}" "./Dangerfile"
popd > /dev/null

# Delete the function again
unset -f replace_copyright
