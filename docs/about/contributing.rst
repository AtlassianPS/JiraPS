======================
Contributing to PSJira
======================

Pester
======

Pester is a unit testing framework for PowerShell that helps make sure changing some functions doesn't break others.

**Pull requests for PSJira are required to pass all Pester tests before they will be merged.**

Tests are code, just like the module itself, so it's entirely possible that they need to be fixed or updated when the module changes. Correcting tests is a healthy part of developing a tool, so when there are legitimate changes needed in tests, they can be submitted via pull requests as well.

However, code that does not pass Pester tests will not be accepted. This either indicates that there is a problem with the new code in the pull request, or the code requires a change to an existing test that hasn't been made.

Pre-Push Hooks
--------------

By setting up a pre-push hook, you can make sure that all Pester tests pass before you push your changes back to GitHub. This is not necessary to contribute, but it can save some frustration all around.

In your PSJira workspace, create a file at .git/hooks/pre-push (with no file extension)

Edit this file in a text editor and add this content:

.. code:: bash

    #!/bin/sh
    echo
    #powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Invoking Pester' -Fore DarkYellow; Invoke-Pester -EnableExit;"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Tools\Pre-Push.ps1"
    exit $?

This won't prevent you from committing with breaking changes, but it will prevent you from pushing changes while there are failing tests.