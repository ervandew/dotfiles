#!/bin/bash

# screen-preexec.sh   Matthew Flint (m@tthew.org)

# this uses the "preexec" bash script by "Glyph" here:
# http://www.twistedmatrix.com/users/glyph/preexec.bash.txt

# it makes it more useful (for me) when using screen, by showing either
# the currently-running command (such as "top") or a filename (when
# editing or viewing a file)

# when a command is running as superuser (either by root, or via sudo)
# then it is prefixed with #

SCREEN=$(echo "$TERM" | grep "^screen")
if [ -z "$SCREEN" ] ; then
	return
fi

preexec() {
	# commandstring starts as the whole string, but we
	# chop it up...
	local commandstring=$1;

	# start by stripping all the switches which start with
	# a hyphen
	commandstring=`echo $commandstring | sed -e 's/\( -[^ ]*\)//g'` ;

	# this is a superuser command if the user is
	# root - so a # will be shown in the title
	local root="";
	if [[ $EUID -eq 0 ]]; then
		root="#";
	fi

	# find the first word in the commandstring, which is the
	# command being executed
	local command=`echo $commandstring | cut -d ' ' -f1`;

	# strip any other unwanted stuff from the start of the command.
	# These generally modify the behaviour or environment of another
	# command
	local removedcommand="no";
	until [[ $removedcommand = "" ]]; do
		removedcommand="";
		case "$command" in
			watch|nice|nohup|time|trickle)
				removedcommand="yes";
				commandstring=`echo $commandstring | cut -d ' ' -f2-`;
				command=`echo $commandstring | cut -d ' ' -f1`;
			;;
			sudo)
				root="#";

				removedcommand="yes";
				commandstring=`echo $commandstring | cut -d ' ' -f2-`;
				command=`echo $commandstring | cut -d ' ' -f1`;
			;;
		esac
	done

	# this is the result which will be shown
	local result;

	# now check for a set of predefined long-running
	# commands which operate on a file. Instead of showing
	# the command name, we'll show the filename surrounded
	# by braces.
	
	# I'd rather see
	#	"{file 1}" "{file 2}" "{file 3}"
	# than
	#	"vi" "vi" "vi"
	case "$command" in
		vi|view|less|more|tail|head|man)
			# remove the command name (vi, less, etc) from the string. This
			# should just leave any filenames, plus pipes and redirects. We append
			# " " to the commandstring to make sure that there's at least one
			# field delimiter, othewise "cut" won't chop off the command
			local filepathsandpipes=`echo $commandstring " " | cut -d ' ' -f2-`;

			# now remove any pipes or redirects
			local filepaths=`echo $filepathsandpipes | sed -e 's/[|>].*//g'` ;

			# how many filepaths?
			local filenamecount=`echo $filepaths | awk '{ print NF }'`;
			if [[ $filenamecount -eq 0 ]]; then
				# no filenames - just show the command
				result=$root$command;
			elif [[ $filenamecount -eq 1 ]]; then
				# one filename - show it
				local filename=`basename $filepaths`;
				result=$root"{"$filename"}";
			else
				# more than one filename - show the command
				# and a wildcard indicator to indicate multiple
				# files
				result=$root$command*;
			fi
		    ;;
		*)
			# just show the basename of the command
			if [ -n "$command" ] ; then
				command=`basename $command`;
				result=$root$command;
			fi
		    ;;
	esac

	preexec_screen_title "$result";
}

precmd() {
	if [[ $EUID -eq 0 ]]; then
		preexec_screen_title "#";
	else
		preexec_screen_title "$";
	fi
}


