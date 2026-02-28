---
title: "publish your first dotnet5 app to Azure App Services"
date: 2020-11-10
tags: ["Azure", ".NET Development"]
draft: false
---

Today, Nov 10th, was the official date of the long-announced ["dotnet5 Framework"](https://dotnet.microsoft.com/download/dotnet/5.0), and it is described as a major release. Still being new in the developer world myself, I know the basics of ASP.NET 3.7 and 4.5, so I can imagine jumping to a 5.0 release is indeed a big thing. 

## .NET 5.0 improvements

The biggest improvements announced by the Product Team are:

- Migration-friendly for older .NET versions
- Production-ready from day 1 of release (thorough-tested for http://www.dot.net and http://www.bing.com websites)
- Enhanced performance 
- ClickOnce client app publishing
- Smaller container image footprint
- Supportability for Windows Arm64 and WebAssembly (Blazor)

Support will go into Feb 2022, which seems the release date for DotNet 6.0 LTS

Another big deal is the **Unification** of the DotNet platform; what this means is that the .NET standard and characteristics will be available across different scenarios (mobile apps, web apps, webassembly, desktop apps, IOT,...) relying on the same set of APIs, tools and languages. While not all has been integrated and unified yet, it's still on the roadmap to become fully unified by version 6.0 in about 18 months from now.

More details about the dotnet 5.0 release can be read in the ["announcement blog:"](https://devblogs.microsoft.com/dotnet/announcing-net-5-0/?utm_source=dotnet-website&utm_medium=banner&utm_campaign=blog-banner)

## Developer Environment dependencies

### Visual Studio 2019

In order to use the .NET 5.0 Framework, an update of **Visual Studio 2019** is required. More specifically, it needs to be version **16.8.0**; if all is set as default in your IDE, you should get this prompt to upgrade automatically; if this has been disabled, you could launch the upgrade yourself by starting the Visual Studio Installer from within the Visual Studio menu option **Tools / Get Tools and Features...** 

![Visual Studio Installer](../images/2020-11-10_01.png)

### Visual Studio for MAC

Updating to the ["latest version"](https://visualstudio.microsoft.com/vs/mac/) of Visual Studio for MAC should bring in support for .NET 5.0; 

### Visual Studio Code

Integration of .NET 5.0 into VIsual Studio Code is managed out of the ["C# Extension"](https://code.visualstudio.com/docs/languages/dotnet), so if you update this one to the latest version, you are good to go too.

## Creating your first .NET 5.0 Project in Visual Studio

Now the prerequirements have been covered, let's give it a try and build a new ASP.NET Web Application:

1. From the Visual Studio 2019 menu, select **File / New / Project...**

2. From the list of templates, select **"ASP.NET Core Web Application"**

![ASP.NET Web App Template](../images/2020-11-10_02.png)

3. **Press Create**; in the next step, from the top, select **.NET Core** and **ASP.NET Core 5.0** 

![ASP.NET Web App Template](../images/2020-11-10_03.png)

4. Choose **ASP.NET Core Web App** as template + confirm by pressing the **Create** button. Wait for the project to load.

5. From **Solution Explorer**, select the Project you just created (the bold title), and open its **Properties**; this will also confirm the **.NET 5.0** Framework

![ASP.NET Web App Template](../images/2020-11-10_04.png)

## Publishing your Web App to Azure App Services

Developing an app is one thing, but what's giving more joy than seeing it running in Azure? Here we go:

(Assumptions: you have an active Azure subscription, and the necessary RBAC permissions to create and deploy App Services...)

1. From Solution Explorer / select your Project (the bold title), **right click** to open the context menu, and select **publish**

![ASP.NET Web App Template](../images/2020-11-10_05.png)

2. From the **Publish** wizard Target step, select **Azure**; click Next 

![ASP.NET Web App Template](../images/2020-11-10_06.png)

3. From the wizard's Specific Target step, select **Azure App Service (Linux)**; click Next

![ASP.NET Web App Template](../images/2020-11-10_07.png)

4. From the wizard's App Service step, Click the **+** sign to **create a new **Azure App Service** 

![ASP.NET Web App Template](../images/2020-11-10_08.png)

    - provide a **unique** name for the webapp, using lowercase characters
    - specify a new for a **new Resource Group**
    - specify a new **App Service Plan** for example S1 - 1.75Gb Memory

![ASP.NET Web App Template](../images/2020-11-10_09.png)

5. Validate all the settings, and confirm by pressing **Finish**

![ASP.NET Web App Template](../images/2020-11-10_10.png)

6. From the summary page, press **Publish**; This starts the publishing process. 

![ASP.NET Web App Template](../images/2020-11-10_11.png)

7. Wait for it to complete successfully. The process can be viewed from the **Output window**

![ASP.NET Web App Template](../images/2020-11-10_12.png)

8. After waiting another few seconds, your **default browser** opens the Web App URL, and shows the web app running

9. Let's validate the App Service Configuration settings from within the Azure Portal:

- Log on to https://portal.azure.com using your Azure Admin Credentials
- Browse to App Services
- Notice the App Service you just created
- Browse to this App Service's **Configuration** (under Settings)

![ASP.NET Web App Template](../images/2020-11-10_13.png)

10. Notice the correct **.NET 5.0** version

## Summary

In this article, you got introduced to the new .NET 5.0 Framework. I walked you through the Project setup in VIsual Studio 2019 for an ASP.NET Core 5.0 based web application, followed by publishing this to a new Azure App Service resource.

As always, I hope you learned from this article; ping me whenever you got any (Azure) questions.

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Take care, Peter