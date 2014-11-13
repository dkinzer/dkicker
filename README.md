Drupal Kicker
=============

![The Gods invoke Devi][gods]

Drupal Kicker is useful for setting up  Drupal projects that deploy simply by
executing  `git push` from a development repository to a production repository.

I developed this project to use as a demo for my Drupaldelphia 2014
presentation entitled "[Using Git to Manage Deployments/Updates][1]"

This project is not production ready.  It is simply a demonstration.

##Use:##

###Step 1:###
On your production environment clone your project repository. Then prepare your
project to run as a repository server. (Note that the project repository
includes only the Drupal sites folder i.e. the part of a Drupal project that is
different from core.)

```shell
git clone project $REPO_URL
cd project
make prepare
```

###Step 2:###
The deploy script can be used to deploy to your local web server.
Copy config/env/local.example to config/env/local and edit for your environment.

```shell
make prepare-local
make local
```

After running `make prepare-local`, any commit you make will also call `make local`

On your development server work as usual then push to production.


##Results:##
Currently a push to production results in the following project directory structure

```
website -> project/build/live

project/build/live -> project/build/live -> ./drupal-[VERSION]

projec/build/drupal-[VERSION]/
|-- ...
|-- sites -> ../sites/5a4c5c2f26e1d79acbc723f001924d8b64a70fc1
    .
    |-- all/default/settings.php -> ../../../settings.php


project/build/sites/
|-- 005099a7d67c74acc93ad03cb7a47eafdc85622e
|-- 18c3576e7faf07eebbe948b6ded03bced96ca676
|-- 19d904f876f891f2db6769858da8c956cb2f1942
|-- 3adeaccb04af988b9e69b1c38ebb763da20227a1
|-- ...

```
And, the process completes with a call to

`drush updb` and `drush cc all`

[1]:https://speakerdeck.com/dkinzer/using-git-to-manage-deployments
[gods]:./git-push.jpg
