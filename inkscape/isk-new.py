# coding=utf-8

# ISK - A web controllable slideshow system
#
# Inkscape plugin for logging in to ISK and creating a new slide
#
# Originally work of Vesa-Pekka Palmu
# This is an Python rewrite of isk-new.rb
#
# Author::    Jarkko Räsänen
# Copyright:: Copyright (c) 2015 Jarkko Räsänen
# License::   Licensed under GPL v3, see LICENSE.md

import urllib
import urllib2
import cookielib
import sys
import json
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

#print username
#print password
#print slidename
#print hostname
#print svg_file

cookiejar = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookiejar))

# Login info
payload = {
	"username": username,
	"password": password
}

# Let's make the login request ready.
data = urllib.urlencode(payload)
req = urllib2.Request(hostname+"/login", data)

# For login purpose, CookieProcessor saves the cookie to the opener after this.

resp = opener.open(req)
#except:
#	print "Error while logging into ISK, aborting"
#	raise SystemExit

# Build the data for the POST request to create a new slide
payload = {
	"slide[name]": slidename,
	"create_type": "empty_file"
}
data = urllib.urlencode(payload)
req = urllib2.Request(hostname+"/slides?format=json", data)
resp = opener.open(req)

# Determine slide ID out of the HTML garble, it's there, trust me.
slide_id_response = json.loads(resp.read())
slide_id = slide_id_response["slide_id"]


req = urllib2.Request(hostname+"/slides/%s/svg_data"%slide_id)
resp = opener.open(req)

sys.stdout.write(resp.read())
