---
title: "Reactive Streams"
date: 2022-07-21T09:55:17+09:00
draft: false
tags:
- reactive-streams
categories:
- WebFlux
---



# Reactive Streams

> 참고
>
> https://engineering.linecorp.com/ko/blog/reactive-streams-with-armeria-1/

스프링 웹 프레임워크는 스프링 5 이후로 크게 두 가지 포트폴리오를 제공해준다. 하나는 서블릿 기반의 스프링 MVC이고, 다른 하나는 리액티브 스트림즈 기반의 스프링 WebFlux이다. WebFlux는 리액티브 스트림즈의 구현체인 Project Reactor 기반으로 구현이 되어 있기 때문에 WebFlux를 이해하기 위해선 리액티브 스트림즈에 대한 이해가 필요하다고 할 수 있다.



## 1. 리액티브 프로그래밍

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



#### 리액티브 스트림즈

결과적으로 리액티브 이 핵심 개념들을 이용해서 공식 문서에서 설명되어 있는 것처럼, 빠른 응답 속도 - 높은 작업 처리율을 가진 프로그래밍 방식이라고 생각하면 될 것이다.





## 2. 리액티브 스트림즈 API

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



## 3. WebFlux

WebFlux는 리액티브 스트림즈라는 표준 명세를 기반으로 구현된 Project Reactor를 스프링 프로젝트에서 사용할 수 있게 만들어진 프레임워크이다. 그래서 실제로 WebFlux가 작동하는 방식은 리액티브 스트림즈의 명세와 동일한 방식으로 작동을 한다. 사용자가 데이터를 요청을 하면, 요청에 대한 처리를 하고 데이터를 발행할 Publisher가 필요하다. WebFlux에서는 그 역할을 `Flux`와 `Mono`가 담당하고 있다. 그리고 WebFlux에서는 발행 대신 방출(emit)이라는 표현을 사용한다.



#### Flux, Mono

![flux](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/doc-files/marbles/flux.svg)

`Flux`와 `Mono`는 리액티브 스트림즈의 Publisher 역할을 한다. 프로젝트 리액터의 공식 문서에서 이 두 추상 클래스에 대한 설명을 자세히 하고 있는데, 공통적으로는 데이터를 방출하면서 오퍼레이터(operator) 통해 데이터가 가공되어 사용자에게 결과물이 전달되지만, `Flux`는 0 ~ N개의 데이터를 방출할 수 있고, `Mono`는 0 ~ 1개의 데이터만 발행할 수 있다는 차이를 가진다. `Flux`와 `Mono`는 기능적으로도 큰 차이가 없기 때문에, 0이나 1대신 boolean을 사용하는 것처럼 하나의 데이터만 방출하는 경우 `Mono`를 사용해주면 된다.

#### 오퍼레이터(operator)

`Flux`와 `Mono`에서 사용하는 오퍼레이터는 요청이 들어오거나, 데이터를 방출할 때 등, 다양한 시점에서 사이드 이펙트를 발생시키고 싶을 때 사용한다. 오퍼레이터를 통해 사이드 이펙트가 발생하는 간단한 예시는 다음과 같다.

```java
Flux<Integer> flux = Flux.range(0, 5)
  .filter(i -> i % 2 == 0).doOnNext(i -> System.out.println(i+1)).log();
```

테스트를 위한 간단한 `Flux`를 만들었다. 스트림 내부의 숫자가 2로 나누어 떨어지는지 확인을 하고, 나누어 떨어진다면 `doOnNext`를 하는 시점에서 1을 더해 표준 출력을 하는 `Flux`이다. `doOnNext`는 다음과 같은 방식으로 작동하는 오퍼레이터다.

> Add behavior (side-effect) triggered when the Flux emits an item.
>
> The consumer is executed first, then the onNext signal is propagated downstream.

![doOnNextForFlux](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/doc-files/marbles/doOnNextForFlux.svg)

공식 문서의 설명에 따르면 `doOnNext`는 우리가 만든 `Flux`가 데이터를 방출할 때 작동한다고 적혀있다. 또한, 매개변수로 `Consumer`를 받고, `Consumer`가 먼저 실행되고 나서 `onNext` 시그널을 준다는 것도 확인할 수 있다. `Flux`나 `Mono`를 테스트하기 위해선 `StepVerifier`를 사용할 수 있다.

