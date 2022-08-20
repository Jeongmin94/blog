---
title: "07 Kube Controller"
date: 2022-07-18T21:59:10+09:00
draft: false
tags:
- k8s-controller
categories:
- k8s
---

쿠버네티스 컨트롤러에 대해 알아본다.

<!--more-->

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





## 3. StatefulSet

StatefulSet은 StatefulSet한 Pod이 필요할 때 사용한다. Deployment, ReplicaSet과는 다르게 복제된 Pod이 완벽하게 동일하지 않고 순서에 따라 고유의 역할을 가진다.

동일한 이미지로 Pod을 생성하지만 실행 시, 각기 다른 역할을 부여하고 서로 그 역할을 교체하지 못하는 경우에 StatefulSet 리소스를 사용하면 된다. 예를 들어, 동일한 프로세스이지만 실행 순서에 따라 마스터 혹은 워커로 결정되는 경우를 생각해볼 수 있다.

StatefulSet은 상태정보를 저장하는 어플리케이션에서 사용하는 리소스이다. Deployment처럼 여러 Pod을 만들어 ReplicaSet을 통한 관리를 하지만, StatefulSet에서는 각 Pod의 순서와 고유성을 보장해준다. Deployment에서의 Pod은 하나의 Pod이 다른 Pod으로 쉽게 대체가 가능하지만, StatefulSet에서는 이것이 불가능하다고 볼 수 있다.

StatefulSet에서는 Pod 마다 고유한 식별자를 부여해 역할을 부여한다. StatefulSet이 필요한 경우는 다음과 같은 경우라고 볼 수 있다.

- 고유의 Pod 식별자가 필요한 경우
- 명시적으로 Pod마다 저장소가 지정되어야 하는 경우
- Pod끼리의 순서에 민감한 경우(마스터 - 워커)
- 순서대로 업데이트가 필요한 경우

> Deployment에서는 Pod 자체적으로 상태를 저장하는 것은 불가능하다. 따라서 DB를 연결하거나 외부 스토리지 연결을 통해 Deployment에서 생성된 Pod의 상태 정보를 저장하고 관리할 수 있다. 하지만 StatefulSet에서는 Pod이 자체적으로 상태 정보를 가지기 때문에 상태 정보가 필요하다면 StatefulSet을 사용하는 것이 합리적인 선택이다.



```YAML
# mysts.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysts
spec:
  serviceName: mysts														# StatefulSet과 연결할 Service 이름 지정
  replicas: 3
  selector:
    matchLabels:																# 라벨링 시스템을 사용하여 Pod 선택
      run: nginx
  template:																			# 복제할 Pod 정의
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: vol
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:													# 동적 Volume 생성
  - metadata:
      name: vol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysts																			# StatefulSet에서 연결할 Service 리소스 생성
spec:
  clusterIP: None
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80
  selector:
    run: nginx
```

StatefulSet 리소스의 YAML 정의서다. 해당 정의서를 가지고 리소스를 생성하고 조회해보자.

```bash
kubectl apply -f mysts.yaml
# statefulset.apps/mysts created
# service/mysts created

kubectl get statefulset   # 축약 시, sts
# NAME    READY   AGE
# mysts   2/3     20s

kubectl get pod
# NAME      READY   STATUS              RESTARTS   AGE
# mysts-0   1/1     Running             0          29s
# mysts-1   0/1     ContainerCreating   0          20s
# mysts-2   0/1     Pending             0          10s
```

Deployment 리소스와 마찬가지로 `replicas`에 지정한 개수만큼 Pod이 생성되지만, Pod를 조회해서 확인을 해보면 랜덤한 해시 값이 Pod의 이름으로 작성된 것이 아니라 `mysts-0`과 같이 Pod의 순서가 적힌 상태로 생성된 것을 확인할 수 있다. 0,1,2라는 숫자가 Pod의 생성 순서이자 식별자가 되는 것이다. 이렇게 생성된 각 Pod는 서로 다른 호스트 이름을 가지고 있어 구분이 가능하다.

```bash
kubectl exec mysts-0 -- hostname
# mysts-0

kubectl exec mysts-1 -- hostname
# mysts-1
```

호스트이름 역시 Pod의 이름과 마찬가지로 0,1,2를 통해 순서와 식별자를 가지고 있음을 알 수 있다. nginx의 html 디렉토리에 각각의 호스트 이름을 저장하고 호출해보자.

