
### Note:
	# "-q" : is for quite delete i.e. without asking to confirm with (Y|n)

# Delete Worker nodes
for i in 0 1 2; do
  gcloud compute instances delete k8s-worker-${i} --zone us-west1-a -q
done

# Delete Master/Controller nodes
for i in 0 1 2; do
  gcloud compute instances delete k8s-master-${i} --zone us-west1-a -q
done

# Delete static IP address
gcloud compute addresses delete k8s-cluster --region us-west1

# Delete firewall rules for internal communication - "k8s-cluster-firewall-rules-allow-internal"
gcloud compute firewall-rules delete k8s-cluster-firewall-rules-allow-internal -q
  
# Delete firewall rules for external communication - "k8s-cluster-firewall-rules-allow-external"
gcloud compute firewall-rules delete k8s-cluster-firewall-rules-allow-external -q

# Delete k8s-cluster-subnet Subnet
gcloud compute networks subnets delete k8s-cluster-subnet --region us-west1 -q

# Delete k8s-cluster-vpc Virtual Private Cloud Network (VPC) created to host Kubernetes Cluster
gcloud compute networks delete k8s-cluster-vpc -q

# List all gcloud resources
./list-cmds.sh