```java
StepVerifier.create(flux)
  .expectNext(0)
  .assertNext(i -> assertThat(i).isEqualTo(2))
  .assertNext(i -> assertThat(i).isEqualTo(4))
  .expectComplete()
  .log()
  .verify();
```

`StepVerifier`는 WebFlux 테스트를 위한 인터페이스다. 스트리밍 방식으로 데이터를 처리하기 때문에 전통적인 방식으로는 테스트를 하기 어렵기 때문에 `StepVerifier`를 통해 하나씩 흘러오는 데이터를 검증할 수 있다.

- `expectNext()`는 `Flux`나 `Mono`에서 방출되는 데이터를 예측하는 것이다. 위의 케이스에서는 처음으로 방출되는 데이터가 0이기 때문에 다음에 방출되는 데이터가 0이라고 예측할 수 있다.
- `assertNext()`는 일반적인 테스트 코드 검증 단계에서 사용하는 Assert 메서드를 사용하여 스트리밍 데이터를 검증한다. `expectNext`와 마찬가지로 하나씩 차례대로 데이터를 검증하지만, `Consumer` 타입의 메서드로 조금 더 다양한 방식으로 테스트가 가능하다.(`expectNext`는 동등한지만 비교)

`StepVerifier`를 실행하면 다음과 같은 로그를 볼 수 있다.

```bash
# StepVerifier log
12:37:09.855 [main] DEBUG reactor.test.StepVerifier - Scenario:
12:37:09.855 [main] DEBUG reactor.test.StepVerifier - 	<defaultOnSubscribe>
12:37:09.856 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(0)>
12:37:09.856 [main] DEBUG reactor.test.StepVerifier - 	<assertNext>
12:37:09.856 [main] DEBUG reactor.test.StepVerifier - 	<assertNext>
12:37:09.856 [main] DEBUG reactor.test.StepVerifier - 	<expectComplete>

# Flux log
12:37:09.859 [main] INFO reactor.Flux.PeekFuseable.1 - | onSubscribe([Fuseable] FluxPeekFuseable.PeekFuseableSubscriber)
12:37:09.860 [main] INFO reactor.Flux.PeekFuseable.1 - | request(unbounded)
1
12:37:09.861 [main] INFO reactor.Flux.PeekFuseable.1 - | onNext(0)
3
12:37:09.861 [main] INFO reactor.Flux.PeekFuseable.1 - | onNext(2)
5
12:37:09.886 [main] INFO reactor.Flux.PeekFuseable.1 - | onNext(4)
12:37:09.887 [main] INFO reactor.Flux.PeekFuseable.1 - | onComplete()
```

`StepVerifier`의 로그를 통해 우리가 검증하기 위해 작성한 오퍼레이터 체인을 확인할 수 있고, 이를 통해 실행된 `Flux`의 로그를 보면 리액티브 스트림즈 API를 그대로 사용하고 있는 것을 확인할 수 있다. `doOnNext` 역시 설명대로 사용자가 `onNext`를 호출하기 전에 표준 출력이 실행된 것을 확인할 수 있다.

다른 오퍼레이터인 `doFirst` 케이스를 확인해보자. `doFirst`는 `Flux`가 구독이 되기 전에 실행되는 사이드 이펙트이다. 따라서 `onSubscribe`로 구독이 되기 전에 사이드 이펙트가 발생한 것을 확인할 수 있다.(스택처럼 나중에 호출된 `doFirst`가 먼저 호출됨)

```java
Flux<Integer> flux = Flux.range(0, 5)
  .doFirst(() -> System.out.println("Hello"))
  .doFirst(() -> System.out.println("World")).log();

StepVerifier.create(flux)
  .expectNext(0,1,2,3,4)
  .expectComplete()
  .log()
  .verify();
```

```bash
# StepVerifier log
12:45:20.561 [main] DEBUG reactor.test.StepVerifier - Scenario:
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<defaultOnSubscribe>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(0)>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(1)>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(2)>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(3)>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectNext(4)>
12:45:20.562 [main] DEBUG reactor.test.StepVerifier - 	<expectComplete>

# Flux log
World
Hello
12:45:20.565 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onSubscribe([Synchronous Fuseable] FluxRange.RangeSubscription)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | request(unbounded)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onNext(0)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onNext(1)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onNext(2)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onNext(3)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onNext(4)
12:45:20.567 [main] INFO reactor.Flux.DoFirstFuseable.1 - | onComplete()
```



