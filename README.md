#GeniGames

Initial readme for the GeniGames project.

## Serving the project in development mode

This project uses [rake-pipeline](https://github.com/livingsocial/rake-pipeline) to dynamically
build itself from component files.

After cloning this repository, run `bundle install --binstubs` (optionally creating a new gemset
first with RVM)

To run the project on your local machine, run `bin/rackup` and visit (http://localhost:9292/) The
application at this url will be updated as you update its component files.

## Compiling a built version of the project

The assets which make up the application can be built into the `build/` directory by running
`bin/rakep build`. When this folder is ready to be published, you can copy replace the contents of
the `static` directory in the `deploy-dev` branch with the contents of the `build` directory. Commit
and push the resulting change to the `deploy-dev` branch.

Note that you will still need to use a Apache virtual host or other mechanism to proxy requests for
'/biologica/' to the Biologica server; see below.

## Serving the project using Apache

To serve this project locally, you can create a local Apache vhost:

Add the following to `/etc/hosts`

    127.0.0.1       gg.local

Add the following to '/etc/apache2/extra/httpd-vhosts.conf':

    <VirtualHost *:80>
      ServerName gg.local

      ProxyPass        /biologica/ http://geniverse.dev.concord.org/biologica/
      ProxyPassReverse /biologica/ http://geniverse.dev.concord.org/biologica/

      ProxyPass        /resources/ http://geniverse.dev.concord.org/resources/ retry=1
      ProxyPassReverse /resources/ http://geniverse.dev.concord.org/resources/

      # Rackup
      ProxyPass         / http://127.0.0.1:9292/ retry=1
      ProxyPassReverse  / http://127.0.0.1:9292/
    </VirtualHost>

Restart Apache:

    $ sudo apachectl restart

Visit the application at gg.local

## Ruby Gems, Guard and Coffeescript

The project's source code can be found in the `app/` directory, and is written in CoffeeScript. The
CoffeeScript is then compiled into JavaScript, concatenated, and placed into the file
`build/js/app.js`.


    rvm use ruby-1.9.2-p290
    rvm gemset create genigames
    echo "rvm use ruby-1.9.2-p290@genigames" > .rvmrc
    cd .

    gem install bundler
    bundle install --binstubs

    bin/guard