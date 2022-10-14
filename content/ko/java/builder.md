---
title: "빌더 패턴"
date: 2022-10-10T18:17:22+09:00
draft: true
mermaid: true
tags:
- builder pattern
categories:
- design pattern
---
빌더 패턴에 대해 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 빌더 패턴

{{<mermaid>}}
classDiagram
    class Builder {
        + buildStepA()
        + buildStepB()
        + getProduct(): Product
    }
    class ConcreteBuilderA {
        + buildStepA()
        + buildStepB()
        + getProduct(): Product
    }
    class Client
    class Product
    class Director {
        - builder: Builder
        + Director(Builder)
        + construct()
    }
    Builder <|-- ConcreteBuilderA
    Director <-- Client
    Builder <-- Director
{{</mermaid>}}

빌더 패턴은 다양한 구성을 가진 인스턴스의 생성을 동일한 로직을 통해 생성할 수 있게 도와주는 패턴이다. 인스턴스가 가지고 있는 프로퍼티의 개수나 종류에 따라 인스턴스 생성에 필요한 인수의 수도 늘어나게 되는데, 모든 종류의 생성자를 만들 수 없기 때문에 빌더 패턴을 이용해서 이런 복잡한 과정을 하나의 방법으로 처리할 수 있게 된다.

Director를 사용한다면 사용자 입장에서 복잡한 인스턴스의 생성 로직을 신경쓰지 않고 미리 정의해둔 로직에 기반을 두어 인스턴스를 생성해 사용할 수 있기 때문에 사용자 편의적인 측면에서도 장점을 가지고 있다.

또한, 빌더 패턴을 사용하는 경우 `getPorduct`와 같은 구현체를 생성하는 메서드를 가지고 있기 때문에 사용자에게 인스턴스를 확실하게 전달시켜줄 수 있다는 장점을 가지기도 한다.

여기에 개발자의 의도에 따라 인스턴스를 만드는 과정에서 특정 로직에 대한 검증 과정을 추가할 수 있기 때문에, 생성자에 인수가 많거나, 인스턴스 생성에 필요한 중요한 검증 로직이 있다면 빌더 패턴을 도입해볼 수 있다.