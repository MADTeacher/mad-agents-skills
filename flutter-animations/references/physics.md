# Physics-Based Animations Reference

Physics-based animations create natural-feeling motion using simulations like springs, gravity, and momentum.

## Core Concept

Instead of linear interpolation, use physics simulations for realistic motion that responds naturally to forces like velocity and damping.

## Fling Animation

### Basic Fling

```dart
class FlingWidget extends StatefulWidget {
  @override
  State<FlingWidget> createState() => _FlingWidgetState();
}

class _FlingWidgetState extends State<FlingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller.fling(velocity: 2.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_controller.value * 100, 0),
          child: child,
        );
      },
      child: const FlutterLogo(),
    );
  }
}
```

### Fling with Gesture

```dart
class DraggableFling extends StatefulWidget {
  @override
  State<DraggableFling> createState() => _DraggableFlingState();
}

class _DraggableFlingState extends State<DraggableFling>
    with SingleTickerProviderStateMixin {
  // Unbounded controller: its value is the horizontal offset in pixels.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _controller.stop();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _controller.value += details.delta.dx;
  }

  void _handlePanEnd(DragEndDetails details) {
    // Don't call fling() on an unbounded controller: fling() springs towards
    // lowerBound/upperBound, which are -infinity/+infinity here.
    // FrictionSimulation decelerates from the release velocity (px/s) to a stop.
    _controller.animateWith(
      FrictionSimulation(
        0.135, // drag: fraction of velocity left after one second
        _controller.value,
        details.velocity.pixelsPerSecond.dx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_controller.value, 0),
            child: child,
          );
        },
        child: const FlutterLogo(),
      ),
    );
  }
}
```

## Spring Simulation

### Basic Spring

```dart
class SpringAnimation extends StatefulWidget {
  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);

    // SpringSimulation takes positional arguments: (spring, start, end, velocity).
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1.0,
          stiffness: 200.0,
          damping: 10.0,
        ),
        0.0, // start
        1.0, // end
        0.0, // velocity
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          child: child,
        );
      },
      child: const FlutterLogo(),
    );
  }
}
```

### Spring Description Parameters

```dart
SpringDescription(
  mass: 1.0,        // Mass of the object (higher = more inertia)
  stiffness: 200.0, // Spring stiffness (higher = faster, stiffer)
  damping: 10.0,    // Damping coefficient, not a ratio (higher = less oscillation)
)

// Or give the damping ratio directly (1.0 = critically damped, no overshoot):
SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 200.0,
  ratio: 1.0,
)
```

**Mass:**
- How "heavy" the object feels
- Typical values: 0.5 - 5.0
- Higher mass = more momentum, slower response

**Stiffness:**
- How stiff the spring is
- Typical values: 100 - 500
- Higher stiffness = faster oscillation
- Lower stiffness = slower; with the same `damping` it also raises the damping ratio, so it bounces less

**Damping:**
- How quickly oscillation stops
- `damping` is a coefficient, so its effect depends on mass and stiffness.
  The damping ratio is `damping / (2 * sqrt(mass * stiffness))`:
  - ratio < 1: underdamped, overshoots and oscillates
  - ratio = 1: critically damped, settles fastest without overshoot
  - ratio > 1: overdamped, settles slowly without overshoot
- Critical damping is `2 * sqrt(mass * stiffness)`, about 28.3 for mass 1.0 and stiffness 200
- Use `SpringDescription.withDampingRatio` to set the ratio directly

### Spring Presets

**Bouncy:**
```dart
SpringDescription.withDampingRatio(
  mass: 0.5,
  stiffness: 300,
  ratio: 0.3, // visible overshoot and oscillation
)
```

**Snappy:**
```dart
SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 400,
  ratio: 0.9, // fast, almost no overshoot
)
```

**Gentle:**
```dart
SpringDescription.withDampingRatio(
  mass: 2.0,
  stiffness: 150,
  ratio: 1.0, // slow, no overshoot
)
```

