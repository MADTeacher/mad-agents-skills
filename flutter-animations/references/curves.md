# Curves Reference

Curves define the easing function for animations, controlling how values interpolate from start to end.

## Core Concept

A curve takes an input `t` (0.0 to 1.0, representing time) and outputs a value (typically 0.0 to 1.0, representing progress).

## Built-in Curves

### Linear

```dart
Curves.linear
```

No easing - straight line from 0 to 1. Use when you want constant speed.

### Ease (Sigmoid)

```dart
Curves.ease
Curves.easeIn
Curves.easeOut
Curves.easeInOut
```

**Curves.ease** - Slow start and end, fast middle (most common)

**Curves.easeIn** - Slow start, fast end (accelerating)

**Curves.easeOut** - Fast start, slow end (decelerating)

**Curves.easeInOut** - Slow start and end, fast middle (combination)

### Cubic (Stronger Ease)

```dart
Curves.easeInCubic
Curves.easeOutCubic
Curves.easeInOutCubic
```

Stronger easing than basic ease. More dramatic slow/fast zones.

### Elastic (Bouncy)

```dart
Curves.elasticIn
Curves.elasticOut
Curves.elasticInOut
```

**Curves.elasticIn** - Bounces in (starts behind, shoots forward)

**Curves.elasticOut** - Bounces out (goes past, comes back)

**Curves.elasticInOut** - Bounces in and out

Example: Good for playful UI, notifications

### Bounce

```dart
Curves.bounceIn
Curves.bounceOut
Curves.bounceInOut
```

**Curves.bounceIn** - Bounces in (less bouncy than elastic)

**Curves.bounceOut** - Bounces out (less bouncy than elastic)

**Curves.bounceInOut** - Bounces in and out

Example: Good for feedback animations

### Back (Overshoot)

```dart
Curves.easeInBack
Curves.easeOutBack
Curves.easeInOutBack
```

**Curves.easeInBack** - Pulls back below the start before accelerating

**Curves.easeOutBack** - Overshoots the end, then settles back

**Curves.easeInOutBack** - Pulls back at the start and overshoots at the end

Example: Good for revealing content

### Decelerate (Fast then Slow)

```dart
Curves.decelerate
```

Fast start, very slow end. Similar to easeOut but more dramatic.

### Fast Out Slow In

```dart
Curves.fastOutSlowIn
```

The standard Material curve, `Cubic(0.4, 0.0, 0.2, 1.0)`: accelerates quickly, then decelerates slowly into the end.

### Custom Curves in Flutter API

Flutter includes specialized curves:

```dart
// Material design curves
Curves.fastLinearToSlowEaseIn
Curves.slowMiddle

// Specific curves for certain transitions
Curves.ease
```

## Using Curves

### With Implicit Animation

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: _expanded ? 200 : 100,
  child: const FlutterLogo(),
)
```

### With Explicit Animation (CurvedAnimation)

```dart
animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut,
);
```

### With Interval

```dart
animation = CurvedAnimation(
  parent: _controller,
  curve: const Interval(
    0.0,
    0.5,
    curve: Curves.easeIn,
  ),
);
```

### With Curves.elasticOut

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 1000),
  curve: Curves.elasticOut,
  transform: Matrix4.rotationZ(_rotated ? 0.5 : 0),
  child: const FlutterLogo(),
)
```

## Custom Curves

### Creating a Custom Curve

```dart
import 'dart:math' as math;

class CustomCurve extends Curve {
  @override
  double transform(double t) {
    // t is 0.0 to 1.0
    // Return 0.0 to 1.0
    return math.pow(t, 2).toDouble();  // Quadratic ease in (pow returns num)
  }
}
```

**Usage:**
```dart
AnimatedContainer(
  curve: CustomCurve(),
  duration: const Duration(milliseconds: 300),
  width: _expanded ? 200 : 100,
  child: const FlutterLogo(),
)
```

### Shake (not a Curve)

A curve must map 0.0 to 0.0 and 1.0 to 1.0. `sin(t * pi * 2)` ends at 0.0, so
`CurvedAnimation` (which implicit animation widgets also use) throws
"Invalid curve endpoint at 1.0" in debug mode. Drive a shake from a linear
controller and apply the oscillation in the builder instead:

```dart
AnimatedBuilder(
  animation: _controller, // e.g. 400ms; call _controller.forward(from: 0) to shake
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(sin(_controller.value * pi * 2) * 8, 0),
      child: child,
    );
  },
  child: const Text('Shake me'),
)
```

### Smooth Step Curve

```dart
class SmoothStep extends Curve {
  final double steps;

  const SmoothStep({this.steps = 5});

  @override
  double transform(double t) {
    return (t * steps).floor() / steps;
  }
}
```

### Exponential Curve

```dart
class ExponentialCurve extends Curve {
  final double exponent;

  const ExponentialCurve({this.exponent = 2});

  @override
  double transform(double t) {
    return math.pow(t, exponent).toDouble();
  }
}
```

## Curve Composition

### Cubic Bezier

Flutter has a built-in cubic Bézier curve, `Cubic(a, b, c, d)`, with the same
control points as CSS `cubic-bezier(a, b, c, d)`. `Curves.ease`,
`Curves.fastOutSlowIn` and most other standard curves are `Cubic` instances.

```dart
// CSS: cubic-bezier(0.68, -0.55, 0.265, 1.55)
const myCurve = Cubic(0.68, -0.55, 0.265, 1.55);

AnimatedContainer(
  curve: myCurve,
  duration: const Duration(milliseconds: 300),
  width: _expanded ? 200 : 100,
  child: const FlutterLogo(),
)
```

