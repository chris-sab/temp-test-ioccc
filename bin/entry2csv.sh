#!/usr/bin/env bash
#
# entry2csv.sh - convert .entry.json data into CSV files
#
# We generate CSV files from the `.entry.json` files from winning
# IOCCC entries listed under years listed in the `.top` file,
# and in sub-directories listed in the `YYYY/.year` file for the
# given year.  Only those entries so listed are processed.
#
# All IOCCC entry directories must have a `.path` file that lists
# the path of the entry's directory from the TOPDIR.
#
# NOTE: When adding a new IOCCC years entries, the `.top` file MUST
#	be updated, and the new IOCCC year `YYYY/.year` files MUST
#	reference the directory of the new IOCCC entries.  They
#	must also contain a `.path` file that contains the path
#	of the IOCCC entry directory from the TOPDIR.
#
# NOTE: All IOCCC entries MUST have a valid `.entry.json` file.
#
# Copyright (c) 2024 by Landon Curt Noll.  All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright, this permission notice and text
# this comment, and the disclaimer below appear in all of the following:
#
#       supporting documentation
#       source copies
#       source works derived from this source
#       binaries derived from this source or from derived source
#
# LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
# EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# chongo (Landon Curt Noll, http://www.isthe.com/chongo/index.html) /\oo/\
#
# Share and enjoy! :-)

