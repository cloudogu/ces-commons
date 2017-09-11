# CES-COMMONS

##  Scripts

**/etc/ces/**

- functions.sh

**/usr/local/bin/**

* ipchange.sh
* ssl.sh 

## Requirements
* git
* ruby (tested with 2.3.2) <br>
```sudo apt-get install ruby-full```
* fpm (tested with 1.9.2) <br>
```gem install fpm```

## Add Scripts 

* inside resources directory the file structure is the same as on the host system. Add new files there! Make sure you the scripts are executable

## Release

* increase the version <br>
 ```Makefile > PKG_VERSION=x.x.x```
* execute make <br>
 ```make```





 