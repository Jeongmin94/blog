---
title: "07 Kube Controller"
date: 2022-07-18T21:59:10+09:00
draft: true
tags:
- k8s-controller
categories:
- k8s
---



# 쿠버네티스 컨트롤러

> https://kubernetes.io/docs/concepts/architecture/controller

쿠번네티스의 컨트롤러는 특정 리소스를 지속적으로 바라보며 리소스의 생명주기에 따라 미리 정해진 작업을 수행하는 주체이다.

컨트롤러는 control-loop를 지속적으로 돌면서 특정 리소스를 관찰하는데, 이 때 중요하게 봐야하는 부분이 바로 바라는 상태와 현재 상태이다. 관찰 대상이 되는 리소스가 사용자의 요청에 따라 바라는 상태가 변경되고, 변경된 상태가 현재 상태와 달라지는 경우 컨트롤러가 현재 상태를 바라는 상태와 동일하게 만들 수 있도록 정해진 작업을 수행하게 된다.

컨트롤러는 특정 리소스의 상태를 바라는 상태로 만들기 위해 배치 작업을 수행하는 Pod를 생성하고, 이 Pod를 통해 특정 리소스의 현재 상태를 바라는 상태로 맞춰지게 만든다.

쿠버네티스에서는 기본적으로 ReplicaSet, Deployment, Job & CronJob, DaemonSet, StatefulSet 등과 같은 내장 컨트롤러를 지원해준다. 내장 컨트롤러는 kube-controller-manager 컴포넌트 안에서 동작하며 사용자 정의 컨트롤러를 만들어 사용할 수도 있다.



## 1. ReplicaSet

이름에서 알 수 있듯 Pod의 복제를 담당하는 컨트롤러이다. 복제를 통해 하나의 Pod에 문제가 생기더라도 다른 Pod을 이용하여 동일한 서비스를 제공할 수 있다.(쿠버네티스에서 Pod은 가축이기 때문에 쉽게 대체가능하다.)

```YAML
# myreplicaset.yaml
apiVersion: apps/v1
kind: ReplicaSet			# ReplicaSet 종류 지정
metadata:
  name: myreplicaset
spec:
  replicas: 2				# 복제할 Pod의 개수
  selector:
    matchLabels:			# 복제할 Pod을 선택(라벨링 시스템 사용)
      run: nginx-rs
  template:					# 복제할 Pod의 spec 정의
    metadata:
      labels:
        run: nginx-rs
    spec:
      containers:
      - name: nginx
        image: nginx
```

ReplicaSet에서도 라벨링 시스템을 이용하여 복제 개수를 유지할 Pod을 선택한다. 여기에서는 `nginx-rs`라는 라벨을 가진 Pod을 복제하게 된다.

```bash
kubectl apply -f myreplicaset.yaml
# replicaset.apps/myreplicaset created

kubectl get replicaset  # 축약 시, rs
# NAME            DESIRED   CURRENT   READY   AGE
# myreplicaset    2         2         2       1m
```

- DESIRED : YAML 정의서에서 정의한 `replicas`의 2가 바라는 복제 Pod의 개수
- CURRENT : 현재 Pod의 개수
- READY : 생성된 Pod 중 준비가 완료된 Pod의 개수

```bash
kubectl get pod
# NAME                READY   STATUS      RESTARTS   AGE
# myreplicaset-jc496  1/1     Running     0          6s
# myreplicaset-xr216  1/1     Running     0          6s
```

그리고 나서 Pod를 조회하면 `myreplicaset-XXXX`라는 형식을 가진 Pod이 2개 생성된 것을 확인할 수 있다. YAML 정의서에 정의한 리소스의 이름인 `myreplicaset`이라는 접두어에 쿠버네티스에서 알아서 이름을 붙여준 것이다.

