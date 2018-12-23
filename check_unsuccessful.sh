# Se trata de implementar una utilidad para comprobar los usuarios (no cuentas de servicios)
# que hayan realizado más de un cierto número de intentos fallidos de acceso al sistema.

# Para realizar lo anterior se debe utilizar como fuente de datos de acceso el fichero/var/log/secure.

# El script admitirá la siguiente sintaxis: check_unsuccessful threshold y generará un fichero
# /var/log/login_unsuccessful con los nombres de las cuentas que hayan intentado acceder al sistema
# de forma infructuosa más de <threshold> veces.

# Asimismo dicho script debe tener una definición funcional que permita planificarlo en un fichero
# crontab para que se ejecute periódicamente y que en cada ejecución se mire a partir de la fecha de la última ejecución del script.

# Opciones adicionales:
# Incorporar en el fichero anterior por cada usuario una marca en aquellos cuya cuenta no tienen
# caducidad y otra marca para si no tienen caducidad de contraseñas.

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

TRHESHOLD=$1
UID_MAX=$(grep "UID_MIN" /etc/login.defs | tr -s '[:blank:]' | cut -d' ' -f2)
PASSWD=/etc/passwd
SECURE=/var/log/secure
OUTPUT=/var/log/login_unsuccessful

# Create the first time the log file
if [[ ! -f $OUTPUT ]]; then
  touch "$OUTPUT"
fi

if [[ ! -r $PASSWD ]]; then
  die "Can't read file $PASSWD"
fi

if [[ ! -r $SECURE ]]; then
  die "Can't read file $SECURE"
fi

echo "TRHESHOLD: $TRHESHOLD"

MONTH_REFERENCE=$(LC_ALL=C date "+%b" -r $SECURE)
DAY_REFERENCE=$(LC_ALL=C date "+%d" -r $SECURE)
HOUR_REFERENCE=$(LC_ALL=C date "+%H" -r $SECURE)
MINUTE_REFERENCE=$(LC_ALL=C date "+%M" -r $SECURE)
SECOND_REFERENCE=$(LC_ALL=C date "+%S" -r $SECURE)

PREVIOUS_IFS=$IFS

IFS=$'\n' arr=($(grep "check failed for user (root)" "$SECURE"))

IFS=$PREVIOUS_IFS
N_TRIES=0
for line in  "${arr[@]}"; do
  # check if the date is greater than the date of modification
  mont=$(echo $line | cut -d' ' -f1)
  if (( mont >= MONTH_REFERENCE ));then 
    day=$(echo $line | cut -d' ' -f2)
    if (( day >= DAY_REFERENCE ));then 
      hours=$(echo $line | cut -d' ' -f3)
      hour=$(echo $hours | cut -d':' -f1)
      if(( hour >= HOUR_REFERENCE ));then 
        minute=$(echo $hours | cut -d':' -f2)
        if (( minute >= MINUTE_REFERENCE ));then 
          second=$(echo $hours | cut -d':' -f3)
          if (( second >= SECOND_REFERENCE ));then 
            N_TRIES=(( N_TRIES + 1 ))
            echo "$mont $day $hour $minute $second"
          fi            
        fi
      fi
    fi
  fi
done

if (( N_TRIES > TRHESHOLD ));then
  echo "User ($user) have unsuccessfully tried to login more than $TRHESHOLD times" >> "$OUTPUT"
fi  



# Check rest users
while IFS=':' read -r user _ uid _; do
  if (( uid >= UID_MAX )); then
    N_TRIES=0

    PREVIOUS_IFS=$IFS

    IFS=$'\n' arr=($(grep "check failed for user (root)" "$SECURE"))

    IFS=$PREVIOUS_IFS

    for line in  "${arr[@]}"; do

      # check if the date is greater than the date of modification
      mont=$(echo $line | cut -d' ' -f1)
      if (( mont >= MONTH_REFERENCE ));then 
        day=$(echo $line | cut -d' ' -f2)
        if (( day >= DAY_REFERENCE ));then 
          hours=$(echo $line | cut -d' ' -f3)
          hour=$(echo $hours | cut -d':' -f1)
          if(( hour >= HOUR_REFERENCE ));then 
            minute=$(echo $hours | cut -d':' -f2)
            if (( minute >= MINUTE_REFERENCE ));then 
              second=$(echo $hours | cut -d':' -f3)
              if (( second >= SECOND_REFERENCE ));then 
                N_TRIES=(( N_TRIES + 1 ))
                echo "$mont $day $hour $minute $second"
              fi            
            fi
          fi
        fi
      fi
    
    done

    if (( N_TRIES > TRHESHOLD ));then
      echo "User ($user) have unsuccessfully tried to login more than $TRHESHOLD times" >> "$OUTPUT"
    fi

  fi
done < $PASSWD

exit 0
