# Troubleshooting

## Common Issues

**Widget not rendering:**

- Check widget type is registered (for custom widgets)
- Verify JSON structure matches expected format
- Ensure `id` is unique across layout

**Driver initialization failing:**

- Check network connectivity
- Verify base URL and headers
- Check server is returning valid JSON

**Theme not applying:**

- Ensure DuitRegistry.initialize called before runApp
- Verify theme name in JSON matches registered theme
- Check overrideRule if attributes conflict with theme

**Memory leaks:**

- Always dispose XDriver in StatefulWidgets
- Dispose custom transport managers properly
