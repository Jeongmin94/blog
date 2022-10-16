---
title: "프로토타입 패턴"
date: 2022-10-15T20:04:00+09:00
draft: true
mermaid: true
tags:
- prototype pattern
categories:
- design pattern
---
프로토타입 패턴에 대해 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 프로토타입 패턴

{{<mermaid>}}
classDiagram
    class Prototype {
        + clone()
    }
    class ConcretePrototypeA {
        + clone()
    }
    class ConcretePrototypeB {
        + clone()
    }
    class client
    Prototype <|-- ConcretePrototypeA
    Prototype <|-- ConcretePrototypeB
    Prototype <-- client
{{</mermaid>}}

프로토타입 패턴은 기존 인스턴스를 복사해서 새로운 인스턴스를 만드는 디자인 패턴이다. 프로그래밍을 하다보면 이미 생성된 인스턴스에서 필요한 값만 수정한 새로운 인스턴스가 필요한 경우가 있다. 프로토타입은 이러한 경우에 적용시켜볼 수 있는 디자인 패턴이다.

인스턴스를 생성하기 위한 다양한 방법이 존재하는데, 굳이 프로토타입이라는 패턴까지 도입해서 기존 인스턴스를 복사해서 새로운 인스턴스를 만드는 것이 필요할까라는 생각을 할 수 있다.

하지만 데이터베이스에 저장된 데이터를 읽어와 새로운 인스턴스를 만들거나, 네트워크 통신을 통해 전달받은 데이터를 기반으로 인스턴스를 만드는 작업은 인스턴스 생성에 필요한 시간과 데이터 전송에 필요한 시간이 동시에 필요하다. 이런 경우에 새로운 인스턴스를 생성할 때마다 데이터 전송을 위해 소모되는 시간이 추가적으로 발생하게 되는데, 프로토타입 패턴을 도입하여 통신 코스트를 줄일 수 있게 된다.


