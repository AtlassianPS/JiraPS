<!-- markdownlint-disable MD002 -->
<!-- markdownlint-disable MD041 -->
<!-- Provide a general summary of your changes in the Title above -->

### Description

<!-- Describe your changes in detail -->

### Motivation and Context

<!-- Why is this change required? What problem does it solve? -->
<!-- If it fixes an open issue, please link to the issue here as follows: -->
<!-- closes #1, closes #2, ... -->

### Types of changes

<!-- What types of changes does your code introduce? Put an `x` in all the boxes that apply: -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)

### Checklist

<!-- Go over all the following points, and put an `x` in all the boxes that apply. -->
<!-- If you're unsure about any of these, don't hesitate to ask. We're here to help! -->

- [ ] My code follows the code style of this project.
- [ ] I have added Pester Tests that describe what my changes should do.
- [ ] I have updated the documentation accordingly.

### Cloud / Data Center Compatibility

<!-- JiraPS targets both Jira Cloud and Data Center. If your change touches API endpoints, -->
<!-- request bodies, or response handling, verify it works for both deployment types. -->

- [ ] This change does **not** affect API endpoints or REST calls (skip items below)
- [ ] Works on Jira **Cloud** (accountId for users, ADF for text fields, v3 endpoints)
- [ ] Works on Jira **Data Center** (username/name for users, plain text fields, v2 endpoints)
- [ ] User identity uses `accountId` for Cloud and `username`/`name` for DC
- [ ] Text fields (description, comment) handle both ADF (Cloud) and plain text (DC)
- [ ] Tests cover both Cloud and DC response shapes where applicable
