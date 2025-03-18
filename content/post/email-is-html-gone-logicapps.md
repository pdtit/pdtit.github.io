---
title: "is HTML parameter gone from Logic Apps Send Email Connector"
date: 2020-05-10
tags: ["Azure", "LogicApps", "Office365"]
draft: false
---

Hi,

For almost 2 years, I have been using the "Office 365 Outlook Connector" as part of my Logic Apps flows, to send emails internally and externally. Mainly for external receivers, I used the "is HTML" parameter for the body of the email.

![Is HTML parameter](../images/20200510_01.jpg)

This weekend, I was building a new Logic Apps flow, and to my surprise, finding out that the "V2" of this same connector / action, doesn't have that parameter anymore.

![Is HTML parameter](../images/20200510_04.jpg)

Even more surprisingly, the HTML code I was using before in the body of my email, doesn't even get recognized as HTML (would have been nice if this was just magically built-in now... no?), but just sending the raw HTML code as body content. Weird...

![Is HTML parameter](../images/20200510_05.jpg)

More important though, is I found a way to fix this, relying on the **"Variables" Connector** I used in the past to read and pass on text during my flows from one step to another. Maybe this could work for HTML text as well?

1. **Add a step** before the "Send Email" step you already have in your workflow, and search for **"Variables"** as connector type.

![Is HTML parameter](../images/20200510_06.jpg)

2. Select **"Initialize Variable"** as action

![Is HTML parameter](../images/20200510_07.jpg)

providing the following parameters:
- Name: *emailbody* or something similarly descriptive
- Type: String
- Value: leave empty

3. Next, **add a new step**, again selecting the **"Variables"** connector, but this time going for the **"Set Variable"** action

![Is HTML parameter](../images/20200510_08.jpg)

Providing the following parameters:
- Name: *emailbody* or what you used as Name in the initialize step
- Value: *this is where you paste in the actual HTML code of your email content*

4. Next, **select the Send Email V2** action from the "Office 365 Outlook Connector", defining the "set variable" variable, as body of the email

![Is HTML parameter](../images/20200510_09.jpg)

resulting in the following configuration:

![Is HTML parameter](../images/20200510_10.jpg)

When running your Logic App flow again, you will notice that the email you receive will again be in the expected nicely-looking HTML layout as we had before:

![Is HTML parameter](../images/20200510_03.jpg)


I have no idea why that "is HTML" setting has been removed from the Office 365 Outlook Connector, but glad to know we still have a work-around available to achieve the same result. On the other side, was I that wrong assuming the body layout should recognize HTML by default now? As in anybody still sending emails that are not in HTML layout? 

Stay safe and healthy you all! 

/Peter