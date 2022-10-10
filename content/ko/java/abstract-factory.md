---
title: "추상 팩토리 패턴"
date: 2022-10-02T19:38:09+09:00
draft: true
mermaid: true
tags:
- abstract-factory
categories:
- design pattern
---
추상 팩토리 패턴에 대해 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 추상 팩토리 패턴

{{<mermaid>}}
classDiagram
    class AbstractFactory {
        + createProductA(): ProductA
        + createProductB(): ProductB
    }
    class ConcreteFactory {
        + createProductA(): ProductA
        + createProductB(): ProductB
    }
    class ProductA
    class ConcreteProductA
    class ProductB
    class ConcreteProductB
    class Client {
        - factory: AbstractFactory
        + Client(AbstractFactory) 
    }

    AbstractFactory <|-- ConcreteFactory
    ProductA <|-- ConcreteProductA
    ProductB <|-- ConcreteProductB

    AbstractFactory <|.. ConcreteProductA: use
    AbstractFactory <|.. ConcreteProductB: use
    
    Client <|.. AbstractFactory: use
{{</mermaid>}}

추상 팩토리 패턴은 기본적으로 팩토리 메서드 패턴을 기반으로 확장된다. 추상 팩토리 패턴의 클래스 다이어그램을 살펴보면 `AbstractFactory`와 `ProudctA`, `ProductB` 사이의 관계가 팩토리 메서드 패턴에서의 관계와 동일한 것을 확인할 수 있다.

`AbstractFactory` 레이어를 하나 더 추가하여 인스턴스 생성에 대한 책임은 `ConcreteFactory`가 가지게 되고, 팩토리를 통해 생성할 인스턴스 역시 `ProductA`, `ProductB`라는 인터페이스로 추상화 되어 있다.

여기서 추상 팩토리 패턴은 팩토리의 사용자인 `Client`가 추가된 구조를 가진다. 사용자는 `AbstractFactory`의 인스턴스 생성 메서드를 사용해서 원하는 인스턴스를 받아 사용할 수 있는데, 인스턴스의 타입이 각각 `ProductA`, `ProductB`와 같이 인터페이스화 되어 있어서 구체적으로 어떤 구현체의 인스턴스인지 감춰진 상태가 된다.

사용자가 `createProductA`를 사용하면 `ProductA`의 구현체가 나오는데, 인터페이스를 사용하고 있기 때문에 `ProductA`의 하위 클래스를 손쉽게 추가할 수 있게 된다. 마찬가지로 `createProductB` 메서드를 사용하면 `ProductB`의 하위 클래스를 가져와 사용할 수 있게 되는데, 이 역할을 `AbstractFactory`로 추상화 시켜 각 제품군의 구현체를 생성하는 과정 역시 추상화된다.

추상 팩토리를 통해 사용자가 사용하는 `Product`가 추상화되고, 인스턴스를 생성하는 `Factory`가 추상화되어 각 인터페이스와 연관이 있는 구현체들을 묶어서 사용할 수 있게 된다.