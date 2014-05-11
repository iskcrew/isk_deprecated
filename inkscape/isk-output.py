# coding=utf-8

# ISK - A web controllable slideshow system
#
# ISK export plugin for inkscape, allows for one-click
# exporting the slide back to the server
#
# Originally work of Vesa-Pekka Palmu
# This is an Python rewrite of isk-output.rb
#
# Author::    Jarkko Räsänen
# Copyright:: Copyright (c) 2014 Jarkko Räsänen
# License::   Licensed under GPL v3, see LICENSE.md

import argparse
import urllib
import urllib2
import cookielib
import sys
from xml.dom import minidom

parser = argparse.ArgumentParser(add_help=True)

parser.add_argument("-u", "--username", dest="username", help="Specify username for ISK login")
parser.add_argument("-p", "--password", dest="password", help="Specify password for ISK login")
parser.add_argument("-n", "--slidename", dest="slidename", help="Specify slidename")
parser.add_argument("-i", "--iskhost", dest="hostname", help="Specify ISK server hostname")
parser.add_argument("-e", "--id", dest="object_id", help="Specify object ID")
parser.add_argument("svg_file", help="Name of the file containing SVG data")
args = parser.parse_args()

cookiejar = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookiejar))

# Login info
payload = {
	"username": args.username,
	"password": args.password
}

# Let's make the request ready.
data = urllib.urlencode(payload)
req = urllib2.Request(args.hostname+"/login", data)

# For login purpose, CookieProcessor saves the cookie to the opener after this.
resp = opener.open(req)

# Open the SVG file for manipulation.
xmldoc = minidom.parse(args.svg_file)

# Let's get all necessary tags and pieces...
val = xmldoc.getElementsByTagName("image")
id = str(xmldoc.getElementsByTagName("metadata")[0].childNodes[0].toxml().split("!")[0])

# And search the right one which we are going to replace with another one (relative path)
for i in val:
	if "backgrounds" in i.attributes["xlink:href"].value:
		i.attributes["xlink:href"].value = "backgrounds/empty.png"


# Let's get the newly manipulated data, and dump it to ISK server and to STDOUT as required by Inkscape.
newsvg = xmldoc.toxml("UTF-8")

payload = {
	"svg": newsvg
}

data = urllib.urlencode(payload)
req = urllib2.Request(args.hostname+"/slides/%s/svg_data"%id, data)
resp = opener.open(req)

sys.stdout.write(newsvg)
