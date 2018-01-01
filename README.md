# Tagless Graphics

The doctor pretty branch. Doc instance for the drawing tagless dsl.

This

```swift
func sample<D: Drawing>() -> D {
    return .combined([
        .ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: CGColor(red: 1.0, green: 0, blue: 0, alpha: 0)),
        .rectangle(CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), fill: CGColor(red: 0, green: 0, blue: 1.0, alpha: 0))
        ])
}
```

Outputs this when pretty printed at the following widths (see the tests of the `swiftpm/` version)

```
@ 40
combined(
  layers: [
    ellipse(
      in: CGRect(
        x: 0.0,
        y: 0.0,
        width: 100.0,
        height: 100.0
      ),
      fill: CGColor(
        rgba: (
          1.0,
          0.0,
          0.0,
          0.0
        )
      )
    ),
    rectangle(
      rect: CGRect(
        x: 50.0,
        y: 50.0,
        width: 100.0,
        height: 100.0
      ),
      fill: CGColor(
        rgba: (
          0.0,
          0.0,
          1.0,
          0.0
        )
      )
    )
  ]
)
@ 80
combined(
  layers: [
    ellipse(
      in: CGRect(
        x: 0.0,
        y: 0.0,
        width: 100.0,
        height: 100.0
      ),
      fill: CGColor(
        rgba: (1.0, 0.0, 0.0, 0.0)
      )
    ),
    rectangle(
      rect: CGRect(
        x: 50.0,
        y: 50.0,
        width: 100.0,
        height: 100.0
      ),
      fill: CGColor(
        rgba: (0.0, 0.0, 1.0, 0.0)
      )
    )
  ]
)
@ 120
combined(
  layers: [
    ellipse(
      in: CGRect(
        x: 0.0, y: 0.0, width: 100.0, height: 100.0
      ),
      fill: CGColor(rgba: (1.0, 0.0, 0.0, 0.0))
    ),
    rectangle(
      rect: CGRect(
        x: 50.0, y: 50.0, width: 100.0, height: 100.0
      ),
      fill: CGColor(rgba: (0.0, 0.0, 1.0, 0.0))
    )
  ]
)
```
