#!/bin/sh

code_ok=0
code_warning=1
code_critical=2
code_unknown=3

for option in "$@"
do
  case $option in
    -w=*|--warning-age=*)
      opt_warning_age="${option#*=}"
      warning_timestamp=`date --utc --date="${opt_warning_age} ago" '+%s'`
    ;;
    -c=*|--critical-age=*)
      opt_critical_age="${option#*=}"
      critical_timestamp=`date --utc --date="${opt_critical_age} ago" '+%s'`
    ;;
    -W=*|--warning-size=*)
      opt_warning_size="${option#*=}"
    ;;
    -C=*|--critical-size=*)
      opt_critical_size="${option#*=}"
    ;;
    -p=*|--process-name=*)
      opt_process_name="${option#*=}"
    ;;
    -u=*|--user-name=*)
      opt_user_name="${option#*=}"
    ;;
    *)
      echo "Unknown option ${option}"
      echo
      echo "Example: $0 -u log-courier --warning-age='2 days' --critical-age='2 days 12 hours'"
      echo
      echo "Usage: $0 [-u/--user-name=substring] [-p/--process-name=substring]"
      echo "          [-c/--critical-age=File_age_string]"
      echo "          [-w/--warning-age=File_age_string]"
      echo "          [-c/--critical-size=File_size_in_bytes]"
      echo "          [-w/--warning-size=File_size_in_bytes]"
      echo
      echo "$0 is a Nagios plugin detects if some process holds deleted file"
      echo "for a long time without modifying it."
      echo "Age should be specified in format as described in 'DATE STRING' of 'date' man page."
      echo "Process name filter can be defined with [-p/--process-name]."
      echo "User name can be limited with [-u/--user-name]."
      exit $code_unknown
    ;;
  esac
done

if [ -z "$opt_user_name" -a -z "$opt_process_name" ]; then
  # no filter defined, search though all processes
  deleted_file_holders_pid=`lsof -M -X -l |grep ' (deleted)$'|cut -d' ' -f 2|sort|uniq|grep -v '^$'`
  # TODO: numerous lsof options can be received on the command line
  # TODO: for example, "+|-e" can filter filesystems
else
  [ -z "$opt_user_name" ]    || pgrep_opt="-u '${opt_user_name}' $pgrep_opt"
  [ -z "$opt_process_name" ] || pgrep_opt="$pgrep_opt '$opt_process_name'"
  deleted_file_holders_pid=`pgrep $pgrep_opt`
fi

warning_files_array=()
critical_files_array=()
warning_pid_array=()
critical_pid_array=()
warning_files_size=0
critical_files_size=0

for pid in $deleted_file_holders_pid ; do
  for file_name in /proc/${pid}/fd/* ; do
    # from "man stat":
    # 0. %s     total size, in bytes
    # 1. %Y     time of last modification, seconds since Epoch
    # 2. %F     file type
    stat_array=(`stat --dereference --format='%s %Y %F' "$file_name"`)
    file_size=${stat_array[0]}
    file_mtime=${stat_array[1]}
    file_type=${stat_array[@]:2:9}
    if [ "$file_type" == 'regular file' ] ; then
      if [ "$warning_timestamp" ] && [ "$file_mtime" -lt "$warning_timestamp" ] ; then
        warning_files_array+=("$file_name")
        warning_pid_array+=("$pid")
        ((warning_files_size+=$file_size))
      fi
      if [ "$critical_timestamp" ] && [ "$file_mtime" -lt "$critical_timestamp" ] ; then
        critical_files_array+=("$file_name")
        critical_pid_array+=("$pid")
        ((critical_files_size+=$file_size))
      fi
    fi
  done
done

critical_pid_string=`echo "${critical_pid_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '`
warning_pid_string=`echo "${warning_pid_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '`

if [ -n "$critical_files_array" ] && ([ -z "$opt_critical_size" ] || [ "$critical_files_size" -gt "$opt_critical_size" ]) ; then
  echo "CRITICAL: deleted files are too old | Offending PIDs: ${critical_pid_string}"
  exit $code_critical
elif [ -n "$warning_files_array" ] && ([ -z "$opt_warning_size" ] || [ "$warning_files_size" -gt "$opt_warning_size" ]) ; then
  echo "WARNING: deleted files are too old | Offending PIDs: ${warning_pid_string}"
  exit $code_warning
else
  echo "OK: no deleted files pass the given threshold"
  exit $code_ok
fi


exit 0

# Licensed under the terms of Apache License 2.0+

# Copyright 2016 Alexander Kabakaev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
