# Bplgeo

This is a geographic parsing library. Beyond regular parsing to mapquest, bing, and google apis, it also can parse
subject strings and query against TGN.

As I'm short for time, full documentation and code cleanup/standardization will happen on Friday, February 21st.

## Installation

Add this line to your application's Gemfile:

    gem 'bpl_geo', :git=>'https://github.com/boston-library/Bplgeo.git'

You will need keys for the mapquest and Bing APIs along with TGN login credentials.

    For mapquest: http://developer.mapquest.com/web/products/open

    For bing: http://www.bingmapsportal.com

(These dependencies will hopefully be reduced very soon).

You will need to use the "bplgeo.yml.sample" file in the test/dummy/config folder as "bplgeo.yml" in whatever
application you plan to use this gem in.

## Usage

For the full parsing of a known geographic string, do:

    Bplgeo.parse('<string>')

For parsing of a LCSH subject (or similar) with geographic data do:

    Bplgeo.parse('<string>', true)

For non-LCSH parsing, all of that is in the Bplgeo::Parser functions.

The are also several functions in the Bplgeo::Standardizer that may be useful. For instance, there is a geographic list
dedupper. So, if you have ['Saigon, Vietnam', 'Saigon (Vietnam)'], it can reduce that down to just ['Saigon, Vietnam'].
In addition, passing "true" as the second variable will eliminate less specific cases, or an array of
['Saigon, Vietnam', 'Saigon (Vietnam)', 'Vietnam'] would return the same end result.

Most of the LCSH functions are in: Bplgeo::LCSH.

## Contributing

1. As this is geared for our use case, let me know about your interest in this gem and how you would like it to function.
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request