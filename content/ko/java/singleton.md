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

## 멀티 스레드 환경에서 안전하게 싱글톤 구현하기

### 1. synchronized 사용

자바에는 synchronized 키워드가 있다. synchronized 키워드를 사용하면 특정 메서드에 락을 걸어 동시에 한 스레드만 접근이 가능하게 된다.

```java
public class Setting {
    private static Setting INSTANCE;

    private Setting() {}

    public static synchronized Setting getInstance() {
        if(INSTANCE == null) {
            INSTANCE = new Setting();
        }

        return INSTANCE;
    }
}
```

이와 같이 `getInstance` 메서드에 synchronized를 사용하게 되면 아무리 많은 스레드가 있더라도 한 스레드에서만 `getInstance` 메서드에 접근할 수 있다.

> `static synchronized`를 사용하게 되면 클래스 단위로 메서드에 접근할 수 있게 된다. `Setting` 클래스의 인스턴스가 여러개 생성되어도 static 메서드는 공유해서 사용하기 때문이다.
> `synchronized`를 사용하면 인스턴스 단위로 메서드 접근이 가능해진다. 즉, A라는 인스턴스가 여러 스레드에서 실행될 때 `synchronized` 키워드가 붙은 메서드에 대한 동기화는 가능하지만, A,B 인스턴스가 있을 때에는 A,B 사이의 동기화는 불가능하다. A,B 사이의 동기화가 필요하다면 static 키워드를 사용하자.

### 2. 즉시 초기화(eager initializaion) 사용

즉시 초기화는 정적 바인딩을 이용해서 클래스의 인스턴스를 미리 생성해놓고, 이를 가져다 사용하는 방식이다. 어떻게 보면 가장 간단한 방식으로 멀티 스레드에서도 안전하게 사용할 수 있는 방법이다.

```java
public class Setting {
    private static final Setting INSTANCE = new Setting();

    private Setting() {}

    public static Setting getInstance() {
        return INSTANCE;
    }
}
```

다만, 정적 바인딩을 통해 인스턴스를 생성하고 있기 때문에 static 블록이나 static 메서드를 따로 사용해서 인스턴스 생성시 발생하는 예외를 처리해야 할 수도 있다.

```java
// static 블록 사용하여 예외 처리
private static Setting INSTANCE;
static {
    try {
        INSTANCE = new Setting();
    } catch (Exception e) {
        // exception
    }
}

// static method 사용하여 예외 처리
private static final Setting INSTANCE = createInstance();

private static Setting createInstance() {
    try {
        return new Setting();
    } catch (Exception e) {
        // exception
    }
    return null;
}
```

그리고 미리 인스턴스를 생성해 놓기 때문에 인스턴스가 필요하지 않은 순간에도 메모리를 잡아먹고 있다는 단점을 가진다.

### 3. 더블 체크 락 사용

`synchronized`를 사용하면 나중에 인스턴스를 만들 수 있지만 여러 스레드에서 인스턴스에 대한 접근을 시도할 때에는 스레드 대기 시간이 너무 길어지고, 정적 바인딩을 사용하면 일정 시간 동안 메모리 공간을 낭비하는 것 같다. 그럴 때 synchronized 키워드를 조금 더 효과적으로 사용할 수 있는 더블 체크 락을 사용해볼 수 있다.

```java
public class Setting {
    private static volatile Setting INSTANCE;

    private Setting() {}

    public static Setting getInstance() {
        if(INSTANCE == null) {
            synchronized(Setting.class) {
                if(INSTANCE == null) {
                    INSTANCE = new Setting();
                }
            }
        }
        return INSTANCE;
    }
}
```

이름 그대로 인스턴스가 null인지 두 번 확인을 한다. 첫 번째 조건에는 동기화가 안되어 있지만, 동기화 블록에서 다시 null 체크를 하기 때문에 INSTACNE 객체가 원자적으로 생성될 수 있다.

여기에 인스턴스까지 volatile로 선언하여야 안전하게 싱글톤 객체가 생성됨을 보장할 수 있다. 

메서드에 synchronized 키워드를 사용하는 방법에서는 인스턴스를 생성하고, 그 데이터를 메모리에 위치시키는 것까지 모두 동기화 블록 내에서 이루어진다. 따라서 `static synchronized` 메서드를 사용해서 싱글톤 인스턴스를 생성할 때에는 `INSTANCE`에 volatile 키워드를 사용할 이유가 없다.

반면, 더블 체크 락 방식에서는 동기화 블록에서 벗어날 때, 동기화 블록에서 생성된 인스턴스를 온전히 메모리에 위치시키기 전에 컨텍스트 스위칭으로 인해 다른 스레드가 동기화 블록에서 또 새로운 인스턴스를 생성시킬 수 있는 기회를 줄 수 있다. 이는 멀티 스레드에서 캐시 메모리 사용에 따라 발생하는 문제로, 캐시 메모리에 적재되어 있는 인스턴스 데이터가 메모리에 반영되지 않았기 때문에 다른 스레드에서는 동기화 블록에 입장하여도 `INSTANCE == null`이 될 수 있다.

이러한 문제를 해결하기 위해 `INSTANCE`의 데이터는 캐시에 저장하지 않고 온전히 메모리에만 위치시키게 만드는 volatile 키워드를 사용한 것이다.

### 4. static inner 클래스 사용

자바에서 static 클래스는 메모리에 로드되어 있긴 하지만, 그 내부의 멤버들은 호출되기 전까지는 초기화 되지 않는다.

```java
public class Setting {
    private Setting() {}

    public static class SettingHolder {
        private static final Settings SETTINGS = new Settings();
    }

    public static Setting getInstance() {
        return SettingHolder.SETTINGS;
    }
}
```

이를 이용해서 싱글톤 패턴을 구현하면 위와 같다. 내부에 인스턴스를 가지고 있는 홀더를 static inner로 만들어 준다. `Setting` 클래스의 인스턴스는 홀더 내부에서 생성을 해주는데, `getInstance`가 호출되기 전까지는 인스턴스가 생성되지 않는다. `getInstance`가 호출되면 메모리에 로드되어 있던 홀더의 데이터를 기반으로 홀더 초기화가 진행되고, 이를 통해 필요한 시점에 싱글톤 인스턴스를 리턴 받아 사용할 수 있게 된다.