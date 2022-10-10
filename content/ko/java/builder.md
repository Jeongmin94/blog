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