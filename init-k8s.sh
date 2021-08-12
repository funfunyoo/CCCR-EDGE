#! /bin/bash

# LoadBalancer 타입의 서비스와 연결할 외부 IP 대역
read -p "수강번호 : " num

# 수강 번호를 입력
case ${num} in
  1) range='192.168.100.11-192.168.100.12' ;;
  2) range='192.168.100.13-192.168.100.14' ;;
  3) range='192.168.100.15-192.168.100.16' ;;
  4) range='192.168.100.17-192.168.100.18' ;;
  5) range='192.168.100.19-192.168.100.20' ;;
  6) range='192.168.100.21-192.168.100.22' ;;
  7) range='192.168.100.23-192.168.100.24' ;;
  8) range='192.168.100.25-192.168.100.26' ;;
  9) range='192.168.100.27-192.168.100.28' ;;
  10) range='192.168.100.29-192.168.100.30' ;;
  11) range='192.168.100.31-192.168.100.32' ;;
  12) range='192.168.100.33-192.168.100.34' ;;
  13) range='192.168.100.35-192.168.100.36' ;;
  14) range='192.168.100.37-192.168.100.38' ;;
  15) range='192.168.100.39-192.168.100.40' ;;
  16) range='192.168.100.41-192.168.100.42' ;;
  17) range='192.168.100.43-192.168.100.44' ;;
  18) range='192.168.100.45-192.168.100.46' ;;
  19) range='192.168.100.47-192.168.100.48' ;;
  20) range='192.168.100.49-192.168.100.50' ;;
  21) range='192.168.100.51-192.168.100.52' ;;
  22) range='192.168.100.53-192.168.100.54' ;;
  23) range='192.168.100.55-192.168.100.56' ;;
  24) range='192.168.100.57-192.168.100.58' ;;
  25) range='192.168.100.59-192.168.100.60' ;;
  26) range='192.168.100.61-192.168.100.62' ;;
  27) range='192.168.100.63-192.168.100.64' ;;
esac

# 파드를 생성하기 위해 swap off
swapoff -a

# 노드의 IP 확인
ip= hostname -I | awk '{print $1}'

# k8s 초기화
kubeadm reset --force
rm -rf /root/.kube
rm -rf /home/vraptor/.kube

# k8s 클러스터 생성
kubeadm init --apiserver-advertise-address=$ip --pod-network-cidr=10.244.0.0/16
# k8s 클러스터를 사용하기 위해 config 파일 복사
mkdir -p /root/.kube
mkdir -p /home/vraptor/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
cp /etc/kubernetes/admin.conf /home/vraptor/.kube/config
chown -R  vraptor:vraptor /home/vraptor/.kube

# Master노드에서 파드를 올리기 위한 taint제거
kubectl taint nodes --all node-role.kubernetes.io/master-

# CNI(Container Network Interface) 플러그인 설치 - Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# LoadBalancer 타입의 서비스에 연결할 외부 IP할당을 편리하게 하는 MetalLb 플러그인 설치
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system
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
      - ${range}
EOF

kubectl apply -f metallb-config.yaml

# 로컬에서 사용하는 Storageclass > PVC(Persistence Volume Claim), PV(Persistence Volume)에 사용됨
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true