ReplicaSet 리소스는 그 자체로는 복제와 유지의 기능만을 담당하고 있고, 복제된 Pod의 실행은 Pod 리소스를 직접 사용하게 된다. 쿠버네티스는 이처럼 컨트롤러에서 모든 일을 담당하는 것이 아니라 각 컨트롤러 리소스가 담당한 작업을 제외한 나머지 작업은 적절한 다른 리소스를 사용하게 된다.

```bash
# 복제본 개수 확장
kubectl scale rs --replicas 4 myreplicaset

kubectl get rs
# NAME            DESIRED   CURRENT   READY   AGE
# myreplicaset    4         4         4       1m

kubectl get pod
# NAME                READY   STATUS      RESTARTS   AGE
# myreplicaset-jc496  1/1     Running     0          2m
# myreplicaset-xr216  1/1     Running     0          2m
# myreplicaset-dc20x  1/1     Running     0          9s
# myreplicaset-3pq2t  1/1     Running     0          9s
```

가축은 필요할 때 늘리고 줄일 수 있다. ReplicaSet으로 복제할 Pod 역시 마찬가지이다. `scale`이라는 명령을 통해 복제본의 개수를 손쉽게 늘리거나 줄일 수 있다.

여기서 강제로 복제본으로 생성된 Pod을 삭제하면 어떻게 될까? 직접 delete 명령어를 사용해서 Pod을 삭제해보자.

```bash
kubectl delete pod myreplicaset-jc496
# pod "myreplicaset-jc496" deleted

kubectl get pod
# NAME                READY   STATUS      RESTARTS   AGE
# myreplicaset-xr216  1/1     Running     0          3m
# myreplicaset-dc20x  1/1     Running     0          1m
# myreplicaset-3pq2t  1/1     Running     0          1m
# myreplicaset-0y18b  1/1     Running     0          11s
```

`jc496`이라는 Pod이 삭제되었지만, control-loop를 돌며 대기하는 컨트롤러가 Pod의 현재 개수가 줄어들어 다시 하나를 생성해준 것을 확인할 수 있다. 즉, 복제본의 개수 4개(`replicas: 4`)를 바라는 상태로 보고 현재 상태에서 변화가 발생한다면 이를 바라는 상태로 맞춰주기 위해 새로운 Pod을 생성한 것을 알 수 있다.

서비스의 가용성을 위해 일정 수의 컨테이너를 지속적으로 유지시켜야 하는 경우 ReplicaSet을 유용하게 사용할 수 있다.

```bash
# ReplicaSet 정리
kubectl delete rs --all
```





## 2. Deployment

ReplicaSet과 유사하지만 업데이트 및 배포에 조금 더 특화된 리소스가 바로 Deployment이다. Deployment 컨트롤러에서는 다음과 같은 작업을 한다.

- 롤링 업데이트를 지원하고 롤링 업데이트되는 Pod의 비율을 조절할 수 있다.
- 업데이트 히스토리를 저장하고 다시 롤백할 수 있는 기능을 제공한다.
- ReplicaSet과 마찬가지로 Pod의 개수를 늘릴 수 있다.
- 배포 상태를 확인할 수 있다.

Deployment는 말 그대로 ReplicaSet이 가지고 있는 Pod의 개수를 조절하는 기능에 더하여 어플리케이션의 배포에 특화된 리소스라고 할 수 있다.

