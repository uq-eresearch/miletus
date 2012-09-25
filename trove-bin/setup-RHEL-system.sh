#!/bin/sh
#
# Miletus setup script for Red Hat Enterprise Linux (RHEL) based
# distributions (e.g. CentOS, Scientific Linux). This script is
# designed to be run on a minimal install of the distribution. It
# installs all the packages and configures PostgreSQL.
#
# Run this as root (or use sudo).
#
# If you are installing on a new machine, in addition to running
# this script, all you need to do is install RVM:
#
#    curl -L https://get.rvm.io | bash -s stable --ruby=ruby-1.9.3
#    source \$HOME/.rvm/scripts/rvm
#
# And get the Miletus source from GitHub:
#
#    git clone https://github.com/uq-eresearch/miletus.git
#
#----------------------------------------------------------------

# Defaults

PROG=`basename $0`

if [ "$SUDO_USER" ]; then
  DEFAULT_DBUSER="$SUDO_USER"
else
  DEFAULT_DBUSER="$USER"
fi

DEFAULT_DBNAME=miletus

# Parameters

DBUSER="$DEFAULT_DBUSER"
DBNAME="$DEFAULT_DBNAME"

HELP=
VERBOSE=
UNINSTALL=

DO_PACKAGES=yes
DO_POSTGRESQL=yes
DO_PG_USER=yes
DO_PG_DATABASE=yes

# Process command line

getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  eval set -- `getopt --long help,database:user:,uninstall,version --options d:hUu:v -- "$@"`
else
    # Original getopt is available
  eval set -- `getopt d:hUu:v "$@"`
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)      HELP=yes;;
        -d | --database)  DBNAME="$2"; shift;;
        -U | --uninstall) UNINSTALL=yes;;
        -u | --user)      DBUSER="$2"; shift;;
        -v | --verbose)   VERBOSE=yes;;
        --)               shift; break;;
    esac
    shift
done

if [ $# -gt 0 ]; then
  DO_PACKAGES=
  DO_POSTGRESQL=
  DO_PG_USER=
  DO_PG_DATABASE=

  for ARG in "$@"; do
    case "$ARG" in
    packages)
      DO_PACKAGES=yes ;;
    postgresql)
      DO_POSTGRESQL=yes ;;
    dbuser)
      DO_PG_USER=yes ;;
    database)
      DO_PG_DATABASE=yes ;;
    *)
      echo "Error: Bad argument: $ARG" >&2
      echo "  Expecting one or more: packages, postgresql, dbuser, database">&2
      exit 2
    esac
  done
fi

if [ $HELP ]; then
  echo "Usage: ${PROG} [options] [items]"
  echo "Options:"
  echo "  -d | --database name"
  echo "        name of database to create (default: $DEFAULT_DBNAME)"
  echo "  -u | --user name"
  echo "        database user to create (default: $DEFAULT_DBUSER)"
  echo "  -U | --uninstall"
  echo "        uninstall items (only works for dbuser and database)"
  echo "  -h | --help"
  echo "        show this message"
  echo "  -v | --verbose"
  echo "        show extra information"
  echo "Items: (defaults to all items)"
  echo "  packages   - download and install packages (uses \"yum\")"
  echo "  postgresql - initialize PostgreSQL"
  echo "  dbuser     - create user in PostgreSQL"
  echo "  database   - create database in PostgreSQL owned by the user"
  exit 3
fi

#----------------------------------------------------------------
# Check permissions

if [ `id -u` != 0 ]; then
  echo "Error: not running with root privileges (try using sudo)" >&2
  exit 1
fi

#----------------------------------------------------------------
# Uninstall mode

