# coding=utf-8

# ISK - A web controllable slideshow system
#
# Inkscape plugin for logging in to ISK and creating a new slide
#
# Originally work of Vesa-Pekka Palmu
# This is an Python rewrite of isk-new.rb
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

# Let's make the login request ready.
data = urllib.urlencode(payload)
req = urllib2.Request(args.hostname+"/login", data)

# For login purpose, CookieProcessor saves the cookie to the opener after this.
try:
	resp = opener.open(req)
except:
	print "Error while logging into ISK, aborting"
	raise SystemExit

# Build the data for the POST request to create a new slide
payload = {
	"slide[name]": args.slidename,
	"create_type": "empty_file"
}
data = urllib.urlencode(payload)
req = urllib2.Request(args.hostname+"/slides", data)
resp = opener.open(req)

# Determine slide ID out of the HTML garble, it's there, trust me.
slide_id = resp.read().split("/slides/")[5].split("/")[0]

req = urllib2.Request(args.hostname+"/slides/%s/svg_data"%slide_id)
resp = opener.open(req)

sys.stdout.write(resp.read())
