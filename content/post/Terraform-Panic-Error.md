---
title: "Terraform showing an error Panic not a collection type" 
date: 2020-09-06
tags: ["Azure", "Infrastructure as Code"]
draft: false
---

Hi all, 

Earlier this week, I got blown away by an interesting **[Terraform](http://www.terraform.io)** issue.

## The Problem

Running a deployment that ran fine for months. I initiated a new deployment using the usual **"terraform init"** step, which ran fine. Followed by the usual **"terraform plan"**, and **BOOM**, the following message appeared:

**Panic: not a collection type**

![Panic error message](../images/2020-09-06_01.jpg)

Since this was a new template I created, I assumed an issue with the syntax or anything similar. As I couldn't find anything, I tried running the same steps with a "valid" template. Only to find out it produced the same error message.

Since I was running this in **[Azure Cloud Shell](https://shell.azure.com)**, I thought next this could be related to the Azure Cloud Shell Azure CLI version and or the Terraform version within.

To get the version of Terraform, run the following:

```
terraform version
```

![Terraform version](../images/2020-09-06_02.jpg)

OK, cool, I was running version 0.13.1, which, based on what I know, was only published recently. Interesting though, there was also a note *about my version being outdated, and I needed to upgrade to 0.13.2*

AFAIK, I've been running my deployments fine over the last few weeks, even this Wednesday during an Azure training demo. So something else must be going on. Digging in some more, I found this issue in the Hashicorp GitHub repository, having a reference to the createEmtpyBlocks, last updated only 3 days ago... hmmmm... let's have a look...

https://github.com/hashicorp/terraform/pull/26028

![Terraform version](../images/2020-09-06_03.jpg)

## The Solution

So apparently the Terraform 0.13.1 got published recently, **causing some issues, and now getting/being replaced with the 0.13.2** as a fix for this (amongst other issues, based on a broader Google search)

Let's give that a try; but wait, I'm running Terraform as part of Azure Cloud Shell, so I probably have to wait for an update getting integrated into the Shell, if that is even happening automatically (something I'll search for later).

Since Cloud Shell is a stripped down Linux, I could only try and treat it like a Linux VM, running the following:

```
curl -O https://releases.hashicorp.com/terraform/0.13.2/terraform_0.13.2_linux_386.zip \
    && unzip terraform_0.13.2_linux_386.zip \
    && mkdir TF0132\
    && mv terraform TF0132/
    
    cd /TF0132

```

![Terraform Install](../images/2020-09-06_04.jpg)

Since **the current Terraform 0.13.1** is part of the default Cloud Shell PATH, it will run from any location you are in; to "force" Cloud Shell to use the **"the newer Terraform 0.13.2"**, one could launch it directly from **"/TF132/.terraform"** , for example:

- ./terraform init <path to templatefile>

- ./terraform plan <path to templatefile>

![Terraform Install](../images/2020-09-06_05.jpg)

Resulting in a successful Terraform deployment again :) 

Hopefully this gets picked up by Azure Cloud Shell soon enough, so I can get rid of this "temporary" workaround. On the other side, actually quite cool to run these versions side by side. Who knows what other bugs I detect while running 0.13.1, although I'm rather sure I will default to the 0.13.2 from now on.

I hope this helps anyone having the same issue as I did,

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

thanks, Peter