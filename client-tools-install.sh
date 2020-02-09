######## Installing the Client Tools ########

# Install CFSSL
# The cfssl and cfssljson command line utilities will be used to provision a Public key infrastructure (PKI) Infrastructure and generate TLS certificates.
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson
  
chmod +x cfssl cfssljson

sudo mv cfssl cfssljson /usr/local/bin/

# Verify cfssl and cfssljson
cfssl version
cfssljson --version

# Install Kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify kubectl version
kubectl version --client
 