```bash
kubectl exec mysts-0 -- sh -c \
  'echo "$(hostname)" > /usr/share/nginx/html/index.html'
kubectl exec mysts-1 -- sh -c \
  'echo "$(hostname)" > /usr/share/nginx/html/index.html'

kubectl exec mysts-0 -- curl -s http://localhost
# mysts-0
kubectl exec mysts-1 -- curl -s http://localhost
# mysts-1
```

YAML 정의서에서 볼륨 마운트를 진행한 경로가 `/usr/share/nginx/html`이기 때문에 StatefulSet의 Pod이 같은 저장소를 바라보고 있다면 `mysts-0`이 `mysts-1`에 의해 덮어져야 하는데, 그것이 아니라 각 Pod이 별도의 볼륨을 사용하고 있기 때문에 서로 다른 값을 가지고 있는 것을 확인할 수 있다. 볼륨을 확인하는 명령을 통해 볼륨 역시 순서와 식별자를 가지고 있는 것을 볼 수 있다.

```bash
kubectl get persistentvolumeclaim
# NAME          STATUS   VOLUME        CAP  MODE   STORAGECLASS   AGE
# vol-mysts-0   Bound    pvc-09d-xxx   1Gi  RWO    local-path     118s
# vol-mysts-1   Bound    pvc-421-xxx   1Gi  RWO    local-path     109s
# vol-mysts-2   Bound    pvc-x42-xxx   1Gi  RWO    local-path     60s
```

StatefulSet은 ReplicaSet, Deployment와 마찬가지로 scale 명령을 통해 Pod의 개수를 조절할 수 있다.

```bash
kubectl scale sts mysts --replicas=0
# statefulset.apps/mysts scaled

kubectl get pod
# NAME      READY   STATUS       RESTARTS   AGE
# mysts-0   1/1     Running      0          29s
# mysts-1   0/1     Terminating  0          20s
```

생성이 0,1,2 순서대로 진행됐다면, Pod의 개수를 줄일 때에는 역순으로 삭제가 진행된다. StatefulSet을 사용하면 이처럼 Pod의 생성 순서를 보장 받거나, 각기 다른 역할을 하는 Pod을 여러 개 만들 때 유용하게 사용할 수 있다.

클러스터 시스템을 구성할 때 StatefulSet을 사용할 수 있다. 클러스터 시스템 구성을 하는 과정에서 리더 선출이나 primary vs replica를 지정하기 위해 명시적은 순서를 지정하는 경우 활용해보자.

> 쿠버네티스 공식 홈페이지에서는 StatefuleSet의 활용 예제로 MySQL 클러스터 구축을 설명하고 있다. 앞에서 진행한 nginx 예제는 StatefulSet의 특징과 역할을 우선적으로 확인하기 위한 것이었고, 필요하다면 직접 이를 확인해보자.
>
> https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/

```bash
kubectl delete sts mysts
kubectl delete svc mysts
kubectl delete pvc --all
```



## 4. DaemonSet

DaemonSet 리소스는 모든 노드에서 동일한 Pod을 실행시키고 싶을 때 사용하는 리소스다. 리소스 모니터링, 로그 수집 등과 같이 모든 노드에서 동일한 Pod이 위치하면서 노드에 대한 정보를 추출할 때 많이 사용한다.

다음은 모든 노드의 로그 정보를 추출하는 fluentd DaemonSet 예시이다.

```yaml
# fluentd.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
      - name: fluentd
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        volumeMounts:
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

DaemonSet의 YAML 정의서다. `template`에 원하는 Pod 스펙을 정의하면 정의한 스펙을 가진 Pod이 모든 노드에서 일괄적으로 실행된다.

```bash
kubectl apply -f fluentd.yaml
# daemonset.apps/fluentd created

kubectl get daemonset   # 축약 시, ds
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE ..
# fluentd   2         2         2       2            2                ..

kubectl get pod -owide
# NAME           READY  STATUS    RESTARTS  AGE   IP          NODE    ..
# fluentd-q9vcc  1/1    Running   0         92s   10.42.0.8   master  ..
# fluentd-f3gt3  1/1    Running   0         92s   10.42.0.10  worker  ..

