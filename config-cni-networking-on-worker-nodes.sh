###### Configure CNI Networking
#			Note: Before this, make sure all the required binaries are already installed on each worker node. 
#				For installation, refer - "bootstrap-n-config-k8s-worker-nodes.sh" file

### Do the following on each worker node -

# 	Retrieve the Pod CIDR range for the current compute instance:
POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)

echo $POD_CIDR

#	Create the 'bridge' network configuration file:
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

# 	Create the loopback network configuration file:

cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF
