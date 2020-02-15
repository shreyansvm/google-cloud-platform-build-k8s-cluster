##### Configuring kubectl for Remote Access

# generate a kubeconfig file for the kubectl command line utility based on the admin user credentials.

# Do the following from /home/shreyans_mulkutkar/kubernetes (i.e.  from the same directory used to generate the admin client certificates.)

cd /home/shreyans_mulkutkar/kubernetes/

# The Admin Kubernetes Configuration File
#	Each kubeconfig requires a Kubernetes API Server to connect to. 
#	To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

#	Generate a kubeconfig file suitable for authenticating as the admin user:
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster --region us-west1 --format 'value(address)')
  echo $KUBERNETES_PUBLIC_ADDRESS

  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context k8s-cluster \
    --cluster=k8s-cluster \
    --user=admin

  kubectl config use-context k8s-cluster
}

### Verification - (From /home/shreyans_mulkutkar/)
#	i.e. now you should be able to get cluster status (and access cluster commands from outside the 'k8s-cluster' (name of my cluster))
kubectl get componentstatuses
kubectl get nodes -o wide


##### ----------- End --------------- #####
