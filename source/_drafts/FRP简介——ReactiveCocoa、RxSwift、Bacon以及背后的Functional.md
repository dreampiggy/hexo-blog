---
title: FRP对比——ReactiveCocoa、RxSwift、Bacon以及背后的Functional
tags:
 - Functional
 - Swift
 - JavaScript
 - iOS
---




# ReactiveCocoa和RxSwift

iOS的开发上，Objective-C可以说既是一个巨大的成功，也是一个巨大的限制。Cocoa Touch提供的原生API本身就是目标当年的GUI编程模型，并且专门为Objective-C设计的，因此，Target-Acion，KVO，Apple式MVC架构才会一直成为一个iOS开发的主流。然而，这套架构在大型App，尤其是网络请求和人机交互特别多的情况下，非常容易让整个App架构变得难以维护。


# Promise
Promise的介绍就不再赘述，自己也有博文和Slides简单描述过。针对Reactive Programming来说，Promise其实只是一个非常小的工具，而不是一套完整的框架。

Promise的目的，在于对异步请求流程的控制，而本身并没有对事件的管理。原始的Promise虽然有着类似Rx的事件流类似特点：`不可变性`、``，但是关键点额区别在于Promise自身是单次流动，数据流只会从then开始走到结束或者catch掉，无法多次重新流动；不支持流程中断取消；缺少Rx强大的操作符，种种都表明Promise只是一个异步流程处理的工具，好比async和await，需要配合其他框架层面的东西，来达到完整事件流和GUI数据绑定，这里就得提到[Bacon](https://github.com/baconjs/bacon.js/)

# Bacon

Bacon是JavaScript上的一个FRP框架，借鉴于知名的[EventStream](https://github.com/dominictarr/event-stream)所实现的事件流，Bacon在这之上完成了FRP所需要的一切：事件流，变换，数据绑定，比起正统的RxJS来说，提供了更适合Web前端应用的的`EventStream`和`Property`，不需要被RxJS的Hot/Cold Observerable烦扰。并且原生支持了所有惰性求值，在benchmark上比起RxJS有着不错的性能优势。

+ 示例——计数器

```javascript
let plus = $("#plus").asEventStream("click").map(1)
let minus = $("#minus").asEventStream("click").map(-1)
let both = plus.merge(minus)
	.scan(0, add) // add +1 or -1 base on click eventstream
	.onValue(sum => $("#sum").text(sum))
	.onError(e => console.log(e))
	.onEnd(() => alert('total: ' + $("#sum").text));
```

除了专门提供的EventStream和Propery的两种Observerable，并且提供了更好的事件源支持，你可以从原生的DOM事件来触发事件源，可以从Promise来触发（这是一个大的优势），甚至从callback或者自定义的binder都可以。在RxJS的基础上有了比较大的提升。不过具体工程上讲两者都是Rx实现的FRP，取舍还要看自己的特定选择（幸好我不做前端）

# Functional

> 由于自己也不是Haskell Guy，仅仅接触过一点点JS、Closure和Swift这些有泛函编程思想的语言 ，如果想具体了解函数式编程中，关于`Functor`、`Applicative`以及`Monad`的知识，推荐花上10分钟看一下简单的图文教程：分别有[原文(推荐)](http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html)、[Swift版](http://www.mokacoding.com/blog/functor-applicative-monads-in-pictures/)和[JS版](https://medium.com/@tzehsiang/javascript-functor-applicative-monads-in-pictures-b567c6415221#.5upsphilw)


下面这些内容，默认为已经掌握了上述简单理解，如果看不太懂可以回过头重新看一下对应的Functional知识

### ReactiveX

Rx的`Observerable`的本质就是一个`Event Monad`，即上下文（就是图文教程中包裹的盒子）为Event的一个Monad，这里的Event定义，可以对应语言的struct或者enum，包括了`next`、`error`和`complete`三个上下文即可。这里截取的是Swift语言的实现，`map`方法实现拆装箱（类似Optional，即Haskell的Maybe）

```swift
public enum Event<Element> {
    /// Next element is produced.
    case next(Element)

    /// Sequence terminated with an error.
    case error(Swift.Error)

    /// Sequence completed successfully.
    case completed
}

extension Event {
    /// Maps sequence elements using transform. If error happens during the transform .error
    /// will be returned as value
    public func map<Result>(_ transform: (Element) throws -> Result) -> Event<Result> {
        do {
            switch self {
            case let .next(element):
                return .next(try transform(element))
            case let .error(error):
                return .error(error)
            case .completed:
                return .completed
            }
        }
        catch let e {
            return .error(e)
        }
    }
}
```


而Rx的`subscribe`方法就是一个解包，也就是`Monad<Event>.map()`，接收一个`(Event) -> void`的参数。或者使用更一般直观的三个参数`onNext: (Element) -> Void`、`onError: (Error) -> Void`、`onCompleted: (Void) -> Void`方法（在其他语言实践上，RxJS就是三个function参数，而RxJava为了支持Java7可以使用匿名内部类）

理论：

```haskell
Monad Event <$> subscribe
```

示例：

```swift
let subscription = Observable<Int>.interval(0.3)
	.subscribe { event in
		print(event) // unwraped event
	}

let cancel = searchWikipedia("me")
	.subscribe(onNext: { results in
		print(results)
	}, onError: { error in
		print(error)
	})

```


Rx的Operator是`Functor`，也就是说`(Event) -> Event`，因此可以通过Monad不断`bind`你想要的组合子，直到最终符合UI控件需要的数据

理论：

```haskell
Monad Event >>= map >>= concat >>= filter >>= map <$> subscribe
```

示例：

```swift
let subscription = primeTextField.rx.text           // Observable<String>
	.map { WolframAlphaIsPrime(Int($0) ?? 0) }      // Observable<Observable<Prime>>
	.concat()                                       // Observable<Prime>
	.filter { $0.isPrime }                          // Observable<Prime>
	.map { "number \($0.n) is prime" }              // Observable<String>
	.bindTo(resultLabel.rx.text)                    // bind to label text
```


### Promise / Future
Promise本质上是一个`Functor`，即`Promise<Element> -> Promise<Element>`
它的`then`、`catch`还有对应的`all`、`race`，都不用返回一个包裹值，所以不是Monad。Promise的所有原型方法返回值都是原始值，除非你主动返回Promise.resolve或者Promsie.reject

```haskell
(+1) <$> then <$> catch <$> then
```

```javascript
Promise.resolve(1)
  .then(v => {
    return v + 1; // 1
  }.then(v =>  {
    throw new Error('error'); //reject
  }.catch(e => {
    console.log(e); // error
    return Promise.resolve(0);
  }.then(v => {
    console.log('end', v); // end 0
  }
```