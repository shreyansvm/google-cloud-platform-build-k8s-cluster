cd ~/kubernetes/

#### Bootstrapping the etcd Cluster  #####

# 	Kubernetes components are stateless and store cluster state in etcd. 
#	This file will bootstrap a three node etcd cluster and configure it for high availability and secure remote access.

# Do the following SIMULTANEOUSLY on each Master node.
	# Following commands must be executed on each K8s master/controller node 
	# 	After SSH into each K8s Master -
	#		Download and Install the etcd Binaries
	#		

		gcloud compute ssh --zone us-west1-a k8s-master-0
		
		# Similarly on k8s-master-1 and k8s-master-2. Login--
			#	gcloud compute ssh --zone us-west1-a k8s-master-1
			#	gcloud compute ssh --zone us-west1-a k8s-master-2
		
	#	Download and Install the etcd Binaries

		wget -q --show-progress --https-only --timestamping \
			"https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"

	# 	Extract and install the etcd server and the etcdctl command line utility:
		{
		  tar -xvf etcd-v3.4.0-linux-amd64.tar.gz
		  sudo mv etcd-v3.4.0-linux-amd64/etcd* /usr/local/bin/
		}	

	###	Configure the etcd Server
		{
		  sudo mkdir -p /etc/etcd /var/lib/etcd
		  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
		}

		# The instance internal IP address will be used to serve client requests and communicate with etcd cluster peers. 
		# So, retrieve the internal IP address for the current compute instance and will be used later.
			
			INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
		
		# Each etcd member must have a unique name within an etcd cluster. 
		# Set the etcd name to match the hostname of the current compute instance:
			ETCD_NAME=$(hostname -s)
		
		# Create the etcd.service systemd unit file:
		# When the etcd service starts, it will take respective execution file from it -
		
			cat <<EOF | sudo tee /etc/systemd/system/etcd.service
			[Unit]
			Description=etcd
			Documentation=https://github.com/coreos

			[Service]
			Type=notify
			ExecStart=/usr/local/bin/etcd \\
			  --name ${ETCD_NAME} \\
			  --cert-file=/etc/etcd/kubernetes.pem \\
			  --key-file=/etc/etcd/kubernetes-key.pem \\
			  --peer-cert-file=/etc/etcd/kubernetes.pem \\
			  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
			  --trusted-ca-file=/etc/etcd/ca.pem \\
			  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
			  --peer-client-cert-auth \\
			  --client-cert-auth \\
			  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
			  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
			  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
			  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
			  --initial-cluster-token etcd-cluster-0 \\
			  --initial-cluster k8s-master-0=https://10.240.0.10:2380,k8s-master-1=https://10.240.0.11:2380,k8s-master-2=https://10.240.0.12:2380 \\
			  --initial-cluster-state new \\
			  --data-dir=/var/lib/etcd
			Restart=on-failure
			RestartSec=5

			[Install]
			WantedBy=multi-user.target
			EOF
		
		# Start the etcd Server

			{
			  sudo systemctl daemon-reload
			  sudo systemctl enable etcd
			  sudo systemctl start etcd
			}

		
################ Verify if the installation and service start was successful -
#	List the etcd cluster members:

	sudo ETCDCTL_API=3 etcdctl member list \
	  --endpoints=https://127.0.0.1:2379 \
	  --cacert=/etc/etcd/ca.pem \
	  --cert=/etc/etcd/kubernetes.pem \
	  --key=/etc/etcd/kubernetes-key.pem
		
# You will see following output.
#	3a57933972cb5131, started, k8s-master-2, https://10.240.0.12:2380, https://10.240.0.12:2379, false
#	f98dc20bce6225a0, started, k8s-master-0, https://10.240.0.10:2380, https://10.240.0.10:2379, false
#	ffed16798470cab5, started, k8s-master-1, https://10.240.0.11:2380, https://10.240.0.11:2379, false	
	
	
############ --------------- End ----------------------- ##############

	
	