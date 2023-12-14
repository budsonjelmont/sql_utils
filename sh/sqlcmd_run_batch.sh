#!/usr/bin/env bash

### Description
# This command takes in a directory and will load
# any files found within a directory
# Note: to allow for multiple files, they get loaded in
# numerical order so prepend all file names with an integer
# Ex: 1_whatever.sql, 2_seed.sql, 3_etc.sql
###

###
# Example usage:
# Run on local database from WSL. Uses local authentication if a $USER argument is supplied.
#./sqlcmd_run_batch.sh mssql/migrations/run_em_all 127.0.0.1,8811 localDbName sa $sa_password_in_local_db 

# Run on remote server from Windows. Uses LDAP authentication if $USER argument is not supplied.
#./sqlcmd_run_batch.sh mssql/migrations/run_em_all hostName hostedDbName
###

LOAD_DIR=$1		# Directory containing .sql files to run
HOST=$2			# Host where database resides
DB=$3			# Database to execute .sql scripts in
USER=$4			# (OPTIONAL) Database user if using local authentication
USER_PASSWORD=$5 	# (OPTIONAL) Password for database user if using local authentication. Can be "" for password-less user.

SQLCMD_DIR=${SQLCMD_DIR:-""} # Default to empty string (assume sqlcmd executable is in $PATH). Allow override from exported $SQLCMD_DIR env variable. If calling from inside Docker MS SQL container, should be /opt/mssql-tools/bin/.

if [[ ! -d "$LOAD_DIR" ]]
then
    echo "Database load directory not found: $LOAD_DIR"
    exit
fi
echo "Running all SQL scripts in $LOAD_DIR..."

# If no password was provided, assume that LDAP authentication should be used instead
if [[ ! -z "${USER}" ]]
then 
  AUTH="-U $USER -P $USER_PASSWORD"
else
  AUTH="-G"
fi

# Can't guarantee users won't put spaces in scripts
#readarray -d ' ' sqlfiles < <(find "$LOAD_DIR" -type f -iname '*.sql' -printf "%f | sort")

for script in `ls -v ${LOAD_DIR}/*.sql`
do
  echo "Now running ${script}..."
  # -I flag sets quoted identifiers ON
  # -a flag sets packet size to allow for very large INSERT scripts
  # -C trust server certificate blindly
  cmd="${SQLCMD_DIR}sqlcmd -S $HOST -I -d $DB $AUTH -i "$script" -a 32767 -C"
  echo $cmd
  $cmd
#  ${SQLCMD_DIR}sqlcmd -S $HOST -I -d $DB $AUTH -i "$script" -a 32767 -C
done
