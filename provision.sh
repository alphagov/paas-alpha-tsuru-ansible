# network
gcloud compute --project "root-unison-859" networks create "tsuru" --range "10.240.0.0/16"

# provision some instance.
for num in 1 2 3 4;
do
    gcloud compute instances create tsuru-i${num} --zone us-central1-c   --machine-type n1-standard-2 --metadata-from-file sshKeys=~/.ssh/GDS/deis.pub --tags tsuru --network tsuru --metadata "cluster=tsuru"  --image "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1404-trusty-v20150316"

done

# firewall rules.
gcloud compute --project "root-unison-859" firewall-rules create "tsuru-filewalls" --allow tcp:22 tcp:3131 tcp:3232 tcp:6379 tcp:8080 tcp:27017 tcp:8081 --network "tsuru" --source-ranges "0.0.0.0/0" --target-tags "tsuru"

# create ansible inventory. 
gcloud compute instances list -r tsuru.* | grep tsuru | awk '{printf "%s\tinternal_ip=%s\texternal_ip=%s\tname=%s\n", $5, $4, $5, $1}' > inventory.base
