---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraPS/about/custom-fields.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/custom-fields.html
---
# Custom Fields

## about_JiraPS_CustomFields

# SHORT DESCRIPTION

Jira has fields of all possible types. Strings, text boxes, numbers, dropdown menus, lists, aso.

This article explains how to pass the desired value for each of them.

# LONG DESCRIPTION

Many of JiraPS's functions contain convenience parameters for issue fields that are commonly used. These parameters take care of translating PowerShell to the correct JSON format when working with Jira's API.

However, not every standard Jira field is implemented via a parameter, and most Jira instances also contain custom fields to allow your organization to tailor its Jira instance to your own requirements. To allow JiraPS to work with fields that do not have named parameters, these functions support a generic `-Fields` parameter.

## Using -Fields

Basically, `-Fields` uses a hashtable that looks something like this:

```powerShell
    $fields = @{
        fieldName = @{
            value = 'New Value'
        }
        fieldID = @{
            id = 'ID of new value or item'
        }
    }

    Set-JiraIssue -Fields $fields
```

> This isn't a super easy syntax - and the module authors are always open to ideas for ways to improve this.

There are two easy ways to know more about a specific field:

- use the `Get-JiraField` function. This can tell you a lot about what to pass in the Fields hashtable.
- use the `Get-JiraIssue | Format-List *` function on an issue that has the value you are looking for.

### Some Known Field Formats

Here are some notes on specific fields that have come up in the past.

#### Text field

A text field is a single line of text that requires the value to be a string.

Examples are:

- Summary
```powershell
$fields = @{
    summary = "This is an example"
}
```

#### Text Area

A text field with multiple lines of text that requires the value to be a string.

Examples are:

- Description
```powershell
$fields = @{
    description = @"
    This is an example
    with multiple lines of text
"@ # this uses the here-string to pass a multiline value
}
```

#### Number

A number field requires the value to be an Integer.

```powershell
$fields = @{
    customfield_11444 = 123
}
```

#### Array

A custom field that is an array of strings.

Examples are:

- Labels
```powershell
$fields = @{
    labels = @( "nameOfTheLabel" )
}
```

#### Single-select

A custom field that allows you to select a single value from a defined list of values.
You can address them by 'value' or by 'id'.

```powershell
$fields = @{
    customfield_11449 = { value = "option3" }
    # or:
    customfield_11449 = { id = 10112 }
}
```

#### Multi-select

Multi-value fields require the value to be an array, even if you're only defining one value.

Examples are:

- Component/s
```powerShell
$fields = @{
    components = @(
        @{ name = 'Component 1' }
    )
}
```

#### Date Picker

A date is passed as a string in the 'YYYY-MM-DD' format.

Examples are:

- DueDate
```powershell
$fields = @{
    duedate = "2017-12-31"
}
```

#### DateTime Picker

A custom field that is a datetime in ISO 8601 `YYYY-MM-DDThh:mm:ss.sTZD` format.

```powershell
$fields = @{
    customfield_11442 = "2015-11-18T14:39:00.000+1100"
}
# or (the automated way of using a [DateTime] object):
$date = Get-Date
$fields = @{
    customfield_11442 = $date.ToString("o") -replace "\.(\d{3})\d*([\+\-]\d{2}):", ".`$1`$2"
}
```

> The "automated way of using a [DateTime] object" mentioned above is needed, as Powershell's `Get-Date -format "o"` differs from what Jira supports:  
> PoSh: `2015-11-18T14:39:00.0000000+11:00`  
> Jira: `2015-11-18T14:39:00.000+1100`

#### Checkbox

A custom field that allows you to select a multiple values from a defined list of values.
You can address them by 'value' or by 'id'.

```powershell
$fields = @{
    customfield_11440 = @(
        @{ value = "Text of the first checkbox" }
        @{ value = "Text of the third checkbox" }
    )
    # or:
    customfield_11440 = @(
        @{ id = 10112} # id of the first checkbox
        @{ id = 10114} # id of the third checkbox
    )
}
```

#### Radio Button

A custom field that allows you to select a single value from a defined list of values.
You can address them by ‘value’ or by ‘id’.

```powershell
$fields = @{
    customfield_11445 = @{ "value" = "Text of the option" }
    # or:
    customfield_11445 = @{ "id" = 10112 } # id of the option
}
```

#### User Picker

A custom field that allows a single user to be selected.
The user is identifies by the username.

```powershell
$fields = @{
    customfield_11453 = @{ name = "tommytomtomahawk" }
}
```

#### Multi-User Picker

A custom field that allows multiple users to be selected.
The user is identifies by the username.

```powershell
$fields = @{
    customfield_11458 = @(
        @{ name = "inigomontoya" }
        @{ name = "tommytomtomahawk" }
    )
}
```

#### Cascading Picker

A custom field that allows you to select a multiple values from a defined list of values.
You can address them by 'value' or by 'id'.

```powershell
$fields = @{
    customfield_11447 = @{
        value = "parent_option1"
        child = @{
            value = "p1_child1"
        }
    }
    # or:
    customfield_11447 = @{
        id = 10112
        child = @{
            id = 10115
        }
    }
}
```

### Finding Allowed Values

Use `Get-JiraField` and look for the AllowedValues property. This will give you both an ID and a value for each "item" your field is allowed to be.

```powershell
(Get-JiraField "Urgency").AllowedValues
```

Then, use this syntax described above.

# EXAMPLES

The following extensive example contains several types of custom fields as input for a new Jira issue.

```powershell
$fields = @{
    project = "TV"
    issuetype = "bug"
    summary = "Important Issue"
    description = "This Issue is *very* important\n\n really!?"
    Assignee = "admin"
    Reporter = "admin"
    Priority = 1
    Fields = @{
        labels = @("important", "notreally")
        fixVersion = @(
            @{ name = "Release 1.1"}
        )
        customfield_10001 = @{ name = "item from a dropdown" }
        duedate = "2020-01-01"
    }
}

```

# NOTE

If you run into any additional fields that you'd like to see documented, feel free to let me know in a GitHub issue - or submit a PR to this page with the field!

# SEE ALSO

[Jira REST Api - Field input formats](https://developer.atlassian.com/server/jira/platform/rest-apis/#field-input-formats)

# KEYWORDS

- customfield
