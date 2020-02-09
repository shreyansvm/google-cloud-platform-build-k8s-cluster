

########### Bootstrapping the Kubernetes Control Plane  ##############

# This command covers -
#	Bootstrapping Kubernetes control plane
#	Configuring Kubernetes control plane for high-availability
#	Create an external load balancer that exposes the Kubernetes API Servers to remote client
#	Install Kubectl, Kubernetes API Server, Scheduler, and Controller Manager... on each K8s master/control node
	# Later configure these K8s control plane components. 


### # Do all these commands SIMULTANEOUSLY on each Master node.

	gcloud compute ssh --zone us-west1-a k8s-master-0
	
	# Similarly on k8s-master-1 and k8s-master-2. Login--
		#	gcloud compute ssh --zone us-west1-a k8s-master-1
		#	gcloud compute ssh --zone us-west1-a k8s-master-2

	# Create the Kubernetes configuration directory:
	sudo mkdir -p /etc/kubernetes/config
	
	# Download Kubernetes API Server, Scheduler, and Controller Manager binaries.
	
	wget -q --show-progress --https-only --timestamping \
	  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
	  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
	  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
	  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"

	
	# Install Kubernetes API Server, Scheduler, and Controller Manager binaries.

	{
	  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
	  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
	}
	
	# Configure the Kubernetes API Server
	{
	  sudo mkdir -p /var/lib/kubernetes/

	  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
		service-account-key.pem service-account.pem \
		encryption-config.yaml /var/lib/kubernetes/
	}

	# The instance internal IP address will be used to advertise the API Server to members of the cluster. 
	# Retrieve the internal IP address for the current compute instance. Later it will be used in creating the systemd unit file. 
	INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
	
	# Create the kube-apiserver.service systemd unit file:
	cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
	[Unit]
	Description=Kubernetes API Server
	Documentation=https://github.com/kubernetes/kubernetes

	[Service]
	ExecStart=/usr/local/bin/kube-apiserver \\
	  --advertise-address=${INTERNAL_IP} \\
	  --allow-privileged=true \\
	  --apiserver-count=3 \\
	  --audit-log-maxage=30 \\
	  --audit-log-maxbackup=3 \\
	  --audit-log-maxsize=100 \\
	  --audit-log-path=/var/log/audit.log \\
	  --authorization-mode=Node,RBAC \\
	  --bind-address=0.0.0.0 \\
	  --client-ca-file=/var/lib/kubernetes/ca.pem \\
	  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
	  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
	  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
	  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
	  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
	  --event-ttl=1h \\
	  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
	  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
	  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
	  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
	  --kubelet-https=true \\
	  --runtime-config=api/all \\
	  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
	  --service-cluster-ip-range=10.32.0.0/24 \\
	  --service-node-port-range=30000-32767 \\
	  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
	  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
	  --v=2
	Restart=on-failure
	RestartSec=5

	[Install]
	WantedBy=multi-user.target
	EOF
	
	## Configure the Kubernetes Controller Manager
	#	Move the kube-controller-manager kubeconfig into place:
	sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

	#	Create the kube-controller-manager.service systemd unit file:
	cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
	[Unit]
	Description=Kubernetes Controller Manager
	Documentation=https://github.com/kubernetes/kubernetes

	[Service]
	ExecStart=/usr/local/bin/kube-controller-manager \\
	  --address=0.0.0.0 \\
	  --cluster-cidr=10.200.0.0/16 \\
	  --cluster-name=kubernetes \\
	  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
	  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
	  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
	  --leader-elect=true \\
	  --root-ca-file=/var/lib/kubernetes/ca.pem \\
	  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
	  --service-cluster-ip-range=10.32.0.0/24 \\
	  --use-service-account-credentials=true \\
	  --v=2
	Restart=on-failure
	RestartSec=5

	[Install]
	WantedBy=multi-user.target
	EOF

	## Configure the Kubernetes Scheduler
	#	Move the kube-scheduler kubeconfig into place:

	sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

	#	Create the kube-scheduler.yaml configuration file:

	cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
	apiVersion: kubescheduler.config.k8s.io/v1alpha1
	kind: KubeSchedulerConfiguration
	clientConnection:
	  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
	leaderElection:
	  leaderElect: true
	EOF

	#	Create the kube-scheduler.service systemd unit file:

	cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
	[Unit]
	Description=Kubernetes Scheduler
	Documentation=https://github.com/kubernetes/kubernetes

	[Service]
	ExecStart=/usr/local/bin/kube-scheduler \\
	  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
	  --v=2
	Restart=on-failure
	RestartSec=5

	[Install]
	WantedBy=multi-user.target
	EOF
	
	####### Start the all the Master/Controller Services
	{
	  sudo systemctl daemon-reload
	  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
	  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
	}
	

# Continue to do on all master nodes -

###### Enable HTTP Health Checks
#	A Google Network Load Balancer will be used to distribute traffic across the three API servers and allow each API server to terminate TLS connections and validate client certificates. 
#	The network load balancer only supports HTTP health checks which means the HTTPS endpoint exposed by the API server cannot be used. 
#	As a workaround the nginx webserver can be used to proxy HTTP health checks. 
	
# Install a basic web server to handle HTTP health checks:
sudo apt-get update
sudo apt-get install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
	 proxy_pass                    https://127.0.0.1:6443/healthz;
	 proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}

sudo systemctl restart nginx
sudo systemctl enable nginx

##### Verify if all Kubernetes components were installed correctly
kubectl get componentstatuses --kubeconfig admin.kubeconfig
# Output will look like this -
#	NAME                 STATUS    MESSAGE              ERROR
#	controller-manager   Healthy   ok
#	scheduler            Healthy   ok
#	etcd-2               Healthy   {"health": "true"}
#	etcd-0               Healthy   {"health": "true"}
#	etcd-1               Healthy   {"health": "true"}


# Test the nginx HTTP health check proxy:
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz


####### Configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node
# The commands from now one effect the entire cluster and only need to be run once from one of the controller nodes.

gcloud compute ssh --zone us-west1-a k8s-master-0
		
# Similarly on k8s-master-1 and k8s-master-2. Login--
	#	gcloud compute ssh --zone us-west1-a k8s-master-1
	#	gcloud compute ssh --zone us-west1-a k8s-master-2

# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF


# The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the client certificate as defined by the "--kubelet-client-certificate" flag.

# Bind the system:kube-apiserver-to-kubelet ClusterRole to the kubernetes user:

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF


########## The Kubernetes Frontend Load Balancer

./config-k8s-gcp-frontend-load-balancer


###### -------------------------- End -----------------------  #######