```yaml
# mydeploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mydeploy
spec:
  replicas: 10					# 유지할 Pod의 개수
  selector:
    matchLabels:				# 복제할 Pod을 선택(라벨링 시스템 사용) 
      run: nginx
  strategy:
    type: RollingUpdate			# 배포전략 종류 선택
    rollingUpdate:
      maxUnavailable: 25%  
      maxSurge: 25%
  template:						# 복제할 Pod 정의
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

Deployment의 YAML 정의서는 ReplicaSet과 마찬가지로 Pod의 개수와 복제할 Pod을 지정해주어야 한다. 배포에 대한 부분은 `strategy`에서 정의를 하고 있다.

- 배포타입 - 배포타입에는 RollingUpdate와 Recreate가 있다. 전자는 점진적으로 업데이트가 진행되고, 후자는 복제된 Pod이 전부 삭제되고 새로 생성된다.
  - RollingUpdate를 사용해야 서비스 중단 없이 배포가 가능하다.
  - Recreate는 실제 운영중인 서비스에서는 지양하는 편이 좋다.
- maxUnavailable : RollingUpdate를 사용하면 복제본 전체 중 일부가 업데이트되며 배포가 진행되는데 maxUnavailable 비율을 통해 전체 중 최대 얼마까지 업데이트를 할 수 있는지 지정할 수 있다.(소수점 내림)
- maxSurge : 점진적 업데이트 중 바라는 상태로 설정한 최대 Pod의 개수를 초과해서 만들 수 있는 Pod의 개수를 정의한다.(소수점 올림)

위와 같은 설정을 한 Deployment 컨트롤러는 기본적으로 10개의 Pod을 유지하게 되지만, 업데이트를 하는 경우에는 maxUnavailable과 maxSurge 설정에 따라 최소 8개에서 최대 13개까지의 Pod을 점진적으로 업데이트하게 된다.

```bash
kubectl apply --record -f mydeploy.yaml
# deployment.apps/mydeploy created

kubectl get deployment  # 축약 시, deploy
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# mydeploy   10/10   10           10          10m

kubectl get rs
# NAME              DESIRED   CURRENT   READY   AGE
# mydeploy-649xxx   10        10        10       1m

kubectl get pod
# NAME                   READY   STATUS       RESTARTS   AGE
# mydeploy-649xxx-bbxx   1/1     Running      0          9s
# mydeploy-649xxx-dtxx   1/1     Running      0          2m9s
```

Deployment 리소스를 사용하게 되면 deploy 리소스와 함께 ReplicaSet과 Pod이 생성된 것을 확인할 수 있다. 각각의 리소스의 역할은 다음과 같다.

- Deployment : 배포 담당
- ReplicaSet : 복제 담당
- Pod : 컨테이너 실행 담당



배포타입을 롤링 업데이트로 설정했기 때문에 복제된 Pod이 점진적으로 업데이트가 되는지 확인할 필요가 있다.

```bash
# 이미지 주소 변경
kubectl set image deployment <NAME> <CONTAINER_NAME>=<IMAGE>
```

위의 명령어를 입력하면 이미지의 주소를 변경할 수 있는데, nginx의 버전 변경으로 롤링 업데이트를 진행한다.

```bash
# 1.9.1로 업데이트
kubectl set image deployment mydeploy nginx=nginx:1.9.1 --record
# deployment.apps/mydeploy image updated

# 업데이트 진행 상황 확인합니다.
kubectl get pod
# NAME                   READY   STATUS             RESTARTS   AGE
# mydeploy-649xxx-bbxx   1/1     ContainerCreating  0          9s
# mydeploy-649xxx-dtxx   1/1     Running            0          2m9s
# ...

# 배포 상태확인
kubectl rollout status deployment mydeploy
# Waiting for deployment "mydeploy" rollout to finish: 
# 7 out of 10 new replicas have been updated...
# Waiting for deployment "mydeploy" rollout to finish: 
# 7 out of 10 new replicas have been updated...
# Waiting for deployment "mydeploy" rollout to finish: 
# 7 out of 10 new replicas have been updated...
# Waiting for deployment "mydeploy" rollout to finish: 
# 8 out of 10 new replicas have been updated...
# ...
# deployment "mydeploy" successfully rolled out

