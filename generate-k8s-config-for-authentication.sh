############ Generating Kubernetes Configuration Files for Authentication #################

# This task is divided into two parts -
#	Part-1: Client Authentication Configs
#		In this part, you will generate kubeconfig files for the :
#			controller manager, 
#			kubelet, 
#			kube-proxy, 
#			scheduler clients and 
#			the admin user.
#	Part-2: Distribute the Kubernetes Configuration Files to each worker node. 


# Each kubeconfig requires a Kubernetes API Server to connect to. 
# To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.
# Get the K8s public IP address i.e (IP addrs of Ex. Load Balancer fronting the K8s API server)

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster --region us-west1 --format 'value(address)')

# i.e you are getting 1st line in the following output -
#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$ gcloud compute addresses describe k8s-cluster --region us-west1
#	address: 34.82.151.90
#	addressType: EXTERNAL
#	creationTimestamp: '2020-02-05T17:28:13.919-08:00'
#	description: ''
#	id: '3704132789257819458'
#	kind: compute#address
#	name: k8s-cluster
#	networkTier: PREMIUM
#	region: https://www.googleapis.com/compute/v1/projects/smulkutk-project-1/regions/us-west1
#	selfLink: https://www.googleapis.com/compute/v1/projects/smulkutk-project-1/regions/us-west1/addresses/k8s-cluster
#	status: RESERVED
#	shreyans_mulkutkar@cloudshell:~/kubernetes (smulkutk-project-1)$


##	Part-1 : The kubelet Kubernetes Configuration File
# 		When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. 
#		This will ensure Kubelets are properly authorized by the Kubernetes Node Authorizer.
#			Generate a kubeconfig file for each worker node:
cd ~/kubernetes/

for instance in k8s-worker-0 k8s-worker-1 k8s-worker-2; do
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# The output of above commands will result in :
#	worker-0.kubeconfig
#	worker-1.kubeconfig
#	worker-2.kubeconfig

## Part-1: kube-proxy Kubernetes Configuration File
#		Generate a kubeconfig file for the kube-proxy service:

{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

# The output of above commands will result in :
#	kube-proxy.kubeconfig


## Part-1: kube-controller-manager Kubernetes Configuration File
#		Generate a kubeconfig file for the kube-controller-manager service:

{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

# The output of above commands will result in :
#	kube-controller-manager.kubeconfig


## Part-1: kube-scheduler Kubernetes Configuration File
#		Generate a kubeconfig file for the kube-scheduler service:

{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

# The output of above commands will result in :
#	kube-scheduler.kubeconfig


## Part-1: admin Kubernetes Configuration File
#		Generate a kubeconfig file for the admin user:

{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

# The output of above commands will result in :
#	admin.kubeconfig


### Part-2 : Distribute the Kubernetes Configuration Files
#		Copy the appropriate kubelet and kube-proxy kubeconfig files to each worker instance:
for instance in k8s-worker-0 k8s-worker-1 k8s-worker-2; do
  gcloud compute scp --zone us-west1-a ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done

#		Copy the appropriate kube-controller-manager and kube-scheduler kubeconfig files to each controller/master instance:
for instance in k8s-master-0 k8s-master-1 k8s-master-2; do
  gcloud compute scp --zone us-west1-a admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done

# -------------- End -----------------