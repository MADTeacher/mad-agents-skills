import 'package:flutter/material.dart';

/// Example of responsive navigation that switches between
/// NavigationBar (bottom) and NavigationRail (side)
/// based on window width.
class ResponsiveNavigationExample extends StatefulWidget {
  const ResponsiveNavigationExample({super.key});

  @override
  State<ResponsiveNavigationExample> createState() =>
      _ResponsiveNavigationExampleState();
}

class _ResponsiveNavigationExampleState
    extends State<ResponsiveNavigationExample> {
  static const _destinations = [
    _AdaptiveDestination(Icons.home, 'Home'),
    _AdaptiveDestination(Icons.search, 'Search'),
    _AdaptiveDestination(Icons.person, 'Profile'),
  ];

  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return width >= 600 ? _buildLargeLayout() : _buildSmallLayout();
  }

  /// Layout for small screens - bottom navigation
  Widget _buildSmallLayout() {
    return Scaffold(
      appBar: AppBar(title: Text(_destinations[_selectedIndex].label)),
      body: _DestinationBody(label: _destinations[_selectedIndex].label),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  /// Layout for large screens - side navigation rail
  Widget _buildLargeLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectDestination,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          Expanded(
            child: _DestinationBody(label: _destinations[_selectedIndex].label),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveDestination {
  const _AdaptiveDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _DestinationBody extends StatelessWidget {
  const _DestinationBody({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
