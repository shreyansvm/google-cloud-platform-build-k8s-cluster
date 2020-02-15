###### Generating the Data Encryption Config and Key

# 	Kubernetes stores a variety of data including cluster state, application configurations, and secrets. 
#	Kubernetes supports the ability to encrypt cluster data at rest.
# 	This file contains commands to generate an encryption key and an encryption config suitable for encrypting Kubernetes Secrets.

### Generate an encryption key:

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

### Create Encryption Config File

cat > encryption-config.yaml <<EOF
kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
  - resources:
    - secrets
	providers:
    - identity: {}
    - aescbc:
       keys:
       - name: key1
         secret: eF1GT99syRIBeEH1DQYyXdA4CZKH605t0juciPQ64w4=
EOF

# Copy the encryption-config.yaml encryption config file to each controller/master instance:

for instance in k8s-master-0 k8s-master-1 k8s-master-2; do
  gcloud compute scp --zone us-west1-a encryption-config.yaml ${instance}:~/
done

#### ------------ End ---------------- #####