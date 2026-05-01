# ARB File Format Reference

Complete reference for App Resource Bundle (`.arb`) files used by Flutter's gen-l10n tool.

## ARB File Basics

ARB files are JSON files containing localization resources with metadata.

### Basic Structure

```json
{
  "messageKey": "Message value",
  "@messageKey": {
    "description": "Message description for translators"
  }
}
```

### Template File

The template file (typically `app_en.arb`) contains all keys with their English translations and metadata:

```json
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "The conventional newborn programmer greeting"
  }
}
```

### Translation File

Translation files (e.g., `app_es.arb`) only contain translated values:

```json
{
  "helloWorld": "¡Hola Mundo!"
}
```

## Message Types

### Simple Messages

Basic text without parameters:

```json
{
  "welcome": "Welcome to our app",
  "@welcome": {
    "description": "Welcome message shown on home screen",
    "type": "text"
  }
}
```

### Placeholder Messages

Messages with dynamic values:

```json
{
  "hello": "Hello {userName}",
  "@hello": {
    "description": "A message with a single parameter",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Bob"
      }
    }
  }
}
```

### Plural Messages

Messages that change based on count:

```json
{
  "nWombats": "{count, plural, =0{no wombats} =1{1 wombat} other{{count} wombats}}",
  "@nWombats": {
    "description": "A plural message",
    "placeholders": {
      "count": {
        "type": "num",
        "format": "compact"
      }
    }
  }
}
```

Plural forms: `=0`, `=1`, `=2`, `zero`, `one`, `two`, `few`, `many`, `other`

### Select Messages

Messages that change based on a string value:

```json
{
  "pronoun": "{gender, select, male{he} female{she} other{they}}",
  "@pronoun": {
    "description": "A gendered message",
    "placeholders": {
      "gender": {
        "type": "String"
      }
    }
  }
}
```

Select matching is case-sensitive. For example, `Male` does not match `male`
and falls back to `other`, so normalize values before passing them to generated
localization methods.

## Placeholder Types

### String

```json
{
  "greeting": "Hello {name}",
  "@greeting": {
    "placeholders": {
      "name": {
        "type": "String",
        "example": "Alice"
      }
    }
  }
}
```

### Number Formatting

```json
{
  "price": "Price: {value}",
  "@price": {
    "placeholders": {
      "value": {
        "type": "int",
        "format": "compactCurrency",
        "optionalParameters": {
          "decimalDigits": 2,
          "symbol": "$"
        }
      }
    }
  }
}
```

### Date Formatting

```json
{
  "eventDate": "Event on {date}",
  "@eventDate": {
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  }
}
```

## Number Format Options

See [number-date-formats.md](number-date-formats.md) for the complete list of
number and date format options.

## Date Format Options

Common `DateFormat` patterns:

| Pattern | Example (en_US) | Description |
|---------|----------------|-------------|
| `y` | 2024 | Year |
| `yM` | 1/2024 | Year/Month |
| `yMd` | 1/15/2024 | Year/Month/Day |
| `yMMMd` | Jan 15, 2024 | Month name, Day, Year |
| `yMMMMd` | January 15, 2024 | Full month name, Day, Year |
| `MMMMd` | January 15 | Full month name, Day |
| `EEE, MMM d` | Mon, Jan 15 | Day name, Month abbr, Day |

## Metadata Attributes

### Required Attributes for Complex Messages

For messages with placeholders, plurals, or selects:

```json
{
  "message": "Text with {placeholder}",
  "@message": {
    "description": "Message description",
    "placeholders": {
      "placeholder": {
        "type": "String"
      }
    }
  }
}
```

### Optional Attributes

```json
{
  "message": "Text",
  "@message": {
    "description": "Message description",
    "type": "text",
    "context": "Context for disambiguation"
  }
}
```

## Escaping Syntax

Enable escaping in `l10n.yaml`:

```yaml
use-escaping: true
```

Then use single quotes to escape special characters:

```json
{
  "escaped": "Hello! '{Isn''t}' this a wonderful day?"
}
```

Results in: `Hello! {Isn't} this a wonderful day?`

## Complete Example

```json
{
  "appTitle": "My App",
  "@appTitle": {
    "description": "Application title"
  },
  "greeting": "Hello {userName}!",
  "@greeting": {
    "description": "Personalized greeting message",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "John"
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Number of items in cart",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "pronoun": "{gender, select, male{he} female{she} other{they}}",
  "@pronoun": {
    "description": "Gender-based pronoun",
    "placeholders": {
      "gender": {
        "type": "String"
      }
    }
  },
  "orderDate": "Ordered on {date}",
  "@orderDate": {
    "description": "Order confirmation with date",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMMMd"
      }
    }
  }
}
```

## Best Practices

1. **Use descriptive keys**: `userProfileTitle` instead of `title1`
2. **Provide examples**: Help translators understand context
3. **Use type annotations**: Improves generated code type safety
4. **Add descriptions**: Provide context for translators
5. **Keep messages short**: Make them easier to translate
6. **Use placeholders**: Don't concatenate strings
7. **Format numbers/dates**: Let Flutter handle localization
