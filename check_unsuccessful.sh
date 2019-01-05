#!/bin/bash

function die () {
    echo "$1" 1>&2
    exit 1
}

if [[ "$#" -ne 1 ]]; then
	die "Usage: $0 threshold"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
	die "Usage: $0 threshold
Check which users have unsuccessfully tried to login more than
threshold times and register the usernames in a file created
the first time the command is used.
Filename: /var/log/login_unsuccessful
Example: $0 3
Options:
	--help, -h	display this help text and exit"
elif [[ ! $1 =~ ^[0-9]+$ ]]; then
	die "[!] ERROR: $1 is not a natural number"
fi

DEFS=/etc/login.defs
PASSWD=/etc/passwd
SECURE=/var/log/secure

# Check files
if [[ ! -r $PASSWD ]]; then
  die "Can't read file $PASSWD"
elif [[ ! -r $SECURE ]]; then
  die "Can't read file $SECURE"
elif [[ ! -r $DEFS ]]; then
  die "Can't read file $DEFS"
fi

TRHESHOLD=$1
UID_MAX=$(grep "UID_MIN" "$DEFS" | tr -s '[:blank:]' | cut -d' ' -f2)
OUTPUT=/var/log/login_unsuccessful
OUTPUT_EXIST=0 
SHOW_DATE=0 

# Create the first time the log file
if [[ ! -w $OUTPUT ]]; then
  touch "$OUTPUT"
  OUTPUT_EXIST=1
  MONTH_REFERENCE=0
  DAY_REFERENCE=0
  HOUR_REFERENCE=0
  MINUTE_REFERENCE=0
  SECOND_REFERENCE=0 
fi

DATE_INIT_SCRIPT=$(LC_ALL=C date "+%Y-%m-%d %H:%M:%S")

if (( OUTPUT_EXIST == 0 )) ;then
  MONTH_REFERENCE=$(LC_ALL=C date "+%m" -r $OUTPUT)
  DAY_REFERENCE=$(LC_ALL=C date "+%d" -r $OUTPUT)
  HOUR_REFERENCE=$(LC_ALL=C date "+%H" -r $OUTPUT)
  MINUTE_REFERENCE=$(LC_ALL=C date "+%M" -r $OUTPUT)
  SECOND_REFERENCE=$(LC_ALL=C date "+%S" -r $OUTPUT)
fi

# Obtain users from /etc/passwd 
while IFS=':' read -r user _ uid _; do

  if (( uid >= UID_MAX )) || (( uid == 0 )); then
    N_TRIES=0
    PREVIOUS_IFS="$IFS"

	# Find unsuccessful logins
    IFS=$'\n' arr=($(grep " user=$user" "$SECURE"))
    IFS="$PREVIOUS_IFS"

    for line in  "${arr[@]}"; do
      # Check if the date is greater than the date of modification
      month=$(echo $line | cut -d' ' -f1)
      month_value=$(date -d "$month 1 1" "+%m")
      day=$(echo $line | cut -d' ' -f2)
      time=$(echo $line | cut -d' ' -f3)
      hour=$(echo $time | cut -d':' -f1)
      minute=$(echo $time | cut -d':' -f2)
      second=$(echo $time | cut -d':' -f3)

      if (( month_value > MONTH_REFERENCE ));then
        ((N_TRIES++))
      elif (( month_value == MONTH_REFERENCE )) && (( day > DAY_REFERENCE ));then
        ((N_TRIES++)) 
      elif (( month_value == MONTH_REFERENCE )) && (( day == DAY_REFERENCE )) && (( 10#$hour > 10#$HOUR_REFERENCE )); then
        ((N_TRIES++))
      elif (( month_value == MONTH_REFERENCE )) && (( day == DAY_REFERENCE )) && (( 10#$hour == 10#$HOUR_REFERENCE )) && (( 10#$minute > 10#$MINUTE_REFERENCE )); then
        ((N_TRIES++))
      elif (( month_value == MONTH_REFERENCE )) && (( day == DAY_REFERENCE )) && (( 10#$hour == 10#$HOUR_REFERENCE )) && (( 10#$minute == 10#$MINUTE_REFERENCE )) && (( 10#$second > 10#$SECOND_REFERENCE )); then
        ((N_TRIES++))
      fi
    
    done
	
    if (( N_TRIES > TRHESHOLD )); then
		
		if((SHOW_DATE == 0)); then
			SHOW_DATE=1
			echo "$DATE_INIT_SCRIPT" "Threshold=$TRHESHOLD">> "$OUTPUT"
		fi
    	printf "  User (%s) have unsuccessfully tried to login (%d) times" "$user" "$N_TRIES" >> "$OUTPUT"

		# Optional part: show if user and user's password doesn't expires 

		PREVIOUS_IFS="$IFS"
		IFS=$'\n' expires=($(LC_ALL=C chage -l "$user" | grep "Password expires\|Account expires" | cut -d: -f2))
		[[ "${expires[0]}" = " never" ]] && printf "\t[Password never expires]" >> $OUTPUT
		[[ "${expires[1]}" = " never" ]] && printf "\t[Account never expires]" >> $OUTPUT
		IFS="$PREVIOUS_IFS"

		#--------------
			
		printf "\n" >> "$OUTPUT"

    fi

  fi

done < "$PASSWD"

exit 0
