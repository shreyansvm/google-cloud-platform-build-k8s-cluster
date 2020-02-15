##### Provisioning a CA and Generating TLS Certificates

# In this section you will provision a Certificate Authority that can be used to generate additional TLS certificates
# Generate the CA configuration file, certificate, and private key:

{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}

# above command shall result in following files -
# 	ca-key.pem
#	ca.pem

#### Client and Server Certificates
# Generate -
#	a client and server certificates for each Kubernetes component and 
# 	a client certificate for the Kubernetes admin user.
	
	# Format
	## https://www.globalsign.com/en/blog/what-is-a-certificate-signing-request-csr/
	# Common Name (CN)
	# Organization (O)
	# Organizational Unit (OU)	
	# City/Locality (L)
	# State/County/Region (S)
	# Country (C)
	# Email Address

# Create 'admin-csr.json' file -

{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Sunnyvale",
      "O": "system:masters",
      "OU": "k8s-cluster",
      "ST": "California"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}
  
# The above command will result in generation of following files :-
#	admin-key.pem
# 	admin.pem


#### The Kubelet Client Certificates
# 	Kubernetes uses a special-purpose authorization mode called Node Authorizer, that specifically authorizes API requests made by Kubelets. 
#	In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the system:nodes group, with a username of system:node:<nodeName>. 
#	In this section you will create a certificate for each Kubernetes worker node that meets the Node Authorizer requirements.
for instance in k8s-worker-0 k8s-worker-1 k8s-worker-2; do
	cat > ${instance}-csr.json <<EOF
	{
		"CN": "system:node:${instance}",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "US",
				"L": "Sunnyvale",
				"O": "system:nodes",
				"OU": "k8s-cluster",
				"ST": "California"
			}
		]
	}
	EOF
	
	EXTERNAL_IP=$(gcloud compute instances describe ${instance} --zone us-west1-a --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

	INTERNAL_IP=$(gcloud compute instances describe ${instance} --zone us-west1-a --format 'value(networkInterfaces[0].networkIP)')

	cfssl gencert \
	  -ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
	  -profile=kubernetes \
	  ${instance}-csr.json | cfssljson -bare ${instance}

done


# The above commands would result in -
#	worker-0-key.pem
#	worker-0.pem
#	worker-1-key.pem
#	worker-1.pem
#	worker-2-key.pem
#	worker-2.pem

#### The Controller Manager Client Certificate
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Sunnyvale",
      "O": "system:kube-controller-manager",
      "OU": "k8s-cluster",
      "ST": "California"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}


# The above command results in following files -
#	kube-controller-manager-key.pem
#	kube-controller-manager.pem


###### The Kube Proxy Client Certificate
{
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
	"size": 2048
  },
  "names": [
    {
	  "C": "US",
	  "L": "Sunnyvale",
	  "O": "system:node-proxier",
	  "OU": "k8s-cluster",
	  "ST": "California"
	}
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
}

# The above command results in following files -
#	kube-proxy-key.pem
#	kube-proxy.pem

#### The Scheduler Client Certificate
{
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
	"size": 2048
  },
  "names": [
    {
	  "C": "US",
	  "L": "Sunnyvale",
	  "O": "system:kube-scheduler",
	  "OU": "k8s-cluster",
	  "ST": "California"
	}
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
}

# The above commands result in following files -
# 	kube-scheduler-key.pem
#	kube-scheduler.pem


#### The Kubernetes API Server Certificate
# 		The kubernetes-the-hard-way static IP address will be included in the list of subject alternative names for the Kubernetes API Server certificate. 
#		This will ensure the certificate can be validated by remote clients.
#		Generate the Kubernetes API Server certificate and private key
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster --region us-west1 --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Sunnyvale",
      "O": "Kubernetes",
      "OU": "k8s-cluster",
      "ST": "California"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}


# The above commands result in following files -
#	kubernetes-key.pem
#	kubernetes.pem


#### The Service Account Key Pair
#		Note: Service accounts are for processes, which run in pods.
# Generate the service-account certificate and private key:
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}

# The above commands result in following files -
# 	service-account-key.pem
#	service-account.pem


######## Distribute the Client and Server Certificates  ############
# Copy the appropriate certificates and private keys to each worker instance:

for instance in k8s-worker-0 k8s-worker-1 k8s-worker-2; do
  gcloud compute scp --zone us-west1-a ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done

# Copy the appropriate certificates and private keys to each controller instance:

for instance in k8s-master-0 k8s-master-1 k8s-master-2; do
  gcloud compute scp --zone us-west1-a ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done


# ----------------- End -------------------


