---
title: "RabbitMQ 튜토리얼"
date: 2022-08-22T19:32:09+09:00
draft: true
tags:
- rabbit-mq
categories:
- rabbit-mq
---
메시지 브로커인 RabbitMQ에 대해 알아보고 튜토리얼을 진행한다.
<!--more-->

> 참고 : RabbitMQ 공식 튜토리얼
> 
> https://www.rabbitmq.com/getstarted.html 

# 1. Hello World

RabbitMQ는 메시지 브로커다. 메시지 브로커는 우편함에 비유할 수 있다. 우편함에 메일을 넣으면 그 안에 있는 메일이 받는 사람에게 전달되는데, 메시지 브로커의 역할이 바로 이 우편함과 일치한다.

RabbitMQ에서 사용하는 용어들은 다음과 같다.

- 프로듀싱(Producing): 메시지를 보내는 것과 일치한다. RabbitMQ에 메시지를 전송하는 프로그램은 프로듀서(producer)라고 부른다.
- 큐(queue): RabbitMQ의 우편함이라 할 수 있다. 메시지는 큐에만 저장할 수 있으며, 호스트 서버의 메모리와 디스크 용량에 따라 바인딩되는 큰 메시지 버퍼라고 생각하면 된다. 프로듀서가 보내는 메시지가 큐에 들어가고 컨슈머(consumer)가 큐에서 메시지를 받아간다.
- 컨슈머(consumer): 컨슈머는 메시지를 받는 대상을 의미한다. 대부분은 메시지를 받기 위해 기다리는 프로그램이다.

### Java를 사용한 Hello World 출력

RabbitMQ는 다양한 프로토콜을 지원하는 메시지 브로커로, 튜토리얼에서는 AMQP 0-9-1을 따르는 자바 클라이언트 라이브러리를 사용할 것이다. maven 프로젝트를 기준으로 라이브러리를 불러오는 저장소이다.

> https://mvnrepository.com/artifact/com.rabbitmq/amqp-client/5.15.0
>
> https://mvnrepository.com/artifact/ch.qos.logback/logback-classic/1.2.3

- `Send.java`

```java
public class Send {
    private final static String QUEUE_NAME = "hello";

    public static void main(String[] args) throws IOException, TimeoutException {

        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");

        try(Connection connection = factory.newConnection();
            Channel channel = connection.createChannel()) {
            channel.queueDeclare(QUEUE_NAME, false, false, false, null);
            String message = "Hello World!";
            channel.basicPublish("", QUEUE_NAME, null, message.getBytes(StandardCharsets.UTF_8));
            System.out.println(" [x] Send " + message);
        }
    }
}
```

- Connection: 소켓 연결과 프로토콜 버전 협상, 인증 등을 추상화한 클래스다. Connection을 통해 RabbitMQ 노드와 연결이 가능해진다.
- Channel: 메시지 전송에 필요한 다양한 API들이 제공되는 클래스다.
- queueDeclare: 메시지 브로커에서 사용하는 큐는 멱등성을 가진다. 큐가 이미 존재한다면 기존에 존재하는 큐를 이용하고, 없는 경우에만 새로운 큐를 사용하게 된다. 메시지의 콘텐츠는 바이트의 배열이므로, 자유롭게 인코딩을 할 수 있다.

- `Recv.java`

```java
public class Recv {

    private final static String QUEUE_NAME = "hello";

    public static void main(String[] args) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();

        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        System.out.println(" [*] Waiting for messages. to Exit press CTRL+C");

        DeliverCallback deliverCallback = (consumerTag, delivery) -> {
            String message = new String(delivery.getBody(), StandardCharsets.UTF_8);
            System.out.println(" [x] Received " + message);
        };
        channel.basicConsume(QUEUE_NAME, true, deliverCallback, consumerTag -> {
        });
    }
}
```

- Connection, Channel을 사용해서 RabbitMQ와 연결
- DeliverCallback: 큐에 메시지가 도착하면 특정 동작을 실행