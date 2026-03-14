---
title: "Book review - Building Blazor WebAssembly Applications with gRPC"
date: 2022-12-17
publishdate: 2022-12-17
tags: ["Azure", ".NET Development", "Books"]
draft: false
---

In this post, I want to share my review of another Blazor book I read recently, **Building Blazor WebAssembly Applications with gRPC** this time from [Vaclav Perakek](https://twitter.com/vaclavperakek), published by [Packt Publishing](https://www.packtpub.com/product/building-blazor-webassembly-applications-with-grpc/9781804610558?_ga=2.130113295.1693879135.1671300604-32592472.1664947786) and available on [Amazon](https://www.amazon.com/Building-Blazor-WebAssembly-Applications-gRPC/dp/1804610550) as well as other e-book subscription platforms.

![Book Cover](../images/screenshot-2022-12-17-53607649.png)

If you have been following me for a while, you know I'm gradually learning more about coding and developing applications, especially using the [Blazor .NET framework](https://dotnet.microsoft.com/en-us/apps/aspnet/web-apps/blazor).

What intrigued me even more with this book, is the gRPC integration. While I heard about before, from far away honestly, I never really looked into it. So besides learning more about Blazor itself, seeing how other much more advanced developers are using the framework, as well as learning on how they write code, I also learned more about what gRPC is all about. 

## What is gRPC
gRPC has been developed by Google, and described as a **high performance Remote Procedure Call RPC framework**. (I remember 'traditional' RPC from my long gone Exchange Server consultant days...). using gRPC, a client application can directly call a method on a foreign server back-end, as if it were a local object to the client, making it a perfect choice for distributed applications and services-oriented architecture. As with any similar RPC-based system - such as in my Exchange Server past - the concept starts from defining a service, specifying the methods that can be called remotely, together with defining the parameters and return types. On the server side, that's where the service interface is running, and the gRPC server component handles the requests. 

gRPC is supported across all popular development languages, such as Java, Ruby, Go, Python,... and now also in Blazor .NET. 

If you want to learn more about gRPC, head over to the [gRPC official docs](https://grpc.io/docs/what-is-grpc/introduction/).

## What is Blazor WebAssembly
Blazor is a high-performance web development framework, created by Microsoft, and part of the broader .NET language family. It allows developers write applications using the familiar C# language. The applications are supported in all modern web browsers using the WebAssembly technology. Where developers would look into JavaScript before, they can now build the same Single Page Applications (SPA) using C-sharp dotnet language. Blazor exists in both WebAssembly (browser-only) runtime, as well as Blazor Server, where it runs on an ASP.NET Server back-end. 

If you want to learn more about Blazor, you might have a look at some of my former blog posts on how to get started:

* https://www.007ffflearning.com/post/efficiently-handling-secrets-as-a-blazor-.net-developer/

* https://www.007ffflearning.com/post/deploying-blazor-apps-using-dotnet-commandline/

* https://www.007ffflearning.com/post/coding-apps-in-blazor-from-a-non-developer/

* https://www.007ffflearning.com/post/coding-apps-in-blazor-from-a-non-developer-part-2/

## Book Review

With that out of the way, let's have a look at what the book has to offer. 

I loved going through the book, as it is **hands-on** from the start. Kicking off the project, starting from the Blazor WASM template in Visual Studio / VSCode, and actually heavily cleaning it up, so you are almost starting from a blank canvas, you learn how to build a web application front-end, which connects to a SQL Server back-end. Without gRPC, this would probably be relying on a REST API call, so that was a nice differentiator for me to learn about. 

Already in the first chapter, Vaclav is jumping into code snippets, clearly explaining how it works, but also often explaining the reasoning behind it. So instead of just copy/pasting code into your own applications, you can almost look into his brain and way of thinking, which helped me understanding the concepts much better.

Chapter 2 is where you **create your first Blazor Web Assembly Application**, starting from a template, but heavily customizing to a workable application example. Chapter 3 describes **Entity Framework** as a process to create a database back-end, and how to interact with it. 

Chapter 4 brings the two worlds together, using **REST API calls**, allowing for **CRUD operations** from the web application towards the database. This was really helpful for me, as I haven't done much around interacting with an actual database to create, update or delete information. While the sample app we're building is around movies and viewers, the concept is valid for about any database-type you could think off (online webshop, HR application with employee data, overall customer information management, etc...)

Chapter 5 is where the **gRPC integration** becomes important. You learn how to build the gRPC services on the server-side, as well as how to consume them from the web app client-side. This was mind-blowing to me, as it was something totally new in my knowledge spectrum. While functionally you are doing the same as with REST, this somewhat felt easier to develop, and the performance seemed better (as in pulling up data from the database...). While my recordset was quite small, I can see a big performance increase here for real-life applications with thousands or tens of thousands of records to work with continuously. 

Having arrived at this point, I think you could say **you should have learned enough to continue your own journey On how to build more complete, powerful WebAssembly-based client applications**, connecting to a database server back-end. The possibilities are unlimited. 

However, Vaclav **didn't stop here**, but continued the book with a chapter on **Source Generators**. As he explains, this technology allows for generating source code automatically, so basically helping developers adding more functionality into applications, without needing to write all the code yourself. 

In the last Chapter 7, Vaclav shares some best practices on how to use gRPC together with C#. 

## Summary
While this book wasn't the largest (about 165 pages), it allowed me to learn more new things about what it takes to build WebAssembly-based web applications, using gRPC instead of the more traditional REST API method. I'm still not an experienced developer, but it teased me to look into more capabilities of Blazor, as well as how to build more services-oriented applications. 

I would recommend this book to developers who are new to Blazor like myself, but it is definitely also a good read for more experienced developers who want to learn more about gRPC-based communication between client/server. 

I'm off now, providing my **5-star review on Amazon** for this book. 

See you later folks!!

[![BuyMeACoffee](../images/screenshot-2022-12-17-17f576e7.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