# firewall - run only with a bash that is version 5.1.8 or later
#
# The "/usr/bin/env bash" command must result in using a bash that
# is version 5.1.8 or later.
#
# We could relax this version and insist on version 4.2 or later.  Versions
# of bash between 4.2 and 5.1.7 might work.  However, to be safe, we will require
# bash version 5.1.8 or later.
#
# WHY 5.1.8 and not 4.2?  This safely is done because macOS Homebrew bash we
# often use is "version 5.2.26(1)-release" or later, and the RHEL Linux bash we
# use often use is "version 5.1.8(1)-release" or later.  These versions are what
# we initially tested.  We recommend you either upgrade bash or install a newer
# version of bash and adjust your $PATH so that "/usr/bin/env bash" finds a bash
# that is version 5.1.8 or later.
#
# NOTE: The macOS shipped, as of 2024 March 15, a version of bash is something like
#	bash "version 3.2.57(1)-release".  That macOS shipped version of bash
#	will NOT work.  For users of macOS we recommend you install Homebrew,
#	(see https://brew.sh), and then run "brew install bash" which will
#	typically install it into /opt/homebrew/bin/bash, and then arrange your $PATH
#	so that "/usr/bin/env bash" finds "/opt/homebrew/bin" (or whatever the
#	Homebrew bash is).
#
# NOTE: And while MacPorts might work, we noticed a number of subtle differences
#	with some of their ported tools to suggest you might be better off
#	with installing Homebrew (see https://brew.sh).  No disrespect is intended
#	to the MacPorts team as they do a commendable job.  Nevertheless we ran
#	into enough differences with MacPorts environments to suggest you
#	might find a better experience with this tool under Homebrew instead.
#
if [[ -z ${BASH_VERSINFO[0]} ||
	 ${BASH_VERSINFO[0]} -lt 5 ||
	 ${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -lt 1 ||
	 ${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -eq 1 && ${BASH_VERSINFO[2]} -lt 8 ]]; then
    echo "$0: ERROR: bash version needs to be >= 5.1.8: $BASH_VERSION" 1>&2
    echo "$0: Warning: bash version >= 4.2 might work but 5.1.8 was the minimum we tested" 1>&2
    echo "$0: Notice: For macOS users: install Homebrew (see https://brew.sh), then run" \
	 ""brew install bash" and then modify your \$PATH so that \"#!/usr/bin/env bash\"" \
	 "finds the Homebrew installed (usually /opt/homebrew/bin/bash) version of bash" 1>&2
    exit 4
fi


# setup bash file matching
#
# We must declare arrays with -ag or -Ag, and we need loops to "export" modified variables.
# This requires a bash with a version 4.2 or later.  See the larger comment above about bash versions.
#
shopt -s nullglob	# enable expanded to nothing rather than remaining unexpanded
shopt -u failglob	# disable error message if no matches are found
shopt -u dotglob	# disable matching files starting with .
shopt -u nocaseglob	# disable strict case matching
shopt -u extglob	# enable extended globbing patterns
shopt -s globstar	# enable ** to match all files and zero or more directories and subdirectories

# set variables referenced in the usage message
#
export VERSION="1.0.1 2024-07-14"
NAME=$(basename "$0")
export NAME
export V_FLAG=0
GIT_TOOL=$(type -P git)
export GIT_TOOL
if [[ -z "$GIT_TOOL" ]]; then
    echo "$0: FATAL: git tool is not installed or not in \$PATH" 1>&2
    exit 5
fi
"$GIT_TOOL" rev-parse --is-inside-work-tree >/dev/null 2>&1
status="$?"
if [[ $status -eq 0 ]]; then
    TOPDIR=$("$GIT_TOOL" rev-parse --show-toplevel)
fi
export TOPDIR
#
export NOOP=
export DO_NOT_PROCESS=
export EXIT_CODE="0"
#
JPARSE_TOOL=$(type -P jparse)
export JPARSE_TOOL
export AUTHOR_WINS_CSV="author_wins.csv"
export MANIFEST_CSV="manifest.csv"
export YEAR_PRIZE_CSV="year_prize.csv"


# output_award
#
# Write the award name to standard output (stdout)
#
# XXX - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XXX
# XXX - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - XXX
# XXX - until we have the jnamval command, we must FAKE PARSE the .entry.json file  - XXX
# XXX - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - XXX
# XXX - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XXX
#
# usage:
#       output_award YYYY/dir/.entry.json
#
# returns:
#       0 ==> no errors detected, but output may be empty
#     > 0 ==> function error number
#
function output_award
{
    local ENTRY_JSON_PATH;	# the .entry.json path
    local AWARD_STRING;		# winning entry award string

    # parse args
    #
    if [[ $# -ne 1 ]]; then
        echo "$0: ERROR: in output_award: expected 1 arg, found $#" 1>&2
        return 1
    fi
    ENTRY_JSON_PATH="$1"
    if [[ ! -e $ENTRY_JSON_PATH ]]; then
        echo "$0: ERROR: in output_award: .entry.json does not exist: $ENTRY_JSON_PATH" 1>&2
        return 2
    fi
    if [[ ! -f $ENTRY_JSON_PATH ]]; then
        echo "$0: ERROR: in output_award: .entry.json is not a file: $ENTRY_JSON_PATH" 1>&2
        return 3
    fi
    if [[ ! -r $ENTRY_JSON_PATH ]]; then
        echo "$0: ERROR: in output_award: .entry.json is not a readable file: $ENTRY_JSON_PATH" 1>&2
        return 4
    fi

    # obtain the award string
    #
    AWARD_STRING=$(grep -F '"award" : "'  "$ENTRY_JSON_PATH" | sed -e 's/^.*"award" : "//' -e 's/",//')
    if [[ -z $AWARD_STRING ]]; then
	echo "$0: ERROR: in output_award: no award found in .entry.json file: $ENTRY_JSON_PATH" 1>&2
	return 5
    fi
    echo "$AWARD_STRING"
    return 0
}


# output_author_handles
#
# Write the author handle(s) for the YYYY/dir entry to standard output (stdout)
#
# XXX - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XXX
# XXX - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - XXX
# XXX - until we have the jnamval command, we must FAKE PARSE the .entry.json file  - XXX
# XXX - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - GROSS HACK - XXX
# XXX - XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XXX
#
# usage:
#	output_author_handles YYYY/dir/.entry.json
#
# returns:
#	0 ==> no errors detected, but output may be empty
#     > 0 ==> function error number
#
function output_author_handles
{
    local ENTRY_JSON_PATH;	# the .entry.json path
    local author_handle;	# a found author handle

    # parse args
    #
    if [[ $# -ne 1 ]]; then
	echo "$0: ERROR: in output_author_handles: expected 1 arg, found $#" 1>&2
	return 1
    fi
    ENTRY_JSON_PATH="$1"
    if [[ ! -e $ENTRY_JSON_PATH ]]; then
	echo "$0: ERROR: in output_author_handles: .entry.json does not exist: $ENTRY_JSON_PATH" 1>&2
	return 2
    fi
    if [[ ! -f $ENTRY_JSON_PATH ]]; then
	echo "$0: ERROR: in output_author_handles: .entry.json is not a file: $ENTRY_JSON_PATH" 1>&2
	return 3
    fi
    if [[ ! -r $ENTRY_JSON_PATH ]]; then
	echo "$0: ERROR: in output_author_handles: .entry.json is not a readable file: $ENTRY_JSON_PATH" 1>&2
	return 4
    fi

    # extract author handles from .entry.json
    #
    grep -F author_handle "$ENTRY_JSON_PATH" |
      awk 'NF == 5 { print $4; }' |
      tr -d '"' |
      while read -r author_handle; do
	echo "$author_handle"
    done
    return 0
}


# usage
#
export USAGE="usage: $0 [-h] [-v level] [-V] [-d topdir] [-n] [-N] [-j jparse]
			[author_wins.csv [manifest.csv [year_prize.csv]]]

	-h		print help message and exit
	-v level	set verbosity level (def level: 0)
	-V		print version string and exit

	-d topdir	set topdir (def: $TOPDIR)

	-n		go thru the actions, but do not update any files (def: do the action)
	-N		do not process anything, just parse arguments (def: process something)

	-j jparse	path to the jparse tool (def: $JPARSE_TOOL)

	author_wins.csv	where to form author_wins.csv (def: $AUTHOR_WINS_CSV)
	manifest.csv	where to form manifest.csv (def: $MANIFEST_CSV)
	year_prize.csv	where to form year_prize.csv (def: $YEAR_PRIZE_CSV)

Exit codes:
     0         all OK
     1	       invalid or missing .entry.json file
     2         -h and help string printed or -V and version string printed
     3         command line error
     4         bash version is too old
     5	       some internal tool is not found or not an executable file
     6	       problems found with or in the topdir or topdir/YYYY directory
     7	       problems found with or in the entry topdir/YYYY/dir directory
     8         unable to write a CSV or temporary file
 >= 10         internal error

$NAME version: $VERSION"

# parse command line
#
while getopts :hv:Vd:D:nNj: flag; do
  case "$flag" in
    h) echo "$USAGE" 1>&2
	exit 2
	;;
    v) V_FLAG="$OPTARG"
	;;
    V) echo "$VERSION"
	exit 2
	;;
    d) TOPDIR="$OPTARG"
	;;
    n) NOOP="-n"
	;;
    N) DO_NOT_PROCESS="-N"
	;;
    j) JPARSE_TOOL="$OPTARG"
	;;
    \?) echo "$0: ERROR: invalid option: -$OPTARG" 1>&2
	echo 1>&2
	print_usage 1>&2
	exit 3
	;;
    :) echo "$0: ERROR: option -$OPTARG requires an argument" 1>&2
	echo 1>&2
	echo "$USAGE" 1>&2
	exit 3
	;;
    *) echo "$0: ERROR: unexpected value from getopts: $flag" 1>&2
	echo 1>&2
	echo "$USAGE" 1>&2
	exit 3
	;;
  esac
done

# remove the options
#
shift $(( OPTIND - 1 ));
#
if [[ $V_FLAG -ge 5 ]]; then
    echo "$0: debug[5]: file argument count: $#" 1>&2
