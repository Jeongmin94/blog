---
title: "플라이웨이트 패턴"
date: 2022-11-07T23:00:17+09:00
draft: true
mermaid: true
tags:
- flyweight
categories:
- design pattern
---
플라이웨이트 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 플라이웨이트 패턴

{{<mermaid>}}
classDiagram
    class Client
    class FlyweightFactory {
        - cache: Flyweight[]
        + getFlyweight(intrinsitState)
    }
    class Flyweight {
        - intrinsitState
        + operation(extrinsitState))
    }
    FlyweightFactory <-- Client
    Flyweight <-- Client
    Flyweight <-- FlyweightFactory
{{</mermaid>}}

플라이웨이트 패턴은 자주 사용하는 부분과 그렇지 않은 부분을 분리해서, 자주 사용하는 부분을 재사용할 수 있도록 만들어 주는 패턴이다.

클래스의 인스턴스 크기가 큰 경우, 매번 새로운 인스턴스를 만들어 사용하기 어려운데, 자주 사용하는 부분을 재사용할 수 있게 만들면 이러한 문제를 해결할 수 있게 된다.

이러한 행위를 통해 얻을 수 있는 이점은 객체의 크기를 가볍게 만들어 메모리의 사용량을 줄일 수 있다는 것이다. 플라이웨이트라는 이름처럼 객체를 가볍게 만드는 것이다.

자주 변하는 부분은 `extrinsit`이라고 하고, 자주 변하지 않는 부분은 `intrinsit`이라고 한다. 플라이웨이트 패턴에서는 `FlyweightFactory`에서 자주 사용하는 부분을 캐싱을 해놓고, 사용자로부터 자주 사용하는 `intrinsit`에 해당하는 `Flyweight` 객체에 대한 요청을 받으면 이를 즉시 리턴해주게 된다.