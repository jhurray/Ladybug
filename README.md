# Ladybug 🐞

Ladybug makes it easy to write a model or data-model layer in Swift 4. Full `Codable` conformance without the headache.

![language](https://img.shields.io/badge/Language-Swift4-56A4D3.svg)
![Version](https://img.shields.io/badge/Pod-%202.0.0%20-96281B.svg)
![MIT License](https://img.shields.io/github/license/mashape/apistatus.svg)
![Platform](https://img.shields.io/badge/platform-%20iOS|tvOS|macOS|watchOS%20-lightgrey.svg)

### Quick Links
* [Codable vs JSONCodable](#why-bug)
* [Installation](#ingestion)
* [Decoding](#decoding)
* [Encoding](#encoding)
* [Mapping JSON to properties](#json-to-property)
  * [JSONKeyPath](#jsonkeypath) 
  * [Nested Objects](#nested-objects)
  * [Dates](#dates)
  * [Additional Mapping](#mapping)
  * [Default Values / Migration](#default-values)
* [Generic Constraints](#generics)
* [Handling Failure](#failure)
* [Class Conformance](#class-conformance)
* [Musings 🤔](#musings)

## `Codable` vs `JSONCodable`? <a name="why-bug"></a>

Ladybug provides the `JSONCodable` protocol which is a subprotocol of [`Codable`](https://developer.apple.com/documentation/swift/codable). Lets compare how we would create an object using `Codable` vs. using `JSONCodable`.

Lets model a `Tree`. I want this object to be `Codable` so I can decode from JSON and encode to JSON.

Here is some JSON:

```json
{
    "tree_names": {
        "colloquial": ["pine", "big green"],
        "scientific": ["piniferous scientificus"]
    },
    "age": 121,
    "family": 1,
    "planted_at": "7-4-1896",
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

## Using `Codable` 😱

#### `Tree: Codable` Implementation

```swift 
struct Tree: Codable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    let plantedAt: Date
    let leaves: [Leaf]
    
    enum CodingKeys: String, CodingKey {
        case names = "tree_names"
        case family
        case age
        case plantedAt = "planted_at"
        case leaves
    }
    
    enum NameKeys: String, CodingKey {
        case name = "colloquial"
    }
    
    enum DecodingError: Error {
        case emptyColloquialNames
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let namesContainer = try values.nestedContainer(keyedBy: NameKeys.self, forKey: .names)
        let names = try namesContainer.decode([String].self, forKey: .name)
        guard let firstColloquialName = names.first else {
            throw DecodingError.emptyColloquialNames
        }
        name = firstColloquialName
        family = try values.decode(Family.self, forKey: .family)
        age = try values.decode(Int.self, forKey: .age)
        plantedAt = try values.decode(Date.self, forKey: .plantedAt)
        leaves = try values.decode([Leaf].self, forKey: .leaves)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nameContainer = container.nestedContainer(keyedBy: NameKeys.self, forKey: .names)
        let colloquialNames = [name]
        try nameContainer.encode(colloquialNames, forKey: .name)
        try container.encode(family, forKey: .family)
        try container.encode(age, forKey: .age)
        try container.encode(plantedAt, forKey: .plantedAt)
        try container.encode(leaves, forKey: .leaves)
    }
    
    struct Leaf: Codable {
        
        enum Size: String, Codable {
            case small, medium, large
        }
        
        let size: Size
        let isAttached: Bool
        
        enum CodingKeys: String, CodingKey {
            case isAttached = "is_attached"
            case size
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            size = try values.decode(Size.self, forKey: .size)
            isAttached = try values.decode(Bool.self, forKey: .isAttached)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(size, forKey: .size)
            try container.encode(isAttached, forKey: .isAttached)
        }
    }
}
```

[`Codable`](https://developer.apple.com/documentation/swift/codable) is a great step for Swift, but as you can see here, it can get [complicated](#why-not-codable) really fast. 

#### Decoding `Tree: Codable`

```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "MM-dd-yyyy"
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .formatted(dateFormatter)
let tree = try decoder.decode(Tree_Codable.self, from: jsonData)
```


#### Encoding `Tree: Codable`

```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "MM-dd-yyyy"
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .formatted(dateFormatter)
let data = try encoder.encode(tree)
```


## 🐞 to the Rescue!

 By conforming to the `JSONCodable` protocol, you can skip all the boilerplate that comes with `Codable` while still getting `Codable` conformance.

#### `Tree: JSONCodable` Implementation

```swift
struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    let plantedAt: Date
    let leaves: [Leaf]
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "name": JSONKeyPath("tree_names", "colloquial", 0),
        "plantedAt": "planted_at" <- format("MM-dd-yyyy"),
        "leaves": [Leaf].transformer,
    ]
    
    struct Leaf: JSONCodable {
        
        enum Size: String, Codable {
            case small, medium, large
        }
        
        let size: Size
        let isAttached: Bool
        
        static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
            "isAttached": "is_attached"
        ]
    }
}
```

As you can see, you only need provide mappings for the JSON keys that don't explicitly map to property names.

### Decoding `Tree: JSONCodable`

```swift
let tree = try Tree(data: jsonData)
```

### Encoding `Tree: JSONCodable`

```swift
let data = try tree.toData()
```

Ladybug will save you time and energy when creating models in Swift by providing `Codable` conformance without the headache.

## Installation <a name="ingestion"></a>

#### Cocoapods

Add the following to your `Podfile`

```ruby
pod 'Ladybug', '~> 2.0.0'
```

#### Carthage

Add the following to your `Cartfile`

```ruby
github "jhurray/Ladybug" ~> 2.0.0
```

## Decoding <a name="decoding"></a>

You can decode any object or array of objects conforming to `JSONCodable` from a JSON object, or `Data`. 

```swift
/// Decode the given object from a JSON object
init(json: Any) throws
/// Decode the given object from `Data`
init(data: Data) throws
```

**Example:**    

```swift
let tree = try Tree(json: treeJSON)
let forest = try Array<Tree>(json: [treeJSON, treeJSON, treeJSON])
```

Both initializers will throw an error if decoding fails.

## Encoding <a name="encoding"></a>

You can encode any object or array of objects conforming to `JSONCodable` to a JSON object or to `Data` 

```swift
/// Encode the object into a JSON object
func toJSON() throws -> Any
/// Encode the object into Data
func toData() throws -> Data
```

**Example:**    

```swift
let jsonObject = try tree.toJSON()
let jsonData = try forest.toData()
```

Both functions will throw an error if encoding fails.

## Mapping JSON Keys to Properties <a name="json-to-property"></a>

By conforming to the `JSONCodable` protocol provided by Ladybug, you can initialize any `struct` or `final class` with `Data` or a JSON object. If your JSON structure diverges form your data model, you can override the static `transformersByPropertyKey` property to provide custom mapping.


```swift
struct Flight: JSONCodable {
    
    enum Airline: String, Codable {
        case delta, united, jetBlue, spirit, other
    }
    
    let airline: Airline
    let number: Int
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	"number": JSONKeyPath("flight_number")
    ]
}
...
let flightJSON = [
  "airline": "united",
  "flight_number": 472,
]
...
let directFlight = try Flight(json: flightJSON)
let flightWithLayover = try Array<Flight>(json: [flightJSON, otherFlightJSON])

```

`directFlight ` and `flightWithLayover ` are fully initialized and can be encoded and decoded. Simple as that. 

**Note:** Any nested enum must conform to `Codable` and `RawRepresentable` where the `RawValue` is `Codable`.

**Note:** `PropertyKey` is a `String` typealias.

You can associate JSON keys with properties via different objects conforming to `JSONTransformer`.

Transformers are provided via a readonly `static` property of the `JSONCodable` protocol, and are indexed by `PropertyKey`.

```swift
static var transformersByPropertyKey: [PropertyKey: JSONTransformer] { get }
```

Ok, it gets a little more complicated, but its easy, I swear. 

### Accessing JSON Values: `JSONKeyPath` <a name="jsonkeypath"></a>

In the example at the beginning we used `JSONKeyPath` to map the value associated with the `tree_name` field to the `name` property of `Tree`.

`JSONKeyPath` is used to access values in JSON. It is initialized with a variadic list of json subscripts (`Int` or `String`).

In the example below:

* `JSONKeyPath("foo")` maps to `{"hello": "world"}`
* Similarly, `"foo"` maps to `{"hello": "world"}`
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

**Note:** These key paths are used optionally in objects conforming to `JSONTransformer` when the property being mapped to does not match the json structure. If the property name is the same as the key path, you dont need to include the key path.

**Note:** JSONKeyPath can also be expressed as a string literal.
> `JSONKeyPath("some_key")` == `"some_key"`

**Note:** You can also use Objective-C keypath notation.
> `JSONKeyPath("foo", "hello")` == `JSONKeyPath("foo.hello")` ==  `"foo.hello"`

This does not work for `Int` subscripts
> `JSONKeyPath("bar", 1)` != `JSONKeyPath("bar.1")`


### Nested Objects <a name="nested-objects"></a>

Lets add a nested class, `Passenger`. Flights have passengers. Nice.

You can denote a nested object via the static `transformer` property of any object or array of objects conforming to `JSONCodable`.

You can combine transformers using the `<-` operator. In this case, for the `airMarshal` property, both the key path and the nested object need explicit transforms.

```json
{
  "airline": "united",
  "flight_number": 472,
  "air_marshal" {
     "name": "50 Cent",
  },
  "passengers": [
  	  {
  	  "name": "Jennifer Lawrence",
  	  },
  	  {
  	  "name": "Chris Pratt"
  	  },
  	  ... 
  ]
}

```

```swift
struct Flight: JSONCodable {
	...
    let passengers: [Passenger]
    let airMarshal: Passenger
    ...
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	...
    	"passengers": [Passenger].transformer,
    	"airMarshal": "air_marshal" <- Passenger.transformer
    ]
    
    struct Passenger: JSONCodable {
        let name: String
    }
}
```

**Note:** When using the `<-` operator, always put the `JSONKeyPath` transformer first.

### Dates

Finally, lets add dates to the mix. Ladybug provides multiple date transformers:

* `secondsSince1970`: Decode the date as a UNIX timestamp from a JSON number.
* `millisecondsSince1970`: Decode the date as UNIX millisecond timestamp from a JSON number.
* `iso8601`: Decode the date as an ISO-8601-formatted string (in RFC 3339 format).
* `format(_ format: String)`: Decode the date with a custom date format string.
* `custom(_ adapter: @escaping (Any?) -> Date?)`: Return a `Date` from the JSON value.

```json
{
"july4th": "7/4/1776",
"y2k": 946684800,
}
```

```swift
struct SomeDates: JSONCodable {
    let july4th: Date
    let Y2K: Date
    let createdAt: Date
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "july4th": format("MM/dd/yyyy"),
        "Y2K": "y2k" <- secondsSince1970,
        "createdAt": custom { _ in return Date() }
    ]
}
```

**Note:** If using `custom` to map to a non-optional `Date`, returning `nil` will result in an error being thrown during decoding. 

### Additional Mapping: `Map<T: Codable>` <a name="mapping"></a>

If you need to provide a simple mapping from a JSON value to a property, use `MapTransformer`. A great example is using this to convert a string to an integer.

```swift
{
"count": "100"
}
...
struct BottlesOfBeerOnTheWall: JSONCodable {
    let count: Int
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
    	"count": Map<Int> { return Int($0 as! String) }
    ]
}
``` 

### Default Values / Migrations: `Default` <a name="default-values"></a>

If you wish to supply a default value for a property, you can use `Default`. You supply the default value, and can also control whether or not to override the property if the property key exists in the JSON payload.

```swift
init(value: Any, override: Bool = false)
```

The default transformer is useful when API's change, and can help migration from cached JSON data to `JSONCodable` objects with new properties.

## Using `JSONCodable` as a Generic Constraint <a name="generics"></a>

Because `Array` does not explicitly conform to `JSONCodable`, `JSONCodable` does not support list types when used as a generic constraint. If you need this support, you can use the `List<T: JSONCodable>` wrapper type.

```swift
struct Tweet: JSONCodable { ... }
class ContentProvider<T: JSONCodable> { ... }

let tweetDetailProvider = ContentProvider<Tweet>()
let timelineProvider = ContentProvider<List<Tweet>>()
```

## Handling Failure <a name="failure"></a>

### Errors
Ladybug is failure driven, and all `JSONCodable` initializers and encoding mechanisms throw errors if they fail. There is a `JSONCodableError` type that Ladybug will throw if there is a typecasting error, and Ladybug will also throw errors from `JSONSerialization`, `JSONDecoder`, and `JSONEncoder`.

### Optionals
If a value is optional in your JSON payload, it should be optional in your data model. Ladybug will only throw an error if a key is missing and the property it is being mapped to is non-optional. Play it safe kids, use optionals.

### Safety for `Map` and Custom Dates

There are 2 transformers that can return `nil` values: `Map<T: Codable>` and `custom(_ adapter: @escaping (Any?) -> Date?)`.

If you are decoding from an already encoded `JSONCodable` object, returning `nil` is fine.

If you are decoding from a `URLResponse`, returning nil can lead to an error being thrown.

## Class Conformance to `JSONCodable` <a name="class-conformance"></a>

There are 2 small caveat to keep in mind when you are conforming a `class` to `JSONCodable`:

1) Because classes in swift dont come with baked in default initializers like structs do, you have to make sure properties are initialized. You can do this by supplying default values, or a default initializer that initializes these values.

You can see examples in [`ClassConformanceTests.swift`](https://github.com/jhurray/Ladybug/blob/master/Tests/ClassConformanceTests.swift).

2) Subclassing an object conforming to `Codable` will not work, so it won't work for `JSONCodable` either.

Because of these caveats, I would suggest using structs for your data models. 

## Thoughts About 🐞 <a name="musings"></a>

### It would be pretty great if `AnyKeyPath` could generate a string for its associated property

If Swift 4 key paths exposed a string value, we could use `PartialKeyPath<Self>` as our `PropertyKey` typealias instead of `String`. This would be a much safer alternative.

```swift
 typealias PropertyKey = PartialKeyPath<Self>
...
static var transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
	\Tree.name: JSONKeyPath("tree_name") 
]
```

There was no disussion of this in [SE-0161](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md).

### It would also be great if `Mirror` could be created for types instead of instances

This would allow us to implicitly map nested objects conforming to `JSONCodable`.

### Whats wrong with `Codable`? <a name="why-not-codable"></a>

As mentioned before, `Codable` is a great step towards simplifying JSON parsing in swift, but the O(n) boilerplate that has become a mainstay in swift JSON parsing still exists when using `Codable` (e.g. For every property your object has, you need to write 1 or more lines of code to map the json to said property). In Apple's documentation on [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types), you can see that as soon as JSON keys diverge from property keys, you have to write a ton of boilerplate code to get `Codable` conformance. Ladybug sidesteps this, and  does a lot of this for you under the hood.

### Be careful with `MapTransformer`

Its easy to go a little to far with `MapTransformer`. In the example below, the map transformer is being used to calculate a sum instead of mapping a JSON value to a `Codable` type. To me, this promotes bad data modeling. I'm a firm believer that data models should closely mirror JSON responses. When used in the wrong way, map transformers can give too data models too much responsibility.

```swift
{
"values": [1, 1, 2, 3, 5, 8, 13]
}
... 
struct FibonacciSequence: JSONCodable {
	let values: [Int]
	let sum: Int
	
	static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
		"sum": MapTransformer<Int>(keyPath: "values") { value in
			let values = value as! [Int]
			return values.reduce(0) { $0 + $1 }
		}
	]
}
```

## Credits

Shoutout to the good folks at [Mantle](https://github.com/Mantle/Mantle) for giving me some inspiration on this project. I'm pretty happy a similar framework is finally possible for Swift without mixing in Obj-C runtime.

## Contact Info && Contributing

Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com) or [hit me up on the twitterverse](https://twitter.com/JeffHurray). I'd love to hear your thoughts on this, or see examples where this has been used.

[MIT License](https://github.com/jhurray/Ladybug/blob/master/LICENSE)





