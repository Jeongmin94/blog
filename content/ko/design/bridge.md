---
title: "브리지 패턴"
date: 2022-10-26T21:34:32+09:00
draft: true
mermaid: true
tags:
- bridge
categories:
- design pattern
---
브리지 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 브리지 패턴

{{<mermaid>}}
classDiagram
    class Client
    class Abstraction {
        - internal: Implementation
        + operation()
    }
    class RefinedAbstraction {
        - internal: Implementation
        + operation()
    }
    class Implementation {
        + method()
    }
    class ConcreteImplenetation {
        + operation()
    }
    Abstraction <-- Client
    Implementation <-- Abstraction
    Abstraction <|-- RefinedAbstraction
    Implementation <|-- ConcreteImplenetation
{{</mermaid>}}

브리지 패턴은 추상적인 것과 구체적인 것을 분리하여 이것을 연결하는 패턴이다. 하나의 계층 구조가 아닌 여러 구조로 나누어 사용하기 때문에 독립적인 계층으로 발전 시켜 사용할 수 있게 된다.

클라이언트는 특정 클래스의 구현체를 직접 사용하는 대신 Abstraction과 같이 추상화 된 계층으로 자신이 원하는 작업을 수행하게 된다.

여기서 클라이언트는 Abstraction으로 추상화 된 계층을 사용하기 때문에 하위 클래스를 교환하면 언제든지 작업 내용을 바꿀 수 있게 된다.

마찬가지로 Abstraction 계층에서도 Implementation이라는 또 다른 추상화 된 계층을 이용해서 원하는 작업을 수행하게 된다. Implementation의 하위 구현체를 교체하면 작업 내용을 바꾸는 것 역시 가능해진다.

브리지 패턴을 적용하게 되면 클라이언트 입장에서는 Abstraction으로 대표되는 추상화 계층만 이용을 하게 되고, 어떤 하위 구현체가 들어오는지 신경을 쓰지 않아도 된다. 마찬가지로 Abstraction에서 사용하는 Implementation 역시 Abstraction 계층에서는 신경을 쓰지 않아도 된다.

이렇게 추상적인 것과 구체적인 것을 분리해 놓은 계층을 만들어 서로를 연결시켜 놓게 되면, 추상 계층의 하위 구현체를 추가하는 것으로 다른 코드에 영향을 주지 않고 독립적으로 확장 시킬 수 있게 된다. 또한, 추상 계층과 구현 계층 분리를 통해 사용자 입장에서는 하위 클래스에 종속되지 않는다는 장점도 가지게 된다.