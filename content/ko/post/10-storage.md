---
title: "10 Storage"
date: 2022-08-06T16:10:25+09:00
draft: false
tags:
- ingress
categories:
- k8s
---
쿠버네티스의 데이터 영속성을 위한 스토리지를 알아본다.
<!--more-->

# 스토리지

쿠버네티스에서는 단순히 호스트 서버의 볼륨을 연결하는 것 외에 다양한 형태로 데이터를 저장 및 참조하는 방법을 제공한다. 쿠버네티스에서 제공하는 대표적인 볼륨은 다음과 같다.

- PersistentVolume
- PersistentVolumeClaim
- StorageClass

데이터를 저장하기 위해서는 누군가 데이터를 저장할 공간을 제공해야 하며, 사용자는 그 공간에 데이터를 저장하게 된다. 쿠버네티스에서는 이 과정을 크게 두 부분으로 나누었다. 
데이터 저장소를 제공(provisioning)하는 부분과 마련한 저장소를 사용하는 부분이다.

PersistentVolume은 클러스터 관리자가 데이터를 어떻게 제공할 것인지에 대한 리소스이고, PersistentVolumeClaim은 사용자가 데이터 저장소를 어떻게 활용할 것인지에 대한 리소스이다. StorageClass는 클러스터 관리자가 사용자들에게 제공하는 저장소 종류에 대한 리소스가 된다. 실제 사용자들에게는 StorageClass 리소스를 통해 동적으로 저장소가 제공된다.

## 1. PersistentVolume

PersistentVolume(PV)는 데이터 저장소를 추상화시킨 리소스다. 클러스터의 관리자가 데이터 저장소를 사용하기 위해 미리 마련한 저장 장치들을 나타낸다.

PV에는 구체적인 저장소에 대한 정보가 담겨 있다. AWS에서는 EBS를, GCP에서는 PersistentDisk 정보를, 로컬 호스트의 저장소에서는 path 정보가 담기게 된다. 다양한 저장소를 지원하기 위해 쿠버네티스는 PersistentVolume이라는 추상화된 리소스를 사용하고, 각 환경에 맞게 타입을 선택할 수 있게 됐다.

### hostPath PV

호스트 서버의 볼륨을 연결하는 PersistentVolume YAML 정의서다.

```YAML
# hostpath-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-volume
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp
```

- storageClassName : 저장소 타입의 이름을 정의한다. PersistentVolumeClaim에서 특정 저장소 타입을 지정하기 위해 사용한다.
- capacity : 데이터 저장소의 크기를 지정한다. 호스트 서버의 디스크를 1Gi를 이용한다.
- accessModes : 접근 모드 설정. ReadWriteOnce는 동시에 1개의 Pod만 해당 볼륨에 접근할 수 있다는 것을 의미한다. NFS Volumes 같은 경우 ReadWriteMany로 여러 Pod에서 동시 접근이 가능하다.
- hostPath : 호스트 서버에서 연결될 path를 나타낸다.(ex. /home)

```bash
kubectl apply -f hostpath-pv.yaml
# persistentvolume/my-volume created

kubectl get pv
# NAME        CAPACITY  ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
# my-volume   1Gi       RWO            Retain           Available           manual                  12s
```

PV 리소스는 네임스페이스에 국한되지 않은 클러스터 레벨의 리소스다. `kubectl get pv` 명령을 사용하면 STATUS가 `Available`인 것을 확인할 수 있다. 이것은 현재 볼륨만 생성되었을 뿐 아직 아무도 데이터 저장소를 사용하고 있지 않다는 것을 의미한다. PersistentVolumeClaim에서 저장소를 요청하고 사용하는 방법을 지정해야 한다.

### NFS PV

```yaml
# my-nfs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-nfs
spec:
  storageClassName: nfs
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /tmp
    server: <NFS_SERVER_IP>
```

로컬 호스트의 볼륨 뿐만 아니라 NFS 볼륨도 사용이 가능하다.

- storageClassName : nfs라는 클래스 이름을 지정한다.
- capacity : NFS 서버의 5Gi를 사용하게 된다.
- accessModes : NFS의 경우 여러 Pod의 접근이 가능한 ReadWriteMany를 적용할 수 있다.
- mountOptions : NFS 서버와 마운트하기 위한 옵션 설정이다.
- nfs : 마운트할 NFS 서버 정보를 입력한다.

현재 NFS 서버가 없기 때문에 StorageClass에서 NFS 서버를 구축하고 설정을 진행한다.

### awsElasticBlockStore PV

