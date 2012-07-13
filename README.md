# Miletus OAI-PMH RIF-CS Harvester

[![Build Status](https://secure.travis-ci.org/tjdett/miletus-oaipmh-rifcs-harvester.png?branch=master)](http://travis-ci.org/tjdett/miletus-oaipmh-rifcs-harvester)

## Overview

_More to come later..._


## Usage

The database connection is provided by the `DATABASE_URL` environment variable.

For running Rake tasks adhoc:

    DATABASE_URL="postgres:///my_db" rake jobs:work

Or to run the whole lot, you can take advantage of Foreman's `.env` file:

    echo "DATABASE_URL=postgres:///my_db" > .env
    foreman start
	