### Combining Curves

```dart
class CombinedCurve extends Curve {
  final Curve first;
  final Curve second;
  final double threshold;

  const CombinedCurve({
    required this.first,
    required this.second,
    required this.threshold,
  });

  @override
  double transform(double t) {
    if (t < threshold) {
      return first.transform(t / threshold) * threshold;
    }
    return threshold +
        second.transform((t - threshold) / (1 - threshold)) * (1 - threshold);
  }
}
```

**Usage:**
```dart
AnimatedContainer(
  curve: CombinedCurve(
    first: Curves.easeIn,
    second: Curves.easeOut,
    threshold: 0.5,
  ),
  duration: const Duration(milliseconds: 500),
  width: _expanded ? 200 : 100,
  child: const FlutterLogo(),
)
```

## Choosing the Right Curve

### Motion Design Guidelines

| Animation Type | Recommended Curve | Why |
|---------------|-------------------|-----|
| Fade in/out | easeInOut | Natural opacity change |
| Size change | easeOut | Decelerate feels natural for growth |
| Position slide | easeInOut | Smooth start and stop |
| Rotation | easeInOut | Natural angular acceleration |
| Color change | linear | Uniform color transition |
| Scale | elasticOut | Playful, bouncy feel |
| Reveal | easeOutBack | Dramatic reveal effect |
| Loading | linear or ease | Consistent speed |
| Success | elasticOut | Celebratory feel |

### Platform Conventions

**iOS:**
- Prefers subtle curves (ease, easeInOut)
- Limited use of elastic/bounce
- Consistent with system animations

**Android:**
- Wider variety of curves
- More use of elastic/bounce for feedback
- Material design curves (easeIn, fastOutSlowIn)

**Web:**
- CSS-like curves (ease, ease-in, ease-out, ease-in-out)
- Limited use of complex curves

## Curve Combinations

### Multi-Stage Animation

```dart
// Stage 1: Ease in (0.0 - 0.5)
// Stage 2: Ease out (0.5 - 1.0)

animation1 = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
);

animation2 = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
);
```

### Staggered with Different Curves

```dart
// Item 1: Bouncy
item1Animation = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
);

// Item 2: Smooth
item2Animation = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.1, 0.4, curve: Curves.easeInOut),
);

// Item 3: Linear
item3Animation = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.2, 0.5, curve: Curves.linear),
);
```

## Performance Considerations

### Curve Complexity

Simple curves (linear, ease) are faster:
- Fewer calculations
- Less GPU work
- Consistent timing

Complex curves (elastic, bounce) are slower:
- More calculations
- Potential for frame drops
- Variable timing

### Optimization Tips

- Use simpler curves on low-end devices
- Cache curve calculations if needed
- Test performance on target devices
- Profile with Flutter DevTools

## Debugging Curves

### Visualize Curve

```dart
class CurveVisualizer extends StatelessWidget {
  final Curve curve;

  const CurveVisualizer({super.key, required this.curve});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CurvePainter(curve: curve),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final Curve curve;

  const _CurvePainter({required this.curve});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (double t = 0; t <= 1; t += 0.01) {
      final x = t * size.width;
      final y = size.height - (curve.transform(t) * size.height);
      if (t == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) => false;
}
```

### Print Curve Values

```dart
void printCurveValues(Curve curve) {
  print('Curve: $curve');
  for (double t = 0; t <= 1; t += 0.1) {
    print('t=$t, output=${curve.transform(t)}');
  }
}

// Usage
printCurveValues(Curves.easeInOut);
```

## Accessibility

### Respecting User Preferences

```dart
Curve getAdaptiveCurve(BuildContext context) {
  if (MediaQuery.of(context).disableAnimations) {
    return Curves.linear;  // No easing when animations disabled
  }
  return Curves.easeInOut;
}
```

### Reduced Motion

```dart
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 300),
  curve: getAdaptiveCurve(context),
  width: _expanded ? 200 : 100,
  child: const FlutterLogo(),
)
```

## Common Patterns

### Loading Spinner

```dart
_animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.linear,  // Constant speed
);
```

### Success Checkmark

```dart
_animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.elasticOut,  // Bouncy celebration
);
```

### Page Transition

```dart
_enterAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeIn,  // Accelerate in
);

_exitAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeOut,  // Decelerate out
);
```

### Modal Popup

```dart
_animation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeOutBack,  // Dramatic reveal
);
```

## Curve Comparison

| Curve | Start | Middle | End | Feel |
|-------|-------|--------|-----|------|
| linear | Fast | Fast | Fast | Mechanical |
| ease | Slow | Fast | Slow | Natural |
| easeIn | Slow | Fast | Fast | Accelerating |
| easeOut | Fast | Slow | Slow | Decelerating |
| easeInOut | Slow | Fast | Slow | Smooth |
| elasticIn | Back | Fast | Normal | Bouncy start |
| elasticOut | Normal | Fast | Back | Bouncy end |
| bounceIn | Bounce | Fast | Normal | Bouncy start |
| bounceOut | Normal | Fast | Bounce | Bouncy end |
| easeInBack | Back | Fast | Normal | Overshoot start |
| easeOutBack | Normal | Fast | Back | Overshoot end |

## Best Practices

### DO

- Use appropriate curves for animation type
- Test on real devices
- Consider platform conventions
- Respect accessibility settings
- Profile performance with DevTools

### DON'T

- Use elastic/bounce for everything (distracting)
- Over-combine curves (confusing motion)
- Ignore device performance
- Use same curve for all animations (boring)
- Forget to handle edge cases (t < 0 or t > 1)
