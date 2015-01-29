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
# Copyright:: Copyright (c) 2015 Jarkko Räsänen
# License::   Licensed under GPL v3, see LICENSE.md

import urllib
import urllib2
import cookielib
import sys
from xml.dom import minidom
from sys import argv

value = 1
username = ""
password = ""
slidename = ""
hostname = ""
svg_file = ""

while 1:
	if value >= len(argv):
		break
	if argv[value].split("=")[0] == "--username":
		username = argv[value].split("=")[1]
		value = value+1
	
	elif argv[value].split("=")[0] == "--password":
		password = argv[value].split("=")[1]
		value = value+1
		
	elif argv[value].split("=")[0] == "--slidename":
		slidename = argv[value].split("=")[1]
		value = value+1
	
	elif argv[value].split("=")[0] == "--iskhost":
		hostname = argv[value].split("=")[1]
		value = value+1
		
	elif argv[value].split("=")[0] == "--id":
		value = value+1
		
	elif ".svg" in argv[value]:
		svg_file = argv[value]
		value = value+1
	else:
		#print "wat is dis"
		break

try:
	if "username" != "":
		pass
	if "password" != "":
		pass
	if "slidename" != "":
		pass
	if "hostname" != "":
		pass
	if "svg_file" != "":
		pass
	else:
		#print "Some parameter(s) is missing!"
		raise Exception
except:
	#print "Missing mandatory arguments!"
	raise SystemExit

cookiejar = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookiejar))

# Login info
payload = {
	"username": username,
	"password": password
}

# Let's make the request ready.
data = urllib.urlencode(payload)
req = urllib2.Request(hostname+"/login", data)

# For login purpose, CookieProcessor saves the cookie to the opener after this.
resp = opener.open(req)

# Open the SVG file for manipulation.
xmldoc = minidom.parse(svg_file)

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
req = urllib2.Request(hostname+"/slides/%s/svg_data"%id, data)
resp = opener.open(req)

sys.stdout.write(newsvg)
