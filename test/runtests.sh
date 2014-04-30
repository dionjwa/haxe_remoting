#! /usr/bin/env sh
mkdir -p build
echo $1
echo $2
haxe -cmd "node build/nodejs_test.js" $1 $2 test/travis.hxml
