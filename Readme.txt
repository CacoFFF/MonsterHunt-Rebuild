The goal of this repository is to create a functional, bugfixed and optimized build of MonsterHunt without breaking network compatibility.
It will be structured in a way that it'll be a lot easier to create mods, extensions and maps for this gametype.

Guidelines:
The base package's name has to be MonsterHunt.
The base package will be globally shared across all modifications, therefore it must contain all function declarations from the original build (even if without code).
Maps have to load with this new package so all non-abstract actors must also be in said base package.
The modifications will be based mainly on mutators and the game class (subclass of MonsterHunt).
All of the insertable actors must facilitate modding, therefore they must interact with the active MH gametype through events.
The package must be network compatible with the original MonsterHunt build, so package conformation is mandatory after it's compiled.
No code protection will be employed in this build, and no decompiled code/resources will be used to rebuild the mod.

I consider this entire repository as a practice for mod rebuilding, and a lesson to new coders.
You are free to use and modify this code as you wish.
- Higor