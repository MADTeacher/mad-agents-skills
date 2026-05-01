import 'package:flutter/material.dart';

/// Example of Capability and Policy classes
/// for handling platform-specific behavior.
class CapabilityPolicyExample extends StatelessWidget {
  const CapabilityPolicyExample({
    super.key,
    this.capability = const Capability(),
    this.policy = const Policy(),
  });

  final Capability capability;
  final Policy policy;

  @override
  Widget build(BuildContext context) {
    final canOpenExternalPurchase = capability.canOpenExternalPurchase();
    final shouldShowExternalPurchase = policy.shouldShowExternalPurchase();

    return Scaffold(
      appBar: AppBar(title: const Text('Capability & Policy Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canOpenExternalPurchase && shouldShowExternalPurchase)
              ElevatedButton(
                onPressed: capability.openExternalPurchase,
                child: const Text('Buy in Browser'),
              )
            else
              const Text('Purchase not available on this platform'),
          ],
        ),
      ),
    );
  }
}

/// Capability class - defines what the code CAN do
class Capability {
  const Capability();

  /// Check whether the app has an implementation for opening purchases.
  bool canOpenExternalPurchase() {
    return true;
  }

  /// Open purchase flow using the target app's URL launcher or service.
  void openExternalPurchase() {
    debugPrint('Opening purchase flow');
  }
}

/// Policy class - defines what the code SHOULD do
class Policy {
  const Policy({this.externalPurchaseAllowed = true});

  final bool externalPurchaseAllowed;

  /// Policy: decide whether the external purchase entry point is allowed.
  bool shouldShowExternalPurchase() {
    return externalPurchaseAllowed;
  }
}
