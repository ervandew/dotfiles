##
# Profile for setting up a work env for ipython.
#
# In .virtualenv/<env>/bin/postactivate you can add an alias to run:
#   ipython --profile work
#
# Any .py files in the startup/ directory will be run in the ipython repl
# context, so that's the place to setup the db, import utils, models, etc. that
# you don't have to have to mess with everytime you start a new repl.
##

# load the profile_default settings
load_subconfig('ipython_config.py', profile='default')
