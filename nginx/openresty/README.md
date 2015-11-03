# fpm-recipes

This is a collection of recipes for [fpm-cookery](https://github.com/bernd/fpm-cookery).
This is an extract from https://github.com/rkt-package-build/fpm-recipes

## Prepare a build server

    $ apt-get install curl git ruby-dev rubygems
    $ gem install fpm-cookery

## Usage

    $ cd openresty
    $ fpm-cook
      [watching the output]
    $ sudo dpkg -i pkg/*.deb
    $ fpm-cook clean
