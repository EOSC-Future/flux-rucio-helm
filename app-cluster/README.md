This repo contains the step-by-step configuration procedure in order to reproduce a running EOSC Future cluster based on Rucio Helm charts. 

## Cluster 
Cluster is created with Magnum on openstack VMs at CERN. 

Command to create the cluster:

```console
$ openstack coe cluster create eosc-cluster \
    --keypair cluster-admin-key\
    --cluster-template kubernetes-1.22.3.4-multi --master-count 3 \
    --merge-labels \
    --labels cern_enabled=true \
    --labels cvmfs_enabled=true \
    --labels cvmfs_storage_driver=true \
    --labels eos_enabled=true \    
    --labels monitoring_enabled=true \
    --labels metrics_server_enabled=true \
    --labels ingress_controller=nginx \
    --labels logging_producer=eosc-future \
    --labels logging_installer=helm \
    --labels logging_include_internal=true \
    --labels grafana_admin_passwd=admin \
    --labels keystone_auth_enabled=true \
    --labels auto_scaling_enabled=true --labels min_node_count=3 --labels max_node_count=7 \
    --node-count 5 --flavor m2.2xlarge --master-flavor m2.medium
 ```
 
To export the configuration: 

```console
$ openstack coe cluster config eosc-cluster --output-certs > eosc-cluster-env.sh
$ eval $(ai-rc "ESCAPE WP2 CERN")
```

## Flux connection

First, install [flux](https://fluxcd.io/docs/installation/).  

You might want to check if your k8s and flux versions are compatible with the line command:

```console
$ flux check
```
Then, connect flux (currrent version v0.29.1) with the repository:

```console
$ flux bootstrap github --owner=EOSC-Future --token-auth --repository=flux-rucio-helm --path=app-cluster/
```
If it didn't work, you might need to setup GitLab authentication. To do that, create a GitLab Personal Access Token, and export your token as a variable:
```console
$ export GITLAB_TOKEN=<your-token>
```
Suggestion: monitor your cluster with [K9s](https://k9scli.io/), an extremely useful tool.  

Explore if [fluxctl](https://fluxcd.io/legacy/flux/references/fluxctl/#installing-fluxctl) is needed?

## Networking
   
```console  
$ kubectl get nodes
```

Label two nodes as ingress:
```console   
$ kubectl label node your_cluster_name-node-0 role=ingress
$ kubectl label node your cluster_name-node-1 role=ingress
```
Set up the load-balancing, to be migrated to [LBaaS](https://clouddocs.web.cern.ch/networking/load_balancing.html). 
```console
$ openstack server set --property landb-alias=eosc-main--load-1-,eosc-auth--load-1-,eosc-webui--load-1-,eosc-notebook--load-1- our_cluster_name-node-0
$ openstack server set --property landb-alias=eosc-main--load-2-,eosc-auth--load-2-,eosc-webui--load-2-,eosc-notebook--load-2- our_cluster_name-node-1
```
Log in to your certificate authority (CA) website (for example [CERN CA](https://ca.cern.ch/ca/host/), select for each of the 4 services (main, auth, notebook and webui) the load-1, set as SANs the same name, but followed by load-2, and the name itself without lad specification. Generate a host certificate WITHOUT A PASSWORD. These will be passed on as secrets to the K8s cluster. Eventually, you will have 4 TLS host certificates in the .p12 format. 
    
## Secrets 
   
```console
$ kubectl create ns rucio
``` 
Secrets are managed with SOPS following this [documentation](https://blog.sldk.de/2021/03/handling-secrets-in-flux-v2-repositories-with-sops/). 
To encrypt new secrets and propagate them automatically in the cluster (only a git push is needed for them to be implemented at cluster level), you will need to execute the following instead of creating new ones:

```console
$ gpg --full-generate-key
$ pip install sops 
$ export gpg_key=<your_key>
$ gpg --export-secret-keys --armor $gpg_key | kubectl create secret generic sops-gpg --namespace=flux-system --from-file=sops.asc=/dev/stdin
$ gpg --export --armor $gpg_key > .sops.pub.asc
```
Exporting the public key allows anyone with access to the repository to encrypt secrets but not decrypt them. The commands will generate a .sops.yaml file, which contains your private key and you should store it in a safe place. 

For host certificates, every key is passed as a data in the secret.yaml, the file is encrypted by executing:

```console
$ gpg --import  .sops.pub.asc
$ sops --encrypt --in-place secret.yaml
```
With SOPS, in case the secret gets deleted manually, it will be redeployed automatically. 

All the secrets needed can be checked in the [ESCAPE repository](https://gitlab.cern.ch/escape-wp2/ew2c-kubernetes-cluster-configuration) (for example, the authentication server needs a .p12 split into .key and .crt and a valid .ca file). 
If you want to deply secrets manually, execute something similar to the script secrets.sh in the /secrets repo, which creates secrets to pass to Rucio from x509 and CA certificates. 

```console
$ kubectl create secret generic name_secret --from-file=file_name -n rucio
```
## Database
postgres

## RSEs
configure the RSEs with CRIC

## Helm releases: Servers, webui, daemons