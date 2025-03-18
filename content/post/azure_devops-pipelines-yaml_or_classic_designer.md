---
title: "Azure DevOps Pipelines - YAML or Classic Designer"
date: 2020-06-21
tags: ["Azure", "Azure DevOps"]
draft: false
---

During several of my [AZ-400 Designing and Implementing Microsoft DevOps Solutions](https://docs.microsoft.com/en-us/learn/certifications/exams/az-400) training deliveries, one recurring point of conversation is **Should we use YAML or the Classic Designer** for our Release pipelines?

So I thought sharing my view in another blog post could be helpful. 

Before answering the question more accurately, let's go over each scenario a bit more in detail:

# Classic Designer
Classic Designer has been the long-standing approach on how Azure DevOps Pipelines have been created. Using a user-friendly graphical User Interface, one can add tasks to create a pipeline just by searching for them from a list of tasks, and complete necessary parameters.

Below example is what I use for building Docker Containers:

![Build Pipeline Classic Designer](../images/2020-06-21_1.jpg)

As you can see, this looks quite straight forward to anyone, even if you are totally new to Azure DevOps.

If I want to update my pipeline with another task, for example **Docker CLI Installer**, I just click on **add task** and search for all **"Docker"** related tasks from the list, 

![Docker Task Classic Designer](../images/2020-06-21_2.jpg)

and select the related task I want:

![Docker Install Task Classic Designer](../images/2020-06-21_3.jpg)

Once you are familiar with the **actual steps** on how to build and compile containers from a command line, moving the manual steps to an Azure Pipeline are **almost 100% the same**. In the end, you are literally automating your manual approach. 

# YAML
Now, let's take a look at the YAML (Yet Another MarkUp Language) approach. There is no graphical designer here, but rather a **text config file** you need to build up, describing the different steps you want to run as part of your Azure Release Pipeline. 

YAML got introduced into Azure DevOps mid 2018 already, but I still see a lot of customers not using it that often yet.

Using a similar example as before, the YAML file looks like this:

```
pool:
  name: Azure Pipelines
steps:
- task: qetza.replacetokens.replacetokens-task.replacetokens@3
  displayName: 'Replace tokens in appsettings.json'
  inputs:
    rootDirectory: '$(build.sourcesdirectory)/src/MyHealth.Web'
    targetFiles: appsettings.json
    escapeType: none
    tokenPrefix: '__'
    tokenSuffix: '__'

- task: qetza.replacetokens.replacetokens-task.replacetokens@3
  displayName: 'Replace tokens in mhc-aks.yaml'
  inputs:
    targetFiles: 'mhc-aks.yaml'
    escapeType: none
    tokenPrefix: '__'
    tokenSuffix: '__'

- task: DockerInstaller@0
  displayName: 'Install Docker 17.09.0-ce'

- task: DockerCompose@0
  displayName: 'Run services'
  inputs:
    dockerComposeFile: 'docker-compose.ci.build.yml'
    action: 'Run services'
    detached: false

- task: DockerCompose@0
  displayName: 'Build services'
  inputs:
    dockerComposeFile: 'docker-compose.yml'
    dockerComposeFileArgs: 'DOCKER_BUILD_SOURCE='
    action: 'Build services'
    additionalImageTags: '$(Build.BuildId)'

- task: DockerCompose@0
  displayName: 'Push services'
  inputs:
    dockerComposeFile: 'docker-compose.yml'
    dockerComposeFileArgs: 'DOCKER_BUILD_SOURCE='
    action: 'Push services'
    additionalImageTags: '$(Build.BuildId)'

- task: DockerCompose@0
  displayName: 'Lock services'
  inputs:
    dockerComposeFile: 'docker-compose.yml'
    dockerComposeFileArgs: 'DOCKER_BUILD_SOURCE='
    action: 'Lock services'

- task: CopyFiles@2
  displayName: 'Copy Files'
  inputs:
    Contents: |
     **/mhc-aks.yaml
     **/*.dacpac
     
    TargetFolder: '$(Build.ArtifactStagingDirectory)'

- task: PublishBuildArtifacts@1
  displayName: 'Publish Artifact'
  inputs:
    ArtifactName: deploy

```

That's rather different, isn't? 

Each individual **task** I just had to select before, now requires a **set of instructions** in a config file. Luckily, Azure DevOps still provides a graphical interface to pick the tasks, which could be helpful in the beginning, when YAML is too new to you.

Good news is, from a Build Pipeline perspective, both methods provide the same result. So the key question is, which one to go for? 

# Classic Designer or YAML
After discussing on this topic with several students during my deliveries, I came up with a **good and bad** list for each. Know this is far from complete, not trying to push you in a certain direction at all, but merely providing an overview. 

## Advantages of Classic Editor
- Ease of Use
- Clear overview of what tasks the pipelines is based on
- Lots of preconfigured task snippets available
- No "development" language to learn

## Disadvantages of Classic Editor
- Less obvious Source Control/Version Control
- Specific to Azure DevOps
- Slow to create or update your pipelines
- Microsoft-native 
- While not immediately, it will phase out at some point

## Advantages of YAML
- 100% code-based, which means you can manage it like your application source code in source/version control
- Easy to make changes (once you know how the language works)
- Easier to compare changes (e.g. Azure Repos "file compare feature")
- Code snippets can be shared easily with colleagues, much easier than screenshots
- Same YAML concept is used by Docker, Kubernetes,... and several other "configuration as code" tools
- **View YAML** option in Classic Editor to see the snippet of GUI task translated to YAML

## Disadvantages of YAML
- Scary at first, especially if you are not a developer
- Harder to learn the "language", when you are used to using the Graphical UI

# Summary
Again, this list is probably far from complete, and mostly depends on your personal preferences. For me, I still see myself going often to the Classic Editor rather than using YAML, but I also try to change my behavior :). Knowing YAML is somehow becoming a standard in other tools and platforms (think of Docker, Kubernetes,...), it makes total sense to also adopt this into Azure DevOps. Next, there is a tendency to move to a **anything as code** (Infrastructure as Code, Configuration as Code, now **Pipelines as Code**,...) which allows for easier creation, change, version control and collaboration across teams. And isn't that the ultimate idea about DevOps after all?

Ping me on [Twitter](http://www.twitter.com/pdtit) or send me an [Email](mailto:peter@pdtit.be) if you want to share your feedback on this.

Stay safe and healthy you all! 

/Peter