# 특정 Pod의 이미지 tag 정보를 확인합니다.
kubectl get pod mydeploy-xxx-xxx -o yaml | grep "image: nginx"
#   - image: nginx:1.9.1
```

`rollout status` 명령어를 사용하면 배포 중인 Deployment 리소스의 상태를 확인할 수 있다. 복제된 전체 Pod의 개수와 현재 업데이트된 Pod의 개수를 확인할 수 있다. Deployment 리소스의 롤링 업데이트 옵션과 Service 리소스에서 만들어진 엔드포인트를 함께 사용하면 무중단 배포를 손쉽게 적용할 수 있게 된다.



Deployment의 또 다른 기능인 롤백을 테스트할 차례이다. nginx의 버전을 임의로 변경하여 에러를 발생시키고, 롤백을 통해 정상적으로 작동하게 만들 것이다.

```bash
# 1.9.1 버전에서 (존재하지 않는) 1.9.21 버전으로 업데이트 (에러 발생)
kubectl set image deployment mydeploy nginx=nginx:1.9.21 --record
# deployment.apps/mydeploy image updated

# Pod의 상태확인
kubectl get pod
# NAME                  READY   STATUS            RESTARTS  AGE
# mydeploy-6498-bbk9v   1/1     Running           0         9m38s
# mydeploy-6498-dt5d7   1/1     Running           0         9m28s
# mydeploy-6498-wrpgt   1/1     Running           0         9m38s
# mydeploy-6498-sbkzz   1/1     Running           0         9m27s
# mydeploy-6498-hclwx   1/1     Running           0         9m26s
# mydeploy-6498-98hd5   1/1     Running           0         9m25s
# mydeploy-6498-5gjrg   1/1     Running           0         9m24s
# mydeploy-6498-4lz4p   1/1     Running           0         9m38s
# mydeploy-6fbf-7kzpf   0/1     ErrImagePull      0         48s
# mydeploy-6fbf-rfgbd   0/1     ErrImagePull      0         48s
# mydeploy-6fbf-v5ms5   0/1     ErrImagePull      0         48s
# mydeploy-6fbf-rccw4   0/1     ErrImagePull      0         48s
# mydeploy-6fbf-ncqd2   0/1     ImagePullBackOff  0         48s
```

비정상적인 nginx의 버전을 입력하여 Pod이 정상적으로 실행되지 않고 있는 상황이다. 여기에서 maxUnavailable 에서 설정한 비율만큼은 사용하지 않고 있기 때문에 10개 중 8개의 Pod은 실행중인 상황임을 알 수 있고, maxSurge 값으로 추가적으로 생성할 수 있는 Pod을 설정해주었기 때문에 최대 Pod이 13개인 것을 확인할 수 있다.

```bash
# 지금까지의 배포 히스토리를 확인합니다.
kubectl rollout history deployment mydeploy
# deployment.apps/mydeploy
# REVISION  CHANGE-CAUSE
# 1         kubectl apply --record=true --filename=mydeploy.yaml
# 2         kubectl set image deployment mydeploy nginx=nginx:1.9.1 
#                   --record=true
# 3         kubectl set image deployment mydeploy nginx=nginx:1.9.21 
#                   --record=true

# 잘못 설정된 1.9.21에서 --> 1.9.1로 롤백
kubectl rollout undo deployment mydeploy
# deployment.apps/mydeploy rolled back

