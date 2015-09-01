# ISK - A web controlled slideshow system

System for centrally managing multiple screens running multiple presentation,
possibly sharing slides / groups of slides. Has simple online-editor and a
inkscape plugin for creating more complex slides.

## Known issues

 * Something might break the websocket-rails cross process syncronization resulting in the server not responding at all and requiring that the redis syncronization data is flushed. ./isk-server.rb force-restart does this for you. There are plans to migrate away from the websocket-rails library in the future.

## Runtime dependencies for production

 * Unix environment (linux or os x)
 * Imagemagick (developed using  6.8.5-5, other versions probably fine)
 * Nginx (or some other front-end webserver capable of proxying websocket connections)
 * memcached (1.4.5)
 * redis (2.6.10)
 * inkscape ( for external editing and converting some of the slides from .svg to .png)
 * postgresql (9.1)
 * rrdtool (1.4.7) for statistic collection and graph generation
 * iskdpy ( http://github.com/deram/iskdpy/ ) for running the slideshows

## Installation

To get the dev environment running you need to do the following:

1. install external dependencies
2. setup rvm and ruby
3. clone the isk git repository
4. install the rubygems needed for isk
5. create the database and initialize it

### Install the external dependencies

1. redis (debian pkg: redis-server)
2. memcached
2. Imagemagick (we use 'convert' and 'identify' imagemagick CLI tools)
3. postgresql + dev headers (postgresql postgresql-client libpg-dev)
4. inkscape
5. rrdtool, librrd + dev headers (rrdtool, librrd4, librrd-dev)
5. git
6. curl

### Rvm and rubies

It is recomended to use rvm for managing the ruby version and gems for isk development. See https://rvm.io/ for information for rvm.

To install rvm and the ruby version used by ISK:

1. \curl -sSL https://get.rvm.io | bash -s stable
2. source the rvm script file as instructed post-install
3. run "rvm requirements" and install packages as needed
4. "rvm install 2.1.1" to install ruby 2.1.1
5. "rvm use 2.1.1" and "rvm gemset create isk" to initialize the gemset for isk 

### Clone isk git repository

Use "git clone https://github.com/depili/isk isk" to clone the repository. With rvm installed and changing to the isk repository directory with "cd" rvm will automatically select the correct ruby and gemset.

### Install the rubygems needed for isk

ISK manages its rubygem dependencies with bundler. This makes installing the correct versions of needed rubygems easy, just execute "bundle install" in the isk directory and they will get installed.

### Create the database and initialize it

You need to copy the config/database.yml.example file to config/database.yml and edit it for your database configuration. You also need to create the database in your postgresql server.

After the database exists and the database.yml file points to it you can run:

1. rake db:schema:load
2. rake db:seed

This will initialize the database.

### Development: Start the server

Now you can start the local isk server instance with "rails s" and then navigate to http://localhost:3000/ with a browser. The default login for a new installation is username: admin password: admin.

You also need to start the background process for isk to generate the slide images. This is done by running "bin/delayed_job start".

For periodic tasks, like updating schedule slides there is a another background daemon you can start it with, "script/background_jobs.rb start".

### Production environment

It is highly recomended that you first generate new session cookie encryption keys ("rake secret") and update config/initializers/secret_token.rb, otherwise you will be vulnerable to session forgery.

For performance you will want to have nginx in front of ISK for serving static files (slide images mostly). Example configuration for nginx is available at config/nginx/isk-server. Consult that file and update as needed.

To run the ISK rails application in production mode set the RAILS_ENV environmental variable to 'production'. The script /isk-server.rb gives an example for starting/stopping all the needed components.

For the default production configuration the server will expect precompiled javascript/css files, to generate them you need to run "rake assets:precompile" on the production environment.

# Inkscape integration

For more complex slides the best (and just about only) tool available is inkscape (http://inkscape.org). ISK includes two plugins for inkscape at inkscape/, the isk-new and isk-output. You need to place them in the inkscape extensions directory.

## Background images

By default the base svg template for slides in ISK uses a relative path for the slide background image to keep the svg document sizes as low as possible. This unfortunately causes some issues with editing the slides in inkscape. In order for inkscape to find the background image you need to place it at backgrounds/empty.png relative to the directory you open the slide svg from. For example windows with firefox and "open link with..." needs the backgrounds at %TEMP%\backgrounds\

## isk-new extension

This extension is for quickly creating new slides within inkscape. The new slides will be ungrouped and hidden after creation.

This extension can be found in the extensions -> isk -> new menu item. Activating the extension first gives you a dialog asking for the URL to your ISK server and login details. In addition there is a field for the name for the slide. Activating the extension will replace the current open inkscape document with that of the new slide.

## isk-output extension

This extension is for sending the modifications made to a slide in inkscape back to the ISK server. It can be found at extensions -> publish to -> isk menu item. It has similiar fields for the servers url and login details as the isk-new extension. Activating the extension will read the slide id from the svg metadata and then push it to the ISK server replacing the existing slides image.

# Copyright

(c) Copyright 2013 Vesa-Pekka Palmu and Niko Vähäsarja.

Python plugins for Inkscape (c) Copyright 2015 Jarkko Räsänen.

* app/assets/images/wait.gif by Jarkko Räsänen, cat photo by Vesa-Pekka Palmu
* app/assets/images/isklogo_* by Jarkko Räsänen
* app/assets/images/display_error.svg by Vesa-Pekka Palmu
* app/assets/images/ui-* from jquery themeroller
* vendor/assets/javascripts/jquery-noty* from https://github.com/needim/noty with MIT license
* vendor/assets/javascripts/jquery.timer.js from http://jchavannes.com/jquery-timer see file for license

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
