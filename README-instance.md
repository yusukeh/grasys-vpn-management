# README Instance

## ToC

<!-- mtoc-start -->

* [Setup Infrastructure on Google Cloud](#setup-infrastructure-on-google-cloud)
  * [VPC](#vpc)
  * [Firewall](#firewall)
  * [Instances (Google Compute Engine)](#instances-google-compute-engine)

<!-- mtoc-end -->

## Setup Infrastructure on Google Cloud

環境変数
```bash
project="適用するプロジェクト" # 要書き換え
vpc="dualstack-vpc"
region="asia-northeast1"
subnet_name="dualstack-tokyo"
subnet_range="10.0.0.0/24"
target_tags="dualstack-vpn-server"
firewall_rules_ipv4_name="vpn-custom-port-ipv4"
firewall_rules_ipv6_name="vpn-custom-port-ipv6"
firewall_rules_open_port="59820" # 使用するポート番号を変更する際は、config/wireguard.yaml のport: も合わせて変更
firewall_rules_office_ipv4_addr="182.169.73.7/32"
external_static_ipv4_name="vpn-endpoint-ipv4"
external_static_ipv6_name="vpn-endpoint-ipv6"
instance_name="dualstack-vpn-server"
instance_zone="asia-northeast1-b"
instance_machine_type="e2-medium"
instance_image="projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20241116" # 適宜、最新イメージがあれば差し替える(差分更新短縮のため)
```

### VPC
```bash
gcloud compute networks create ${vpc} --project=${project} --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional --bgp-best-path-selection-mode=legacy

gcloud compute networks subnets create ${subnet_name} --project=${project} --range=${subnet_range} --stack-type=IPV4_IPV6 --ipv6-access-type=EXTERNAL --network=${vpc} --region=${region}
```

### Firewall
```bash
gcloud compute --project=${project} firewall-rules create ${firewall_rules_ipv4_name} --direction=INGRESS --priority=1000 --network=${vpc} --action=ALLOW --rules=tcp:${firewall_rules_open_port},udp:${firewall_rules_open_port} --source-ranges=0.0.0.0/0 --target-tags=${target_tags}

gcloud compute --project=${project} firewall-rules create ${firewall_rules_ipv6_name} --direction=INGRESS --priority=1000 --network=${vpc} --action=ALLOW --rules=tcp:${firewall_rules_open_port},udp:${firewall_rules_open_port} --source-ranges=::/0 --target-tags=${target_tags}

# オフィスIPv4アドレスからのssh 接続を許可
gcloud compute --project=${project} firewall-rules create allow-ssh-from-office --direction=INGRESS --priority=1000 --network=${vpc} --action=ALLOW --rules=tcp:22 --source-ranges=${firewall_rules_office_ipv4_addr} --target-tags=${target_tags}
```

### External static IP address for VPN endpoint
```bash
# IPv4
gcloud compute addresses create ${external_static_ipv4_name} --project=${project} --region=${region}

# IPv6
gcloud compute addresses create ${external_static_ipv6_name} --project=${project} --ip-version=IPV6 --region=${region} --endpoint-type=VM --subnet=projects/${project}/regions/${region}/subnetworks/${subnet_name}
```

### Instances (Google Compute Engine)
```bash
gcloud compute instances create ${instance_name} \
    --project=${project} \
    --zone=${instance_zone} \
    --machine-type=${instance_machine_type} \
    --network-interface=address=${external_static_ipv4_name},external-ipv6-address=${external_static_ipv6_name},external-ipv6-prefix-length=96,ipv6-network-tier=PREMIUM,network-tier=PREMIUM,stack-type=IPV4_IPV6,subnet=${subnet_name} \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --no-service-account \
    --no-scopes \
    --tags=${target_tags} \
    --create-disk=auto-delete=yes,boot=yes,device-name=${instance_name},image=${instance_image},mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any
```