## Gravity Simulation

### Falling Animation

```dart
class GravityAnimation extends StatefulWidget {
  @override
  State<GravityAnimation> createState() => _GravityAnimationState();
}

class _GravityAnimationState extends State<GravityAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);

    // GravitySimulation takes positional arguments:
    // (acceleration, start position, end position, initial velocity).
    // The simulation is done once the position passes the end position.
    _controller.animateWith(
      GravitySimulation(
        980, // acceleration in pixels/s²
        0, // start position
        500, // end position: pixels to fall
        0, // initial velocity
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _controller.value),
          child: child,
        );
      },
      child: const FlutterLogo(),
    );
  }
}
```

## Scroll Physics

### Bouncing Scroll

```dart
CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
    SliverList(
      delegate: SliverChildListDelegate([
        // Items
      ]),
    ),
  ],
)
```

### Clamping Scroll

```dart
CustomScrollView(
  physics: const ClampingScrollPhysics(),
  slivers: [
    SliverList(
      delegate: SliverChildListDelegate([
        // Items
      ]),
    ),
  ],
)
```

### Fixed Scroll

```dart
CustomScrollView(
  physics: const NeverScrollableScrollPhysics(),
  slivers: [
    SliverList(
      delegate: SliverChildListDelegate([
        // Items
      ]),
    ),
  ],
)
```

### Always Scrollable

Scrolls (and overscrolls) even when the content is shorter than the viewport.
This is not platform-adaptive. For the platform default (bouncing on iOS and macOS,
clamping elsewhere), omit `physics` and let `ScrollConfiguration` choose it.

```dart
CustomScrollView(
  physics: const AlwaysScrollableScrollPhysics(),
  slivers: [
    SliverList(
      delegate: SliverChildListDelegate([
        // Items
      ]),
    ),
  ],
)
```

## Custom Simulation

### Creating Custom Simulation

```dart
class CustomSimulation extends Simulation {
  final double target;

  CustomSimulation({required this.target});

  @override
  double x(double time) {
    // Calculate position at given time
    return target * (1 - math.exp(-time / 0.5));
  }

  @override
  double dx(double time) {
    // Calculate velocity (derivative) at given time
    return target * math.exp(-time / 0.5) / 0.5;
  }

  @override
  bool isDone(double time) {
    return dx(time).abs() < 0.01;
  }
}
```

**Usage:**
```dart
_controller.animateWith(
  CustomSimulation(target: 1.0),
);
```

### Decay Simulation

```dart
class DecaySimulation extends Simulation {
  final double velocity;

  DecaySimulation({required this.velocity});

  @override
  double x(double time) {
    return velocity * (1 - math.exp(-time));
  }

  @override
  double dx(double time) {
    return velocity * math.exp(-time);
  }

  @override
  bool isDone(double time) {
    return dx(time).abs() < 0.1;
  }
}
```

## Combining Physics and Animation

### Spring with Fallback

```dart
void animateWithSpring({
  required AnimationController controller,
  required double start,
  required double end,
}) {
  try {
    controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1.0,
          stiffness: 200.0,
          damping: 15.0,
        ),
        start,
        end,
        0.0, // velocity
      ),
    );
  } catch (e) {
    // Fallback to linear animation
    controller.animateTo(end);
  }
}
```

### Spring with Completion Callback

```dart
_controller.animateWith(
  SpringSimulation(
    const SpringDescription(
      mass: 1.0,
      stiffness: 200.0,
      damping: 15.0,
    ),
    0.0, // start
    1.0, // end
    0.0, // velocity
  ),
);

_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    // Animation complete
  }
});
```

## Physics for Gestures

### Swipe to Dismiss with Physics