> AWS 플랫폼 위에서 적절한 권한이 부여된 환경에서만 동작한다. AWS의 EB를 생성하고 볼륨 아이디를 가져와야 한다.
```
aws ec2 create-volume --availability-zone=eu-east-1a \
  --size=80 --volume-type=gp2
# {
#     "AvailabilityZone": "us-east-1a",
#     "Tags": [],
#     "Encrypted": false,
#     "VolumeType": "gp2",
#     "VolumeId": "vol-1234567890abcdef0",
#     "State": "creating",
#     "Iops": 240,
#     "SnapshotId": "",
#     "CreateTime": "YYYY-MM-DDTHH:MM:SS.000Z",
#     "Size": 80
# }
```

```yaml
# aws-ebs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: aws-ebs
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore:
    volumeID: <volume-id>
    fsType: ext4
```

- awsElasticBlockStore : AWS EBS 자원 정보를 입력한다. 해당 EBS에 PV가 연결된다.

### 다른 PV

- azureDisk : Azure에서 제공하는 저장소를 사용할 때 사용
- emptyDir : Pod와 생명 주기를 같이하는 임시 저장소다. 주로 같은 Pod 내 컨테이너들끼리 파일시스템을 통한 정보를 주고 받을 때 사용한다.
- downward API : 일반적인 볼륨과는 다르게 쿠버네티스 리소스 메타 정보를 마운트하여 마치 파일처럼 읽을 수 있게 제공한다.
- configMap : configMap 리소스를 PV 리소스처럼 마운트하여 사용할 수 있다.

## 2. PersistentVolumeClaim

PersistentVolumeClaim(PVC)는 저장소 사용자가 PV를 요청하는 리소스다. 클러스터 관리자가 PV를 통해 데이터 저장소를 준비하면, 쿠버네티스의 사용자는 PVC 요청을 통해 리소스를 선점하게 된다.

1. 클러스터 관리자가 PV를 생성한다.
2. PV의 정의에 따라 구체적인 볼륨이 생성된다.
3. 일반 사용자가 PV를 선점ㄴ하기 위해 PVC 요청을 한다.
4. PV와 사용자가 연결되어 볼륨을 사용한다.

```yaml
# my-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

- storageClassName : 선점할 PV의 저장소 클래스를 입력한다.
- accessModes : 선점할 PV의 접근 모드를 설정한다.
- resources : 요청할 저장소 크기를 지정한다.

PVC 리소스를 생성하면 요청할 때 입력한 `storageClassName`에 맞는 PV를 연결해준다.

```bash
kubectl apply -f my-pvc.yaml
# persistentvolumeclaim/my-pvc created

# 앞에서 생성한 my-volume을 선점하였습니다.
kubectl get pvc
# NAME          STATUS   VOLUME      CAPACITY  ACCESS MODES    ... 
# my-pvc        Bound    my-volume   1Gi       RWO             ...

kubectl get pv
# NAME        CAPACITY  ACCESS MODES   RECLAIM POLICY   STATUS   
# my-volume   1Gi       RWO            Retain           Bound    
#
#                 CLAIM              STORAGECLASS    REASON   AGE
#                 default/my-pvc     manual                   11s
```

PVC 리소스가 생성되고 나서 이전에 생성한 `manual` PV의 STATUS가 `Bound`로 변경된 것을 확인할 수 있다. CLAIM 역시 `my-pvc`인 것을 볼 수 있다. PVC를 이용해서 Pod에서 직접 사용하는 방법이다.

```yaml
# use-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: use-pvc
spec:
  containers: 
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: /test-volume
      name: vol
  volumes:
  - name: vol
    persistentVolumeClaim:
      claimName: my-pvc
```

- volumes : 연결할 볼륨을 설정한다.
  - persistentVolumeClaim : PVC 볼륨 사용을 선언한다.
    - claimName : 사용할 PVC의 이름을 지정한다.

```bash
kubectl apply -f use-pvc.yaml
# pod/use-pvc created

# 데이터 저장
kubectl exec use-pvc -- sh -c "echo 'hello' > /test-volume/hello.txt"

# 데이터 확인
kubectl exec use-pvc -- cat /test-volume/hello.txt
# hello
```

요청한 PVC에 `/text-volume/hello.txt`라는 데이터를 저장했다. 그리고 데이터가 저장된 것을 확인했다. 우리는 이 데이터를 PVC라는 저장소에 저장했기 때문에 `use-pvc` Pod를 삭제하고, 다시 Pod를 생성하면 해당 데이터가 남아있을 것을 기대할 수 있다.

```bash
kubectl delete pod use-pvc
# pod/use-pvc deleted

