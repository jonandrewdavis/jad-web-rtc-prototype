# Typescript Websocket Server for Godot Lobby

####

butler push dist

butler push dist jonandrewitchio/jad-web-rtc-prototype:html5

#### TS build is pretty annoying...

## Updates July 2025

https://nodejs.org/en/learn/typescript/run

```
yarn build
```

```
npx ts-node app.ts
```

### Notes

Changed the `require` statements to:
```
import WebSocket from 'ws';
```


### Godot WebSocket Multiplayer Template
 A Godot client project that connects to a Typescript server
https://github.com/Hairic95/Godot-WebSocket-Multiplayer-Template/tree/main

#### Server

install all the node packages with

npm install

run in debug with

ts-node app.ts

export in the /dist folder with

npm run build

#### Client

run multiple clients using the powershell script

run_multiple 2

I'll probably update the readme to be clearer, right now I'm tired
