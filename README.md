# Miletus

[![Build Status](https://secure.travis-ci.org/uq-eresearch/miletus.png)
](http://travis-ci.org/uq-eresearch/miletus)
[![Dependency Status](https://gemnasium.com/uq-eresearch/miletus.png)
](https://gemnasium.com/uq-eresearch/miletus)
[![Code Climate](https://codeclimate.com/badge.png)
](https://codeclimate.com/github/uq-eresearch/miletus)
[YARD Docs](http://rdoc.info/github/uq-eresearch/miletus)

## Overview

Miletus is an application for aggregating and merging collection metadata
records at an institutional level. If you have never heard of [RIF-CS] and
[ANDS], then likely it's not for you.

Its most common use case is to harvest records from systems outputing collection
metadata, merge together records describing the same concept (eg. a person) and
to look up further information from institutional systems storing HR and funding
data.

### Features

Miletus supports the following harvest methods:

 * OAIPMH
   * RIF-CS
 * Direct document fetching
   * RDC Atom
   * RIF-CS
 * Atom feeds (via rel="alternate" links)
   * RDC Atom
   * RIF-CS

Output feeds are available in:

 * OAIPMH
   * RIF-CS (rif)
   * Dublin Core (oai_dc)
 * Atom
   * RIF-CS (application/rifcs+xml)

The web interface is also heavily sprinkled with RDFa for good search engine optimisation.

Static content can be updated through the admin interface using Markdown.

## Usage

The database connection is provided by the `DATABASE_URL` environment variable.

Take advantage of Foreman's `.env` file:

    echo "DATABASE_URL=postgres:///my_db" > .env

To run Rake tasks adhoc:

    foreman run rake jobs:work

Or to run the whole lot:

    foreman start

Exporting to system script to run on port 8000, managed by bluepill:

    sudo gem install bluepill
    foreman export bluepill /tmp -a miletus -u <miletus_user> -p 8000 -t ./foreman
    sudo cp /tmp/miletus.pill /etc/bluepill/miletus.pill
    sudo cp ./foreman/miletus-bluepill.init /etc/init.d/miletus
    sudo service miletus start

To configure feeds and lookup services once running, go to `/admin/`. The default username is `admin@example.com`, and password is `password`. *You are strongly advised to change both of these after you log in.*

The OAI-PMH output feed can be found at `/oai`. The Atom feed can be found at `/atom`.

### Production & SSL

Miletus will enforce the use of HTTPS for admin logins in a production
environments (ie. `RAILS_ENV=production`). If you need to run in an environment
where HTTPS is not available, you run with `DISABLE_HTTPS=1` in the environment
to disable this check.

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

This project is supported by the Australian National Data Service
([ANDS](http://www.ands.org.au/)). ANDS is supported by the Australian
Government through the National Collaborative Research Infrastructure
Strategy Program and the Education Investment Fund (EIF) Super Science
Initiative.

[ANDS]: http://www.ands.org.au/
[RIF-CS]: http://services.ands.org.au/documentation/rifcs/guidelines/rif-cs.html
