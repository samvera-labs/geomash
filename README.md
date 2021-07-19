# Geomash

This is a geographic parsing library. It is designed to take subject and other text strings and return hierarchical data
along with coordinates for that string.

Beyond regular parsing to mapquest api, bing api, and google api, it currently also supports TGN and Geonames.

## Installation

Add this line to your application's Gemfile:

    gem 'geomash'

The following options can all be configured. If any of these are skipped, those resources won't be
available.

    tgn_enabled: <true or false>

    geonames API account: http://www.geonames.org/login

    Mapquest API key: http://developer.mapquest.com/web/products/open
    (NOTE: Recommended to skip this API key. I can't get reliable / good results. I've left in support just in case
    someone wants to still use it or can improve this).

    Bing API key: http://www.bingmapsportal.com
    (NOTE: Only semi-reliable as a geographic source. Recommended to skip this as well).

You will need to use the "geomash.yml.sample" file in the test/dummy/config folder as "geomash.yml" in whatever
application you plan to use this gem in. If you have directly checked out this repository, you will need to rename
"geomash.yml.sample" in that test/dummy/config folder to that "geomash.yml" and fill in the values you have. Then using
"rake" in the root of the checkout out directly will run unit tests.

## Usage

For the full parsing of a known geographic string (for example, "421 S Salisbury St, Raleigh, NC 27601" or
"Paris, France"), do that following:

    Geomash.parse('<string>')

For parsing of a LCSH subject (or similar) with geographic data located in the USA currently (such as
"Chicopee (Mass.) -- City Directories", "Women--Employment--Massachusetts--Holyoke", or "Palmer (Mass) - history"),
then pass in a second parameter of true to indicate an attempt to parse the string. NOTE: As the BPL is a USA based
organization, this is currently limited to USA locations. I'd be happy to work with an international entity to expand
this parsing. :)

    Geomash.parse('<string>', true)

Once that is complete, any coordinates returned will be near-exact location coordinates, otherwise that is left blank.
In addition, you may have received a tgn_id or a geonames_id (if those are configured and a match was found) along with
if those entries can completely replace the geographic data of the original string (for example,
"421 S Salisbury St, Raleigh, NC 27601" has a street address part that those hierarchies cannot duplicate).
To get the hierarchy, official coordinates, and other information, use the functions below:

    Geomash::Geonames.get_geonames_data(geonames_id)

    Geomash::TGN.get_tgn_data(tgn_id)

The are also several functions in the Geomash::Standardizer that may be useful. For instance, there is a geographic list
dedupper. So, if you have ['Saigon, Vietnam', 'Saigon (Vietnam)'], it can reduce that down to just ['Saigon, Vietnam'].
In addition, passing "true" as the second variable will eliminate less specific cases, or an array of
['Saigon, Vietnam', 'Saigon (Vietnam)', 'Vietnam'] would return the same end result.

Within Geomash::TownLookup, there is a town listing for Massachusetts that one can use by the following:

    Geomash::TownLookup.state_town_lookup('MA', <string to parse>)

Feel free to add your own location to this as a potential shortcut from hitting web APIs. Currently this only supports
TGN and needs to be refactored to support other needs.

## Locations of some code bits to use pieces of this:

For direct access to various geographic APIs, see Geomash::Parser.

Most of the LCSH functions are in: Geomash::LCSH.

Most of the Geonames functions are in: Geomash::Geonames

## Optional Caching

You can enable caching of your requests to reduce the amount of HTTP requests you make and avoid hitting query limits.
This is configured by the following YML setting:

    parser_cache_enabled:: <true or false>

Setting it to "true" just enables some code logic but will fail unless your application further configured it. For
example, to use Dalli caching, add the following to an initializer of an application using this gem:

    ::Geocoder.configure(:cache => Geomash::AutoexpireCacheDalli.new(Dalli::Client.new, 86400)) #86400 is the TTL

You would also have 'memcached' installed (sudo apt-get install memcached) on your machine. If you instead prefer to
use redis and have that installed, you can enable that by something like:

    ::Geocoder.configure(:cache => Geomash::AutoexpireCacheRedis.new(Redis.new, 86400)) #86400 is the TTL

## Optional Blazegraph integration

TGN can be slow and respond with bad json at times... so support for Blazegraph has been added and may work with
marmotta (untested). To enable this, first setup a blazegraph instance with TGN and AAT loaded into it. For instructions
on this, see:
[https://github.com/projecthydra-labs/geomash/wiki/Blazegraph-Setup](https://github.com/projecthydra-labs/geomash/wiki/Blazegraph-Setup)

Once setup, you need to update the Blazegraph section of the sample config file with the correct settings. The "url" refers
to the sparql endpoint (ie. http://localhost:8988/blazegraph/sparql). The contexts refer to whatever uri you loaded your
TGN and AAT vocabularies under. Examples might be: http://vocab.getty.edu/tgn and http://vocab.getty.edu/aat for those
two settings.

## Contributing

If you're working on PR for this project, create a feature branch off of `main`.

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

### Steps

1. As this is geared for our use case, let me know about your interest in this gem and how you would like it to function.
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
