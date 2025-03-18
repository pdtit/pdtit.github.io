---
title: "AzCopy failing in Azure Devops with error ServiceCode=AuthorizationPermissionMismatch" 
date: 2020-12-14
tags: ["Azure", "Azure DevOps"]
draft: false
---

Hi all, 

This is one of the nail biting challenges of our industry, failing in running a **straight-forward** task. Especially when it is failing... 

## What happened?

I was creating a pipeline in **Azure DevOps** to deploy an ARM template for VM setups with VM Extensions. To prep this deployment, the artifacts (DSC scripts) should be copied to Azure Blob Storage, in order for the Azure DevOps build agent to "find" it. Easy-peasy, there is a predefined task for that, called **[Azure Blob File Copy](https://docs.microsoft.com/azure/devops/pipelines/tasks/deploy/azure-file-copy)** 

I defined source (my Azure Repos folder) and target (Blob Container in Azure Storage Account), but saw the copy failing with an interesting error message:

![AzCopy Error](../images/2020-12-14_1.jpg)

- INFO: Authentication failed, it is either not correct, or expired, or does not have the correct permission
- RESPONSE Status: 403 This request is not authorized to perform this operation using this permission.

Knowing I'm running this deployment with a valid **Service Principal** linked to my **Azure DevOps Service Connection** which deployed Azure Resources successfully before (including a new Azure Storage Account from within the same Job earlier in the process), I had no immediate idea what was wrong. Also, I have used AzCopy for a while already, without issues.

## What to check?
Next challenge is, where do I start troubleshooting? 

- My Service Principal only got created last week, so definitely not expired (and working for other Azure deployments);

- My Service Principal got created with all default settings and scoped to my subscription as Contributor (az ad sp create)(https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli); While you should definitely limit the scope in a production environment, not that important for my demos. And thus also not the blocking factor;

- Check the differences between a working AzCopy pipeline and the non-working version to try and identify any differences;

## BINGO!

Not yet, but at least I found the clue... in the **[AzCopy documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10#option-1-use-azure-active-directory)** which specifies how to enable Azure Blob storage access using Azure Active Directory instead of the traditional SAS token (A Service Principal is an Azure Active Directory object, therefore I was not looking into SAS tokens anymore...). Following the link under [Option 1 (Azure AD)](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-authorize-azure-active-directory), pointed me to the following updates in AzCOpy:


    - The level of authorization that you need is based on whether you plan to upload files or just download them.

    - *If you just want to download files, then verify that the Storage Blob Data Reader role has been assigned to your user identity, managed identity, or service principal.

    - If you want to upload files, then verify that one of these roles has been assigned to your security principal:

        - Storage Blob Data Contributor
        - Storage Blob Data Owner
 

Let's give this a try:

1. From your Azure DevOps Project, select **Project Settings** / **Service Connections**

    ![Service Connections](../images/2020-12-14_2.jpg)

1. Select the **Service Connection** you use for the given Pipeline deployment and choose **Manage Service Principal Roles**

     ![Service Connection Roles](../images/2020-12-14_3.jpg)

1. This opens Azure Active Directory - Access Control from where you can add a role assignment by clicking **Add Role Assignment**

    ![Add Role Assignment](../images/2020-12-14_4.jpg)

1. From the list of roles, select **Storage Blob Data Contributor**, and search for your Service Principal name in the **Select** field (if you don't know the exact name of your Service Principal anymore, from Azure DevOps / Service Connections, select "Manage Service Principal", which will open your Service Principal blade in Azure Active Directory for this specific object - the name will be visible from there)

    ![Add Role Assignment](../images/2020-12-14_5.jpg)

1. **Save** your changes. (Note - I'm allowing this permission for this Service Principal across the full subscription; in a real-life scenario, it would be enough to allocate this Azure Role scoped to the specific storage account)

The result should look about similar to below screenshot:

    ![Add Role Assignment](../images/2020-12-14_6.jpg)

1. Run the Pipeline again from Azure DevOps, and behold... a successful run this time :)! 

    ![AzCopy Successful](../images/2020-12-14_6.jpg)

I hope this helps anyone bumping into the same issue as I did. For me lesson learned is reading the [Azure Docs](https://docs.microsoft.com/en-us/azure/?product=featured) a bit more every now and then, especially when something isn't working right away...

thanks, Peter