kubectl logs fluentd-q9vcc
# 2020-07-05 04:12:05 +0000 [info]: parsing config file is succeeded ..
# 2020-07-05 04:12:05 +0000 [info]: using configuration file: <ROOT>
#   <match fluent.**>
#     @type null
#   </match>
# </ROOT>
# 2020-07-05 04:12:05 +0000 [info]: starting fluentd-1.4.2 pid=1 ..
# 2020-07-05 04:12:05 +0000 [info]: spawn command to main: cmdline=..
# ...
```

마스터와 워커로 구성된 노드를 가지고 있다면, 각 노드마다 Pod이 하나씩 생성된다. DaemonSet 리소스는 모든 노드에서 항상 동일한 작업을 수행해야 하는 경우 사용하는 리소스이기 때문이다.

DaemonSet을 사용하면 클러스터에 노드를 새롭게 추가할 때, 따로 작업을 수행하지 않아도 신규로 편입된 노드에도 자동으로 DaemonSet의 `template`을 통해 정의한 Pod들을 생성하게 된다. 그래서 로그 수집이나 리소스 모니터링 등 모든 노드에서 동일하게 필요한 작업이 필요하다면 DaemonSet을 활용하는 것이 좋은 선택이다.

```bash
kubectl delete ds --all
```



## 5. Job & CronJob

### Job

Job 리소스는 일반 Pod 처럼 항상 실행되고 있는 서비스 프로세스가 아닌 한번 실행하고 완료가 되는 배치 전용 프로세스로 만들어졌다. 기계학습 모델을 Job으로 실행하는 시나리오는 다음과 같다.

- train.py : 간단한 기계학습을 진행할 스크립트
- Dockerfile : 기계학습 스크립트를 도커 이미지로 변환
- job.yaml : Job 실행을 위한 YAML 정의서

```python
# train.py
import os, sys, json
import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.optimizers import RMSprop

#####################
# parameters <-- Job 리소스에서 파라미터로 전달할 예정
#####################
epochs = int(sys.argv[1])
activate = sys.argv[2]
dropout = float(sys.argv[3])
print(sys.argv)
#####################

batch_size, num_classes, hidden = (128, 10, 512)
loss_func = "categorical_crossentropy"
opt = RMSprop()

