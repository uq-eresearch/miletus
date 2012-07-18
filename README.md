# Miletus

[![Build Status](https://secure.travis-ci.org/tjdett/miletus.png?branch=master)](http://travis-ci.org/tjdett/miletus)

## Overview

_More to come later..._


## Usage

The database connection is provided by the `DATABASE_URL` environment variable.

Take advantage of Foreman's `.env` file:

    echo "DATABASE_URL=postgres:///my_db" > .env

To run Rake tasks adhoc:

    foreman run rake jobs:work

Or to run the whole lot:

    foreman start

	
