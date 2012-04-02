#GeniGames

Initial readme for the GeniGames project.

## Serving the project using Apache

To serve this project locally, you can create a local Apache vhost:

Add the following to '/etc/hosts'

    127.0.0.1       gg.local

Add the following to '/etc/apache2/extra/httpd-vhosts.conf':

     <VirtualHost *:80>
       ServerName gg.local
       DocumentRoot /path/to/genigames-test-ember
       <Directory /path/to/genigames-test-ember>
          AllowOverride all
          Options -MultiViews
       </Directory>
     
       ProxyPass        /biologica/ http://geniverse.dev.concord.org/biologica/
       ProxyPassReverse /biologica/ http://geniverse.dev.concord.org/biologica/
  
       ProxyPass        /resources/ http://geniverse.dev.concord.org/resources/ retry=1
       ProxyPassReverse /resources/ http://geniverse.dev.concord.org/resources/  
     </VirtualHost>

Restart Apache:

    $ sudo apachectl restart
   
Visit the application at gg.local

## Ruby Gems, Guard and Coffeescript

The project's source code can be found in the src/ directory, and is written in CoffeeScript. The CoffeeScript is then compiled into JavaScript
and placed into the js/ directory.

Set up Guard to automatically watch for all .coffee files in src/ and compile them into .js files in js/

    rvm use ruby-1.9.2-p290
    rvm gemset create genigames
    echo "rvm use ruby-1.9.2-p290@genigames" > .rvmrc
    cd .
    
    gem install bundler
    bundle install --binstubs
    
    bin/guard