---
title: "데코레이터 패턴"
date: 2022-10-30T12:47:58+09:00
draft: true
mermaid: true
tags:
- decorator
categories:
- design pattern
---
데코레이터 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 데코레이터 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Component {
        + operation()
    }
    class ConcreteComponent {
        + operation()
    }
    class Decorator {
        + wrapee: Component
    }
    class ConcreteDecorator1 {
        + operation()
        + extraOperation()
    }
    class ConcreteDecorator2 {
        + operation()
        + extraOperation()       
    }
    Component <-- Client
    Component <|-- ConcreteComponent
    Component <|-- Decorator
    Decorator <|-- ConcreteDecorator1
    Decorator <|-- ConcreteDecorator2
{{</mermaid>}}

데코레이터 패턴은 기존 코드를 변경하지 않고 부가 기능을 추가할 수 있는 패턴이다. 대부분의 프로그래밍 언어에서는 다중 상속을 지원하지 않기 때문에 상속을 통한 부가 기능 추가는 유연하지 못하다는 단점을 가지고 있다.

그래서 데코레이터 패턴에서는 상속이 아닌 위임을 통해 런타임에 부가 기능을 추가해주는 방식을 사용하여 유연한 프로그래밍을 가능하게 해준다.

클라이언트는 Component라는 인터페이스만을 사용한다. 그리고 Component는 인터페이스의 구현체와 Decorator라는 타입을 가진 인터페이스를 멤버로 가지고 있다.

여기까지만 봤을 때, Decorator를 Composite로 변환한다면 데코레이터 패턴은 컴포지트 패턴과 매우 유사한 구조를 가지고 있는 것을 볼 수 있다. 하지만 컴포지트 패턴은 추상화 된 특정한 작업을 재귀적으로 호출하여 간단하게 처리할 수 있는 것에 초점이 맞춰져 있다.

데코레이터 패턴은 이름 그대로, Component가 가지고 있는 주요 기능에 부가적인 기능을 담당하는 Decorator 계층을 추가하여 주 기능과 함께 사용되는 부가 기능을 추가하는 것에 초점이 있다.

데코레이터 패턴을 부가 기능을 담당하는 각 Decorator의 구현체들은 자신의 역할만 수행하면 되기 때문에 단일 책임 원칙을 만족하게 되며, 클라이언트의 코드 변경 없이 새로운 Decorator를 통해 부가 기능을 추가할 수 있어 개방 폐쇄 원칙도 만족하게 된다.

Decorator는 기본적으로 Component의 주요 기능과 별개로 실행되는 부가 기능에 대한 책임을 가지고 있기 때문에, 부가 기능을 모두 처리하고 나면 주요 기능을 실행하게 된다. 따라서 사용자가 원하는 바에 따라 여러 Decorator를 조합해서 사용할 수 있는데, 상속이 아닌 위임을 통해 부가 기능이 추가되어 런타임에 기능을 변경할 수 있다는 장점을 가지게 된다.