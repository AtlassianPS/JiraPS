===================
Working With Fields
===================

Many of PSJira's functions contain convenience parameters for issue fields that are commonly used. These parameters take care of translating PowerShell to the correct JSON format when working with JIRA'S API.

However, not every standard JIRA field is implemented via a parameter, and most JIRA instances also contain custom fields to allow your organization to tailor its JIRA instance to your own requirements. To allow PSJira to work with fields that do not have named parameters, these functions support a generic -Fields parameter.

Using -Fields
=============

Basically, -Fields uses a hashtable that looks something like this:

.. code-block:: PowerShell

    $fields = @{
        fieldName = @{
            value = 'New Value'
        }
        fieldID = @{
            id = 'ID of new value or item'
        }
    }

    Set-JiraIssue -Fields $fields

This isn't a super easy syntax - and the module authors are always open to ideas for ways to improve this.

One of the best ways you can get information about the type of data to pass is using the Get-JiraField function. This can tell you a lot about what to pass in the Fields hashtable.

Specific Fields
===============

Here are some notes on specific fields that have come up in the past.

Components
----------

JIRA expects the Components field to be an array, even if you're only defining one component. Use this syntax:

.. code-block:: PowerShell

    $fields = @{
        # Note that this is an array!
        components = @(
            @{
                name = 'Component 1'
            },
            @{
                name = 'Component 2'
            }
        )
    }

Here's a shorthand version when only using one component:

.. code-block:: PowerShell

    $fields = @{
        components = @(@{
                name = 'Component 1'
        })
    }

Custom Fields
=============

Here are some more general notes about types of custom fields you may run into.

Fields with allowed values
--------------------------

(Also known as multiselect or drop-down fields.)

Use Get-JiraField and look for the AllowedValues property. This will give you both an ID and a value for each "item" your field is allowed to be.

Then, use this syntax:

.. code-block:: PowerShell

    $fields = @{
        'customfield_10001' = @{
            id = '10029'
        }
        # Or reference the value instead
        'customfield_10002' = @{
            value = 'Value 1'
        }
    }

If you run into any additional fields that you'd like to see documented, feel free to let me know in a GitHub issue - or submit a PR to this page with the field!