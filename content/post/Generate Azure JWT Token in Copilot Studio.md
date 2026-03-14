---
title: "Generate Azure JWT Token in Copilot Studio"
date: 2025-08-09
publishdate: 2025-08-09
tags: ["Azure", "AI"]
draft: false
---

Out of my role as a Lead Technical Trainer at Microsoft, the portfolio of trainings I'm covering has heavily shifted to Azure AI and Copilot over the last few months. Still doing Azure Architecture and Developing courses as well, but not as frequent anymore. This confirms the interest we see at customers in adopting Generative AI solutions. Apart from [Copilot in M365](https://www.microsoft.com/microsoft-365/copilot), or using [Azure AI Foundry](https://azure.microsoft.com/en-us/products/ai-foundry), I also started digging into [Copilot Studio](https://azure.microsoft.com/en-us/products/copilot-studio) a lot more. Having a good background in Azure LogicApps and a bit of PowerPlatform, Copilot Studio feels quite comfortable to me. 

I've been working on a few Agent scenarios in Copilot Studio, which I will blog more about in the near future. One of the newer features that got my attention, is the **advanced feature** of HTTP Requests, which opens the door to using **REST API calls** to other platforms, for example **Azure**. 

As you probably know, any action against Azure requires authentication, whether an interactive admin user logon, or a Service Principal application logon. Which means that - before I can trigger any actions against Azure, I first need to get the Copilot Studio Agent authenticating to Azure, using a JWT Bearer token (Azure Entra ID OAuth 2.0 Token). 

This article walks you through the different steps and setup of the Copilot Studio Agent, to allow it to authenticate to Azure, and from there taking a possible next step against the platform.

## What this article covers

âœ… How to create App Registration for Copilot Studio Agent in Entra ID
âœ… How to generate JWT Bearer token in Copilot Studio for API authentication
âœ… How to set up Microsoft Graph API authentication with Azure Entra ID OAuth 2.0 token


## Create Entra ID App Registration for Copilot Studio Agent

Any Service / Application level interaction with Azure, starts from an App Registration. This generates a Service Principal, think of it as a Service Account, which then gets linked/reused by a 3rd party application, as like in our case, Copilot Studio. 

Apart from creating the Service Principal entity object, it also needs corresponding API permissions to interact with Microsoft Graph. 

These are the steps to set all this up:

1. From Entra ID, navigate to **App Registration**, and select **New Registration**

![App Registration](../images/screenshot-2025-08-09-eea9c540.png)

2. Provide a name for the App Registration **e.g. Copilot Studio Agent Demo**, and leave all other default settings as-is. Click **Register**

![App Registration](../images/screenshot-2025-08-09-26cbbfbf.png)

3. This generates the Service Principal, with some specific IDs you need to copy aside. The Client ID, reflecting the unique GUID of the Service Principal as well as the Tenant ID which corresponds to your Entra ID Tenant GUID.

![Client Credentials](../images/screenshot-2025-08-09-3d5a737f.png)

4. Next, the Service Principal also needs the necessary credential to authenticate, which can be set up from the **Subscription or Resource Group Access Control IAM (RBAC)** permissions. For my example, I specify "Read" permissions on Subscription level, as I only want to run that as a validation of my workflow actually running successfully. You could alter to any permissions your scenario requires. 

![RBAC Permissions](../images/screenshot-2025-08-09-ed33ad68.png)

5. And to request an authentication JWT Token, we also need to pass the Client ID password, which can be generated from the Entra ID App Registration page for the newly created App Registration. Copy this secret aside, as you will need it in a later step.

![App Registration Client Secret](../images/screenshot-2025-08-09-2563fe19.png)

6. With all this out of the way, we have all ID information, credentials and RBAC permissions to bring into Copilot Studio. But there are a few other pieces of information we are gathering first, the **Authentication API Endpoint**, which is the Microsoft Login URL for our Tenant. this should look like this:

```
https://login.microsoftonline.com/<yourtenantID>/oauth2/v.2.0/token
```

and we also need a REST API Header and Body, which are the additional parameters Copilot Studio Agent REST API action requires:

```
- Header: Content-Type: application/x-www-form-urlencoded
- Body: client-id=<yourclientid>&client_secret=<clientsecret>&grant_type=client_credentials&scope=https://graph.microsoft.com/.default
```

where you insert the actual value of the clientid and clientsecret you copied earlier for the placeholders.

## Configure the HTTP Request Action in Copilot Studio

