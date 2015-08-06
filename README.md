# tinge_deploy

let's get this off the ground.

Ok, so we've got a pretty decent deploy process in place.  It uses opsworks and
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
