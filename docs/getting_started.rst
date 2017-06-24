===============
Getting Started
===============

Prerequisites
-------------

There are only two pre-requisites for JiraPS:

1. A working JIRA environment
2. PowerShell 3.0 or greater

You do *not* need to be a JIRA administrator to use JiraPS, though of course you won't be able to perform admin-only tasks if you don't have those permissions.

Installing
----------

If you have PowerShell 5.0 (or the PackageManagement module), you can install JiraPS easily with a single line.

.. code-block:: powershell

    Install-Module JiraPS

If you don't have PowerShell 5, consider updating! It's pretty quick and easy, and there are a fair amount of new features.

If updating isn't an option, consider installing PackageManagement on PowerShell 3 or 4 (you can do so from the `PowerShell gallery`_ using the "Get PowerShellGet for PS 3 & 4" button).

First-Time Setup
----------------

Before using JiraPS, you'll need to define the URL of the JIRA server you'll be using. You can do this with just one line of PowerShell:

.. code-block:: powershell

    Set-JiraConfigServer -Server 'https://my.jira.server.com:8080'

That's it! You should only need to do that once (it saves a config.xml file to the same location where the JiraPS module is saved).

.. note:: If you installed JiraPS to Program Files, you may need to run the above command in an elevated PowerShell session. Otherwise, you might get an Access Denied error.

.. _PowerShell gallery: http://www.powershellgallery.com/
