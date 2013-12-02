#GeniGames

Initial readme for the GeniGames project.

## Initial setup of development environment

    # assuming you have installed RVM and Ruby 1.9.3:
    rvm --rvmrc --create use 1.9.3@genigames
    gem install bundler
    bundle install --binstubs

Now setup an Apache vhost as below. This is the easiest way to proxy the required backend services
so that they can be accessed by the webapp. (Unfortunately, we haven't been able to proxy using
Rack middleware, as `rack-streaming-proxy` causes a mysterious error in which the Biologica GWT
servlet claims not have received the required `X-GWT-Permutation` header.)

## Serving the project in development mode

This project is built from component files in `app/` using
[rake-pipeline](https://github.com/livingsocial/rake-pipeline). This tool should have been installed
by the `bundle install` step above.

To run the project on your local machine, run `bin/rakep server` in the root of the repository and
visit [http://gg.local/](http://gg.local/) in a web browser. This development server is built
continuously, so to see the change after making a modification to a source file, you just reload
your browser.

## Compiling a built version of the project

The assets which make up the application can be built into the `build/` directory by running
`bin/rakep build`. If you have created a vhost with your `build/` directory as its docroot, then
you can visit the that server in a web browser.

If you are happy with the version in `build`, you can run `./build-and-deploy.sh [server]` where
[server] is one of 'dev' or 'production'. (Actually, at the time of this writing, only 'dev' is
valid, but 'production' should work eventually.) This checks that your current branch has no
uncommitted or unstaged changes and replaces the contents of the `static` directory in the `deploy-
dev` (or `deploy-production`) branch with the contents of the `build` directory, makes a commit
in the deploy branch noting the current SHA of the source branch, pushes the deploy branch, and, if
the push is successful, pulls the branch into the appropriate place on the appropriate server.

For `dev` this server is [http://genigames.dev.concord.org/](http://genigames.dev.concord.org/)

You can of course perform these same steps by hand, or checkout an earlier version of the deploy
branch if desired.

## Serving the project using Apache

To serve this project locally, you can create a local Apache vhosts to proxy the needed resources.
In order to allow the portal's login cookie to be set correctly, the local server name should end
with '.concord.org' (this will work fine, as the hosts file will be consulted first).

The server at `http://gg.local.concord.org/` is for proxying the development server provided by
rake-pipeline. The server at `http://gg-build.local.concord.org` is for viewing and verifying the
latest statically-built version compiled by rake-pipeline.

Add the following to `/etc/hosts`:

    127.0.0.1       gg.local.concord.org
    127.0.0.1       gg-static.local.concord.org

(Remember to use real tabs to separate the IP address and the name.)

Add the following to '/etc/apache2/extra/httpd-vhosts.conf':

    <VirtualHost *:80>
      ServerName gg.local.concord.org

      ProxyPass        /biologica/ http://geniverse.dev.concord.org/biologica/
      ProxyPassReverse /biologica/ http://geniverse.dev.concord.org/biologica/

      ProxyPass        /portal/ http://geniverse.dev.concord.org/portal/
      ProxyPassReverse /portal/ http://geniverse.dev.concord.org/portal/

      ProxyPass        /resources/ http://geniverse.dev.concord.org/resources/ retry=1
      ProxyPassReverse /resources/ http://geniverse.dev.concord.org/resources/

      ProxyPass        /couchdb http://genigames.dev.concord.org/couchdb retry=1
      ProxyPassReverse /couchdb http://genigames.dev.concord.org/couchdb

      # Rackup
      ProxyPass         / http://127.0.0.1:9292/ retry=1
      ProxyPassReverse  / http://127.0.0.1:9292/
    </VirtualHost>

    <VirtualHost *:80>
      ServerName gg-static.local.concord.org

      DocumentRoot "/path/to/build/folder"
      <Directory "/path/to/build/folder">
         AllowOverride all
         Options -MultiViews
         Order allow,deny
         Allow from all
         DirectoryIndex index.html
      </Directory>

      ProxyPass        /biologica/ http://geniverse.dev.concord.org/biologica/
      ProxyPassReverse /biologica/ http://geniverse.dev.concord.org/biologica/

      ProxyPass        /portal/ http://geniverse.dev.concord.org/portal/
      ProxyPassReverse /portal/ http://geniverse.dev.concord.org/portal/

      ProxyPass        /resources/ http://geniverse.dev.concord.org/resources/ retry=1
      ProxyPassReverse /resources/ http://geniverse.dev.concord.org/resources/
    </VirtualHost>

Restart Apache:

    $ sudo apachectl restart

## Program structure

The project's source code can be found in the `app/src` directory, and is written in CoffeeScript. The
CoffeeScript is then compiled into JavaScript, concatenated, and placed into the file
`build/js/app.js`.

The project's stylesheets can be found in the `app/style` directory, and are written in Stylus. They
are then compiled into CSS, concatenated, and placed into the file `build/css/genigames.css`.

Note that regular .css files can also go into the /style directory, and will be concatenated with
everything else. Note also that vanilla CSS can be mixed in freely inside .styl files.

## Sublime settings

A Stylus syntax highlighter for Sublime (and TextMate, AFAIK) can be found at
  https://raw.github.com/Wizek/stylus/master/editors/Stylus.tmbundle/Syntaxes/Stylus.tmLanguage

