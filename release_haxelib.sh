#!/bin/sh
rm -f echo.zip
zip -r echo.zip echo *.html *.md *.json *.hxml run.n
haxelib submit echo.zip $HAXELIB_PWD --always
