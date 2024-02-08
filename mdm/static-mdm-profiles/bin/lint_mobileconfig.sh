#!/bin/bash

for profile in $@
do
  echo "Parsing ${profile}"
  # Extract profile payload
  cat $profile | yq ".mobileconfig" > /tmp/in.plist
  # Format with Python
  (echo "import plistlib" ; echo "with open('/tmp/out.plist', 'w') as f: f.write(plistlib.dumps(plistlib.load(open('/tmp/in.plist', 'rb')), sort_keys=False).decode())") | python3
  # Update yaml with yq
  yq --inplace '.mobileconfig= load_str("/tmp/out.plist")' $profile
  # Cleanup
  rm /tmp/in.plist /tmp/out.plist
done