kubectl apply -f use-pvc.yaml
# pod/use-pvc created

kubectl exec use-pvc -- cat /test-volume/hello.txt
# hello
```

Pod을 삭제하고 다시 만들어도 PVC를 통해 만들어진 저장소가 유지된 것을 확인할 수 있다.

## PV와 PVC로 나누는 이유

쿠버네티스의 Node와 Pod는 서로 다른 생명주기를 가지고 있다. Pod는 한번 실행되었다가 종료될 수 있지만, Node는 Pod와 상관없이 지속적으로 유지된다. 그리고 Node는 인프라적인 성격이 강하다.

Pod는 누구나 쉽게 생성하고 삭제할 수 있지만 Node는 클러스터 관리자가 직접 추가해야 하고 비용이 발생한다. 클러스터 관리자가 Node를 제공하면 Pod는 Node의 자원을 소비하는 형태이다.

PV와 PVC도 이와 비슷한 관계를 가진다. 데이터를 저장하는 PV와 이를 활용하는 PVC의 생명주기는 서로 다르다. PVC는 사용자의 요청에 의해 생성되고 삭제될 수 있지만 PV는 PVC의 생명주기와 상관없이 지속적으로 데이터를 유지하고 있어야 한다. PV도 Node와 마찬가지로 인프라적인 성격이 강하기 때문이다.

데이터 저장소를 준비하기 위해서는 물리적으로 스토리지를 붙이거나 스토리지 비용을 지불해야 하는데, PVC는 클러스터 관리자가 마련한 PV를 소비하는 역할을 한다. 

또한, PV는 Node와 마찬가지로 네임스페이스에 포함되지 않고(클러스터 레벨) PVC는 Pod와 마찬가지로 특정 네임스페이스 안에 존재(네임스페이스 레벨)한다. 이러한 이유로 쿠버네티스는 스토리지 자원을 책임과 역할에 따라 구분하여 제공한다.

```bash
# clean up
kubectl delete pod use-pvc
kubectl delete pvc my-pvc
kubectl delete pv my-volume
```

## 3. StorageClass

StorageClass 리소스는 클러스터 관리자에 의해 사용자들이 선택할 수 있는 스토리지 열거한 것이다. 사용자는 클러스터 관리자가 제공하는 StorageClass를 이용하여 동적으로 볼륨을 제공 받게 된다.

원래 데이터 저장소를 사용하려면 먼저 쿠버네티스 관리자가 데이터 저장소를 미리 준비해야 한다. 가용 가능한 볼륨이 존재하지 않는다면 Pod가 생성되지 않고 Pending 상태로 대기하게 된다. 하지만 StorageClass를 사용하면 볼륨 생성을 기다리지 않고 동적으로 데이터 저장소를 제공받을 수 있다.

쿠버네티스가 설치된 방법에 따라 기본적으로 제공되는 StorageClass가 있다. k3s는 `local-path`라는 이름의 StorageClass 리소스가 존재하는데, 노드의 로컬 저장소를 활용할 수 있게 해준다.

```bash
# local-path라는 이름의 StorageClass
kubectl get sc
# NAME                  PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# local-path (default)  rancher.io/local-path   Delete          WaitForFirstConsumer   false                  20d

kubectl get sc local-path -oyaml
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   annotations:
#     objectset.rio.cattle.io/id: ""
#   ...
#   name: local-path
#   resourceVersion: "172"
#   selfLink: /apis/storage.k8s.io/v1/storageclasses/local-path
#   uid: 3aede349-0b94-40c8-b10a-784d38f7c120
# provisioner: rancher.io/local-path
# reclaimPolicy: Delete
# volumeBindingMode: WaitForFirstConsumer
```

StorageClass 클래스는 클러스터 레벨 리소스로 조회 시, 네임스페이스 지정을 할 필요가 없다.

```yaml
# my-pvc-sc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-sc
spec:
  storageClassName: local-path
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

`storageClassName`을 기본 제공되는 StorageClass의 이름으로 지정한다.

```bash
kubectl apply -f my-pvc-sc.yaml
# persistentvolumeclaim/my-pvc-sc created

kubectl get pvc my-pvc-sc
# NAME         STATUS    VOLUME     CAPACITY   ACCESS MODES  STORAGECLASS   AGE 
# my-pvc-sc    Pending                                       local-path     11s 
```

Pending 상태는 Pod가 PVC를 사용하게 만들면 변하게 된다.

```yaml
# use-pvc-sc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: use-pvc-sc
spec:
  volumes:
  - name: vol
    persistentVolumeClaim:
      claimName: my-pvc-sc
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: vol
```

