---
title: "You do not have permissions to view this directory or page after publishing to Azure App Service"
date: 2023-04-30
publishdate: 2023-04-30
tags: ["Azure", "App Service", "Azure DevOps"]
draft: false
---

Earlier this week, I got an interesting phenomenon when publishing a code update to an existing Azure App Service. As this was a small project, I've always been deploying updates in a manual way from **right-click / publish** in Visual Studio. But than I said to myself, Peter, as a passionate DevOps engineer and trainer, just go out and create a pipeline for this.

And that's what happened.

Running the release pipeline came back successful, but the site threw an error:

![App Service Error](../images/2023-04-30_11-25-45.png)

I was like well, OK, no worries, let's go back to the **manual deployment** from Visual Studio for now. Only to find out that one didn't succeed either anymore, just giving me a **spinning** publishing task. 

![Publish task hang](../images/2023-04-30_11-30-12.png)

So this was not really helping me further. Time to open up the **App Service Logs** settings on the App Service to dig in. 

![App Service Logs](../images/2023-04-30_11-32-06.png)

After which I could check the live logs using **App Service Log Stream** (notice the **verbose** option to get immediate and full feedback...)

![Verbose Logs](../images/2023-04-30_11-33-49.png)

2 things here got my attention: 
* HTTP Error 403.13 Forbidden
* A default document is not configured for the requested URL

So it seems like the index.html I use in my app, couldn't be found on the Web Server. Let's validate with **App Service Editor**

![Verbose Logs](../images/2023-04-30_11-37-59.png)

Interesting... so I have my drop folder with the application zip package and some other deployment artifacts, but not the actual application files in an extracted format. The **drop** folder was also something that made me curious... As that is what Azure DevOps is using to publish the package... Let's go back to my Azure DevOps Release pipeline and check something...

![App Service Release settings](../images/2023-04-30_11-41-07.png)

EUREKA!!! Looks like Peter made a mistake here, by not setting the **package file** to use. So what the ADO Pipeline does here, is just copying the /drop folder with the artifact into the Azure App Service, but not extracting it.

This is what this setting should look like:

![Select ZIP package](../images/2023-04-30_11-43-46.png)

![Zip Package Selected](../images/2023-04-30_11-44-43.png)

With these new changes, let's run the release deployment again and see what happens...

![Actual files got deployed](../images/2023-04-30_12-21-49.png)

and the website is running as expected! 

Last check, validating if a new deployment from Visual Studio is running as expected again... and that runs successful again too!

## Summary
In this post, I wanted to help you sharing some troubleshooting steps for Azure App Services. And also admitting I made a minor mistake in my ADO pipeline setup. So additional lesson learned: always doublecheck your setting when something doesn't work anymore as it should be :)

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter