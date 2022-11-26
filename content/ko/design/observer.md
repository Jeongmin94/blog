---
title: "옵저버 패턴"
date: 2022-11-26T16:16:27+09:00
draft: true
mermaid: true
tags:
- obserer
categories:
- design pattern
---
옵저버 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 옵저버 패턴

{{<mermaid>}}
classDiagram
    class Subject {
        - observers: Observer[]
        + subscribe(Observer)
        + unsubscribe(Observer)
        + notify()
    }
    class Observer {
        + update()
    }
    class ConcreteObserver {
        + update()
    }
    Observer <-- Subject
    Observer <|-- ConcreteObserver
{{</mermaid>}}

옵저버 패턴은 여러 객체가 특정 객체의 상태 변화를 감지하고, 그에 따라 반응을 해야 할 때 사용할 수 있는 디자인 패턴이다. 옵저버 패턴을 사용하면 pub/sub 패턴을 손쉽게 구현할 수 있게 된다.

옵저버 패턴을 적용하면 상태를 변경하는 객체(publisher)와 변경을 감지하는 객체(subscriber)의 관계를 느슨하게 유지할 수 있다.

그리고 subject의 상태 변경을 감지하는 측에서 주기적으로 조회하지 않고, publisher 측에서 notify를 주기 때문에 불필요한 조회를 줄일 수 있다.

또한, 옵저버를 등록, 해제할 수 있는 subscribe, unsubscribe를 제공하기 때문에 런타임에 옵저버 추가, 제거가 쉽게 가능하다.

하지만 복잡도가 증가하고, 등록된 옵저버를 사용하지 않는 경우에 반드시 해제를 해주어야 메모리 손실을 줄일 수 있게 된다.