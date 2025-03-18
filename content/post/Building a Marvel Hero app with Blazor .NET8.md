---
title: "ScifiDevCon 2024 : Building a Marvel Hero App using Blazor and .NET8 "
date: 2024-05-18
publishdate: 2024-05-18
tags: ["Blazor", "Azure", .NET8]
draft: false
---

Building a Marvel Hero catalog app using Blazor Server and .NET8

# Introduction

At the end of 2022, as part of the *Festive Tech Calendar* community initiative, I provided a step-by-step instruction blog on how to build a Blazor Web Assembly app from scratch, using .NET7.

About 18 months later, a lot of things have changed in the **.NET8 world**, which also impacted **positively** new features around the Blazor Web App Framework, on both Web Assembly (Client/Browser) and Server side.

I decided to rewrite/update the steps, using the same idea for the app, but this time redeveloping it from scratch, using .NET8 and Blazor WebAssembly RenderMode. If you want to see the live coding in action, head over to **https://www.scifidevcon.com**, a great community initiative to celebrate the month of May, Geekiness, Developing, cloud and everything else that fits in the combination of all those topics in a virtual conference.

This app introduces Blazor .NET8 development, and more specifically how to easily create a Single Page App using HTML, CSS and API calls to an external API Service at <https://developer.marvel.com>

While I've been using Blazor .NET for about 3 years now as a hobby project, I feel like I am still learning development with .NET for the first time at age 48. Having succeeded in getting an actual app up-and-running, I wanted to continue sharing my experience, inspiring other readers (and viewers of the ScifiDevCon session) to learn coding as well. And maybe becoming a passionate Marvel Comics fan as myself.

# Prerequisites

If you want to follow along and building this sample app from scratch, you need a few tools to get started:

-   Visual Studio 2022 version 17.9.7 or newer, to develop the application (VSCode or other dev tools will work as well, but I'm not that familiar with those...)
    -   Community Edition can be downloaded for free here ([Visual Studio 2022 Community Edition – Download Latest Free Version (microsoft.com)](https://visualstudio.microsoft.com/vs/community/))
-   GitHub Account to store the application code in source control
    -   Sign Up for free here (<https://github.com/join>)
-   Azure Subscription to run Azure App Service web application
    -   Get a Free Azure Subscription here (<https://azure.microsoft.com/en-us/free/>)
-   Marvel Developer Account to get access to the API back-end
    -   Register for free at <https://developer.marvel.com>

# Deploying your first Blazor Web Assembly app from a template

Visual Studio (and .NET) provide different Blazor templates, both as an “empty template”, as well as one with a functional “sample weather app”, and both options are available for Server and Web Assembly. 

With the release of .NET8 last November, the Product Group decided to simplify getting started with Blazor, using the **Blazor Web App** template. Actually allowing you to decide wether to use WebAssembly, Server or both, in the same project. 

1.  Launch **Visual Studio 2022**, and select **Create New Project**
2.  From the list of templates, select **Blazor Web App**

![Graphical user interface, text, application Description automatically generated](../images/2024-05-17-215846.png)

3. Provide a name for the project, e.g. **BlazorMarvel8**, and store it to your local machine's folder of choice
4. Click **Next** to continue the project creation wizard
5. Select **.NET 8.0** (Long Term Support) as Framework version
6. Select **None** for authentication type
7. Select **WebAssembly** for Interactive Render Mode
8. Select **Per Page/component** for Interactivity location

9.  Click **Create** to complete the project creation wizard and wait for the template to get deployed in the Visual Studio development environment. The Solution Explorer looks like below:

![Graphical user interface, Create Project](../images/2024-05-17-220528.png)

10.  Run the app by pressing **Ctrl-F5** or select **Run** from the upper menu (the green arrow) and wait for the compile and build phase to complete. The web app should load successfully in a new browser window.

![Blazor WebAssembly default app in browser](../images/2024-05-17-220807.png)

11.  Wander around the different parts of the web app to get a bit familiar with the features. In the context of .NET 8, Blazor WebAssembly projects typically consist of two separate projects: an app and an app.client. The app project is the server-side part of the Blazor application, which can serve pages or views as a Razor Pages or MVC app. The app.client project contains the client-side Blazor application that runs in the browser on a WebAssembly-based .NET runtime.

The separation of the client and server projects in the Blazor WebAssembly hosting model provides a clear separation of concerns, allowing for server-side functionality, integration with ASP.NET Core features, and flexibility in hosting and deployment options. This architecture aligns well with the server-client model and the capabilities of the ASP.NET Core framework.

For instance, Blazor WebAssembly can be standalone for simple, offline apps, but having a separate server project unlocks improved security, scalability, complex server tasks, and potential offline features, making it ideal for more elaborate and demanding applications. As your application grows or requires server-side functionality, having a separate server project provides a scalable and maintainable architecture.

This design pattern, where decoupling or loosely coupled apps are encouraged, is preferred over tightly coupled applications, especially as the complexity of the project increases.

12.  Close the browser, which brings you back into the Visual Studio development environment.

13.  This confirms the Blazor Server app is running as expected.

In the next section, you learn how to update the Home.razor page and add your own custom HTML-layout, CSS structure and actual runtime code.

# Updating the template with your custom code

Blazor allows you to combine web page layout code (Razor pages), basically HTML and CSS, together with actual application source code (C# DotNet), in the same razor files. I can’t compare it with previous development environments, but it seems to be one of the great things about Blazor – and I really like it, since it’s somewhat simplifying the structure of your application source code itself.

Another take is creating the web page layout first, and only adding logic later on. So let’s start with creating a basic web page, adding a search field and a button. All Razor Pages the app uses, are typically stored in the \Components subfolder.

1.  You can chose to reuse the Home.razor sample page and continue from there, or create a new Razor Page and update the route path. To show you how Blazor Components are working, let's define our SearchMarvel page, as a **new page** under the **\Pages** section in the **Client** project. Save it as **SearchMarvel.razor**

2.  In this part, we start with adding a search field and a search button to the web page layout. Insert the following snippet of code, replacing all the current content on the page:

```csharp
@page "/searchmarvel"

<h1 class="text-center text-primary"> Blazor Marvel Finder</h1>

<div class="text-center">

<div class="p-2">

<input class="form-control form-control-lg w-50 mx-auto mt-4" placeholder="Enter Marvel Character" />

</div>

<div class="p-2">

<button class="btn btn-primary btn-lg">Find your Favorite Marvel Hero</button>

</div>

</div>

```
3.  This adds the necessary objects on the web page.
4.  And let’s run this update to see what we have for now.

![Web page layout is visible in the browser](../images/2024-05-17-221303.png)

5.  So the layout for the search part of the app is done. Let’s move on with the design of the actual response / result items. The return from the Marvel API can be presented in a table gridview, but that’s not that nice-looking; I remembered having physical cards as collector items as a kid, so I did some searching for a similar digital experience. Interesting enough, there is a CSS-class object “card”, which nicely reflects this experience. So let’s add the next snippet of code for this response layout.

6.  Add the following code, below the snippet you copied earlier:

```csharp

    <div class="container">

    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3">

    <div class="col mb-4">

    <div class="card">

    <img src="https://via.placeholder.com/300x200"

    class="card-img-top">

    <div class="card-body">

    <h5 class="card-title">Marvel Hero Name</h5>

    <p class="card-text">

    Character details

    </p>

    </div>

    </div>

    </div>

    </div>

    </div>

```

What this snippet does, is adding a “container” object, in which we create a small table view having 3 rows and 1 column. The card composition shows the Hero title on top, the Marvel Hero character details in the middle and an image of the character as well.

7.  Let’s run the code again to test if everything works as expected.

![Graphical user interface, text, application, chat or text message Description automatically generated](../images/2024-05-17-221457.png)

8.  Now wait, we lose quite some time on stopping the app, updating code, starting it again – so what we can do is use the **new VS2022 feature called Hot Reload** / if I set this to “Hot Reload on Save”, it will dynamically update the runtime state of the app based on my edits. Let’s check it out.
9.  While in debugging mode, check the “flame” icon in the menu:

![Hot Reload](../images/2024-05-17-221614.png)

10.  Enable the setting “Hot Reload on File Save”.
11.  Edit the card-title “Marvel Hero Name” to “Marvel Character Name” and check how the app refreshes itself without needing to stop/start.

![Update after Hot Reload](../images/2024-05-17-221738.png)

The search field is not doing anything yet, so we need to make sure – that whenever we type something in that field - it kicks of an API call to the Marvel API back-end.

12.  First, we need to use the bind-value parameter for this field, linking it to a search task; Update the line with the field box as follows:  

```csharp
      
     <input class="form-control form-control-lg w-50 mx-auto mt-4" placeholder="Enter Marvel Character" @bind-value="whotofind" />

```

add **@bind-value=”whotofind”** at the end of the line.

![Add bind-value parameter to text field](../images/2024-05-18-090106.png)

Ignore the errors regarding the “whotofind” for now. We'll fix that in a minute.

13.  Next, we need to update the button code to actually pick up an action when clicking on it; this is done using the @onclick event

    Add **@onclick=FindMarvel**

![AAdd onclick event for button](../images/2024-05-18-090244.png)

14.  The code snippet complains about unknown attributes, which is what we need to add in the actual code section of the app page:

15. Add the following @code section below the HTML/CSS layout

```csharp
@code {
    private string whotofind;

    private async Task FindMarvel()
        {
        // Call the Marvel API
        Console.WriteLine("Marvel Character to find: " + whotofind);
    }
}
```

16.  Within the curly brackets, we can use regular C# code
17.  Start with defining a string for the “whotofind”
18.  Followed by defining a method (task) for the FindMarvel onclick action – for now, let’s write something to the console to validate our search field is working as expected

The string “whotofind” refers to the search field object, where the Task “FindMarvel” refers to the button click action. So easy said, whenever we click the button, it will pick up the string content from the search field, and send it to the Marvel API back-end. As we don’t have that yet, I’m just writing the data to the console, which is always a great test to validate the code is working as expected.

![Code snippet for button action](../images/2024-05-18-090439.png)


19.  Save the file, which will throw a warning regarding the hot reload. Since we added new actual code snippets, hot reload can’t just go and recognize it. So a reload is needed…

![Hot Reload can't handle code changes](../images/d0be33cb6858972b3c00724c40f485e3.png)

20.  Select “Rebuild and Apply Changes”

21.  Enter the name of a Marvel character, for example “thor”, and notice **nothing happens on the console/terminal**. Why not?? Is it an error in our code, did we miss anything,...?

**NO and YES :)**... our code is fine, but we are missing a new .NET8 feature for Blazor apps... we need to specify the **Render Mode** 

Note > for more details on Blazor app Render Mode, check [this article](https://www.sitepoint.com/net-8-blazor-render-modes-explained/) I guest-authored for SitePoint a few weeks ago, explaining the different options and how to use them. 
      
22. Remember when we created the Visual Studio project, we defined the **WebAssembly** Render Mode. Now to make this work, there are a few more changes needed in the source code: 

a) Define the InteractiveWebAssembly Render Mode in the App.razor file
b) (Optionally), specify the InteractiveWebAssembly Render Mode for Pages and/or Components

So depending a bit on how much control you want, or how frequently you want to use Interactive Render mode, you would specify this in your App.razor, as a Global parameter - turning the full Blazor App into that mode. Or, if not all pages and/or components require that Render Mode, you can add the specific parameter to individual components. 

In this example, I'll show you how to use it on a 'per page' level, knowing that either one would be OK for this sample app.

23. At the top of your SearchMarvel.razor page, after the @page line, add the following:

```
@rendermode InteractiveWebAssembly
```

which tells the page/component should use the Interactive Render Mode, which "enables" the button event in our case. 

24. Save the changes, and run the app; enter a Marvel character name in the search field, click the Find Button and notice the search field string is shown in the console now. This is what InteractiveWebAssembly Render Mode is doing...

![Console.WriteLine is working as expected](../images/2024-05-18-091910.png)


25.  I think the bare minimum app layout development is ready, so it’s time to set up the Marvel API-part of the solution in the next section.

# Configuring the Marvel Developer API Backend Code interaction

1.  Head over to the Marvel Developer website <https://developer.marvel.com> and grab the necessary API information.

![Marvel Developer Site Home Page](../images//fc2a542cfdbca3fb86519841f3f53999.png)

2.  Select Create Account + Accept Terms & Conditions
3.  Grab the API keys (public & private)

    **Public:** 579a41c9eccaf70a3a09c1xxxxxxxxxxx

    **Private:** 6362bd53a4c307c96fb27xxxxxxxxxx

4.  To allow requests to come into the Marvel API back-end, you need to specify the source URL domains where the requests are coming from. Add **localhost** here, which is the URL you use for all testing on your development workstation. Later on, once the app runs in Azure, you need to add the Azure Service URL here as well…

![API rate limits and domains](../images//a7dd9d49c1402deb787b6ab792a0fb38.png)

5.  Once set up, head over to “interactive documentation”, and walk through the different API placeholders and keywords one can use, to show the capabilities. For the app later on, we will use the “namestartswith”, as it is the most easy to use – names could work, but it requires knowing the explicit name of the character, and having it correctly spelled.

![Marvel API documentation site](../images//d9552cc8c4ec1ff4e0f2e32a767a4f42.png)

![nameStartsWith API Example](../images//57bc3634f004877c8cff9942d9e6e8d3.png)

![Limit the result set parameter to 50](../images//4f749b51a5d1bdf6d51e81f614c8d72a.png)

![API response codes and try-out button](../images//9883c08decac6bffde5cb763539b953f.png)

6.  Click the “Try it out” button. The result shows the outcome + the exact URL that was used:

![API Response Body in JSON](../images//b3aab53a282e9d00b58ba5c91e81afa0.png)

7.  Blazor WebAssembly doesn't come with the HTTPClient package installed by default, which means we need to add the Nuget package for this. (Although if you want, you could also find Nuget packages that provide similar functionality), as well as specifying the necessary Service, in both the server-side and client-side project.

8. From the app.client project, select **Manage Nuget Packages**, and search for **Microsoft.Extension.Http** as package name. 

![Http Nuget Package](../images/2024-05-18-124041.png).

9. Once the package got installed, update the **Program.cs** file in the client project, by adding the following line below the "var builder = WebAssemblyHostBuilder... line:

```
builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri("https://gateway.marvel.com:443/v1/public") });
```
![Add Scoped Service for HTTPClient](../images/2024-05-18-093043.png)

10. Next, open the **Program.cs** on the server-side project, and add the following line to the //Add Services to the container section:

```
builder.Services.AddHttpClient();
```

![Add Service for HTTPClient](../images/2024-05-18-124637.png)

9. Next, using .NET dependency injection, create a reference to the HTTPCLient in your Blazor SearchMarvel.razor page

```csharp

@page "/"

@inject HttpClient HttpClient

<h1 class="text-center text-primary"> Blazor Marvel Finder</h1>

<div class="text-center">

```

![HttpClient Dependency Injection](../images/2024-05-18-093311.png)

10.  As you could see from the Marvel output, they are using JSON; this means, when calling the HttpClient, we also receive a JSON object back. 

![Marvel Characters JSON Response](../images//6ace0a137db04fd541e730b90bf18a42.png)

11. To 'recognize' the data from the JSON response into our Web App, we need to link it to a data model, using a Csharp class. There's a few different ways to do this, either creating it manual, using the Visual Studio 'Edit - Paste Special - as JSON", which will create the necessary Class setup for you. However, in this specific scenario, I don't need all the details from the JSON Response (although you could definitely update the app yourself to display all the information you want, related to a Marvel Character...)

12. To help transforming a JSON Response into an actual C-Sharp Class, I often rely on a free website,  **https://www.jSON2CSharp.com**, which allows for pasting in a JSON payload, which then gets converted to c# class structure

![Text Description automatically generated](../images//7840c5de3eda79f2d196079bc0081756.png)

13.  In the VStudio app.client project, create a new subfolder “Models”, and add a new Item in there, called MarvelResult.cs

![Graphical user interface, application Description automatically generated](../images//3bb34b057bc24ab07c3280a90a41e829.png)

14.  We could copy the content from the JSON deserialize output into this class object, but for this sample, we don’t need all the provided data by Marvel – so I made some changes and ended up with the core pieces of data I want, like image, name, description

The code snippet I'm using for this example, looks like follows:

```csharp
{

public class MarvelResult

namespace BlazorMarvel8.Models
{
    public class MarvelResult
    {
        public string AttributionText { get; set; }
        public Datawrapper Data { get; set; }

        public class Datawrapper
        {
            public List<Result> Results { get; set; }
        }

        public class Result
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string Description { get; set; }
            public Image Thumbnail { get; set; }

            public class Image
            {
                public string Path { get; set; }
                public string Extension { get; set; }
            }
        }
    }
}


}

```

![MarvelResult Class](../images/2024-05-18-094323.png)

15.  With the class in place, let’s update the SearchMarvel.razor, to make sure it recognizes the model class MarvelResult. To do this, we need to add a private MarvelResult, reflecting the data class we just created;

```csharp
private MarvelResult _marvelResult;

```
![Add Model data to Razor Page](../images/2024-05-18-094655.png)

16. As we stored the MarvelResult.cs class model in a different folder within the application source code, we also need to update our Page details, telling it to “use” the Models subfolder to find it. This is done using the @using statement on top of the Home.razor page:

```
@using BlazorMarvel8.Models

@page "/"

@inject HttpClient HttpClient
```

![Adding using statement to point to Models subfolder](../images/2024-05-18-094850.png)

Where now the Class gets nicely recognized

![MarvelResults recognized](../images/2024-05-18-095009.png)

17.  Let’s update the Task FindMarvel, with the required code snippet to recognize the dynamic URL to connect to, as well as calling the HttpClient function. As per the Marvel API docs, we also need to integrate the api Public key into our URL search string, so we have to define the string for this first. 

Btw, the full Request URL to use is visible from the Interactive Documentation page where we ran the 'try it now' search task (https://gateway.marvel.com:443/v1/public/characters?nameStartsWith=spider&apikey=579a41c9eccaf70a3a09c1722ef6c2fc)

The updated code snippet looks like this now:

```csharp
@code

{

private MarvelResult _marvelResult;

private string whotofind;

private string MarvelapiKey = "579a41c9eccaf70a3a09c1722ef6c2fc";


```
18.  After which we can update the Task FindMarvel as follows:

```csharp
private async Task FindMarvel()

{

Console.WriteLine(whotofind);

var url = $"characters?nameStartsWith={whotofind}&apikey={MarvelapiKey}";

_marvelResult = await HttpClient.GetFromJsonAsync<MarvelResult>(url, new System.Text.Json.JsonSerializerOptions

{

PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase

});

}

```

![API Call snippet to Marvel back-end](../images/88a6f657a0adfca57021b3606066f8db.png)

19. While all the code pieces are done, note that as of .NET6, it started checking for Nullable values. This is what the green squickly lines are identifying. What this means is that the value could be equal to null, which could potentially break your application, since it expects to have a real value in there.
20.  I wouldn’t recommend it to change, but for this little sample app, it would be totally OK to disable the nullable check. This can be done from the Properties of the Project

![Disable Nullable Check for Project](../images/2024-05-18-095912.png)

# Render JSON Response data into HTML Layout

1.  That’s all from a code snippet perspective, where now the last piece of updates is back into the HTML Layout of the web page itself, updating the content of the card object:
1.  Since we most probably get an array of results back, meaning more than one, we need to go through a “for each” loop; also, there might be scenarios where we are not getting back any results (like the character doesn’t exist, a typo in the character’s name,…), so we will add a little validation check on that too, using an if = !null

Let’s go ahead!

1.  At the top of the card object (class=container), or right below the <div> section where we defined the search button, insert the @if statement, and move the whole div section between the curly brackets, updating the fixed fields we defined earlier, with the MarvelResult class objects:

```csharp
@if (_marvelResult != null)


{
    <div class="container">
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3">

            @foreach (var result in _marvelResult.Data.Results)
            {
                <div class="col mb-4">
                    <div class="card">
                        <img src="@($"{result.Thumbnail.Path}.{result.Thumbnail.Extension}")"
                             class="card-img-top">
                        <div class="card-body">
                            <h5 class="card-title">@result.Name</h5>
                            <p class="card-text">
                                @result.Description
                            </p>
                        </div>
                    </div>
                </div>
            }
        </div>
    </div>
}
```

1.  Run the app and see the result in action

![Graphical user interface, website Description automatically generated](../images//44856923dff937c6cad7d953b046c1bd.png)

1.  That’s it for now. Great job!

# Making the cards ‘flip’

**Note: this part is left out of the ScifiDevCon presentation to keep the video within the expected time – what we’re doing here is integrating more CSS layout components on to a new Page in the web app, which provides a more dynamic look-and-feel to the Marvel cards we have.**

While CSS can be difficult – and trust me it is – I literally googled for “flipping cards CSS” and found a snippet of code on <https://w3schools.com>, and it worked almost straight away…

Here we go:

1.  Let’s copy the current state of the page we have, and store it in a different page; so we grab **SearchMarvel.razor** and copy/paste it to **FlipMarvel.razor** this will allow me to also demonstrate some other Blazor features around Menu Navigation and how to use object-specific css; meaning, CSS that will only be picked up by the specific page, and not interfere with the rest of the application CSS we already have.
1.  Open FlipMarvel.razor page; First thing we need to change, is the Page Routing, pointing to the “/flip” routing directory instead of the “/”, as that one is linked to the index.razor page.  
      
    ![Graphical user interface, text, application Description automatically generated](../images//46aac649d4ecfb4be03d1ce021141274.png)
2.  Go to this link: <https://www.w3schools.com/howto/tryit.asp?filename=tryhow_css_flip_card>
3.  Select the code between the <style> objects, including the <style>/</style> tags  

```csharp      
    <style>

body {

font-family: Arial, Helvetica, sans-serif;

}

.flip-card {

background-color: transparent;

width: 300px;

height: 300px;

perspective: 1000px;

}

.flip-card-inner {

position: relative;

width: 300px;

height: 300px;

text-align: center;

transition: transform 0.6s;

transform-style: preserve-3d;

box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);

}

.flip-card:hover .flip-card-inner {

transform: rotateY(180deg);

}

.flip-card-front, .flip-card-back {

position: absolute;

width: 300px;

height: 300px;

-webkit-backface-visibility: hidden;

backface-visibility: hidden;

}

.flip-card-front {

background-color: #bbb;

color: black;

}

.flip-card-back {

background-color: #2980b9;

color: white;

transform: rotateY(180deg);

}

</style>

```

1.  and paste this under the @using section and the <PageTitle> section of the code you already have (Note: ignore the @using marveltake2.models in the screenshot, it’s the name of my test project)

![Graphical user interface, application Description automatically generated](../images//e28cd81c4d68ae3560000e3a047e15f9.png)

1.  Next, we need to update the layout of the card item itself, in the section within the “foreach” loop, as that’s where the data is coming in, and getting displayed

@foreach(var result in _marvelResult.Data.Results)

```csharp
{

<div class="col mb-4">

<div class="flip-card">

<div class="flip-card-inner">

<div class="flip-card-front">

<img class="thumbnail" src="@($"{result.Thumbnail.Path}.{result.Thumbnail.Extension}")" style="width:300px;height:300px;">

</div>

<div class="flip-card-back">

<h5>@result.Name</h5>

<p>

@result.Description

</p>

</div>

</div>

</div>

</div>

}

```

What we do here is basically pointing to the different CSS-snippets for each style we want to get applied; we have the flip-card div class, next the flip-card-inner and flip-card-front. For the front, we want to use the image, so we keep the img class details as is, but change the width and height to 300px, to make sure it looks like a nice rectangular on screen.

1.  Next, we add a class for the flip-card-back, where we will show the Marvel character name and description.   
      
    ![Graphical user interface, text, application, email Description automatically generated](../images//4082873f68fc45f018526dcce23ec2b7.png)

That’s all we need to have for now; so let’s have a look, by launching the app

1.  Since the previous page was index.razor, it’s getting loaded by design (from the index.html). so we need to update the URL to pick up the /flip page, by adding it to the end of the URL, such as <https://localhost:7110?flip> (note, the port number will be different on your end)

![Graphical user interface, application Description automatically generated](../images//7ce7af6f54af8a7aee9535ff23b92e47.png)

1.  Search for a character, and see the outcome cards:

![Graphical user interface Description automatically generated](../images//b2a599d62eb62f38570ce2865d97a8a0.png)

1.  About the same as before, but let’s hoover over a card:
2.  It flips and shows the character name and description (if provided by Marvel) to the back of the card

![Text Description automatically generated](../images//445529556f9af96a20cecb08dee76707.png)

Cool!!

1.  Let’s switch back to the code and add a menu item for the “flip” page to our left-side navigation menu.
2.  Open the file NavMenu.razor within the **Server-Side Layout** folder.
3.  Add a new <div> section for this menu item, by copying one from above + make minor changes to the href reference (flip) and change the Menu item word to Flip
1.  The icons are coming from the open iconic library, which is also referenced as part of Blazor bootstrap. Know you can change to MudBlazor, Telerik Progress or several other bootstrap frameworks to have layout-rich styles.
2.  Open https:://useiconic.com and find a suitable icon, for example loop-circular

![Chart Description automatically generated with medium confidence](../images//934083c32d1deed78048f9f953f85869.png)

```csharp

<div class="nav-item px-3">

<**NavLink** class="nav-link" href="flip">

<span class="oi oi-loop-circular" aria-hidden="true"></span> Flip

</**NavLink**>

</div>

```

1.  When you run the app again, the new Menu item will appear. Given the href=”flip”, it will redirect to the base URL (<https://localhost:7110>) /flip route

![Graphical user interface, application Description automatically generated](../images//d9276771ac7e7f6fb7800724605797cc.png)

Since we are changing the layout a bit here, why not modify the default purple color from the Blazor template, to the well-known Marvel dark-red?

1.  Open MainLayout.razor
2.  Notice the <div class=sidebar>
3.  Paste in the following style object:

```csharp
<div style="background-image:none;background-color:darkred;" class="sidebar">

```

1.  This changes the default purple color to darkred.

![Graphical user interface, application Description automatically generated](../images//33d3c7a7c6df44851c787ad147d4904e.png)

1.  This completes our development part. Let’s move on to the next step, and integrate our app code with GitHub Source Control (which actually should have happened at the start, before writing a single line of code – but hey, it’s a sample scenario right)

# Integrating Visual Studio with GitHub Source Control

1.  With that, let’s close this project and save it to GitHub; so you can grab it as a reference. From the explorer, click “Git changes” tab and select Create GitHub Repository

![Graphical user interface, application Description automatically generated](../images//51bf9482699dc85b868b603bab0406d8.png)

1.  Click Create and Push, and provide a description as commit message (I typically call this first action the “init”).
2.  Wait for the git clone action to complete successfully. Connect to the GitHub repository and confirm all source code is there.   
      
    **Note: the actual source code I used for the Festive Tech Calendar presentation can be found here:** [petender/FestiveBlazor2022live (github.com)](https://github.com/petender/FestiveBlazor2022live)

![A screenshot of a computer Description automatically generated with medium confidence](../images//4d09932a92c0b020a566940e79741aeb.png)

1.  Whenever you would make changes in the source code in Visual Studio and save the changes, Git Source Control will keep track of these and allowing you to commit the changes into the GitHub repository. I would recommend you to commit changes frequently, basically after each “important” update to the code.

# Publish Blazor Web Assembly app to Azure Static Web Apps

In this last section, I will show you how to publish this webapp to Azure Static Web Apps, a web hosting service in Azure for static web frameworks like Blazor, React, Vue and several other.

1.  From the Azure Portal, create new resource / static web app  
      
    ![Graphical user interface, text, application Description automatically generated](../images//756a5b2424f865b6cf86eefab8492d2e.png)
2.  Provide base information for this deployment:
-   Resource group – any name of choice
-   Name of the app – any unique name for the app
-   Source = GitHub
-   Plan = Free
-   Region = any region of your choice

    ![Graphical user interface, text, application Description automatically generated](../images//3910c87d613034cbd0c9ed1392dfda7b.png)

1.  Scroll down and authenticate to GitHub; Next, select your source repo in Github where the code is stored (the one we just created)

    ![Graphical user interface, text, application Description automatically generated](../images//1bd1ddddd3602c3ba2d84b540da393aa.png)

2.  Click Build Details to provide more parameters regarding the Blazor app itself. Note you need to change the default App location from /Client to /, since our source code is in the root of the Blazor Web Assembly, without using ASP.Net hosted back-end.

    ![Graphical user interface, application, email Description automatically generated](../images//420cbce0770a41dc39ddf2184948363e.png)

3.  Once published, it will trigger a GitHub Actions pipeline to publish the actual content

    ![](../images//ba208857aa01b6d744c79606a7a76b53.png)

4.  The YAML pipeline code is stored in the .github/workflows/ subfolder within the GitHub repository. You shouldn’t need to update this file though. It just works out-of-the-box.

    ![Graphical user interface, text, application, email Description automatically generated](../images//7d89901490cd8ae277355c130085551f.png)

5.  Check in Actions what’s happening:

    ![Graphical user interface, text, application, email Description automatically generated](../images//97f08b3e40277869ee85a42fa0d2a343.png)

6.  Open the details for the Build & Deploy workflow

    ![Text Description automatically generated](../images//da5cda0e73ed46fcc4274becc2f4a30e.png)

7.  Selecting any step in the Action workflow will show more details:

    ![Graphical user interface, text Description automatically generated](../images//765fda402ec958a1267c45c8d15592df.png)

8.  Wait for the workflow to complete successfully.

    ![Text Description automatically generated](../images//291538dda0fbb66c1ccc93f67b3ed263.png)

9.  Navigate back to the Azure Static Web app, click it’s URL and see the Blazor Web App is running as expected.

    ![Graphical user interface, text, application Description automatically generated](../images//71e0fdcd38b8f4e3df22af93a6c04215.png)

10. When searching for a Marvel Character, this throws an error though, which can be validated from the Inspect option of the browser:

    ![A screenshot of a computer Description automatically generated](../images//aebf1488e59ba401c5c69708ed8b2958.png)

11. Remember at the start, where we configured the API calls at the Marvel Developer site, we needed to specify the source URLs from where the calls are allowed. This Azure Static Web App URL is not configured. (Hence why I didn’t worry too much about including my APIKey as hard-coded string in the source code).

    ![Graphical user interface, text, application, email Description automatically generated](../images//07a00ae95a0f1548ac84f149b11ccd34.png)

12. Click Update to save those changes. Trigger a new search, which should reveal the actual Marvel character details. Remember you can use both the default (index) page, as well as the flip page.

# Summary

In this article, I provided all the necessary steps to build a Blazor .NET 8 Web Assembly application. Started from the default template, you updated snippets of code to create a search field and corresponding action button to trigger the search. You learned about using HTTPClient to interact with an external API Back-End. Once this was all working, you looked into using some additional “flip card” CSS layout features, and how to update the Blazor Navigation Menu.

Once the development work was done, we saved the code in a GitHub repository.

Last, you deployed an Azure Static Web App, interacting with the GitHub repository to pick up the source code and publish it using GitHub Actions workflow.

I would like to thank the organizing team of ScifiDevCon 2024 for having accepted my session submission for the 3rd year in a row. Especially since this was my first attempt to do some (semi)live coding, to share my excitement of how I learned to write and build code at age 48. I’m already brainstorming on what Blazor app I can share in next year’s edition...

/Peter

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)
