from	ubuntu:14.04
# Create a fake tsuru_unit_agent
run echo "#!/bin/sh\nsleep 31" > /usr/local/bin/tsuru_unit_agent
run	chmod +x /usr/local/bin/tsuru_unit_agent
# Add the ubuntu user
run useradd -m ubuntu -s /bin/bash
run echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
