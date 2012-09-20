# Miletus

[![Build Status](https://secure.travis-ci.org/uq-eresearch/miletus.png)
](http://travis-ci.org/uq-eresearch/miletus)
[![Dependency Status](https://gemnasium.com/uq-eresearch/miletus.png)
](https://gemnasium.com/uq-eresearch/miletus)
[![Code Climate](https://codeclimate.com/badge.png)
](https://codeclimate.com/github/uq-eresearch/miletus)

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

Exporting to system script to run on port 8000:

    foreman export upstart /tmp -a miletus -u <miletus_user> -p 8000 -t ./foreman
    sudo cp /tmp/miletus* /etc/init/


## Acknowledgements

This app was produced as a result of an [ANDS-funded](http://www.ands.org.au/) project.
