==============
Authentication
==============

At present, there are two main methods of authenticating to JIRA: HTTP basic authentication, and session-based authentication, which uses HTTP basic authentication once and preserves a session cookie.

.. warning:: Be sure to set JIRA up to use HTTPS with a valid SSL certificate if you are concerned about security!

HTTP Basic
==========

Each JiraPS function that queries a JIRA instance provides a -Credential parameter. Simply pass your JIRA credentials to this parameter.

.. code-block:: powershell

    $cred = Get-Credential 'powershell'
    Get-JiraIssue TEST-01 -Credential $cred

HTTP basic authentication is not a secure form of authentication. It uses a Base 64-encoded String of the format "username:password", and passes this string in clear text to JIRA. Because decrypting this string and obtaining the username and password is trivial, the use of HTTPS is critical in any system that needs to remain secure.

.. note:: For more information on HTTP Basic authentication, see `Basic Access Authentication`_ on Wikipedia.

Sessions
========

JIRA sessions still require HTTP basic authentication once, to create the connection, but in this case a persistent session cookie is saved. This is almost identical to "logging in" to JIRA in a Web browser.

To create a JIRA session, you can use the New-JiraSession function:

.. code-block:: powershell

    $cred = Get-Credential 'powershell'
    New-JiraSession -Credential $cred

Once you've created this session, you're done! You don't need to specify it when running other commands - JiraPS will manage this session internally and provide the session cookie to JIRA when needed. This also means your credentials are only sent over the network once.

To close this session, use this command:

.. code-block:: powershell

    Get-JiraSession | Remove-JiraSession

This will close the active "logged in" session with JIRA.

.. note:: It is a good practice to close JIRA sessions when you're done using them. JIRA will eventually time these sessions out, but there is a limit to how many sessions can be open at a given time.

What About OAuth?
=================

JIRA does support use of OAuth, but JiraPS does not yet. This is a to-do item!

.. _Basic Access Authentication: https://en.wikipedia.org/wiki/Basic_access_authentication
