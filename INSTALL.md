Miletus: Install notes
======================

# Installing Miletus

## Install system dependencies

These instructions are for installing Miletus on a _Red Hat Enterprise
Linux_ (RHEL) based distibution of Linux.

Use `yum` to install these packages:

- `make`
- `patch`
- `autoconf automake libtool bison`
- `gcc-c++`
- `git`
- `bzip2`
- `readline-devel`
- `zlib-devel`
- `openssl-devel`
- `libyaml-devel`
- `libffi-devel`
- `iconv-devel`
- `libxslt-devel`
- `sqlite-devel`
- `postgresql-devel`
- `postgresql-server`

## Setup database

### PostgreSQL

Initialize PostgreSQL and start PostgreSQL server:

    sudo  postgresql-setup initdb

    sudo  service postgresql start

### Create user and database in PostgreSQL

    sudo -u postgres psql \<\<EOF
    CREATE USER hoylen;
    CREATE DATABASE miletus OWNER hoylen;
    EOF

Edit the `pg_hba.conf` file to configure the PostgreSQL database
access control rules.

    # vi /var/lib/pgsql/data/pg_hba.conf

Note: the /var/lib/pgsql directory is only readable by the `postgres`
user. You will need to be `root` or `postgres` to access it. For example,
run the editor using `sudo`.

### Install RVM

Install the [Ruby Version Manager](https://rvm.io/) (RVM) and Ruby
1.9.x. See <https://rvm.io/> for the latest installation instructions.

Note: this should be done in the user account that will be running
_Miletus_ (i.e. not as `root`).

    curl -L https://get.rvm.io | bash -s stable --ruby=ruby-1.9.3
    source \$HOME/.rvm/scripts/rvm
	
    curl -L https://get.rvm.io | bash -s stable
    . \$HOME/.rvm/scripts/rvm
    rvm install ruby-1.9.3
    rvm use ruby-1.9.3

## Installing Miletus

### Obtain miletus from GitHub

Use `git` to clone the Miletus source from GitHub into a local directory
called `miletus`:

    git clone https://github.com/uq-eresearch/miletus.git

This will create a new directory called `miletus`. Specify a directory
name if you want to use a different directory.

### Install dependent gems

Use `cd` to change into the Miletus source directory.

    cd miletus

With _RVM_ installed, the `cd` command (a shell function provided by
_RVM_ that executes the builtin `cd` command and then additional RVM
shell scripts) will automatically detect the `.rvmrc` configuration
file and ask if you want to trust it: answer yes. This will cause
`bundle install` to automatically run, which will download and install
the necessary gems.

### Configure database for Foreman to use

Create the `.env` file that configures _Foreman_. Specify the database
that Miletus will use.

    echo 'DATABASE_URL=postgres:///miletus' > .env

### Initialize the database

    foreman run rake db:migrate

Note: if rake aborts with a "database configuration does not specify
adapter" error, the likely cause is the `.env` file is missing.

### Run tests

    rake spec

# Running Miletus

## Starting Miletus

    foreman start

## Creating harvest jobs

Leave _Miletus_ running and in a separate console start the _Rails
console_ from within the _Miletus_ source directory:

    foreman run rails console

At the prompt, enter the following Ruby code:

    require 'miletus'
    Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.new(:endpoint => 'http://dataspace.uq.edu.au/oai').save!

To see how many records have been harvested, at the prompt enter the
following Ruby code:

    Miletus::Output::OAIPMH::Record.count

Wait a few minutes for the harvesting scheduler to run. Status
messages will appear in the console running _Miletus_. If additional
records are havested, the count should be different. **Can we manually
trigger this to happen instead of waiting?**

To exit from the _Rails console_, at the prompt enter the following:

    quit

## Examining the OAI-PMH feed

By default, the _Miletus server_ provides an OAI-PMH feed on port 5000
under the `/oai` path.

For example, use these URIs to access it:

    http://localhost:5000/oai?verb=Identify
    http://localhost:5000/oai?verb=ListIdentifiers&metadataPrefix=rif
    http://localhost:5000/oai?verb=ListRecords&metadataPrefix=rif
    http://localhost:5000/oai?verb=ListRecords&metadataPrefix=oai_dc

## Stopping Miletus

To stop the _Miletus server_, type Ctrl-C.

**Is there a better way?**

# Acknowledgements

This project is supported by the _Australian National Data Service_
([ANDS](http://www.ands.org.au/)). ANDS is supported by the Australian
Government through the _National Collaborative Research Infrastructure
Strategy Program_ and the _Education Investment Fund_ (EIF) _Super
Science Initiative_.
