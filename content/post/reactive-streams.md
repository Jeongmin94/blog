---
title: "Reactive Streams"
date: 2022-07-21T09:55:17+09:00
draft: false
tags:
- reactive-streams
categories:
- WebFlux
---



# 리액티브 스트림즈(Reactive Streams)

> 참고
>
> https://engineering.linecorp.com/ko/blog/reactive-streams-with-armeria-1/

스프링 웹 프레임워크는 스프링 5 이후로 크게 두 가지 포트폴리오를 제공해준다. 하나는 서블릿 기반의 스프링 MVC이고, 다른 하나는 리액티브 스트림즈 기반의 스프링 WebFlux이다. WebFlux는 리액티브 스트림즈의 구현체인 Project Reactor 기반으로 구현이 되어 있기 때문에 WebFlux를 이해하기 위해선 리액티브 스트림즈에 대한 이해가 필요하다고 할 수 있다.



## 리액티브 프로그래밍

스프링의 리액티브 공식 페이지(https://spring.io/reactive)에서는 리액티브라는 단어의 뜻과 함께 리액티브 프로세싱에 대해서 설명을 해주고 있다.

> Reactive
>
> - Reactive systems have certain characteristics that make them ideal for low-latency, high-throughput workloads. 
>
> What is reactive Processing?
>
> - Reactive processing is a paradigm that enables developers build non-blocking, asynchronous applications that can handle back-pressure (flow control).

스프링의 리액티브 시스템은 몇 가지 특징 덕분에 낮은 지연 시간(low-latency)과 높은 처리율(high-throuput)이 필요한 작업에 이상적이라고 설명하고 있다. 어떤 특징 때문에 리액티브 시스템이 이와 같은 장점을 가지고 있는지는 리액티브 프로세싱에 대한 설명에서 바로 나온다. 리액티브 프로세싱(혹은 프로그래밍)은 백프레셔를 통해 데이터 처리량을 조절하는 비동기, 논블로킹 방식의 어플리케이션이라는 것이다.

이는 스프링 리액티브 시스템의 표준이라고 볼 수 있는 리액티브 스트림즈의 공식 문서(http://www.reactive-streams.org/)에서도 비슷하게 언급되고 있다.

> Reactive Streams is an initiative to provide a standard for asynchronous stream processing with non-blocking back pressure. 

결국 핵심은 `비동기`, `논블로킹`, `스트리밍`, `백프레셔`이 되는 것이다.



#### 비동기 - 논블로킹

동기 방식에서는 서버에 요청을 보내고 응답을 받기 까지 블로킹이 되는 것이 일반적이다. 블로킹이 되면서 현재 작업중인 스레드는 대기 상태에 놓이게 되어 놀게 되는 것이다.

반면 비동기로 작업을 처리한다면 요청에 대한 응답을 받기까지 대기하지 않고 다른 작업을 처리할 수 있기 때문에 작업 처리율이 높고 빠른 응답 속도를 가질 수 있게 되는 것이다.



#### 스트리밍

전통적인 데이터 처리 방식은 요청에 대한 응답으로 전달할 데이터를 모두 메모리에 로드한 뒤, 이를 보내주는 것이다. 하지만 메모리의 용량보다 큰 데이터를 로드해야 하는 경우 OOM 문제가 발생할 수 있고, 순간적으로 요청이 몰리는 경우 다량의 GC가 발생하여 서버가 작동하지 않는 경우가 발생할 수 있다.

스트리밍 방식은 전통적인 방식과는 다르게 데이터를 전부 메모리에 로드하는 것이 아니라 입력 데이터에 대한 파이프 라인을 만들어 데이터가 들어오는 대로 구독 - 데이터 처리 - 발행까지 한 번에 연결하여 처리하기 때문에 탄력적인 데이터 처리가 가능하다.



#### 백프레셔

스트리밍 방식에서 구독 - 데이터 처리 - 발행이라는 과정을 언급했다. 발행은 발행자가 구독자에게 데이터를 전달하는 것이고, 구독은 구독자가 발행자로부터 데이터를 전달 받는 것을 의미한다. 옵저버 패턴에서 발행자는 구독자가 데이터를 얼마나 수용할 수 있는지를 고려하지 않고 데이터를 전달한다.

구독자가 데이터를 수용하고 처리하는 속도가 발행자가 데이터를 가공하여 전달하는 속도보다 느린 경우, 구독자의 수용치를 초과한 데이터는 큐를 이용해서 대기시킨다. 하지만 메모리는 항상 한정되어 있기 때문에 큐의 용량을 초과하는 경우 신규 데이터는 거부하거나, 에러를 발생시키는 현상이 발생하게 된다.

여기에서 백프레셔가 등장한다. 구독자가 자신이 처리할 수 있는 양만큼의 데이터를 요청하면 큐를 별도로 관리할 필요가 없어지고, 네트워크에서 낭비되는 자원도 없어지게 될 것이다. 또한, 구독자가 현재 처리하고 있는 데이터와 가용할 수 있는 메모리를 계산하여 자신이 처리 가능한 범위 내에서 추가적인 요청도 가능해지게 되어 조금 더 유연하게 데이터 처리를 할 수 있게 된다.

#### 

#### 리액티브 스트림즈

결과적으로 리액티브 이 핵심 개념들을 이용해서 공식 문서에서 설명되어 있는 것처럼, 빠른 응답 속도 - 높은 작업 처리율을 가진 프로그래밍 방식이라고 생각하면 될 것이다.





## 리액티브 스트림즈 API

```java
public interface Publisher<T> {
  // Subscriber의 구독을 받기 위한 메서드
  public void subscribe(Subscriber<? super T> s);
}
 
public interface Subscriber<T> {
  public void onSubscribe(Subscription s);			// Subscription을 받기 위한 메서드
  public void onNext(T t);											// Publisher로 부터 받은 데이터 처리를 위한 메서드
  public void onError(Throwable t);							// 에러를 처리하는 메서드
  public void onComplete();											// 작업 완료 시 사용하는 메서드
}
 
public interface Subscription {
  public void request(long n);									// n개의 데이터 요청을 위한 메서드
  public void cancel();													// 구독을 취소하기 위한 메서드
}
```

리액티브 스트림즈에서 사용하는 인터페이스는 이게 전부다. 실제 리액티브 스트림즈를 사용하는 흐름은 다음과 같다.

1. Subscriber가 `subscribe` 메서드를 사용해 Publisher에게 구독 요청
2. Publisher는 Subscriber가 가지고 있는 `onSubscribe` 메서드를 사용해 Subscription을 전달
3. Publisher가 Subscription을 Subscriber에게 전달했기 때문에 Subscription은 통신 매개체로 사용됨
   - Subscriber는 필요한 데이터가 있으면 Subscription의 `request` 메서드를 사용해 Publisher에게 요청함
4. 데이터 요청이 들어오면 Publisher는 `onNext` 메서드를 사용해 Subscriber에게 데이터 전달
   - 작업이 완료되면 `onComplete`, 에러가 발생하면 `onError`를 Subscriber가 반환



#### 리액티브 스트림즈 간단 구현

> https://youtu.be/6TiUCm3K_IE

```xml
...
				<!-- 리액티브 스트림즈 의존성 추가 -->
        <dependency>
            <groupId>org.reactivestreams</groupId>
            <artifactId>reactive-streams</artifactId>
            <version>1.0.4</version>
        </dependency>
...
```

- Publisher

```java
public class MyPub implements Publisher<Integer> {

    Iterable<Integer> its = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    @Override
    public void subscribe(Subscriber<? super Integer> subscriber) {
        MySubscription subscription = new MySubscription(subscriber, its);

        // 구독자에게 구독 정보 리턴
        subscriber.onSubscribe(subscription);
    }
}
```

- Subscriber

```java
public class MySub implements Subscriber<Integer> {

    private Subscription subscription;
    private int bufferSize = 2;					// 백프레셔

    @Override
    public void onSubscribe(Subscription subscription) {
      	// Publisher로 부터 Subscription 전달 받기
        this.subscription = subscription;

      	// Publisher에게 데이터 요청하기
        subscription.request(bufferSize);
    }

    @Override
    public void onNext(Integer integer) {
        System.out.println("onNext() : " + integer);
        bufferSize--;
        if(bufferSize == 0) {
            bufferSize = 2;
            subscription.request(bufferSize);
        }
    }

    @Override
    public void onError(Throwable throwable) {
        System.out.println("구독중 에러");
    }

    @Override
    public void onComplete() {
        System.out.println("구독 완료");
    }
}
```

- Subscription

```java
public class MySubscription implements Subscription {

    private Subscriber subscriber;
    private Iterator<Integer> its;

    public MySubscription(Subscriber subscriber, Iterable<Integer> its) {
        this.subscriber = subscriber;
        this.its = its.iterator();
    }


    @Override
    public void request(long l) {
        while(l > 0) {
            if(its.hasNext()) {
                subscriber.onNext(its.next());
            } else {
                subscriber.onComplete();
                break;
            }
            l--;
        }
    }

    @Override
    public void cancel() {

    }
}
```

- 테스트

```java
@Test
public void test() {
  MyPub pub = new MyPub();
  MySub sub = new MySub();

  // 구독 요청
  pub.subscribe(sub);
}
```





