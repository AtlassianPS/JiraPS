$Params2 = {
    key= "EX",
    name= "Example",
    projectTypeKey= "business",
    projectTemplateKey= "com.atlassian.jira-core-project-templates:jira-core-project-management",
    description= "Example Project description",
    lead= "Michael.dejulia",
    assigneeType= "ProjectLead",
    avatarId= 10011,
    issueSecurityScheme= 10000,
    permissionScheme= 10000,
    notificationScheme= 10000,
    categoryId= 10000
}

Set-JiraProject @Params2
