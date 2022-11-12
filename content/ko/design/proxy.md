---
title: "프록시 패턴"
date: 2022-11-12T16:23:29+09:00
draft: true
mermaid: true
tags:
- proxy
categories:
- design pattern
---
프록시 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 프록시 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Subject {
        + operation()
    }
    class RealSubject {
        + operation()
    }
    class Proxy {
        - subject: Subject
        + operation()
    }
    Subject <-- Client
    Subject <|-- RealSubject
    Subject <|-- Proxy
    RealSubject <-- Proxy
{{</mermaid>}}

프록시 패턴은 특정 객체의 인스턴스에 직접 접근해서 사용하는 것이 아니라 프록시로 래핑된 프록시 객체를 통해 사용하게 만드는 것을 의미한다.

프록시 인스턴스 내부에 들어있는 실제 인스턴스를 가지고 작업을 실행하기 전에 프록시에서 정의한 다양한 작업들을 수행할 수 있게 된다.(지연 로딩, 접근 제어, 로깅, 캐싱 등)

프록시 패턴을 사용하는 경우 실제 인스턴스의 코드 변경 없이 다양한 작업을 수행할 수 있다는 점에서 개방 폐쇄 원칙을 지키게 되며, 타겟 인스턴스에서는 본연의 임무에만 충실한다는 점에서 단일 책임 원칙도 지킨다고 볼 수 있다.
