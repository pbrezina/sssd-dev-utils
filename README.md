# SSSD Development Scripts
 
This is a set of bash scripts to simplify development of [SSSD](https://fedorahosted.org/sssd).

Those scripts help me to perform the most common task I do when working on SSSD. See the scripts for more details and you can run each function with `--help` or `-?` parameter for basic description. It covers building SSSD and scratch builds, calling InfoPipe methods, time correction, some git shortcuts, etc.

Any improvement to those scripts and workflow is welcome so don't hesitate to send me a pull request.
 
## Setup
 
You can edit your `~/.bashrc` with the following lines:
 
* **Setup environment variables**, e.g.
```bash
export SSSD_SOURCE=$HOME/workspace/sssd
export SSSD_BUILD=/dev/shm/sssd
export SSSD_TEST_BUILD=/dev/shm/sssd-tests
export SSSD_USER=sssd
export SSSD_RHEL_PACKAGE=$HOME/packages/rhel/sssd
export CFLAGS_CUSTOM=""

export GIT_PATCH_LOCATION="$HOME/Downloads"
export GIT_DEVEL_REPOSITORY="devel"
export GIT_PUSH_REPOSITORIES="devel pbrezina"

export NTP_SERVER="master.ipa.pb"
export BREW_URL="http://brew-url.com"
```
* **Source the scripts**, e.g.
```bash
if [ -d ~/scripts/include ]; then
  for FILE in ~/scripts/include/*.sh; do
      . $FILE
  done
fi
```

## Workflow ##

These are the most common task those scripts can help with tremendously.

### Building SSSD ###
 
Configure and build SSSD in `$SSSD_BUILD` from a specific git branch.
 
```bash
$ test-build my-branch
```
 
### Providing a scratch build to a customer ###
 
Reindex patches and move them to my RHEL package directory.

```bash
$ mygit-mv-patches start-index
```

Update `sssd.spec` manually, then create scratch build with:

```bash
$ sss-brew-scratch-build
```

Download RPMs from a brew url:

```bash
$ sss-brew-rpms-fetch url-to-any-build-rpm
```

Push them to my scratch directory on `fedorapeople.org`:

```bash
$ sss-brew-rpms-push build-name
```

### Review patches or pull request ###

Review patches stored at `$GIT_PATCH_LOCATION`:

```bash
$ mygit-review
```

Review a pull request:

```bash
$ mygit-review pull-request-url
```

### Push branches ###

To force push current branch to all repositories in `$GIT_PUSH_REPOSITORIES`:

```bash
$ mygit-push
```

## Tips ##

### Generate a talloc report of an SSSD proccess ###

```bash
$ sss-talloc-report sssd_nss
Attaching GDB to sssd_nss with PID 23369
Talloc report generated to: /tmp/sssd.talloc/sssd_nss.1481631737
```

### InfoPipe commands ###

```bash
$ ifp-send Users Users.FindByName string:John
$ ifp-get Users/10001 org.freedekstop.sssd.Users.User name
$ ifp-get-all Users/10001 org.freedekstop.sssd.Users.User
$ ifp-introspect /org/freedesktop/sssd/infopipe
```