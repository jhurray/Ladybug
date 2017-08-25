# Ladybug 🐞

Ladybug makes it easy to write a model or data-model layer in Swift 4.

This framework is *modeled* (ha 👏 ha 👏) after [Mantle](https://github.com/Mantle/Mantle). Mantle provides easy translation from JSON to model objects with minimal setup, and also comes with [`NSCoding`](https://developer.apple.com/documentation/foundation/nscoding) conformance out of the box. Ladybug takes advantage of the new [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol to provide similar functionality without subclassing `NSObject`.

![language](https://img.shields.io/badge/Language-Swift4-56A4D3.svg)
![Version](https://img.shields.io/badge/Pod-%201.0.0%20-96281B.svg)
![MIT License](https://img.shields.io/github/license/mashape/apistatus.svg)
![Platform](https://img.shields.io/badge/platform-%20iOS|tvOS|macOS|watchOS%20-lightgrey.svg)

### Quick Links
* [Setup](#setup)
* [Cocoapods & Carthage](#ingestion)
* [Mapping JSON to properties](#json-to-property)
  * [Nested Objects](#nested-objecs)
  * [Dates](#dates)
  * [Additional Mapping](#mapping)
  * [Default Values / Migration](#default-values)
  * [JSONKeyPath](#jsonkeypath)
* [Musings 🤔](#musings)

## Why use 🐞? 
Ladybug is the first 3rd party model framework for Swift where you dont need a line of code for every property of your model. **If a JSON key is the same as the property name you dont need to explicitly supply a mapping.**

This is true for `Codable`, but if your JSON structure diverges from your data model even slightly, you have to write *at least* 1 line of code for every property. I elaborate on this [here](#why-not-codable).

### Setup <a name="setup"></a>
By conforming to the `JSONCodable` protocol provided by 🐞, you can initialize any `struct` or `class` with `Data` or JSON, and get full `Codable` conformance. If your JSON structure diverges form your data model, you can override the static `transformersByPropertyKey` property to provide custom mapping.


```swift
struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	"name": JSONKeyPath("tree_name")
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

**Note:** `PropertyKey` is a `String` typealias.

### Cocoapods & Carthage <a name="ingestion"></a>

#### Cocoapods

Add the following to your `Podfile`

```ruby
pod 'Ladybug', '~> 1.0.0'
```

#### Carthage

Add the following to your `Cartfile`

```ruby
github "jhurray/Ladybug" ~> 1.0.0
```

## Mapping JSON Keys to Properties <a name="json-to-property"></a>
Ok, it gets a little more complicated, but its easy, I swear. 

In the example above we needed to map the `tree_name` key to the `name` property.

You can associate JSON keys with properties via different objects conforming to `JSONTransformer`.

There are 6 types of transformers provided:    

* `JSONKeyPath` (mapping key paths to property names)
* `NestedObjectTransformer<T: JSONCodable>` (explicitly declaring nested types)
* `NestedListTransformer<T: JSONCodable>` (explicitly declaring nested lists)
* `DateTransformer` (handling dates in different formats)
* `MapTransformer<T: Codable>` (handling JSON values that require further mapping)
* `DefaultValueTransformer` (assigning default values to properties)

Transformers are provided via a readonly `static` property of the `JSONCodable` protocol, and are indexed by `PropertyKey`.

```swift
static var transformersByPropertyKey: [PropertyKey: JSONTransformer] { get }
```

### `JSONKeyPath` <a name="jsonkeypath"></a>

In the example at the beginning we used `JSONKeyPath` to map the value associated with the `tree_name` field to the `name` property of `Tree`.

`JSONKeyPath` is used to access values in JSON. It is initialized with a variadic list of json subscripts (`Int` or `String`).

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

**Note:** These key paths are used optionally in objects conforming to `JSONTransformer` when the property being mapped to does not match the json structure.

**Note:** JSONKeyPath can also be expressed as a string literal.
> `JSONKeyPath("some_key")` == `"some_key"`

**Note:** You can also use keypath notation from Objective-C.
> `JSONKeyPath("foo", "hello")` == `JSONKeyPath("foo.hello")` == "foo.hello"    

This does not work for `Int` subscripts
> `JSONKeyPath("bar", 1)` != `JSONKeyPath("bar.1")`


### Nested Objects: `NestedObjectTransformer` and `NestedListTransformer`

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
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	...
    	"leaves": NestedListTransformer<Leaf>(),
    	"firstLeaf": NestedObjectTransformer<Leaf>(keyPath: JSONKeyPath("leaves", 0))
    ]
    
    struct Leaf: JSONCodable {
        ...
    }
}
```

Use `NestedObjectTransformer` to map JSON objects to types conforming to `JSONCodable`. Likewise use `NestedListTransformer` to map lists of JSON  objects to a list of objects conforming to `JSONCodable`.

**Note:** If the property name is the same as the key path, you dont need to include the key path.

### Dates: `DateTransformer`

Finally, lets add dates to the mix. You can use `DateTransformer` to map formatted date strings, ints, or doubles from JSON to `Date` objects.

Ladybug supports multiple date parsing formats:

```swift
public enum DateTransformer.Format: Hashable {
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
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "july4th": DateTransformer(format: .custom(format: "MM/dd/yyyy")),
        "Y2K": DateTransformer(format: .secondsSince1970),
        "createdAt": DateTransformer(customAdapter: { (_) -> Date? in
            return Date()
        })
    ]
}
```

**Note:** If using `customAdapter` to map to a non-optional `Date`, returning `nil` will result in an error being thrown. 

### Additional Mapping: `MapTransformer` <a name="mapping"></a>

If you need to provide a simple mapping from a JSON value to a property, use `MapTransformer`. A great example is using this to convert a string to an integer.

```swift
{
"count": "100"
}
...
struct Object: JSONCodable {
    let count: Int
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	"count": MapTransformer<Int> {
    		return Int($0 as! String)
    	}
    ]
}
``` 

### Default Values / Migrations: `DefaultValueTransformer` <a name="default-values"></a>

If you wish to supply a default value for a property, you can use `DefaultValueTransformer`. You supply the default value, and can also control whether or not to override the property if the property key exists in the JSON payload.

```swift
init(value: Any, override: Bool = false)
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

As mentioned before, `Codable` is a great step towards simplifying JSON parsing in swift, but the O(n) boilerplate that has become a mainstay in swift JSON parsing still exists when using `Codable` (e.g. For every property your object has, you need to write 1 or more lines of code to map the json to said property). In Apple's documentation on [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types), you can see that as soon as JSON keys diverge from property keys, you have to write a ton of boilerplate code to get `Codable` conformance. Ladybug sidesteps this, and  does a lot of this for you under the hood.

### Performance
Ladybugs decoding and mapping performance is about the same as the performance of `JSONDecoder`. The transformers are very lightweight, but obviously as the number of transformers per model increases, the perfomace degrades at a linear rate. Just keep in mind that the closer your JSON schema is to your model schema, the more performant it will be.

```
performance = (JSONDecoder performance) + (Ladybug transformer performance)
```

### It would be pretty great if `AnyKeyPath` conformed to `ExpressibleByStringLiteral`

If Swift 4 key paths could be expressible by a string value, we could use that as our `PropertyKey` typealias instead of `String`. This would be a safer alternative.

### Be careful with `MapTransformer`

Its easy to go a little to far with `MapTransformer`. In the example below, the map transformer is being used to calculate a sum instead of mapping a JSON value to a `Codable` type. To me, this promotes bad data modeling. I'm a firm believer that data models should closely mirror JSON responses. When used in the wrong way, map transformers can give too data models too much responsibility.

```swift
{
"values": [1, 1, 2, 3, 5, 8, 13]
}
... 
struct Count: JSONCodable {
	let values: [Int]
	let sum: Int
	
	static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
		MapTransformer<Int>(keyPath: "values") { value in
			let values = value as! [Int]
			return values.reduce(0) { $0 + $1 }
		}
	]
}
```

### Things I would like to do:   
- [ ] Custom rules: Provide a simple interface to say by default, map **under_scored** JSON keys to **camelCased** properties.

### Why is this called Ladybug?

Ask [Billy](https://twitter.com/billy_the_kid), or file an issue 😋

## Contact Info && Contributing

Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com) or [hit me up on the twitterverse](https://twitter.com/JeffHurray). I'd love to hear your thoughts on this, or see examples where this has been used.

[MIT License](https://github.com/jhurray/Ladybug/blob/master/LICENSE)