fi
case "$#" in
0) ;;
1) AUTHOR_WINS_CSV="$1" ;;
2) AUTHOR_WINS_CSV="$1" ; MANIFEST_CSV="$2" ;;
3) AUTHOR_WINS_CSV="$1" ; MANIFEST_CSV="$2" ; YEAR_PRIZE_CSV="$3" ;;
*) echo "$0: expected 0, 1, 2 or 3 args, found #$" 1>&2
   echo 1>*2
   echo  "$USAGE" 1>&2
   exit 3
   ;;
esac

# if CSV files exist, verify that they are in a writable directory
#
if [[ -z $AUTHOR_WINS_CSV ]]; then
    echo "$0: ERROR: AUTHOR_WINS_CSV is empty" 1>&2
    exit 8
fi
AUTHOR_WINS_CSV_DIR=$(dirname "$AUTHOR_WINS_CSV")
export AUTHOR_WINS_CSV_DIR
if [[ ! -w $AUTHOR_WINS_CSV_DIR ]]; then
    echo "$0: ERROR: AUTHOR_WINS_CSV file: $AUTHOR_WINS_CSV in a non-writable directory: $AUTHOR_WINS_CSV_DIR" 1>&2
    exit 8
fi
#
if [[ -z $AUTHOR_WINS_CSV ]]; then
    echo "$0: ERROR: AUTHOR_WINS_CSV is empty" 1>&2
    exit 8
fi
MANIFEST_WINS_CSV_DIR=$(dirname "$MANIFEST_CSV")
export MANIFEST_WINS_CSV_DIR
if [[ ! -w $MANIFEST_WINS_CSV_DIR ]]; then
    echo "$0: ERROR: AUTHOR_WINS_CSV file: $MANIFEST_CSV in a non-writable directory: $MANIFEST_WINS_CSV_DIR" 1>&2
    exit 8
fi
#
if [[ -z $YEAR_PRIZE_CSV ]]; then
    echo "$0: ERROR: YEAR_PRIZE_CSV is empty" 1>&2
    exit 8
fi
YEAR_PRIZE_CSV_DIR=$(dirname "$YEAR_PRIZE_CSV")
export YEAR_PRIZE_CSV_DIR
if [[ ! -w $YEAR_PRIZE_CSV_DIR ]]; then
    echo "$0: ERROR: YEAR_PRIZE_CSV file: $YEAR_PRIZE_CSV in a non-writable directory: $YEAR_PRIZE_CSV_DIR" 1>&2
    exit 8
fi

# verify that we have a topdir directory
#
if [[ -z $TOPDIR ]]; then
    echo "$0: ERROR: cannot find top of git repo directory" 1>&2
    exit 6
fi
if [[ ! -e $TOPDIR ]]; then
    echo "$0: ERROR: TOPDIR does not exist: $TOPDIR" 1>&2
    exit 6
fi
if [[ ! -d $TOPDIR ]]; then
    echo "$0: ERROR: TOPDIR is not a directory: $TOPDIR" 1>&2
    exit 6
fi

# cd to topdir
#
if [[ ! -e $TOPDIR ]]; then
    echo "$0: ERROR: cannot cd to non-existent path: $TOPDIR" 1>&2
    exit 6
fi
if [[ ! -d $TOPDIR ]]; then
    echo "$0: ERROR: cannot cd to a non-directory: $TOPDIR" 1>&2
    exit 6
fi
export CD_FAILED
if [[ $V_FLAG -ge 5 ]]; then
    echo "$0: debug[5]: about to: cd $TOPDIR" 1>&2
fi
cd "$TOPDIR" || CD_FAILED="true"
if [[ -n $CD_FAILED ]]; then
    echo "$0: ERROR: cd $TOPDIR failed" 1>&2
    exit 6
