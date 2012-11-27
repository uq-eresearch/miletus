# Miletus

[![Build Status](https://secure.travis-ci.org/uq-eresearch/miletus.png)
](http://travis-ci.org/uq-eresearch/miletus)
[![Dependency Status](https://gemnasium.com/uq-eresearch/miletus.png)
](https://gemnasium.com/uq-eresearch/miletus)
[![Code Climate](https://codeclimate.com/badge.png)
](https://codeclimate.com/github/uq-eresearch/miletus)

## Overview

Miletus is an application for aggregating and merging collection metadata
records at an institutional level. If you have never heard of [RIF-CS] and
[ANDS], then likely it's not for you.

Its most common use case is to harvest records from systems outputing collection
metadata, merge together records describing the same concept (eg. a person) and
to look up further information from institutional systems storing HR and funding
data.

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

## Architecture

The harvest and output sections are loosely coupled to the merge process, and
are persisted separatedly. The result is that changes will take time to flow
through the system, but the output performance should be independant of the time
it takes to merge facets.

An example of the sequence for OAI-PMH RIF-CS records is as follows:

<!-- Graphviz source (turned into boxart by graph-easy):
digraph miletus {
  node[shape=box];
  input_record [label=" Miletus::Harvest::OAIPMH::RIFCS::Record "];
  rifcs_record_observer [label=" RifcsRecordObserver "];
  facet [label=" Miletus::Merge::Facet "];
  concept [label=" Miletus::Merge::Concept "];
  oaipmh_output_observer [label=" OaipmhOutputObserver "];
  output_record [label=" Miletus::Output::OAIPMH::Record "];
  input_record -> rifcs_record_observer [ label=" :after_save " ];
  rifcs_record_observer -> facet [ label=" :create" ];
  facet -> concept [ label=" :reindex " ];
  concept -> oaipmh_output_observer [ label=" :after_save " ];
  oaipmh_output_observer -> output_record [ label=" :create " ];
}
-->

```
┌─────────────────────────────────────────┐
│ Miletus::Harvest::OAIPMH::RIFCS::Record │
└─────────────────────────────────────────┘
  │
  │ :after_save
  ▼
┌─────────────────────────────────────────┐
│           RifcsRecordObserver           │
└─────────────────────────────────────────┘
  │
  │ :create
  ▼
┌─────────────────────────────────────────┐
│          Miletus::Merge::Facet          │
└─────────────────────────────────────────┘
  │
  │ :reindex
  ▼
┌─────────────────────────────────────────┐
│         Miletus::Merge::Concept         │
└─────────────────────────────────────────┘
  │
  │ :after_save
  ▼
┌─────────────────────────────────────────┐
│          OaipmhOutputObserver           │
└─────────────────────────────────────────┘
  │
  │ :create
  ▼
┌─────────────────────────────────────────┐
│     Miletus::Output::OAIPMH::Record     │
└─────────────────────────────────────────┘

```

## Acknowledgements

This app was produced as a result of an [ANDS-funded](http://www.ands.org.au/)
project.

[ANDS]: http://www.ands.org.au/
[RIF-CS]: http://services.ands.org.au/documentation/rifcs/guidelines/rif-cs.html