kubectl rollout history deployment mydeploy
# deployment.apps/mydeploy
# REVISION  CHANGE-CAUSE
# 1         kubectl apply --record=true --filename=mydeploy.yaml
# 3         kubectl set image deployment mydeploy nginx=nginx:1.9.21 
#                    --record=true
# 4         kubectl set image deployment mydeploy nginx=nginx:1.9.1 
#                    --record=true
```

`kubectl rollout history` 명령어를 사용하면 지금까지 Deployment 리소스를 이용해서 배포한 내역을 확인할 수 있다. 마지막 배포에서 nginx 버전 문제로 Pod이 정상적으로 실행되지 않았기 때문에 2번이나 1번으로 롤백을 하면 될 것이다.

배포를 할 때 `--record`라는 옵션을 사용했기 때문에 `rollout history`에서 실제 사용한 명령을 조회할 수 있었던 것이다. `rollout undo` 명령을 사용하면 이전 상태로 롤백을 할 수 있게 된다.

롤백을 하고나서 다시 배포 내역을 확인해보면 문제가 발생한 버전의 직전 버전인 REVISION 2가 가지고 있던 배포 버전이 최종 배포 버전으로 옮겨진 것을 확인할 수 있다.(REVISION 4로 이동함) 물론, 직접 REVISION 값을 명시해서 특정 버전으로 롤백도 가능하다.

```bash
# 1.9.1 --> 1.7.9 (revision 1)로 롤백 (처음으로 롤백)
kubectl rollout undo deployment mydeploy --to-revision=1
# deployment.apps/mydeploy rolled back
```



Deployment에서 ReplicaSet을 사용하고 있기 때문에 이를 이용해서 Pod의 개수를 조절할 수도 있다.

```bash
# 복제본 개수 조절
kubectl scale deployment --replicas <NUMBER> <NAME>
```

ReplicaSet과 동일하게 scale 명령어를 사용하지만 deployment로 사용하는 것에 유의하자.

```bash
kubectl scale deployment mydeploy --replicas 5
# deployment.apps/mydeploy scaled

# 10개에서 5개로 줄어가는 것을 확인할 수 있습니다.
kubectl get pod
# NAME                  READY   STATUS           RESTARTS  AGE
# mydeploy-6498-bbk9v   1/1     Running          0         9m38s
# mydeploy-6498-dt5d7   1/1     Running          0         9m28s
# mydeploy-6498-wrpgt   1/1     Running          0         9m38s
# mydeploy-6498-sbkzz   1/1     Running          0         9m27s
# mydeploy-6498-98hd5   1/1     Running          0         9m27s
# mydeploy-6498-3srxd   0/1     Terminating      0         9m25s
# mydeploy-6498-5gjrg   0/1     Terminating      0         9m24s
# mydeploy-6498-4lz4p   0/1     Terminating      0         9m38s
# mydeploy-6fbf-7kzpf   0/1     Terminating      0         9m38s
# mydeploy-6fbf-d245c   0/1     Terminating      0         9m38s

# 다시 Pod의 개수를 10개로 되돌립니다.
kubectl scale deployment mydeploy --replicas=10
# deployment.apps/mydeploy scaled

# 5개가 새롭게 추가되어 다시 10개가 됩니다.
kubectl get pod
# NAME                  READY   STATUS              RESTARTS  AGE
# mydeploy-6498-bbk9v   1/1     Running             0         9m38s
# mydeploy-6498-dt5d7   1/1     Running             0         9m28s
# mydeploy-6498-wrpgt   1/1     Running             0         9m38s
# mydeploy-6498-sbkzz   1/1     Running             0         9m27s
# mydeploy-6498-98hd5   1/1     Running             0         9m25s
# mydeploy-6498-30cs2   0/1     ContainerCreating   0         5s
# mydeploy-6fbf-sdjc8   0/1     ContainerCreating   0         5s
# mydeploy-6498-w8fkx   0/1     ContainerCreating   0         5s
# mydeploy-6498-qw89f   0/1     ContainerCreating   0         5s
# mydeploy-6fbf-19glc   0/1     ContainerCreating   0         5s
```



마지막으로 Deployment 리소스를 edit 명령으로 직접 수정할 수 있다.

```bash
kubectl edit deploy mydeploy
# apiVersion: apps/v1
# kind: Deployment
# metadata:
# ...
# spec:
#   progressDeadlineSeconds: 600
#   replicas: 10                  # --> 3으로 수정
#   revisionHistoryLimit: 10
#   selector:
#     matchLabels:
#       run: nginx
# 
# <ESC> + :wq

kubectl get pod
# NAME                  READY   STATUS     RESTARTS  AGE
# mydeploy-6498-bbk9v   1/1     Running    0         12m8s
# mydeploy-6498-dt5d7   1/1     Running    0         12m8s
# mydeploy-6498-wrpgt   1/1     Running    0         12m8s

# deployment 리소스 정리
kubectl delete deploy --all
```