```bash
# pod 생성
kubectl apply -f use-pvc-sc.yaml
# pod/use-pvc-sc created

# STATUS가 Bound로 변경
kubectl get pvc my-pvc-sc
# NAME         STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# my-pvc-sc    Bound    pvc-479cff32-xx   1Gi        RWO            local-path     92s         

# 기존에 생성하지 않은 신규 volume이 생성된 것을 확인
kubectl get pv
# NAME              CAPACITY  ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
# pvc-479cff32-xx   1Gi       RWO            Delete           Bound    default/my-pvc-sc   local-path              3m

# pv 상세 정보 확인 (hostPath 등)
kubectl get pv pvc-479cff32-xx -oyaml
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#     ...
#   name: pvc-b1727544-f4be-4cd6-acb7-29eb8f68e84a
#   ...
# spec:
#   ...
#   hostPath:
#     path: /var/lib/rancher/k3s/storage/pvc-b1727544-f4be-4cd6-acb7-29eb8f68e84a
#     type: DirectoryOrCreate
#   nodeAffinity:
#     required:
#       nodeSelectorTerms:
#       - matchExpressions:
#         - key: kubernetes.io/hostname
#           operator: In
#           values:
#           - worker
#    ...
```

local-path를 사용하는 StorageClass는 결국 로컬 호스트 볼륨을 사용하는 PV와 다를게 없어 보인다. 실제로 PV를 StorageClass가 대신 만들어 준다는 것을 제외하면 특별한 차이가 없다.

그럼에도 StorageClass 리소스를 사용하는 이유는 PV를 StorageClass가 대신 특정 디렉토리 위치 아래(`/var/lib/rancher/k3s/storage`)로만 만들어주기 때문에 일반 사용자가 로컬 호스트 서버의 아무 위치나 디렉토리를 사용하지 못하게 막을 수 있다.

또한, `local-path`와 같이 간단하게 PV를 설정하는 경우에는 별 차이가 없겠지만, NFS StorageClass와 같이 NFS 서버 정보, 마운트 옵션, 마운트 디렉토리 등 PV를 생성하기 위해 복잡한 인프라 정보를 알고 있어야 하는 경우, 사용자가 StorageClass에게 요청만 보내면 나머지는 StorageClass가 알아서 PV를 만들어 사용자를 PVC에 연결해준다.

1. 일반 사용자가 StorageClass를 이용하여 PVC를 생성한다.
2. StorageClass 프로비저닝이 사용자의 요청을 인지한다.
3. 사용자의 요청에 따라 PV를 생성한다.
4. 볼륨이 만들어진다.
5. 사용자는 PV와 연결되어 볼륨을 사용한다.


### NFS StorageClass 설정

helm chart 중에 NFS 서버를 생성하고, NFS StorageClass를 제공하는 `nfs-server-provisioner`라는 chart가 있다.

```bash
helm install nfs stable/nfs-server-provisioner \
    --set persistence.enabled=true \
    --set persistence.size=10Gi \
    --version 1.1.1 \
    --namespace ctrl
# NAME: nfs
# LAST DEPLOYED: Wed Jul  8 13:19:46 2020
# NAMESPACE: ctrl
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# ...

# nfs-server-provisioner라는 Pod가 생성되어 있습니다.
kubectl get pod -n ctrl
# NAME                           READY   STATUS       RESTARTS   AGE
# ...
# nfs-nfs-server-provisioner-0   1/1     Running      0          4m

# 이것은 StatefulSet로 구성되어 있습니다.
kubectl get statefulset  -n ctrl
# NAME                         READY   AGE
# nfs-nfs-server-provisioner   1/1     57s

# nfs-server-provisioner Service도 있습니다.
kubectl get svc  -n ctrl
# NAME                                  TYPE           CLUSTER-IP     ..
# nginx-nginx-ingress-default-backend   ClusterIP      10.43.79.133   .. 
# nginx-nginx-ingress-controller        LoadBalancer   10.43.182.174  ..  
# nfs-nfs-server-provisioner            ClusterIP      10.43.248.122  ..  

# 새로운 nfs StorageClass 생성
kubectl get sc
# NAME                 PROVISIONER                                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# local-path (default) rancher.io/local-path                      Delete          WaitForFirstConsumer   false                  20d
# nfs                  cluster.local/nfs-nfs-server-provisioner   Delete          Immediate              true                   10s
```

`nfs-server-provisioner`는 크게 StatefulSet과 Service로 이루어져 있다. 그리고 nfs라는 StorageClass가 생성된 것을 확인할 수 있다. 이를 활용하여 NFS 볼륨을 생성한다.