1. Navigate to [Copilot Studio](https://copilotstudio.microsoft.com) and open the workflow setup of your Agent.

2. Navigate to **Topics** and **Add a new topic**. Select "From Blank"

![New Copilot Studio Agent](../images/screenshot-2025-08-09-e3c7cb65.png)

3. Click the **+ Sign** below the Trigger step, and select **Advanced / HTTP Request** from the option menu.

![HTTP Request](../images/screenshot-2025-08-09-66d30fbe.png)

4. Complete the following fields of the HTTP Request per below overview:

- **URL**: the login-URL specified earlier: https://login.microsoftonline.com/<tenantID>/oauth2/v.2.0/token, where the <tenantid> placeholder gets replaced with the actual GUID of your tenant, something like this (redacted)

![HTTP Request URL](../images/screenshot-2025-08-09-919da3b8.png)

https://login.microsoftonline.com/1c5e3b03-f225-4622-b785-abcdefghi/oauth2/token

- **Method**: POST

- **Headers and Body**: 
    - *Headers / Key*: Content-Type
    - *Headers / Value*: application/x-www-form-urlencoded
    - *Body*: Raw Content
    - *Content Type*: application/x-www-form-urlencoded
    - *Content*: client-id=c92c3f9f-7ba3-4e5b-1234-abcdefghi&client_secret=nzE8Q~q-tDIrvlLkBGe2IwWH.abcdefghij_&grant_type=client_credentials&scope=https://graph.microsoft.com/.default
    - *Response headers*: Create new **Global** variable to store the value in, e.g. HTTPResponseVar
    - *Response data type*: Record + select Edit Schema, and add the following schema structure:
        ```
        kind: Record
        properties: 
            access_token: String
            expires_in: Number
            token_type: String
        ```
    - *Save Response as*: select the Global.HTTPResponseVar again

5. **Save** the changes. 

![HTTP Request Headers](../images/screenshot-2025-08-09-0114f195.png)
Request Header details

![HTTP Request Body Content](../images/screenshot-2025-08-09-255a4fbb.png)
Request Body details

![Global Variable details](../images/screenshot-2025-08-09-beda8599.png)
Global Variable details

![Record Schema details](../images/screenshot-2025-08-09-d9e11cea.png)
Record Schema details

6. While this flow should work fine now, you won't get any output from it. We need to update the flow with a follow-up message, in which we read/present the output from the HTTPResponseVar variable. **Click** the **+** sign below the HTTP Request step in the workflow, and select **Send a Message** from the context menu.

7. Enter an informative text, e.g. "Here is the Azure Token String", and add the HTTPResponseVar variable into the text box, by selecting the *insert variable {X}* option and selecting the variable from the list. 

![Response Message](../images/screenshot-2025-08-09-4bb46368.png)

8. **Save** the changes. Next, from the **Test your Agent** pane, trigger the Agent flow by sending a short chat message, like "get my token". This should result in the chat response, showing your message "Here is the Azure Token String", and the actual JWT token with all necessary information in it. 

![Response JWT Token](../images/screenshot-2025-08-09-591adf22.png)

9. Cool, this works as expected! While we're close, we're not 100% done yet, as the value of this variable is not immediately reusable as an authentication token, as not all information in the response is part of the actually authentication token (e.g. String{"access_token"}, "expires_in", "token_type"). We can fix this by running a **concatenate** formula, and splitting the received information in a new variable which only stores the actual Token information we need to authenticate. After the last message step in the flow, **click the + sign** again, and once more, select *Send a Message*. Provide a new informative message, something like "And this is the cleaned up version of the Bearer token, just what you need...", and add a new **PowerFx Expression** by clicking the **{fX}** button. Enter the following formula:

    ```
    Concatenate(Topic.HTTPResponseVar.token_type," ",Topic.HTTPResponseVar.access_token)
    ```

![Concat Response JWT Token](../images/screenshot-2025-08-09-7792f764.png)

10. Which would transform the response into a valid Bearer token text string "Bearer ey..." which you can use for any Azure HTTP REST API in a different Topic. To do that, it's best to save the concat result in a new Global Variable.  

## Reuse the JWT Authenticator Topic in Copilot Studio Agent

While I want to keep this article on the actual JWT Token authentication process, I wanted to add a little teaser for a follow-up article, in which I create a Copilot Studio Agent to interact with Azure, relying on the Bearer Token from this Topic we just created. In any Copilot Studio flow you have, you can now refer to the Auth2Azure Authentication request Topic like this:

![Reuse Bearer Token Topic](../images/screenshot-2025-08-09-624f9a1b.png)

## Summary

In this article, I wanted to document the necessary steps on how to use the Copilot Studio Agent - HTTP Request task, to get a Bearer Token to authenticate to Azure (or any similar HTTP REST API for that matter). 



[![BuyMeACoffee](../images/screenshot-2025-08-09-17f576e7.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
