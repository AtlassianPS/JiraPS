==============
Viewing Issues
==============

Get-JiraIssue is the primary tool for getting information about existing issues in JIRA - whether you're looking for a single issue or all issues matching a certain criteria.

* :ref:`Get Issue`
* :ref:`Search Issues`

.. _Get Issue:

Getting a Specific Issue
========================

If you know exactly what issue you're looking for, there are two ways to return information about it using Get-JiraIssue.

Issue Key
---------

The simplest way to get info about an issue is using the issue's key. This is quite straightforward:

.. code:: PowerShell

    Get-JiraIssue -Key 'TEST-1'

Issue ID
--------

JIRA issues also contain an internal ID number. This ID is not exposed in the Web interface, but you can also use it to reference an issue.

.. code:: PowerShell

    Get-JiraIssue 10016

You probably won't use this method very much, but it's available.

.. _Search Issues:

Searching For Issues
====================

To search for an issue in JIRA, you'll need to dip into `JIRA Query Language`_ a little bit. JQL is a structured query language used to search for issues in JIRA that match a given criteria, but it uses a very different syntax from SQL.

One of the easiest ways to build a JQL query is to use the search functions in JIRA's Web interface, then click the "Advanced" button to switch your search query from interactive buttons to a long string. This will show you the raw JQL for your current search, which can be copied and pasted directly into the -Query parameter here.

.. code:: PowerShell

    # Issues created in the last week
    Get-JiraIssue -Query "created >= -7d"

    # Issues created by replicaJunction in the last week
    Get-JiraIssue -Query "created >= -7d AND reporter in (replicaJunction)"

For more information on using JQL, see Atlassian's article on `JIRA Query Language`_.

Paging Through a Search
-----------------------

By default, when you use JQL to pull data from JIRA, it will return all issues that match the given criteria. If you use a query that returns a large number of issues (for example, "all issues created after January 1, 2000"), this can take quite some time.

You can use the -StartIndex and -MaxResults parameters to "page" through all search results in smaller chunks.

.. code:: PowerShell

    # This is a pretty generic query that will probably return a lot of issues.
    $query = 'created >= 2000-01-01'

    #  Return the first 50 search results...
    Get-JiraIssue -Query $query -MaxResults 50

    # ...and the next 25 after that.
    Get-JiraIssue -Query $query -MaxResults 25 -StartIndex 50

.. _JIRA Query Language: https://confluence.atlassian.com/jiracoreserver072/advanced-searching-829092661.html