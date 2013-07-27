ISK - A web controlled slideshow system
=======================================

System for centrally managing multiple screens running multiple presentation,
possibly sharing slides / groups of slides. Has simple online-editor and a
inkscape plugin for creating more complex slides.

External dependencies
---------------------

Imagemagick (developed using  6.8.5-5, other versions probably fine)
Nginx (or some other front-end webserver capable of proxying websocket connections)
librsvg & rsvg-convert (developed with 2.36.4)
memcached (1.4.5)
redis (2.6.10)

inkscape for external editing
iskdpy ( http://github.com/deram/iskdpy/ ) for running the slideshows

Installation
------------

Installation instructions to come.

Copyright
---------
(c) Copyright 2013 Vesa-Pekka Palmu and Niko Vähäsarja.

License
-------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
