
[![Build Status](https://travis-ci.org/SpeciesFileGroup/taxonifi.svg?branch=master)](https://travis-ci.org/SpeciesFileGroup/taxonifi)



# taxonifi
There will always be "legacy" taxonomic data that needs shuffling around. The taxonifi gem is a suite of general purpose tools that act as a middle layer for data-conversion purposes (e.g. migrating legacy taxonomic databases).  Its first application was to convert DwC-style data downloaded from EoL into a Species File.  The code is well documented in unit tests, poke around to see if it might be useful.  In particular, if you've considered building a collection of regular expressions particular to biodiversity data look at the Tokens code and related tests. 

Overall, the goal is to provide well documented (and unit-tested) coded that is broadly useful, and vanilla enough to encourage other to fork and hack on their own.

# Source
Source is available at https://github.com/SpeciesFile/taxonifi .  The rdoc API is also viewable at http://taxonifi.speciesfile.org , (though those docs may lag behind commits to github).

# What's next?
Before you jump on board you should also check out similar code from the Global Names team at https://github.com/GlobalNamesArchitecture. Future integration and merging of shared functionality is planned. 

Taxonifi is presently coded for convience, not speed (though it's not necessarily slow). It assumes that conversion processes are typically one-offs that can afford to run over a longer period of time (read minutes rather than seconds). Reading, and fully parsing into objects, around 25k rows of nomenclature (class to species, inc. author year, = ~45k names) in to memory as Taxonifi objects benchmarks at around 2 minutes. 

# Getting started
taxonifi is coded for Ruby 2.6.5, 0.4.0 works on 1.9.4.

To install:

```
gem install taxonifi
```

In your script:

```
require 'taxonifi'
```

Use
===

Quick start
-----------

Write some code:

```
require 'taxonifi'

headers = ["a", "B", "c"]
csv_string = CSV.generate() do |csv|
  csv <<  @headers
  csv << %w{a b c}
end

csv = CSV.parse(csv_string, {headers: true, header_converters: :downcase})

# Taxonifi can create generic hierachical collections based on column headers
c = Taxonifi::Lumper.create_hierarchical_collection(csv, %w{a b c})    # => a Taxonifi::Model::Collection 
c.collection.first               # => Taxonifi::Model::GenericObject
c.collection.first.name          # => "a" 
c.collection.last.name           # => "c" 
c.collection.last.parent.name    # => "b" 
c.collection.first.row_number    # => 0
c.collection.first.rank          # => "a"

# Header order is important:
c = Taxonifi::Lumper.create_hierarchical_collection(csv, %w{c a b})    # => a Taxonifi::Model::Collection 
c.collection.first.name          # => "c" 
c.collection.last.rank           # => "c" 
c.collection.last.name           # => "b" 
c.collection.last.parent.name    # => "a" 

# Collections of GenericObjects (and some other Taxonifi::Collection based objects like TaxonifiNameCollection) only include
# unique names, i.e. if a name has a shared parent lineage only the name itself is created, not its parents. 
# For example, for:
#  a b   c 
#  a d   nil
#  b nil d
# The collection consists of objects with names a,b,c,d,b,d respectively.
# This makes it very useful for handling not only nomenclatural but other nested data as well.
```

There are collections of specific types (e.g. taxonomic names, geographic names):

```
string = CSV.generate() do |csv|
  csv << %w{family genus species author_year}
  csv << ["Fooidae", "Foo", "bar", "Smith, 1854"]
  csv << ["Fooidae", "Foo", "foo", "(Smith, 1854)"]
end

csv = CSV.parse(string, {headers: true})

nc = Taxonifi::Lumper.create_name_collection(:csv => csv)  # => Taxonifi::Model::NameCollection

nc.collection.first                                # => Taxonifi::Model::Name 
nc.collection.first.name                           # => "Fooidae"
nc.collection.first.rank                           # => "family" 
nc.collection.first.year                           # =>  nil
nc.collection.first.author                         # => []
nc.collection.last.rank                            # => "species" 
nc.collection.last.name                            # => "foo" 
nc.collection.last.author.first.last_name          # =>  "Smith"
nc.collection.last.year                            # =>  "1854"
```

Parent/child style nomenclature is also parseable.

There are *lots* more examples of code use in the test suite.

# Export/conversion

The following is an example that translates a DwC style input format as exported by EOL into tables importable to SpeciesFile.  The input file is has id, parent, child, vernacular, synonym columns.  Data are exported by default to a the users home folder in a taxonifi directory.  The export creates 6 tables that can be imported into Species File directly.

```
require 'taxonifi'
file = File.expand_path(File.join(File.dirname(__FILE__), 'file_fixtures/Lygaeoidea-csv.tsv'))

csv = CSV.read(file,
  headers: true,
  col_sep: "\t",
  header_converters: :downcase
)

nc = Taxonifi::Lumper::Lumps::ParentChildNameCollection.name_collection(csv)
e = Taxonifi::Export::SpeciesFile.new(:nc => nc, :authorized_user_id => 1)
e.export
```

You should be able to relativley quickly use the export framework to code new output formats.

Reading files 
-------------

taxonifi feeds on Ruby's CSV. read your files with header true, and downcased, e.g.:

```
csv = CSV.read('input/my_data.tab',
              headers: true,
              header_converters: :downcase,
              col_sep: "\t")
```

# Code organization

```
test                # unit tests, quite a few of them
lib                 # the main libraries
lib/assessor        # libraries to assess the properties of incoming data
lib/export          # export wrappers 
lib/export/format   # one module for each export type
lib/lumper          # code that builds Taxonifi objects 
lib/model           # Taxonifi objects
lib/splitter        # a parser/lexer/token suite for breaking down data 
```

# Contributing to taxonifi

(this is generic)
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Write unit test for your code.  Changes are good, just as long as tests run clean.  
* All pull requests should test clean.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

# About

taxonifi is coded by Matt Yoder in consultation with the Species File Group at University of Illinois.

# Copyright

Copyright (c) 2012-2020 Illinois Natural History Survey. See LICENSE.txt for
further details.

[1]: https://secure.travis-ci.org/SpeciesFileGroup/taxonifi.png?branch=master
[2]: https://travis-ci.org/SpeciesFileGroup/taxonifi.svg?branch=master



