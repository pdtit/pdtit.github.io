---
title: "Using GitHub Copilot Agent Mode to transform ARM templates to BICEP"
date: 2025-07-12
publishdate: 2025-07-12
tags: ["Infrastructure as Code", "DevOps", "GitHub Copilot", "AI"]
draft: false
---

Over the last few months, I've been working on an exciting project for our Microsoft Technical Trainer team, known as ["Trainer-Demo-Deploy"](https://aka.ms/trainer-demo-deploy), a catalog of Azure end-to-end demo scenarios, available as an Open-Source project.

While we managed to get about 50 templates live, there can never be enough scenarios to integrate into your Azure classes or POC activities if you ask me. One of the challenging tasks in the project is not only coming up with demo ideas, but also creating the actual artifacts, such as Azure templates with Bicep, sample apps and sample data. 

I had an [Azure Site Recovery Services](https://azure.microsoft.com/en-us/products/site-recovery/) scenario from a few years ago, written in modular ARM templates. With Bicep providing a great way to [transform your ARM to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/decompile?tabs=azure-cli), I could have gone through each template file and convert them. Have done several of those over the last few months.

But out of teaching [AZ-2007 Accelerate app development by using GitHub Copilot](https://learn.microsoft.com/en-us/training/paths/accelerate-app-development-using-github-copilot/), where I integrate a - what I think amazing demo on how to use Agent mode to deploy a sample web app - I started thinking about testing if **Agent Mode** could help me with this transformation project. 

Fact I'm dedicating a blog post to it, is mainly to confirm it worked amazingly well, as well as sharing my excitement and some steps of what the process looked like. Hopefully this post inspires you to start embracing [**GitHub Copilot Agent Mode**](https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/) into your own tasks. 

## My starting templates

1. My original setup was pretty straightforward, having a folder "templates", in which I have modular templates for each part of my Azure Site Recovery Vault deployment.

Each templates hold a snippet of ARM / JSON structured code to deploy one or more Azure Resources. 

![Current ARM Templates](../images/screenshot-2025-07-12-677ae48c.png)

2. I opened up the folder structure in my Visual Studio Code, and opened GitHub Copilot, selecting **Agent Mode**. I *clearly described in a prompt*, what I wanted the Agent to perform as tasks. I didn't provide much detail to be honest, as initially, I was merily experimenting to try and find out if Agent could actually help with this, or how far it would go in the process.  


## Agent Mode Prompt

The prompt I used was this:
*for each file in the templates folder, convert to azure bicep. create a new bicep file for each, keeping the same name as the original json file. the azuredeploy should be transformed to main.bicep. validate all pointers to all new bicep files to be correct"*

![Agent Mode Prompt Used](../images/screenshot-2025-07-12-0e6d3c1f.png)

3. From here, the **Agent started rolling...**

4. Informing me about the different steps it would take to handle this task, starting with *exploring the templates folder to see all the files that need to be converted*

![Agent Mode Starting](../images/screenshot-2025-07-12-9563c155.png)

5. Followed by going more in-depth into each and every template JSON file


6. Followed by *starting the conversion process to Bicep files*. Before doing that, it also highlighted it would check the Azure deployment best practices (although I didn't explicitly asked to do that, nice one! ) 

![Agent Mode inspecting files](../images/screenshot-2025-07-12-23d6f25c.png)

7. It felt like it *learned* from the best practices, by starting with the azuredeploy.json conversion to main.bicep first. It could also be that it started with this, because I mentioned this in the prompt itself.

![Agent Mode creating main.bicep](../images/screenshot-2025-07-12-048d528f.png)

8. As the main.bicep conversion took a bit longer than normal - although it was only running over it for about a minute, it *prompted*, asking if it was ok to continue. Obviously, I confirmed to **continue**. 

![Agent Mode pending task](../images/screenshot-2025-07-12-9f313718.png)

9. From here, it nicely continued looping through all smaller json-files, and transforming them into corresponding bicep-files. Since each file typically had only 1 or 2 resource references, the conversion went really smooth. 

![Agent Mode conversion](../images/screenshot-2025-07-12-cc406a5d.png)

10. After a bit, it had finished the transformation of each ARM to Bicep, and *started on updating the template links*, as I asked for in my prompt, to also validate the references to all the deployment files.

![Agent Mode updating file links](../images/screenshot-2025-07-12-3a52cde6.png)

11. With all references updated, it continued with its own *error checking*, and validating the different templates for any possible errors. Even more interesting, **without me specifying**, it detected an error in the **azure.yaml**, which I had in my project folder, from a baseline started AZD-template we use to create all our Trainer-Demo-Deploy scenarios. 

![Agent Mode create azure.yaml](../images/screenshot-2025-07-12-c58c585e.png)

12. Last, it also created a *main.parameters.json*, to capture any specific Parameters for the deployment. 

![Agent Mode create main.parameters.json](../images/screenshot-2025-07-12-52ae46b8.png)

13. From here, it went back to *validating* the Bicep templates again, where it detected a few different issues. (I didn't check in detail what got identified as issue, as it didn't prompt me to validate anything on my end...); based on the *next informational message*, it struggled with missing an output for **myWorkspaceKey**, in the deploy-infra.bicep file. 

![Agent Mode validating infra](../images2025-07-04-bicep-error.png)

14. *Chewing* a bit on the myWorkspaceKey problem, it managed to find its own work-around to solve the problem. It even provided a clear explaining on why, identifying the dependency on the parent template.

![Agent Mode detecting an issue](../images/screenshot-2025-07-12-7c9e3eae.png)

15. Feeling we were close to the end of the process, it **continued amazing** me, as it now also created its **own documentation** in a BICEP_CONVERSION_SUMMARY.md Markdown file, in which it listed up what conversations it did.  

![Agent Mode creating conversion documentation](../images/screenshot-2025-07-12-233210a1.png)

16. With all that out of the way, it ran another **final validation** to conclude there were no more issues, closing the task with creating another README-BICEP.md file, describing how to run the actual deployment, using AZD. 

![Agent Mode creating readme](../images/screenshot-2025-07-12-ea367bd4.png)

17. Finally, the Agent **provided a description within the Chat Agent window**, clearly describing all the tasks accomplished with the necessary file references included:

![Agent Mode Chat description](../images/screenshot-2025-07-12-12b1b132.png)

18. As well as adding additional details on the **task validation**.

![Agent Mode creating task validation](../images/screenshot-2025-07-12-8a5606f6.png)

19. Finishing with describing different ways on how to run the actual deployment, using **azd**, **Azure CLI** and **Azure PowerShell**. 

![Agent Mode explaining how to run the deployment](../images/screenshot-2025-07-12-1a21a2ce.png)

20. Last step was running the deployment, and this worked without any hiccups! 

![Deployment completed](../images/screenshot-2025-07-12-b01b0623.png)

## Summary

As mentioned earlier, I didn't intend to go through this process as part of writing a blog post. Yet, the fact that the **GitHub Copilot Agent Mode** happily suprised me once more, I wanted to share my joy and excitement about this. 

Starting from a *somewhat complex* JSON ARM template folder with about 10 modular arm-json files, it managed to nicely convert all of them into the new Bicep template language, with only a few minor issues throughout the process. Without asking assistance or halting the process, it ran its own troubleshooting and issue resolution, resulting in a 100% successful transformation.

Apart from the technical success of the task, what surprised me even more, is **it only took the agent barely 5 minutes** and only had to **prompt me twice** during the whole process!!

If you want to see this template in action, head over to [my github repo](https://github.com/petender/azd-asrdemo) and continue your Azure learning journey with more demo scenarios at [Trainer-Demo-Deploy](https://aka.ms/trainer-demo-deploy). 

[![BuyMeACoffee](../images/screenshot-2025-07-12-17f576e7.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
