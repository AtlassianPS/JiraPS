.. PSJira documentation master file, created by
   sphinx-quickstart on Tue Dec 13 19:31:32 2016.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

======
PSJira
======

.. image:: https://ci.appveyor.com/api/projects/status/rog7nhvpfu58xrxu?svg=true
   :target: https://ci.appveyor.com/project/JoshuaT/psjira
   :alt: Appveyor build status

.. image:: https://readthedocs.org/projects/psjira/badge/?version=latest
    :target: http://psjira.readthedocs.io/en/latest/?badge=latest
    :alt: Documentation Status


PSJira is a Windows PowerShell module to interact with Atlassian JIRA via a REST API, while maintaining a consistent PowerShell look and feel.

.. note:: This documentation is a work in progress - but there's enough here already that I wanted to go ahead and publish it as I continue fleshing it out. Please feel free to submit PR's or issues on this documentation over on the `GitHub Issues`_ page!

.. toctree::
    :maxdepth: 2
    :caption: Introduction

    getting_started
    authentication

.. toctree::
    :maxdepth: 2
    :caption: Working with issues

    viewing_issues
    creating_issues
    updating_issues
    custom_fields

.. toctree::
   :maxdepth: 1
   :caption: About PSJira

   contributing
   changelog

New to the project? Check out the :doc:`getting_started` page for a quick guide to get you up and running!

.. _`GitHub Issues`: https://github.com/replicaJunction/PSJira/issues