fi
if [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: now in directory: $(/bin/pwd)" 1>&2
fi

# verify we have a non-empty readable .top file
#
export TOP_FILE=".top"
if [[ ! -e $TOP_FILE ]]; then
    echo  "$0: ERROR: .top does not exist: $TOP_FILE" 1>&2
    exit 6
fi
if [[ ! -f $TOP_FILE ]]; then
    echo  "$0: ERROR: .top is not a regular file: $TOP_FILE" 1>&2
    exit 6
fi
if [[ ! -r $TOP_FILE ]]; then
    echo  "$0: ERROR: .top is not an readable file: $TOP_FILE" 1>&2
    exit 6
fi
if [[ ! -s $TOP_FILE ]]; then
    echo  "$0: ERROR: .top is not a non-empty readable file: $TOP_FILE" 1>&2
    exit 6
fi

# verify that we have a bin subdirectory
#
export BIN_PATH="$TOPDIR/bin"
if [[ ! -d $BIN_PATH ]]; then
    echo "$0: ERROR: bin is not a directory under topdir: $BIN_PATH" 1>&2
    exit 6
fi
export BIN_DIR="bin"

# verify we have our awk script
#
export MANIFEST_ENTRY_CSV_ENTRY_AWK="$BIN_DIR/manifest.csv.entry.awk"
if [[ ! -e $MANIFEST_ENTRY_CSV_ENTRY_AWK ]]; then
    echo "$0: ERROR: bin/manifest.csv.entry.awk does not exist: $MANIFEST_ENTRY_CSV_ENTRY_AWK" 1>&2
    exit 6
fi
if [[ ! -f $MANIFEST_ENTRY_CSV_ENTRY_AWK ]]; then
    echo "$0: ERROR: bin/manifest.csv.entry.awk is not a regular file: $MANIFEST_ENTRY_CSV_ENTRY_AWK" 1>&2
    exit 6
fi
if [[ ! -r $MANIFEST_ENTRY_CSV_ENTRY_AWK ]]; then
    echo "$0: ERROR: bin/manifest.csv.entry.awk is not a readable file: $MANIFEST_ENTRY_CSV_ENTRY_AWK" 1>&2
    exit 6
fi

# verify jparse tool
#
if [[ -z "$JPARSE_TOOL" ]]; then
    echo "$0: ERROR: cannot find an executable jparse tool" 1>&2
    exit 5
fi
if [[ ! -f "$JPARSE_TOOL" ]]; then
    echo "$0: ERROR: jparse is not a file: $JPARSE_TOOL" 1>&2
    exit 5
fi
if [[ ! -x "$JPARSE_TOOL" ]]; then
    echo "$0: ERROR: jparse is not an executable file: $JPARSE_TOOL" 1>&2
    exit 5
fi

# print running info if verbose
#
# If -v 3 or higher, print exported variables in order that they were exported.
#
if [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: VERSION=$VERSION" 1>&2
    echo "$0: debug[3]: NAME=$NAME" 1>&2
    echo "$0: debug[3]: V_FLAG=$V_FLAG" 1>&2
    echo "$0: debug[3]: GIT_TOOL=$GIT_TOOL" 1>&2
    echo "$0: debug[3]: TOPDIR=$TOPDIR" 1>&2
    echo "$0: debug[3]: NOOP=$NOOP" 1>&2
    echo "$0: debug[3]: DO_NOT_PROCESS=$DO_NOT_PROCESS" 1>&2
    echo "$0: debug[3]: EXIT_CODE=$EXIT_CODE" 1>&2
    echo "$0: debug[3]: JPARSE_TOOL=$JPARSE_TOOL" 1>&2
    echo "$0: debug[3]: AUTHOR_WINS_CSV=$AUTHOR_WINS_CSV" 1>&2
    echo "$0: debug[3]: MANIFEST_CSV=$MANIFEST_CSV" 1>&2
    echo "$0: debug[3]: YEAR_PRIZE_CSV=$YEAR_PRIZE_CSV" 1>&2
    echo "$0: debug[3]: AUTHOR_WINS_CSV_DIR=$AUTHOR_WINS_CSV_DIR" 1>&2
    echo "$0: debug[3]: MANIFEST_WINS_CSV_DIR=$MANIFEST_WINS_CSV_DIR" 1>&2
    echo "$0: debug[3]: YEAR_PRIZE_CSV_DIR=$YEAR_PRIZE_CSV_DIR" 1>&2
    echo "$0: debug[3]: CD_FAILED=$CD_FAILED" 1>&2
    echo "$0: debug[3]: TOP_FILE=$TOP_FILE" 1>&2
    echo "$0: debug[3]: BIN_PATH=$BIN_DIR" 1>&2
    echo "$0: debug[3]: BIN_DIR=$BIN_DIR" 1>&2
    echo "$0: debug[3]: MANIFEST_ENTRY_CSV_ENTRY_AWK=$MANIFEST_ENTRY_CSV_ENTRY_AWK" 1>&2
fi

# -N stops early before any processing is performed
#
if [[ -n $DO_NOT_PROCESS ]]; then
    if [[ $V_FLAG -ge 3 ]]; then
	echo "$0: debug[3]: arguments parsed, -N given, exiting 0" 1>&2
    fi
    exit 0
fi


# create a temporary author.csv file
#
export TMP_AUTHOR_WINS_CSV=".tmp.$NAME.AUTHOR_WINS_CSV.$$.tmp"
if [[ $V_FLAG -ge 3 ]]; then
    echo  "$0: debug[3]: temporary CSV author.csv file: $TMP_AUTHOR_WINS_CSV" 1>&2
fi
if [[ -z $NOOP ]]; then
    trap 'rm -f $TMP_AUTHOR_WINS_CSV; exit' 0 1 2 3 15
    rm -f "$TMP_AUTHOR_WINS_CSV"
    if [[ -e $TMP_AUTHOR_WINS_CSV ]]; then
	echo "$0: ERROR: cannot remove temporary CSV author.csv file: $TMP_AUTHOR_WINS_CSV" 1>&2
	exit 10
    fi
    echo '# author_handle,entry_id,entry_id,entry_id,…,,,,,,,,,,,,,,,' > \
      "$TMP_AUTHOR_WINS_CSV"
    if [[ ! -e $TMP_AUTHOR_WINS_CSV ]]; then
	echo "$0: ERROR: cannot create temporary CSV author.csv file: $TMP_AUTHOR_WINS_CSV" 1>&2
	exit 13
    fi
elif [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: because of -n, temporary CSV author.csv file is not used: $TMP_AUTHOR_WINS_CSV" 1>&2
fi


# create a temporary manifest.csv file
#
export TMP_MANIFEST_CSV=".tmp.$NAME.MANIFEST_CSV.$$.tmp"
if [[ $V_FLAG -ge 3 ]]; then
    echo  "$0: debug[3]: temporary CSV manifest.csv file: $TMP_MANIFEST_CSV" 1>&2
fi
if [[ -z $NOOP ]]; then
    trap 'rm -f $TMP_AUTHOR_WINS_CSV $TMP_MANIFEST_CSV; exit' 0 1 2 3 15
    rm -f "$TMP_MANIFEST_CSV"
    if [[ -e $TMP_MANIFEST_CSV ]]; then
	echo "$0: ERROR: cannot remove temporary CSV manifest.csv file: $TMP_MANIFEST_CSV" 1>&2
	exit 12
    fi
    echo '# year,dir,file_path,inventory_order,OK_to_edit,display_as,display_via_github,entry_text' > \
      "$TMP_MANIFEST_CSV"
    if [[ ! -e $TMP_MANIFEST_CSV ]]; then
	echo "$0: ERROR: cannot create temporary CSV manifest.csv file: $TMP_MANIFEST_CSV" 1>&2
	exit 13
    fi
elif [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: because of -n, temporary CSV file manifest.csv is not used: $TMP_MANIFEST_CSV" 1>&2
fi


# create a temporary year_prize.csv file
#
export TMP_YEAR_PRIZE_CSV=".tmp.$NAME.YEAR_PRIZE_CSV.$$.tmp"
if [[ $V_FLAG -ge 3 ]]; then
    echo  "$0: debug[3]: temporary CSV year_prize.csv file: $TMP_YEAR_PRIZE_CSV" 1>&2
fi
if [[ -z $NOOP ]]; then
    trap 'rm -f $TMP_AUTHOR_WINS_CSV $TMP_MANIFEST_CSV $TMP_YEAR_PRIZE_CSV; exit' 0 1 2 3 15
    rm -f "$TMP_YEAR_PRIZE_CSV"
    if [[ -e $TMP_YEAR_PRIZE_CSV ]]; then
	echo "$0: ERROR: cannot remove temporary CSV year_prize.csv file: $TMP_YEAR_PRIZE_CSV" 1>&2
	exit 12
    fi
    echo '# year_handle,award name' > \
      "$TMP_YEAR_PRIZE_CSV"
    if [[ ! -e $TMP_YEAR_PRIZE_CSV ]]; then
	echo "$0: ERROR: cannot create temporary CSV year_prize.csv file: $TMP_YEAR_PRIZE_CSV" 1>&2
	exit 13
    fi
elif [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: because of -n, temporary CSV year_prize.csv file is not used: $TMP_YEAR_PRIZE_CSV" 1>&2
fi


# create a temporary author win file
#
export TMP_AUTHOR_WIN=".tmp.$NAME.AUTHOR_WIN.$$.tmp"
if [[ $V_FLAG -ge 3 ]]; then
    echo  "$0: debug[3]: temporary CSV author_win file: $TMP_AUTHOR_WIN" 1>&2
fi
if [[ -z $NOOP ]]; then
    trap 'rm -f $TMP_AUTHOR_WINS_CSV $TMP_MANIFEST_CSV $TMP_YEAR_PRIZE_CSV $TMP_AUTHOR_WIN; exit' 0 1 2 3 15
    rm -f "$TMP_AUTHOR_WIN"
    if [[ -e $TMP_AUTHOR_WIN ]]; then
	echo "$0: ERROR: cannot remove temporary CSV author_win file: $TMP_AUTHOR_WIN" 1>&2
	exit 14
    fi
    :> "$TMP_AUTHOR_WIN"
    if [[ ! -e $TMP_AUTHOR_WIN ]]; then
	echo "$0: ERROR: cannot create temporary CSV author_win file: $TMP_AUTHOR_WIN" 1>&2
	exit 15
    fi
elif [[ $V_FLAG -ge 3 ]]; then
    echo "$0: debug[3]: because of -n, temporary CSV author_win file is not used: $TMP_AUTHOR_WIN" 1>&2
fi



# process each year
#
export YYYY
for YYYY in $(< "$TOP_FILE"); do

    # debug YYYY
    #
    if [[ $V_FLAG -ge 1 ]]; then
	echo "$0: debug[1]: starting to process year: $YYYY" 1>&2
    fi

    # verify that YYYY is a readable directory
    #
    if [[ ! -e $YYYY ]]; then
	echo  "$0: ERROR: YYYY does not exist: $YYYY" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi
    if [[ ! -d $YYYY ]]; then
	echo  "$0: ERROR: YYYY is not a directory: $YYYY" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi
    if [[ ! -r $YYYY ]]; then
	echo  "$0: ERROR: YYYY is not an readable directory: $YYYY" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi

    # verify that YYYY has a non-empty readable .year file
    #
    export YEAR_FILE="$YYYY/.year"
    if [[ ! -e $YEAR_FILE ]]; then
	echo  "$0: ERROR: YYYY/.year does not exist: $YEAR_FILE" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi
    if [[ ! -f $YEAR_FILE ]]; then
	echo  "$0: ERROR: YYYY/.year is not a regular file: $YEAR_FILE" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi
    if [[ ! -r $YEAR_FILE ]]; then
	echo  "$0: ERROR: YYYY/.year is not an readable file: $YEAR_FILE" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi
    if [[ ! -s $YEAR_FILE ]]; then
	echo  "$0: ERROR: YYYY/.year is not a non-empty readable file: $YEAR_FILE" 1>&2
	EXIT_CODE="6"  # exit 6
	echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	continue
    fi

    # process each entry directory under YYYY
    #
    export YYYY_DIR
    for YYYY_DIR in $(< "$YEAR_FILE"); do

	# debug YYYY
	#
	if [[ $V_FLAG -ge 3 ]]; then
	    echo "$0: debug[3]: starting to process year/dir: $YYYY_DIR" 1>&2
	fi

	# parse YYYY_DIR
	#
	if [[ ! -d $YYYY_DIR ]]; then
	    echo "$0: ERROR: YYYY_DIR is not a directory: $YYYY_DIR" 1>&2
	    EXIT_CODE="6"  # exit 6
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -w $YYYY_DIR ]]; then
	    echo "$0: ERROR: YYYY_DIR is not a writable directory: $YYYY_DIR" 1>&2
	    EXIT_CODE="6"  # exit 6
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	export YEAR_DIR=${YYYY_DIR%%/*}
	if [[ -z $YEAR_DIR ]]; then
	    echo "$0: ERROR: YYYY_DIR not in YYYY/dir form: $YYYY_DIR" 1>&2
	    EXIT_CODE="6"  # exit 6
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	export ENTRY_DIR=${YYYY_DIR#*/}
	if [[ -z $ENTRY_DIR ]]; then
	    echo "$0: ERROR: YYYY_DIR not in $YEAR_DIR/dir form: $YYYY_DIR" 1>&2
	    EXIT_CODE="6"  # exit 6
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ $ENTRY_DIR = */* ]]; then
	    echo "$0: ERROR: YYYY_DIR: $YYYY_DIR dir contains a /: $ENTRY_DIR" 1>&2
	    EXIT_CODE="6"  # exit 6
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	export ENTRY_ID="${YEAR_DIR}_${ENTRY_DIR}"

	# verify that YYYY_DIR is a writable directory
	#
	if [[ ! -e $YYYY_DIR ]]; then
	    echo  "$0: ERROR: YYYY_DIR does not exist: $YYYY_DIR" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -d $YYYY_DIR ]]; then
	    echo  "$0: ERROR: YYYY_DIR is not a directory: $YYYY_DIR" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -w $YYYY_DIR ]]; then
	    echo  "$0: ERROR: YYYY_DIR is not an writable directory: $YYYY_DIR" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi

	# verify YYYY/dir/.path
	#
	export DOT_PATH="$YYYY_DIR/.path"
	if [[ ! -s $DOT_PATH ]]; then
	    echo "$0: ERROR: not a non-empty file: $DOT_PATH" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	DOT_PATH_CONTENT=$(< "$DOT_PATH")
	if [[ $YYYY_DIR != "$DOT_PATH_CONTENT" ]]; then
	    echo "$0: ERROR: arg: $YYYY_DIR does not match $DOT_PATH contents: $DOT_PATH_CONTENT" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi

	# process the entry .entry.json file
	#
	if [[ $V_FLAG -ge 5 ]]; then
	    echo "$0: debug[5]: about process .entry.json: $ENTRY_JSON for: $YYYY_DIR" 1>&2
	fi

	# verify .entry.json
	#
	export ENTRY_JSON="$YYYY_DIR/.entry.json"
	if [[ ! -e $ENTRY_JSON ]]; then
	    echo "$0: ERROR: .entry.json does not exist: $ENTRY_JSON" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -f $ENTRY_JSON ]]; then
	    echo "$0: ERROR: .entry.json is not a file: $ENTRY_JSON" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -r $ENTRY_JSON ]]; then
	    echo "$0: ERROR: .entry.json is not a readable file: $ENTRY_JSON" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ ! -s $ENTRY_JSON ]]; then
	    echo "$0: ERROR: .entry.json is not a readable non-empty file: $ENTRY_JSON" 1>&2
	    EXIT_CODE="7"  # exit 7
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	#
	if [[ $V_FLAG -ge 7 ]]; then
	    echo "$0: debug[7]: about to run: $JPARSE_TOOL -q -- $ENTRY_JSON" 1>&2
	fi
	if "$JPARSE_TOOL" -q -- "$ENTRY_JSON"; then
	    if [[ $V_FLAG -ge 9 ]]; then
		echo "$0: debug[9]: valid JSON: $ENTRY_JSON" 1>&2
	    fi
	else
	    echo "$0: ERROR: .entry.json is not valid JSON: $ENTRY_JSON" 1>&2
	    EXIT_CODE="1"  # exit 1
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi

	# process the year_prize.csv update
	#
	AWARD=$(output_award "$ENTRY_JSON")
	if [[ -z $AWARD ]]; then
	    echo "$0: ERROR: award name empty or not found in: $$ENTRY_JSON" 1>&2
	    EXIT_CODE="1"  # exit 1
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ -z $NOOP ]]; then
	    echo "$ENTRY_ID,$AWARD" >> "$TMP_YEAR_PRIZE_CSV"
	elif [[ $V_FLAG -ge 7 ]]; then
	    echo "$0: debug[7]: because of -n, did append to year_prize.csv: $TMP_YEAR_PRIZE_CSV for: $ENTRY_JSON" 1>&2
	fi

	# record a win for each author_handle associated with this entry
	#
	AUTHOR_HANDLES=$(output_author_handles "$ENTRY_JSON")
	if [[ -z $AUTHOR_HANDLES ]]; then
	    echo "$0: ERROR: output_author_handles returned empty string for: $$ENTRY_JSON" 1>&2
	    EXIT_CODE="1"  # exit 1
	    echo "$0: Warning: EXIT_CODE set to: $EXIT_CODE" 1>&2
	    continue
	fi
	if [[ $V_FLAG -ge 7 ]]; then
	    echo "$0: debug[7]: output_author_handles $ENTRY_JSON: $AUTHOR_HANDLES" 1>&2
	fi
	if [[ -z $NOOP ]]; then
	    echo "$AUTHOR_HANDLES" | while read -r AUTHOR_HANDLE; do
		echo "$AUTHOR_HANDLE $ENTRY_ID" >> "$TMP_AUTHOR_WIN"
	    done
	elif [[ $V_FLAG -ge 9 ]]; then
	    echo "$0: debug[9]: because of -n, did not append to the temporary author win file" 1>&2
	fi

	# append top temporary manifest file for this entry
	#
	if [[ $V_FLAG -ge 5 ]]; then
	    echo "$0: debug[5]: about to: awk -f $MANIFEST_ENTRY_CSV_ENTRY_AWK $ENTRY_JSON >> $TMP_MANIFEST_CSV" 1>&2
	fi
	if [[ -z $NOOP ]]; then
	    awk -f "$MANIFEST_ENTRY_CSV_ENTRY_AWK" "$ENTRY_JSON" >> "$TMP_MANIFEST_CSV"
	    status="$?"
	    if [[ status -ne 0 ]]; then
		echo "$0: ERROR: awk -f $MANIFEST_ENTRY_CSV_ENTRY_AWK $ENTRY_JSON >> $TMP_MANIFEST_CSV," \
		     "error code: $status" 1>&2
		exit 8
	    fi
	elif [[ $V_FLAG -ge 9 ]]; then
	    echo "$0: debug[9]: because of -n, did not append to the temporary manifest file" 1>&2
	fi
    done
done


# Convert temporary author win file lines in TMP_AUTHOR_WINS_CSV lines
#
if [[ -z $NOOP ]]; then

    # firewall
    #
    if [[ ! -s $TMP_AUTHOR_WIN ]]; then
	echo "$0: ERROR: temporary author win file is empty: $TMP_AUTHOR_WIN" 1>&2
	exit 16
    fi

    # sort author win file
    #
    if [[ $V_FLAG -ge 5 ]]; then
	echo "$0: debug[5]: about to: sort $TMP_AUTHOR_WIN -o $TMP_AUTHOR_WIN" 1>&2
    fi
    sort "$TMP_AUTHOR_WIN" -o "$TMP_AUTHOR_WIN"
    status="$?"
    if [[ status -ne 0 ]]; then
	echo "$0: ERROR: sort $TMP_AUTHOR_WIN -o $TMP_AUTHOR_WIN," \
	     "error code: $status" 1>&2
	exit 8
    elif [[ $V_FLAG -ge 3 ]]; then
	echo "$0: debug[3]: sorted temporary author win file file: $TMP_AUTHOR_WIN" 1>&2
    fi

    # convert consecutive author win file lines with the same author_handle into a single TMP_AUTHOR_WINS_CSV line
    #
    export line=0
    export PREV_AUTHOR_ID=""
    while read -r AUTHOR_ID ENTRY_ID extra; do

	# firewall
	#
	((++line))
        if [[ -z $AUTHOR_ID ]]; then
	    echo "$0: line $line of $TMP_AUTHOR_WIN has an empty 1st field for AUTHOR_ID" 1>&2
	    exit 17
	fi
        if [[ -z $ENTRY_ID ]]; then
	    echo "$0: line $line of $TMP_AUTHOR_WIN has an empty 2nd field for ENTRY_ID" 1>&2
	    exit 18
	fi
        if [[ ! -z $extra ]]; then
	    echo "$0: line $line of $TMP_AUTHOR_WIN has 3 or more fields" 1>&2
	    exit 19
	fi

	# case: first author win file line
	#
	if [[ $line -eq 1 ]]; then
	    echo -n "$AUTHOR_ID,$ENTRY_ID" >> "$TMP_AUTHOR_WINS_CSV"
	    PREV_AUTHOR_ID="$AUTHOR_ID"

	# case: new AUTHOR_ID
	#
	elif [[ $AUTHOR_ID != "$PREV_AUTHOR_ID" ]]; then
	    echo >> "$TMP_AUTHOR_WINS_CSV"
	    echo -n "$AUTHOR_ID,$ENTRY_ID" >> "$TMP_AUTHOR_WINS_CSV"
	    PREV_AUTHOR_ID="$AUTHOR_ID"

	# case: same AUTHOR_ID as the previous author win file line
	#
	else
	    echo -n ",$ENTRY_ID" >> "$TMP_AUTHOR_WINS_CSV"
	fi

    done <  "$TMP_AUTHOR_WIN"

    # complete the final TMP_AUTHOR_WINS_CSV line
    #
    echo >> "$TMP_AUTHOR_WINS_CSV"

elif [[ $V_FLAG -ge 5 ]]; then
    echo "$0: debug[5]: because of -n, did not convert temporary author win file into TMP_AUTHOR_WINS_CSV lines" 1>&2
fi


# sort the temporary author_wins.csv file
#
if [[ -z $NOOP ]]; then

    if [[ $V_FLAG -ge 5 ]]; then
	echo "$0: debug[5]: about to: sort -t, -k1d,1 -k2d,2 $TMP_AUTHOR_WINS_CSV -o $TMP_AUTHOR_WINS_CSV" 1>&2
    fi
    sort -t, -k1d,1 -k2d,2 "$TMP_AUTHOR_WINS_CSV" -o "$TMP_AUTHOR_WINS_CSV"
    status="$?"
    if [[ status -ne 0 ]]; then
	echo "$0: ERROR: sort -t, -k1d,1 -k2d,2 $TMP_AUTHOR_WINS_CSV -o $TMP_AUTHOR_WINS_CSV," \
	     "error code: $status" 1>&2
	EXIT_CODE=8 # exit 8
    elif [[ $V_FLAG -ge 3 ]]; then
	echo "$0: debug[3]: sorted temporary author_wins.csv file: $TMP_AUTHOR_WINS_CSV" 1>&2
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not sort: $TMP_AUTHOR_WINS_CSV"
fi


# replace author_wins.csv file with the temporary file if author_wins.csv is missing or different
#
if [[ -z $NOOP ]]; then
    if cmp -s "$TMP_AUTHOR_WINS_CSV" "$AUTHOR_WINS_CSV"; then

	# case: author_wins.csv did not change
	#
	if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: author_wins.csv file did not change: $AUTHOR_WINS_CSV" 1>&2
        fi

    else

        # case: author_wins.csv file changed, update the file
        #
        if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: about to: mv -f -- $TMP_AUTHOR_WINS_CSV $AUTHOR_WINS_CSV" 1>&2
        fi
        if [[ $V_FLAG -ge 3 ]]; then
            mv -f -v -- "$TMP_AUTHOR_WINS_CSV" "$AUTHOR_WINS_CSV"
            status="$?"
        else
            mv -f -- "$TMP_AUTHOR_WINS_CSV" "$AUTHOR_WINS_CSV"
            status="$?"
        fi
        if [[ status -ne 0 ]]; then
            echo "$0: ERROR: mv -f -- $TMP_AUTHOR_WINS_CSV $AUTHOR_WINS_CSV filed," \
	         "error code: $status" 1>&2
            EXIT_CODE=8 # exit 8
        elif [[ $V_FLAG -ge 1 ]]; then
            echo "$0: debug[1]: replaced author_wins.csv file: $AUTHOR_WINS_CSV" 1>&2
        fi
        if [[ ! -s $AUTHOR_WINS_CSV ]]; then
            echo "$0: ERROR: not a non-empty author_wins.csv file: $AUTHOR_WINS_CSV" 1>&2
            EXIT_CODE=8 # exit 8
        fi
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not update $AUTHOR_WINS_CSV"
fi


# sort the temporary manifest.csv file
#
if [[ -z $NOOP ]]; then

    if [[ $V_FLAG -ge 5 ]]; then
	echo "$0: debug[5]: about to: sort -t, -k1,1 -k2d,2 -k4n,4 -k3d,3 -k5d,8 $TMP_MANIFEST_CSV -o $TMP_MANIFEST_CSV" 1>&2
    fi
    sort -t, -k1,1 -k2d,2 -k4g,4 -k3d,3 -k5d,8 "$TMP_MANIFEST_CSV" -o "$TMP_MANIFEST_CSV"
    status="$?"
    if [[ status -ne 0 ]]; then
	echo "$0: ERROR: sort -t, -k1,1 -k2d,2 -k4n,4 -k3d,3 -k5d,8 $TMP_MANIFEST_CSV -o $TMP_MANIFEST_CSV," \
	     "error code: $status" 1>&2
	EXIT_CODE=8 # exit 8
    elif [[ $V_FLAG -ge 3 ]]; then
	echo "$0: debug[3]: sorted temporary manifest.csv file: $TMP_MANIFEST_CSV" 1>&2
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not sort: $TMP_MANIFEST_CSV"
fi


# replace manifest.csv file with the temporary file if manifest.csv is missing or different
#
if [[ -z $NOOP ]]; then
    if cmp -s "$TMP_MANIFEST_CSV" "$MANIFEST_CSV"; then

	# case: manifest.csv did not change
	#
	if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: manifest.csv file did not change: $MANIFEST_CSV" 1>&2
        fi

    else

        # case: manifest.csv file changed, update the file
        #
        if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: about to: mv -f -- $TMP_MANIFEST_CSV $MANIFEST_CSV" 1>&2
        fi
        if [[ $V_FLAG -ge 3 ]]; then
            mv -f -v -- "$TMP_MANIFEST_CSV" "$MANIFEST_CSV"
            status="$?"
        else
            mv -f -- "$TMP_MANIFEST_CSV" "$MANIFEST_CSV"
            status="$?"
        fi
        if [[ status -ne 0 ]]; then
            echo "$0: ERROR: mv -f -- $TMP_MANIFEST_CSV $MANIFEST_CSV filed," \
	         "error code: $status" 1>&2
            EXIT_CODE=8 # exit 8
        elif [[ $V_FLAG -ge 1 ]]; then
            echo "$0: debug[1]: replaced manifest.csv file: $MANIFEST_CSV" 1>&2
        fi
        if [[ ! -s $MANIFEST_CSV ]]; then
            echo "$0: ERROR: not a non-empty manifest.csv file: $MANIFEST_CSV" 1>&2
            EXIT_CODE=8 # exit 8
        fi
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not update $MANIFEST_CSV"
fi


# sort the temporary year_prize.csv file
#
if [[ -z $NOOP ]]; then

    if [[ $V_FLAG -ge 5 ]]; then
	echo "$0: debug[5]: about to: sort -t, -k1d,1 -k2d,2 $TMP_YEAR_PRIZE_CSV -o $TMP_YEAR_PRIZE_CSV" 1>&2
    fi
    sort -t, -k1d,1 -k2d,2 "$TMP_YEAR_PRIZE_CSV" -o "$TMP_YEAR_PRIZE_CSV"
    status="$?"
    if [[ status -ne 0 ]]; then
	echo "$0: ERROR: sort -t, -k1d,1 -k2d,2 $TMP_YEAR_PRIZE_CSV -o $TMP_YEAR_PRIZE_CSV," \
	     "error code: $status" 1>&2
	EXIT_CODE=8 # exit 8
    elif [[ $V_FLAG -ge 3 ]]; then
	echo "$0: debug[3]: sorted temporary year_prize.csv file: $TMP_YEAR_PRIZE_CSV" 1>&2
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not sort: $TMP_YEAR_PRIZE_CSV"
fi


# replace year_prize.csv file with the temporary file if year_prize.csv is missing or different
#
if [[ -z $NOOP ]]; then
    if cmp -s "$TMP_YEAR_PRIZE_CSV" "$YEAR_PRIZE_CSV"; then

	# case: year_prize.csv did not change
	#
	if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: year_prize.csv file did not change: $YEAR_PRIZE_CSV" 1>&2
        fi

    else

        # case: year_prize.csv file changed, update the file
        #
        if [[ $V_FLAG -ge 5 ]]; then
            echo "$0: debug[5]: about to: mv -f -- $TMP_YEAR_PRIZE_CSV $YEAR_PRIZE_CSV" 1>&2
        fi
        if [[ $V_FLAG -ge 3 ]]; then
            mv -f -v -- "$TMP_YEAR_PRIZE_CSV" "$YEAR_PRIZE_CSV"
            status="$?"
        else
            mv -f -- "$TMP_YEAR_PRIZE_CSV" "$YEAR_PRIZE_CSV"
            status="$?"
        fi
        if [[ status -ne 0 ]]; then
            echo "$0: ERROR: mv -f -- $TMP_YEAR_PRIZE_CSV $YEAR_PRIZE_CSV filed," \
	         "error code: $status" 1>&2
            EXIT_CODE=8 # exit 8
        elif [[ $V_FLAG -ge 1 ]]; then
            echo "$0: debug[1]: replaced year_prize.csv file: $YEAR_PRIZE_CSV" 1>&2
        fi
        if [[ ! -s $YEAR_PRIZE_CSV ]]; then
            echo "$0: ERROR: not a non-empty year_prize.csv file: $YEAR_PRIZE_CSV" 1>&2
            EXIT_CODE=8 # exit 8
        fi
    fi

elif [[ $V_FLAG -ge 3 ]]; then
   echo "$0: debug[3]: because of -n, will not update $YEAR_PRIZE_CSV"
fi


# All Done!!! All Done!!! -- Jessica Noll, Age 2
#
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "$0: Warning: about to exit non-zero: $EXIT_CODE" 1>&2
elif [[ $V_FLAG -ge 1 ]]; then
    echo "$0: debug[1]: about to exit $EXIT_CODE" 1>&2
fi
exit "$EXIT_CODE"