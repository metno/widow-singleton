# widow-singleton.sh

Wrapper script to run jobs on linux. The name is inspired by widow spiders,
which are famous for eating their partner. Similarily this script will kill 
a previous job if it has been running more than a specified number of
seconds. If the new job is triggered before the timeout, the new instance is
simply discarded. This ensures that there is never more than one job for
each lock file running on one linux system. That long running jobs are
allowed to complete within a reasonable time (specified by the timeout
determined by the parameter to the attempting job run.)

    ./widow-singleton.sh /tmp/file.lock 10 /tmp/script.sh


A possible scenario:

  1. Job 1 starts
  2. Job 2 is discarted because Job 1 is still running
  3. Job 1 ends
  4. Job 3 starts
  5. Job 4 is discarded because Job 1 is still running
  6. Job 5 kills job 3 and starts
  7. Job 5 ends
