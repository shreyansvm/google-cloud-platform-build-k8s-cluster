gcloud config set project smulkutk-project-1

# List all networks
echo " ######## (VPC) Networks list ########"
gcloud compute networks list

# List all subnets
echo " ######## Networks Subnet list ########"
gcloud compute networks subnets list

# List all GCP Forntend Load Balancer target-pools
echo " ######## Target-Pools list ########"
gcloud compute target-pools list

# List all GCP Forntend Load Balancer Forwarding-Rules 
echo " ######## GCP Forntend Load Balancer Forwarding-Rules list ########"
gcloud compute forwarding-rules list

# List all GCP Forntend Load Balancer firewall-rules
echo " ######## GCP Forntend Load Balancer Firewall-Rules list ########"
gcloud compute firewall-rules list

# List Routes in your network
echo " ######## Route list in given VPC ########"
gcloud compute routes list --filter "network: k8s-cluster-vpc"

# List all compute instances
echo " ######## Compute Instances list ########"
gcloud compute instances list