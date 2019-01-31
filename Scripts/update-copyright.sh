#!/bin/bash

set -euo pipefail
SCRIPT_NAME=$(basename $0)

# Arg1: OLD_YEAR
# Arg2: NEW_YEAR
# Arg3: File Path
replace_copyright() {
	sed -i '' -e "s|Copyright (c) 2010-${1}, Deusty, LLC|Copyright (c) 2010-${2}, Deusty, LLC|g" "$3"
	return $?
}

current_year() {
	date '+%Y'
	return $?
}

last_year() {
	date -v'-1y' '+%Y'
	return $?
}

# Arg1: Mode (full, usage_only). Defaults to 'full'.
print_usage() {
	echo "Usage: ${SCRIPT_NAME} [OLD_YEAR NEW_YEAR]"
	if [[ "${1:-full}" == "full" ]]; then
		echo ""
		echo "If called with OLD_YEAR and NEW_YEAR arguments, updates the copyright years from OLD_YEAR to NEW_YEAR."
		echo "If called with no arguments but OLD_YEAR and NEW_YEAR environment variables defined, updates from OLD_YEAR to NEW_YEAR."
		echo "If called with no arguments and OLD_YEAR and NEW_YEAR not being defined, updates from last year to the current year."
		echo ""
		echo "Examples:"
		echo "$ ${SCRIPT_NAME} 2016 2017                       # Updates from 2016 to 2017."
		echo "$ OLD_YEAR=2017 NEW_YEAR=2018 ${SCRIPT_NAME}     # Updates from 2017 to 2018."
		echo "$ ${SCRIPT_NAME}                                 # Updates from $(last_year) to $(current_year)."
	fi
}

OLD_YEAR=${OLD_YEAR:-$(last_year)}
NEW_YEAR=${NEW_YEAR:-$(current_year)}
if [[ $# -gt 0 ]]; then
	if [[ $# -eq 2 ]]; then
		OLD_YEAR="$1"
		NEW_YEAR="$2"
	elif [[ $# -eq 1 ]] && [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
		print_usage 'full'
		exit 0
	else
		echo "Specifying years via command line arguments requires two arguments (OLD_YEAR and NEW_YEAR)!"
		echo "For more information use --help."
		echo ""
		print_usage 'usage_only'
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
