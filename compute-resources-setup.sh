### Virtual Private Cloud Network (VPC) to host Kubernetes Cluster
gcloud compute networks create k8s-cluster-vpc --subnet-mode custom

### Create a subnet in VPC
# Make sure the subnet is large enough to assign a private IP address to each node in the Kubernetes cluster.
gcloud compute networks subnets create k8s-cluster-subnet \
  --network k8s-cluster-vpc \
  --region us-west1 \
  --range 10.240.0.0/24 
 
### Firewall Rules: 
# A firewall rule that allows internal communication across all protocols
gcloud compute firewall-rules create k8s-cluster-firewall-rules-allow-internal \
  --allow tcp,udp,icmp \
  --network k8s-cluster-vpc \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
  
# A firewall rule that allows external SSH, ICMP, and HTTPS:
gcloud compute firewall-rules create k8s-cluster-firewall-rules-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network k8s-cluster-vpc \
  --source-ranges 0.0.0.0/0
  
# Note: An external load balancer will be used to expose the Kubernetes API Servers to remote clients.

# List all firewall-rules
gcloud compute firewall-rules list --filter="network:k8s-cluster-vpc"


### Kubernetes Public IP Address
#		Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:
gcloud compute addresses create k8s-cluster --region us-west1

### Compute Instances
# Kubernetes Controllers
for i in 0 1 2; do
  gcloud compute instances create k8s-master-${i} \
    --zone us-west1-a \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet k8s-cluster-subnet \
    --tags k8s-cluster-vpc,master
done


# Kubernetes Workers
# The Kubernetes cluster CIDR range is defined by the Controller Manager's --cluster-cidr flag. 
# In this case, the cluster CIDR range will be set to 10.200.0.0/16, which supports 254 subnets.
for i in 0 1 2; do
  gcloud compute instances create k8s-worker-${i} \
    --async \
	--zone us-west1-a \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet k8s-cluster-subnet \
    --tags k8s-cluster-vpc,worker
done

# List all gcloud resources
./list-cmds.sh