#!/bin/bash

cd /home/teeworlds/servers

if [ $(cat /proc/loadavg|head -c1) -ge 2 ]; then
  #echo -e "Current load is > 2, not running."
  exit 1
fi

LOCK_FILE="scripts/ranks-lock"

# noclobber prevents the '>' from overwriting an existing lock file.
if ! (set -o noclobber; (echo $$ > "$LOCK_FILE") 2> /dev/null); then
  #echo -e "Already locked by the process with the PID $(cat "$LOCK_FILE"). Remove $LOCK_FILE to unlock manually."
  exit 1
fi

cleanup()
{
  rm -f "$LOCK_FILE"
}

trap cleanup EXIT HUP INT QUIT TERM # Always call, even on success.

types=`cat all-types`

scripts/update-local.sh

scripts/ranks.py $types
# Only update the country-specific pages once per day
#if test `find /var/www/ranks/ger/novice/index.html -mmin +1440`; then
  # EUR is split into 4 regions in ranks:
  scripts/ranks.py --country=NLD $types
  scripts/ranks.py --country=GER $types
  scripts/ranks.py --country=POL $types
  scripts/ranks.py --country=FRA $types
  grep name serverlist.json | sed -e 's/.*"name": "\(.*\)".*/\1/' | while read country; do
    scripts/ranks.py --country=$country $types
  done
#fi

scripts/releases-mappers.py $types > /var/www/mappers/index.$$.tmp && mv /var/www/mappers/index.$$.tmp /var/www/mappers/index.html

#scripts/halloffame.py > /var/www/halloffame/index.html

zip -q9r /var/www/players-cache.$$.tmp players-cache && mv /var/www/players-cache.$$.tmp /var/www/players-cache.zip

curl -s -o serverlist-kog.json.$$.tmp https://qshar.com/servers.php && mv serverlist-kog.json.$$.tmp serverlist-kog.json && ./git-update-serverlist-only.sh

#scripts/update-stats.sh
