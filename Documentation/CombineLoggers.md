How to write your own custom logger using Combine.

### Introduction

Loggers allow you to direct log messages wherever you want. `DDLog.messagePublisher()` wraps the API with a Combine publisher. Allowing you to use common Operators to transform these messages to your needs.

For general information about loggers, see the [architecture](Architecture.md) page.

### Publisher

`DDLog.messagePublisher()` returns `MessagePublisher`, which will never stop sending `DDLogMessage`s while there is an active subscriber and doesn't emit errors. Note that it'll create a `DDLogger` for each subscription unless you use the `share()` operator.

### Example

Here is an example of how you could use it display the last 1000 message in a log viewer.

```swift
var messages = [String]()

private var subscriptions = Set<AnyCancellable>()

func setup() {
    DDLog.sharedInstance.messagePublisher() //messagePublisher emits `DDLogMessage`
        .map(\.message) //Emits `String`. You could do the formating here if you wanted.
        .scan([], { (messages, newMessage) in
            var messages = messages
            messages.insert(newMessage, at: 0)
            return Array(messages.prefix(1000))
        }) //Emits `[String]`. Up to 1000 messages, most recent message is first.
        .receive(on: DispatchQueue.main) //Emits `[String]` on Main Queue
        .sink(receiveValue: { [weak self] self?.messages = $0 }) //Sets `[String]` to local storage avoiding retain cycle.
        .store(in: &subscriptions) //stores the subscription or it'll stop emitting events right away
}
```

You could add different operators to write the messages to disk, or to forward the messages to another API. 
