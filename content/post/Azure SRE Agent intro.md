---
title: "Azure SRE Agent: Bringing Agentic AI to Site Reliability Engineering on Azure"
date: 2026-03-14T09:30:00-07:00
publishDate: 2026-03-14T09:30:00-07:00
tags: ["Azure", "DevOps", "AI"]
draft: false
---

If you have been following me for a while, you know I'm a big fan of Azure reliability. It was the main topic I presented on several years ago (in the early days of Azure - if that sounds right?) and also mapped with a big part of my job as Azure Architect, consultant and trainer. 

I got amazed at the end of 2021 by **[Azure Chaos Studio](https://learn.microsoft.com/azure/chaos-studio/chaos-studio-overview)**, a service that allows you to inject faults against your Azure workloads (preferably production!), to make them more stable, more reliable. 

But then came Generative AI, and Agentic InfraOps/DevOps. Welcome **Azure SRE Agent**, which was in public preview for a few months, but went GA earlier this week. I played with it since its early inception, and thought the GA - with a lot of cool new updates - was a good time to dedicate a blog article to it. 

## Introduction: What Is Azure SRE Agent?

Modern cloud systems are increasingly distributed, dynamic, and failure‑prone by design. While DevOps practices have optimized delivery velocity, operational reliability still demands significant human effort. Particularly during incident response, root cause analysis, and post‑incident follow‑up. (Having been on the consultant side in physical and cloud environments since 1996, especially the outages and trying to fix issues is what got me into training - is what my wife says when you ask her why I love training so much, lol. She might be right...)

**Azure SRE Agent** is an **AI‑powered reliability assistant** designed to automate and augment Site Reliability Engineering practices for Azure workloads. It continuously observes telemetry (metrics, logs, traces), understands Azure resource topology, correlates incidents with recent changes, and assists with, or ask human approval to execute, remediation steps. 

Unlike traditional monitoring or AI-Ops tools, Azure SRE Agent operates as an **agentic system**:

*   It reasons over multiple data sources simultaneously.
*   It maintains contextual awareness of your Azure environment.
*   It can take action via Azure CLI and REST APIs, subject to explicit approval.
*   It integrates natively with incident management and developer workflows.

In effect, Azure SRE Agent acts as a **virtual SRE teammate**, reducing operational toil and lowering mean time to resolution (MTTR) while preserving human oversight. (If we had agents in the early 2000's, maybe I would still be a technical consultant instead of technical trainer, hmmmm)

## Architecture and Core Capabilities

At a high level, Azure SRE Agent combines four capability pillars:

1.  **Continuous Observability Ingestion**  
    The agent consumes signals from Azure Monitor, Log Analytics, Application Insights, and supported external observability systems to build a live understanding of system health and dependencies. The **real benefit for me** here, is that organizations already have everything in place. So the adoption goes smooth. And the data the agent relies on, feels familiar.

2.  **Intelligent Diagnosis and Correlation**  
    When an alert or anomaly occurs, the agent correlates telemetry with:
    *   Recent deployments or configuration changes
    *   Resource topology and dependencies
    *   Historical incident patterns  
        This enables accelerated root cause analysis without manual log spelunking. (does that exist as a word?)

3.  **Automated and Approval‑Gated Remediation**  
    Azure SRE Agent can execute operational actions. Think of scaling, restarting services, or reverting deployments. Or basically anything that relies on **Azure CLI and REST APIs**. All write actions are gated by RBAC and explicit approval, ensuring governance and control. (If you don't trust the commands it suggests, don't approve the action...) 

4.  **Workflow and Developer Tool Integration**  
    The agent integrates with Azure Monitor alerts, GitHub, Azure DevOps, ServiceNow, and PagerDuty, allowing incidents to flow naturally into existing operational and engineering processes. (I have to be honest, I didn't go that far yet to integrate with source control, probably another blog post in the near future)

## Setup and Deployment

### Prerequisites

To deploy Azure SRE Agent, the following prerequisites must be met:

*   An active Azure subscription
*   Permissions to assign RBAC roles (`Microsoft.Authorization/roleAssignments/write`)
*   Network access to the `*.azuresre.ai` domain
*   Deployment in a supported region (Preview was available in EastUS2, SwedenCentral and AustraliaEast), you might check the docs for accurate updates

> **Note**: I didn't find any information on how to automate the deployment using bicep or az cli - have to come back to that at some point

### Creating an Azure SRE Agent

1.  In the Azure Portal, search for **Azure SRE Agent**.
2.  Select **Create Agent**.
3.  Create or select a **dedicated resource group** for the agent itself (I would recommend deploying this separate from application resources).
4.  Choose the region.
5.  Associate one or more **resource groups to monitor**.  
    The agent automatically gains visibility into all resources within those groups.
6.  Complete the deployment and wait for the agent to initialize.

Once deployed, the agent exposes a **chat‑based interface** in the Azure Portal, allowing engineers to interact using natural language to investigate and manage incidents. 

## Using Azure SRE Agent

After the baseline deployment of the agent, it's nothing more than **running prompts**. Using natural language, asking generic or more-specific questions, and off it goes :)

To test this out, I deployed an Azure App Service, connecting to CosmosDB using Managed Identity. After testing the app, I removed the App Service Managed Identity to simulate the issue. 

I opened SRE Agent and asked:

`can you investigate my app service outage`

This is what it came back with:

![Investigating_App_Service](../images/Screenshot%202026-03-14%20090607.png)

Followed by **looking into the metrics**

![Investigating_Metrics](../images/Screenshot%202026-03-14%20090726.png)

To then provide **a summary** of the findings and observations, **INCLUDING CHART VIEWS**

![Investigating_charts](../images/Screenshot%202026-03-14%20090957.png)

Detailed Root Cause Analysis

![Investigating_summary](../images/Screenshot%202026-03-14%20091106.png)

and detailed description of **what happened** and **Recommended actions**

![Investigating_summary](../images/Screenshot%202026-03-14%20091159.png)

It identified the root cause being an **identity** problem, where the Web App could not connect to Cosmos DB. 

![Investigating_summary](../images/Screenshot%202026-03-14%20091431.png)

To wrap it up with a **Diagnosis Complete - Data Unreachable Root Cause** report (in table format), including **potential fix steps** (Isn't that amazing?? I think it's just brilliant...!!!)

![Investigating_diagnose_complete](../images/Screenshot%202026-03-14%20091606.png)

From there, it asked me if it was OK to move on and assist with fixing the problem. Using the same response I would tell when talking to a colleague, I said

`Yes, go ahead and assist me with fixing this problem using the described steps` 

(I'm pretty sure just saying "yes", or "sure" or "OK" or "YOUCANDOIT" might have worked too...)

![acknowledge_fix](../images/Screenshot%202026-03-14%20091835.png)

The above screenshot was taken after the process completed, but remember the SRE Agent can only perform actions when you as the **human-in-the-loop** acknowledges the approval.

Smoothly, it came back with **Issue resolved**. Including a summary of the steps taken

![acknowledge_fix](../images/Screenshot%202026-03-14%20092204.png)

Well done SRE Agent!!

## Summary

Azure SRE Agent is - apart from GitHub Copilot - my next favorite use case for Generative AI. Having experienced the challenges of cloud workload outages myself for years, spending hours, sometimes days, digging in, gathering metrics and logs, pinpointing the root-cause,... (which sort of was a lucrative business if I think back about it...), I think this is an **amazing** service to be added to your Azure environment. Even when you don't trust it at first (actually, why not?) to take actions, having that AI assistant next to you to help you with the investigation, the outage analysis,... will be a big time-saver. Which means, your workload will be back up-and-running faster too. 

And I didn't talk about the source control integration with GitHub or Azure DevOps. I didn't mention the notifications through Outlook or Teams. I didn't explain the expansion to other data scenarios, third-party monitoring tools such as Grafana, DataDog,... damn, there will be a lot of blog posts on Azure SRE Agent in the near-future I'm afraid.

Also, if you want some inspiration to play with this, have a look at the [Microsoft Learn lab - Optimize Azure Reliability using SRE Agent](https://microsoftlearning.github.io/mslearn-devops/Instructions/agentic/03-optimize-azure-reliability-using-sre-agent.html) I published recently.

If you deployed it and use it in your environment, please let me know. Happy to hear your stories!

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter