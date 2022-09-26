---
title: "싱글톤 패턴"
date: 2022-09-26T22:59:06+09:00
draft: true
mermaid: true
tags:
- singleton
categories:
- design pattern
---
싱글톤 패턴을 알아본다.
<!--more-->

> 코딩으로 학습하는 GoF의 디자인 패턴(https://inf.run/W9wa)

# 싱글톤(Singleton) 패턴

{{<mermaid>}}
classDiagram
    class Singleton {
        - instance Singleton
        + getInstance(): Singleton
    }
{{</mermaid>}}

싱글톤 패턴은 오직 한개의 인스턴스만 제공하는 클래스를 만들어 사용한다.

시스템 런타임, 환경 설정 등 인스턴스가 하나만 필요한 경우에 유용하게 사용할 수 있는 것이 바로 싱글톤 패턴이다.

오직 하나의 인스턴스만 만들기 위해서는 어떻게 할 수 있을까? 가장 간단한 방법은 private 생성자를 하나 만들어 놓고, 접근은 static 키워드를 사용해서 가능하게 만드는 것이다.

```java
public class Setting {
    private static Setting INSTANCE;

    private Setting() {}

    public static Setting getInstance() {
        if(INSTANCE == null) {
            INSTANCE = new Setting();
        }

        return INSTANCE;
    }
}
```

이렇게 `Setting` 클래스는 오직 private 접근 제한자를 가진 생성자 하나만을 가지고 있기 때문에 외부에서 인스턴스에 접근하는 방법은 오로지 static 메서드만 존재하게 된다.

이 상황에서 `getInstance` 메서드를 호출하게 되면 `INSTANCE`가 null일 때 단 한 번 초기화 되고 리턴된다.

그러나 이 방법은 멀티 스레드 환경에서 심각한 문제를 야기한다. 여러 스레드가 동시에 `getInstance` 메서드를 호출하게 되면 컨텍스트 스위칭이 발생하는 순간에 `INSTANCE == null`이라는 조건을 통과하는 스레드가 여러개가 될 수있다. 그렇게 되면 각자의 스레드가 가지고 있는 `INSTACNE`는 싱글톤이 아니게 된다.