# preprocess
(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train = x_train.reshape(60000, 784)
x_test = x_test.reshape(10000, 784)
x_train = x_train.astype('float32') / 255
x_test = x_test.astype('float32') / 255

# convert class vectors to binary class matrices
y_train = keras.utils.to_categorical(y_train, num_classes)
y_test = keras.utils.to_categorical(y_test, num_classes)

# build model
model = Sequential()
model.add(Dense(hidden, activation='relu', input_shape=(784,)))
model.add(Dropout(dropout))
model.add(Dense(num_classes, activation=activate))
model.summary()

model.compile(loss=loss_func, optimizer=opt, metrics=['accuracy'])

# train
history = model.fit(x_train, y_train, batch_size=batch_size, 
        epochs=epochs, validation_data=(x_test, y_test))

score = model.evaluate(x_test, y_test, verbose=0)
print('Test loss:', score[0])
print('Test accuracy:', score[1])
```

```dockerfile
# Dockerfile
FROM python:3.6.8-stretch

RUN pip install tensorflow==1.5 keras==2.0.8 h5py==2.7.1

COPY train.py .

ENTRYPOINT ["python", "train.py"]
```

```bash
# 도커 이미지 빌드
docker build . -t $USERNAME/train
# Sending build context to Docker daemon  3.249MB
# Step 1/4 : FROM python:3.6.8-stretch
# 3.6.8-stretch: Pulling from library/python
# 6f2f362378c5: Pull complete
# ...

# 도커 이미지 업로드를 위해 도커허브에 로그인합니다.
docker login
# Login with your Docker ID to push and pull images from Docker Hub. ..
# Username: $USERNAME
# Password:
# WARNING! Your password will be stored unencrypted in /home/..
# Configure a credential helper to remove this warning. See
# https://docs.docker.com/engine/reference/commandline/..
# 
# Login Succeeded

# 도커 이미지 업로드
docker push $USERNAME/train
# The push refers to repository [docker.io/$USERNAME/train]
```

```yaml
# job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob
spec:
  template:
    spec:
      containers:
      - name: ml
        image: $USERNAME/train
        args: ['3', 'softmax', '0.5']
      restartPolicy: Never
  backoffLimit: 2
```

Job 리소스도 내부적으로 Pod을 실행하기 때문에 `template`을 통해 Pod의 스펙을 정의해주었다. `backoffLimit`를 통해 재시도 횟수를 지정할 수 있는데, Job이 실행되고 총 2번의 재시도 후에도 실패하면 최종적으로 실패로 기록된다.

```bash
# Job 생성
kubectl apply -f job.yaml
# job.batch/myjob created

# Job 리소스 확인
kubectl get job
# NAME    COMPLETIONS   DURATION   AGE
# myjob   0/1           9s         9s

# Pod 리소스 확인
kubectl get pod
# NAME          READY   STATUS      RESTARTS   AGE
# myjob-l5thh   1/1     Running     0          9s

# 로그 확인
kubectl logs -f myjob-l5thh 
# ...
# Layer (type)                 Output Shape              Param #
# =================================================================
# dense_1 (Dense)              (None, 512)               401920
# ...

# Pod 완료 확인
kubectl get pod
# NAME          READY   STATUS      RESTARTS   AGE
# myjob-l5thh   0/1     Completed   0          3m27s

# Job 완료 확인
kubectl get job
# NAME    COMPLETIONS   DURATION   AGE
# myjob   1/1           51s         4m
```

Job 리소스로 배치 작업이 종료되면 Pod은 Completed로 남게 된다.

의도적으로 장애 상황을 만들어 재시도 작업을 수행하는지(`backoffLimit` 테스트) 확인할 차례이다. `backoffLimit`을 2로 설정했기 때문에 첫 번째 시도와 두 번의 재시도, 총 3번의 시도를 하게 된다.

```yaml
# job-bug.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob-bug
spec:
  template:
    spec:
      containers:
      - name: ml
        image: $USERNAME/train
        # int 타입이 아닌 string 타입 전달
        args: ['bug-string', 'softmax', '0.5']
      restartPolicy: Never
  backoffLimit: 2
```

```bash
kubectl apply -f job-bug.yaml

# 2번 재시도 후(총 3번 실행) failed
kubectl get pod
# NAME               READY   STATUS              RESTARTS   AGE
# myjob-bug-8f867      0/1     Error               0          6s
# myjob-bug-s23xs      0/1     Error               0          4s
# myjob-bug-jz2ss      0/1     ContainerCreating   0          1s

kubectl get job myjob-bug -oyaml | grep type
# type: Failed

# 에러 원인 확인
kubectl logs -f myjob-bug-jz2ss
# /usr/local/lib/python3.6/site-packages/tensorflow/python/framework/
#   dtypes.py:502: FutureWarning: Passing (type, 1) or '1type' 
#   as a synonym of type is deprecated; in a future version of numpy, 
#   it will be understood as (type, (1,)) / '(1,)type'.
#   np_resource = np.dtype([("resource", np.ubyte, 1)])
# Traceback (most recent call last):
#   File "train.py", line 11, in <module>
#    epochs = int(sys.argv[1])
# ValueError: invalid literal for int() with base 10: 'bug-string'
```

```bash
kubectl delete job --all
```



### CronJob

Job이 한 번의 작업을 완료하고 Completed가 되는 Pod을 만드는 것이라면, CronJob은 주기적으로 Job을 실행시킬 수 있는 확장된 리소스다. 리눅스의 crontab과 마찬가지로 cron 형식을 이용하여 주기를 정할 수 있다.

```yaml
# cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"						# Job 리소스를 실행할 실행 주기
  jobTemplate:											# Job 리소스에서 사용할 Pod의 스펙 정의
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

```bash
kubectl apply -f cronjob.yaml
# cronjob.batch/hello created

kubectl get cronjob
# NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# hello   */1 * * * *   False     0        <none>          4s

kubectl get job
# NAME               COMPLETIONS   DURATION   AGE
# hello-1584873060   0/1           3s         3s
# hello-1584873060   0/1           3s         62s
```

```bash
kubectl delete cronjob --all
```

CronJob은 동일한 주기마다 반복해서 실행해야 하는 작업을 할 때 활용할 수 있다.

### 

쿠버네티스는 모든 것을 리소스로 표현한다. 그리그 빌딩블럭처럼 작은 단위의 리소스를 조합하여 점점 더 큰 리소스로 만들어 사용하게 된다.

1. 사용자는 컨테이너를 모아 Pod을 만든다.

2. 이렇게 만들어진 Pod은 Deployment와 Service로 묶여 작은 컴포넌트가 된다.

3. 작은 컴포넌트들이 모여 하나의 거대한 어플리케이션이 된다.