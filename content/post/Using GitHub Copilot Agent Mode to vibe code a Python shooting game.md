---
title: "Using GitHub Copilot Agent Mode to vibe code a Python shooting game"
date: 2025-11-29
publishdate: 2025-11-28
tags: ["DevOps", "GitHub Copilot", "AI"]
draft: false
---

For about a year now, I've been teaching a lot on [GitHub Copilot](https://github.com/copilot) as part of my Microsoft role. Our program offers 2 different learning paths, one created by the Microsoft Content developers, [AZ-2007](https://learn.microsoft.com/en-us/training/paths/accelerate-app-development-using-github-copilot/), and the other one is managed by GitHub Content team, known as [GH-300](https://learn.microsoft.com/en-us/training/paths/copilot/). 

If you know my approach to teaching tech a bit, which a learner in my class lately called **inspiring through technology**, it means I'm trying to explain as much as possible through compelling, live demos. After walking learners through different GitHub Copilot features such as documenting/explaining code, generate application code (on different development frameworks), but also Azure CLI, CI/CD pipeline, Dockerfile, YAML, JSON and alike, I usually close with [Agent Mode](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent).

Having showed the first time in April when GitHub Copilot was still in preview, I usually show a demo where the Agent Mode builds me an ASP.NET webapp, modifies the Welcome home page, creates some sample employee data in a json-file, which then gets displayed in a table view in the webapp. If time allows, I also ask to then migrate everything into a SQLite setup, which brings in more complexity such as Entity Framework, SQL data migration steps and interaction with Azure KeyVault, since I specify I want to run this in Azure SQL, but not allowing connection strings in my appsettings.json. 

(Now that I think about it, it might be another great blog post to write on in the near future...)

Earlier this week however, I came up with a new scenario, asking Agent Mode to develop a *shooter game* using Python code, bringing me back to my youth in the mid-80's when I was playing such games on my first 486-PC.

## Agent Mode Prompt

The prompt I used was this:

```bash
*"as a kid, I played arcade games a lot. I want to build a Python app, which tests me on my shooting reflexes. Help me developing a game which does the following:

1. aks for player name input
2. bottom middle of the game screen shows a shooter 
3. anywhere random on screen appears a target
4. player uses the space bar to simulate a shoot
5. calculate the time between the target appearing and player pressing the space bar to shoot
6. if that time is less than 0.3 sec, player wins, otherwise computer wins
7. show a "YOU WIN" or "YOU ARE TOO SLOW" dpeending on the outcome"
```

![Agent Mode Prompt Used](../images/screenshot-2025-11-28-018f3ae5.png)

## Agent Mode Processing

1. From here, the **Agent started rolling...**

1. Confirming with some sort of understanding what I asked for, followed by  *creating 3 todos*:

- Set Up Python Environment
- Creating the Reflex Shooting Game
- Testing the Game

![Agent Mode Starting](../images/screenshot-2025-11-28-88f73764.png)

1. This process took less than **1 minute**, can you imagine? From there, it continued with providing detailed instructions on how to the game works.

![Game Playing Instructions](../images/screenshot-2025-11-28-f533f735.png)

1. Next, it also had a list of features included: 

![Game Features Included](../images/screenshot-2025-11-28-dc0b721b.png)

1. Time to start the game!!

![Start Game](../images/screenshot-2025-11-28-c3d6fa9b.png)

1. Which allowed me to play exactly as I asked for. When I was too slow, it would tell me... 

![Too Slow](../images/screenshot-2025-11-28-df129c5d.png)

1. And several attempts later, I finally managed to win a game!! 

![You Win](../images/screenshot-2025-11-28-8d0ea57f.png)

## Summary

I thought after using GitHub Copilot for training our customers and showing capabilities using live demos for about 5 hours per class, as well as using it for a lot of "coding" tasks as part of my role as trainer, mainly creating more demo scenarios (see [Trainer-Demo-Deploy](https://aka.ms/trainer-demo-deploy) to get an idea what that means...), I thought I'd seen it all. 

Yet, **it keeps suprising me every single day when I try something new.** 

If I had access to this technology in the mid 80's, I guess I would have spent more time learning about coding than playing games... although this game is actually pretty addicting already. Time to wrap up this post and go play a bit more! And feel 12 years old again.

If you want to see some similar version of this templategame in action, head over to [my github repo](https://github.com/petender/vibeshooter). 

[![BuyMeACoffee](../images/screenshot-2025-11-28-17f576e7.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
