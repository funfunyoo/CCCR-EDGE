#! /bin/bash
# sudo로 실행 필요

# MetalLB 외부 연결 ip대역 설정
echo "set external ip band"
read -p "from (ex.192.168.0.11) :" from # 시작점
read -p "to (ex.192.168.0.20) :" to # 끝점

# Kubernetes를 운영하기위해 swap 정지
swapoff -a

# 디바이스의 IP
ip= hostname -I | awk '{print $1}'

# k8s 리셋
kubeadm reset --force

rm -rf /root/.kube
rm -rf /home/vraptor/.kube

# k8s 시작
kubeadm init --apiserver-advertise-address=$ip --pod-network-cidr=10.244.0.0/16

mkdir -p /root/.kube

mkdir -p /home/vraptor/.kube

cp /etc/kubernetes/admin.conf /root/.kube/config

cp /etc/kubernetes/admin.conf /home/vraptor/.kube/config

chown -R  vraptor:vraptor /home/vraptor/.kube

# 마스터노드 테인트 제거 - 마스터노드에 파드를 올리기 위함
kubectl taint nodes --all node-role.kubernetes.io/master-

# CNi(Container Network Interface) - calico 설치
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml 
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system

# MetalLB 설치
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

cat <<EOF >  metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${from}-${to}
EOF

kubectl apply -f metallb-config.yaml

# local 스토리지 생성
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
# local 스토리지를 디폴트로 설정
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true