```dart
class DismissibleWithPhysics extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const DismissibleWithPhysics({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  @override
  State<DismissibleWithPhysics> createState() => _DismissibleWithPhysicsState();
}

class _DismissibleWithPhysicsState extends State<DismissibleWithPhysics>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 15.0,
  );

  // Unbounded controller: its value is the horizontal offset in pixels.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final offset = _controller.value;

    if (velocity.abs() > 500 || offset.abs() > screenWidth / 3) {
      // Dismiss: spring to a finite target off-screen. Don't use fling() on an
      // unbounded controller: it would target -infinity/+infinity.
      final direction = velocity.abs() > 500 ? velocity.sign : offset.sign;
      _controller
          .animateWith(
            SpringSimulation(_spring, offset, direction * screenWidth, velocity),
          )
          .then((_) => widget.onDismiss());
    } else {
      // Spring back from the current offset.
      _controller.animateWith(SpringSimulation(_spring, offset, 0, velocity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!_controller.isAnimating) {
          _controller.value += details.delta.dx;
        }
      },
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_controller.value, 0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
```

## Performance Considerations

### Simulation Complexity

Physics simulations can be computationally expensive. Optimize by:

- Using simpler simulations when possible (e.g., linear interpolation)
- Reducing simulation resolution
- Caching simulation results
- Using built-in physics widgets

### Spring Tuning

Finding the right spring parameters can be trial and error:

1. Start with moderate values: `SpringDescription.withDampingRatio(mass: 1.0, stiffness: 200, ratio: 0.8)`
2. Adjust for feel:
   - Too slow? Increase stiffness or decrease mass
   - Too bouncy? Increase the damping ratio (1.0 removes overshoot)
   - Not bouncy enough? Decrease the damping ratio
3. Test on real devices

## Debugging

### Visualize Physics

```dart
void main() {
  timeDilation = 5.0;  // Slow down physics
  runApp(MyApp());
}
```

### Print Simulation Values

```dart
_controller.addListener(() {
  print('Position: ${_controller.value}');
});

_controller.addStatusListener((status) {
  print('Status: $status');
});
```

### Physics Inspector

Use Flutter DevTools to profile physics animations:
1. Open Performance overlay
2. Look for frame drops during physics simulations
3. Identify expensive calculations

## Best Practices

### DO

- Use physics simulations for natural-feeling motion
- Tune spring parameters for desired feel
- Test on various devices and screen sizes
- Profile performance with DevTools
- Provide fallback animations for physics failures

### DON'T

- Use complex physics when simple curves suffice
- Forget to handle simulation completion
- Use overly bouncy animations (distracting)
- Ignore accessibility (respect disable animations preference)
- Assume physics simulation completes instantly

## Common Physics Patterns

### Bouncy Button Press

```dart
_controller.animateWith(
  SpringSimulation(
    const SpringDescription(
      mass: 0.5,
      stiffness: 500,
      damping: 10,
    ),
    1.0, // start
    0.9, // end
    0, // velocity
  ),
);
```

### Swipeable Card

```dart
_controller.fling(
  velocity: details.velocity.pixelsPerSecond.dx / 1000,
);
```

### Pull to Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    // Refresh data
  },
  child: ListView(...),
)
```

## Accessibility

- Respect `MediaQuery.disableAnimations` setting
- Provide non-physics alternatives
- Ensure physics animations don't cause motion sickness
- Test with reduced motion settings

## Platform-Specific Physics

### Adaptive Scroll Physics

```dart
class AdaptiveScrollPhysics extends ScrollPhysics {
  const AdaptiveScrollPhysics({super.parent});

  @override
  AdaptiveScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AdaptiveScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => Platform.isIOS
      ? const SpringDescription(
          mass: 0.5,
          stiffness: 100,
          damping: 10,
        )
      : const SpringDescription(
          mass: 0.8,
          stiffness: 150,
          damping: 15,
        );
}
```

**Usage:**
```dart
ListView(
  physics: const AdaptiveScrollPhysics(),
  children: [...],
)
```
