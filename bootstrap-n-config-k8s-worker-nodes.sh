###### Bootstrapping the Kubernetes Worker Nodes
# 	bootstrap three Kubernetes worker nodes. 
#	On each worker node, Install:- runc, container networking plugins, containerd, kubelet, and kube-proxy.

### # Do all these commands SIMULTANEOUSLY on each Worker node.

	gcloud compute ssh --zone us-west1-a k8s-worker-0
	
	# Similarly on k8s-master-1 and k8s-master-2. Login--
		#	gcloud compute ssh --zone us-west1-a k8s-worker-1
		#	gcloud compute ssh --zone us-west1-a k8s-worker-2

###		Provisioning a Kubernetes Worker Node
#			Install OS dependencies
#			Note: The socat binary enables support for the kubectl port-forward command.
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}

#		Disable Swap
#			By default the kubelet will fail to start if swap is enabled. 
#			It is recommended that swap be disabled to ensure Kubernetes can provide proper resource allocation and quality of service.
#			First, Verify if swap is enabled:
sudo swapon --show
#			If output is empty then swap is not enabled. So, you are good. No need to worry.
#			If swap is enabled run the following command to disable swap immediately:
sudo swapoff -a


### Download and Install Worker Binaries
#		kubectl, kube-proxy, kubelet, runc, cni-plugins, containerd
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet
  
# 		Create installation directories
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

#		Install the worker binaries:
{
  mkdir containerd
  tar -xvf crictl-v1.15.0-linux-amd64.tar.gz
  tar -xvf containerd-1.2.9.linux-amd64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
  sudo mv runc.amd64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc 
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}

#### Configure CNI Networking
./config-cni-networking-on-worker-nodes.sh

#### Configure containerd
./config-containerd-on-worker-nodes.sh

#### Configure the Kubelet
./config-kubelet-on-worker-nodes.sh

#### Configure the Kubernetes Proxy
./config-kube-proxy-on-worker-nodes.sh

#### Start the Worker Services
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}

# Check if each service is running -
# 	sudo systemctl status kubelet
#	sudo systemctl status containerd
#	sudo systemctl status kube-proxy


#### ----------- End --------------- #####

