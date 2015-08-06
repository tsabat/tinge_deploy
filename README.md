# tinge_deploy

let's get this off the ground.

Ok, so we've got a pretty decent deploy process in place.  It uses codedeploy and
some bash scripts to make things run.  You can replace ansible with all this, but
i'm not sure it'll do you much better than what we have.

With this secret sauce, you'll be able to set up a codedeploy `application` and
`group`, pass in a repo, and you're good-to-go.  Here are the details:

## The deployment box

There's a box called `Deployment` in ec2 that has all the right goodies on it to
run your deployment.  You can log into it with the tinge key.  Upon login, the
`bash_profile` will make you root, then `cd` you to `tinge_deploy`.  From there,
you can launch this shuttle like this:

```bash
/push.sh -a tinge_hello_world_application -r https://github.com/tsabat/example_rails.git -g tinge_hello_world_as_group
```

the arguments are

**--application || -a** - your application name

**--group || -g** - your deployment group

**--repo || -r** - the repo you want to pull from

When run, you'll see a buncha gibberish and then your app will be running.

## Setup

You have to have the same environment on your deploy box as you do for
autoscale, so I've created a `install.sh` script that has all the bash commands
to get a box running.  This must be run on deploy and in your AMI you use for
autoscaling.

## Details

These are the steps that happen on to deploy.

`push.sh` is called with the right arguments.  The script parses the keywords
and bombs if you don't have the right params.

Then you build up a `$REVISION` varaible, which is a nice name for the bundle
that gets pushed out to all the servers.  The `$REVISION` looks like this:
`<app_name>-<date>-<random_word>`.  The app-name is what you define in
codedeploy as the application, the date is a `%Y-%m-%d_%k-%M-%S` formatted
string, and the `random_word` is appended just make the revision easy to
identify.  Believe me, you'll be happy you don't have to remember a date string.

Finally you call `version.sh`, which is a separate script which builds out a
passenger-friendly diretory stucture. It looks like this:

```
├── current -> /var/www/tinge/versions/tinge_hello_world_application-2015-08-06_22-57-53-AMBUSHING
├── repo_example
│   ├── app
│   ├── bin
      ...snip - rest of rails ish here
│   └── vendor
├── repo_tinge_hello_world_application
│   ├── app
│   ├── bin
      ...snip - rest of rails ish here
│   └── vendor
└── versions
    ├── tinge_hello_world_application-2015-08-06_22-49-25-PAGEANTS
    └── tinge_hello_world_application-2015-08-06_22-57-53-AMBUSHING
    └── example-2015-08-06_22-57-53-COOL
```

Notice how the `repo_` prefix separates the `example` and
`tinge_hello_world_application` applications?  That's on purpuse.  With this
structure you can build several projects on the same box.  Cool.

The script pulls the master branch, bundle installs, precomples, then symlinks
the current directory.

One you return to `push.sh`, then a NEW `versions` folder is created, this one
to house the correct codedeploy directoy structure.  This one looks like this:

```
└── app_name-2015-08-06_13-03-28-random_word
   ├── appspec.yml
   ├── code
   │   └── app_name-2015-08-06_13-03-28-random_word
   ├── scripts
   │   ├── after_install.sh
   │   └── application_stop.sh
   └── version.txt
```

The `appspect.yml` is a control file for codedeploy.  It tells the daemon what
to do with the bundle we're creating.  In this case, we're telling it to do this:

1. execute `scripts/application_stop.sh` from previous install
1. download the bundle struture above
1. move the `/code` folder to `/var/www/tinge/current_deployment`
1. move the `/version.txt` file to `/var/www/tinge/version.txt`
1. execute the `scripts/after_install.sh` script

The `after_install.sh` is where the magic happens.  It moves the
`current_deployment/$VERSION` to the corrct place an symlinks it.  It then
cleans up the `curent_deploynemt` and `version.txt` files, fixes permissions,
and restarts the applicaiton.

Then you have a drink.
