======================
Contributing to PSJira
======================

There are two main areas where PSJira needs your help: in the module code itself, and in this documentation.

* :ref:`PSJira core`
* :ref:`Documentation`

.. _PSJira core:

Module Code
===========

The code for PSJira relies extensively on Pester tests as a sanity check. Pester tests make sure that when a function gets changed, other functions that depend on it don't break due to the change.

**Pull requests for PSJira are expected to pass all Pester tests before they will be merged.**

This is not intended to keep people from contributing to PSJira...just to ensure that new features and changes don't break existing ones. If you have ideas for improvements but aren't comfortable with Pester, please feel free to submit a pull request. I (or other authors) would be glad to work with you to figure out what's failing and make the necessary changes (whether in your code or in the test code).

Tests are code, just like the module itself, so it's entirely possible that they need to be fixed or updated when the module changes. Correcting tests is a healthy part of developing a tool, so changes to tests are welcome as well.

When code does not pass all the tests, it either indicates that there is a problem with the new code in the pull request, or the code requires a change to an existing test that hasn't been made.

Automated Testing via Pre-Push Hooks
------------------------------------

By setting up a pre-push hook in your local Git repository, you can make sure that all Pester tests pass before you push your changes back to GitHub. This is not necessary to contribute, but it can save some frustration all around.

In your PSJira workspace, create a file at .git/hooks/pre-push (with no file extension)

Edit this file in a text editor and add this content:

.. code:: bash

    #!/bin/sh
    echo
    #powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Invoking Pester' -Fore DarkYellow; Invoke-Pester -EnableExit;"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Tools\Pre-Push.ps1"
    exit $?

This won't prevent you from committing with breaking changes, but it will prevent you from pushing changes while there are failing tests.

.. _Documentation:

Documentation
=============

Unlike the main module code, there is very little to be tested in this documentation (the big thing that gets tested is the changelog, to make sure it's kept up-to-date with releases).

This documentation is found in the /docs/ folder of the main PSJira repo, and is written in `ReStructured Text`_. This format was chosen mostly due to a deeper integration with ReadTheDocs than Markdown provided on its own, but the Sphinx build engine that processes the RST is quite powerful and supports a lot of interesting features.

RST isn't difficult - a lot of the information in here is just written in plain text, and the parts that aren't provide examples of how to use it - but if you'd like to read more on how to write in RST, I'd recommend the `Sphinx guide`_ on RST, since that engine is responsible for building this documentation.

One particular place where I'd love some help with these docs is the :doc:`custom_fields` page. I'd like to add as many examples of the -Fields parameter as possible to this page, so that in the future, users can find working examples for specific fields and field types.

.. _ReStructured Text: http://docutils.sourceforge.net/rst.html
.. _Sphinx guide: http://www.sphinx-doc.org/en/1.4.9/rest.html