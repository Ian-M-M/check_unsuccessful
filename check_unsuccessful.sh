# Se trata de implementar una utilidad para comprobar los usuarios (no cuentas de servicios) que hayan realizado más de un cierto número de intentos fallidos de acceso al sistema.

# Para realizar lo anterior se debe utilizar como fuente de datos de acceso el fichero/var/log/secure.

# El script admitirá la siguiente sintaxis: check_unsuccessful threshold y generará un fichero /var/log/login_unsuccessful con los nombres de las cuentas que hayan intentado acceder al sistema de forma infructuosa más de <threshold> veces.

# Asimismo dicho script debe tener una definición funcional que permita planificarlo en un fichero crontab para que se ejecute periódicamente y que en cada ejecución se mire a partir de la fecha de la última ejecución del script.

# Opciones adicionales:
# Incorporar en el fichero anterior por cada usuario una marca en aquellos cuya cuenta no tienen caducidad y otra marca para si no tienen caducidad de contraseñas.

#!/bin/bash

function die ()
{
    echo -e "$1" 1>&2
    exit 1
}

if [[ "$#" -ne 1 ]]; then 
	die "Usage: $0 threshold"
elif ( [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] ); then 
	die "Usage: $0 threshold
Check which users have unsuccessfully tried to enter more than
threshold times and register the usernames in a file created 
the first time the command is used.
Filename: /var/log/login_unsuccessful
Example: $0 3

Options:
	--help, -h	display this help text and exit"
elif [[ ! $1 =~ ^[0-9]+$ ]]; then
	die "\e[0;31m[!] ERROR:\e[0m $1 is not a natural number"
fi

exit 0

#grep "check failed for user ($user)" /var/log/secure
#LC_ALL=C date "formato" -r $testigo
