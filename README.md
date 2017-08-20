# Ladybug 🐞

Ladybug makes it easy to write a simple model or data-model layer in Swift 4

This framework is *modeled* (ha 👏 ha 👏) after [Mantle](https://github.com/Mantle/Mantle). Mantle provides easy translation from JSON to model objects, and also comes with [`NSCoding`](https://developer.apple.com/documentation/foundation/nscoding) conformance out of the box. Ladybug takes advantage of the new [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol to provide similar functionality without subclassing `NSObject`.

![language](https://img.shields.io/badge/Language-Swift 4-56A4D3.svg)
![Version](https://img.shields.io/badge/Pod-%200.0.1%20-96281B.svg)
![MIT License](https://img.shields.io/github/license/mashape/apistatus.svg)
![Platform](https://img.shields.io/badge/platform-%20iOS | tvOS | macOS | watchOS%20-lightgrey.svg)

### Quick Links
* [Setup](#setup)
* [Cocoapods & Carthage](#ingestion)
* [Mapping JSON to properties](#json-to-property)
  * [Nested Objects](#nested-objecs)
  * [Dates](#dates)
  * [Default Values / Migration](#default-values)
  * [JSONKeyPath](#jsonkeypath)
* [Musings 🤔](#musings)

## Why use 🐞? 
Ladybug takes the pain out of parsing JSON in Swift. It allows you to map JSON keys to properties of your model without having to worry about explicit types. 

`Codable` is a huge step for modeling data in swift, but if your JSON structure diverges from your model, conforming to `Codable` can be a **huge** pain 🤕. I elaborate on this [here](#why-not-codable).

#### Setup <a name="setup"></a>
By conforming to the `JSONCodable` protocol provided by 🐞, you can initialize any `struct` or `class` with `Data` or JSON, and get full `Codable` conformance. If your JSON structure diverges form your data model, you can override the static `transformers` property to provide custom mapping.


```swift
struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    
    static transformers: [JSONTransformer] = [
    	JSONKeyPathTransformer(propertyName: "name", keyPath: JSONKeyPath("tree_name"))	
    ]
}
...
let treeJSON = [
  "tree_name": "pine",
  "age": "121",
  "family": 1
]
...
let pineTree = try Tree(json: treeJSON)
let forest = try Array<Tree>(json: [treeJSON, treeJSON, treeJSON])

```

`pineTree` and `forest` are fully initialized and can be encoded and decoded. Simple as that. 

**Note:** Any nested enum must conform to `Codable` and `RawRepresentable` where the `RawValue` is `Codable`.

### Cocoapods & Carthage <a name="ingestion"></a>

#### Cocoapods

```ruby
pod 'Ladybug', '~> 0.0.1'
```
Then add the following:

```swift
import Ladybug
```

#### Carthage

Unfortunately Carthage will not build using the XCode9 beta due to [this issue](https://github.com/Carthage/Carthage/issues/2104). Once the bug is fixed, I will add Carthage support.


## Mapping JSON Keys to Properties <a name="json-to-property"></a>
Ok, it gets a little more complicated, but its easy, I swear. 

In the example above we needed to map the `tree_name` key to the `name` property.

You can associate JSON keys with properties via different objects conforming to `JSONTransformer`.

There are 5 types of transformers provided:    

* `JSONKeyPathTransformer` (mapping key paths to property names)
* `JSONNestedObjectTransformer<T: JSONCodable>` (explicitly declaring nested types)
* `JSONNestedListTransformer<T: JSONCodable>` (explicitly declaring nested list)
* `JSONDateTransformer` (handling dates in different formats)
* `JSONDefaultValueTransformer` (assigning default values to properties)

Transformers are provided via a readonly `static` property of the `JSONCodable` protocol.

```swift
static var transformers: [JSONTransformer] { get }
```

### `JSONKeyPathTransformer`


To solve the problem in the first example, we overrode `transformers` in our `Tree` object, and supplied a key path transformer.

```swift
struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    
    static let transformers: [JSONTransformer] = [
    	JSONKeyPathTransformer(propertyName: "name", keyPath: JSONKeyPath("tree_name"))
    ]
}
```

This maps the value associated with the `tree_name` field to the `name` property.

### What's a `JSONKeyPath`? <a name="jsonkeypath"></a>

I'm glad you asked. `JSONKeyPath` is used to access values in JSON. It is initialized with a variadic list of json subscripts (`Int` or `String`).

In the example below:

* `JSONKeyPath("foo")` maps to `{"hello": "world"}`
* `JSONKeyPath("foo", "hello")` maps to `"world"`
* `JSONKeyPath("bar", 0)` maps to `"lorem"`

```json
{
  "foo": {
     "hello": "world"
  },
  "bar": [ 
  		"lorem",
  		"ipsum"
  ]  
}
```

**Note:** These key paths are used optionally in the rest of the transformers if the transformed property name does not match the json structure.

**Note:** JSONKeyPath can also be expressed as a string literal.
> `JSONKeyPath("some_key", "some_other_key")` == `"some_key.some_other_key"`

**Note:** You can also use keypath notation from Objective-C.
> `JSONKeyPath("foo", "hello")` == `JSONKeyPath("foo.hello")`


### Nested Objects: `JSONNestedObjectTransformer` and `JSONNestedListTransformer`

Lets add a nested class, `Leaf`. Trees have leaves. Nice.

```json
{
  "tree_name": "pine",
  "age": 121,
  "family": 1,
  "leaves": [
  	  {
  	  "size": "large",
  	  "is_attached": true
  	  },
  	  {
  	  "size": "small",
  	  "is_attached": false
  	  }
  ]
}

```

```swift
struct Tree: JSONCodable {
	...
    let firstLeaf: Leaf?
    let leaves: [Leaf]
    ...
    static let transformers: [JSONTransformer] = [
    	...
    	JSONNestedListTransformer<Leaf>(propertyName: "leaves"),
    	JSONNestedObjectTransformer<Leaf>(propertyName: "firstLeaf", keyPath: JSONKeyPath("leaves", 0))
    ]
    
    struct Leaf: JSONCodable {
        ...
    }
}
```

Use `JSONNestedObjectTransformer` to map JSON objects to types conforming to `JSONCodable`. Likewise use `JSONNestedListTransformer` to map lists of JSON  objects to a list of objects conforming to `JSONCodable`.

**Note:** If the property name is the same as the key path, you dont need to include the key path.

### Dates: `JSONDateTransformer`

Finally, lets add dates to the mix. You can use `JSONDateTransformer` to map formatted date strings, ints, or doubles from JSON to `Date` objects.

Ladybug supports multiple date parsing formats:

```swift
public enum DateFormat: Hashable {
   /// Decode the `Date` as a UNIX timestamp from a JSON number.
   case secondsSince1970
   /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
   case millisecondsSince1970
   /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
   case iso8601
   /// Decode the `Date` with a custom date format string
   case custom(format: String)
}
```

You can also use initializers with a `customAdapter` of type `(Any?) -> Date?`

```json
{
"july4th": "7/4/1776",
"Y2K": 946684800,
}
```

```swift
struct SomeDates: JSONCodable {
    let july4th: Date
    let Y2K: Date
    let createdAt: Date
    
    static let transformers: [JSONTransformer] = [
        JSONDateTransformer(propertyName: "july4th", dateFormat: .custom(format: "MM/dd/yyyy")),
        JSONDateTransformer(propertyName: "Y2K", dateFormat: .secondsSince1970),
        JSONDateTransformer(propertyName: "createdAt", customAdapter: { (_) -> Date? in
            return Date()
        })
    ]
}
```

**Note:** If using `customAdapter` to map to a non-optional `Date`, returning `nil` will result in an error being thrown. 

### Default Values / Migrations: `JSONDefaultValueTransformer` <a name="default-values"></a>

If you wish to supply a default value for an property, you can use `JSONDefaultValueTransformer`. Supply the property name and the the default value. You can also control whether or not to override the property if the `propertyName` key exists in the JSON payload.

```swift
init(propertyName: String, value: Any, override: Bool = false)
```

The default transformer is useful when API's change, and can help migration from cached JSON data to `JSONCodable` objects with new properties.


## Handling Failure

### Exceptions
Ladybug is failure driven, and all `JSONCodable` initializers throw exceptions if they fail. There is a `JSONCodableError` type that Ladybug will throw if there is a typecasting error, and Ladybug will also throw exceptions from `JSONSerialization` and `JSONDecoder`.

### Optionals
If a value is optional in your JSON payload, it should be optional in your data model. Ladybug will only throw an exception if a key is missing and the property it is being mapped to is non-optional. Play it safe kids, use optionals.

## Class Conformance to `JSONCodable`

There is a small caveat to keep in mind when you are conforming a `class` to `JSONCodable`. Because classes in swift dont come with baked in default initializers like structs do, you have to make sure properties are initialized. You can do this by supplying default values, or a default initializer that initializes these values.

You can see examples in [`ClassConformanceTests.swift`](https://github.com/jhurray/Ladybug/blob/master/Tests/ClassConformanceTests.swift).

## Thoughts About 🐞 <a name="musings"></a>

### Whats wrong with `Codable`? <a name="why-not-codable"></a>

As mentioned before, `Codable` is a great step towards simplifying JSON parsing in swift, but the O(n) boilerplate that has become a mainstay in swift JSON parsing still exists when using `Codable` (e.g. For every property your object has, you need to write 1 or more lines of code to map the json to said property). In Apple's documentation on [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types), you can see that as soon as JSON keys diverge from property keys, you have to write a ton of boilerplate code to get `Codable` conformance. Ladybug sidesteps this, and  does a lot fo this for you under the hood.

### It would be pretty great if `AnyKeyPath` conformed to `ExpressibleByStringLiteral`

If Swift 4 key paths could be expressible by a string value, we could use that instead of `propertyName: String` in `JSONTransformer`. This would provide a safer interface.

### Why I didn't include `Map` transformers
Say you had a URL string passed through the JSON and you wanted to map that to a string property that is just the query of the URL.

```swift
{
"values": [1, 8, 9, 14, 6]
}
... 
struct Count: JSONCodable {
	let values: [Int]
	let sum: Int
	
	let transformers = [
		JSONMapTransformer<Int>(propertyName: "sum", keyPath: JSONKeyPath("values")) { value in
			let values = value as! [Int]
			return values.reduce(0) { $0 + $1 }
		}
	]
}
```

To me, this promotes bad data modeling. I'm a firm believer that data models should closely mirror JSON responses, and map transformers would give too data models too much responsibility.

That being said, if you want the functionality of `JSONMapTransformer`, you can create an object that conforms to [`JSONTransformer`](https://github.com/jhurray/Ladybug/blob/master/Source/JSONTransformer.swift).

### Things I would like to do:   
- [ ] Test Performance [Here](https://github.com/bwhiteley/JSONShootout)
- [ ] Custom rules: Provide a simple interface to say by default, map **under_scored** JSON keys to **camelCased** properties.


## Contact Info && Contributing

Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com). I'd love to hear your thoughts on this, or see examples where this has been used.

[MIT License](https://github.com/jhurray/Ladybug/blob/master/LICENSE)





