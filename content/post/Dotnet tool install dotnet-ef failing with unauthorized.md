---
title: "Dotnet tool install dotnet-ef failing with unauthorized" 
date: 2020-12-27
tags: ["DotNet", ".NET Development"]
draft: false
---

Hi all, 

I hope you all have great holidays this time around, giving you the opportunity to spend time with your family as well as having the opportunity to learn some new skills, which in my case means learning **[Blazor](https://docs.microsoft.com/en-us/aspnet/core/blazor/?view=aspnetcore-5.0)**, a Framework within the DotNet family, allowing for "any-client" applications (browser, mobile device).

My learning journey involves building a front-end Web App, connecting to a SQL (Azure) database back-end. To make this work, I want to use the **[SQL Server Entity Framework](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/ef/overview)**.  


## What happened?

Besides installing the necessary Nuget Packages within my application, I also need to install the dotnet-ef Entity Framework Tools, initiating the following command:

```
dotnet tool install --global dotnet-ef
```
which was throwing an error

 ![Dotnet tool install error](../images/2020-12-27_1.jpg)

## What to check?
Based on the error message and description, there were a few things to validate:
- Using Preview release features; *not valid in my case* since I'm not using preview release.
- Unauthorized access to the Nuget Feed; *not valid in my case*, since I am not using any Package Feed integration; all Nuget packages can be downloaded directly from Nuget.org
- Mistyped the name of the tool; *well, no, it was correct*

I know I was using **DotNet 5.0.1** for my Blazor project, and I know I have the correct SDK and Framework installed on my machine. Let's validate by running

```
dotnet --version
```

 ![Dotnet version](../images/2020-12-27_2.jpg)

 I also installed the different EntityFramework Packages I need (FrameworkCore, Design, SQLServer,...), and those are also version 5.0.1

![Package version](../images/2020-12-27_3.jpg)


## How to fix this error?
This explicit versioning led me to the solution; **what if I specify that version for the tool**, as somehow recommended as a first thing to check (although that was referring to preview, but hey, let's give it a try...)

```
dotnet tool install --global dotnet-ef --version 5.0.1
```
![dotnet install version](../images/2020-12-27_4.jpg)

following by running 

```
dotnet ef
```
which loaded fine this time! Problem solved!

![dotnet ef](../images/2020-12-27_5.jpg)

I guess the root cause of the issue is related to my "mixed" setup, where I still have the dotnetcore 3.1 on my machine as well, probably confusing the dotnet environment. By explicitly referring to the version you want to use, you can avoid seeing weird error messages.

thanks, Peter

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

