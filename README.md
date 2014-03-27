# Bplgeo

This is a geographic parsing library. Beyond regular parsing to mapquest api, bing api, and google api, it also can parse
subject strings and query against TGN and geonames.

## Installation

Add this line to your application's Gemfile:

    gem 'bpl_geo', :git=>'https://github.com/boston-library/Bplgeo.git'

The following needs to be obtained for optimal configuration. If any of these are skipped, those resources won't be available.

    Bing API key: http://www.bingmapsportal.com

    geonames API account: http://www.geonames.org/login

    TGN API account: ???? (believe it will be available free soon)

    Mapquest API key: http://developer.mapquest.com/web/products/open
    (NOTE: Recommended to skip this API key. I can't get reliable / good results. I've left in support just in case
    someone wants to still use it or can improve this).

You will need to use the "bplgeo.yml.sample" file in the test/dummy/config folder as "bplgeo.yml" in whatever
application you plan to use this gem in. If you have directly checked out this repository, you will need to rename
"bplgeo.yml.sample" in that test/dummy/config folder to that "bplgeo.yml" and fill in the values you have. Then using
"rake" in the root of the checkout out directly will run unit tests.

## Usage

For the full parsing of a known geographic string, do:

    Bplgeo.parse('<string>')

For parsing of a LCSH subject (or similar) with geographic data do:

    Bplgeo.parse('<string>', true)

Once that is complete, any coordinates returned will be near-exact location coordinates, otherwise that is left blank.
<<Talk about keeping original string here>>. In addition, you may have received a tgn_id or a geonames_id (if those
are configured and a match was found). To get the hierarchy, official coordinates, and other information, use the
functions below:

    Bplgeo::Geonames.get_geonames_data(geonames_id)

    Bplgeo::Geonames.get_tgn_data(tgn_id)

The are also several functions in the Bplgeo::Standardizer that may be useful. For instance, there is a geographic list
dedupper. So, if you have ['Saigon, Vietnam', 'Saigon (Vietnam)'], it can reduce that down to just ['Saigon, Vietnam'].
In addition, passing "true" as the second variable will eliminate less specific cases, or an array of
['Saigon, Vietnam', 'Saigon (Vietnam)', 'Vietnam'] would return the same end result.

Within Bplgeo::TownLookup, there is a town listing for Massachusetts that one can use by the following:

    Bplgeo::TownLookup.state_town_lookup('MA', <string to parse>)

Feel free to add your own location to this as a potential shortcut from hitting web APIs. Currently this only supports
TGN and needs to be refactored to support other needs.

## Locations of some code bits to use pieces of this:

For direct access to various geographic APIs, see Bplgeo::Parser.

Most of the LCSH functions are in: Bplgeo::LCSH.

Most of the Geonames functions are in: Bplgeo::Geonames

## Contributing

1. As this is geared for our use case, let me know about your interest in this gem and how you would like it to function.
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request