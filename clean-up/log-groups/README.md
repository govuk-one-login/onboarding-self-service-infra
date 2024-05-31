# Clean-up stale log groups

This script removes log groups that haven't been used in a certain amount of time.

It relies on log group retention settings to remove any old log events, and then removes log streams that do not have any log events, and log groups that do not have any log streams.

It is intended to be run regularly as a lambda as operations can take some time to complete.

## TODO

This script is not complete, it should not remove log groups that are managed by a cloudformation stack, only those that have been manually created.

The supporting lambda infrastructure for this clean up opperation also needs to be created.