if [ $UNINSTALL ]; then

  if [ $DO_PG_DATABASE ]; then
  
    echo "$PROG: Dropping PostgreSQL database \"${DBNAME}\""
  
    cd /tmp # Prevent warnings if postgres user can't access current directory
  
    # Run psql as the user "postgres" to execute these SQL commands
  
    echo "DROP DATABASE \"${DBNAME}\";" | \
    sudo -u postgres  psql
  
    if [ $? -ne 0 ]; then
      echo "Error: psql failed: aborted" >&2
      exit 1
    fi
  fi

  if [ $DO_PG_USER ]; then
  
    echo "$PROG: Dropping PostgreSQL user \"${DBUSER}\""
  
    cd /tmp # Prevent warnings if postgres user can't access current directory
  
    # Run psql as the user "postgres" to execute these SQL commands
  
    echo "DROP USER \"${DBUSER}\";" | \
    sudo -u postgres  psql
  
    if [ $? -ne 0 ]; then
      echo "Error: psql failed: aborted" >&2
      exit 1
    fi
  fi

  if [ $DO_POSTGRESQL ]; then

    # Experimental: this does not yet work properly. After deleting
    # the PGDATA directory, running "setup-RHEL-system.sh" again
    # does not work (dbuser and database fails).

    echo "$PROG: Deleting PostgreSQL data"
    echo "WARNING: THIS DOES NOT WORK PROPERLY. You will need to"
    echo "         ALSO RUN 'yum erase postgresql' before it will work again."

    PGDATA=`. ~postgres/.bash_profile && echo $PGDATA`
    if [ -d "${PGDATA}" ]; then
       rm -rf "${PGDATA}"
    else
      echo "Warning: PostgreSQL data directory does not exist: $PGDATA" 2>&1
    fi
  fi

  if [ $DO_PACKAGES ]; then
    echo "Warning: cannot uninstall yum packages" 2>&1
  fi

  exit 0
fi

#----------------------------------------------------------------
# Install system packages

if [ $DO_PACKAGES ]; then

  echo "$PROG: Downloading and installing system packages"
  
  if [ $VERBOSE ]; then
    YUM_QUIET=
  else
    YUM_QUIET=-q
  fi
 
  yum install --assumeyes ${YUM_QUIET} \
    make \
    patch \
    autoconf automake libtool bison \
    gcc-c++ \
    git \
    bzip2 \
    readline-devel \
    zlib-devel \
    openssl-devel \
    libyaml-devel \
    libffi-devel \
    iconv-devel \
    libxslt-devel \
    sqlite-devel \
    postgresql-devel \
    postgresql-server
  
  if [ $? -ne 0 ]; then
    echo "Error: yum install failed: aborted" >&2
    exit 1
  fi

  echo
fi

#----------------------------------------------------------------
# Initialize PostgreSQL

if [ $DO_POSTGRESQL ]; then

  # Initialize default database and start PostgreSQL

  echo "$PROG: Initializing PostgreSQL"
  postgresql-setup initdb
  if [ $? -ne 0 ]; then
    echo "Error: postgresql-setup failed: aborted" >&2
    exit 1
  fi

  echo "$PROG: Starting PostgreSQL service"
  service postgresql start
  if [ $? -ne 0 ]; then
    echo "Error: starting postgresql service failed: aborted" >&2
    exit 1
  fi

  PGDATA=`. ~postgres/.bash_profile && echo $PGDATA`
  echo "$PROG: Please edit configuration: ${PGDATA}/pg_hba.conf"
  echo
fi

#----------------------------------------------------------------

if [ $DO_PG_USER ]; then

  echo "$PROG: Creating PostgreSQL user \"${DBUSER}\""

  cd /tmp # Prevent warnings if postgres user can't access current directory

  # Run psql as the user "postgres" to execute these SQL commands

  echo "CREATE USER \"${DBUSER}\";" | \
  sudo -u postgres  psql

  if [ $? -ne 0 ]; then
    echo "Error: psql failed: aborted" >&2
    exit 1
  fi
  echo
fi

#----------------------------------------------------------------

if [ $DO_PG_DATABASE ]; then

  echo "$PROG: Creating PostgreSQL database \"${DBNAME}\""

  cd /tmp # Prevent warnings if postgres user can't access current directory

  # Run psql as the user "postgres" to execute these SQL commands

  echo "CREATE DATABASE \"${DBNAME}\" OWNER \"${DBUSER}\";" | \
  sudo -u postgres  psql

  if [ $? -ne 0 ]; then
    echo "Error: psql failed: aborted" >&2
    exit 1
  fi
fi

exit 0

#EOF
