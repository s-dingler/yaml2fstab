# fstab
## transform yaml to fstab

I choosed a very simple approach by using a bash script which is available on almost every machine and has no big dependencies.

I also choosed to read the YAML-file line by line and matched it exactly by a bunch of regexes so that always all lines have to be matched and automatically stop the process if a new and unmatched line is found.

### To run the script just use
./fstab.sh test.yml

The output will be saved in the file fstab or fstab.tmp depending if all commands (i.e. "tune2fs") passed or not.
