# Ladybug 🐞

Ladybug makes it easy to write a simple model or data-model layer in Swift 4

This framework is *modeled* (ha 👏 ha 👏) after [Mantle](https://github.com/Mantle/Mantle). Mantle provides easy translation from JSON to model objects, and also comes with [`NSCoding`](https://developer.apple.com/documentation/foundation/nscoding) conformance out of the box. Ladybug takes advantage of the new [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol to provide similar functionality without subclassing `NSObject`.

### Quick Links
* [Setup](#setup)
* [Mapping JSON to properties](#json-to-property)
* [Nested objects](#nested-objecs)
* [Dates](#dates)
* [Default Values / Migration](#default-values)
* [JSONKeyPath](#jsonkeypath)

## Why Ladybug? 
Ladybug takes the pain out of parsing JSON in Swift. It allows you to map JSON keys to properties of your model without having to worry about explicit types. 

`Codable` is a huge step for modeling data in swift, but if your JSON structure diverges from your model, conforming to `Codable` can be a **huge** pain 🤕. I elaborate on this [here](#why-not-codable).

#### Setup <a name="setup"></a>
By conforming to the `JSONCodable` protocol provided by 🐞, you can initialize any `struct` or `class` with `Data` or JSON, and get full `Codable` conformance.


```swift
struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
}
...
let treeJSON = [
  "name": "pine",
  "age": "121",
  "family": 1
]
...
let pineTree = try Tree(json: treeJSON)
let forest = try Array<Tree>(json: [treeJSON, treeJSON, treeJSON])

```

`pineTree` and `forest` are fully initialized and can be encoded and decoded. Simple as that. 

**Note:** Any nested enum must conform to `Codable` and `RawRepresentable` where the `RawValue` is `Codable`.

## Mapping JSON Keys to Properties <a name="json-to-property"></a>
Ok, it gets a little more complicated, but its easy, I swear. 

What if our JSON looked like this:

```json   
{
  "tree_name": "pine",
  "age": 121,
  "family": 1
}
```

We need to map the `tree_name` key to the `name` property.

You can associate JSON keys with properties via different objects conforming to `JSONTransformer`.

There are 4 types of transformers provided:    

* `JSONKeyPathTransformer` (mapping key paths to property names)
* `JSONNestedObjectTransformer` (explicitly calling out nested types)
* `JSONNestedListTransformer` (explicitly calling out nested list)
* `JSONDateTransformer` (handling dates in different formats)
* `JSONDefaultValueTransformer` (assigning default values to properties)

Transformers are provided via a readonly `static` property of the `JSONCodable` protocol.

```swift
static var transformers: [JSONTransformer] { get }
```

### `JSONKeyPathTransformer`


To solve the problem above, we would have to override `transformers` in our `Tree` object, and supply a key path transformer.

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
* `JSONKeyPath("bar", 1)` maps to `"ipsum"`

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

You can also use keypath notation from Objective-C. In that sense `JSONKeyPath("foo", "hello")` is the same as `JSONKeyPath("foo.hello")`

These key paths are used optionally in the rest of the transformers if the transformed property name does not match the json structure.

### Nested Objects: `JSONNestedObjectTransformer` and `JSONNestedListTransformer`

Lets add a nested class, `Leaf`. Trees have leaves. Nice.

```json
{
  "tree_name": "pine",
  "age": 121,
  "family": 1
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
    	JSONNestedListTransformer(propertyName: "leaves", type: Leaf.self),
    	JSONNestedObjectTransformer(propertyName: "firstLeaf", keyPath: JSONKeyPath("leaves", 0), type: Leaf.self)
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

### Default Values / Migrations: `JSONDefaultValueTransformer` <a name="default-values"></a>

// Yeah yeah talk about it


## Whats Wrong With `Codable`? <a name="why-not-codable"></a>

[Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)

## Handling Failure

Try catch stuff

Optionals

Mismatched type

Migration?

## Class Conformance to `JSONCodable`

## Thoughts About 🐞

* Why I didnt map objects further
* Swift 4 features
* Performance
* Custom rules (underscore -> camelCase)


## Contact Info && Contributing

Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com). I'd love to hear your thoughts on this, or see examples where this has been used.

[MIT License](https://github.com/jhurray/Ladybug/blob/master/LICENSE)





