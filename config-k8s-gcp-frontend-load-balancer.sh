########## The Kubernetes Frontend Load Balancer
# provision an external load balancer to front the Kubernetes API Servers

# The "k8s-cluster" (your cluster name) static IP address will be attached to the resulting load balancer.
# Run these commands on the home (cd /home/shreyans_mulkutkar/)
cd /home/shreyans_mulkutkar/

{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster --region us-west1 --format 'value(address)')

  gcloud compute http-health-checks create k8s-cluster-health-check \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create k8s-cluster-allow-health-check \
    --network k8s-cluster-vpc \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create k8s-cluster-target-pool \
	--region us-west1
    --http-health-check k8s-cluster-health-check

  gcloud compute target-pools add-instances k8s-cluster-target-pool \
	--region us-west1
	--instances k8s-master-0,k8s-master-1,k8s-master-2

  gcloud compute forwarding-rules create k8s-cluster-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region us-west1 \
    --target-pool k8s-cluster-target-pool
}

### Verify if the Frontend Load Balancer provisioning was done correctly. 

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster --region us-west1 --format 'value(address)')

#	Make a HTTP request for the Kubernetes version info (from the file where CA certificate exists.
cd kubernetes/
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version


######## ------------- End ------------------------ ############
