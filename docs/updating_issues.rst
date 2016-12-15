===============
Updating Issues
===============

* :ref:`Editing Issues`
* :ref:`Adding Comments`
* :ref:`Issue Transitions`

.. _Editing Issues:

Editing Issues
==============

Editing issues is done with the Set-JiraIssue function.

.. code:: PowerShell

    # Assign an issue
    Set-JiraIssue TEST-1 -Assignee 'bob'

    # Get the issue's existing summary and add a tag
    $issue = Get-JiraIssue TEST-1
    $issue | Set-JiraIssue -Summary "$($issue.Summary) (Modified by PowerShell)"

If the field you want to change does not have a named parameter, Set-JiraIssue also supports changing arbitrary fields using the -Fields parameter. For more information on this parameter, see the :doc:`custom_fields` page.

.. _Adding Comments:

Adding Comments
===============

Add-JiraIssueComment is your friend here.

.. code:: PowerShell

    Add-JiraIssueComment -Issue TEST-1 -Comment "Test comment from PowerShell"

You can also use Format-Jira to convert a PowerShell object into a JIRA table.

.. code:: PowerShell

    $commentText = Get-Process powershell | Format-Jira
    Get-JiraIssue TEST-1 | Add-JiraIssueComment "Current PowerShell processes:\n$commentText"

.. note:: Like other Format-* commands, Format-Jira is a destructive operation for data in the pipeline. Remember to "filter left, format right!"

.. _Issue Transitions:

Issue Transitions
=================

Closing an issue, reopening an issue, or changing an issue to a pending state are all examples of what JIRA calls "issue transitions." The transitions an issue can perform depend on its current status and the JIRA workflow set up for its project.

First, check the transitions an issue can currently perform:

.. code:: PowerShell

    Get-JiraIssue TEST-1 | Select-Object -ExpandProperty Transition

Once you have a list of transitions, use Invoke-JiraIssueTransition with the ID of the transition to perform:

.. code:: PowerShell

    Get-JiraIssue TEST-1 | Invoke-JiraIssueTransition -Transition 11

.. note:: For more information on configuring transitions in JIRA, see Atlassian's article on `JIRA Workflows`_.

.. _JIRA Workflows: https://confluence.atlassian.com/adminjiraserver072/working-with-workflows-828787890.html