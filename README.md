# Roblox Placement System

Tried my hand at Lua and Roblox game development to make a quick demo allowing a user to choose an object from a menu, then place it onto the map. Some extra features are thrown in, like collision detection and even saving placed objects to user profiles.

## Features

### Placing an Object

The idea is easy enough, when a user selects an object to build from the menu, the server sends this object ID to the client to instantiate the placement system. Here, we track the user's mouse and detect where they would like to place it, then send the coordinates off to the server to place it into the world.

A lot of heavy lifting is done by Roblox's existing raycasting features, but we still need to handle a few things. Users can only place objects onto their own baseplate, so we need to dynamically whitelist the possible coordinates (so we can place more possible baseplates without having to re-calculate anything).

Additionally, we want some visual features for the user: highlighting the object being placed in red or green based on collision with other objects, and turning the baseplate into a grid and snapping the object onto the correct coordinates. Collision is the most complicated here, so we use a custom hitbox to define collisions. This is better than just detecting overlap of the actual objects, as we can customize it to allow certain pieces to overlap if we wish.

### Client-Server Relationship
One of the earlier challenges was figuring out how to communicate between the client and server. Looking at the code, you will see the only thing handled by the client is the user choosing where to place an object. Since this is a placement system, it seems like this would be the bulk of the work. However, a significant amount is done on the server, such as building objects into the world, the menus where items are selected, handling loading and saving player data, and building/clearing baseplates when users join or leave.

The client-server relationship is purely handled through listeners. When an item is selected from the menu, the server send the object ID to the client so a user can choose where to place it. When a user selects a position, the client sends these coordinates to the server to build it.

### Save Placed Objects

Another complicated feature was saving data to user profiles. This feature saves all objects placed by a user, and handles rebuilding them when the user joins the game again, even if they spawn on a baseplate at a different location. For each object, we store relative coordinates, rotation, a UUID, and the item ID. When leaving, the objects are cleared. When joining, the objects are rebuilt.

### Anti-Cheat

Roblox is susceptible to exploiting just about anything that exists client-side. As mentioned before, the relationship between the client and server is handled only through listeners and strict avenues for accepting inputs when they are called. This way, the only data that exists on the client side can me modified to the exploiter's wishes without having an impact to other playes or the game overall.

Another common 'cheat' is autoclicking to place objects quickly. There is a few safe measures in place: generating a UUID by the server before instantiating the placement system for the user, adding a debounce onto the placement function, and adding a limiter on how fast clicks are registered while in the placement system. All together, auto clicking is mitigated.

### Rojo Framework

Typically, Roblox development takes place within the Roblox studio. However, writing code here lacks a lot of the pros of existing tools, like a proper IDE and version control. Rojo is a custom Roblox development framework that synchronizes externally written code into Roblox Studio. That is why I can display my code here with proper version control, rather than a single Roblox Studio file.