```yaml
# nfs-sc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-sc
spec:
  # 기존 local-path에서 nfs로 변경
  storageClassName: nfs
  # accessModes를 ReadWriteMany로 변경
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f nfs-sc.yaml
# persistentvolumeclaim/nfs-sc created

# pvc 리소스 확인
kubectl get pvc
# NAME        STATUS   VOLUME             CAPACITY   ACCESS MODES  ...
# my-pvc-sc   Bound    pvc-b1727544-xxx   1Gi        RWO           ...
# nfs-sc      Bound    pvc-49fea9cf-xxx   1Gi        RWO           ...

# pv 리소스 확인
kubectl get pv pvc-49fea9cf-xxx
# NAME                CAPACITY   ACCESS MODES   RECLAIM  POLICY  STATUS    CLAIM            STORAGECLASS   REASON  AGE
# pvc-49fea9cf-xxx    1Gi        RWX            Delete           Bound     default/nfs-sc   nfs                    5m

# pv 상세 정보 확인 (nfs 마운트 정보)
kubectl get pv pvc-49fea9cf-xxx -oyaml
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   ...
# spec:
#   accessModes:
#   - ReadWriteMany
#   capacity:
#     storage: 1Gi
#   claimRef:
#     apiVersion: v1
#     kind: PersistentVolumeClaim
#     name: nfs-sc
#     namespace: default
#     resourceVersion: "10084380"
#     uid: 2e95f6c4-2b43-4375-808f-0c93e44a1003
#   mountOptions:
#   - vers=3
#   nfs:
#     path: /export/pvc-2e95f6c4-2b43-4375-808f-0c93e44a1003
#     server: 10.43.248.122
#   persistentVolumeReclaimPolicy: Delete
#   storageClassName: nfs
#   volumeMode: Filesystem
# status:
#   phase: Bound
```

NFS StorageClass를 이용하여 PVC를 생성하면 다음과 같이 자동으로 PV가 생성되고 사용자가 직접 NFS 서버 정보를 몰라도 자동으로 연결이 된다. 이제 이 PVC를 사용하는 Pod를 생성한다. 동일한 NFS 저장소를 바라보는 nginx pod를 2개 만들고, 이때 nodeSelector를 이용하여 서로 다른 노드에 Pod를 배치한다.

```yaml
# use-nfs-sc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: use-nfs-sc-master
spec:
  volumes:
  - name: vol
    persistentVolumeClaim:
      claimName: nfs-sc
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: vol
  nodeSelector:
    kubernetes.io/hostname: master
---
apiVersion: v1
kind: Pod
metadata:
  name: use-nfs-sc-worker
spec:
  volumes:
  - name: vol
    persistentVolumeClaim:
      claimName: nfs-sc
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: vol
  nodeSelector:
    kubernetes.io/hostname: worker
```

```bash
kubectl apply -f use-nfs-sc.yaml
# pod/use-nfs-sc-master created
# pod/use-nfs-sc-worker created

kubectl get pod -o wide
# NAME               READY  STATUS    RESTARTS  AGE   IP          NODE
# ...
# use-nfs-sc-master  1/1    Running   0         19s   10.42.0.8   master
# use-nfs-sc-worker  1/1    Running   0         19s   10.42.0.52  worker
```

서로 다른 Node에 만들어진 Pod을 확인할 수 있다. master에 위치한 Pod에서 index.html 파일을 생성하고, worker에 위치한 Pod에서는 index.html을 읽어 NFS 저장소를 사용하는지 확인할 수 있다.

```bash
# master Pod에 index.html 파일을 생성합니다.
kubectl exec use-nfs-sc-master -- sh -c \
      "echo 'hello world' >> /usr/share/nginx/html/index.html"

# worker Pod에서 호출을 합니다.
kubectl exec use-nfs-sc-worker -- curl -s localhost
# hello world
```

```bash
# clean up
kubectl delete pod --all
kubectl delete pvc nfs-sc my-pvc-sc
```
## 마치며

스토리지는 컴퓨팅에 있어서 중요한 리소스다. 쿠버네티스에서는 스토리지 생성(PV)과 활용(PVC)이라는 생명주기를 나누어 관리하여 플랫폼 종속성을 최대한 낮추고자 했다.

또한, 매번 관리자가 스토리지 자원을 프로비저닝 할 필요 없이 클러스터 관리자가 제공하는 스토리지 종류(StorageClass)를 통해 스토리지 리소스를 동적으로 사용할 수 있는 방법도 제공해준다.
