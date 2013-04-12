# Kubrick

A movie database and browser using ncurses.

The gem comes with a database of movies that have won Academy Awards, or have been nominated
for the same, or are in various lists of best or greatest movies. The list is not comprehensive, 
it contains about 2 to 3 thousand movies. The data on directors, producers etc has been culled
from wikipedia. It also contains flags for whether the movie won or was nominated for best picture,
best actor, best director, best cinematography, thus enabling various kinds of queries.

It is intended that one can track movies one has watched using this list.

I use the wikipedia URL as a unique key to track whether I already have a movie in the database.
If you want any movie added, please submit the wiki URL. Wikipedia forwards URL's so there can
still be duplicates despite all my efforts to remove them.

## Installation

    $ gem install kubrick

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
