---
title: "이터레이터 패턴"
date: 2022-11-20T09:28:51+09:00
draft: true
mermaid: true
tags:
- iterator
categories:
- design pattern
---
이터레이터 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 이터레이터 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Iterator {
        + getNext()
        + hasNext()
    }
    class ConcreteIterator {
        + getNext()
        + hasNext()
    }
    class Aggregate {
        + createIterator(): Iterator
    }
    class ConcreteAggregate {
        + createIterator(): Iterator
    }
    Iterator <-- Client
    Aggregate <-- Client
    Iterator <|-- ConcreteIterator
    Aggregate <-- ConcreteAggregate
    ConcreteIterator <--> ConcreteAggregate
{{</mermaid>}}

이터레이터 패턴은 내부 구현을 알 필요 없이 집합 객체의 요소들을 순회할 수 있는 방법을 제공해주는 패턴이다.

집합 객체가 가지고 있는 객체를 손쉽게 접근할 수 있게 되고, 내부 구현에 대한 정보를 알 필요 없이 간단하게 순회가 가능해진다. 순회에 대한 책임을 이터레이터 객체에서 담당하기 때문에 단일 책임 원칙을 충족시키며, 집합 객체의 구현이 변경될 때마다(리스트, 맵, 세트 등) 이에 해당하는 타입의 새로운 이터레이터를 만들어 주입시켜 사용할 수 있기 때문에 개방 폐쇄 원칙도 만족하게 된다.

따라서 집합 객체의 내부 구조가 변경될 가능성이 있다면, 사용자에게 직접 집합 객체를 노출시키는 것보다 이터레이터 패턴을 적용하여 변화에 유연하게 대응할 수 있게 만드는 것이 좋은 방법이 될 수 있다.