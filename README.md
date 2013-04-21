# Kubrick

A movie database and browser using ncurses.

The gem comes with a database of movies that have won Academy Awards, or have
been nominated for the same, or are in various lists of best or greatest
movies. The list contains about 2 to 3 thousand movies. The data on directors,
producers etc has been culled from wikipedia. It also contains flags for
whether the movie won or was nominated for best picture, best actor, best
director, best cinematography, best foreign movie, thus enabling various kinds of queries.

e.g. search for movies that won a best picture and best director and best cinematography.

It is intended that one can track movies one has watched using this list, or look up to see
movies worth watching. This is not a database of all movies, and focuses on award winning movies,
or movies of great directors worldwide.

I use the wikipedia URL as a unique key to track whether I already have a movie in the database.
If you want any movie added, please submit the wiki URL. Wikipedia forwards URL's so there can
still be duplicates despite all my efforts to remove them.

The list is current as per 2013-04-12.

The data itself resides in an sqlite3 database, but for the purposes of versioning it, is in a 
dump format (text) and needs to be imported. I would have liked to zip the text file to reduce size
but am not sure how that will play with github, or where I could store it.

The data is extracted from wikipedia using nokogiri. I also store the copy of the wiki page on my disk,
and in a table, so i can view it using `w3m` and don't need to fetch repeatedly for processing.
I am not including that data since the size of the DB will go into many hundred MB.

## Installation

    $ gem install kubrick

    Dependencies for browsing: sqlite3

    In case I add programs so the user can add to his own database, then for those programs,
    nokogiri is required to parse the wiki page.

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
